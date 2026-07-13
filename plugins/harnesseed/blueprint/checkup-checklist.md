# Checkup Checklist（ハーネス健康診断の正典・~12カテゴリ）

/harnesseed:checkup はこのファイルを roots/ から読み、カテゴリごとに診断する。
taxonomy の出典: ai-boost/awesome-harness-engineering（trend-scout #0 で精査済み）。
判定は3値: **present**（機能している証拠がある）/ **partial**（一部のみ・形骸化の疑い）/
**absent**（無い・無効）。判定には必ず根拠（どのファイルのどのキー/設定を見たか）を添える。

> 盲点になりやすいのは **observability / permissions / human-in-the-loop**（#0 の知見）。
> この3つは特に具体的に診ること。

## 1. agent loop（作業ループの型）
- 確認: CLAUDE.md / スキル構成に「計画→実装→検証」の型があるか。spec/plan 系スキル
  （superpowers 等）の導入と実際の利用痕跡。
- 良い状態: 大きな作業が計画ドキュメント経由で進む規約が明文化されている。

## 2. planning（計画と分解）
- 確認: plan mode の利用、planning 系スキル、タスク分解の規約（CLAUDE.md 記述）。
- 良い状態: 「いつ計画を書くか」の基準が決まっている（全部 ad-hoc でない）。

## 3. context（コンテキスト管理）
- 確認: CLAUDE.md のサイズ（グローバルが肥大していないか — short-global/rich-project）、
  ポインタ型の参照構造、memory ディレクトリの構成。
- 良い状態: グローバル CLAUDE.md は簡潔、詳細はプロジェクト側・オンデマンド参照。

## 4. tool（ツール構成）
- 確認: 有効プラグイン数と実際に使うものの比率（enabledPlugins の棚卸し）、
  死んでいる/重複するツールの有無。
- 良い状態: 有効なものは説明できるものだけ（コンテキスト税を払う価値があるもの）。

## 5. skills & MCP（スキルと外部接続）
- 確認: インストール済み marketplace / プラグイン一覧、.mcp.json（ユーザー/プロジェクト層）、
  認証切れ・未使用 MCP の有無。
- 良い状態: MCP は使うものだけ接続。スキルは portable SKILL.md 標準で書かれている。

## 6. permissions（権限モデル）★盲点
- 確認: settings.json の permissions（allow/deny/ask ルール数と中身）、bypassPermissions の
  常用有無、deny ルールの保護対象（秘密情報・破壊的コマンド）。
- 良い状態: allowlist ベースで、bypass は限定された文脈のみ。危険操作に deny/ask がある。

## 7. memory（記憶）
- 確認: memory ディレクトリの有無と構造（index + 単一事実ファイル）、腐った記憶の有無
  （日付・存在しないファイルへの言及）。
- 良い状態: 記憶が構造化され、定期的に手入れされている。

## 8. orchestration（並列・委譲）
- 確認: subagent / workflow の利用可否（disableWorkflows 等の設定）、agents/ 定義、
  worktree 運用の痕跡。**Dynamic Workflow 可用性はここで診る**（scout の劣化パス判断の材料）。
- 良い状態: 委譲の使い分け基準がある（何を субagent に、何をインラインで）。

## 9. verification（検証）
- 確認: テスト・lint・型チェックの hook 化（PostToolUse 等）、CI の有無、
  「決定的チェック優先」の規約。
- 良い状態: 決定的ゲートが自動で走る。LLM 判定を盲信していない。

## 10. observability（可観測性）★盲点
- 確認: 何が起きたかを後から追える仕組み — セッションログ・成果物の記録規約・
  作業ログ（bootstrap-log / growth-log 相当）の有無。
- 良い状態: 「先週何をどう変えたか」に記録で答えられる。

## 11. debugging（デバッグ規律）
- 確認: systematic-debugging 系スキルの有無、「再現→仮説→検証」の規約、
  エラー時の場当たり修正を防ぐ仕組み。
- 良い状態: デバッグに型がある。

## 12. human-in-the-loop（人間の関与点）★盲点
- 確認: 破壊的操作・公開操作の確認規約、承認ゲートの設計（何が自動で何が要承認か）、
  通知経路。
- 良い状態: 「人間が見るべき点」が明文化され、それ以外は自動で流れる。

## レポート形式

1. カテゴリ別: 判定（present/partial/absent）+ 根拠 + 一言コメント
2. gap ランキング: 重要度順（impact × 修正コスト）。各提案は観測事実に紐づける
   （推測で提案しない）
3. 提案の適用は checkup ではやらない — /harnesseed:grow の提案供給源になるか、
   ユーザーが手で適用する
