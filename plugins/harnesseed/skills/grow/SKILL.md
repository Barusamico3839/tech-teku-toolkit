---
name: grow
description: Use when the user wants to apply improvements to their harness (/harnesseed:grow), asks to act on scout/checkup findings, or wants their seedling to evolve. Propose→approve→apply with the deterministic invariants gate (auto-revert), advisory behavior scenarios, scope-restriction allowlist, per-run cap, and condition-triggered drift review.
---

# /harnesseed:grow — governed self-improvement

Requires a germinated seedling. Paths:

```bash
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
BP="${CLAUDE_PLUGIN_ROOT}/blueprint"
CHECKER="$SEEDLING/roots/evals/check-invariants.sh"   # ALWAYS run the roots/ copy, never the cache copy
```

## Stage 0 — blueprint integrity gate (every run, before anything else)

Compare the live cache against what this seedling absorbed:

```bash
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
BP="${CLAUDE_PLUGIN_ROOT}/blueprint"
python3 - "$BP" "$SEEDLING" "${CLAUDE_PLUGIN_ROOT}" <<'PY'
import hashlib, json, os, sys
bp, s, plug = sys.argv[1], sys.argv[2], sys.argv[3]
planted = json.load(open(os.path.join(s, "planted.json")))
cache_ver = json.load(open(os.path.join(plug, ".claude-plugin/plugin.json")))["version"]
walked = {}
for dp, _, fns in os.walk(bp):
    for fn in sorted(fns):
        rel = os.path.relpath(os.path.join(dp, fn), bp)
        walked[rel] = hashlib.sha256(open(os.path.join(dp, fn), "rb").read()).hexdigest()
if cache_ver != planted["seed_version"]:
    sys.exit(f"PULL-FIRST: installed seed v{cache_ver} != absorbed v{planted['seed_version']} — "
             "run /harnesseed:pull before growing (grow must not run against an unabsorbed canon).")
if walked != planted["blueprint"]:
    sys.exit("TAMPER-STOP: plugin cache blueprint differs from planted.json at the SAME version — "
             "tamper suspected. Hard stop; reinstall the plugin. Do NOT proceed.")
print("blueprint integrity OK")
PY
```

Two branches, never confused: version newer → **pull誘導して中断** (legitimate update);
same version but hash mismatch → **tamper hard-stop** (no reinstall = no grow).
Then pin the checker itself before trusting it:

```bash
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
python3 - "$SEEDLING" <<'PY'
import hashlib, json, os, sys
s = sys.argv[1]
planted = json.load(open(os.path.join(s, "planted.json")))
rel = "evals/check-invariants.sh"
got = hashlib.sha256(open(os.path.join(s, "roots", rel), "rb").read()).hexdigest()
if planted["blueprint"].get(rel) != got:
    sys.exit("TAMPER-STOP: roots checker does not match planted.json — do not run it.")
print("checker pinned OK")
PY
```

## Stage 1 — propose (structured deltas only)

Sources, in priority order: drift-review findings (checkups/) → checkup gaps → adopted scout
stock (trend-stock/) → the user's own observations. Each proposal is a **structured delta**
(ACE discipline — never a wholesale rewrite):

```
{ target: <path>, change: <the exact delta>, evidence: <observed fact / stock id>,
  rationale: <why this improves the harness>, regression_risk: <what could get worse> }
```

Screen every proposal against the 5 anti-patterns (instruction bloat / 矛盾 / over-specificity /
prompt theater / cargo-cult) — drop or shrink offenders, note the screening in growth-log.

**Behavior baseline (advisory):** run the 3 scenarios in `roots/evals/scenarios.md` against the
current stem (subagent per scenario) and keep the answers for Stage 3 comparison.

**Allowlist routing** (spec §9 — default-deny closure: anything not listed below is app source
code and absolutely off-limits):

| target | route |
|---|---|
| `stem/` | freely editable — the main growth surface |
| `trend-stock/index.json` (append/status via ledger.py), `trend-stock/*-scout-*.md`・`checkups/` (new files), `growth-log.md` (append) | append-only surfaces |
| `trend-stock/summary.md` regen・growth-log rotation | governed operation (approval + 1 commit) |
| `planted.json`・`roots/` | NEVER from grow (germination/pull only — the checker enforces the trailer rule) |
| user/project harness settings (`settings.json`, CLAUDE.md, `.mcp.json`, hooks…) | **diff proposal only** — user applies by hand. Mechanically flag any diff that loosens permissions/hooks and highlight it in Stage 2 |
| `blueprint/` cache・any project's app source | absolutely never |

## Stage 2 — approve (human gate, one proposal at a time)

Per proposal show: the delta, evidence, rationale, regression risk, anti-pattern screening
result, and (when scenario baselines exist) the advisory verdict. Keep `roots/invariants.md`
visible (quote the relevant hard rule when a proposal skirts one). **Per-run cap: at most 5
approved-and-applied proposals**; queue the rest for the next run. Nothing un-decided is applied.

## Stage 3 — apply (1 proposal = 1 commit, deterministic gate, auto-revert)

For each approved proposal:

```bash
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
CHECKER="$SEEDLING/roots/evals/check-invariants.sh"
# 1. apply the delta to the seedling working tree (allowlist surfaces only)
# 2. append the growth-log entry (date, technique-id, target, decision) — append ONLY
# 3. single commit with single-paragraph trailers:
git -C "$SEEDLING" add -A
git -C "$SEEDLING" commit -q -m "grow: <short description>" \
  -m "Harnesseed-Event: grow
Technique-Id: <id>
Source: <scout|checkup|drift-review|user>
Seed-Version: $(python3 -c "import json;print(json.load(open('$SEEDLING/planted.json'))['seed_version'])")
Evidence: <one line>"
# 4. deterministic gate — THE only auto-revert trigger:
if ! bash "$CHECKER" "$SEEDLING"; then
  git -C "$SEEDLING" revert -q --no-edit HEAD
  # record the auto-revert in growth-log (append) in a follow-up commit, then STOP this proposal
fi
```

After the batch: re-run the 3 behavior scenarios against the new stem, judge 前後比較
(改善/同等/劣化 per scenario), append the verdicts to growth-log — **advisory only**; a 劣化
verdict becomes a 却下推奨 shown at the NEXT Stage 2, never an automatic revert.

## Stage 4 — drift review (condition-triggered, criteria in roots/drift-review.md)

Fire when ≥10 proposals applied since the last review, or 90 days elapsed (count from
growth-log + the newest `checkups/*drift-review*` date). Follow `roots/drift-review.md`:
aggregate growth-log+trailers, summarize the cumulative roots↔stem diff, rescreen the whole
stem against the 5 anti-patterns. Save `checkups/YYYY-MM-DD-drift-review.md`, commit with
`Harnesseed-Event: drift-review` trailer. Findings feed the next Stage 1 — drift review itself
edits nothing.
