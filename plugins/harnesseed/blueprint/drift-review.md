# Drift Review（累積ドリフト監査の正典）

grow の各 apply は個別に invariants ゲートを通るが、**cycle を跨いだ劣化**（少しずつの
instruction bloat・矛盾の蓄積・基準の意味的な軟化）は per-edit ゲートでは捕まらない
（Misevolution, arXiv:2509.26354）。drift review はそれを見る定期監査。

## 発火条件（grow Stage 4 が毎 run 判定）

次のいずれかで発火する:
1. 前回 drift review 以降の**適用済み提案が累計 10 件以上**
   （growth-log.md の適用記録と checkups/ 内の最新 drift-review の日付から機械的に数える）
2. 前回 drift review から **90 日**経過（初回は germination から起算）

## レビューの3入力

1. **growth-log + trailer の集約**: 前回 review 以降の全適用について
   Technique-Id / Source / 対象ファイルを表にする（何がどこから入ったか）
2. **roots ↔ stem の全体 diff 要約**: 個別 delta でなく累積結果を見る。
   stem が正典からどれだけ・どの方向に離れたかを要約する
3. **累積 anti-pattern 再スクリーニング**: stem/ 全体（現在形）に対して 5 anti-pattern
   （instruction bloat / 矛盾 / over-specificity / prompt theater / cargo-cult）を
   改めて当てる。**個別コミットでは合格したものが、合算で bloat になっていないか**が主眼

## 出力契約

- `checkups/YYYY-MM-DD-drift-review.md` に保存し、seedling repo に1コミット
  （trailer: `Harnesseed-Event: drift-review` + `Seed-Version`）
- 検出された drift は**提案の供給源**になる: 次の grow Stage 1 に「圧縮・矛盾解消・削除」
  提案として流す（一方通行の管路は維持 — drift review 自身は何も編集しない）

## 判定の規律

- 指摘は必ず具体的な行・見出しを指す（「全体的に冗長」は指摘ではない）
- 削除提案は「何を失うか」を明記する（記録の要約化は可・事実の抹消は不可）
- この文書自体への変更は上流（tree への PR / pull）経由のみ
