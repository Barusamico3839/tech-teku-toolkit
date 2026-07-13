# Harnesseed bootstrap log: v1.0 implementation sprint (2026-07-13)

> 1日で design spec rev.2 → P1〜P5 全実装 → v1.0.0 に到達したスプリントの記録。
> 前半（P1）は subagent-driven development（タスクごとに実装 subagent＋レビュー subagent、
> 指摘→修正→再レビューのゲート）、後半（P2〜P5）はセッション上限到達により
> コントローラのインライン実装へ切り替えた。ひかるの判断で**ライブ検証を翌日以降に回し、
> 実装量を最大化**する方針を取った。

## 実装の到達点（バージョン階段）

| version | phase | 中身 |
|---|---|---|
| 0.1.0 | P1 First Sprout | 骨格・発芽スキル・フック・invariants チェッカー・philosophy 正典（ひかると会話で確定）・brainstorm-harness 完全削除 |
| 0.2.0 | P2 scout | scout-angles 正典・ledger.py（追記型台帳の決定的ガーディアン）・scout SKILL.md |
| 0.3.0 | P3 checkup | 12カテゴリ checklist 正典・collect.py（秘密値を漏らさない事実収集）・checkup SKILL.md |
| 0.4.0 | P4 grow | drift-review + scenarios 正典・チェッカー git 履歴検査拡張・grow SKILL.md |
| 1.0.0 | P5 pull ほか | stage-merge.sh（staging 方式 3-way merge）・pull SKILL.md・learn 3本・meta-harness 正典 |

決定的テスト: manifest 6 / hook 24 / invariants 5+10 / ledger 12 / collect 6 / pull-merge 15 = **78 チェック**、全 green。`claude plugin validate` 通過。

## プロセス上の出来事と学び

1. **subagent レビューは実際に品質を上げた**: Task 7（フック）で fail-open な source 処理と
   方向無視のバージョン比較を、Task 11 で SECURITY.md の「実在しない機能の記述」を捕捉。
   いずれも修正→再レビューで解消。
2. **P1 実装クリティーク（#3）は 5 lenses × find→verify で 28 findings**、確認14件を同日修正
   （詳細: `2026-07-13-p1-critique-3.md`）。検証14件はセッション上限で未完 —
   workflow の resume（キャッシュ再利用）で翌日回収予定。
3. **セッション上限という現実的制約**への適応: subagent が使えなくなった時点で、
   プラン本文にコードが完全記載されていたため（writing-plans の規律）、インライン転写での
   継続が低リスクで可能だった。**プランの網羅性は実行主体の交代可能性でもある**。
4. **P2〜P5 のフェーズ別クリティークは未実施**（翌日以降）。P1 の教訓から、実施時は
   検証者に隔離環境での実再現を要求すること。

## 翌日以降への引き継ぎ（deferred）

- **ライブ e2e**（ひかる）: 発芽（proj1）→ leaf-only（proj2）→ declined（proj3）→
  resume/subdir。実施前に `claude plugin update harnesseed@tech-teku-toolkit` で
  キャッシュを 1.0.0 へ（現在 0.1.0 のまま）
- **受け入れ基準9（bump 後の再実行安全）の専用手順**（クリティーク#4 指摘: 基準1/3/4 と別シナリオが必要）:
  ① proj2 の leaf-only 確認後に `sha256sum ~/.claude/harnesseed/planted.json`・
  `find ~/.claude/harnesseed/roots -type f | xargs sha256sum`・`git -C ~/.claude/harnesseed rev-parse HEAD`
  をスナップショット ② dev clone の plugin.json version をテスト用に bump（blueprint は触らない）→
  `claude plugin update` → **セッション再起動** ③ **leaf の無い新規4件目プロジェクト**で
  /harnesseed:harness（既存 proj では already-harnessed ガードで skew パスを通らないため）
  ④ pull 実行**前に**検証: skew 警告＋pull 提案が出る / leaf は作られる / planted.json と roots/ の
  sha256 前後一致 / HEAD 不変かつ status --porcelain 空 ⑤ テスト bump を revert、4件目を削除
- P1 クリティーク未検証14件の resume（wf_d26813df-c4a）
- P2〜P5 のフェーズ別クリティーク workflow ＋ 最終 whole-branch レビュー
- ライブ機能検証: scout 実走（stock 更新を兼ねる）/ checkup 実走 / grow 1サイクル /
  pull 実チェーン（marketplace update → plugin update → 再起動 → pull）
- ひかる確認のうえ push（brainstorm uninstall は実施済み。マーケットは dev ローカル版に
  差し替え中 — 公開時は GitHub 版へ戻す）
