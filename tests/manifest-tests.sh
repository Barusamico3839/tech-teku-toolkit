#!/usr/bin/env bash
# manifest generate/verify unit tests.
# Mutating cases run against a mktemp COPY of plugins/harnesseed so the real
# working tree is never touched (uncommitted edits stay safe).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MS="$ROOT/scripts/blueprint-manifest.sh"
PASS=0; FAIL=0
check() { # name, expected_exit, actual_exit
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 (expected exit $2, got $3)"; fi
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/plugins"
cp -r "$ROOT/plugins/harnesseed" "$TMP/plugins/"

bash "$MS" generate "$TMP"; check "generate runs (isolated copy)" 0 $?
python3 -c "import json; m=json.load(open('$TMP/plugins/harnesseed/blueprint/manifest.json')); assert m['files'], 'empty'; assert 'manifest.json' not in m['files']"
check "manifest well-formed, excludes itself" 0 $?
bash "$MS" verify "$TMP"; check "verify passes on fresh manifest" 0 $?

echo "tamper" >> "$TMP/plugins/harnesseed/blueprint/invariants.md"
bash "$MS" verify "$TMP" >/dev/null 2>&1; check "verify fails on tamper" 1 $?
bash "$MS" generate "$TMP" >/dev/null && bash "$MS" verify "$TMP"; check "regenerate then verify passes" 0 $?

# the real repo's committed manifest must also verify (read-only, no generate)
bash "$MS" verify; check "repo manifest verifies (read-only)" 0 $?

echo "manifest-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
