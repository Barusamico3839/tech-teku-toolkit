#!/usr/bin/env bash
# Staged 3-way merge for /harnesseed:pull.
#   stage    <seedling> <new-blueprint>  merge stem overlays into .pull-staging/merged/
#                                        (exit 0 clean / 2 conflicts remain / 1 abort)
#   finalize <seedling> <new-blueprint>  all-or-nothing apply: roots replacement + merged
#                                        stem + regenerated planted.json in ONE commit
#                                        carrying the pull trailer (exit 1 on any refusal)
# The seedling's tracked files are NEVER touched by `stage`; partial states live only in
# the git-ignored .pull-staging/. `finalize` refuses to start unless it can commit
# (git identity probe) and the new blueprint still matches what was staged; the staging
# directory is removed only AFTER the commit succeeds, so an interrupted pull always
# remains either resumable or byte-identical to the pre-pull state.
set -euo pipefail
CMD="${1:?usage: stage-merge.sh stage|finalize <seedling> <new-blueprint-dir>}"
S="${2:?seedling dir}"
NEWBP="${3:?new blueprint dir}"
STG="$S/.pull-staging"

validate_newbp() {
  [ -d "$NEWBP" ] || { echo "ABORT: new blueprint dir not found: $NEWBP"; exit 1; }
  python3 - "$NEWBP" <<'PY' || exit 1
import json, sys
try:
    m = json.load(open(sys.argv[1] + "/manifest.json"))
except Exception as e:
    sys.exit(f"ABORT: new blueprint manifest unreadable: {e}")
if "seed_version" not in m:
    sys.exit("ABORT: new blueprint manifest has no seed_version")
PY
}

case "$CMD" in
stage)
  git -C "$S" rev-parse --git-dir >/dev/null 2>&1 \
    || { echo "ABORT: $S is not a git repository (germination incomplete or wrong path?)"; exit 1; }
  [ -d "$S/stem" ] || { echo "ABORT: $S/stem missing — not a germinated seedling"; exit 1; }
  validate_newbp
  if [ -n "$(git -C "$S" status --porcelain)" ]; then
    echo "ABORT: seedling working tree is not clean — commit or discard first"; exit 1
  fi
  if [ -e "$STG" ]; then
    echo "ABORT: leftover staging at $STG (an interrupted pull) — resume by resolving its"
    echo "       conflicts then 'finalize', or discard it (rm -rf) and stage again"; exit 1
  fi
  mkdir -p "$STG/merged"
  sha256sum "$NEWBP/manifest.json" | cut -d' ' -f1 > "$STG/newbp-manifest.sha256"
  CONFLICTS=0
  while IFS= read -r -d '' f; do
    rel="${f#"$S/stem/"}"
    base="$S/roots/$rel"; theirs="$NEWBP/$rel"
    mkdir -p "$(dirname "$STG/merged/$rel")"
    cp "$f" "$STG/merged/$rel"
    [ -f "$base" ] || base=/dev/null
    if [ -f "$theirs" ]; then
      if ! git merge-file -L stem -L roots -L upstream "$STG/merged/$rel" "$base" "$theirs"; then
        echo "CONFLICT: $rel"; CONFLICTS=1
      fi
    fi
  done < <(find "$S/stem" -type f -print0)
  if [ "$CONFLICTS" = 0 ]; then
    echo "staging complete: no conflicts"; exit 0
  fi
  echo "staging complete: conflicts remain in $STG/merged/ (resolve, then finalize)"; exit 2
  ;;
finalize)
  if [ ! -d "$STG/merged" ]; then
    echo "ABORT: no staging to finalize (run 'stage' first)"; exit 1
  fi
  if grep -rn '^<<<<<<< ' "$STG/merged" >/dev/null 2>&1; then
    echo "ABORT: unresolved conflict markers remain in staging"; exit 1
  fi
  validate_newbp
  if [ -f "$STG/newbp-manifest.sha256" ]; then
    staged="$(cat "$STG/newbp-manifest.sha256")"
    current="$(sha256sum "$NEWBP/manifest.json" | cut -d' ' -f1)"
    if [ "$staged" != "$current" ]; then
      echo "ABORT: the new blueprint changed since 'stage' ran — discard staging"
      echo "       (rm -rf $STG) and stage again against the current blueprint"; exit 1
    fi
  fi
  # Refuse before any mutation if a commit would be impossible (identity unavailable).
  git -C "$S" var GIT_COMMITTER_IDENT >/dev/null 2>&1 \
    || { echo "ABORT: git identity unavailable (set user.name/user.email) — nothing was changed"; exit 1; }
  python3 - "$S" "$NEWBP" "$STG" <<'PY'
import hashlib, json, os, shutil, subprocess, sys
s, newbp, stg = sys.argv[1], sys.argv[2], sys.argv[3]

# Phase 1: read and compute EVERYTHING before touching the seedling.
ver = json.load(open(os.path.join(newbp, "manifest.json")))["seed_version"]
walked = {}
for dp, _, fns in os.walk(newbp):
    for fn in sorted(fns):
        rel = os.path.relpath(os.path.join(dp, fn), newbp)
        walked[rel] = hashlib.sha256(open(os.path.join(dp, fn), "rb").read()).hexdigest()
planted = json.load(open(os.path.join(s, "planted.json")))
planted["seed_version"] = ver
planted["blueprint"] = dict(sorted(walked.items()))
new_roots = os.path.join(stg, "new-roots")
if os.path.exists(new_roots):
    shutil.rmtree(new_roots)
shutil.copytree(newbp, new_roots)

# Phase 2: mutate (any failure below leaves staging intact and prints recovery).
try:
    old_roots = os.path.join(stg, "old-roots")
    if os.path.exists(old_roots):
        shutil.rmtree(old_roots)
    os.rename(os.path.join(s, "roots"), old_roots)
    os.rename(new_roots, os.path.join(s, "roots"))
    merged = os.path.join(stg, "merged")
    for dp, _, fns in os.walk(merged):
        for fn in fns:
            src = os.path.join(dp, fn)
            rel = os.path.relpath(src, merged)
            dst = os.path.join(s, "stem", rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy(src, dst)
    tmp = os.path.join(s, "planted.json.tmp")
    with open(tmp, "w") as f:
        json.dump(planted, f, indent=2, ensure_ascii=False)
    os.replace(tmp, os.path.join(s, "planted.json"))
    subprocess.run(["git", "-C", s, "add", "-A"], check=True)
    subprocess.run(["git", "-C", s, "commit", "-q",
                    "-m", f"pull: absorb seed v{ver}",
                    "-m", f"Harnesseed-Event: pull\nSeed-Version: {ver}"], check=True)
except Exception as e:
    print(f"ERROR during finalize: {e}", file=sys.stderr)
    print("The seedling working tree may be modified but NOTHING was committed.",
          file=sys.stderr)
    print(f"Recover with: git -C {s} reset --hard && git -C {s} clean -fd -e .pull-staging",
          file=sys.stderr)
    print("Staging is intact — resolve and re-run finalize, or discard it.", file=sys.stderr)
    sys.exit(1)

# Phase 3: only after a successful commit does staging disappear.
shutil.rmtree(stg)
print(f"pull finalized: seedling absorbed v{ver}")
PY
  ;;
*)
  echo "unknown command $CMD"; exit 1
  ;;
esac
