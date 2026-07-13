---
name: checkup
description: Use when the user asks for a harness health check (/harnesseed:checkup), wants to know what's missing in their Claude Code setup, or asks "is my harness configured well?". Read-only diagnosis of settings/plugins/MCP/CLAUDE.md against the 12-category canon checklist; produces a ranked gap report in the seedling. Never modifies anything.
---

# /harnesseed:checkup — harness health check (read-only)

Requires a germinated seedling (`${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed`). If missing, point the user to `/harnesseed:harness` and stop.

Checkup **changes nothing**: the only write in this whole procedure is the report file and its
seedling commit. Recommendations are applied later via `/harnesseed:grow` proposals or by the
user's own hands — never here.

## 1. Collect the machine-readable facts

```bash
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
python3 "${CLAUDE_PLUGIN_ROOT}/skills/checkup/collect.py" "$CFG" "$PROJECT_ROOT"
```

The collector returns key names, counts and booleans only (it never prints configuration
values). Treat its JSON as the factual backbone of the report.

## 2. Walk the canon checklist

Read `$SEEDLING/roots/checkup-checklist.md` (12 categories). For each category:

- Start from the collector facts. Do targeted Reads only where a probe needs detail
  (e.g. the actual deny rules in settings.json for category 6, the global CLAUDE.md length
  for category 3, `.mcp.json` server names for category 5). Read-only, always.
- For big environments you MAY fan out one subagent per category group (read-only tools) —
  optional; sequential inline is fine.
- Judge **present / partial / absent** and record the evidence (file + key/section you saw).
  No evidence, no judgment — write "unknown (probe found nothing)" rather than guessing.
- Category 8 includes the Dynamic Workflow availability probe — record its result; the scout
  skill's degrade path decision uses it.

## 3. Rank the gaps

Order by impact × fix cost. Every recommendation must cite the observed fact it fixes
(e.g. "permissions.deny is empty → add deny rules for .env/secrets — category 6, absent").
Recommendations that touch host settings are labeled: 「適用は /harnesseed:grow の提案経由か、
あなたの手で」.

## 4. Save the report into the seedling (one commit)

Write `$SEEDLING/checkups/YYYY-MM-DD-checkup.md`:
category table (verdict + evidence) → gap ranking → collector JSON snapshot (as-is, it is
secret-free). If a checkup for today already exists, suffix `-2`, `-3`, ….

```bash
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
git -C "$SEEDLING" add checkups && git -C "$SEEDLING" commit -q -m "checkup: $(date +%F)" \
  -m "Harnesseed-Event: checkup
Seed-Version: $(python3 -c "import json;print(json.load(open('$SEEDLING/planted.json'))['seed_version'])")"
```

## 5. Present

Give the user the category table and the top gaps conversationally; point at the saved report.
Offer: 「この gap を /harnesseed:grow の提案として流しますか？(P4)」
