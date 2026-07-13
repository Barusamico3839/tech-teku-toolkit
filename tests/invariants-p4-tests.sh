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

# ===== fixture 2: heading-ful canon (skeleton, revert-pair, rejected-metadata) =====
S2="$TMP/seedling2"
G2() { git -C "$S2" -c user.email=t@t -c user.name=t "$@"; }
mkdir -p "$S2/roots" "$S2/stem" "$S2/trend-stock"
printf '# Alpha\ncanon body\n## Beta\nmore\n' > "$S2/roots/philosophy.md"
H2="$(python3 -c "import hashlib;print(hashlib.sha256(open('$S2/roots/philosophy.md','rb').read()).hexdigest())")"
printf '{"seed_version":"1.0.1","planted_at":"2026-07-13","blueprint":{"philosophy.md":"%s"}}' "$H2" > "$S2/planted.json"
printf '{"entries":[]}' > "$S2/trend-stock/index.json"
git -C "$S2" init -q
G2 add -A
G2 commit -q -m "germinate: v1.0.1" -m "Harnesseed-Event: germinate
Seed-Version: 1.0.1"
bash "$CHK" "$S2" >/dev/null; check "baseline without stem philosophy passes (never existed)" 0 $?

printf '# Alpha\nmy take\n## Beta\nmine\n## Mine\nextra\n' > "$S2/stem/philosophy.md"
G2 add -A; G2 commit -q -m "grow: personalize" -m "Harnesseed-Event: grow"
bash "$CHK" "$S2" >/dev/null; check "stem keeping canon headings + additions passes" 0 $?

printf '## Mine\nonly mine now\n' > "$S2/stem/philosophy.md"
G2 add -A; G2 commit -q -m "bad: drop canon headings" -m "Harnesseed-Event: grow"
bash "$CHK" "$S2" >/dev/null 2>&1; check "stem losing canon headings fails" 1 $?
G2 reset -q --hard HEAD~1

rm "$S2/stem/philosophy.md"
G2 add -A; G2 commit -q -m "bad: delete stem philosophy" -m "Harnesseed-Event: grow"
bash "$CHK" "$S2" >/dev/null 2>&1; check "stem philosophy deletion fails (existed in history)" 1 $?
G2 reset -q --hard HEAD~1

# --- auto-revert pair nets to zero ---
printf 'e1\n' > "$S2/growth-log.md"; G2 add -A; G2 commit -q -m "grow: e1" -m "Harnesseed-Event: grow"
printf 'e2\n' >> "$S2/growth-log.md"; G2 add -A; G2 commit -q -m "grow: e2" -m "Harnesseed-Event: grow"
G2 revert --no-edit HEAD >/dev/null 2>&1
bash "$CHK" "$S2" >/dev/null; check "auto-revert pair passes (net-zero tree)" 0 $?
printf 'revert note\n' >> "$S2/growth-log.md"; G2 add -A; G2 commit -q -m "grow: note revert" -m "Harnesseed-Event: grow"
bash "$CHK" "$S2" >/dev/null; check "append after revert passes" 0 $?

# --- deferred->rejected metadata addition (sole immutability exception) ---
python3 -c "
import json; p='$S2/trend-stock/index.json'; d=json.load(open(p))
d['entries'].append({'id':'x','title':'X','status':'deferred','source':'s','registered_at':'2026-07-13','maturity':'emerging'})
json.dump(d, open(p,'w'), indent=1)"
G2 add -A; G2 commit -q -m "scout: defer x" -m "Harnesseed-Event: scout"
python3 -c "
import json; p='$S2/trend-stock/index.json'; d=json.load(open(p))
e = d['entries'][0]; e['status']='rejected'; e['reason']='immature'; e['evidence']='single blog'; e['rejected_at']='2026-07-13'
json.dump(d, open(p,'w'), indent=1)"
G2 add -A; G2 commit -q -m "scout: reject x" -m "Harnesseed-Event: scout"
bash "$CHK" "$S2" >/dev/null; check "deferred->rejected metadata addition passes" 0 $?
python3 -c "
import json; p='$S2/trend-stock/index.json'; d=json.load(open(p))
d['entries'][0]['reason']='REWRITTEN'
json.dump(d, open(p,'w'), indent=1)"
G2 add -A; G2 commit -q -m "bad: rewrite rejection reason" -m "Harnesseed-Event: scout"
bash "$CHK" "$S2" >/dev/null 2>&1; check "rewriting existing rejected metadata fails" 1 $?
G2 reset -q --hard HEAD~1

# --- add-only record surfaces (checkups/, scout run details) ---
mkdir -p "$S2/checkups"
printf 'report body\n' > "$S2/checkups/2026-07-14-checkup.md"
G2 add -A; G2 commit -q -m "checkup" -m "Harnesseed-Event: checkup"
bash "$CHK" "$S2" >/dev/null; check "new checkup report passes" 0 $?
printf 'edited later\n' >> "$S2/checkups/2026-07-14-checkup.md"
G2 add -A; G2 commit -q -m "bad: edit past checkup" -m "Harnesseed-Event: grow"
bash "$CHK" "$S2" >/dev/null 2>&1; check "modifying a past checkup fails" 1 $?
G2 reset -q --hard HEAD~1
# a spacer commit so the delete is NOT adjacent to the add (an adjacent add+delete
# is tree-identical to an auto-revert pair and intentionally passes as net zero)
printf 'spacer\n' >> "$S2/growth-log.md"
G2 add -A; G2 commit -q -m "grow: spacer" -m "Harnesseed-Event: grow"
rm "$S2/checkups/2026-07-14-checkup.md"
G2 add -A; G2 commit -q -m "bad: delete past checkup" -m "Harnesseed-Event: grow"
bash "$CHK" "$S2" >/dev/null 2>&1; check "deleting a past checkup (non-adjacent) fails" 1 $?
G2 reset -q --hard HEAD~1
printf 'run detail\n' > "$S2/trend-stock/2026-07-14-scout-1.md"
G2 add -A; G2 commit -q -m "scout: run detail" -m "Harnesseed-Event: scout"
bash "$CHK" "$S2" >/dev/null; check "new scout detail passes" 0 $?
printf 'revised\n' >> "$S2/trend-stock/2026-07-14-scout-1.md"
G2 add -A; G2 commit -q -m "bad: edit scout detail" -m "Harnesseed-Event: grow"
bash "$CHK" "$S2" >/dev/null 2>&1; check "modifying a past scout detail fails" 1 $?
G2 reset -q --hard HEAD~1
printf 'r2\n' > "$S2/checkups/2026-07-14-checkup-2.md"
G2 add -A; G2 commit -q -m "checkup 2" -m "Harnesseed-Event: checkup"
G2 revert --no-edit HEAD >/dev/null 2>&1
bash "$CHK" "$S2" >/dev/null; check "checkup auto-revert pair still passes" 0 $?

echo "invariants-p4-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
