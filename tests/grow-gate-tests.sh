#!/usr/bin/env bash
# integrity-gate.py unit tests: the PULL-FIRST / TAMPER-STOP branches must never be confused.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$ROOT/plugins/harnesseed/skills/grow/integrity-gate.py"
PASS=0; FAIL=0
expect() { # name, expected_exit, expected_needle, out, actual_exit
  local ok=1
  [ "$2" = "$5" ] || ok=0
  case "$4" in *"$3"*) ;; *) ok=0 ;; esac
  if [ "$ok" = 1 ]; then PASS=$((PASS+1)); else
    FAIL=$((FAIL+1)); echo "FAIL: $1 (want exit $2 + '$3'; got exit $5, out: $4)"
  fi
}
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# fixture: mock plugin cache + matching seedling
PLUG="$TMP/plug"; BP="$PLUG/blueprint"; S="$TMP/seedling"
mkdir -p "$PLUG/.claude-plugin" "$BP/evals" "$S/roots/evals"
printf '{"name":"harnesseed","version":"9.9.9"}' > "$PLUG/.claude-plugin/plugin.json"
printf 'canon philosophy\n' > "$BP/philosophy.md"
printf '#!/bin/bash\necho mock checker\n' > "$BP/evals/check-invariants.sh"
cp "$BP/philosophy.md" "$S/roots/philosophy.md"
cp "$BP/evals/check-invariants.sh" "$S/roots/evals/check-invariants.sh"
python3 - "$BP" "$S" <<'PY'
import hashlib, json, os, sys
bp, s = sys.argv[1], sys.argv[2]
walked = {}
for dp, _, fns in os.walk(bp):
    for fn in sorted(fns):
        rel = os.path.relpath(os.path.join(dp, fn), bp)
        walked[rel] = hashlib.sha256(open(os.path.join(dp, fn), "rb").read()).hexdigest()
json.dump({"seed_version": "9.9.9", "planted_at": "2026-07-13", "blueprint": walked},
          open(os.path.join(s, "planted.json"), "w"))
PY

OUT="$(python3 "$GATE" "$BP" "$S" "$PLUG")"; RC=$?
expect "matched cache passes" 0 "integrity OK" "$OUT" $RC

printf '{"name":"harnesseed","version":"9.9.10"}' > "$PLUG/.claude-plugin/plugin.json"
OUT="$(python3 "$GATE" "$BP" "$S" "$PLUG" 2>&1)"; RC=$?
expect "version mismatch -> PULL-FIRST exit 3" 3 "PULL-FIRST:" "$OUT" $RC
printf '{"name":"harnesseed","version":"9.9.9"}' > "$PLUG/.claude-plugin/plugin.json"

printf 'tampered\n' >> "$BP/philosophy.md"
OUT="$(python3 "$GATE" "$BP" "$S" "$PLUG" 2>&1)"; RC=$?
expect "same version + hash mismatch -> TAMPER-STOP exit 2" 2 "TAMPER-STOP:" "$OUT" $RC
printf 'canon philosophy\n' > "$BP/philosophy.md"

printf 'echo weakened\n' >> "$S/roots/evals/check-invariants.sh"
OUT="$(python3 "$GATE" "$BP" "$S" "$PLUG" 2>&1)"; RC=$?
expect "unpinned roots checker -> TAMPER-STOP exit 2" 2 "TAMPER-STOP:" "$OUT" $RC

echo "grow-gate-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
