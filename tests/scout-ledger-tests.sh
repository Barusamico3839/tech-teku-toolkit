#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LEDGER="$ROOT/plugins/harnesseed/skills/scout/ledger.py"
PASS=0; FAIL=0
check() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 (expected $2 got $3)"; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
IDX="$TMP/index.json"
printf '{"entries":[{"id":"a","title":"A","status":"bundled","source":"s","registered_at":"2026-07-13"}]}' > "$IDX"

python3 "$LEDGER" known "$IDX" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d[0]['id']=='a' and d[0]['status']=='bundled'"
check "known lists entries" 0 $?

printf '{"id":"b","title":"B","status":"adopted","source":"s","registered_at":"2026-07-13"}' > "$TMP/e.json"
python3 "$LEDGER" append "$IDX" "$TMP/e.json" >/dev/null; check "append new ok" 0 $?
python3 "$LEDGER" append "$IDX" "$TMP/e.json" >/dev/null 2>&1; check "duplicate id rejected" 1 $?

printf '{"id":"c","title":"C","status":"rejected","source":"s","registered_at":"2026-07-13"}' > "$TMP/e.json"
python3 "$LEDGER" append "$IDX" "$TMP/e.json" >/dev/null 2>&1; check "rejected missing reason/maturity/evidence fails" 1 $?
printf '{"id":"c","title":"C","status":"rejected","source":"s","registered_at":"2026-07-13","reason":"immature","maturity":"emerging","evidence":"single blog post"}' > "$TMP/e.json"
python3 "$LEDGER" append "$IDX" "$TMP/e.json" >/dev/null; check "rejected with fields ok" 0 $?

printf '{"id":"d","title":"D","status":"adopted","source":"s","registered_at":"2026-07-13","supersedes":"zzz"}' > "$TMP/e.json"
python3 "$LEDGER" append "$IDX" "$TMP/e.json" >/dev/null 2>&1; check "supersedes unknown id fails" 1 $?
printf '{"id":"d","title":"D","status":"adopted","source":"s","registered_at":"2026-07-13","supersedes":"c"}' > "$TMP/e.json"
python3 "$LEDGER" append "$IDX" "$TMP/e.json" >/dev/null; check "supersedes known id ok" 0 $?

printf '{"id":"e","title":"E","status":"banana","source":"s","registered_at":"2026-07-13"}' > "$TMP/e.json"
python3 "$LEDGER" append "$IDX" "$TMP/e.json" >/dev/null 2>&1; check "bad status rejected" 1 $?

python3 "$LEDGER" set-status "$IDX" b deferred >/dev/null; check "set-status ok" 0 $?
python3 "$LEDGER" set-status "$IDX" nope adopted >/dev/null 2>&1; check "set-status unknown id fails" 1 $?
python3 "$LEDGER" set-status "$IDX" b banana >/dev/null 2>&1; check "set-status bad status fails" 1 $?

python3 -c "
import json; d=json.load(open('$IDX'))
assert [e['id'] for e in d['entries']] == ['a','b','c','d'], d
assert d['entries'][1]['status'] == 'deferred'
assert d['entries'][3]['supersedes'] == 'c'
"
check "ledger grew append-only with statuses intact" 0 $?

# --- set-status to rejected requires metadata (b is currently deferred, no maturity) ---
python3 "$LEDGER" set-status "$IDX" b rejected >/dev/null 2>&1; check "bare rejected transition fails" 1 $?
python3 "$LEDGER" set-status "$IDX" b rejected "too immature" "one blog post only" >/dev/null 2>&1
check "rejected transition without maturity on maturity-less entry fails" 1 $?
python3 "$LEDGER" set-status "$IDX" b rejected "too immature" "one blog post only" emerging >/dev/null
check "rejected transition with full metadata ok" 0 $?
python3 -c "
import json; d=json.load(open('$IDX'))
b = [e for e in d['entries'] if e['id']=='b'][0]
assert b['status'] == 'rejected' and b['reason'] == 'too immature', b
assert b['evidence'] == 'one blog post only' and b['maturity'] == 'emerging', b
assert 'rejected_at' in b, b
"
check "rejection metadata written to entry" 0 $?

# --- known view carries the significant-change fields ---
python3 "$LEDGER" known "$IDX" | python3 -c "
import json, sys; v=json.load(sys.stdin)
assert all('title' in e and 'source' in e for e in v), v
rej = [e for e in v if e['status']=='rejected']
assert rej and all('reason' in e and 'evidence' in e for e in rej), v
"
check "known view includes title/source (+reason/evidence for rejected)" 0 $?

echo "scout-ledger-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
