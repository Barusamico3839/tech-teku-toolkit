# tech-teku-toolkit 🌳

[![tests](https://github.com/Barusamico3839/tech-teku-toolkit/actions/workflows/test.yml/badge.svg)](https://github.com/Barusamico3839/tech-teku-toolkit/actions/workflows/test.yml)

Tech-Teku's toolkit of Claude Code **harness** plugins, distributed as one marketplace.

## harnesseed 🌱

A harness-engineering framework that is itself built and grown by harness engineering.
Install the seed, germinate a **seedling**, articulate your harness **philosophy** in conversation,
and keep a **vetted stock** of the latest harness-engineering trends.

### Install

```
/plugin marketplace add Barusamico3839/tech-teku-toolkit
/plugin install harnesseed@tech-teku-toolkit
```

Open any project: the SessionStart nudge asks once —
「🌱 このプロジェクトを Harnesseed でハーネスしますか？」— or run `/harnesseed:harness` yourself.
Saying no writes `.harnesseed/declined` and it never asks that project again.

### Glossary — the only 4 words you need

| word | literally | metaphor |
|---|---|---|
| **tree** | this GitHub repo (main = hikaru only; friends send PRs) | the mature tree |
| **seed** | the installable plugin `plugins/harnesseed/` (carries `blueprint/`, the canon) | a scattered seed |
| **seedling** | your growing instance: the git repo at `~/.claude/harnesseed/` | the sprouted plant |
| **stem** | the personalization overlay `stem/` inside your seedling | the growing stalk |

Supporting words: **blueprint** (canon carried by the seed) / **roots** (pristine canon copy inside
your seedling — the merge base for upstream pulls) / **leaf** (`.harnesseed/leaf.json`, the
per-project marker). Germination happens **once**; further projects just get a leaf.

Three directories named "harnesseed", and what each is:

| path | what it is |
|---|---|
| `plugins/harnesseed/` | the seed — distributed plugin (this repo) |
| `~/.claude/harnesseed/` | your seedling — user-level git repo, grows across projects |
| `.harnesseed/` (in a project) | the leaf marker — per-user, add it to `.gitignore` |

Note: `~/.claude/` in this README means `${CLAUDE_CONFIG_DIR:-~/.claude}` — if you have set
`CLAUDE_CONFIG_DIR`, your seedling lives at `$CLAUDE_CONFIG_DIR/harnesseed/`.

### What germination creates

A git-backed seedling: `planted.json` (which seed version you absorbed + canon hashes),
`roots/` (pristine canon), `stem/` (your overlay, grown from the philosophy conversation),
`trend-stock/` (a living ledger seeded with the bundled trend-scout #0 — 14 vetted items).
Everything is inspectable: `git -C ~/.claude/harnesseed log`.

### Governance in one paragraph

Changes to your harness flow one way: scout/checkup **propose**, you **approve**, grow **applies**
(1 change = 1 audited commit, max 5 per run, deterministic invariants gate with automatic revert).
`roots/` and `planted.json` are written only by germination and `/harnesseed:pull`.
Harnesseed is **tamper-evident, not tamper-proof** — the canon ships inside a writable plugin
cache, so integrity is enforced by hash checks against your seedling's records, not by isolation.
v1 never edits your host settings: proposals touching `settings.json`/`CLAUDE.md` are emitted as
diffs for you to apply by hand.

### The five commands

`/harnesseed:harness` (germinate / attach) · `/harnesseed:scout` (automated,
adversarially-verified trend research) · `/harnesseed:checkup` (12-category harness health
check, read-only) · `/harnesseed:grow` (propose→approve→apply with Misevolution governance
and automatic revert) · `/harnesseed:pull` (staged 3-way merge of upstream canon — your stem
survives, and an interrupted pull can never corrupt the seedling).

### Migrating from brainstorm-harness (removed)

Migrating from brainstorm-harness? It is gone. If you had it installed:

```
claude plugin uninstall brainstorm-harness@tech-teku-toolkit
```

If an `enabledPlugins` entry lingers, remove it from `~/.claude/settings.json` manually.

### Learn

`plugins/harnesseed/learn/` is the study entrance; `plugins/harnesseed/docs/bootstrap-log/` is the
primary record of Harnesseed building itself (design critiques, trend scouting) — readable as a
case study in harness engineering.

_Design spec & rationale: `plugins/harnesseed/docs/specs/`._
