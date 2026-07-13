# Bootstrap Case Study — Harnesseed が Harnesseed を作った記録の読み方

`../docs/bootstrap-log/` は演出ではなく、本物の開発過程の一次記録。ハーネスエンジニアリングを
「実演で」学ぶには、この順で読むのがおすすめ。

## 読む順番

1. **`2026-06-18-trend-scout-0.md`** — 最初のトレンド調査。4アングルの fan-out、
   敵対的検証で「PostToolUse は block 不可」などの誇張を捕まえた記録。
   `/harnesseed:scout` の方法論はこのログから蒸留された（§4 methodology が実装仕様の親）。
2. **`2026-06-18-design-critique-1.md`** — 最初の設計への5レンズ敵対的レビュー。
   「フックが質問して分岐」が物理的に不可能なこと、バージョン管理の欠落など、
   着手前に4つの重大な穴を潰した。**作る前に壊す**の実例。
3. **`2026-07-13-design-critique-2.md`** — フルv1.0 spec への find→verify 2段レビュー
   （30 findings → 確認27 / 反証3）。検証者が実機検証で「二重バージョンの非連動が
   update を no-op にする」を実証した回。**指摘自体を疑う（verify 段）**の価値がわかる。
4. **`2026-07-13-p1-critique-3.md`** — 実装への同型レビュー。plan のコード例に由来する
   欠陥（trailer が機械可読でない・cwd 相対マーカー・CI ゲートの `|| true`）を捕捉。
   **プランは出発点であって根拠ではない**の実例。

## このケーススタディが実演していること

- spec → plan → implement → verify の各段に敵対的レビューを挟む（レビューは贅沢品ではなく工程）
- 決定的チェック（hash・テスト・CI）を最優先し、LLM 判定は advisory に留める
- 記録を追記型で残す — このファイル自体、その記録から書かれた（`../blueprint/meta-harness.md` も参照）
