# Harnesseed 設計クリティカルレビュー #1 (2026-06-18)

> ここまで会話で決めた設計を、5レンズ（Claude Code実現可能性 / bootstrap・統治 / スコープ・YAGNI / 一貫性・教えやすさ / トレンドギャップ）で敵対的にレビューした結果。trend-scout #0 の知見も突き合わせている。各段階でこのクリティークを習慣化する、その1回目。

## 0. 一行サマリー

設計の**思想と方向性は強い**が、**着手前に潰すべき重大な穴が4つ**ある — ①発動の仕組みが「フックがユーザーに質問する」前提だが、それはClaude Codeで**物理的に不可能**。②種(roots)の**バージョン管理が無い**。③育った苗が上流の改善を**取り込む経路が無い**（永久に乖離する）。④自己改善なのに**Misevolution対策（暴走防止）がゼロ**。加えてMVPが大きすぎ＆矛盾、メタファーが生物学的に破綻、名前が読みにくい。

---

## 1. 設計の強み（残すべき芯）

- **propose → approve → apply ループ自体が教材**。学習者は「思想を言語化し、トレンドを精査し、学びを昇格させる」過程を見て、ハーネスエンジニアリングを"説明"ではなく"実演"で学べる。最大の教育資産。
- **user stem / project leaf の2層分離は正しい**。「グローバルなハーネス vs プロジェクトのハーネス」という学習者が内面化すべき本物の区別に対応している。
- **本家main＝ひかる専用＋友達PR**は、正典(roots/)に対する明確で強制可能な信頼境界。
- **思想を会話でゼロから言語化**は、脆い設定パース機構をMVPから排除できる妥当な選択。
- **究極のbootstrap（meta-harness）**は記憶に残る・動機づけになるフレーミング。

---

## 2. 重大な問題（MVP着手前に決め直す）

### C-1 🔴 [実現可能性] 「フックが質問して分岐」は Claude Code に存在しない
公式ドキュメント明記：SessionStartフックは**制御端末を持たないセッションで実行**され、`/dev/tty`を開けず**ユーザー入力を読む手段が無い**。`decision: "block"` 等の判断フィールドも**非対応**で、起動をゲートできない。→「フックが聞く→はい→フックが進める」フローは**丸ごと不可能**。

**直し方（プラットフォームが実際にサポートする2つに分解）：**
1. **フックの仕事は検知＋注入だけ**：マーカーファイルの有無を見て、未ハーネスなら `additionalContext` に「このプロジェクトは未ハーネス。`/tane:harness` を提案し、勝手に進めず必ずユーザーに聞け」と注入。
2. **質問するのはモデル**（注入された指示に従い会話で聞く）、**作業するのはスキル** `/tane:harness`（ユーザーが承認/起動）。

→ 摩擦ゼロ（nudgeは自動で出る）を保ったまま、ドキュメント準拠になる。

### C-2 🔴 [実現可能性] 「一度だけ聞いてもう二度と聞かない」もフック単体では不可
SessionStartは毎セッション発火し、「前に聞いて"いいえ"だった」を記憶できない（答えがフックに届かないため）。素のままだと**毎回nudgeが再注入＝結局しつこい**。

**直し方：「聞いたか」をファイル状態の契約にする。** フックは3状態を安いファイル存在チェックで読むだけ：
- マーカー無し → オファーを注入
- `.tane/declined` → 何も注入しない（オプトアウト）
- `.tane/leaf.json` → ハーネス済み（通常コンテキストのみ）

`/tane:harness` が「はい」で `leaf.json` を書き、明示的「いいえ」で `declined` を書く。

### C-3 🔴 [統治] 種(roots)のバージョン管理が「どこにも無い」
roots/（philosophy・baseline・meta-harness）が種なのに、**バージョン番号もコンテンツハッシュも、苗が「どのバージョンの種から芽吹いたか」の記録も無い**。これが無いと後続の懸念（上流の取り込み・衝突解決・ロールバック）が全て**答え不能**になる。一番load-bearingな所が手薄。

**直し方（MVPの前提条件、後回し不可）：** roots/ に明示的なseedバージョン（`roots/VERSION` か per-fileハッシュのマニフェスト）。**種まき時に、苗のマニフェストへ「芽吹き元のseedバージョン＋ハッシュ＋planted_at」を必ず記録**。これを最初に入れないと、アップグレード不能なインストール母体を抱え込む。

### C-4 🔴 [統治/トレンドギャップ] 自己改善なのに Misevolution 対策がゼロ
「自己改善ハーネス」を謳うのに、**ハーネスが編集できない held-out eval も、合格基準を弱められない hard rule も、cycle跨ぎの trajectory 監視も無い**。唯一のゲートが「ユーザー承認」＝疲れたひかるが"それっぽい"diffを承認する、まさに論文(arXiv:2509.26354)が警告する eval-gaming / drift の温床。**diffを目視するのは回帰ゲートではない。**

**直し方（grow sub-project着手前に）：** roots/ に①ハーネスが読み書きできない held-out 受け入れ集合、②「自己編集は受け入れ基準を緩めてはならない」というバージョン管理されたhard invariant、③変更はevidence＋rationale＋regression-riskを伴う構造化delta（D6）、④バージョン跨ぎでdiffできる軌跡ログ。**特に meta-harness.md / harness-baseline.md に適用**。通常の苗の成長はもっと軽くてよい。

---

## 3. 高優先の論点（スコープ・名前・統治）

### H-1 [スコープ] MVPが大きすぎ＆内部矛盾
発動フローが「はい→checkup＋trend-scout＋philosophy」と書いてあるが、checkup/trend-scoutは**sub-project 2,3に明示的に先送り**されている＝**作れない手順を仕様に書いている矛盾**。さらに(1)4役ハイブリッドrepo (2)発動フック＋多段アクティベーション (3)philosophy/meta-harness 2本の長い会話オーサリング、の3つが各々独立に重い。

**直し方：MVPを1枚の縦切りに。** repo骨格 ＋ SessionStart nudge ＋ `/tane:harness`（はい→stem/leaf作成→**philosophy.md の会話だけ**起動）。trend-scout・checkup・meta-harness.md はMVPから**完全に外す**。フロー文言も実際に作る物と一致させる。

### H-2 [スコープ] meta-harness.md はMVPに入れない
「TANE自身の作り方」は最も抽象的で最も書き換わる文書。trend-scout/grow/checkupが**まだ存在しない段階で書くと、存在しないビルド過程の作文＝即陳腐化**。会話オーサリング機構の実証には philosophy.md 1本で足りる。→ meta-harness.md は後続 or 既存の bootstrap-log から漸進的に育てる。

### H-3 [スコープ] MVPが「差別化されない方の半分」を出荷してしまう
philosophy.md の会話は心地よいが、superpowers等の既存メソドロジープラグインより明確に良いとは言えない。**TANE固有の価値（精査済みトレンドの生きたストック）がちょうど欠けている。** 出荷可能でも「誰かがHarnesseedを欲しがるか」を検証できない恐れ。

**直し方（強く推奨）：** trend-scoutの**自動化はコードとして先送りのまま**、**すでに生成済みの trend-scout #0 出力を静的・手キュレーションのコンテンツとして roots/ か stem に種として入れる**。友達は初日に「精査済みトレンドの生きたストック」を体験でき、当面はひかるが手で更新、自動化はsub-project 2で。→ **我々はもう #0 を持っている**ので即実現できる。

### H-4 [一貫性] 植物メタファーが生物学的に逆転・破綻
自然界：種→苗、根は生きた植物を支える、茎は苗から伸び、葉は植物に付く。設計：「種＝本家＝ひかるのみ編集の権威」だが**苗は種の子であって、種に統治される複製ではない**。「roots/」が**種の中**にあるのも生物学的に逆（根は育った植物のもの）。stem=ユーザー級 / leaf=プロジェクト級だが、茎も葉も同じ1本の植物の部位なので**なぜ片方がグローバルで片方がプロジェクトごとなのか直感が湧かない**。→ 学習者はメタファーから挙動を導けず、恣意的対応を**暗記**させられる。教材として逆効果。

**直し方：** (a) 生物を直して導出可能にする（種が発芽→苗が**根(吸収した正典philosophy)・茎(ユーザー級の幹)・葉(プロジェクトごとの outgrowth)**を発達させる。roots/は「苗が育てるもの」へ概念移動）、**または** (b) メタファーを軽い覚え方に格下げし、ドキュメントは**literalな仕組み**（上流repo / ユーザーグローバル層 / プロジェクト層）を主役にする。破綻したメタファーを理解の幹にしない。

### H-5 [一貫性] 名前が読みにくい／3つの名前が未整理
"Harnesseed" は s が重なり Harnes-seed / Harness-eed と読み割れ、声に出すと "harnessed" と区別不能。"Harnesseedling" は3形態素の塊で発音困難。さらに **TANE / Harnesseed / Harnesseedling のどれがプロジェクト/repo/ユーザーインスタンスか**を明示する必要。

**直し方：** 声に出して読む・聞いて綴れるかでテスト。ハイフン/大文字（Harness-Seed 等）か、ユーザーインスタンスは別語幹を検討。3名称の役割をドキュメントで明記。

### H-6 [実現可能性] `/tane:` を使うならプラグイン名は `tane`
スキル呼び出しprefixは `plugin.json` の `name` 由来。`/tane:harness` を使うなら plugin name は `harnesseed` ではなく `tane` にする必要。予約名（`anthropic-*`等）と衝突しないか確認し、公開前に `claude plugin validate` を実行。（repo名はHarnesseed、marketplace名は非予約語でOK）

### H-7 [実現可能性] プラグインソースはrepoルート不可 → ネスト配置
ドキュメントはソースを `./` 始まりのサブディレクトリへ解決する想定。`source: "."`（plugin==marketplace root）は非ドキュメントパターン。→ `/.claude-plugin/marketplace.json`（マーケット）、`/plugins/harnesseed/{plugin.json,skills,hooks,commands}`（プラグイン）、`/roots/`、`/learn/` のネスト構成にする。

### H-8 [統治] 苗はgitバックドにしてロールバック/監査を無料で得る
"~/.tane か個人repo" が未確定。**stemをgit管理にし、各 propose→approve→apply を1コミット**（machine-readable trailer：technique id, source, seed_version）に。DGMのarchive/stepping-stone思想（D4）を低コストで実現。MVPで非バージョンのフラットファイルstemを出すと後で移行地獄。

---

## 4. 中〜低の論点（実装時に効かせる）

- **[runtime] Dynamic Workflowsを採るか明示的に決める**（A1）。trend-scout/checkup/growをsaved workflowにするか手組みか。**重要制約：workflowはmid-run入力不可**→「propose→承認」ゲートは1つのworkflow内に置けず**ステージ境界にする**必要（今回我々が実体験した通り）。`/deep-research`が参照アーキ。
- **[stem location] クロスプラットフォーム**：`~/.tane`ハードコードはWindowsで破綻。`${CLAUDE_CONFIG_DIR:-~/.claude}/tane`等を1つ正準として決め、path解決を明記。並行セッションのstock/log競合は追記型 or ロックで。
- **[hook性能] フックは超軽量に**（毎セッション発火）。`test -e` 1〜2回で即exit、ネットワーク/git呼び出し禁止。重い処理は全てon-demandスキルへ。
- **[構造] トレンドストックを awesome-harness-engineering ~12カテゴリで構造化**（B8, ★★★未導入）。「TANEに何が欠けてるか」をvibesでなくチェックリストに。observability/permissions/HITLが現設計に不在。
- **[memory] stem成果物のライフサイクル**：adopted-logは追記型構造delta（ACE流, rewrite禁止）、trend stockは定期summarize/discard、SessionStartは**軽いポインタだけ注入**（全stem注入禁止＝context rot防止）。
- **[grow統治] 編集可能サーフェスのallowlist**（config/skills/memoryは可・アプリソース不可, D6）＋per-run上限＋矛盾検証ゲート＋5 anti-pattern スクリーニング。
- **[互換] portable SKILL.md標準で書く**（C8）。`harness-baseline.md`は削除済み `/output-style` でなく `/config`＋`settings.json outputStyle`／新Proactive built-inを参照（A7）。
- **[教育] 初回stem作成を"見える化"**：「~/.tane を作りました、中身はこれ、理由はこれ」と表示。摩擦ゼロでも説明ゼロにしない（初回が最大の教育機会）。
- **[教育] philosophy会話を白紙にしない**：roots/philosophy.md の具体的スタンスを叩き台に「TANEはXをこう考える。賛成/反対/修正？」で引き出す。
- **[教育] 用語が多すぎる**：初回ユーザーが理解必須な語を3〜4個に絞り、glossaryを1枚用意。削除した `/tane:plant` の残骸を全docから掃除。

---

## 5. MVP着手前に決め直すべきこと（決定リスト）

1. **発動の仕組み**：フック＝検知＋注入のみ／質問はモデル／作業は `/tane:harness` スキル／「一度だけ」はマーカー3状態。【ほぼ強制：採用推奨】
2. **MVPスコープ**：repo骨格＋発動＋**philosophy.md会話のみ**。meta-harness.mdとtrend-scout/checkup自動化は外す。**ただしtrend-scout #0をstaticな種ストックとして同梱**して差別化価値を初日に出す。
3. **名前**：Harnesseed/Harnesseedlingを読みやすく直すか、3名称の役割を整理するか。
4. **メタファー**：生物学を直して導出可能にするか、軽い覚え方に格下げしてliteralな仕組みを主役にするか。
5. **統治の最小核をMVPに入れる**：①seedバージョン＋苗マニフェスト記録、②gitバックドstem、③Misevolution不変条件のプレースホルダ（roots/に「受け入れ基準は緩められない」hard rule）。
6. **runtime方針**：Dynamic Workflows採用 or 手組みを明示（mid-run入力不可の制約込み）。

---
*生成元：5レンズ敵対的レビュー（Claude Code feasibility / bootstrap-governance / scope-yagni / coherence-teaching / trend-gap）。trend-scout #0 と突き合わせ済み。*
