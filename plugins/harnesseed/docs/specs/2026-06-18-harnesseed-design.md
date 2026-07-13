# Harnesseed — 設計仕様 (Design Spec)

- **日付**: 2026-06-18
- **ステータス**: 設計合意済み（MVP＝サブプロジェクト1「最初の芽 / First Sprout」を実装対象とする）
- **関連ログ**: `docs/bootstrap-log/2026-06-18-trend-scout-0.md`（最新動向リサーチ）、`docs/bootstrap-log/2026-06-18-design-critique-1.md`（5レンズ設計クリティーク）

---

## 1. これは何か（ビジョン）

**Harnesseed** は、ハーネスエンジニアリングのフレームワーク。最大の特徴は **Harnesseed 自身がハーネスエンジニアリングで作られ、ハーネスエンジニアリングで育つ**（究極のbootstrap）こと。

ユーザーがプロジェクトでHarnesseedを「発芽」させると：
- 自分がいつも使うハーネス設定（Claude Codeのsettings/plugins/marketplace/MCP）の健康診断を受けられる（※自動化は後続サブプロジェクト）
- 最新のハーネスエンジニアリング定石・動向を調べてきて「最近こういうのもありますが取り入れますか？」と提案・ストックしてくれる（※自動化は後続。MVPでは静的ストックを同梱）
- 自分のハーネス思想を会話でゼロから言語化できる
- 使う中で見つけた良い手法で、自分のインスタンスが半自動（提案→承認→適用）で育つ（※grow機構は後続）

対象は自分（ひかる）に加え、将来GitHub公開して友達も使える。さらに**初〜中堅エンジニアの勉強用**：Harnesseed自身が「ハーネスエンジニアリングを実演して見せる教材」になる。

---

## 2. 中心メタファー（生物学的に導出可能）

```
🌳 tree    … GitHubにある大本の本家repo（ひかるのみ main に書ける。友達はPR）。
   │           成熟した木＝正典の源。中に blueprint/（philosophy 等の遺伝設計図）。
   │ 種をばらまく scatter（marketplace公開 → 友達が install）
   ▼
🌱 seed    … ばらまかれる単位＝インストールするプラグインそのもの（blueprintを運ぶ）。
   │ 発芽 germinate（/harnesseed:harness で「はい」）
   ▼
🌿 seedling … ユーザー環境で芽吹いた、育つ自分のインスタンス。3部位を発達させる：
     ├─ 🪵 roots … 吸収した正典 philosophy（＝blueprintのpristineコピー＝継承層／3-way mergeのbase）
     ├─ 🌿 stem  … ユーザー級の幹。全プロジェクト横断で育つ本体（個人化philosophy・baseline・トレンドstock・採用ログ）＝継承層への上書き層
     └─ 🍃 leaf  … プロジェクトごとの葉（ハーネス済みマーカー＋プロジェクト固有設定）
```

締め：**よく育った seedling は、いずれ自分の tree になれる**（友達のforkが各自の大本になる）。`tree → seed → seedling →(roots/stem/leaf)→ tree` と循環する。これが「自分のHarnesseedと友達のHarnesseedは違くていい」を満たす。

副産物：**roots（継承した正典pristineコピー）と stem（個人化の上書き）の分離**は、将来の「上流改善の取り込み」を *roots=merge base / stem=mine / 新blueprint=theirs* の3-way mergeに落とせる、統治上の要請にそのまま一致する。

### 用語（初回ユーザーが覚えるのは太字の4語だけ）
| 語 | 役割（literal） | メタファー |
|---|---|---|
| **tree** | 上流の本家GitHubリポジトリ（ひかる管理） | 成熟した木 |
| **seed** | 配布されるプラグイン（installするもの） | ばらまかれる種 |
| **seedling** | ユーザーごとの育つインスタンス | 発芽した苗 |
| blueprint | tree内の正典コンテンツ（philosophy等） | 種の遺伝設計図 |
| roots | seedlingが吸収した正典のpristineコピー（継承層） | 根 |
| **stem** | ユーザー級・全プロジェクト横断で育つ本体（個人化層） | 幹 |
| leaf | プロジェクトごとのマーカー＋設定 | 葉 |

> メタファーは**ニックネーム**。ドキュメントは常に「literalな仕組み」を主役にし、メタファーは覚え方として添える（破綻させない・暗記させない）。

---

## 3. リポジトリ構造（tree＝1つのハイブリッドrepo）

```
harnesseed/                              # the tree（GitHub大本。main保護＝ひかるのみ。友達はPR）
├── .claude-plugin/
│   └── marketplace.json                 # 【マーケット】友達: /plugin marketplace add <repo>
├── plugins/
│   └── harnesseed/                       # 【seed＝配布プラグイン】
│       ├── .claude-plugin/
│       │   └── plugin.json               # name: "harnesseed" → 呼び出しは /harnesseed:<cmd>
│       ├── skills/
│       │   └── harness/                  # 発芽スキル: seedling生成＋philosophy会話＋trend-stock提示
│       │       └── SKILL.md              # portable SKILL.md標準で記述
│       └── hooks/
│           └── hooks.json                # SessionStart: マーカー検知→nudge注入のみ（超軽量）
├── blueprint/                            # 【正典】tree内の遺伝設計図（ひかるのみ編集）
│   ├── VERSION                           # seed/blueprintのsemver
│   ├── manifest.json                     # 各blueprintファイルのcontent hash（芽吹き元記録用）
│   ├── philosophy.md                     # ★MVP唯一のオーサリング対象：ハーネス思想の正典
│   ├── invariants.md                     # 「受け入れ基準は自己編集で緩められない」hard rule（Misevolutionプレースホルダ）
│   └── trend-stock/                      # 静的・手キュレーションのトレンドストック
│       └── 2026-06-18-trend-scout-0.md   # trend-scout #0 を同梱（差別化価値を初日に）
├── learn/                                # 【勉強場】MVPは入口READMEのみ（中身は後続）
│   └── README.md
├── docs/
│   └── bootstrap-log/                    # bootstrapの記録（このspec・critique・scout #0…）
└── README.md                            # 「このrepoはN個の顔を持つ」マップ＋glossary
```

設計判断（クリティーク反映）：
- **プラグインソースはrepoルート不可**。`marketplace.json` の entry は `{ "name": "harnesseed", "source": "./plugins/harnesseed" }` とネスト配置（H-7）。
- `plugin.json` の `name` は `harnesseed`（予約名と衝突しないこと。公開前に `claude plugin validate` 実行）。
- 4つの顔（マーケット/seed/正典/勉強場）は**ディレクトリ名で役割を明示**し、READMEに「N hats マップ」を置く（学習者の理解のため、H-3）。

---

## 4. 発動の仕組み（Claude Code実現可能性に準拠）

> 重要：SessionStartフックは**制御端末を持たず・ユーザー入力を読めず・起動をゲートできない**（公式ドキュメント明記）。「フックが質問して分岐」は**不可能**。よって**検知＋注入（フック）／質問（モデル）／作業（スキル）**に分解する。

### フックの責務（検知＋注入のみ・超軽量）
プラグイン同梱の SessionStart フックは、プロジェクト内マーカーを安いファイル存在チェックで読むだけ。ネットワーク/git呼び出し禁止。3状態：

| 状態 | フックの挙動 |
|---|---|
| マーカー無し | `additionalContext` に注入：「このプロジェクトは未ハーネス。`/harnesseed:harness` をユーザーに提案し、**勝手に進めず必ず聞け**」 |
| `.harnesseed/declined` 有り | 何も注入しない（オプトアウトを尊重） |
| `.harnesseed/leaf.json` 有り | ハーネス済み。軽いポインタのみ注入（stem全体は注入しない＝context rot防止） |

### 質問するのはモデル
注入された指示に従い、Claudeが会話で「🌱 このプロジェクト、Harnesseedで発芽させますか？」と一度だけ聞く。「一度だけ」は**マーカーのファイル状態**で担保（フックの記憶ではない）。

### 作業するのはスキル `/harnesseed:harness`（ユーザー承認後）
「はい」で起動。冪等。手順：
1. **stem が無ければ生成**（種まきはここに吸収＝手動 `/…:plant` は廃止）。場所は `${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed/`（クロスプラットフォーム）。**git-backed**で初期化。
2. **生成を見える化**：「`<path>` に stem を作りました。中身はこれ、理由はこれ」と表示（初回＝最大の教育機会）。
3. **stem マニフェストに芽吹き元を記録**：`seed_version` ＋ blueprint content hashes ＋ `planted_at`（統治C-3）。
4. **roots（継承層）を作る**：`blueprint/philosophy.md` を pristine コピーとして roots に保存（将来の3-way merge base）。
5. **project leaf を注入**：プロジェクトに `.harnesseed/leaf.json`（マーカー＋stemへのリンク＋seed_version）。
6. **philosophy.md 会話**：正典の具体的スタンスを叩き台に「Harnesseedはこう考える。賛成/反対/修正？」で引き出す（白紙にしない）。結果は stem の個人化層（上書き）に保存。
7. **トレンドストック提示**：同梱の `trend-stock/` を「精査済みトレンドの生きたストック」として見せる。
8. 明示的「いいえ」→ `.harnesseed/declined` を書く。

→ ユーザーが手で打つコマンドは実質ゼロ（nudgeは自動、`/harnesseed` は能動呼び出し用の予備）。摩擦ゼロを保ったままドキュメント準拠。

---

## 5. 統治の最小核（MVPに最初から入れる・後付け不能な土台）

1. **seed/blueprint のバージョン**：`blueprint/VERSION`（semver）＋ `manifest.json`（per-file content hash）。
2. **芽吹き元の記録**：stem マニフェストに「sprouted-from `seed_version` ＋ hashes ＋ `planted_at`」を必ず保存。
3. **git-backed stem**：stem は git リポジトリ。将来の各 propose→approve→apply は1コミット（trailer: technique id, source, seed_version）に落とす（ロールバック/監査/DGM風archiveを無料で得る）。
4. **継承層と上書き層の分離**：roots（pristineコピー＝merge base）と stem個人化（上書き）を別物として保持。`philosophy.md` は**正典の見出し骨格を保ったまま**個人化（白紙でなく、上流追記がmergeできる形）。
5. **Misevolutionプレースホルダ**：`blueprint/invariants.md` に「自己編集は受け入れ基準を緩めてはならない」hard rule を明記し、ハーネスが編集できない eval 置き場を予約（中身は後続grow sub-projectで）。

> 本格的な eval/grow 統治（held-out eval実体・trajectory監視・scope-restriction allowlist・per-run上限）は **grow サブプロジェクト**着手前に実装。土台（1〜5）だけMVPで先に入れる。

---

## 6. MVP（サブプロジェクト1「最初の芽 / First Sprout」）の確定スコープ

**作る：**
- tree repo 骨格：`marketplace.json` ＋ `plugins/harnesseed/`（`plugin.json`、`skills/harness/`、`hooks/hooks.json`）
- `blueprint/`：`VERSION` ＋ `manifest.json` ＋ `philosophy.md`（会話で言語化＝思想の明文化）＋ `invariants.md` ＋ `trend-stock/2026-06-18-trend-scout-0.md`（同梱）
- 発動：SessionStartフック（検知＋注入）＋ `/harnesseed:harness` スキル（§4の手順1〜8）
- 統治の最小核（§5の1〜5）
- `README.md`（N hats マップ＋4語glossary）、`learn/README.md`（入口のみ）

**作らない（後続サブプロジェクトへ）：**
- `meta-harness.md`（存在しないビルド過程の作文になる→bootstrap-logから漸進的に育てる）
- trend-scout の**自動化**（#0は静的同梱で代替）／harness-checkup の**自動化**
- grow（半自動アップデート機構）と本格Misevolution統治
- `/harnesseed:pull`（上流改善の3-way merge取り込み）／learn拡充／友達PRフロー

**矛盾の解消**：発動フローに「trend-scout/checkup を実行」とは書かない（それらは未実装のため）。MVPの発動が起動するオーサリングは **philosophy.md 会話の1本のみ**。

**MVP受け入れ基準（着手前に固定）**：
- 友達/ひかるが「marketplace add → install → 起動時にnudge → はい → seedling(stem git-backed + roots + leaf)生成 → philosophy.md会話 → trend-stock閲覧」をエンドツーエンドで完走できる。
- `claude plugin validate` が通る。`marketplace.json`/`leaf.json`/blueprint が schema/parse を満たす（決定的チェック）。
- ひかるが実プロジェクト2件で発芽をdogfoodingする。

---

## 7. ランタイム方針（後続実装時の制約メモ）

trend-scout / checkup / grow を将来作る際、saved **Dynamic Workflows**（`.claude/workflows/`、structured `args`）にするか手組みかを明示的に決める。
- **重要制約**：Dynamic Workflows は **mid-run のユーザー入力不可**。よって「propose→承認」ゲートは1つのworkflow内に置けず、**ステージ境界**にする（本specを作る過程の trend-scout/critique workflow で実体験済み）。
- spawnされたsubagentは acceptEdits ＋ tool allowlist を継承する（growのsubagentが触れる範囲＝セキュリティ制約として扱う）。
- `/deep-research` バンドルが fan-out→cross-check→vote→cited report の参照アーキテクチャ。

---

## 8. 後続サブプロジェクト（ロードマップ）

| # | 名称 | 中身 |
|---|---|---|
| 2 | trend-scout 自動化 | Web fan-out＋敵対的検証＋ストック化。trend-scout #0 の方法論ログを一次資料に。差別化価値の自動更新。 |
| 3 | harness-checkup | settings/plugins/marketplace/MCP の健康診断（いつも通りか）。awesome-harness-engineering ~12カテゴリでgap分析。 |
| 4 | grow | 半自動アップデート（提案→承認→適用）＋本格Misevolution統治（held-out eval実体・scope allowlist・per-run上限・anti-patternスクリーニング）＋tiered verification。 |
| 5 | 上流還元＆learn拡充 | `/harnesseed:pull`（3-way merge）／友達PRフロー／勉強ドキュメント拡充／meta-harness.md育成。 |

---

## 9. 各段階でのクリティーク習慣（運用ルール）

本プロジェクトは「各段階で設計をクリティカルに再評価しながら、確認して進める」を運用ルールとする。trend-scout / critique は dynamic workflow を使ってよい。bootstrap-log に各回を記録し、Harnesseed自身の育ちの一次資料にする。
