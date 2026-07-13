#!/usr/bin/env bash
# stage-merge.sh tests: staged 3-way merge can never corrupt the seedling.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SM="$ROOT/plugins/harnesseed/skills/pull/stage-merge.sh"
CHK="$ROOT/plugins/harnesseed/blueprint/evals/check-invariants.sh"
PASS=0; FAIL=0
check() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 (expected $2 got $3)"; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

mk_seedling() { # $1 = dir
  local S="$1"
  mkdir -p "$S/roots" "$S/stem" "$S/trend-stock"
  printf 'line-a\nline-b\nline-c\n' > "$S/roots/philosophy.md"
  printf 'minimal\n' > "$S/roots/invariants.md"
  printf '{"seed_version":"0.4.0","files":{}}' > "$S/roots/manifest.json"
  # personalization: stem adds a line at the END (upstream will change the TOP)
  printf 'line-a\nline-b\nline-c\nmy-personal-take\n' > "$S/stem/philosophy.md"
  printf '{"entries":[]}' > "$S/trend-stock/index.json"
  python3 - "$S" <<'PY'
import hashlib, json, os, sys
s = sys.argv[1]
walked = {}
for dp, _, fns in os.walk(os.path.join(s, "roots")):
    for fn in sorted(fns):
        rel = os.path.relpath(os.path.join(dp, fn), os.path.join(s, "roots"))
        walked[rel] = hashlib.sha256(open(os.path.join(dp, fn), "rb").read()).hexdigest()
json.dump({"seed_version": "0.4.0", "planted_at": "2026-07-13", "blueprint": walked},
          open(os.path.join(s, "planted.json"), "w"), indent=1)
PY
  printf '.pull-staging/\n' > "$S/.gitignore"
  git -C "$S" init -q
  git -C "$S" -c user.email=t@t -c user.name=t add -A
  git -C "$S" -c user.email=t@t -c user.name=t commit -q -m "germinate: v0.4.0" -m "Harnesseed-Event: germinate
Seed-Version: 0.4.0"
}

mk_newbp() { # $1 = dir, $2 = philosophy top line — writes a REAL manifest (hashes match)
  local B="$1"
  mkdir -p "$B"
  printf '%s\nline-b\nline-c\n' "$2" > "$B/philosophy.md"
  printf 'minimal v2\n' > "$B/invariants.md"
  python3 - "$B" <<'PY'
import hashlib, json, os, sys
b = sys.argv[1]
files = {}
for dp, _, fns in os.walk(b):
    for fn in sorted(fns):
        rel = os.path.relpath(os.path.join(dp, fn), b)
        if rel == "manifest.json":
            continue
        files[rel] = hashlib.sha256(open(os.path.join(dp, fn), "rb").read()).hexdigest()
json.dump({"seed_version": "0.5.0", "files": files}, open(os.path.join(b, "manifest.json"), "w"))
PY
}

# --- clean merge: upstream changes top line, stem added bottom line ---
S1="$TMP/s1"; mk_seedling "$S1"
B1="$TMP/bp1"; mk_newbp "$B1" "line-a-improved"
bash "$SM" stage "$S1" "$B1" >/dev/null; check "clean stage exits 0" 0 $?
GIT_AUTHOR_EMAIL=t@t GIT_AUTHOR_NAME=t GIT_COMMITTER_EMAIL=t@t GIT_COMMITTER_NAME=t \
  bash "$SM" finalize "$S1" "$B1" >/dev/null; check "finalize exits 0" 0 $?
grep -q 'line-a-improved' "$S1/stem/philosophy.md"; check "merged stem absorbed upstream change" 0 $?
grep -q 'my-personal-take' "$S1/stem/philosophy.md"; check "merged stem kept personalization" 0 $?
grep -q 'line-a-improved' "$S1/roots/philosophy.md"; check "roots replaced with new pristine" 0 $?
python3 -c "import json; d=json.load(open('$S1/planted.json')); assert d['seed_version']=='0.5.0', d"
check "planted.json absorbed new version" 0 $?
[ ! -e "$S1/.pull-staging" ]; check "staging removed after finalize" 0 $?
bash "$CHK" "$S1" >/dev/null; check "invariants checker passes post-pull (pull trailer)" 0 $?
N_COMMITS="$(git -C "$S1" rev-list --count HEAD)"
check "pull is exactly one commit (germinate+pull=2)" 2 "$N_COMMITS"

# --- conflict: upstream and stem change the SAME line ---
S2="$TMP/s2"; mk_seedling "$S2"
printf 'line-a-MINE\nline-b\nline-c\n' > "$S2/stem/philosophy.md"
git -C "$S2" -c user.email=t@t -c user.name=t add -A
git -C "$S2" -c user.email=t@t -c user.name=t commit -q -m "grow: personalize top" -m "Harnesseed-Event: grow"
B2="$TMP/bp2"; mk_newbp "$B2" "line-a-THEIRS"
SNAP_BEFORE="$(git -C "$S2" status --porcelain; git -C "$S2" rev-parse HEAD)"
bash "$SM" stage "$S2" "$B2" >/dev/null 2>&1; check "conflicting stage exits 2" 2 $?
SNAP_AFTER="$(git -C "$S2" status --porcelain; git -C "$S2" rev-parse HEAD)"
[ "$SNAP_BEFORE" = "$SNAP_AFTER" ]; check "seedling tracked files untouched by conflict" 0 $?
grep -q '^<<<<<<< ' "$S2/.pull-staging/merged/philosophy.md"; check "conflict markers live in staging only" 0 $?
bash "$SM" finalize "$S2" "$B2" >/dev/null 2>&1; check "finalize refuses unresolved markers" 1 $?
bash "$SM" stage "$S2" "$B2" >/dev/null 2>&1; check "leftover staging detected on re-stage" 1 $?

# --- interrupted pull: resolve the staged conflict, then finalize completes (P5-4) ---
printf 'line-a-RESOLVED\nline-b\nline-c\n' > "$S2/.pull-staging/merged/philosophy.md"
GIT_AUTHOR_EMAIL=t@t GIT_AUTHOR_NAME=t GIT_COMMITTER_EMAIL=t@t GIT_COMMITTER_NAME=t \
  bash "$SM" finalize "$S2" "$B2" >/dev/null; check "resume: finalize completes after resolution" 0 $?
bash "$CHK" "$S2" >/dev/null; check "resume: invariants pass post-pull" 0 $?
check "resume: pull is one commit (total 3)" 3 "$(git -C "$S2" rev-list --count HEAD)"
python3 -c "import json; d=json.load(open('$S2/planted.json')); assert d['seed_version']=='0.5.0', d"
check "resume: planted absorbed 0.5.0" 0 $?
grep -q 'line-a-RESOLVED' "$S2/stem/philosophy.md"; check "resume: stem has resolved content" 0 $?
grep -q 'line-a-THEIRS' "$S2/roots/philosophy.md"; check "resume: roots is new pristine" 0 $?
[ ! -e "$S2/.pull-staging" ]; check "resume: staging cleaned up" 0 $?
check "resume: pull trailer present" "pull" "$(git -C "$S2" log -1 --format='%(trailers:key=Harnesseed-Event,valueonly)')"

# --- dirty tree abort ---
S3="$TMP/s3"; mk_seedling "$S3"
printf 'dirty\n' >> "$S3/stem/philosophy.md"
B3="$TMP/bp3"; mk_newbp "$B3" "x"
bash "$SM" stage "$S3" "$B3" >/dev/null 2>&1; check "dirty working tree aborts stage" 1 $?

# --- stage precondition hardening ---
NOTREPO="$TMP/notrepo"; mkdir -p "$NOTREPO"
bash "$SM" stage "$NOTREPO" "$B3" >/dev/null 2>&1; check "non-repo seedling aborts stage" 1 $?
NOSTEM="$TMP/nostem"; mkdir -p "$NOSTEM"; git -C "$NOSTEM" init -q
bash "$SM" stage "$NOSTEM" "$B3" >/dev/null 2>&1; check "stem-less seedling aborts stage" 1 $?
S4="$TMP/s4"; mk_seedling "$S4"
bash "$SM" stage "$S4" "$TMP/does-not-exist" >/dev/null 2>&1; check "missing NEWBP aborts stage" 1 $?
BTAMPER="$TMP/bptamper"; mk_newbp "$BTAMPER" "line-a-evil"
printf 'weakened\n' >> "$BTAMPER/philosophy.md"
bash "$SM" stage "$S4" "$BTAMPER" >/dev/null 2>&1; check "files-only tamper (manifest stale) aborts stage" 1 $?
touch "$BTAMPER/evil.md"
bash "$SM" stage "$S4" "$BTAMPER" >/dev/null 2>&1; check "rogue file addition aborts stage" 1 $?

# --- finalize refuses when NEWBP changed after stage / is invalid ---
B4="$TMP/bp4"; mk_newbp "$B4" "line-a-new"
bash "$SM" stage "$S4" "$B4" >/dev/null; check "s4 stage clean" 0 $?
printf ' \n' >> "$B4/manifest.json"
SNAP4="$(git -C "$S4" status --porcelain; git -C "$S4" rev-parse HEAD)"
bash "$SM" finalize "$S4" "$B4" >/dev/null 2>&1; check "NEWBP mutated after stage aborts finalize" 1 $?
SNAP4B="$(git -C "$S4" status --porcelain; git -C "$S4" rev-parse HEAD)"
[ "$SNAP4" = "$SNAP4B" ]; check "seedling untouched by refused finalize" 0 $?
bash "$SM" finalize "$S4" "$TMP/does-not-exist" >/dev/null 2>&1; check "missing NEWBP aborts finalize" 1 $?

# --- finalize refuses (before mutating) when git identity is unavailable ---
S5="$TMP/s5"; mk_seedling "$S5"
git -C "$S5" config user.useConfigOnly true
B5="$TMP/bp5"; mk_newbp "$B5" "line-a-v5"
bash "$SM" stage "$S5" "$B5" >/dev/null; check "s5 stage clean" 0 $?
OUT5="$(env -u GIT_AUTHOR_EMAIL -u GIT_AUTHOR_NAME -u GIT_COMMITTER_EMAIL -u GIT_COMMITTER_NAME -u EMAIL \
  GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null bash "$SM" finalize "$S5" "$B5" 2>&1)"
check "identity-less finalize aborts" 1 $?
grep -q 'line-a\b' "$S5/roots/philosophy.md"; check "roots untouched by identity abort" 0 $?
[ -d "$S5/.pull-staging/merged" ]; check "staging preserved for resume after identity abort" 0 $?

echo "pull-merge-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
