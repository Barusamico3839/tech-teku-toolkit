#!/usr/bin/env bash
# manifest generate/verify unit tests
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
check() { # name, expected_exit, actual_exit
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 (expected exit $2, got $3)"; fi
}

bash "$ROOT/scripts/blueprint-manifest.sh" generate; check "generate runs" 0 $?
python3 -c "import json; m=json.load(open('$ROOT/plugins/harnesseed/blueprint/manifest.json')); assert m['files'], 'empty'; assert 'manifest.json' not in m['files']"
check "manifest well-formed, excludes itself" 0 $?
bash "$ROOT/scripts/blueprint-manifest.sh" verify; check "verify passes on fresh manifest" 0 $?

echo "tamper" >> "$ROOT/plugins/harnesseed/blueprint/invariants.md"
bash "$ROOT/scripts/blueprint-manifest.sh" verify >/dev/null 2>&1; check "verify fails on tamper" 1 $?
git -C "$ROOT" checkout -q -- plugins/harnesseed/blueprint/invariants.md
bash "$ROOT/scripts/blueprint-manifest.sh" verify; check "verify passes after restore" 0 $?

echo "manifest-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
