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
| governed operation（承認＋1コミット） | 要約 view の再生成のみ: `trend-stock/summary.md`・`growth-log-summary.md`。**本体ファイル（growth-log.md・index.json）は無期限 append-only で切り詰めない**（旧「rotation」は廃止 — 追記型の機械検査と構造矛盾するため。肥大は要約 view を第一参照にすることで吸収する） |
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
7. `stem/philosophy.md` は正典（`roots/philosophy.md`）の**全見出しを保持**しなければならない
   （見出しの追加は自由・削除は不可。ファイル削除も骨格喪失として fail）。見出し包含は
   チェッカーが機械検査する — pull の 3-way merge は mine 側がこの骨格を保つことに依存する。
