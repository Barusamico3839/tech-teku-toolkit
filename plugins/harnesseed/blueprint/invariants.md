# Harnesseed Invariants（統治のハードルール・正典）

これは人間可読の hard rules。決定的な検査は `evals/check-invariants.sh` が行い、
grow の apply コミットはこのゲートに失敗すると自動 git revert される（P4 で全項目が有効化）。
Harnesseed は tamper-proof を主張しない。ここにあるのは「grow パイプラインからは編集禁止であり、
パイプライン外の改竄も必ず検知される（tamper-evident）」という契約である。

## 編集サーフェス（allowlist・default-deny）

| 区分 | 対象 |
|---|---|
| 自由に編集可 | `stem/` |
| 追記のみ可 | `trend-stock/index.json`（id 単調増加・既存エントリは status 以外書換禁止）・`trend-stock/*-scout-*.md`（新規追加のみ）・`checkups/`（新規追加のみ）・`growth-log.md`（追記のみ） |
| governed operation（承認＋1コミット） | `trend-stock/summary.md` 再生成・growth-log の rotation |
| 特定ゲートのみ | `planted.json`・`roots/` — 書けるのは初回発芽と /harnesseed:pull だけ。同一の1コミットで更新する |
| 提案出力のみ（v1 は直接編集しない） | ユーザー級/プロジェクト級ハーネス設定（settings.json・CLAUDE.md・.mcp.json・hooks 等）。permissions/hooks を緩和する diff は提示時に明示ハイライトする |
| 絶対不可 | プラグインキャッシュの `blueprint/`・あらゆるプロジェクトのアプリソースコード |

この列挙は網羅的である。プロジェクトツリー内で列挙されていないパスは
すべて「アプリソースコード」として絶対不可に落ちる（default-deny）。

## ハードルール

1. 1回の grow で適用できる提案は最大 **5件**。
2. 1提案 = seedling repo に1コミット。machine-readable trailer（Technique-Id / Source / Seed-Version / Evidence）必須。
3. 自動 git revert に接続できるのは決定的チェックのみ。LLM-judge の判定は advisory（人間承認の材料）に留める。
4. `planted.json` を変更するコミットは「初回発芽」または「pull」の trailer を持たなければならない。
5. grow は毎 run 冒頭に blueprint 整合検証を行う: plugin version が planted.json より新しい → pull へ誘導して中断。
   version 同一なのに hash 不一致 → tamper 疑いとして hard-stop。
6. 受け入れ基準・invariants・チェッカーを弱める変更は、protected ファイル（planted.json・roots/）への
   diff 検出として機械的に fail する。この規則自体を緩める提案は却下される。
