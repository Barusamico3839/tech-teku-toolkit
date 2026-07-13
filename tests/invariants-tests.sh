#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHK="$ROOT/plugins/harnesseed/blueprint/evals/check-invariants.sh"
PASS=0; FAIL=0
check() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 (expected $2 got $3)"; fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
S="$TMP/seedling"; mkdir -p "$S/roots"
printf 'canon-content\n' > "$S/roots/philosophy.md"
H="$(python3 -c "import hashlib;print(hashlib.sha256(open('$S/roots/philosophy.md','rb').read()).hexdigest())")"
printf '{"seed_version":"0.1.0","planted_at":"2026-07-13","blueprint":{"philosophy.md":"%s"}}' "$H" > "$S/planted.json"

bash "$CHK" "$S"; check "pristine roots pass" 0 $?
touch "$S/roots/evil.md"
bash "$CHK" "$S" >/dev/null 2>&1; check "unexpected roots addition fails" 1 $?
rm "$S/roots/evil.md"
printf 'personalized!\n' >> "$S/roots/philosophy.md"
bash "$CHK" "$S" >/dev/null 2>&1; check "tampered roots fail" 1 $?
printf 'not json' > "$S/planted.json"
bash "$CHK" "$S" >/dev/null 2>&1; check "broken planted.json fails" 1 $?
rm "$S/planted.json"
bash "$CHK" "$S" >/dev/null 2>&1; check "missing planted.json fails" 1 $?

echo "invariants-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
