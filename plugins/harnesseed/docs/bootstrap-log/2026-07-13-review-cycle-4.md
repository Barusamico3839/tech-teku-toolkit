# Harnesseed bootstrap log: v1.0 review cycle #4 (2026-07-13)

> v1.0.0 実装完了直後に回した「レビューと改善」のフルサイクル。2本の workflow
> （P1クリティーク再開 + 全ブランチ5レンズ）を find→verify で走らせ、確認された指摘を
> 3 wave で修正し、v1.0.0 → 1.0.1 → 1.0.2 に到達した。セッション上限・手動停止で
> workflow が3回中断したが、resume（journal キャッシュ再生）で毎回追加コストほぼゼロで再開できた。

## 数字

| wave | 対象 | findings | 確認 | 反証 | 修正 |
|---|---|---|---|---|---|
| 1 | P1クリティーク再開（未検証14件） | 28（累計） | 3 (low) | 25 | 3 → commit 981afe4 |
| 2 | 全ブランチ5レンズ（初回+再開） | 18 | 16 + 自力検証2 | 2 | 18 → commit 1075f8f (v1.0.1) |
| 3 | 同・最終再開（残verify 11件） | 29（累計） | 7 | 22 | 7 → commit d0d3bc4 (v1.0.2) |

- 検証者の反証は「修正が効いている」ことの独立確認として機能した（wave 3 の反証22件は
  ほぼ全て wave 2 で修正済みの指摘）。
- テスト: 78 → **124 チェック**、全 green。`claude plugin validate` 通過。
- 副産物のライブ検証: dev marketplace 経由の実更新チェーン 0.1.0 → 1.0.1
  （バージョン別キャッシュ・installPath/gitCommitSha 解決・配布物の manifest 一致を実機確認）。

## 大物の指摘と直し方（設計判断を含むもの）

1. **[critical] pull が改竄キャッシュの洗浄経路になっていた**: 発芽には双方向 walk ゲートが
   あるのに pull の確定点（stage-merge finalize）には無く、改竄 blueprint が planted.json/
   roots/チェッカーごと恒久汚染できた（検証者が隔離環境で完全再現）。→ `validate_newbp()` に
   発芽と同一の双方向ゲートを実装し stage/finalize 両方で実行（TOCTOU も構造的にカバー）。
2. **auto-revert が二重に壊れていた**（自力検証）: `git revert -q` は不正構文、正構文でも
   revert コミットが追記型検査に偽陽性 fail。→ 構文修正 + チェッカーに「相殺ペア認識」
   （tree(HEAD)==tree(HEAD~2) → delta 検査スキップ）。この設計は「追加直後の手動削除」も
   revert と区別せず許すが、net-zero = 状態不変 = 無害、と定義して受容（テストで意図を固定）。
3. **公認操作がゲートと構造矛盾**: growth-log rotation は spec 公認の governed operation
   なのに追記型検査を絶対に通れない。→ **文書側を修正**（rotation 概念を廃止し「本体は
   永久追記・governed op は要約 view の再生成のみ」に統一）。チェッカーに例外を掘るより
   invariant を単純に保つ方を選んだ。
4. **見出し包含ゲート（spec ①-3）が実装から丸ごと欠落**: 3ドキュメントが「機械検査される」と
   約束していたのに checker に存在しなかった。→ 実装（fenced code 除外・ファイル削除も
   骨格喪失として fail・未作成ウィンドウは skip）。
5. **却下メタデータの迂回路**: `set-status rejected` が理由なしで通り、正典の再浮上ルールが
   構造的に実行不能だった。→ 必須引数化 + rejected_at 自動刻印 + チェッカーに「一度きりの
   追加のみ」例外を厳密定義（既存メタデータの書換は fail のまま）。
6. **ハードコードされた ID**: pull が marketplace 名を決め打ちし、dev/directory インストールで
   壊れた。→ 実行中プラグイン自身のキャッシュパスから marketplace/plugin 名を導出、
   registry エントリは lastUpdated 最新を選んで installPath の plugin.json と相互検証。

## 方法論メモ（次サイクルへ）

- **「反証された指摘」はコスト無駄ではない** — wave 3 の 22 反証は wave 2 修正の独立検証に
  なった。find→verify を修正後に再実行する「回帰クリティーク」は安上がりで価値が高い
  （キャッシュ resume なら finder 再実行なし）。
- **検証者への隔離環境実再現の要求は継続的に効いた**: critical の pull 洗浄経路・rotation 矛盾・
  RUN_DATE 構文エラーはすべて実測で確定した指摘。
- **workflow の resume は3回の中断（上限×2・手動停止×1）を全て無傷で吸収**。長時間レビューは
  「止まっても journal から再開できる」前提で設計しておくと精神的にも安い。
- テストが落ちたら**まずテストの期待を疑う**: 「追加直後の削除」fail 期待は net-zero 設計と
  矛盾していた。設計判断（revert ペア許容）をテストコメントに書き残して意図を固定した。

## 残タスク（ライブ検証・ひかると）

- 発芽 e2e（proj1..3、キャッシュは 1.0.2 に要更新）+ 受け入れ基準9 の bump 再実行安全手順
- scout / checkup / grow 各1サイクルの実走、pull の実チェーン完走
- 完了後 push（ひかる確認）
