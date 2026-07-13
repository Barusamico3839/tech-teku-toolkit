---
name: harness
description: Use when the user agrees to harness this project with Harnesseed (or asks to). Germinates the seedling on first use (roots + stem), attaches a leaf to this project, runs the philosophy conversation, and registers the bundled trend stock. Idempotent; also handles explicit decline.
---

# /harnesseed:harness — germinate / attach

Terms: **seedling** = the git repo at `${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed` (whole thing).
**stem/** = the personalization overlay inside it. **roots/** = the pristine canon copy — NEVER edit it here.

## 0. Resolve paths and state

```bash
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
BP="${CLAUDE_PLUGIN_ROOT}/blueprint"
SEED_VERSION="$(python3 -c "import json;print(json.load(open('${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json'))['version'])")"
```

- If the user said **no**: write the opt-out marker and stop —
  `mkdir -p .harnesseed && touch .harnesseed/declined`, offer adding `.harnesseed/` to `.gitignore` (see step 4), and confirm we will never nudge again here.
- If an ancestor directory already has `.harnesseed/leaf.json`, this project is already harnessed — say so and stop (no nested germination).

## 1. Germinate once, attach every time

**If `$SEEDLING/planted.json` exists** (seedling already germinated): skip to step 4 (leaf only).
Additionally, if `$SEED_VERSION` differs from `seed_version` in `planted.json`, do NOT touch `roots/` or `planted.json` — tell the user a newer seed is installed and suggest `/harnesseed:pull` (roots/planted are written only by germination and pull).

**Else germinate:**

```bash
mkdir -p "$SEEDLING" && cd "$SEEDLING" && git init -q
mkdir -p roots stem trend-stock checkups
cp -R "$BP/." roots/
python3 - "$BP" "$SEEDLING" "$SEED_VERSION" <<'PY'
import hashlib, json, os, sys, datetime
bp, s, ver = sys.argv[1], sys.argv[2], sys.argv[3]
files = {}
for dp, _, fns in os.walk(bp):
    for fn in sorted(fns):
        rel = os.path.relpath(os.path.join(dp, fn), bp)
        if rel == "manifest.json": continue
        files[rel] = hashlib.sha256(open(os.path.join(dp, fn), "rb").read()).hexdigest()
json.dump({"seed_version": ver,
           "planted_at": datetime.date.today().isoformat(),
           "blueprint": dict(sorted(files.items()))},
          open(os.path.join(s, "planted.json"), "w"), indent=2, ensure_ascii=False)
PY
printf '.pull-staging/\n' > .gitignore
```

Then register the bundled stock ledger:

```bash
python3 - "$SEEDLING" <<'PY'
import json, os, sys, datetime
s = sys.argv[1]
seed = json.load(open(os.path.join(s, "roots/trend-stock/index-seed.json")))
today = datetime.date.today().isoformat()
entries = [{**e, "status": "bundled", "registered_at": today} for e in seed["entries"]]
json.dump({"entries": entries}, open(os.path.join(s, "trend-stock/index.json"), "w"),
          indent=2, ensure_ascii=False)
PY
```

Self-check, then the germination commit (single commit, required trailer):

```bash
bash "$SEEDLING/roots/evals/check-invariants.sh" "$SEEDLING"
cd "$SEEDLING" && git add -A && git commit -q -m "germinate: seedling from seed v$SEED_VERSION" \
  -m "Harnesseed-Event: germinate" -m "Seed-Version: $SEED_VERSION"
```

## 2. Make it visible (first-time teaching moment)

Show the user, briefly and warmly: where the seedling lives, the tree/seed/seedling/stem glossary
(one line each), what roots vs stem means (pristine canon vs their overlay), and that everything is
a git repo they can inspect (`git -C "$SEEDLING" log`).

## 3. Philosophy conversation (never from a blank page)

Read `roots/philosophy.md`. For each stance, ask: 「Harnesseed はこう考える —（要約）。賛成？反対？修正する？」
Write the personalized result to `stem/philosophy.md`, **keeping every heading of the canon**
(add under headings; do not delete headings — P4's invariant checks heading-set inclusion).
Commit: `git -C "$SEEDLING" add stem && git -C "$SEEDLING" commit -q -m "stem: personalize philosophy" -m "Harnesseed-Event: personalize"`

## 4. Attach the leaf to this project

```bash
mkdir -p .harnesseed
python3 - "$SEEDLING" <<'PY'
import json, os, sys
s = sys.argv[1]
ver = json.load(open(os.path.join(s, "planted.json")))["seed_version"]
json.dump({"harnesseed": True, "seed_version": ver}, open(".harnesseed/leaf.json", "w"))
PY
```

The leaf stores **no paths** (the seedling location is always derived) and records the seed_version
the seedling actually absorbed (from planted.json, not the live plugin).
`.harnesseed/` is per-user state: offer to append `.harnesseed/` to the project's `.gitignore`
(committed leaves/declines break teammates' nudges), and explain why in one sentence.

## 5. Present the trend stock

Show `trend-stock/index.json` (14 bundled entries from trend-scout #0) tier by tier, and where the
full writeup lives (`roots/trend-stock/2026-06-18-trend-scout-0.md`). Mention `/harnesseed:scout`
(P2) will keep this stock alive with vetted updates.

## 6. Optional hardening

Offer once: add a permission deny rule for writes to the plugin cache's `blueprint/**`
(tamper-surface reduction; spec §4 step 8). Respect a "no".
