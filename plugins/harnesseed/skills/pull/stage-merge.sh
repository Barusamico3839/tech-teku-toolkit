#!/usr/bin/env bash
# Staged 3-way merge for /harnesseed:pull.
#   stage    <seedling> <new-blueprint>  merge stem overlays into .pull-staging/merged/
#                                        (exit 0 clean / 2 conflicts remain / 1 abort)
#   finalize <seedling> <new-blueprint>  all-or-nothing apply: roots replacement + merged
#                                        stem + regenerated planted.json in ONE commit
#                                        carrying the pull trailer (exit 1 on any refusal)
# The seedling's tracked files are NEVER touched by `stage`; partial states live only in
# the git-ignored .pull-staging/. Interrupted pulls leave the seedling byte-identical.
set -euo pipefail
CMD="${1:?usage: stage-merge.sh stage|finalize <seedling> <new-blueprint-dir>}"
S="${2:?seedling dir}"
NEWBP="${3:?new blueprint dir}"
STG="$S/.pull-staging"

case "$CMD" in
stage)
  if [ -n "$(git -C "$S" status --porcelain)" ]; then
    echo "ABORT: seedling working tree is not clean — commit or discard first"; exit 1
  fi
  if [ -e "$STG" ]; then
    echo "ABORT: leftover staging at $STG (an interrupted pull) — resume by resolving its"
    echo "       conflicts then 'finalize', or discard it (rm -rf) and stage again"; exit 1
  fi
  mkdir -p "$STG/merged"
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
  python3 - "$S" "$NEWBP" "$STG" <<'PY'
import hashlib, json, os, shutil, subprocess, sys
s, newbp, stg = sys.argv[1], sys.argv[2], sys.argv[3]
shutil.rmtree(os.path.join(s, "roots"))
shutil.copytree(newbp, os.path.join(s, "roots"))
merged = os.path.join(stg, "merged")
for dp, _, fns in os.walk(merged):
    for fn in fns:
        src = os.path.join(dp, fn)
        rel = os.path.relpath(src, merged)
        dst = os.path.join(s, "stem", rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy(src, dst)
walked = {}
for dp, _, fns in os.walk(newbp):
    for fn in sorted(fns):
        rel = os.path.relpath(os.path.join(dp, fn), newbp)
        walked[rel] = hashlib.sha256(open(os.path.join(dp, fn), "rb").read()).hexdigest()
ver = json.load(open(os.path.join(newbp, "manifest.json")))["seed_version"]
planted = json.load(open(os.path.join(s, "planted.json")))
planted["seed_version"] = ver
planted["blueprint"] = dict(sorted(walked.items()))
tmp = os.path.join(s, "planted.json.tmp")
with open(tmp, "w") as f:
    json.dump(planted, f, indent=2, ensure_ascii=False)
os.replace(tmp, os.path.join(s, "planted.json"))
shutil.rmtree(stg)
subprocess.run(["git", "-C", s, "add", "-A"], check=True)
subprocess.run(["git", "-C", s, "commit", "-q",
                "-m", f"pull: absorb seed v{ver}",
                "-m", f"Harnesseed-Event: pull\nSeed-Version: {ver}"], check=True)
print(f"pull finalized: seedling absorbed v{ver}")
PY
  ;;
*)
  echo "unknown command $CMD"; exit 1
  ;;
esac
