#!/usr/bin/env bash
# P4 extension of check-invariants.sh: git-history checks on fixture seedlings.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHK="$ROOT/plugins/harnesseed/blueprint/evals/check-invariants.sh"
PASS=0; FAIL=0
check() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 (expected $2 got $3)"; fi; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
S="$TMP/seedling"
G() { git -C "$S" -c user.email=t@t -c user.name=t "$@"; }

# --- build a valid germinated seedling ---
mkdir -p "$S/roots" "$S/stem" "$S/trend-stock"
printf 'canon\n' > "$S/roots/philosophy.md"
H="$(python3 -c "import hashlib;print(hashlib.sha256(open('$S/roots/philosophy.md','rb').read()).hexdigest())")"
printf '{"seed_version":"0.4.0","planted_at":"2026-07-13","blueprint":{"philosophy.md":"%s"}}' "$H" > "$S/planted.json"
printf '{"entries":[{"id":"a","title":"A","status":"bundled","source":"s","registered_at":"2026-07-13"}]}' > "$S/trend-stock/index.json"
git -C "$S" init -q
G add -A
G commit -q -m "germinate: seedling from seed v0.4.0" -m "Harnesseed-Event: germinate
Seed-Version: 0.4.0"

bash "$CHK" "$S" >/dev/null; check "germinated baseline passes" 0 $?

# --- growth-log append-only ---
printf 'entry1\n' > "$S/growth-log.md"
G add -A; G commit -q -m "grow: e1" -m "Harnesseed-Event: grow"
printf 'entry2\n' >> "$S/growth-log.md"
G add -A; G commit -q -m "grow: e2" -m "Harnesseed-Event: grow"
bash "$CHK" "$S" >/dev/null; check "growth-log append passes" 0 $?
printf 'REWRITTEN\nentry2\n' > "$S/growth-log.md"
G add -A; G commit -q -m "grow: bad rewrite" -m "Harnesseed-Event: grow"
bash "$CHK" "$S" >/dev/null 2>&1; check "growth-log rewrite fails" 1 $?
G reset -q --hard HEAD~1

# --- index.json monotonicity ---
python3 -c "
import json; p='$S/trend-stock/index.json'; d=json.load(open(p))
d['entries'].append({'id':'b','title':'B','status':'adopted','source':'s','registered_at':'2026-07-13'})
json.dump(d, open(p,'w'), indent=1)"
G add -A; G commit -q -m "grow: add entry" -m "Harnesseed-Event: grow"
bash "$CHK" "$S" >/dev/null; check "index append passes" 0 $?

python3 -c "
import json; p='$S/trend-stock/index.json'; d=json.load(open(p))
d['entries'] = [e for e in d['entries'] if e['id'] != 'a']
json.dump(d, open(p,'w'), indent=1)"
G add -A; G commit -q -m "bad: delete entry" -m "Harnesseed-Event: grow"
bash "$CHK" "$S" >/dev/null 2>&1; check "index entry deletion fails" 1 $?
G reset -q --hard HEAD~1

python3 -c "
import json; p='$S/trend-stock/index.json'; d=json.load(open(p))
d['entries'][0]['title'] = 'MUTATED'
json.dump(d, open(p,'w'), indent=1)"
G add -A; G commit -q -m "bad: mutate title" -m "Harnesseed-Event: grow"
bash "$CHK" "$S" >/dev/null 2>&1; check "index non-status mutation fails" 1 $?
G reset -q --hard HEAD~1

python3 -c "
import json; p='$S/trend-stock/index.json'; d=json.load(open(p))
d['entries'][0]['status'] = 'deferred'
json.dump(d, open(p,'w'), indent=1)"
G add -A; G commit -q -m "grow: status change" -m "Harnesseed-Event: grow"
bash "$CHK" "$S" >/dev/null; check "index status-only change passes" 0 $?

# --- protected paths require germinate/pull trailer ---
printf 'tampered planted' > "$S/planted.json"
G add -A; G commit -q -m "bad: touch planted without trailer"
bash "$CHK" "$S" >/dev/null 2>&1; check "planted.json change without pull trailer fails" 1 $?
G reset -q --hard HEAD~1

printf 'new canon\n' > "$S/roots/philosophy.md"
python3 -c "
import hashlib, json
h = hashlib.sha256(open('$S/roots/philosophy.md','rb').read()).hexdigest()
d = json.load(open('$S/planted.json')); d['blueprint']['philosophy.md'] = h; d['seed_version'] = '0.5.0'
json.dump(d, open('$S/planted.json','w'), indent=1)"
G add -A; G commit -q -m "pull: absorb v0.5.0" -m "Harnesseed-Event: pull
Seed-Version: 0.5.0"
bash "$CHK" "$S" >/dev/null; check "roots+planted change WITH pull trailer passes" 0 $?

# --- linear history ---
G checkout -q -b side HEAD~1
printf 'side\n' > "$S/stem/note.md"
G add -A; G commit -q -m "side work"
G checkout -q master 2>/dev/null || G checkout -q main
G merge -q --no-ff -m "merge side" side 2>/dev/null
bash "$CHK" "$S" >/dev/null 2>&1; check "merge commit (non-linear history) fails" 1 $?

echo "invariants-p4-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
