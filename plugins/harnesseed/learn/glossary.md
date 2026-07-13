# Glossary（用語集・詳細版）

覚えるのは太字の4語だけ。残りは説明語。

| 語 | literal には | メタファー |
|---|---|---|
| **tree** | 本家 GitHub repo（tech-teku-toolkit。main はオーナーのみ、他は PR） | 成熟した木 |
| **seed** | 配布プラグイン `plugins/harnesseed/`（install する単位。blueprint を運ぶ） | ばらまかれる種 |
| **seedling** | あなたの育つインスタンス = `~/.claude/harnesseed/` の git repo 全体 | 芽吹いた苗 |
| **stem** | seedling 内の個人化上書き層 `stem/` | 幹（育つ部分） |
| blueprint | seed が運ぶ正典（philosophy / invariants / チェックリスト / チェッカー） | 遺伝設計図 |
| roots | seedling が吸収した正典の pristine コピー（merge base。発芽と pull だけが書く） | 根（吸収器官） |
| leaf | プロジェクトごとのマーカー `.harnesseed/leaf.json` | 葉 |
| 発芽 (germinate) | **初回のみ**: seedling の生成（roots+stem を作る）。2プロジェクト目からは leaf 追加だけ | 種→苗 |
| planted.json | 吸収した seed_version と正典の per-file hash の記録 | 芽吹きの記憶 |
| trend-stock | 検証済みトレンドの台帳（index.json）+ 要約 view（summary.md） | 蓄え |
| growth-log | grow の軌跡ログ（追記型） | 年輪 |

## メタファーの導出ルール

- 種は1回だけ発芽する。苗は roots（吸収した正典）・stem（自分の幹）・leaf（プロジェクトの葉）を持つ。
- よく育った seedling は fork して自分の tree になれる（circulation）。
- **迷ったら literal を信じる**。メタファーは覚え方であって仕様ではない。

## 「harnesseed」という名前のディレクトリは3つある

| パス | 正体 |
|---|---|
| `plugins/harnesseed/`（repo / プラグインキャッシュ内） | seed = 配布物 |
| `${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed/` | seedling = あなたの実体 |
| `<project>/.harnesseed/` | leaf マーカー（per-user。`.gitignore` 推奨） |
