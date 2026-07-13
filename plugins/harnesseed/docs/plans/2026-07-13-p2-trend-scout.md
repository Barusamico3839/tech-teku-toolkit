# Harnesseed P2 "trend-scout" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `/harnesseed:scout` — automated, adversarially-verified trend research whose results flow through a conversation approval gate into the seedling's append-only trend-stock ledger.

**Architecture:** Three stages per spec §7: (1) an autonomous research Dynamic Workflow the skill composes at runtime (attempt-and-degrade to subagent fan-out, then sequential), (2) conversational approval, (3) deterministic apply via a shipped ledger helper (`ledger.py`) that enforces the append-only/supersede rules, one seedling commit per run. Angle definitions and quality guardrails live in the canon (`blueprint/scout-angles.md`) so they ride pull updates.

**Tech Stack:** Markdown SKILL.md, Python 3 stdlib helper, bash tests, Dynamic Workflow (JS) template embedded in the skill.

## Global Constraints

- Repo root: `/home/hikaru/projects/personal/tech-teku-toolkit-dev/tech-teku-toolkit`, branch `harnesseed`. Never push.
- **Version bump**: P2 changes blueprint/ ⇒ `plugin.json` version goes `0.1.0` → `0.2.0` in the same commit as the first blueprint change; regenerate `blueprint/manifest.json` AFTER the bump (manifest embeds seed_version).
- Ledger rules (spec §5/§7, enforced by ledger.py): entry set only grows; existing entries immutable except `status`; `rejected` requires reason/maturity/evidence; `supersedes` must reference an existing id; statuses are exactly {bundled, adopted, rejected, deferred}.
- Dedup rule: known ids (bundled/adopted/rejected) are never re-proposed as new; `deferred` IS re-presented next run; `rejected` may return only as an "update proposal" citing significant change (criteria in scout-angles.md).
- Python 3 stdlib only. Commit trailer: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- Tests at repo-root `tests/`; run everything with `bash tests/run-all.sh`.

---

### Task 1: Version bump + blueprint/scout-angles.md (canon)

**Files:**
- Modify: `plugins/harnesseed/.claude-plugin/plugin.json` (version `0.1.0` → `0.2.0`)
- Create: `plugins/harnesseed/blueprint/scout-angles.md`
- Regenerate: `plugins/harnesseed/blueprint/manifest.json`

**Interfaces:**
- Produces: canon consumed at runtime by the scout skill from `roots/scout-angles.md`; "significant change" criteria consumed by the dedup rules.

- [ ] **Step 1: Bump the version**

```bash
python3 - <<'EOF'
import json
p = 'plugins/harnesseed/.claude-plugin/plugin.json'
d = json.load(open(p)); assert d['version'] == '0.1.0', d['version']
d['version'] = '0.2.0'
json.dump(d, open(p, 'w'), indent=2, ensure_ascii=False); open(p, 'a').write('\n')
EOF
```

- [ ] **Step 2: Write blueprint/scout-angles.md**

```markdown
# Scout Angles（trend-scout の調査アングル正典）

/harnesseed:scout の Stage 1 はこのファイルを roots/ から読み、アングルごとに調査を fan-out する。
方法論の一次資料: `docs/bootstrap-log/2026-06-18-trend-scout-0.md` §4。

## アングル定義（4本）

### A — Claude Code プラットフォーム機能（ハーネスを BUILD する側）
新機能・仕様変更・非推奨化。effective queries: "claude code <feature> 2026" /
"code.claude.com docs <topic>" / changelog・min-version アノテーション。
canonical target: `code.claude.com/docs/en/<page>`（llms.txt を index に）。

### B — Agentic coding / context engineering パターン
spec-driven / verification loops / memory / subagent orchestration / worktree 並列。
effective queries: "context engineering <year>" / "agent verification loop" /
"spec driven development claude"。

### C — エコシステム / コミュニティ動向
人気プラグイン・marketplace 動向・規約の収束。install/star 数は snapshot として扱う
（~2.5週で ~10% drift する実測あり）。高 star curated list を信頼 entry point に。

### D — 自己改善 / meta-agent 研究
self-improving agents / eval gaming / memory 研究。arXiv ID を必ず控える
（ID の日付整合が recency の sanity check になる）。

## 出典規律（load-bearing claim の条件）

- 数値・固有主張は primary/named source のみ: official docs、arXiv ID、GitHub repo、公式 blog。
- SEO/aggregator/Medium は maturity signal 扱い。load-bearing に使わない。
- 行単位で再検証できない数値は `~` を付けて保持する。
- 各 claim に verdict を付ける: confirmed / partly-confirmed / uncorroborated。
  uncorroborated を採用候補の根拠にしない。

## Tier スコアリング

Tier = 未導入度 × Harnesseed/ユーザーへの直接効果 × 検証の堅さ。
Tier 1 = 未導入明示 or 中核に直結、confirmed。Tier 2 = 直結・研究 confirmed。Tier 3 = 規約・運用の候補。

## 「有意変化」の判定基準（却下済み項目の再浮上条件）

maturity の順序: emerging < growing < mainstream。以下のいずれかで「有意変化」とみなし、
却下済み項目を supersede 付き更新提案として再提示できる:
1. maturity が却下時から 1 段階以上進んだ
2. 却下時に無かった種類の primary source が出現した（例: 公式 docs 掲載、arXiv 論文化、GA リリース）
3. 却下理由そのものが解消された（却下エントリの reason フィールドと突き合わせて判断）

変化が無い却下項目は再提示しない。deferred（保留）は無条件で次回再提示する。
```

- [ ] **Step 3: Regenerate manifest and verify**

Run: `bash scripts/blueprint-manifest.sh generate && bash scripts/blueprint-manifest.sh verify`
Expected: `manifest.json written (6 files, seed_version 0.2.0)` then `manifest verify: OK`

- [ ] **Step 4: Commit, then verify the bump rule against the previous commit**

```bash
git add plugins/harnesseed/.claude-plugin/plugin.json plugins/harnesseed/blueprint
git commit -m "feat: scout angles canon + seed version 0.2.0"
bash tests/version-bump-check.sh HEAD~1
```
Expected: commit succeeds; check prints `blueprint changed and version bumped (0.1.0 -> 0.2.0): OK`

---

### Task 2: Ledger helper (skills/scout/ledger.py) — TDD

**Files:**
- Create: `plugins/harnesseed/skills/scout/ledger.py`
- Create: `tests/scout-ledger-tests.sh`

**Interfaces:**
- Produces: `python3 ledger.py known <index.json>` → compact JSON array of `{id,status,maturity?,registered_at?,supersedes?}` for dedup. `python3 ledger.py append <index.json> <entry.json>` → validates + appends (exit 1 with message on violation). `python3 ledger.py set-status <index.json> <id> <status>` → in-place status-only mutation. Consumed by scout SKILL.md Stage 1 (known) and Stage 3 (append/set-status).

- [ ] **Step 1: Write the failing test**

```bash
cat > tests/scout-ledger-tests.sh <<'EOF'
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

echo "scout-ledger-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
EOF
chmod +x tests/scout-ledger-tests.sh
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/scout-ledger-tests.sh`
Expected: FAIL (ledger.py not found)

- [ ] **Step 3: Implement ledger.py**

```bash
mkdir -p plugins/harnesseed/skills/scout
cat > plugins/harnesseed/skills/scout/ledger.py <<'EOF'
#!/usr/bin/env python3
"""Deterministic guardian of the seedling's trend-stock ledger (index.json).

Commands:
  known <index.json>                  print JSON array of known entries (dedup view)
  append <index.json> <entry.json>    validate + append a NEW entry
  set-status <index.json> <id> <st>   update ONLY the status field of an entry

Rules (spec paths: docs/specs/2026-07-13-harnesseed-v1-design.md section 5/7):
entry set only grows; existing entries are immutable except `status`;
`rejected` requires reason/maturity/evidence; `supersedes` must reference an
existing id; statuses are exactly bundled|adopted|rejected|deferred.
"""
import json
import sys

STATUSES = {"bundled", "adopted", "rejected", "deferred"}
REQUIRED = {"id", "title", "status", "source", "registered_at"}
REJECTED_REQUIRED = {"reason", "maturity", "evidence"}


def load(path):
    with open(path) as f:
        return json.load(f)


def save(path, data):
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def cmd_known(path):
    view = []
    for e in load(path)["entries"]:
        item = {"id": e["id"], "status": e["status"]}
        for k in ("maturity", "registered_at", "supersedes"):
            if k in e:
                item[k] = e[k]
        view.append(item)
    print(json.dumps(view, ensure_ascii=False))


def cmd_append(path, entry_path):
    data = load(path)
    entry = load(entry_path)
    missing = REQUIRED - set(entry)
    if missing:
        sys.exit(f"append rejected: missing fields {sorted(missing)}")
    if entry["status"] not in STATUSES:
        sys.exit(f"append rejected: bad status {entry['status']!r}")
    if entry["status"] == "rejected":
        rmissing = REJECTED_REQUIRED - set(entry)
        if rmissing:
            sys.exit(f"append rejected: rejected entry missing {sorted(rmissing)}")
    ids = {e["id"] for e in data["entries"]}
    if entry["id"] in ids:
        sys.exit(f"append rejected: id {entry['id']!r} already exists "
                 "(existing entries are immutable; supersede with a new id)")
    if "supersedes" in entry and entry["supersedes"] not in ids:
        sys.exit(f"append rejected: supersedes unknown id {entry['supersedes']!r}")
    data["entries"].append(entry)
    save(path, data)
    print(f"appended {entry['id']} ({entry['status']})")


def cmd_set_status(path, eid, status):
    if status not in STATUSES:
        sys.exit(f"set-status rejected: bad status {status!r}")
    data = load(path)
    for e in data["entries"]:
        if e["id"] == eid:
            old = e["status"]
            e["status"] = status
            save(path, data)
            print(f"{eid}: {old} -> {status}")
            return
    sys.exit(f"set-status rejected: unknown id {eid!r}")


def main():
    argv = sys.argv
    if len(argv) == 3 and argv[1] == "known":
        cmd_known(argv[2])
    elif len(argv) == 4 and argv[1] == "append":
        cmd_append(argv[2], argv[3])
    elif len(argv) == 5 and argv[1] == "set-status":
        cmd_set_status(argv[2], argv[3], argv[4])
    else:
        sys.exit(__doc__)


main()
EOF
chmod +x plugins/harnesseed/skills/scout/ledger.py
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/scout-ledger-tests.sh`
Expected: `scout-ledger-tests: 12 passed, 0 failed`

- [ ] **Step 5: Commit**

```bash
git add plugins/harnesseed/skills/scout/ledger.py tests/scout-ledger-tests.sh
git commit -m "feat: append-only trend-stock ledger helper with validation tests"
```

---

### Task 3: `/harnesseed:scout` skill (SKILL.md)

**Files:**
- Create: `plugins/harnesseed/skills/scout/SKILL.md`

**Interfaces:**
- Consumes: `roots/scout-angles.md` (Task 1), `ledger.py` (Task 2), seedling layout from P1 (`planted.json`, `trend-stock/index.json`, git repo).
- Produces: scout run outputs — `trend-stock/YYYY-MM-DD-scout-N.md` + ledger entries + one seedling commit with trailers `Harnesseed-Event: scout` / `Seed-Version` / `Scout-Run`.

- [ ] **Step 1: Write SKILL.md**

````markdown
---
name: scout
description: Use when the user asks to scout the latest harness-engineering trends (/harnesseed:scout), wants the trend stock refreshed, or asks "what's new in harness engineering". Runs autonomous multi-angle research with adversarial verification, then a conversational approve gate, then appends decisions to the seedling's trend-stock ledger.
---

# /harnesseed:scout — vetted trend research

Requires a germinated seedling (`${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed`). If missing, point the user to `/harnesseed:harness` and stop.

Paths for this run:

```bash
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
ANGLES="$SEEDLING/roots/scout-angles.md"       # canon (from your absorbed seed version)
INDEX="$SEEDLING/trend-stock/index.json"
LEDGER="${CLAUDE_PLUGIN_ROOT}/skills/scout/ledger.py"
KNOWN_JSON="$(python3 "$LEDGER" known "$INDEX")"
RUN_DATE=<today YYYY-MM-DD>; RUN_ID="scout-$RUN_DATE"
```

## Stage 1 — autonomous research (approval gate is a STAGE BOUNDARY, never mid-run)

Preferred: compose and launch a Dynamic Workflow from this template (adapt paths/args; pass
`KNOWN_JSON` and the angles file path via `args` — workflow scripts cannot read files themselves):

```js
export const meta = {
  name: 'harnesseed-scout',
  description: 'Fan out 4 research angles, adversarially verify claims, dedup, return candidates',
  phases: [{ title: 'Research' }, { title: 'Verify' }],
}
const A = typeof args === 'string' ? JSON.parse(args) : args   // {anglesPath, known, runDate}
const CANDIDATES_SCHEMA = { type: 'object', required: ['candidates'], properties: {
  candidates: { type: 'array', items: { type: 'object',
    required: ['id', 'title', 'tier', 'maturity', 'source', 'summary', 'verdict'],
    properties: {
      id: { type: 'string', description: 'kebab-case slug' },
      title: { type: 'string' }, tier: { type: 'number' },
      maturity: { type: 'string', enum: ['emerging', 'growing', 'mainstream'] },
      source: { type: 'string', description: 'primary/named source' },
      summary: { type: 'string' }, verdict: { type: 'string', enum: ['confirmed', 'partly-confirmed'] },
      updates_known_id: { type: 'string', description: 'set when this is an update proposal for a known entry' },
    } } } } }
const VERIFY_SCHEMA = { type: 'object', required: ['verdict', 'reason'], properties: {
  verdict: { type: 'string', enum: ['confirmed', 'partly-confirmed', 'uncorroborated'] },
  reason: { type: 'string' }, correctedSummary: { type: 'string' } } }
phase('Research')
const ANGLE_KEYS = ['A-platform', 'B-patterns', 'C-ecosystem', 'D-self-improvement']
const results = await pipeline(
  ANGLE_KEYS,
  key => agent(
    `あなたは trend-scout。まず ${A.anglesPath} を読み、担当アングル「${key}」の定義・クエリ例・出典規律に従って調査せよ。` +
    `WebSearch を 4〜8 本 fan-out し、primary source を WebFetch で読み込むこと(ToolSearchで両ツールをロード)。` +
    `既知エントリ(dedup対象): ${JSON.stringify(A.known)} — bundled/adopted/rejected の id は新規候補にしない。` +
    `ただし既知項目に有意変化(maturity進行・新primary source)を見つけたら updates_known_id 付きで返せ。` +
    `rejected の再浮上は有意変化がある場合のみ。今日は ${A.runDate}。候補は最大6件、Tier順。`,
    { label: `angle:${key}`, phase: 'Research', schema: CANDIDATES_SCHEMA }
  ),
  (res, key) => parallel((res?.candidates || []).map(c => () =>
    agent(
      `敵対的検証者として、この trend claim を反証せよ: 「${c.title}」(source: ${c.source})\n要約: ${c.summary}\n` +
      `primary source を自分で WebFetch して確かめ、誇張・陳腐化・出典不一致を探せ。確認できなければ uncorroborated。`,
      { label: `verify:${c.id}`, phase: 'Verify', schema: VERIFY_SCHEMA }
    ).then(v => ({ ...c, verify: v }))))
)
const all = results.filter(Boolean).flat().filter(Boolean)
return { candidates: all.filter(c => c.verify.verdict !== 'uncorroborated'),
         dropped: all.filter(c => c.verify.verdict === 'uncorroborated').map(c => c.id) }
```

**Degrade path 1** (Workflow tool unavailable/errors): run the same fan-out with 4 parallel
general-purpose subagents via the Agent tool (one per angle, same prompts), then verify
candidates with parallel skeptic subagents.
**Degrade path 2** (no subagents either): sequential inline WebSearch → WebFetch → self-verify,
angle by angle. Always report which path ran.

## Stage 2 — conversational approval

Present `trend-stock/summary.md` first if it exists, then the candidates tier by tier:
title, maturity, source, verified summary, and whether it updates a known entry.
For each: 採用 / 却下(理由を聞く) / 保留. Never apply anything the user did not decide.

## Stage 3 — deterministic apply (one seedling commit)

Write the run detail file `trend-stock/$RUN_DATE-scout-N.md` (N = 1 + count of existing files
that date): per candidate — decision, verified summary, sources, verify verdict.
Then for each decision, build an entry JSON and apply via the ledger helper (it enforces the rules):

```bash
# adopted:  {"id","title","status":"adopted","source","registered_at":"$RUN_DATE","maturity","tier"}
# rejected: + "reason" (user's words), "maturity", "evidence" (verified summary)
# deferred: status "deferred"  |  update of known entry: new id "<old>-r2" + "supersedes":"<old id>"
python3 "$LEDGER" append "$INDEX" /tmp/entry.json
# resolution of a previously deferred entry: python3 "$LEDGER" set-status "$INDEX" <id> adopted|rejected
git -C "$SEEDLING" add trend-stock && git -C "$SEEDLING" commit -m "scout: $RUN_DATE run" \
  -m "Harnesseed-Event: scout" -m "Scout-Run: $RUN_ID" \
  -m "Seed-Version: $(python3 -c "import json;print(json.load(open('$SEEDLING/planted.json'))['seed_version'])")"
```

If `trend-stock/summary.md` is stale or missing, offer to regenerate it (bounded: Tier-grouped,
adopted+bundled entries only, one line each) in the same commit.
````

- [ ] **Step 2: Validate**

Run: `claude plugin validate plugins/harnesseed`
Expected: Validation passed

- [ ] **Step 3: Commit**

```bash
git add plugins/harnesseed/skills/scout/SKILL.md
git commit -m "feat: /harnesseed:scout skill (research workflow, approve gate, ledger apply)"
```

---

### Task 4: Wire scout tests into CI runner

**Files:**
- Modify: `tests/run-all.sh` (add scout-ledger suite)

**Interfaces:**
- Consumes: `tests/scout-ledger-tests.sh` (Task 2).

- [ ] **Step 1: Add the suite to run-all.sh**

In `tests/run-all.sh`, after the line `bash "$ROOT/tests/invariants-tests.sh"`, insert:

```bash
bash "$ROOT/tests/scout-ledger-tests.sh"
```

- [ ] **Step 2: Run the full suite**

Run: `bash tests/run-all.sh`
Expected: all suites pass, ending `ALL TEST SUITES PASSED`

- [ ] **Step 3: Commit**

```bash
git add tests/run-all.sh
git commit -m "ci: scout ledger suite in run-all"
```

---

## Deferred verification (hikaru, later)

- Live scout run (Stage 1 with real WebSearch/WebFetch, Stage 2 approval, Stage 3 commit) — acceptance §11-P2-1..5. The workflow degrade path (P2-5, disableWorkflows) also needs a live session.
- These are recorded in the P2 section of `.superpowers/sdd/progress.md` as deferred.
