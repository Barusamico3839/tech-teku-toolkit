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
