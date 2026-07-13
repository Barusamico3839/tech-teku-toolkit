# Harnesseed bootstrap log: design-critique #2 (2026-07-13)

> フルv1.0 spec（rev.1）に対する2回目の敵対的クリティーク。5レンズ（Claude Code実現可能性 / bootstrap統治 / スコープ・YAGNI / 一貫性・教えやすさ / トレンドギャップ）の finder を dynamic workflow で fan-out し、**全 finding に懐疑的検証者を1体ずつ当てて反証を試みた**（find → verify の2段。計35 agents、約15分）。検証者の多くが実機検証（プラグインキャッシュ構造・フック発火・headless挙動の実測）まで行い、fix の不正確な部分を correctedFix として補正した。結果は spec rev.2 に反映済み。

## 統計

- finder 5 lenses → findings 30 件 → **確認 27 / 反証 3**
- 反証された3件（＝specは正しかった）: ①「スキルが workflow を組み立てて実行」の起動経路は成立する ②`${CLAUDE_PLUGIN_ROOT}` の解決は問題にならない ③stem/ 配下の invariants シャドー上書き攻撃は成立しない

## 確認された指摘 → rev.2 での解決（テーマ別）

### A. バージョニングと pull 経路（feasibility/high ほか）
- **二重バージョン（plugin.json / blueprint/VERSION）が非連動**で、blueprint だけ bump すると plugin update が no-op になり pull が永遠に「最新」と誤答する（キャッシュは plugin.json の version がキー。実機検証済み）→ **seed version = plugin.json に1本化、blueprint/VERSION 廃止**。CI に「blueprint 差分→version bump 必須」の整合チェック。
- pull に「インストール済み seed を新しくする」ステップが無い → **Step 0（marketplace update + plugin update + installed_plugins.json の installPath から新 blueprint を解決）**を追加。`${CLAUDE_PLUGIN_ROOT}` 参照の唯一の例外として明文化。
- pull の原子性欠如（merge-file がコンフリクトマーカーを直接書き込み、中断で全プロジェクト共有の stem が汚染）→ **working tree clean 前提チェック＋ .pull-staging/ での merge ＋ all-or-nothing 1コミット＋検出ベースの中断復旧**。
- harness 再実行×プラグイン更新で roots（merge base）が silent 破壊 → **roots/ と planted.json への書き込みは初回発芽と pull のみ**、再実行は leaf 追加だけ、version skew 検知で pull 誘導。

### B. 統治の誠実化（governance/critical ほか）
- 「blueprint/evals/ はハーネスが編集できない」は新構造（プラグイン内 blueprint＝ユーザー書き込み可能なキャッシュ）では**宣言のみで機構的に強制されない**。さらに改変後に pull を1回通すと汚染が正規 hash として固定される洗浄経路まで存在 → **tamper-proof を主張しない（tamper-evident に再定義）**。grow 毎 run 冒頭の blueprint 整合検証（version 同一×hash 不一致= hard-stop / version 新= pull 誘導の2分岐）、pull の上流照合（git remote の manifest と照合、照合不能なら拒否）、evals/チェッカーの実行元を roots/（git 監査下）へ、発芽時の permission deny 提案。
- 「held-out eval」が構造チェックのみで意味的 drift を検出せず、「基準を緩める変更の拒否」は決定的スクリプトで実装不能 → **2層ゲートに分離**: ①決定的 invariants ゲート（自動 revert 接続。protected diff 検出・追記型検査・骨格包含チェック等）②挙動シナリオ＋LLM-judge は**advisory のみ**（人間承認の材料。自動ゲート非接続）。「held-out」の語を廃止。
- stem 外サーフェス（settings.json 等）への grow 適用は自動 revert の保証外（backup/復元が全て未規定）→ **v1 は grow の適用先を seedling repo 内に限定**。外部ハーネス設定は「diff 提案→ユーザー手適用」に格下げ（YAGNI 案を採用。自動適用＋復元機構は v2 候補として明示先送り）。
- allowlist にプロジェクト級ハーネス設定の層が無い → 提案出力層に明記＋**default-deny 閉包**（列挙なきプロジェクト内パスは全てアプリソース扱い）。

### C. フック仕様の精密化（feasibility/medium）
- source 無差別発火（resume/compact での再ナグ）、headless（claude -p）での誤発動、サブディレクトリ起動での誤判定 → **状態×source マトリクス**（nudge は startup/clear のみ、ポインタは全 source）、`CLAUDE_CODE_ENTRYPOINT=sdk-*` でスキップ、**上方向探索（.git 境界打ち切り）**。CI にケース追加。
- フックに更新検知が無く新版に気づく手段が無い → leaf 有り時に planted.json と plugin.json の version 比較で **pull 提案を注入**（「存在チェックのみ」原則の明示的緩和）。

### D. 用語・一貫性（coherence/high ほか）
- 「stem」がリポジトリ全体とサブディレクトリの**二重定義**でパス表記が相互矛盾（§5 vs §7/§8）、allowlist 境界が二義的 → **seedling（repo 全体）/ stem（上書き層のみ）に一本化**、パスは seedling ルート相対で統一、checkups/ を allowlist に明記。
- stem 側 manifest.json が blueprint/manifest.json と同名衝突 → **planted.json に改名**。
- roots「絶対不可」と pull の roots 更新が矛盾 → 正当な書き込み2経路（発芽/pull・同一コミット）を明文化。
- 「発芽」が初回生成と毎プロジェクト操作の両方に使われる → **発芽=初回のみ**に予約、質問文言は「ハーネスしますか？」に統一、2件目以降は「leaf 追加」。
- glossary が P5 まで無い（旧 MVP からの退行）→ P1 README に復活。docs/superpowers/ 階層 → docs/ フラット化。

### E. ストックのライフサイクル（scope/trend-gap）
- 同梱 #0 が台帳に接続されず初回 scout が全項目を再提案 → 発芽手順7で **index.json に status: bundled で初期登録**。
- 却下の永久封印が maturity 進化と衝突 → 却下エントリに理由/日付/maturity/evidence を必須化し、**有意変化時のみ supersede 追記で再浮上**（基準は scout-angles.md に正典化）。保留= deferred は次回再提示。
- 純追記型の invariant 化が将来の curation を禁止 → invariant は「id 単調増加・status 以外書換禁止」に精密化し、**summary.md 生成・growth-log rotation を governed operation として許可**。
- trajectory 監視が受動ログ止まり → **drift review ステージ**（累積10件 or 90日で発火、累積 anti-pattern 再スクリーニング、結果は提案供給源へ）。
- scout の workflow hard 依存 → **attempt-and-degrade**（subagent fan-out → 会話内逐次）。

### F. 移行と受け入れ基準の完全性（feasibility/scope）
- brainstorm-harness は repo から消してもユーザー環境に残る（実機で確認: installed_plugins.json・enabledPlugins に残存、同名 marketplace 衝突で P1 の e2e がそのまま実行不能）→ **uninstall 手順＋push 順序＋dev 用別名 marketplace（tech-teku-toolkit-dev）**を §3/§13 に明記。
- P1/P5 のスコープ項目の約半分に受け入れ基準が無い → P1 を10項目、P5 を6項目に拡充（brainstorm 残骸ゼロの決定的検証、philosophy 非スタブ、再実行安全、learn/meta-harness の完了条件等）。
- leaf.json の stem 絶対パス保存は冗長・共有時有害 → パス削除（正準導出に一本化）、`.harnesseed/` の .gitignore 提案を P1 に。

## 方法論メモ（次回クリティークへの蒸留）

- **find→verify の2段は効いた**: 30件中3件を反証で落とし、残る27件も fix の不正確部分（例:「matcher を startup 限定に」はポインタ再注入を壊す、「2セッション必須」は言い過ぎ）を correctedFix で補正できた。単段 fan-out より明確に質が高い。
- **検証者に実機検証をさせる**のが決定打（プラグインキャッシュのバージョンキー構造、no-op update、headless での SessionStart 発火、CLAUDE_CODE_ENTRYPOINT の実測値などは机上では確定できなかった）。
- workflow 起動時の教訓: `args` はネスト JSON がスクリプトに文字列で届くことがある → スクリプト側で `typeof args === 'string' ? JSON.parse(args) : args` のガードを入れる。
