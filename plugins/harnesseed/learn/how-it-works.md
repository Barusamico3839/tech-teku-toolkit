# How Harnesseed Works（literal な仕組み解説）

メタファー(tree/seed/seedling)はニックネーム。ここでは実際の機構だけを説明する。

## 部品は4つ

1. **配布プラグイン**（`plugins/harnesseed/` — インストールされるとプラグインキャッシュに置かれる）
   - `blueprint/` = 正典。philosophy・invariants・チェックリスト群・trend-stock 種・
     決定的チェッカー。`manifest.json` に per-file sha256 と seed_version が焼き込まれている
   - `skills/` = 5つの手順書（harness / scout / checkup / grow / pull）
   - `hooks/` = SessionStart の検知フック（読み取り専用・注入のみ）
2. **ユーザー級 git リポジトリ**（`${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed/` = seedling）
   - `roots/` = 発芽時に blueprint を丸ごと pristine コピーしたもの（3-way merge の base）
   - `stem/` = あなたの個人化上書き層（philosophy の会話結果などが育つ）
   - `trend-stock/` = 検証済みトレンドの台帳（index.json は追記型）と要約 view
   - `planted.json` = どのバージョンの正典をどの hash で吸収したかの記録
   - 全変更が git コミット（trailer 付き）= 監査とロールバックが無料
3. **プロジェクトマーカー**（各プロジェクトの `.harnesseed/` — leaf.json か declined）
4. **CI**（tree 側）= manifest 整合・フック挙動・invariants・merge 機構の決定的テスト

## セッションの流れ

起動 → フックが cwd から上へマーカーを探す（.git 境界で停止）→
未ハーネスなら一度だけ提案 / ハーネス済みなら軽いポインタ（stem の philosophy と
trend-stock の summary への参照）だけ注入。全文注入はしない。

## 変更の流れ（一方通行の管路）

```
scout（調査・検証） ─┐
checkup（診断）      ├→ 提案 → あなたの承認 → grow が適用（1変更=1コミット、最大5件/run）
drift review（監査） ┘                         └→ 決定的チェッカー失敗なら自動 revert
```

ホスト設定（settings.json / CLAUDE.md / .mcp.json）への変更は **diff の提示まで**。
適用は常にあなたの手で行う。

## 更新に気づく経路

上流（tree）が新しい正典をリリース → あなたが `claude plugin update` する（または pull の
Step 0 が実行）→ 以後のセッションでフックが「installed vs absorbed」のバージョン差を検知して
`/harnesseed:pull` を提案する。pull は staged 3-way merge（base=roots / mine=stem /
theirs=新 blueprint）であなたの個人化を保ったまま正典を更新する。途中で失敗しても
seedling は無傷（作業は git 管理外の staging で行われ、反映は全or無の1コミット）。

## 信頼モデル（正直な限界）

Harnesseed は **tamper-evident であって tamper-proof ではない**。正典は書き込み可能な
プラグインキャッシュに載るため「編集不能」は作れない。その代わり:
発芽・grow・pull の各所で hash 照合（planted.json / manifest / 上流 git 履歴）を行い、
パイプライン外の改竄を検知して停止する。
