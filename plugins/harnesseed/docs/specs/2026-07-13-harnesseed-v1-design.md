# Harnesseed v1 — 設計仕様 (Design Spec) rev.2

- **日付**: 2026-07-13（rev.2 同日: クリティーク#2の確認済み27指摘を反映）
- **ステータス**: 設計合意済み（フルv1.0＝5フェーズ全部をこの開発で作り切る）
- **前身**: `../bootstrap-log/` の trend-scout #0・design-critique #1・design-critique #2、および 2026-06-18 の旧設計仕様（First Sprout MVP）。本書は旧specを「tech-teku-toolkit の1プラグイン」構造へ更新し、スコープをフルv1.0に拡大した改訂版。
- **配布先**: 既存の GitHub repo `Barusamico3839/tech-teku-toolkit`（継続利用）。brainstorm-harness は本開発で完全削除する（§3・§13の移行手順つき）。
- **開発の流儀**: 本気ブートストラップ流（旧spec§9踏襲）— 各段階で dynamic workflow によるクリティーク＋bootstrap-log 記録。

---

## 1. これは何か（ビジョン）

**Harnesseed** は、ハーネスエンジニアリングのフレームワーク。最大の特徴は **Harnesseed 自身がハーネスエンジニアリングで作られ、ハーネスエンジニアリングで育つ**（究極のbootstrap）こと。

ユーザーがプロジェクトを Harnesseed でハーネスすると:

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
   │ 発芽（初回のみ: seedling を生成）
   ▼
🌿 seedling … ユーザー環境で芽吹いた、育つ自分のインスタンス
              = `${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed/`（git repo）全体
     ├─ 🪵 roots/ … 吸収した正典の pristine コピー（継承層＝3-way merge の base）
     ├─ 🌿 stem/  … 個人化の上書き層（正典に対する「mine」。育つ部分）
     └─ 🍃 leaf   … プロジェクトごとの葉（`.harnesseed/leaf.json` マーカー）
```

- **用語の厳密な定義**: 「seedling」= ユーザー級 git repo 全体。「stem」= その中の個人化上書き層サブディレクトリ `stem/` **のみ**を指す。コミットの主語は常に「seedling repo に1コミット」。本書のパス表記は原則 **seedling ルート相対**（例: `trend-stock/index.json`）。
- **発芽は初回の1回だけ**（seedling 生成＝roots/ + stem/ の作成）。2プロジェクト目以降に起きるのは**既存 seedling への leaf 追加**であり、発芽とは呼ばない。
- **旧specからの変更**: tree は harnesseed 単独repoではなく、アンブレラ・マーケット **tech-teku-toolkit repo**。「1本の木が複数の種類の種を実らせる」余地ができ、メタファーは崩れない。
- よく育った seedling は、いずれ自分の tree になれる（友達の fork が各自の本家になる）。
- 初回ユーザーが覚えるのは **tree / seed / seedling / stem** の4語だけ。blueprint / roots / leaf は説明語。
- メタファーは**ニックネーム**。ドキュメントは常に literal な仕組みを主役にする。
- 同名衝突への配慮: 「harnesseed」ディレクトリは3箇所ある（`plugins/harnesseed/`=seed配布元 / `~/.claude/harnesseed/`=seedling本体 / `.harnesseed/`=leafマーカー）。README の glossary（P1）にこの対応表を必ず載せる。

---

## 3. リポジトリ最終形

```
tech-teku-toolkit/                       # 🌳 tree = 本家repo（main = ひかるのみ、友達はPR）
├── .claude-plugin/
│   └── marketplace.json                 # マーケット: harnesseed 単一エントリ（brainstorm削除）
├── plugins/
│   └── harnesseed/                      # 🌱 seed = 配布プラグイン（installする単位）
│       ├── .claude-plugin/plugin.json   #   name: "harnesseed"、version = ★seed version の正
│       ├── skills/
│       │   ├── harness/SKILL.md         #   P1 発芽・ハーネス化スキル
│       │   ├── scout/SKILL.md           #   P2 trend-scout
│       │   ├── checkup/SKILL.md         #   P3 健康診断
│       │   ├── grow/SKILL.md            #   P4 半自動アップデート
│       │   └── pull/SKILL.md            #   P5 上流取り込み
│       ├── hooks/
│       │   ├── hooks.json               #   SessionStart 登録
│       │   └── harnesseed-nudge.sh      #   マーカー検知→注入（超軽量）
│       ├── blueprint/                   #   ★正典（seed が運ぶ遺伝設計図）
│       │   ├── manifest.json            #     per-file sha256 + seed_version（リリーススクリプトで生成）
│       │   ├── philosophy.md            #     ハーネス思想の正典（ひかるとの会話で言語化）
│       │   ├── invariants.md            #     統治 hard rules（人間可読の正典）
│       │   ├── evals/                   #     invariants チェッカー（決定的スクリプト）＋挙動シナリオ
│       │   ├── scout-angles.md          #     P2 の4アングル定義＋「有意変化」の判定基準
│       │   ├── checkup-checklist.md     #     P3 の~12カテゴリチェックリスト
│       │   ├── drift-review.md          #     P4 の drift review 基準
│       │   ├── meta-harness.md          #     P5 で bootstrap-log から蒸留
│       │   └── trend-stock/
│       │       └── 2026-06-18-trend-scout-0.md   # 静的同梱（差別化価値を初日に）
│       ├── learn/                       #   勉強場（P5 で拡充）
│       │   └── README.md
│       └── docs/                        #   開発記録（旧 harnesseed/ の残骸を移設）
│           ├── bootstrap-log/
│           └── specs/                   #   本書もここ（フラット構成。superpowers/ 階層は使わない）
├── .github/workflows/test.yml           # CI: harnesseed 用に書き換え
├── README.md                            # 全面書き直し（harnesseed が主役＋glossary）
├── LICENSE / SECURITY.md                # 維持
└── .gitignore                           # 維持（.superpowers/ は ignore 済み）
```

**構造上の設計判断**:

1. **blueprint/ はプラグインの中**。友達が install したとき blueprint がプラグインキャッシュとして届く＝「seed が遺伝設計図を運ぶ」が literal に成立。スキルからは `${CLAUDE_PLUGIN_ROOT}/blueprint/` で参照する。**例外は pull の theirs 取得のみ**（§10 ステップ0: 更新直後は `${CLAUDE_PLUGIN_ROOT}` が旧版を指すため、`installed_plugins.json` の installPath から新キャッシュを解決する）。
2. **バージョン規約は1本**: seed version の正は `plugin.json` の `version`。`blueprint/VERSION` は置かない。`blueprint/manifest.json` に seed_version と per-file hash をリリーススクリプトが焼き込む。**blueprint に差分があるリリースは plugin.json の version bump 必須**（CI で機械検査。bump 漏れはプラグイン更新が no-op になり pull が永遠に「最新」と誤答するため）。
3. **learn/ と docs/ もプラグインの中**。seed 自身が教材と成長記録を運ぶ。docs 配下はフラット（`docs/specs/`・`docs/bootstrap-log/`）。
4. **tamper-evident であって tamper-proof ではない**（正直な限界の明記）: プラグインキャッシュはユーザー権限で書き込めるため、「ハーネスが物理的に編集できない」領域はローカルに作れない（スキル本体も同じキャッシュに載る bootstrap 限界）。統治は「grow パイプラインからは編集禁止（allowlist）＋パイプライン外の改竄も決定的チェッカーが必ず検知」で担保する（§9）。

**削除するもの（brainstorm 関連すべて・完全に不要）**:

- `plugins/brainstorm-harness/` 一式、`install/` 一式（clbs, clbs-run, brainstorm.json, sunrise-cream.json, setup.sh, test-setup.sh）
- README の brainstorm 記述、marketplace.json の brainstorm エントリ
- ローカルのみ: `.superpowers/sdd/`（gitignore 済み。作業ツリーから削除）
- 移設完了後、開発残骸の `../harnesseed/` ディレクトリ（docs のみ）も削除

**既存インストールの移行**（repo から消してもユーザー環境からは消えない）:

- README/リリースノートに案内を明記: `claude plugin uninstall brainstorm-harness@tech-teku-toolkit`（enabledPlugins に残骸が残る場合は settings.json から手動削除）
- **push の順序**: marketplace エントリ削除を push する**前に**、ひかる環境で uninstall を済ませる（エントリ消失後は update/uninstall が失敗し dangling になるため）

---

## 4. 発動の仕組み（P1）

原則: **検知＋注入（フック）／質問（モデル）／作業（スキル）**。SessionStart フックは制御端末を持たず、ユーザー入力を読めず、起動をゲートできないため。

### SessionStart フック（検知＋注入のみ・超軽量）

`hooks/harnesseed-nudge.sh`: ファイル存在チェックと軽量なローカル読取りのみで即 exit。ネットワーク/git コマンド呼び出し禁止。

**マーカー検知（サブディレクトリ対応）**: cwd から**上方向**へ、各ディレクトリで `.harnesseed/leaf.json`・`.harnesseed/declined` を確認する有限ループ。`.git` を含むディレクトリ（リポジトリ境界）で打ち切り、ファイルシステムルートでも停止（`CLAUDE_PROJECT_DIR` は起動ディレクトリと同値のため代替にならない）。これによりハーネス済み repo のサブディレクトリ起動で「未ハーネス」と誤判定しない。

**状態 × source のマトリクス**（SessionStart は startup/resume/clear/compact で発火する。stdin JSON の `source` で分岐）:

| 状態 \ source | startup / clear | resume / compact |
|---|---|---|
| マーカー無し | nudge を注入:「未ハーネス。`/harnesseed:harness` を提案し、**勝手に進めず必ず聞け**」 | 何も注入しない（未決状態での再ナグ防止） |
| `declined` あり | 注入しない | 注入しない |
| `leaf.json` あり | 軽量ポインタを注入 | 軽量ポインタを注入（compact 後のコンテキスト再構築に必須） |

- **非対話セッション対策**: フックが継承する `CLAUDE_CODE_ENTRYPOINT` が `sdk-*`（`claude -p` 等）のとき、未ハーネス nudge はスキップ。非公式 env var のためフォールバックとして注入テキストにも「非対話実行と思われる場合は質問せずタスクを進める」を併記。
- **軽量ポインタの中身**: seedling は `${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed/` の正準導出で解決（leaf にパスは持たせない）。加えて `planted.json` の seed_version と `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` の version を読み比べ、**新版が来ていれば「/harnesseed:pull を提案せよ」を注入**（「存在チェックのみ」原則の明示的な緩和。2ファイルの軽量読取り）。

### 質問するのはモデル

注入された指示に従い、会話で「🌱 このプロジェクトを Harnesseed でハーネスしますか？」と一度だけ聞く（文言は seedling の有無で分岐しない）。「一度だけ」は**マーカーのファイル状態**で担保。

### 作業するのは `/harnesseed:harness` スキル（承認後・冪等）

1. **seedling が無ければ生成**: `${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed/` に **git init**。
   **seedling 既存時**は手順2〜4・6〜8をスキップし、leaf 注入＋案内のみ（「既存の seedling にこのプロジェクトの葉を追加しました」）。このとき plugin の version ≠ planted.json の seed_version を検知したら **roots/ には一切触れず** `/harnesseed:pull` を案内する（roots/ と planted.json への書き込みは**初回発芽時と pull 完了時のみ**。再実行×プラグイン更新で merge base が silent に破壊されるのを防ぐ）
2. **生成を見える化**: 「ここに seedling を作りました。中身はこれ、理由はこれ」（初回＝最大の教育機会）
3. **芽吹き元を記録**: seedling の `planted.json` に `seed_version`（= plugin.json の version）+ blueprint content hashes + `planted_at`
4. **roots/ を作る**: `${CLAUDE_PLUGIN_ROOT}/blueprint/` **全体**を pristine コピー（evals/ 含む。以後 evals・チェッカーの実行元は roots/ 側＝git 監査下）
5. **leaf を注入**: プロジェクトルートに `.harnesseed/leaf.json`（マーカー + seed_version のみ。**seed_version は planted.json の値**＝実際に吸収済みの正典バージョン。stem へのパスは持たない）。祖先ディレクトリに既存 leaf があれば「ハーネス済み」としてネスト発芽を拒否。同時にプロジェクトの `.gitignore` へ `.harnesseed/` の追記を提案（leaf/declined は per-user/per-machine 状態。共有すると他メンバーの nudge を誤って消す）
6. **philosophy 会話**: 正典の具体的スタンスを叩き台に「Harnesseed はこう考える。賛成/反対/修正？」で個人化（白紙にしない）。結果は `stem/philosophy.md` に保存
7. **trend-stock 初期化**: 同梱 #0 の各項目を `trend-stock/index.json` に **status: "bundled"** で登録し（台帳の初期コミット）、その上で提示（scout の dedup 台帳に最初から接続する）
8. **blueprint 保護の提案**: Claude Code の permission deny ルールでプラグインキャッシュの `blueprint/**` への書き込み拒否をユーザーに提案・記録（tamper 面の縮小。任意）
9. 明示的「いいえ」→ `.harnesseed/declined` を書く（これも `.gitignore` 対象）

ユーザーが手で打つコマンドは実質ゼロ（nudge 自動、`/harnesseed:harness` は能動呼び出し用の予備）。

---

## 5. seedling の構造と統治の最小核（P1）

### seedling の中身（`${CLAUDE_CONFIG_DIR:-~/.claude}/harnesseed/` = git repo）

```
~/.claude/harnesseed/               # 🌿 seedling（ユーザー級・全プロジェクト横断・git repo）
├── planted.json                    # 芽吹き元: seed_version + blueprint hashes + planted_at
│                                   #   （blueprint/manifest.json とは別物。名前も分けてある）
├── roots/                          # 🪵 正典の pristine コピー（継承層）
│   ├── philosophy.md ほか正典一式  #   = 3-way merge の base
│   └── evals/                      #   チェッカー・挙動シナリオの実行元（git 監査下）
├── stem/                           # 🌿 個人化の上書き層（roots に対する「mine」）
│   └── philosophy.md               #   正典の見出し骨格を保ったまま個人化
├── trend-stock/                    # 生きたストック
│   ├── index.json                  #   正準台帳（追記型: id 単調増加・status 以外書換禁止）
│   ├── YYYY-MM-DD-scout-N.md       #   scout 実行ごとの詳細（新規追加のみ）
│   └── summary.md                  #   curated view（governed operation で再生成・bounded size）
├── checkups/                       # P3 レポート＋P4 drift review 結果（新規追加のみ）
├── growth-log.md                   # P4 の軌跡ログ（追記のみ。rotation は governed operation）
└── .pull-staging/                  # P5 pull の作業領域（git 管理外・.gitignore）
```

- プロジェクト側には `.harnesseed/leaf.json` 🍃 だけ。
- **roots（pristine）と stem（上書き）の分離**が肝: pull で roots=base / stem=mine / 新blueprint=theirs の 3-way merge に落とせる。
- **roots/ への正当な書き込みは2経路のみ**: (a) 発芽時の初期生成（§4手順4）、(b) pull 完了時の pristine 更新（§10）。いずれも planted.json の更新と**同一の1コミット**で行う。grow を含む他の全経路からは絶対不可。
- **trend-stock は3層あり役割が違う**: `blueprint/trend-stock/`＝配布正典（プラグイン更新で入れ替わる）／`roots/trend-stock/`＝version 固定の pristine スナップショット（merge base）／生きた `trend-stock/`＝台帳と採用ストック。
- **ライフサイクル方針**: index.json と growth-log.md は無期限追記（1件が小さい台帳）。肥大する散文側（scout 詳細・growth-log 本文）は governed operation（承認ゲート＋1コミット）で summary 生成・archive rotation できる。読み手（フックのポインタ先・scout Stage 2）は summary.md を第一参照にする。

### 統治の最小核（P1 に最初から入れる・後付け不能な土台）

1. **バージョン**: seed version = plugin.json（§3判断2）+ `blueprint/manifest.json`（per-file hash）
2. **芽吹き元の記録**: planted.json に必ず保存。**planted.json の更新コミットは「初回発芽」または「pull」の trailer を持つものに限る**（invariants チェッカーの検査項目）
3. **git-backed seedling**: 各 propose→approve→apply を1コミット（machine-readable trailer）に落とす土台。ロールバック/監査が無料
4. **継承層と上書き層の分離**（roots/ / stem/）
5. **invariants の正典**: `blueprint/invariants.md` に hard rules を明記、`blueprint/evals/` に決定的チェッカーと挙動シナリオ（実体の拡充は P4。実行元は常に roots/ コピー側）

---

## 6. フルv1.0 スコープ — 5フェーズ構成

依存関係順。各フェーズは「実装 → 受け入れ検証 → workflow クリティーク → 修正 → bootstrap-log 記録」で締めてから次へ。

| Phase | 名称 | 中身 | 依存 |
|---|---|---|---|
| **P1** | First Sprout | §3〜5 の全部（骨格・発芽・seedling・統治最小核）+ brainstorm 削除/移行 + trend-stock #0 同梱・台帳登録 + README（glossary 込み）/CI 書き換え | なし |
| **P2** | trend-scout 自動化 | `/harnesseed:scout`（§7） | P1 |
| **P3** | harness-checkup | `/harnesseed:checkup`（§8） | P1 |
| **P4** | grow + Misevolution 統治 | `/harnesseed:grow`（§9） | P2, P3 |
| **P5** | pull + learn + meta-harness | `/harnesseed:pull`・learn 拡充・meta-harness.md 蒸留（§10） | P1〜P4 |

**共通の技術制約**:

- Dynamic Workflow は **mid-run のユーザー入力不可** → propose→approve ゲートは必ず**ステージ境界**（workflow が候補を返して終了→会話で承認→スキルが適用）。
- プラグインが同梱できるのは skills/hooks/agents 等。workflow ファイルの自動配布は前提にしない → scout 等は**スキルが workflow スクリプトを組み立てて実行**する。
- **attempt-and-degrade**: workflow は maturity=growing のプリミティブなので、利用不可・エラー時は subagent fan-out へ、最終手段として会話内逐次実行へ劣化する（§7）。
- spawn される subagent は権限・tool allowlist を継承する。

---

## 7. `/harnesseed:scout` の設計（P2）

### パイプライン（3段: 調査 → 会話承認 → 適用）

```
Stage 1: 調査（Dynamic Workflow・自律実行。不可なら subagent fan-out → 会話内逐次に劣化）
  ├─ roots/scout-angles.md から4アングルを読む
  │    A: プラットフォーム機能 / B: agentic パターン / C: エコシステム / D: 自己改善研究
  ├─ アングルごとに WebSearch fan-out（4〜8クエリ）→ primary source を WebFetch
  ├─ load-bearing claim を敵対的検証（confirmed / partly / uncorroborated の verdict 付き）
  ├─ trend-stock/index.json と照合（dedup 規則は下記）
  └─ 構造化された候補リストを返して終了 ★workflow はここで終わる

Stage 2: 承認（会話）
  └─ summary.md ＋候補を優先度 Tier 付き（未導入度×効果×検証の堅さ）で提示
     →「採用 / 却下 / 保留」を聞く

Stage 3: 適用（スキル）
  ├─ 採用 → trend-stock/YYYY-MM-DD-scout-N.md 追記 + index.json 更新
  │         = seedling repo に1コミット（trailer: scout-run, source, verdict）
  ├─ 却下 → index.json に status: "rejected" ＋必須フィールド
  │         （却下理由・却下日・却下時 maturity・evidence 要約）
  └─ 保留 → index.json に status: "deferred"（次回 scout で dedup 除外せず再提示する）
```

### dedup と再浮上の規則

- **新規候補として再提案しないもの**: index.json の全既知エントリ（bundled / adopted / rejected。deferred は除く）
- **却下の再浮上**: 却下時に記録した maturity/evidence と今回の findings を比較し、**有意な変化**（maturity が1段以上進んだ・primary source の新規出現。判定基準は `scout-angles.md` に正典として明文化）がある場合のみ「以前この理由で却下済み。状況がこう変わった」と明示して再提示できる。再判断は**旧エントリを supersede 参照する新エントリの追記**で表現（追記型 invariant と両立）
- **bundled（#0 由来）**: 新規候補として再提案しない。陳腐化・状態変化を検出した場合は「既知項目の更新提案」として別枠で提示

### 品質ガードレール（trend-scout #0 の方法論ログ＝一次資料）

- **出典規律**: 数値・固有主張は primary/named source のみ（official docs, arXiv ID, GitHub repo）。SEO/aggregator は maturity signal 扱い
- **recency 判定**: docs の min-version アノテーション、arXiv ID の日付整合
- **hedge 規律**: 行単位で再検証できない数値は `~` 付きで保持

---

## 8. `/harnesseed:checkup` の設計（P3）

### 何を診るか（読み取り専用・ネットワーク不要）

- `${CLAUDE_CONFIG_DIR:-~/.claude}/settings.json`（permissions, enabledPlugins, hooks, outputStyle…）
- インストール済み plugins / marketplaces、MCP 設定（`.mcp.json` 各層）
- CLAUDE.md（グローバル/プロジェクト）・memory・skills の構成

### 判定フレーム: `roots/checkup-checklist.md`（正典は blueprint、実行元は roots コピー）

awesome-harness-engineering の **~12カテゴリ taxonomy** をチェックリスト化:

> agent loop / planning / context / tool / skills&MCP / permissions / memory / orchestration / verification / observability / debugging / human-in-the-loop

カテゴリごとに「何を確認するか」「良い状態とは何か」を記述。**observability / permissions / human-in-the-loop が盲点になりやすい**（#0 の知見）ので具体的なプローブを書く。プラットフォーム機能カテゴリには **Dynamic Workflow 可用性のプローブ**を含める（§7 の劣化パス判断の材料）。

### 出力

1. **カテゴリ別レポート**: `present / partial / absent` + 根拠（どのファイルのどの設定を見たか）
2. **gap ランキング**: 重要度順の改善提案（見つかった事実に紐づける）
3. 保存先: `checkups/YYYY-MM-DD-checkup.md` = seedling repo に1コミット

### 統治との接続

checkup は**診断と提案だけ**で、設定を一切変更しない。**scout と checkup が「提案の供給源」、grow が「変更の唯一の通り道」**という一方通行の管路。ただし grow の直接適用先は seedling repo 内に限る（§9）— seedling 外のハーネス設定への提案は「diff 出力→ユーザー手適用」になる。

### 実装形態

読み取り＋分析だけなので workflow は必須ではない。カテゴリ並列の subagent fan-out はオプション。

---

## 9. `/harnesseed:grow` の設計（P4）

### propose → approve → apply

```
Stage 0: blueprint 整合検証（毎 run 冒頭）
  ├─ ${CLAUDE_PLUGIN_ROOT}/blueprint/ 全ファイルの実 hash を planted.json 記録値と照合
  ├─ plugin version が新しい → grow を中断し /harnesseed:pull へ誘導（正規更新の誤検知防止）
  └─ version 同一なのに hash 不一致 → tamper 疑いとして hard-stop・再インストール要求

Stage 1: propose（供給源から提案を組み立てる）
  ├─ 供給源: scout の採用ストック / checkup の gap / drift review / ユーザー自身の気づき
  ├─ 提案は構造化 delta（ACE流・丸ごと rewrite 禁止）:
  │    { 対象ファイル, 変更内容, evidence, rationale, regression-risk }
  ├─ 5 anti-pattern スクリーニング:
  │    instruction bloat / 矛盾 / over-specificity / prompt theater / cargo-cult
  └─ 挙動シナリオ（roots/evals/ の固定模擬タスク2〜3本）を grow 前 stem で実行し
     ベースラインを取る（advisory 層。下記「2層ゲート」）

Stage 2: approve（会話）
  └─ 1提案ずつ evidence・rationale・regression-risk ＋ advisory 判定を見せて承認を取る

Stage 3: apply（seedling repo 内のみ）
  ├─ 1提案 = seedling repo に1コミット（trailer: Technique-Id / Source / Seed-Version / Evidence）
  ├─ 適用後に決定的 invariants ゲート（下記①）を実行 → 失敗なら自動 git revert
  ├─ 挙動シナリオを再実行し LLM-judge で前後比較 → 結果は growth-log に記録し
  │  次回 Stage 2 に advisory として持ち越す（自動 revert には接続しない）
  └─ growth-log.md に追記（採用/却下/自動 revert を全部記録＝trajectory ログ）

Stage 4: drift review（条件発火の必須ステージ）
  ├─ 発火条件: 前回 review 以降の累積適用 10 件以上、または 90 日経過
  ├─ (a) 直近サイクル分の growth-log + git trailer の集約
  ├─ (b) roots ↔ stem の全体 diff 要約
  ├─ (c) stem 全体（累積結果）への 5 anti-pattern 再スクリーニング（基準は roots/drift-review.md）
  └─ 結果は checkups/ に保存。検出 drift は「提案の供給源」として次の grow ゲートに流す
```

### 2層ゲート（「held-out」という語は使わない — 正直な設計）

- **① 決定的 invariants ゲート**（自動 git revert に接続する唯一の層。実行元は roots/evals/ のチェッカー、実行直前に自身の hash を planted.json と照合してから走る）:
  1. seedling の git 履歴が線形
  2. roots/ 実ファイル hash = planted.json 記録値（pristine 検証）
  3. stem/philosophy.md の見出し集合が roots/philosophy.md の見出し集合を**包含**する（相対チェック。骨格は pull で roots ごと更新され追従する）
  4. index.json が parse 可能・id 単調増加・既存エントリは status フィールド以外書換なし
  5. growth-log.md が追記型（直前コミット版が新版の prefix）
  6. **protected ファイル（planted.json・roots/）への diff が grow の apply コミットに含まれたら機械的に fail**
  7. planted.json の変更コミットは「初回発芽」or「pull」trailer を持つもののみ（履歴検査）
- **② 挙動レベルの受け入れシナリオ**（roots/evals/ の固定模擬タスク＋LLM-judge）: 出力が非決定的で判定に judge が要るため**自動ゲートには接続しない**。Stage 2 の承認画面に advisory（却下推奨等）として提示し、ゲートは人間承認のみとする。
- 旧文書の「受け入れ基準を緩める変更の拒否」は意味的判定で決定的スクリプトでは実装不能のため、独立項目としては置かず、①-6/7 の protected diff 検出に統合した。invariants.md（人間可読の hard rules）は Stage 2 で承認者に常時提示する。

### scope-restriction allowlist（編集サーフェスの明示・default-deny 閉包）

| 区分 | 対象 | 扱い |
|---|---|---|
| 自由に編集可 | `stem/` | grow の主戦場（個人化上書き層） |
| 追記のみ可 | `trend-stock/index.json`（id 単調増加）・`trend-stock/*-scout-*.md`（新規追加）・`checkups/`（新規追加）・`growth-log.md`（追記） | invariants ①-4/5 が機械検査 |
| governed operation | `trend-stock/summary.md` 再生成・growth-log の rotation/archive | 承認ゲート＋1コミット |
| 特定ゲートのみ | `planted.json`・`roots/` | 初回発芽 / pull だけが書ける（①-6/7） |
| **提案出力のみ（v1 は直接編集しない）** | ユーザー級・プロジェクト級のハーネス設定: `~/.claude/settings.json`・グローバル/プロジェクト CLAUDE.md・`.claude/settings*.json`・`.mcp.json`・hooks 等 | grow は **diff を提案として出力し、適用はユーザーが手で行う**。permissions/hooks の緩和を含む diff は提示時に機械検出して明示ハイライト |
| 絶対不可 | `blueprint/`（プラグインキャッシュ）・**あらゆるプロジェクトのアプリソースコード** | — |

- **default-deny 閉包**: この列挙は網羅的。プロジェクトツリー内で上記に列挙されていないパスはすべて「アプリソースコード」として絶対不可に落ちる。
- **per-run 上限**: 1回の grow で適用できる提案は最大5件。
- **v1 で意図的にやらないこと（正直なスコープ宣言）**: seedling 外サーフェスの自動適用。自動 git revert の保証が届かない編集面を v1 の自動化から排除する（自動適用＋バックアップ/復元機構は v2 候補。§14）。これにより「ホスト設定を触るのは人間だけ」が v1 の不変条件になり、CI もチェッカーのユニットテストに集中できる。

---

## 10. `/harnesseed:pull` + learn + meta-harness（P5）

### `/harnesseed:pull`（上流改善の取り込み）

```
Step 0: seed 更新
  ├─ claude plugin marketplace update → claude plugin update harnesseed を実行
  ├─ 新 blueprint は installed_plugins.json の installPath（新バージョンのキャッシュ）から解決
  │   （${CLAUDE_PLUGIN_ROOT} は旧版を指すため theirs の取得には使わない — §3判断1の例外）
  └─ スキル/フック自体の更新反映のため、pull 完了後に再起動を案内

Step 1: 上流照合（tamper 対策）
  ├─ 新 blueprint の per-file hash をキャッシュ内 manifest.json から鵜呑みにせず、
  │   上流信頼点（git remote の該当バージョンのタグ/コミットの manifest.json）と照合
  └─ 照合不能（オフライン等）なら pull を拒否

Step 2: 前提チェック
  └─ seedling の working tree が clean であることを検証。汚れていれば中止して提示

Step 3: staging で 3-way merge
  ├─ .pull-staging/（git 管理外）にコピーを作り、ファイルごとに git merge-file
  │   （base = roots/ / mine = stem/ / theirs = 新 blueprint）
  ├─ コンフリクトは会話で提示 → ユーザーが解決
  └─ blueprint/trend-stock/ の新規項目は merge せず「bundled 登録候補」として会話提示

Step 4: all-or-nothing 反映
  ├─ 全ファイルの解決が完了して初めて、マージ結果 + 新 roots/ + 新 planted.json を
  │   同一の1コミットで seedling repo に反映（trailer: pull, seed_version）
  └─ 部分適用（一部ファイルのみ解決した状態での roots/planted 更新）は禁止
      （merge base 不整合を再導入するため）

中断復旧: staging 方式により seedling の tracked ファイルと git 履歴は構造的に無傷。
次回 pull 起動時に残存 staging を検出し「破棄して最初から / 解決済み分を引き継いで再開」を
ユーザーに選ばせる。
```

- 更新の**検知**はフックが担う（§4: leaf 有り時に version 比較して pull を提案）。

### learn/ 拡充

3ドキュメント: ① how-it-works（literal な仕組み解説。「新版に気づく経路」も明記）② glossary 詳細版（4語＋説明語＋メタファー導出の解説＋3つの harnesseed ディレクトリ対応表。P1 README 版の拡張）③ bootstrap-case-study（docs/bootstrap-log を教材として読むガイド）。

### meta-harness.md の蒸留

P1〜P4 の bootstrap-log が揃った時点で「Harnesseed 自身がどう作られたか」を `blueprint/meta-harness.md` に蒸留する。bootstrap-log への実引用（ファイルパス付き参照）を必ず含める＝存在しないビルド過程の作文でないことの担保。

---

## 11. 受け入れ基準（フェーズ別・着手前に固定）

### P1
1. **e2e 完走**: dev 用ローカル marketplace（§13: 別名 `tech-teku-toolkit-dev`）で `marketplace add` → `install` → 未ハーネスプロジェクトで起動→nudge → 「はい」→ seedling 生成（git-backed + roots + stem + leaf）→ philosophy 会話 → trend-stock 提示＋ **index.json への bundled 登録確認**
2. **決定的チェック**: `claude plugin validate` / 各 JSON parse / blueprint manifest の hash 一致
3. **dogfooding**: ひかるが実プロジェクト2件でハーネス化（**1件目=発芽込み、2件目=leaf 追加のみ**になること＝冪等パスの確認）。前提チェックリスト: ひかる環境の brainstorm-harness uninstall ＋ enabledPlugins/installed_plugins.json の残骸確認
4. **declined フロー**: 「いいえ」→ `.harnesseed/declined` → 以後 nudge が出ない
5. **CI green**: §12 の P1 分すべて
6. **brainstorm 残骸ゼロ（機能面サーフェス限定の決定的検証）**: `plugins/brainstorm-harness/`・`install/` が不存在、README.md / marketplace.json / .github/workflows/ に brainstorm 参照なし（docs/ 配下の spec・bootstrap-log は履歴記録として除外）。marketplace.json のエントリが harnesseed 単一
7. **docs 移設完了**: 旧 `harnesseed/` の spec・bootstrap-log が `plugins/harnesseed/docs/` に存在し、旧ディレクトリ削除済み
8. **philosophy.md が正典として著述済み**（スタブでない: 見出し1つ以上＋manifest の hash 対象）
9. **再実行安全**: seedling 既存＋plugin version bump 後の再ハーネスで roots/ と planted.json が変化しない（hash 比較）
10. **`.harnesseed/` が .gitignore 提案でカバーされる**（フックテストにも反映）

### P2
1. scout 実行→検証済み候補提示→承認→seedling repo に1コミット追記
2. **却下時から記録上の maturity/evidence に有意変化がない却下候補は再提案されない**（同一状態の再提案なし）
3. **#0 掲載項目が新規候補として再提案されない**（既知項目への「更新提案」としての提示は可）
4. deferred（保留）項目が次回 scout で再提示される
5. workflow 不可環境で subagent fan-out への劣化パスが動く（disableWorkflows で1回検証）

### P3
1. 実環境で checkup → 12カテゴリの gap レポートが checkups/ に保存される

### P4
1. 提案→承認→適用→**git revert でロールバック**が通る
2. **invariants 違反の提案が自動で弾かれる**テストケース（protected diff / 追記型違反 / 骨格包含違反）
3. **blueprint/evals/ またはチェッカーを改変した状態（version 同一・hash 不一致）で grow を実行すると hard-stop する**
4. drift review が閾値で自動発火し、複数コミットに分散させた累積型 anti-pattern（instruction bloat 等）を検出するケースが1回通る

### P5
1. **実チャネル e2e**: marketplace update → plugin update →（再起動）→ pull の連鎖を dev marketplace で実際に通す（キャッシュ直編集・作業ツリー直参照による迂回検証は不可）
2. 個人化を保持したまま上流変更が入る。コンフリクトケースも1つ通す
3. **負のケース**: blueprint のみ変更・plugin.json 未 bump で update が no-op になることを検出し、CI/リリース手順が弾く
4. **中断復旧**: コンフリクト未解決のまま中断→ seedling の tracked ファイルと git 履歴が pull 前と同一（残るのは staging のみ）→ pull 再実行で完走
5. **キャッシュ blueprint を改ざんした状態の pull が上流照合（Step 1）で拒否される**
6. learn/ 3本が存在し、glossary が4語＋literal 対応表を含む。meta-harness.md が bootstrap-log への実引用を1件以上含む

## 12. CI（test.yml 書き換え）

- **P1**: marketplace.json / plugin.json / hooks.json の JSON parse 検証。blueprint/manifest.json の hash と実ファイルの一致検証。フックのユニットテスト: 3状態 × source（startup/resume/clear/compact）× サブディレクトリ起動 × `CLAUDE_CODE_ENTRYPOINT=sdk-cli`
- **P1**: **バージョン整合チェック**: blueprint/ 配下に差分があるコミット/PR では plugin.json の version が bump されていること
- **P4**: invariants チェッカーのユニットテスト（tamper 検出の2分岐 / protected diff / id 単調増加 / 追記型 / 骨格包含）
- **P5**: 3-way merge のテストケース＋staging 中断→seedling 無傷の検証（fixture ベース・一時ディレクトリ。実ホスト設定不要）

grow は seedling repo 外を書かない（§9）ため、ホスト設定の統合テストは不要のまま。**「harnesseed はホスト設定を変更しない（提案 diff の手適用を除く）」が v1 の検証可能な不変条件**。

## 13. 開発プロセスと git 運用

- 開発は tech-teku-toolkit クローンの **`harnesseed` ブランチ**で直接行う（案B）。コミットは既存スタイル（conventional prefix・英語）。
- **push はひかるの確認を得てから**。main へのマージも同様。**brainstorm の marketplace エントリ削除を含む push の前に、ひかる環境での uninstall を完了させる**（§3 移行手順）。
- **dev 用 marketplace は別名で登録**: `tech-teku-toolkit`（github source）が登録済みのため名前衝突する。ローカル検証は `tech-teku-toolkit-dev` 等の別名で `marketplace add` し、本番切替時に dev 側 `harnesseed@tech-teku-toolkit-dev` を uninstall してスキル二重登録を防ぐ。leaf/planted は marketplace 名非依存（seed_version + hashes のみ記録）なので切替の影響を受けない。
- フェーズごとに: 実装 → 受け入れ検証 → **workflow クリティーク**（5レンズ敵対的レビュー）→ 修正 → **bootstrap-log 記録** → コミット。
- philosophy.md の正典オーサリングは **P1 実装中のひかるとの会話**で行う（インタラクティブな工程として計画に明記）。
- 旧 `harnesseed/docs/` の残骸は P1 で `plugins/harnesseed/docs/` へ移設し、空になったディレクトリは削除。
- `toolkit-production/` は今回触らない。

## 14. リスクと対応

| リスク | 対応 |
|---|---|
| SessionStart フックの仕様変化 | フックは検知＋注入のみの最小結合。source マトリクス（§4）は CI のユニットテスト＋手動 dogfooding で確認 |
| workflow の mid-run 入力不可 | 全フェーズで承認ゲートをステージ境界に置く設計を固定済み |
| **Dynamic Workflow 不可用/仕様変化（maturity=growing）** | scout は attempt-and-degrade で subagent fan-out → 会話内逐次に劣化（§7）。checkup に可用性プローブ（§8） |
| grow の暴走（Misevolution） | §9 の多層統治（allowlist＋default-deny / per-run 上限 / 決定的 invariants ゲート＋自動 revert / advisory 挙動判定 / drift review / trajectory ログ） |
| **ローカル tamper（プラグインキャッシュは書き込み可能）** | tamper-proof は主張しない（§3判断4）。blueprint 整合検証（§9 Stage 0）＋pull の上流照合（§10 Step 1）＋permission deny 提案（§4手順8）で tamper-evident を担保 |
| pull の途中失敗で stem 汚染 | staging 方式＋all-or-nothing 1コミット＋検出ベースの中断復旧（§10） |
| メタファーの破綻 | literal 主役・「発芽は初回のみ」の語法統一（§2）を全ドキュメントで貫く |
| trend-stock #0 の陳腐化（2026-06-18時点） | P2 完成後に scout を1回実走。bundled 項目には「更新提案」枠で新情報が届く（§7） |
| **seedling 外サーフェスの自動適用は v1 でやらない** | grow は diff 提案の出力まで（§9）。自動適用＋バックアップ/復元機構は v2 候補として意図的に先送り |
