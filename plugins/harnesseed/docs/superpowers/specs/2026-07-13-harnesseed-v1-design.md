# Harnesseed v1 — 設計仕様 (Design Spec)

- **日付**: 2026-07-13
- **ステータス**: 設計合意済み（フルv1.0＝5フェーズ全部をこの開発で作り切る）
- **前身**: `../../bootstrap-log/` の trend-scout #0・design-critique #1、および 2026-06-18 の旧設計仕様（First Sprout MVP）。本書は旧specを「tech-teku-toolkit の1プラグイン」構造へ更新し、スコープをフルv1.0に拡大した改訂版。
- **配布先**: 既存の GitHub repo `Barusamico3839/tech-teku-toolkit`（継続利用）。brainstorm-harness は本開発で完全削除する。
- **開発の流儀**: 本気ブートストラップ流（旧spec§9踏襲）— 各段階で dynamic workflow によるクリティーク＋bootstrap-log 記録。

---

## 1. これは何か（ビジョン）

**Harnesseed** は、ハーネスエンジニアリングのフレームワーク。最大の特徴は **Harnesseed 自身がハーネスエンジニアリングで作られ、ハーネスエンジニアリングで育つ**（究極のbootstrap）こと。

ユーザーがプロジェクトで Harnesseed を「発芽」させると:

- 自分のハーネス思想を会話でゼロから言語化できる（philosophy）
- 最新のハーネスエンジニアリング定石・動向を調べて「取り入れますか？」と提案・ストックしてくれる（trend-scout）
- いつものハーネス設定（settings/plugins/marketplace/MCP）の健康診断を受けられる（checkup）
- 使う中で見つけた良い手法で、自分のインスタンスが半自動（propose→approve→apply）で育つ（grow）
- 上流（本家）の改善を、自分の個人化を壊さずに取り込める（pull）

対象はひかる本人に加え、GitHub公開後は友達も。さらに**初〜中堅エンジニアの勉強用**: Harnesseed 自身が「ハーネスエンジニアリングを実演して見せる教材」になる（learn/ と bootstrap-log）。

---

## 2. 中心メタファーと用語

```
🌳 tree    … 本家repo = tech-teku-toolkit（main はひかるのみ。友達はPR）
   │ 種をばらまく（marketplace 公開 → 友達が install）
   ▼
🌱 seed    … 配布プラグイン = plugins/harnesseed/（blueprint＝遺伝設計図を運ぶ）
   │ 発芽（/harnesseed:harness で「はい」）
   ▼
🌿 seedling … ユーザー環境で芽吹いた、育つ自分のインスタンス
     ├─ 🪵 roots … 吸収した正典の pristine コピー（継承層＝3-way merge の base）
     ├─ 🌿 stem  … ユーザー級の幹。全プロジェクト横断で育つ本体（個人化層）
     └─ 🍃 leaf  … プロジェクトごとの葉（マーカー＋プロジェクト固有設定）
```

- **旧specからの変更**: tree は harnesseed 単独repoではなく、アンブレラ・マーケット **tech-teku-toolkit repo** になった。「1本の木が複数の種類の種を実らせる」余地ができ、メタファーは崩れない。
- よく育った seedling は、いずれ自分の tree になれる（友達の fork が各自の本家になる）。`tree → seed → seedling → tree` と循環する。
- 初回ユーザーが覚えるのは **tree / seed / seedling / stem** の4語だけ。blueprint / roots / leaf は説明語。
- メタファーは**ニックネーム**。ドキュメントは常に literal な仕組み（上流repo / 配布プラグイン / ユーザーグローバル層 / プロジェクト層）を主役にする。

---

## 3. リポジトリ最終形

```
tech-teku-toolkit/                       # 🌳 tree = 本家repo（main = ひかるのみ、友達はPR）
├── .claude-plugin/
│   └── marketplace.json                 # マーケット: harnesseed を列挙（brainstorm削除）
├── plugins/
│   └── harnesseed/                      # 🌱 seed = 配布プラグイン（installする単位）
│       ├── .claude-plugin/plugin.json   #   name: "harnesseed" → /harnesseed:<cmd>
│       ├── skills/
│       │   ├── harness/SKILL.md         #   P1 発芽スキル
│       │   ├── scout/SKILL.md           #   P2 trend-scout
│       │   ├── checkup/SKILL.md         #   P3 健康診断
│       │   ├── grow/SKILL.md            #   P4 半自動アップデート
│       │   └── pull/SKILL.md            #   P5 上流取り込み
│       ├── hooks/
│       │   ├── hooks.json               #   SessionStart 登録
│       │   └── harnesseed-nudge.sh      #   マーカー検知→注入（超軽量）
│       ├── blueprint/                   #   ★正典（seed が運ぶ遺伝設計図）
│       │   ├── VERSION                  #     semver
│       │   ├── manifest.json            #     per-file content hash
│       │   ├── philosophy.md            #     ハーネス思想の正典（ひかるとの会話で言語化）
│       │   ├── invariants.md            #     Misevolution hard rules
│       │   ├── evals/                   #     held-out 受け入れ集合（ハーネスは編集不可）
│       │   ├── scout-angles.md          #     P2 の4アングル定義
│       │   ├── checkup-checklist.md     #     P3 の~12カテゴリチェックリスト
│       │   ├── meta-harness.md          #     P5 で bootstrap-log から蒸留
│       │   └── trend-stock/
│       │       └── 2026-06-18-trend-scout-0.md   # 静的同梱（差別化価値を初日に）
│       ├── learn/                       #   勉強場（P5 で拡充）
│       │   └── README.md
│       └── docs/                        #   bootstrap-log + specs（旧 harnesseed/ の残骸を移設）
│           ├── bootstrap-log/
│           └── superpowers/specs/
├── .github/workflows/test.yml           # CI: harnesseed 用に書き換え
├── README.md                            # 全面書き直し（harnesseed が主役）
├── LICENSE / SECURITY.md                # 維持
└── .gitignore                           # 維持（.superpowers/ は ignore 済み）
```

**構造上の設計判断**:

1. **blueprint/ はプラグインの中**。友達が install したとき blueprint がプラグインキャッシュとして届く＝「seed が遺伝設計図を運ぶ」が literal に成立。スキルからは `${CLAUDE_PLUGIN_ROOT}/blueprint/` で参照。
2. **learn/ と docs/ もプラグインの中**。seed 自身が教材と成長記録を運ぶ。
3. プラグインソースは repo ルート不可（旧critique H-7）→ `plugins/harnesseed/` にネスト。marketplace.json の entry は `{ "name": "harnesseed", "source": "./plugins/harnesseed" }`。

**削除するもの（brainstorm 関連すべて・完全に不要）**:

- `plugins/brainstorm-harness/` 一式
- `install/` 一式（clbs, clbs-run, brainstorm.json, sunrise-cream.json, setup.sh, test-setup.sh）
- README の brainstorm 記述、marketplace.json の brainstorm エントリ
- ローカルのみ: `.superpowers/sdd/`（gitignore 済み。作業ツリーから削除）
- 移設完了後、開発残骸の `../harnesseed/` ディレクトリ（docs のみ）も削除

---

## 4. 発動の仕組み（P1）

原則: **検知＋注入（フック）／質問（モデル）／作業（スキル）**。SessionStart フックは制御端末を持たず、ユーザー入力を読めず、起動をゲートできない（公式ドキュメント明記）ため。

### SessionStart フック（検知＋注入のみ・超軽量）

`hooks/harnesseed-nudge.sh`: プロジェクト内マーカーの存在チェック（`test -e` 1〜2回）だけで即 exit。ネットワーク/git 呼び出し禁止。3状態:

| プロジェクトの状態 | フックの挙動 |
|---|---|
| マーカー無し | `additionalContext` に注入:「未ハーネス。`/harnesseed:harness` をユーザーに提案し、**勝手に進めず必ず聞け**」 |
| `.harnesseed/declined` あり | 何も注入しない（オプトアウト尊重） |
| `.harnesseed/leaf.json` あり | ハーネス済み。stem への軽いポインタのみ注入（全 stem 注入禁止＝context rot 防止） |

### 質問するのはモデル

注入された指示に従い、会話で「🌱 このプロジェクト、Harnesseed で発芽させますか？」と一度だけ聞く。「一度だけ」は**マーカーのファイル状態**で担保（フックの記憶ではない）。

### 作業するのは `/harnesseed:harness` スキル（承認後・冪等）

1. **stem が無ければ生成**: `${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed/` に **git init** して作る
2. **生成を見える化**: 「ここに stem を作りました。中身はこれ、理由はこれ」（初回＝最大の教育機会）
3. **芽吹き元を記録**: stem の `manifest.json` に `seed_version` + blueprint content hashes + `planted_at`
4. **roots を作る**: `${CLAUDE_PLUGIN_ROOT}/blueprint/` の正典を pristine コピーとして `roots/` に保存
5. **leaf を注入**: プロジェクトに `.harnesseed/leaf.json`（マーカー + stem へのパス + seed_version）
6. **philosophy 会話**: 正典の具体的スタンスを叩き台に「Harnesseed はこう考える。賛成/反対/修正？」で個人化（白紙にしない）。結果は stem の上書き層に保存
7. **trend-stock 提示**: 同梱の精査済みトレンドストックを見せる
8. 明示的「いいえ」→ `.harnesseed/declined` を書く

ユーザーが手で打つコマンドは実質ゼロ（nudge 自動、`/harnesseed:harness` は能動呼び出し用の予備）。

---

## 5. seedling の構造と統治の最小核（P1）

### stem の中身（`${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed/` = git repo）

```
~/.claude/harnesseed/               # 🌿 seedling の本体（ユーザー級・全プロジェクト横断）
├── manifest.json                   # 芽吹き元: seed_version + blueprint hashes + planted_at
├── roots/                          # 🪵 正典の pristine コピー（継承層・編集しない）
│   └── philosophy.md ほか          #   = 3-way merge の base
├── stem/                           # 🌿 個人化の上書き層（育つ部分）
│   └── philosophy.md               #   正典の見出し骨格を保ったまま個人化
├── trend-stock/                    # 精査済みトレンドの生きたストック
│   └── index.json                  #   採用/却下の台帳（追記型）
├── checkups/                       # P3 の診断レポート置き場
└── growth-log.md                   # P4 の軌跡ログ（追記型）
```

- プロジェクト側には `.harnesseed/leaf.json` 🍃 だけ。
- **roots（pristine）と stem（上書き）の分離**が肝: `/harnesseed:pull` で roots=base / stem=mine / 新blueprint=theirs の 3-way merge に落とせる。

### 統治の最小核（P1 に最初から入れる・後付け不能な土台）

1. **バージョン**: `blueprint/VERSION`（semver）+ `blueprint/manifest.json`（per-file content hash）
2. **芽吹き元の記録**: stem マニフェストに必ず保存
3. **git-backed stem**: 各 propose→approve→apply を1コミット（machine-readable trailer）に落とす土台。ロールバック/監査が無料
4. **継承層と上書き層の分離**（roots / stem）
5. **Misevolution プレースホルダ**: `blueprint/invariants.md` に hard rule を明記、`blueprint/evals/` にハーネスが編集できない held-out 置き場（実体は P4 で拡充）

---

## 6. フルv1.0 スコープ — 5フェーズ構成

依存関係順。各フェーズは「実装 → 受け入れ検証 → workflow クリティーク → 修正 → bootstrap-log 記録」で締めてから次へ。

| Phase | 名称 | 中身 | 依存 |
|---|---|---|---|
| **P1** | First Sprout | §3〜5 の全部（骨格・発芽・seedling・統治最小核）+ brainstorm 削除 + trend-stock #0 同梱 + README/CI 書き換え | なし |
| **P2** | trend-scout 自動化 | `/harnesseed:scout`（§7） | P1 |
| **P3** | harness-checkup | `/harnesseed:checkup`（§8） | P1 |
| **P4** | grow + Misevolution 統治 | `/harnesseed:grow`（§9） | P2, P3 |
| **P5** | pull + learn + meta-harness | `/harnesseed:pull`・learn 拡充・meta-harness.md 蒸留（§10） | P1〜P4 |

**共通の技術制約**:

- Dynamic Workflow は **mid-run のユーザー入力不可** → propose→approve ゲートは必ず**ワークフローのステージ境界**（workflow が候補を返して終了→会話で承認→スキルが適用）。
- プラグインが同梱できるのは skills/hooks/agents 等。workflow ファイルの自動配布は前提にしない → scout 等は**スキルが workflow スクリプトを組み立てて実行**する。
- spawn される subagent は権限・tool allowlist を継承する（grow の subagent が触れる範囲＝セキュリティ制約として扱う）。

---

## 7. `/harnesseed:scout` の設計（P2）

### パイプライン（3段: 調査 workflow → 会話承認 → 適用）

```
Stage 1: 調査（Dynamic Workflow・自律実行）
  ├─ blueprint/scout-angles.md から4アングルを読む
  │    A: プラットフォーム機能 / B: agentic パターン / C: エコシステム / D: 自己改善研究
  ├─ アングルごとに WebSearch fan-out（4〜8クエリ）→ primary source を WebFetch
  ├─ load-bearing claim を敵対的検証（confirmed / partly / uncorroborated の verdict 付き）
  ├─ stem/trend-stock/index.json の既知リストと dedup（採用済み・却下済みは除外）
  └─ 構造化された候補リストを返して終了 ★workflow はここで終わる

Stage 2: 承認（会話）
  └─ 候補を優先度 Tier 付き（未導入度×効果×検証の堅さ）で提示 →「採用/却下/保留」

Stage 3: 適用（スキル）
  ├─ 採用 → stem/trend-stock/YYYY-MM-DD-scout-N.md 追記 + index.json 更新
  │         = stem に1コミット（trailer: scout-run, source, verdict）
  └─ 却下 → index.json の rejected に記録（二度と再提案しない）
```

### 品質ガードレール（trend-scout #0 の方法論ログ＝一次資料）

- **出典規律**: 数値・固有主張は primary/named source のみ（official docs, arXiv ID, GitHub repo）。SEO/aggregator は maturity signal 扱い
- **recency 判定**: docs の min-version アノテーション、arXiv ID の日付整合
- **hedge 規律**: 行単位で再検証できない数値は `~` 付きで保持
- **アングル定義は blueprint**（`scout-angles.md`）: 正典として上流で育ち、pull で更新が届く

---

## 8. `/harnesseed:checkup` の設計（P3）

### 何を診るか（読み取り専用・ネットワーク不要）

- `${CLAUDE_CONFIG_DIR:-~/.claude}/settings.json`（permissions, enabledPlugins, hooks, outputStyle…）
- インストール済み plugins / marketplaces
- MCP 設定（`.mcp.json` 各層）
- CLAUDE.md（グローバル/プロジェクト）・memory・skills の構成

### 判定フレーム: `blueprint/checkup-checklist.md`

awesome-harness-engineering の **~12カテゴリ taxonomy** をチェックリスト化して blueprint に同梱:

> agent loop / planning / context / tool / skills&MCP / permissions / memory / orchestration / verification / observability / debugging / human-in-the-loop

カテゴリごとに「何を確認するか」「良い状態とは何か」を記述。**observability / permissions / human-in-the-loop が盲点になりやすい**（#0 の知見）ので具体的なプローブを書く。

### 出力

1. **カテゴリ別レポート**: `present / partial / absent` + 根拠（どのファイルのどの設定を見たか）
2. **gap ランキング**: 重要度順の改善提案（見つかった事実に紐づける）
3. 保存先: `stem/checkups/YYYY-MM-DD-checkup.md` = stem に1コミット

### 統治との接続

checkup は**診断と提案だけ**で、設定を一切変更しない。変更は必ず P4 grow のゲートを通る。**scout と checkup が「提案の供給源」、grow が「変更の唯一の通り道」**という一方通行の管路。

### 実装形態

読み取り＋分析だけなので workflow は必須ではない。カテゴリ並列の subagent fan-out はオプション。

---

## 9. `/harnesseed:grow` の設計（P4）

### propose → approve → apply

```
Stage 1: propose（供給源から提案を組み立てる）
  ├─ 供給源: scout の採用ストック / checkup の gap / ユーザー自身の気づき
  ├─ 提案は構造化 delta（ACE流・丸ごと rewrite 禁止）:
  │    { 対象ファイル, 変更内容, evidence, rationale, regression-risk }
  ├─ 5 anti-pattern スクリーニング:
  │    instruction bloat / 矛盾 / over-specificity / prompt theater / cargo-cult
  └─ 決定的 invariants チェッカー（シェル/スクリプト）を通す（下記）

Stage 2: approve（会話）
  └─ 1提案ずつ evidence・rationale・regression-risk を見せて承認を取る

Stage 3: apply
  ├─ 1提案 = stem に1コミット（trailer: Technique-Id / Source / Seed-Version / Evidence）
  ├─ 適用後に held-out eval（blueprint/evals/）を実行 → 失敗なら自動 git revert
  └─ growth-log.md に追記（採用/却下/自動revert を全部記録＝trajectory 監視）
```

### Misevolution 統治（本格実装）

1. **scope-restriction allowlist**（編集可能サーフェスの明示）:
   - 自由に編集可: `stem/`・`trend-stock/`・`growth-log.md`（seedling の個人化層）
   - 明示承認＋バックアップ必須: `~/.claude/settings.json`・グローバル CLAUDE.md 等のユーザーハーネス設定（diff を stem に記録）
   - **絶対不可**: `roots/`（pristine）・`blueprint/`（正典）・`blueprint/evals/`（held-out）・**あらゆるプロジェクトのアプリソースコード**
2. **per-run 上限**: 1回の grow で適用できる提案は最大5件
3. **held-out eval の実体**（`blueprint/evals/` — ハーネスが編集できない決定的チェック群）:
   - stem の git 履歴が線形に保たれている / roots が manifest のhashと一致（pristine）
   - stem/philosophy.md が正典の見出し骨格を保持 / index.json が parse 可能かつ追記型
   - 「受け入れ基準を緩める変更」の拒否（invariants.md の hard rule）
4. **invariants チェッカー**: 上記を検査する決定的スクリプト。propose 段階と apply 後の両方で走る。CI にユニットテストを置く
5. **trajectory 監視**: growth-log.md（追記型）+ git trailer で、cycle 跨ぎの drift を後から diff できる

---

## 10. `/harnesseed:pull` + learn + meta-harness（P5）

### `/harnesseed:pull`（上流改善の取り込み）

1. インストール済み seed の `blueprint/VERSION` と stem manifest の記録を比較。新しければ:
2. blueprint ファイルごとに 3-way merge: **base = roots のコピー / mine = stem の個人化 / theirs = 新 blueprint**（`git merge-file` を使用）
3. コンフリクトは会話で提示 → ユーザーが解決
4. 完了後: roots を新 pristine に更新、manifest を新 seed_version + hashes に更新、stem に1コミット
5. **テスト方法**: 開発中に blueprint の VERSION を bump して pull を通す

### learn/ 拡充

3ドキュメント: ①how-it-works（literal な仕組み解説）②glossary（4語＋メタファーの対応表）③bootstrap-case-study（docs/bootstrap-log を教材として読むガイド）。

### meta-harness.md の蒸留

P1〜P4 の bootstrap-log が揃った時点で「Harnesseed 自身がどう作られたか」を `blueprint/meta-harness.md` に蒸留する。旧spec が先送りした理由（存在しないビルド過程の作文になる）は、この時点では消えている。

---

## 11. 受け入れ基準（フェーズ別・着手前に固定）

- **P1**:
  1. e2e 完走: ローカルパスで `marketplace add` → `install` → 未ハーネスプロジェクトで起動→nudge → 「はい」→ seedling 生成（git-backed stem + roots + leaf）→ philosophy 会話 → trend-stock 閲覧
  2. 決定的チェック: `claude plugin validate` / 各 JSON parse / blueprint manifest の hash 一致
  3. dogfooding: ひかるが実プロジェクト2件で発芽
  4. declined フロー: 「いいえ」→ `.harnesseed/declined` → 以後 nudge が出ない
- **P2**: scout 実行→検証済み候補提示→承認→stem に1コミット追記。**却下候補が再提案されない**
- **P3**: 実環境で checkup → 12カテゴリの gap レポートが stem に保存される
- **P4**: 提案→承認→適用→**git revert でロールバック**が通る。invariants 違反の提案が**自動で弾かれる**テストケースが通る
- **P5**: blueprint VERSION bump → pull → 個人化を保持したまま上流変更が入る。コンフリクトケースも1つ通す

## 12. CI（test.yml 書き換え）

- marketplace.json / plugin.json / hooks.json の JSON parse 検証
- blueprint/manifest.json の hash と実ファイルの一致検証（スクリプト1本）
- フックスクリプトの3状態ユニットテスト（マーカー無し / declined / leaf）
- P4: invariants チェッカーのユニットテスト
- P5: 3-way merge のテストケース

brainstorm の test-setup.sh 的な「ホスト設定の統合テスト」は不要（harnesseed はホスト設定を触らない。grow の設定編集は承認ゲート越しで、CI 対象はチェッカーのみ）。

## 13. 開発プロセスと git 運用

- 開発は tech-teku-toolkit クローンの **`harnesseed` ブランチ**で直接行う（案B）。コミットは既存スタイル（conventional prefix・英語）。
- **push はひかるの確認を得てから**。main へのマージも同様。
- フェーズごとに: 実装 → 受け入れ検証 → **workflow クリティーク**（5レンズ敵対的レビュー）→ 修正 → **bootstrap-log 記録** → コミット。
- philosophy.md の正典オーサリングは **P1 実装中のひかるとの会話**で行う（インタラクティブな工程として計画に明記）。
- 旧 `harnesseed/docs/` の残骸（spec・bootstrap-log 2本）は P1 で `plugins/harnesseed/docs/` へ移設し、空になったディレクトリは削除。
- `toolkit-production/` は今回触らない。

## 14. リスクと対応

| リスク | 対応 |
|---|---|
| SessionStart フックの仕様変化 | フックは検知＋注入のみの最小結合。公式ドキュメント準拠を CI ではなく手動 dogfooding で確認 |
| workflow の mid-run 入力不可 | 全フェーズで承認ゲートをステージ境界に置く設計を固定済み |
| grow の暴走（Misevolution） | §9 の5層統治（allowlist / 上限 / held-out eval / チェッカー / trajectory ログ） |
| メタファーの破綻 | literal 主役・メタファーはニックネーム、を全ドキュメントで貫く |
| trend-stock #0 の陳腐化（2026-06-18時点） | P2 完成後に scout を1回実走して stock を更新（dogfooding を兼ねる） |
