# Harnesseed P1 "First Sprout" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **注（実装後スナップショット）**: 本プランは実装時の設計図。クリティーク#3（P1実装レビュー）の修正で、実装は本プランのコード例と一部異なる（発芽時のmanifest照合ゲート、コミットtrailerの単一段落化、マーカーのプロジェクトルート書き込み等）。**差異は実装が正**。

**Goal:** Ship the harnesseed seed (plugin) inside the tech-teku-toolkit marketplace: SessionStart nudge → `/harnesseed:harness` germination → git-backed seedling (roots/stem/leaf) → philosophy conversation → bundled trend-stock #0, plus complete brainstorm-harness removal.

**Architecture:** One plugin (`plugins/harnesseed/`) carrying its canon (`blueprint/`). A detect-and-inject SessionStart hook (pure bash, file checks only), a `/harnesseed:harness` skill that creates the user-level seedling git repo at `${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed/`, and deterministic CI (JSON parse, manifest hash verify, hook unit tests, version-bump consistency). Spec: `plugins/harnesseed/docs/specs/2026-07-13-harnesseed-v1-design.md` (rev.2).

**Tech Stack:** Bash (hook, checkers, tests), Python 3 stdlib only (hashing/JSON — no jq dependency), Claude Code plugin conventions (plugin.json / marketplace.json / hooks.json / SKILL.md), GitHub Actions.

## Global Constraints

- Working dir = repo root: `/home/hikaru/projects/personal/tech-teku-toolkit-dev/tech-teku-toolkit` (branch `harnesseed`). **Never push; never merge to main** — hikaru approves those.
- Seed version の正は `plugins/harnesseed/.claude-plugin/plugin.json` の `version`。P1 は `0.1.0`。`blueprint/VERSION` ファイルは作らない。
- blueprint/ に差分を入れたタスクは必ず `bash scripts/blueprint-manifest.sh generate` でマニフェストを更新してからコミットする。
- Hook script: no network, no `git` invocation, no `jq`. File reads + bash string ops only.
- Paths inside seedling docs/specs are **seedling-root relative**. Seedling path is always derived as `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed` — never stored in leaf.json.
- Commit style: conventional prefix, English subject (existing repo style), trailer `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.
- Do not touch `toolkit-production/`. Do not reference brainstorm-harness as a design source (it is being deleted).
- Tests live at repo-root `tests/` (not shipped in the seed). Run all: `bash tests/run-all.sh`.

---

### Task 1: Scaffold harnesseed plugin manifest + marketplace entry

**Files:**
- Create: `plugins/harnesseed/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

**Interfaces:**
- Produces: plugin name `harnesseed` (→ commands namespace `/harnesseed:<cmd>`), seed version `0.1.0` consumed by hook/skill/manifest tooling.

- [ ] **Step 1: Write plugin.json**

```json
{
  "name": "harnesseed",
  "version": "0.1.0",
  "description": "A harness-engineering framework that is itself built and grown by harness engineering. Germinate a seedling, articulate your harness philosophy, and keep a vetted stock of the latest harness trends.",
  "author": { "name": "hikaru" },
  "homepage": "https://github.com/Barusamico3839/tech-teku-toolkit",
  "repository": "https://github.com/Barusamico3839/tech-teku-toolkit",
  "license": "MIT"
}
```

- [ ] **Step 2: Replace the plugins array in marketplace.json**

Full new content of `.claude-plugin/marketplace.json`:

```json
{
  "name": "tech-teku-toolkit",
  "owner": { "name": "hikaru" },
  "metadata": {
    "description": "Tech-Teku's toolkit of Claude Code harness plugins.",
    "version": "0.2.0"
  },
  "plugins": [
    {
      "name": "harnesseed",
      "source": "./plugins/harnesseed",
      "description": "Self-growing harness engineering: germinate a seedling, evolve your philosophy, stock vetted trends."
    }
  ]
}
```

- [ ] **Step 3: Verify both parse**

Run: `python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); json.load(open('plugins/harnesseed/.claude-plugin/plugin.json')); print('ok')"`
Expected: `ok`

- [ ] **Step 4: Commit**

```bash
git add .claude-plugin/marketplace.json plugins/harnesseed/.claude-plugin/plugin.json
git commit -m "feat: scaffold harnesseed plugin manifest, single marketplace entry"
```

---

### Task 2: Remove brainstorm-harness from the repo

**Files:**
- Delete: `plugins/brainstorm-harness/` (all), `install/` (all)
- Delete (untracked local): `.superpowers/sdd/`

**Interfaces:**
- Produces: repo with harnesseed as the only plugin. README/CI still reference brainstorm after this task — they are rewritten in Tasks 11/12 (acceptance §11-P1-6 is checked there).

- [ ] **Step 1: Delete tracked brainstorm files**

```bash
git rm -r -q plugins/brainstorm-harness install
```

- [ ] **Step 2: Delete local-only residue**

```bash
rm -rf .superpowers/sdd
```

- [ ] **Step 3: Verify nothing else references the deleted paths in functional surfaces**

Run: `grep -rn "brainstorm" .claude-plugin/ plugins/harnesseed/ 2>/dev/null | grep -v docs/ ; echo "exit=$?"`
Expected: `exit=1` (no matches outside docs history)

- [ ] **Step 4: Commit**

```bash
git commit -m "chore: remove brainstorm-harness plugin and install scripts"
```

---

### Task 3: Migrate legacy harnesseed docs into the plugin

**Files:**
- Create: `plugins/harnesseed/docs/specs/2026-06-18-harnesseed-design.md` (copy)
- Create: `plugins/harnesseed/docs/bootstrap-log/2026-06-18-trend-scout-0.md`, `plugins/harnesseed/docs/bootstrap-log/2026-06-18-design-critique-1.md` (copies)
- Delete (outside repo): `/home/hikaru/projects/personal/tech-teku-toolkit-dev/harnesseed/`

**Interfaces:**
- Produces: `docs/bootstrap-log/2026-06-18-trend-scout-0.md` at the path Task 4 copies into blueprint.

- [ ] **Step 1: Copy the three legacy files**

```bash
SRC=/home/hikaru/projects/personal/tech-teku-toolkit-dev/harnesseed/docs
cp "$SRC/superpowers/specs/2026-06-18-harnesseed-design.md" plugins/harnesseed/docs/specs/
cp "$SRC/bootstrap-log/2026-06-18-trend-scout-0.md" plugins/harnesseed/docs/bootstrap-log/
cp "$SRC/bootstrap-log/2026-06-18-design-critique-1.md" plugins/harnesseed/docs/bootstrap-log/
```

- [ ] **Step 2: Verify and delete the old directory**

```bash
ls plugins/harnesseed/docs/specs/ plugins/harnesseed/docs/bootstrap-log/
rm -rf /home/hikaru/projects/personal/tech-teku-toolkit-dev/harnesseed
```
Expected: both old (2026-06-18) and new (2026-07-13) docs listed; old dir gone.

- [ ] **Step 3: Commit**

```bash
git add plugins/harnesseed/docs
git commit -m "docs: migrate legacy harnesseed spec and bootstrap logs into the plugin"
```

---

### Task 4: Blueprint static canon — invariants.md, trend-stock #0, index-seed.json

**Files:**
- Create: `plugins/harnesseed/blueprint/invariants.md`
- Create: `plugins/harnesseed/blueprint/trend-stock/2026-06-18-trend-scout-0.md` (copy)
- Create: `plugins/harnesseed/blueprint/trend-stock/index-seed.json`

**Interfaces:**
- Produces: `index-seed.json` — array of `{id, title, tier, source}`; the harness skill (Task 10) turns each entry into a living-ledger entry `{id, title, tier, source, status:"bundled", registered_at}` in the seedling's `trend-stock/index.json`.

- [ ] **Step 1: Write invariants.md**

```markdown
# Harnesseed Invariants（統治のハードルール・正典）

これは人間可読の hard rules。決定的な検査は `evals/check-invariants.sh` が行い、
grow の apply コミットはこのゲートに失敗すると自動 git revert される（P4 で全項目が有効化）。
Harnesseed は tamper-proof を主張しない。ここにあるのは「grow パイプラインからは編集禁止であり、
パイプライン外の改竄も必ず検知される（tamper-evident）」という契約である。

## 編集サーフェス（allowlist・default-deny）

| 区分 | 対象 |
|---|---|
| 自由に編集可 | `stem/` |
| 追記のみ可 | `trend-stock/index.json`（id 単調増加・既存エントリは status 以外書換禁止）・`trend-stock/*-scout-*.md`（新規追加のみ）・`checkups/`（新規追加のみ）・`growth-log.md`（追記のみ） |
| governed operation（承認＋1コミット） | `trend-stock/summary.md` 再生成・growth-log の rotation |
| 特定ゲートのみ | `planted.json`・`roots/` — 書けるのは初回発芽と /harnesseed:pull だけ。同一の1コミットで更新する |
| 提案出力のみ（v1 は直接編集しない） | ユーザー級/プロジェクト級ハーネス設定（settings.json・CLAUDE.md・.mcp.json・hooks 等）。permissions/hooks を緩和する diff は提示時に明示ハイライトする |
| 絶対不可 | プラグインキャッシュの `blueprint/`・あらゆるプロジェクトのアプリソースコード |

この列挙は網羅的である。プロジェクトツリー内で列挙されていないパスは
すべて「アプリソースコード」として絶対不可に落ちる（default-deny）。

## ハードルール

1. 1回の grow で適用できる提案は最大 **5件**。
2. 1提案 = seedling repo に1コミット。machine-readable trailer（Technique-Id / Source / Seed-Version / Evidence）必須。
3. 自動 git revert に接続できるのは決定的チェックのみ。LLM-judge の判定は advisory（人間承認の材料）に留める。
4. `planted.json` を変更するコミットは「初回発芽」または「pull」の trailer を持たなければならない。
5. grow は毎 run 冒頭に blueprint 整合検証を行う: plugin version が planted.json より新しい → pull へ誘導して中断。
   version 同一なのに hash 不一致 → tamper 疑いとして hard-stop。
6. 受け入れ基準・invariants・チェッカーを弱める変更は、protected ファイル（planted.json・roots/）への
   diff 検出として機械的に fail する。この規則自体を緩める提案は却下される。
```

- [ ] **Step 2: Copy trend-scout #0 into the blueprint**

```bash
mkdir -p plugins/harnesseed/blueprint/trend-stock
cp plugins/harnesseed/docs/bootstrap-log/2026-06-18-trend-scout-0.md plugins/harnesseed/blueprint/trend-stock/
```

- [ ] **Step 3: Write index-seed.json** (the 14 stock items of #0, Tier order)

```json
{
  "seed_note": "trend-scout #0 (2026-06-18) の優先stockリスト。発芽時に status:'bundled' で living ledger (trend-stock/index.json) へ登録される。",
  "entries": [
    { "id": "misevolution-risk-register", "title": "Misevolution の risk register（trajectory監視・held-out相当のゲート・基準を緩めない hard rule）", "tier": 1, "source": "arXiv:2509.26354" },
    { "id": "awesome-harness-taxonomy-gap", "title": "awesome-harness-engineering ~12カテゴリでの gap 分析", "tier": 1, "source": "ai-boost/awesome-harness-engineering" },
    { "id": "dynamic-workflows-native-runtime", "title": "Dynamic Workflows を native runtime として評価（16並列/1000上限/mid-run入力不可）", "tier": 1, "source": "code.claude.com/docs" },
    { "id": "ace-delta-update", "title": "ACE の Generator-Reflector-Curator + delta-update 規律（丸ごとrewrite禁止）", "tier": 2, "source": "ACE (2025-Q4)" },
    { "id": "sica-overseer-gating", "title": "SICA の overseer + benchmark-gated acceptance", "tier": 2, "source": "SICA" },
    { "id": "dgm-archive-population", "title": "Darwin Gödel Machine の archive/population 戦略（stepping-stone保持・empirical fitness）", "tier": 2, "source": "DGM/DARWIN" },
    { "id": "skill-evolver-scope-restriction", "title": "Skill Evolver の scope-restriction governance（編集面allowlist・per-run上限・anti-pattern screen）", "tier": 2, "source": "Skill Evolver" },
    { "id": "gepa-meta-prompting", "title": "GEPA を meta-prompting engine として採用（DSPy・Pareto frontier）", "tier": 2, "source": "GEPA/DSPy" },
    { "id": "tiered-verification-60-30-10", "title": "Tiered verification loop（60% deterministic / 30% LLM-judge / 10% human）+ failure-log feedback", "tier": 2, "source": "community (2026-Q1/Q2)" },
    { "id": "error-analysis-first", "title": "Hamel Husain の error-analysis-first（投機的 upfront eval に過剰投資しない）", "tier": 3, "source": "Hamel Husain" },
    { "id": "dotfiles-as-code-claude", "title": "Dotfiles-as-code for ~/.claude（fork可能なversion管理repo化）", "tier": 3, "source": "community (2026-Q1)" },
    { "id": "portable-skill-md", "title": "Cross-agent portable SKILL.md 標準", "tier": 3, "source": "community (2026-Q1)" },
    { "id": "aggregator-seo-dedup", "title": "aggregator/SEO dedup（curated list を信頼 entry point に）", "tier": 3, "source": "community" },
    { "id": "proactive-output-style", "title": "Proactive output style を worker baseline に（settings.json outputStyle）", "tier": 3, "source": "Claude Code docs" }
  ]
}
```

- [ ] **Step 4: Verify JSON parses**

Run: `python3 -c "import json; d=json.load(open('plugins/harnesseed/blueprint/trend-stock/index-seed.json')); print(len(d['entries']))"`
Expected: `14`

- [ ] **Step 5: Commit**

```bash
git add plugins/harnesseed/blueprint
git commit -m "feat: blueprint canon — invariants hard rules, bundled trend-scout #0 + index seed"
```

---

### Task 5: Blueprint manifest tooling (generate / verify)

**Files:**
- Create: `scripts/blueprint-manifest.sh`
- Create: `tests/manifest-tests.sh`
- Create (generated): `plugins/harnesseed/blueprint/manifest.json`

**Interfaces:**
- Produces: `bash scripts/blueprint-manifest.sh generate|verify` (exit 0/1). `manifest.json` schema: `{"seed_version": "<plugin.json version>", "files": {"<relpath>": "<sha256>", ...}}` — relpaths are blueprint-root relative, manifest.json itself excluded. Consumed by CI (Task 12), the harness skill (Task 10), and the invariants checker (Task 8).

- [ ] **Step 1: Write the failing test**

```bash
cat > tests/manifest-tests.sh <<'EOF'
#!/usr/bin/env bash
# manifest generate/verify unit tests
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0
check() { # name, expected_exit, actual_exit
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 (expected exit $2, got $3)"; fi
}

bash "$ROOT/scripts/blueprint-manifest.sh" generate; check "generate runs" 0 $?
python3 -c "import json; m=json.load(open('$ROOT/plugins/harnesseed/blueprint/manifest.json')); assert m['files'], 'empty'; assert 'manifest.json' not in m['files']"
check "manifest well-formed, excludes itself" 0 $?
bash "$ROOT/scripts/blueprint-manifest.sh" verify; check "verify passes on fresh manifest" 0 $?

echo "tamper" >> "$ROOT/plugins/harnesseed/blueprint/invariants.md"
bash "$ROOT/scripts/blueprint-manifest.sh" verify >/dev/null 2>&1; check "verify fails on tamper" 1 $?
git -C "$ROOT" checkout -q -- plugins/harnesseed/blueprint/invariants.md
bash "$ROOT/scripts/blueprint-manifest.sh" verify; check "verify passes after restore" 0 $?

echo "manifest-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
EOF
chmod +x tests/manifest-tests.sh
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/manifest-tests.sh`
Expected: FAIL (scripts/blueprint-manifest.sh not found)

- [ ] **Step 3: Implement the tool**

```bash
mkdir -p scripts
cat > scripts/blueprint-manifest.sh <<'EOF'
#!/usr/bin/env bash
# generate|verify plugins/harnesseed/blueprint/manifest.json
# manifest = { "seed_version": <plugin.json version>, "files": { relpath: sha256 } }
set -euo pipefail
MODE="${1:-verify}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - "$MODE" "$ROOT" <<'PY'
import hashlib, json, os, sys
mode, root = sys.argv[1], sys.argv[2]
plug = os.path.join(root, "plugins/harnesseed")
bp = os.path.join(plug, "blueprint")
mf = os.path.join(bp, "manifest.json")
ver = json.load(open(os.path.join(plug, ".claude-plugin/plugin.json")))["version"]
files = {}
for dp, _, fns in os.walk(bp):
    for fn in sorted(fns):
        p = os.path.join(dp, fn)
        rel = os.path.relpath(p, bp)
        if rel == "manifest.json":
            continue
        files[rel] = hashlib.sha256(open(p, "rb").read()).hexdigest()
current = {"seed_version": ver, "files": dict(sorted(files.items()))}
if mode == "generate":
    json.dump(current, open(mf, "w"), indent=2, ensure_ascii=False)
    open(mf, "a").write("\n")
    print(f"manifest.json written ({len(files)} files, seed_version {ver})")
elif mode == "verify":
    recorded = json.load(open(mf))
    if recorded != current:
        for k in sorted(set(recorded.get("files", {})) | set(current["files"])):
            a, b = recorded.get("files", {}).get(k), current["files"].get(k)
            if a != b:
                print(f"MISMATCH {k}: recorded={a} actual={b}")
        if recorded.get("seed_version") != current["seed_version"]:
            print(f"MISMATCH seed_version: recorded={recorded.get('seed_version')} actual={current['seed_version']}")
        sys.exit(1)
    print("manifest verify: OK")
else:
    sys.exit(f"unknown mode {mode}")
PY
EOF
chmod +x scripts/blueprint-manifest.sh
bash scripts/blueprint-manifest.sh generate
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/manifest-tests.sh`
Expected: `manifest-tests: 5 passed, 0 failed`

- [ ] **Step 5: Commit**

```bash
git add scripts/blueprint-manifest.sh tests/manifest-tests.sh plugins/harnesseed/blueprint/manifest.json
git commit -m "feat: blueprint manifest generate/verify tooling with tests"
```

---

### Task 6: Version-bump consistency check

**Files:**
- Create: `tests/version-bump-check.sh`

**Interfaces:**
- Produces: `bash tests/version-bump-check.sh <base-ref>` — exit 1 iff `plugins/harnesseed/blueprint/` differs from base-ref while plugin.json version is unchanged. Consumed by CI (Task 12).

- [ ] **Step 1: Write the script (it is its own test via the cases below)**

```bash
cat > tests/version-bump-check.sh <<'EOF'
#!/usr/bin/env bash
# Fails if blueprint/ changed vs <base-ref> without a plugin.json version bump.
set -euo pipefail
BASE="${1:?usage: version-bump-check.sh <base-ref>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
PLUG=plugins/harnesseed/.claude-plugin/plugin.json
if ! git rev-parse -q --verify "$BASE" >/dev/null; then
  echo "base ref $BASE not found — skipping (first push?)"; exit 0
fi
if git diff --quiet "$BASE"...HEAD -- plugins/harnesseed/blueprint/; then
  echo "no blueprint changes vs $BASE: OK"; exit 0
fi
if ! git cat-file -e "$BASE:$PLUG" 2>/dev/null; then
  echo "plugin.json absent at $BASE (new plugin): OK"; exit 0
fi
old="$(git show "$BASE:$PLUG" | python3 -c "import json,sys;print(json.load(sys.stdin)['version'])")"
new="$(python3 -c "import json;print(json.load(open('$PLUG'))['version'])")"
if [ "$old" = "$new" ]; then
  echo "FAIL: blueprint/ changed vs $BASE but plugin.json version is still $new"
  echo "      (un-bumped releases make 'claude plugin update' a no-op and break /harnesseed:pull)"
  exit 1
fi
echo "blueprint changed and version bumped ($old -> $new): OK"
EOF
chmod +x tests/version-bump-check.sh
```

- [ ] **Step 2: Exercise both branches**

Run: `bash tests/version-bump-check.sh main && bash tests/version-bump-check.sh HEAD`
Expected: first prints `plugin.json absent at main (new plugin): OK` (exit 0); second prints `no blueprint changes vs HEAD: OK`.

- [ ] **Step 3: Commit**

```bash
git add tests/version-bump-check.sh
git commit -m "test: blueprint change requires plugin version bump"
```

---

### Task 7: SessionStart hook — detect and inject

**Files:**
- Create: `plugins/harnesseed/hooks/hooks.json`
- Create: `plugins/harnesseed/hooks/harnesseed-nudge.sh`
- Create: `tests/hook-tests.sh`

**Interfaces:**
- Consumes: `plugins/harnesseed/.claude-plugin/plugin.json` version (Task 1); seedling `planted.json` field `seed_version` (written by Task 10's skill).
- Produces: stdout context injection per the spec §4 state×source matrix. Marker contract consumed by the harness skill: `.harnesseed/leaf.json` / `.harnesseed/declined` at project root.

- [ ] **Step 1: Write hooks.json**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/harnesseed-nudge.sh\"" }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Write the failing tests**

```bash
cat > tests/hook-tests.sh <<'EOF'
#!/usr/bin/env bash
# harnesseed-nudge.sh unit tests: 3 states x sources x subdir x entrypoint x version-skew
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$ROOT/plugins/harnesseed/hooks/harnesseed-nudge.sh"
PASS=0; FAIL=0
run_hook() { # cwd, source, entrypoint -> stdout
  ( cd "$1" && printf '{"source":"%s"}' "$2" | \
    CLAUDE_CODE_ENTRYPOINT="$3" CLAUDE_CONFIG_DIR="$CFG" CLAUDE_PLUGIN_ROOT="$PLUGROOT" bash "$HOOK" )
}
expect() { # name, needle-or-EMPTY, output
  local out="$3"
  if [ "$2" = "EMPTY" ]; then
    [ -z "$out" ] && PASS=$((PASS+1)) || { FAIL=$((FAIL+1)); echo "FAIL: $1 (expected empty, got: $out)"; }
  else
    case "$out" in *"$2"*) PASS=$((PASS+1));; *) FAIL=$((FAIL+1)); echo "FAIL: $1 (missing '$2' in: $out)";; esac
  fi
}

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
CFG="$TMP/claude"; PLUGROOT="$TMP/plug"
mkdir -p "$CFG/harnesseed" "$PLUGROOT/.claude-plugin"
printf '{"name":"harnesseed","version":"0.1.0"}' > "$PLUGROOT/.claude-plugin/plugin.json"

# unharnessed project (git repo)
P1="$TMP/proj1"; mkdir -p "$P1/sub/dir" "$P1/.git"
expect "unharnessed startup nudges"      "/harnesseed:harness" "$(run_hook "$P1" startup cli)"
expect "unharnessed clear nudges"        "/harnesseed:harness" "$(run_hook "$P1" clear cli)"
expect "unharnessed resume silent"       EMPTY                 "$(run_hook "$P1" resume cli)"
expect "unharnessed compact silent"      EMPTY                 "$(run_hook "$P1" compact cli)"
expect "headless sdk silent"             EMPTY                 "$(run_hook "$P1" startup sdk-cli)"
expect "subdir stops at .git boundary"   "/harnesseed:harness" "$(run_hook "$P1/sub/dir" startup cli)"

# declined project
P2="$TMP/proj2"; mkdir -p "$P2/.harnesseed" "$P2/.git"; touch "$P2/.harnesseed/declined"
expect "declined startup silent"         EMPTY                 "$(run_hook "$P2" startup cli)"
expect "declined resume silent"          EMPTY                 "$(run_hook "$P2" resume cli)"

# harnessed project, matching versions
P3="$TMP/proj3"; mkdir -p "$P3/.harnesseed" "$P3/sub" "$P3/.git"
printf '{"harnesseed":true,"seed_version":"0.1.0"}' > "$P3/.harnesseed/leaf.json"
printf '{"seed_version":"0.1.0","planted_at":"2026-07-13"}' > "$CFG/harnesseed/planted.json"
expect "leaf startup pointer"            "harnessed"           "$(run_hook "$P3" startup cli)"
expect "leaf resume pointer (compact rebuild)" "harnessed"     "$(run_hook "$P3" resume cli)"
expect "leaf from subdir finds root"     "harnessed"           "$(run_hook "$P3/sub" startup cli)"
expect "no pull hint when versions match" EMPTY "$(run_hook "$P3" startup cli | grep -o 'harnesseed:pull' || true)"

# version skew -> pull hint
printf '{"seed_version":"0.0.9","planted_at":"2026-07-13"}' > "$CFG/harnesseed/planted.json"
expect "version skew suggests pull"      "/harnesseed:pull"    "$(run_hook "$P3" startup cli)"

echo "hook-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
EOF
chmod +x tests/hook-tests.sh
```

- [ ] **Step 3: Run to verify it fails**

Run: `bash tests/hook-tests.sh`
Expected: FAIL (hook script not found)

- [ ] **Step 4: Implement the hook**

```bash
cat > plugins/harnesseed/hooks/harnesseed-nudge.sh <<'EOF'
#!/usr/bin/env bash
# harnesseed SessionStart hook: detect-and-inject ONLY.
# Hard constraints: no network, no git commands, no jq. Cheap file reads, then exit.
set -u

INPUT="$(cat 2>/dev/null || true)"
SOURCE="$(printf '%s' "$INPUT" | sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
[ -n "$SOURCE" ] || SOURCE="startup"

# Upward marker search from cwd; stop at repo boundary (.git) or filesystem root.
dir="$PWD"; STATE="none"
while :; do
  if [ -e "$dir/.harnesseed/declined" ]; then STATE="declined"; break; fi
  if [ -e "$dir/.harnesseed/leaf.json" ]; then STATE="leaf"; break; fi
  if [ -e "$dir/.git" ] || [ "$dir" = "/" ]; then break; fi
  dir="$(dirname "$dir")"
done

json_field() { # file, key -> first string value
  sed -n 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" 2>/dev/null | head -n1
}

case "$STATE" in
  declined)
    exit 0
    ;;
  leaf)
    SEEDLING="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/harnesseed"
    HINT=""
    PLANTED="$SEEDLING/planted.json"
    PLUGJSON="${CLAUDE_PLUGIN_ROOT:-}/.claude-plugin/plugin.json"
    if [ -f "$PLANTED" ] && [ -f "$PLUGJSON" ]; then
      pv="$(json_field "$PLANTED" seed_version)"
      cv="$(json_field "$PLUGJSON" version)"
      if [ -n "$pv" ] && [ -n "$cv" ] && [ "$pv" != "$cv" ]; then
        HINT=" A newer seed (v$cv) is installed than this seedling absorbed (v$pv) — suggest running /harnesseed:pull."
      fi
    fi
    printf '%s\n' "[harnesseed] This project is harnessed. Seedling: $SEEDLING — read stem/philosophy.md (personal overlay) and trend-stock/summary.md if you need harness context; do NOT load the whole seedling.$HINT"
    exit 0
    ;;
esac

# Unharnessed: nudge only on startup/clear, never in non-interactive runs.
case "$SOURCE" in resume|compact) exit 0 ;; esac
case "${CLAUDE_CODE_ENTRYPOINT:-}" in sdk-*) exit 0 ;; esac
cat <<'NUDGE'
[harnesseed] This project is not harnessed. Suggest /harnesseed:harness to the user and ASK FIRST — never proceed on your own. Ask exactly once, in the user's language, e.g.: "🌱 このプロジェクトを Harnesseed でハーネスしますか？" If the user seems busy with another task, mention it briefly instead of interrupting. If this appears to be a non-interactive run, skip the question entirely and proceed with the task.
NUDGE
exit 0
EOF
chmod +x plugins/harnesseed/hooks/harnesseed-nudge.sh
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bash tests/hook-tests.sh`
Expected: `hook-tests: 13 passed, 0 failed`

- [ ] **Step 6: Commit**

```bash
git add plugins/harnesseed/hooks tests/hook-tests.sh
git commit -m "feat: SessionStart nudge hook with state/source matrix, boundary-aware search, update hint"
```

---

### Task 8: Invariants checker (P1 scope) in blueprint/evals/

**Files:**
- Create: `plugins/harnesseed/blueprint/evals/check-invariants.sh`
- Create: `tests/invariants-tests.sh`
- Modify (regenerate): `plugins/harnesseed/blueprint/manifest.json`

**Interfaces:**
- Produces: `bash check-invariants.sh <seedling-dir>` — exit 0/1. P1 checks: (1) `planted.json` parses and has `seed_version`+`blueprint` hash map; (2) every file recorded in `planted.json.blueprint` exists under `roots/` with a matching sha256. P4 will extend this file (append-only checks, protected-diff, trailer rules) — it ships in blueprint/ from P1 so it rides the manifest/hash governance from day one. Consumed by the harness skill (runs it after germination as a self-check) and P4 grow.

- [ ] **Step 1: Write the failing test**

```bash
cat > tests/invariants-tests.sh <<'EOF'
#!/usr/bin/env bash
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHK="$ROOT/plugins/harnesseed/blueprint/evals/check-invariants.sh"
PASS=0; FAIL=0
check() { if [ "$2" = "$3" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $1 (expected $2 got $3)"; fi; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
S="$TMP/seedling"; mkdir -p "$S/roots"
printf 'canon-content\n' > "$S/roots/philosophy.md"
H="$(python3 -c "import hashlib;print(hashlib.sha256(open('$S/roots/philosophy.md','rb').read()).hexdigest())")"
printf '{"seed_version":"0.1.0","planted_at":"2026-07-13","blueprint":{"philosophy.md":"%s"}}' "$H" > "$S/planted.json"

bash "$CHK" "$S"; check "pristine roots pass" 0 $?
printf 'personalized!\n' >> "$S/roots/philosophy.md"
bash "$CHK" "$S" >/dev/null 2>&1; check "tampered roots fail" 1 $?
printf 'not json' > "$S/planted.json"
bash "$CHK" "$S" >/dev/null 2>&1; check "broken planted.json fails" 1 $?
rm "$S/planted.json"
bash "$CHK" "$S" >/dev/null 2>&1; check "missing planted.json fails" 1 $?

echo "invariants-tests: $PASS passed, $FAIL failed"; [ "$FAIL" = 0 ]
EOF
chmod +x tests/invariants-tests.sh
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/invariants-tests.sh`
Expected: FAIL (checker not found)

- [ ] **Step 3: Implement the checker**

```bash
mkdir -p plugins/harnesseed/blueprint/evals
cat > plugins/harnesseed/blueprint/evals/check-invariants.sh <<'EOF'
#!/usr/bin/env bash
# Deterministic invariants gate. P1 scope: planted.json integrity + roots pristine check.
# P4 extends this file (append-only ledgers, protected-diff, trailer rules).
# Run FROM the seedling's roots/ copy (git-audited), not from the live plugin cache.
set -euo pipefail
SEEDLING="${1:?usage: check-invariants.sh <seedling-dir>}"
python3 - "$SEEDLING" <<'PY'
import hashlib, json, os, sys
s = sys.argv[1]
fail = []
planted_path = os.path.join(s, "planted.json")
try:
    planted = json.load(open(planted_path))
except Exception as e:
    print(f"INVARIANT FAIL: planted.json unreadable: {e}"); sys.exit(1)
if "seed_version" not in planted or "blueprint" not in planted:
    print("INVARIANT FAIL: planted.json missing seed_version/blueprint"); sys.exit(1)
for rel, want in sorted(planted["blueprint"].items()):
    p = os.path.join(s, "roots", rel)
    if not os.path.isfile(p):
        fail.append(f"roots/{rel} missing"); continue
    got = hashlib.sha256(open(p, "rb").read()).hexdigest()
    if got != want:
        fail.append(f"roots/{rel} hash mismatch (roots must stay pristine; only germination/pull may write it)")
if fail:
    print("INVARIANT FAIL:"); [print("  -", f) for f in fail]; sys.exit(1)
print(f"invariants OK (seed_version {planted['seed_version']}, {len(planted['blueprint'])} canon files pristine)")
PY
EOF
chmod +x plugins/harnesseed/blueprint/evals/check-invariants.sh
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/invariants-tests.sh`
Expected: `invariants-tests: 4 passed, 0 failed`

- [ ] **Step 5: Regenerate manifest (blueprint changed) and verify all tests**

Run: `bash scripts/blueprint-manifest.sh generate && bash tests/manifest-tests.sh && bash tests/hook-tests.sh`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add plugins/harnesseed/blueprint tests/invariants-tests.sh
git commit -m "feat: deterministic invariants checker (P1: planted integrity + pristine roots)"
```

---

### Task 9: philosophy.md canon authoring — INTERACTIVE with hikaru

**Files:**
- Create: `plugins/harnesseed/blueprint/philosophy.md`
- Modify (regenerate): `plugins/harnesseed/blueprint/manifest.json`

**Interfaces:**
- Produces: the canon whose **heading skeleton** stem/philosophy.md must preserve (P4 invariant checks heading-set inclusion). Headings below are the proposed skeleton; content is authored in conversation.

⚠️ **This task requires hikaru.** Do NOT delegate to a subagent and do NOT write the canon unilaterally. Present the draft below stance-by-stance and revise per his reactions (spec §4 step 6 pattern: "Harnesseed はこう考える。賛成/反対/修正？").

- [ ] **Step 1: Hold the conversation using this draft as the tatakidai**

```markdown
# Harnesseed Philosophy（ハーネス思想の正典）

> これは tree の正典。seedling では roots/philosophy.md が pristine コピーとなり、
> あなたの個人化は stem/philosophy.md（見出し骨格を保った上書き層）に書かれる。

## 1. ハーネスはプロダクトである
モデルは借り物でも、ハーネスは自分の資産。設定・スキル・フック・記録の総体を
「育てる対象」として扱い、行き当たりばったりの設定変更をしない。

## 2. 検証はモデルより強い（harness > model）
同じモデルでもハーネス次第で成果は大きく振れる。決定的チェックを最優先し、
LLM 判定は advisory、人間の目視は最後の砦として使い分ける。

## 3. コンテキストは有限資源
セッションに注ぐ情報は「軽いポインタ」を基本にし、全文注入をしない。
記録は追記型で腐らせず、要約 view を育てる。

## 4. 変更は管路を通る
ハーネスへの変更は propose → approve → apply の一方通行の管路を通す。
供給源（調査・診断）と適用（grow）を分け、適用は 1 変更 = 1 コミットで監査可能にする。

## 5. 記録が次の自分を作る
やったこと・やらなかったこと・なぜかを bootstrap-log / growth-log に残す。
記録は教材であり、将来の自動化の一次資料である。
```

- [ ] **Step 2: Write the agreed canon to `plugins/harnesseed/blueprint/philosophy.md`** (the conversation's outcome, preserving a stable heading skeleton)

- [ ] **Step 3: Regenerate manifest and verify**

Run: `bash scripts/blueprint-manifest.sh generate && bash scripts/blueprint-manifest.sh verify`
Expected: OK.

- [ ] **Step 4: Commit**

```bash
git add plugins/harnesseed/blueprint
git commit -m "feat: philosophy canon authored with hikaru (blueprint)"
```

---

### Task 10: `/harnesseed:harness` skill

**Files:**
- Create: `plugins/harnesseed/skills/harness/SKILL.md`

**Interfaces:**
- Consumes: blueprint files (Tasks 4/8/9), manifest.json (Task 5), marker contract (Task 7), `check-invariants.sh` (Task 8), `index-seed.json` (Task 4).
- Produces: seedling repo at `${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed/` — `planted.json` `{seed_version, planted_at, blueprint:{relpath:sha256}}`; `roots/` (full blueprint copy); `stem/philosophy.md`; `trend-stock/index.json` `{"entries":[{id,title,tier,source,status:"bundled",registered_at}]}`; project `.harnesseed/leaf.json` `{"harnesseed":true,"seed_version":"<planted seed_version>"}`.

- [ ] **Step 1: Write SKILL.md**

````markdown
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
````

- [ ] **Step 2: Validate the plugin (skill frontmatter, manifests)**

Run: `claude plugin validate plugins/harnesseed`
Expected: validation passes (name `harnesseed`, no reserved-name conflicts, skill parses).

- [ ] **Step 3: Commit**

```bash
git add plugins/harnesseed/skills
git commit -m "feat: /harnesseed:harness germination skill (idempotent, leaf-only re-runs)"
```

---

### Task 11: learn/README.md + repo README rewrite (glossary, install, migration)

**Files:**
- Create: `plugins/harnesseed/learn/README.md`
- Rewrite: `README.md`
- Check/adjust: `SECURITY.md` (remove brainstorm references if any)

**Interfaces:**
- Consumes: glossary terms fixed in spec §2; install/uninstall flows from spec §3/§13.

- [ ] **Step 1: Write learn/README.md**

```markdown
# learn/ — Harnesseed を教材として読む

Harnesseed は「ハーネスエンジニアリングを実演して見せる教材」でもあります。ここはその入口です。

- いまあるもの: `../docs/bootstrap-log/` — Harnesseed 自身がどう設計・検証・修正されたかの一次記録
  （trend-scout #0、設計クリティーク #1/#2）。ケーススタディとして読めます。
- P5 で増えるもの: how-it-works（literal な仕組み解説）/ glossary 詳細版 / bootstrap-case-study ガイド。

まず `../docs/specs/2026-07-13-harnesseed-v1-design.md` の §1〜§5 を読むと全体像がつかめます。
```

- [ ] **Step 2: Rewrite README.md** (full replacement)

```markdown
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

### Coming in this major version (build order)

P2 `/harnesseed:scout` (automated, adversarially-verified trend research) → P3 `/harnesseed:checkup`
(12-category harness health check) → P4 `/harnesseed:grow` (propose→approve→apply with Misevolution
governance) → P5 `/harnesseed:pull` (3-way merge of upstream canon; your stem survives).

### Migrating from brainstorm-harness (removed)

This marketplace used to ship `brainstorm-harness`. It is gone. If you had it installed:

```
claude plugin uninstall brainstorm-harness@tech-teku-toolkit
```

If an `enabledPlugins` entry lingers, remove it from `~/.claude/settings.json` manually.

### Learn

`plugins/harnesseed/learn/` is the study entrance; `plugins/harnesseed/docs/bootstrap-log/` is the
primary record of Harnesseed building itself (design critiques, trend scouting) — readable as a
case study in harness engineering.

_Design spec & rationale: `plugins/harnesseed/docs/specs/`._
```

- [ ] **Step 3: Check SECURITY.md for brainstorm references**

Run: `grep -in brainstorm SECURITY.md || echo clean`
If matches: rewrite the affected lines to describe harnesseed (it runs no bypass modes; hook is read-only detect-and-inject). If `clean`: no change.

- [ ] **Step 4: Verify acceptance grep (spec §11-P1-6)**

Run: `grep -rn "brainstorm" README.md .claude-plugin/ .github/ 2>/dev/null | grep -v "Migrating from brainstorm-harness" | grep -v "uninstall brainstorm-harness" ; echo "exit=$?"`
Expected: `exit=1` (only the migration notice mentions it) — CI workflow still references it until Task 12; re-run this check there.

- [ ] **Step 5: Commit**

```bash
git add README.md plugins/harnesseed/learn SECURITY.md
git commit -m "docs: rewrite README around harnesseed (glossary, governance, migration); learn/ entrance"
```

---

### Task 12: CI rewrite + test runner

**Files:**
- Create: `tests/run-all.sh`
- Rewrite: `.github/workflows/test.yml`

**Interfaces:**
- Consumes: `tests/manifest-tests.sh` (Task 5), `tests/version-bump-check.sh` (Task 6), `tests/hook-tests.sh` (Task 7), `tests/invariants-tests.sh` (Task 8), `scripts/blueprint-manifest.sh verify`.

- [ ] **Step 1: Write the runner**

```bash
cat > tests/run-all.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 - <<'PY'
import json
for p in [".claude-plugin/marketplace.json",
          "plugins/harnesseed/.claude-plugin/plugin.json",
          "plugins/harnesseed/hooks/hooks.json",
          "plugins/harnesseed/blueprint/trend-stock/index-seed.json"]:
    json.load(open(p)); print("parse OK:", p)
PY
bash "$ROOT/scripts/blueprint-manifest.sh" verify
bash "$ROOT/tests/manifest-tests.sh"
bash "$ROOT/tests/hook-tests.sh"
bash "$ROOT/tests/invariants-tests.sh"
echo "ALL TEST SUITES PASSED"
EOF
chmod +x tests/run-all.sh
```

- [ ] **Step 2: Run it**

Run: `bash tests/run-all.sh`
Expected: `ALL TEST SUITES PASSED`

- [ ] **Step 3: Rewrite the workflow**

```yaml
name: tests

on:
  push:
    branches: [main, harnesseed]
  pull_request:

jobs:
  harnesseed-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Manifest, hook, and invariants test suites
        run: bash tests/run-all.sh
      - name: Blueprint change requires plugin version bump
        run: |
          if [ "${{ github.event_name }}" = "pull_request" ]; then
            bash tests/version-bump-check.sh "origin/${{ github.base_ref }}"
          else
            bash tests/version-bump-check.sh "HEAD~1" || true
          fi
```

- [ ] **Step 4: Verify no brainstorm references remain in functional surfaces**

Run: `grep -rn "brainstorm" README.md .claude-plugin/ .github/ install plugins/brainstorm-harness 2>/dev/null | grep -v Migrating | grep -v uninstall ; echo "exit=$?"`
Expected: `exit=1`

- [ ] **Step 5: Commit**

```bash
git add tests/run-all.sh .github/workflows/test.yml
git commit -m "ci: harnesseed test suites (manifest, hooks, invariants, version-bump rule)"
```

---

### Task 13: Manual e2e + dogfooding checklist — WITH hikaru

**Files:** none (verification task; findings go to `plugins/harnesseed/docs/bootstrap-log/2026-07-XX-p1-verify.md`)

⚠️ Requires hikaru's machine state changes (plugin uninstall/install). Confirm each step with him.

- [ ] **Step 1: Pre-flight (migration, spec §13)** — uninstall brainstorm & check residue:

```
claude plugin uninstall brainstorm-harness@tech-teku-toolkit
grep -n brainstorm ~/.claude/settings.json || echo "enabledPlugins clean"
```

- [ ] **Step 2: Register the dev marketplace.** Preferred: keep the github marketplace and add the local clone under a distinct name if supported. Otherwise swap: `claude plugin marketplace remove tech-teku-toolkit` then `claude plugin marketplace add /home/hikaru/projects/personal/tech-teku-toolkit-dev/tech-teku-toolkit`. Record which path worked (feeds spec §13).

- [ ] **Step 3: Install and validate**: `/plugin install harnesseed@tech-teku-toolkit` (or dev name), then `claude plugin validate plugins/harnesseed`.

- [ ] **Step 4: e2e in test project #1**: fresh dir with `git init` → start claude → nudge appears once → "はい" → seedling created (verify `git -C ~/.claude/harnesseed log` shows germinate commit; `planted.json` matches plugin version; `trend-stock/index.json` has 14 bundled entries) → philosophy conversation writes `stem/philosophy.md` → leaf exists, `.gitignore` offer made.

- [ ] **Step 5: e2e in project #2**: expect **leaf-only attach** (no germination, roots/planted.json byte-identical before/after — `sha256sum` them).

- [ ] **Step 6: declined flow** in a third dir: "いいえ" → `.harnesseed/declined` → restart → no nudge.

- [ ] **Step 7: resume/subdir spot-checks**: `claude --resume` in project #1 (no re-nudge, pointer present), start claude in a subdirectory (pointer, not nudge).

- [ ] **Step 8: Write `docs/bootstrap-log/2026-07-XX-p1-verify.md`** (what passed, what surprised, spec deviations) and commit:

```bash
git add plugins/harnesseed/docs/bootstrap-log/
git commit -m "docs: P1 verify log (e2e + dogfooding results)"
```

---

### Task 14: P1 close-out — acceptance sweep + phase critique

- [ ] **Step 1: Walk spec §11-P1 items 1–10** against reality; fix or file gaps.
- [ ] **Step 2: Run the 5-lens critique workflow** on the P1 implementation (same find→verify pattern as design critique #2), log to `docs/bootstrap-log/`, apply confirmed fixes, commit.
- [ ] **Step 3: Only after critique fixes: ask hikaru about pushing branch `harnesseed`** (never push without his OK).

---

## Execution notes

- Tasks 1–8 and 11–12 are subagent-friendly. **Tasks 9, 13 (and 14 step 3) require hikaru** — run them inline, never delegated.
- Task order matters: 5 needs 4 (files to hash); 8 and 9 regenerate the manifest; 12 needs all test scripts.
- P2–P5 get their own plans, written after each preceding phase's critique closes (spec §13 cadence).
