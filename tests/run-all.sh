#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - <<'PY'
import json
for p in [".claude-plugin/marketplace.json",
          "plugins/harnesseed/.claude-plugin/plugin.json",
          "plugins/harnesseed/hooks/hooks.json",
          "plugins/harnesseed/blueprint/trend-stock/index-seed.json"]:
    json.load(open(p)); print("parse OK:", p)
PY
bash "$ROOT/scripts/blueprint-manifest.sh" verify
bash "$ROOT/tests/manifest-tests.sh"
bash "$ROOT/tests/hook-tests.sh"
bash "$ROOT/tests/invariants-tests.sh"
bash "$ROOT/tests/scout-ledger-tests.sh"
bash "$ROOT/tests/checkup-collect-tests.sh"
bash "$ROOT/tests/invariants-p4-tests.sh"
echo "ALL TEST SUITES PASSED"
