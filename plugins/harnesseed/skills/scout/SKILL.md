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
