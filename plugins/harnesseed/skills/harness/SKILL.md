---
name: harness
description: Use when the user agrees to harness this project with Harnesseed (or asks to). Germinates the seedling on first use (roots + stem), attaches a leaf to this project, runs the philosophy conversation, and registers the bundled trend stock. Idempotent; also handles explicit decline.
---

# /harnesseed:harness — germinate / attach

Terms: **seedling** = the git repo at `${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed` (whole thing).
**stem/** = the personalization overlay inside it. **roots/** = the pristine canon copy — NEVER edit it here.

Shell state does not persist between bash blocks: re-derive `PROJECT_ROOT` (and friends) at the
top of every block that uses it. Never `cd` — stay in the project.

## 0. Resolve paths and state

```bash
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
BP="${CLAUDE_PLUGIN_ROOT}/blueprint"
SEED_VERSION="$(python3 -c "import json;print(json.load(open('${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json'))['version'])")"
GERMINATED="$(git -C "$SEEDLING" log --all --grep='Harnesseed-Event: germinate' -1 --format=%H 2>/dev/null || true)"
```

- If the user said **no**: write the opt-out marker at the project root and stop —
  `mkdir -p "$PROJECT_ROOT/.harnesseed" && touch "$PROJECT_ROOT/.harnesseed/declined"`,
  offer adding `.harnesseed/` to `.gitignore` (see step 4), and confirm we will never nudge again here.
- If `$PROJECT_ROOT/.harnesseed/leaf.json` (or an ancestor's) already exists, this project is
  already harnessed — say so and stop (no nested germination, no duplicate leaf).
- `$GERMINATED` (a germinate commit) is the idempotence sentinel — NOT the mere existence of
  `planted.json`. A seedling directory without that commit is a crashed half-germination:
  re-run germination from scratch (overwriting roots/planted/index is safe — nothing was committed).

## 1. Germinate once, attach every time

**If `$GERMINATED` is non-empty** (seedling exists):
- If `$SEED_VERSION` differs from `seed_version` in `$SEEDLING/planted.json`, do NOT touch
  `roots/` or `planted.json` — tell the user a newer seed is installed and suggest
  `/harnesseed:pull` (roots/planted are written only by germination and pull).
- Self-check the seedling: `bash "$SEEDLING/roots/evals/check-invariants.sh" "$SEEDLING"` and
  confirm `trend-stock/index.json` exists. On failure, treat the seedling as broken and offer
  to re-germinate instead of attaching.
- Then do ONLY step 4 (attach the leaf, including the `.gitignore` offer), tell the user
  「既存の seedling にこのプロジェクトの葉を追加しました」, and STOP — do NOT run steps 2-3
  or 5-6 (no philosophy re-run, no trend-stock presentation, no hardening re-offer).

**Else germinate:**

```bash
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
BP="${CLAUDE_PLUGIN_ROOT}/blueprint"
SEED_VERSION="$(python3 -c "import json;print(json.load(open('${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json'))['version'])")"
mkdir -p "$SEEDLING/roots" "$SEEDLING/stem" "$SEEDLING/trend-stock" "$SEEDLING/checkups"
git -C "$SEEDLING" init -q
python3 - "$BP" "$SEEDLING" "$SEED_VERSION" <<'PY'
import hashlib, json, os, sys, datetime
bp, s, ver = sys.argv[1], sys.argv[2], sys.argv[3]
walked = {}
for dp, _, fns in os.walk(bp):
    for fn in sorted(fns):
        rel = os.path.relpath(os.path.join(dp, fn), bp)
        walked[rel] = hashlib.sha256(open(os.path.join(dp, fn), "rb").read()).hexdigest()
# Integrity gate: the cache must match its shipped manifest exactly (both directions:
# hash mismatches, missing files, AND rogue additions), and the manifest's seed_version
# must match plugin.json. Otherwise a tampered cache would become the trusted baseline.
manifest = json.load(open(os.path.join(bp, "manifest.json")))
no_manifest = {k: v for k, v in walked.items() if k != "manifest.json"}
if no_manifest != manifest["files"] or manifest.get("seed_version") != ver:
    sys.exit("ABORT germination: blueprint cache does not match its manifest "
             "(tamper or broken release). Reinstall the plugin and retry.")
tmp = os.path.join(s, "planted.json.tmp")
with open(tmp, "w") as f:
    json.dump({"seed_version": ver,
               "planted_at": datetime.date.today().isoformat(),
               "blueprint": dict(sorted(walked.items()))},  # includes manifest.json
              f, indent=2, ensure_ascii=False)
os.replace(tmp, os.path.join(s, "planted.json"))
PY
cp -R "$BP/." "$SEEDLING/roots/"
printf '.pull-staging/\n' > "$SEEDLING/.gitignore"
```

Then register the bundled stock ledger and its curated summary view (atomic writes):

```bash
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
python3 - "$SEEDLING" <<'PY'
import json, os, sys, datetime
s = sys.argv[1]
seed = json.load(open(os.path.join(s, "roots/trend-stock/index-seed.json")))
today = datetime.date.today().isoformat()
entries = [{**e, "status": "bundled", "registered_at": today} for e in seed["entries"]]
tmp = os.path.join(s, "trend-stock/index.json.tmp")
with open(tmp, "w") as f:
    json.dump({"entries": entries}, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp, os.path.join(s, "trend-stock/index.json"))
lines = ["# trend-stock summary (curated view)", ""]
for tier in (1, 2, 3):
    items = [e for e in entries if e.get("tier") == tier]
    if items:
        lines.append(f"## Tier {tier}")
        lines += [f"- {e['id']}: {e['title']}" for e in items] + [""]
with open(os.path.join(s, "trend-stock/summary.md"), "w") as f:
    f.write("\n".join(lines) + "\n")
PY
```

Self-check, then the germination commit (single commit; the trailers form ONE final paragraph
so git parses them as machine-readable trailers — keep the literal newline inside the quotes):

```bash
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
SEED_VERSION="$(python3 -c "import json;print(json.load(open('${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json'))['version'])")"
bash "$SEEDLING/roots/evals/check-invariants.sh" "$SEEDLING"
git -C "$SEEDLING" add -A
git -C "$SEEDLING" commit -q -m "germinate: seedling from seed v$SEED_VERSION" \
  -m "Harnesseed-Event: germinate
Seed-Version: $SEED_VERSION"
```

## 2. Make it visible (first-time teaching moment)

Show the user, briefly and warmly: where the seedling lives, the tree/seed/seedling/stem glossary
(one line each), what roots vs stem means (pristine canon vs their overlay), and that everything is
a git repo they can inspect (`git -C "$SEEDLING" log`).

## 3. Philosophy conversation (never from a blank page)

Read `$SEEDLING/roots/philosophy.md`. For each stance, ask: 「Harnesseed はこう考える —（要約）。賛成？反対？修正する？」
Write the personalized result to `$SEEDLING/stem/philosophy.md`, **keeping every heading of the canon**
(add under headings; do not delete headings — P4's invariant checks heading-set inclusion).
Commit (same single-paragraph trailer form):

```bash
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
git -C "$SEEDLING" add stem && git -C "$SEEDLING" commit -q -m "stem: personalize philosophy" \
  -m "Harnesseed-Event: personalize"
```

## 4. Attach the leaf to this project

```bash
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
mkdir -p "$PROJECT_ROOT/.harnesseed"
python3 - "$SEEDLING" "$PROJECT_ROOT" <<'PY'
import json, os, sys
s, root = sys.argv[1], sys.argv[2]
ver = json.load(open(os.path.join(s, "planted.json")))["seed_version"]
tmp = os.path.join(root, ".harnesseed", "leaf.json.tmp")
with open(tmp, "w") as f:
    json.dump({"harnesseed": True, "seed_version": ver}, f)
os.replace(tmp, os.path.join(root, ".harnesseed", "leaf.json"))
PY
```

The leaf lives at the PROJECT ROOT (matching the hook's upward search), stores **no paths**
(the seedling location is always derived) and records the seed_version the seedling actually
absorbed (from planted.json, not the live plugin).
`.harnesseed/` is per-user state: offer to append `.harnesseed/` to the project's `.gitignore`
(committed leaves/declines break teammates' nudges), and explain why in one sentence.

## 5. Present the trend stock

Show `$SEEDLING/trend-stock/summary.md` (curated view), mention the full ledger
(`trend-stock/index.json`, 14 bundled entries from trend-scout #0) and where the full writeup
lives (`roots/trend-stock/2026-06-18-trend-scout-0.md`). Mention `/harnesseed:scout` keeps this
stock alive with vetted updates.

## 6. Optional hardening (diff only — never applied by harnesseed)

Offer once: show the user a settings diff adding a permission deny rule for writes to the plugin
cache's `blueprint/**` (tamper-surface reduction). **The user applies it by hand if they want it**
— harnesseed itself never writes `~/.claude/settings.json`. Respect a "no".
