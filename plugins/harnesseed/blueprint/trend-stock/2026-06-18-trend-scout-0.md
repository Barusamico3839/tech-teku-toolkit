# Harnesseed bootstrap log: trend-scout #0 (2026-06-18)

> Harnesseed の自己改善（harness が harness を育てる）ための初回 trend-scout ログ。4 アングルで「いま現場で実際に採用されつつある」最新パターンを収集し、各 claim を adversarial に検証した結果を、ひかるの既存導入状況と照らしてまとめる。出典・数値は DATA に忠実で、未確認・低信頼のものはその旨を明記している。

## 1. 要約 (top takeaways)

1. **Dynamic Workflows が TANE にとって最重要の native primitive**。Claude が JS オーケストレーション script を書き、background runtime が実行、結果は script 変数に保持され lead の context を汚さない。GA（v2.1.154+、trigger `ultracode`）。最大 16 concurrent / 1,000 agents/run、mid-run user input 不可。TANE 自身がこの「workflow orchestration script」。`/deep-research` バンドルが参照アーキテクチャ。**ひかる未導入っぽい (unknown)。**
2. **自己改善エージェント研究が結晶化**: ACE（Generator-Reflector-Curator で playbook を delta 更新、context collapse 回避）、SICA（自分のコードを編集し benchmark gating + async overseer、17–53% gain）、Darwin Gödel Machine（self-modifying agent の archive を empirical fitness で選別）、GEPA（reflective prompt evolution、RLより~20%強・~35x少 rollout）。**大半が unknown — TANE の中核論文群。**
3. **「Misevolution」= 自己改善固有のリスク**（arXiv:2509.26354）。各 edit が個別に合格しても cycle 跨ぎで drift 蓄積、自分の eval を gaming（Goodhart）。対策は trajectory-level monitoring + harness が編集できない held-out eval + 「合格基準を弱められない」hard rule。**ひかる未導入 (no)。**
4. **Scope-restriction が self-editing harness の #1 governance lever**（Skill Evolver）。自己編集は skill/command/hook/CLAUDE.md/memory のみ可、**app source code は不可**。max 5 evolutions/run、evidence+rationale+regression-risk 付き edit、anti-pattern（instruction bloat / 矛盾 / over-specificity / prompt theater / cargo-cult）。
5. **Harness engineering が名前のついた分野として確立**。`ai-boost/awesome-harness-engineering` が ~12 カテゴリ taxonomy を提供（agent loop / planning / context / tool / skills&MCP / permissions / memory / orchestration / verification / observability / debugging / human-in-the-loop）。**ひかる未導入 (no)。**
6. **検証で効いた counter-signal**: (a) Hamel Husain は naive eval-driven dev に反対、error-analysis-first 推奨。(b) 誇張/陳腐化を複数捕捉（§4）: superpowers star 数は出典間で不一致、PostToolUse は実は block 不可、official marketplace の LSP は 12 でなく 11、install snapshot は ~2.5 週で ~10% drift。

## 2. アングル別 findings（maturity & Hikaru未導入っぽい度）

凡例: 未導入度 **高**=`no`、**中**=`unknown`、**低**=`yes`。

### Angle A — Claude Code platform capabilities（harness を BUILD する）

| Finding | maturity | recency | 未導入度 |
|---|---|---|---|
| Dynamic Workflows（Claude著JS orchestration、16並列/1000上限、`ultracode`、`.claude/workflows/`+`args`） | growing | 2026-Q2 (GA, v2.1.154+) | 中 |
| Hooks ~30 event 拡張（SessionStart context注入、handler種 command/http/mcp_tool/prompt/agent、asyncRewake、CLAUDE_ENV_FILE） | mainstream | 25末〜26-Q2 | 低 |
| Plugin marketplace.json schema（github/url/git-subdir/npm、displayName/defaultEnabled、strictKnownMarketplaces、SEED_DIR） | mainstream | 2026 | 低 |
| Plugin が束ねるもの（agents/hooks/MCP/LSP/monitors/bin/settings.json — `monitors/`で async event 通知） | mainstream | 2026 | 低 |
| Agent Skills frontmatter（disable-model-invocation、allowed/disallowed-tools、context:fork+agent、`!`cmd`` 注入） | mainstream | 25末〜26 | 低 |
| Subagents（per-agent model/tools/permission、skill preload、Performance Outcomes grader-loop） | mainstream | 2026-Q2 | 低 |
| Output styles（`/output-style` は v2.1.91 削除→`/config`、新 Proactive style） | mainstream | 2026 | 中 |
| settings.json（precedence、enabledPlugins、disableWorkflows、TaskOutput→Read deprecation） | mainstream | 2026 | 低 |
| MCP（plugin .mcp.json、Elicitation hook、mcp_tool handler、regex matcher） | mainstream | 2026 | 低 |

### Angle B — Agentic coding / harness / context engineering パターン

| Finding | maturity | recency | 未導入度 |
|---|---|---|---|
| Spec→plan→implement→verify（SDD、living spec、Plan Mode、Coordinator/Implementor/Verifier） | mainstream | 2026-Q2 | 低 |
| Context engineering（compaction=tool-result clearing が最軽量、note-taking/memory、JIT retrieval、Goldilocks zone） | mainstream | 25末/26-Q1 | 低 |
| Subagent orchestration（isolated context、1–2k token の condensed summary return） | mainstream | 2026-Q2 | 低 |
| Parallel agents via git worktrees（dev当たり4–8、review がボトルネック） | growing | 2026-Q2 | 低 |
| Verification loops（60% deterministic/30% LLM-judge/10% human、failure log feedback、"harness > model"） | growing | 26-Q1/Q2 | 中 |
| TDD with agents（e2e/behavioral優先）+ Hamel Husain caveat（eval-driven dev に反対、error-analysis-first） | mainstream | 2026-Q1 | 中 |
| Memory & state（CLAUDE.md、memory tool、symbol-indexed codebase memory、explicit intent-capture） | growing | 26-Q1/Q2 | 低 |
| Harness taxonomy ~12 categories（5-layer permission、LLMLingua ~20x、SWE-Bench/Terminal-Bench） | growing | 2026-Q2 | **高** |

### Angle C — Claude Code エコシステム / コミュニティ動向

| Finding | maturity | recency | 未導入度 |
|---|---|---|---|
| obra/superpowers が de facto methodology layer（brainstorm→TDD→subagent-dev→code-review、~752k installs #2） | mainstream | 2026-mid | 低 |
| Official marketplace + plugin-as-bundle 規約（~101 plugins、bundle=skills+agents+commands+hooks+MCP） | mainstream | 2026-Q1 | 低 |
| Top installs は Frontend Design/Superpowers/Context7/Remotion に集中 | mainstream | 2026-mid | 低 |
| awesome-claude-* リスト乱立（高品質は少数、~15,134 plugin repos、SEO noise 多） | mainstream | 2026-Q1 | 中 |
| SDD が mainstream convention 化（gotalab/cc-sdd、DeepLearning.AI 講座、Plan Mode + CLAUDE.md spine） | mainstream | 2026-Q1 | 低 |
| 規約の収束（skills=convention/hooks=determinism/subagents=parallelism/progressive disclosure） | mainstream | 2026-mid | 低 |
| Dotfiles-as-code for ~/.claude（version管理+symlink、short-global/rich-project、allowlist permission） | growing | 2026-Q1 | 中 |
| Cross-agent skill portability（universal SKILL.md が default 期待値化） | growing | 2026-Q1 | 中 |

### Angle D — Self-improving / bootstrapping / meta-agent systems

| Finding | maturity | recency | 未導入度 |
|---|---|---|---|
| Anthropic Agent Skills roadmap（"agents create/edit/evaluate Skills on their own" は **aspirational**） | growing | 25末〜26 | 低 |
| **ACE**（Generator-Reflector-Curator、playbook delta 更新、context collapse 回避、~+10.6%/AppWorld+17.1%/~+8.6%/~86.9% latency減） | growing | 2025-Q4 | 中 |
| **SICA**（自分の code/prompt/tool を編集、benchmark gating、async overseer cancel 可、17–53% gain） | emerging | 2025〜 | 中 |
| **Darwin Gödel Machine**（self-modifying agent の archive、empirical fitness 選別、stepping-stone 保持、DARWIN follow-up） | emerging | 25-Q2/26-Q1 | 中 |
| **Misevolution**（自己改善固有リスク: cycle 跨ぎ drift、eval gaming） | emerging | 2025-Q3 | **高** |
| **Skill Evolver**（scope-restriction が #1 lever、max5/run、evidence-linked edit、5 anti-patterns） | emerging | 2026-Q1 | 中 |
| **GEPA**（Genetic-Pareto reflective prompt evolution、DSPy、RLより~20%強・~35x少 rollout、text-feedback-as-signal） | mainstream | 2025-Q3 | 中 |
| **Memory が self-improvement の基盤**（mem0 survey、AgeMem: store/retrieve/update/summarize/discard を RL最適化 tool 化） | growing | 26-Q1/Q2 | 低 |
| Self-improving/harness 分野の crystallization（awesome-harness-engineering、ICLR SSI-FM workshop、"evals が engine"） | growing | 26-Q1/Q2 | 低 |

## 3. 「ひかるがまだ取り入れてなさそうな最新」= 優先 stock list

優先度 = 未導入度 × TANE への直接効果 × 検証の堅さ。

### Tier 1 — 高優先（`no` 明示 or TANE 中核、検証 confirmed）

1. **Misevolution の risk register を TANE に実装**（Angle D / `no`）— per-edit gate では不十分。trajectory-level monitoring、harness が編集できない held-out/rotating eval、「自分の acceptance criteria を弱められない」hard rule。出典 arXiv:2509.26354（confirmed、PDF 部分抽出のため定量値は loosely）。
2. **awesome-harness-engineering ~12 カテゴリで TANE の gap 分析**（Angle B&D / `no`）— observability/tracing・permissions model・human-in-the-loop が under-build しやすい。フル crawl して監査チェックリスト化。trend-scout の index source としても最良。
3. **Dynamic Workflows を native runtime として評価**（Angle A / `unknown`、confirmed）— 16並列/1000上限/mid-run input 不可は hard design parameter。`/deep-research` が fan-out→cross-check→vote→cited report の参照アーキテクチャ。自前 orchestrator か native かの意思決定が必要。

### Tier 2 — 中優先（self-improvement loop に直結、研究 confirmed）

4. **ACE の Generator-Reflector-Curator + delta-update 規律**（`unknown`、confirmed・数値 exact）— CLAUDE.md/skills/instinct 編集 loop で追記型 structured delta、丸ごと rewrite 禁止。brevity drift を計測・上限。最も転用しやすい。
5. **SICA の overseer + benchmark-gated acceptance**（`unknown`、confirmed）— 自己編集に必ず empirical fitness test + 独立 async overseer の veto を対にする。TANE のテーゼそのもの。
6. **Darwin Gödel Machine の archive/population 戦略**（`unknown`、confirmed）— 単一 mutating harness でなく改善した harness state を全 version 化、diverse stepping-stone 保持、empirical fitness 選別。open-ended 改善 + 即時 rollback を両立。
7. **Skill Evolver の scope-restriction governance**（`unknown`）— harness/config surface（編集可）と product/source code（off-limits）を分離。per-run edit cap、evidence+rationale+regression-risk 必須、5 anti-pattern screen。Tier 1-1 の運用版。
8. **GEPA を meta-prompting engine として採用**（`unknown`、confirmed）— 自前で書かず DSPy GEPA。Pareto-frontier of candidates は DGM archive / ACE anti-collapse と呼応。qualitative review が metric な harness に text-feedback-as-signal が合う。
9. **Tiered verification loop（60/30/10）+ failure-log feedback**（Angle B / `unknown`）— 全変更に deterministic gate（lint/typecheck/test/schema）→ fuzzy は LLM-judge → ambiguity のみ human。"harness > model"（同一 model が 30–50pt 振れる）が TANE 投資を正当化。

### Tier 3 — 取り込み候補（規約・運用、検証で誇張に注意）

10. **Hamel Husain の error-analysis-first**（`unknown`）— 投機的 upfront eval suite に過剰投資せず、trace logging + error-analysis review surface を作り eval を観測 failure から育てる。
11. **Dotfiles-as-code for ~/.claude**（`unknown`）— harness config を fork 可能な version 管理 repo に。short-global/rich-project の CLAUDE.md 分割 + allowlist permission。
12. **Cross-agent portable SKILL.md**（`unknown`）— skill を書くなら portable format で再利用幅拡大。hard expectation 化するかは要追跡。
13. **aggregator/SEO dedup**（`unknown`）— discovery は curation/dedup 問題。低品質 aggregator を強くフィルタ、高 star の curated GitHub list を信頼 entry point に。
14. **Proactive output style を worker baseline に**（`unknown`）— autonomous worker の baseline を settings.json の `outputStyle` で宣言。`/output-style` は削除済み、参照は要修正。

## 4. どう調べたか（methodology — trend-scout を後で BUILD するための蒸留）

### 共通の型（全アングル）
ToolSearch で `select:WebSearch,WebFetch` schema をロード → アングルごとに WebSearch を 4–8 本 fan-out → primary source を 3–4 本 WebFetch して読込 → 各 load-bearing claim を adversarial に verify（confirmed/partly-confirmed の verdict + correctedSummary を残す）。数値・固有主張は primary/named source（official docs、arXiv ID、GitHub repo、DSPy docs、Anthropic engineering blog）に依拠。SEO blog/Medium/aggregator は trend-maturity signal のみ、load-bearing には使わない。

### 効いた search angle / query
- **Official docs 直 fetch + targeted extraction prompt** が最強。authoritative は `code.claude.com/docs/en/<page>`。
- **`{/* min-version: X */}` annotation が recency dating の gold**（displayName v2.1.143、defaultEnabled v2.1.154、workflows v2.1.154+、terminalSequence v2.1.141+）。
- **arXiv ID が dated で citable**（26xx 系が現在日付 2026-06-18 と整合 = date sanity check）。
- 効いた具体 query: marketplace.json structure 2026 / SKILL.md frontmatter / hooks SessionStart settings.json / dynamic-workflow tool 2026（A）；spec-driven 2026 / context engineering / eval-driven & verification loops / parallel agents & worktrees（B）；popular plugins & install counts / superpowers adoption / convention convergence（C）；self-improving agents / Darwin Gödel Machine / misevolution / DSPy GEPA / SICA / ACE（D）。
- **install/star 数や日付が search snippet に乗る**ので primary quantitative signal として扱えた（C）。

### noisy だったもの
- Generic search summary は同じ事実の言い換え → fetch した primary doc を snippet より優先。
- Aggregator/SEO サイトが query を支配（6か月で空→氾濫）→ dedup 必須。
- arXiv PDF の WebFetch 抽出が部分的（misevolution, ACE 一部）→ 行ごと再検証できない数値は loosely 保持・`~` で hedge。
- star count が出典間で不一致（superpowers 94k/227.6k/daily velocity）→ approximate 明記。
- paywall（buildtolaunch review が partial signal のみ）。

### verification が捕まえたもの（faithful な誇張・陳腐化補正）
- **PostToolUse は実は block 不可**（tool 実行済み；exit 2 は stderr feedback のみ）。"can block" は overstated。
- **Plan Mode は shift+tab を 2 回**（Auto-Accept→Plan を cycle）、1 回ではない。
- **Official marketplace の LSP は 11、12 ではない**；dev-workflow plugin 名も不正確。`claude-community` "synced nightly" は docs に記載なし。
- **install snapshot は ~2.5 週で ~10% drift**（Frontend Design 829k→907k）。「winners vs long-tail noise」は overstated — 200k–350k の mid-tier が厚い。
- **subagents は legacy 語**、docs は "agents"。
- ACE の数値は abstract に exact 記載（`~` hedge は不要だった）。Karpathy は正確には「agentic engineering」への pivot 表現。

### trend-scout への再利用メモ
- **canonical scrape target**: `code.claude.com/docs/en/<page>` + `llms.txt` index、min-version annotation を recency signal に。
- **構造化データ源**: official Anthropic plugin directory、GitHub API での star/fork polling。
- **index source**: `ai-boost/awesome-harness-engineering`（フル crawl 推奨）、`VoltAgent/awesome-ai-agent-papers`、高 star curated GitHub list。
- **filter**: 低品質 aggregator/SEO の dedup を built-in に。
- **architecture 雛形**: `/deep-research`（fan-out search → cross-check → vote → cited report）がそのまま trend-scout の参照アーキテクチャ。
- **未着手 follow-up**: Agent SDK pages / plugins-reference の深掘り、spec-driven Medium piece と worktree guide の deep-fetch。

### 付記
maturity・recency・「未導入っぽい度」は提供 DATA に忠実。`unknown` は「導入状況が未確認」を意味し未導入の断定ではない。`no`（Misevolution、awesome-harness-engineering taxonomy）が最優先の取り込み候補。