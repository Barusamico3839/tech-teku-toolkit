# Harnesseed P5 "pull + learn + meta-harness" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship `/harnesseed:pull` (upstream absorption via staged 3-way merge that can never corrupt the seedling), the learn/ trio, the meta-harness canon distilled from real bootstrap logs, and the v1.0.0 version.

**Architecture:** Spec §10. A deterministic staging helper (`skills/pull/stage-merge.sh`) does the dangerous parts: `stage` merges each stem-overlaid file (mine=stem / base=roots / theirs=new blueprint) into `.pull-staging/merged/` (git-ignored — seedling tracked files never touched until finalize), `finalize` refuses unresolved markers then applies roots replacement + merged stem + regenerated planted.json as ONE commit with the pull trailer (which is exactly what the P4 checker's protected-path rule expects). The skill wraps it with Step 0 seed update (plugin update + installPath resolution for theirs) and Step 1 upstream manifest verification; conflicts are resolved conversationally between stage and finalize; leftover staging is detected on the next run (discard or resume).

**Tech Stack:** bash+git merge-file+python helper, fixture tests, SKILL.md, markdown canon/learn docs.

## Global Constraints

- Repo root: `/home/hikaru/projects/personal/tech-teku-toolkit-dev/tech-teku-toolkit`, branch `harnesseed`. Never push.
- **Version bump**: blueprint changes (meta-harness.md) ⇒ plugin.json `0.4.0` → `1.0.0`; manifest regenerated after.
- All-or-nothing rule: no partial application — roots/planted/stem land in ONE commit carrying `Harnesseed-Event: pull` + `Seed-Version` (single-paragraph trailers). Partial states live only in git-ignored `.pull-staging/`.
- `${CLAUDE_PLUGIN_ROOT}` is NOT used to fetch theirs (it points at the old version right after update) — resolve the new cache via `installed_plugins.json` installPath. This is the documented exception (spec §3判断1).
- meta-harness.md must cite real bootstrap-log files by path (no invented build history).
- Commit trailer: `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`. Tests wired into run-all.

## Tasks

### Task 1: Staging merge helper — TDD
`plugins/harnesseed/skills/pull/stage-merge.sh` with `stage <seedling> <new-blueprint>` (precondition: clean tree, no leftover staging; exit 0 clean / 2 conflicts / 1 abort) and `finalize <seedling> <new-blueprint>` (refuse markers; replace roots, overlay merged stem, regenerate planted.json from the new blueprint walk, drop staging, single pull-trailer commit). `tests/pull-merge-tests.sh` fixtures: clean merge preserves personalization + absorbs upstream change + checker passes post-finalize; conflict → exit 2 with seedling tracked files byte-identical; dirty tree abort; leftover staging abort (resume detection); finalize-with-markers abort.

### Task 2: `/harnesseed:pull` SKILL.md
Step 0 seed update (`claude plugin marketplace update` + `claude plugin update harnesseed`, resolve new installPath from installed_plugins.json, restart advice at the end); Step 1 upstream verification (marketplace cache is a git clone: compare the new cache's blueprint/manifest.json against `git show <gitCommitSha>:plugins/harnesseed/blueprint/manifest.json` from the marketplace origin; refuse pull when unverifiable); Step 2-4 wrap stage-merge.sh with conversational conflict resolution; new blueprint/trend-stock items become bundled-candidates (via ledger.py), not merges; leftover staging → discard/resume choice. Validate plugin.

### Task 3: learn/ trio + README update
`learn/how-it-works.md` (literal mechanisms incl. how updates are noticed), `learn/glossary.md` (4 words + literal table + metaphor derivation + 3-harnesseed-dirs), `learn/bootstrap-case-study.md` (reading order for docs/bootstrap-log as a case study); learn/README.md links them; repo README "Coming" section becomes "Shipped".

### Task 4: meta-harness.md canon + v1.0.0
`blueprint/meta-harness.md` distilled from the REAL logs (cites 2026-06-18 trend-scout-0 / critique-1 / 2026-07-13 critique-2 / p1-critique-3 by path); bump plugin.json to 1.0.0; regenerate manifest; version-bump-check green; full suite green.

## Deferred verification (hikaru, later)
- Acceptance §11-P5-1..5 live chain (marketplace update → plugin update → restart → pull) — the merge mechanics are covered by fixture tests; the update chain needs the real CLI/session. Negative no-op case (blueprint-only change without bump) is CI-covered by version-bump-check.
