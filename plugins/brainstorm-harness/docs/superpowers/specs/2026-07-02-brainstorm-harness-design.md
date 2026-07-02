# Brainstorm Harness 🌱 — 設計仕様 (Design Spec)

- **日付**: 2026-07-02
- **ステータス**: 設計合意済み（実装プラン作成へ）
- **配布**: 共通アンブレラ・マーケット `tech-teku-toolkit` の1プラグイン（`plugins/brainstorm-harness/`）。将来 `harnesseed` も同マーケットへ移設予定。
- **公開**: GitHub Public
- **開発の流儀**: ライト版ハーネスエンジニアリング（spec → plan → implement → verify。要検証ポイントはインライン確認。bootstrap-log は簡易メモ）
- **関連ログ**: `docs/bootstrap-log/2026-07-02-verify-0.md`（技術前提のインライン検証メモ）
- **注**: 本書は設計時点のスナップショット。実装（`install/`・README）と差異がある箇所は実装が正。

---

## 1. これは何か（ビジョン）

**Brainstorm Harness** は「ブレインストーミングに没入するための、明るくて気持ちのいい Claude Code 環境」を1コマンドで開くためのハーネス。VS Code の統合ターミナルから独立した **Windows Terminal の明るい窓** が開き、その中で **ライトテーマ・bypass 権限・ブレスト特化スキルだけ・応援メッセージ・英日切替** が効いた Claude Code が立ち上がる。

設定一式は **自分のマーケットプレイス（GitHub）で配布**でき、push すればクラウド保存、友達は `marketplace add` → `install` → `setup.sh` 一発で同じ環境を再現できる。

対象環境の前提: **WSL2 (Ubuntu) + Windows Terminal**（ユーザーの実環境で確認済み。`wt.exe` あり、Linux 側ネイティブ端末は無し）。

---

## 2. スコープ（YAGNI）

### やること（MVP）
- 3つの入口（WTプロファイル / `clbs` コマンド / `/clbs` スラッシュ）から、明るい独立ターミナルでブレストモードの Claude Code を起動。
- ブレストモードの中身: ライトテーマ・bypass・厳選スキル・起動バナー・英日切替。
- アンブレラ・マーケット `tech-teku-toolkit` の器 + `brainstorm-harness` プラグイン + `setup.sh`。

### やらないこと（Out of scope）
- harnesseed 本体の移設（今回は「入る場所」だけ用意し、slot と README に導線を書く。既存 `docs/` は触らない）。
- GitHub リポジトリの自動作成・push（実装フェーズでユーザー確認のうえ実施）。
- macOS / ネイティブLinux 向けの端末色対応（`setup.sh` は WT 非検出時に安全にスキップ。Claude設定・スキル・バナーは効く）。
- 自己改善ループ（trend-scout 自動化 / grow 機構）などの harnesseed 的メタ機能。

---

## 3. アーキテクチャ（コンポーネント）

責務ごとに独立した5ユニット。各ユニットは「何をする / どう使う / 何に依存する」が単独で言える粒度。

| # | ユニット | 何をする | 依存 | 配布層 |
|---|---|---|---|---|
| U1 | **WT プロファイル + カラースキーム**（`install/sunrise-cream.json`） | 「明るい独立窓」を提供。`Sunrise Cream` スキーム＋`Brainstorm` プロファイル | Windows Terminal | install/（setup で適用） |
| U2 | **起動スクリプト**（`install/clbs`, `install/clbs-run`） | `clbs`＝新しい明るい窓を開く。`clbs-run`＝バナー表示→ブレストモード Claude Code を exec | wt.exe / cux or claude | install/（setup で `~/.local/bin` へ） |
| U3 | **Claude 設定オーバーレイ**（`install/brainstorm.json`） | ライトテーマ・bypass・厳選 `enabledPlugins`・statusLine・言語デフォルト | claude `--settings` | install/（setup で `~/.claude/` へ） |
| U4 | **プラグイン**（`plugins/brainstorm-harness/`） | コマンド（`/clbs` `/en` `/jp`）・SessionStart フック（挨拶/言語の文脈注入）・statusline スクリプト・(任意)ブレストスキル | Claude Code plugin loader | marketplace（`install` で有効化） |
| U5 | **アンブレラ・マーケット**（`.claude-plugin/marketplace.json` + `setup.sh` + `README`） | 配布カタログ。複数プラグインを列挙。setup がホストに U1–U3 を冪等適用 | git / GitHub | repo ルート |

### 責務分離の原則（＝「マーケット化は簡単？」への答え）
- **プラグインで“配れる”もの** = U4（コマンド・フック・statusline・スキル）。`install` するだけで有効化。
- **プラグインで“配れない”もの** = U1〜U3（Windows 側設定・`~/.bashrc` 相当の PATH・`~/.claude/` のユーザー設定・ターミナル色・エイリアス）。これらは **`setup.sh` を1回**走らせて各マシンに適用する。
- この非対称性が本ハーネスの核心的トレードオフであり、README で明示する。

---

## 4. データフロー（起動）

```
[どこからでも]      clbs ─────────┐
[WTドロップダウン]  Brainstorm ───┤→ Windows Terminal 新窓（Sunrise Cream スキーム）
[Claude Code内]     /clbs ────────┘        │
                                            ▼
        profile.commandline: wsl.exe -d Ubuntu -- bash -lic "clbs-run"
                                            │
        clbs-run:  (1) 明るい応援バナーを echo（★画面表示はここで確実に行う）
                   (2) exec  cux --settings ~/.claude/brainstorm.json
                             （cux 無ければ claude --settings ... --permission-mode bypassPermissions）
                                            │
                                            ▼
        Claude Code: theme=light / bypass / 厳選スキル / statusline(🌱淡色)
                     + SessionStart フックが「英語で・ブレスト前提で温かく挨拶」を文脈注入
                     + /en /jp で言語トグル
```

### 3つの入口（エイリアスもスラッシュも両対応）
- **WT プロファイル `Brainstorm`**（タブ表示は🌱）: `+` ドロップダウン／タスクバーのジャンプリストから1クリック。
- **`clbs`**（`~/.local/bin/clbs`）: `wt.exe -w new -p Brainstorm` を叩くだけ。VS Code 含むどの端末からでも新しい明るい窓が開く。
- **`/clbs`**（プラグインのスラッシュコマンド）: いま Claude Code の中にいるとき用。`wt.exe -w new -p Brainstorm` を実行して新窓をポップ。

> **プロファイル名は ASCII `Brainstorm`**（`wt.exe -p` のマッチと WSL からのクオートを安定させるため）。見た目の🌱は `tabTitle` / `icon` で付与。

---

## 5. 明るい見た目（「明るい気持ちになる画面」）

4層で“明るさ”を作る。

1. **ターミナル窓の色** = WT「Sunrise Cream」スキーム
   - background `#FFF8F0` / foreground `#4A4137` / accent(orange) `#E8871E`
   - green `#5E9E4A` / blue `#3A8FB7` / red `#D6564B` / purple `#9A6FB0` / cyan `#2FA6A6`
   - （明るい背景でも視認できるよう ANSI 16色を再調整。bright系も別途定義）
2. **Claude Code 本体** = `theme: "light"`（設定オーバーレイ U3 で指定）
3. **起動バナー**（U2 `clbs-run` が echo）= 温かいトーンの ASCII/emoji 一言。
   - 例: `🌱  Brainstorm Space  —  no wrong ideas here. What shall we dream up today?`
   - ★ **フックではなく起動スクリプトで出す**（後述の検証メモ参照。フック stdout は画面表示ではなくモデル文脈への注入のため）。
4. **statusline** = 🌱＋淡色の控えめ表示（`brainstorm mode` と分かる。モデル名など最小限）。

---

## 6. 言語切替（英日）

- 起動時デフォルト = **英語**（U4 SessionStart フックが `additionalContext` に「デフォルト英語・ブレスト前提で温かく」を注入）。
- `/en` = 以降 English、`/jp` = 以降 日本語（U4 コマンド。中身は言語指示を注入する軽量プロンプト）。どちらの入口でも両コマンド同梱。

---

## 7. 厳選スキル構成（ブレスト特化）

U3 の `enabledPlugins` に **ONにしたい厳選セットだけを列挙**する。`--settings` はキー単位の上書き（＝`enabledPlugins` オブジェクトごと置換。検証 V2）なので、**未列挙のプラグインはこのセッションでは自動的に落ちて無効化**される。OFF を明示する必要はない。

- **ON（列挙する）**: `brainstorm-harness@tech-teku-toolkit`（本プラグイン自体）, `superpowers`（brainstorming / writing-plans）, `everything-claude-code`（market-research / council / product-lens / blueprint / brand-voice 等）, `frontend-design`（ビジュアルモック）, `firecrawl`（Web調査）, `notion`（アイデア記録）
- **自動的に無効（列挙しない）**: コードレビュー系 / ビルド修復系 / ralph-loop / mcp-server-dev / groundwork / greptile / bells-and-whistles など。
- **常時利用可（組み込み）**: `deep-research`, `dataviz`, `artifact-design` はプラグイン外でも使えるので列挙不要。

> 列挙するプラグインは、そのマシンに **install 済み**である必要がある（オーバーレイは enable/disable のみで install はしない。検証 V2 の caveat）。

---

## 8. 配布・セットアップ（アンブレラ・マーケット）

```
tech-teku-toolkit/                         # ← GitHub Public。push = クラウド保存
├─ .claude-plugin/marketplace.json        # 複数プラグインを列挙するカタログ
├─ plugins/
│   ├─ brainstorm-harness/                # 今回のプラグイン(U4)
│   │   ├─ .claude-plugin/plugin.json
│   │   ├─ commands/  (clbs.md, en.md, jp.md)
│   │   ├─ hooks/hooks.json               (SessionStart: 挨拶/言語の文脈注入)
│   │   ├─ statusline/brainstorm-statusline.sh
│   │   └─ docs/…                          (この spec と bootstrap-log)
│   └─ (将来) harnesseed/                  # slot だけ用意。README に導線
├─ install/
│   ├─ brainstorm.json                     # U3 Claude 設定オーバーレイ
│   ├─ sunrise-cream.json                 # U1 WT スキーム＋プロファイル片
│   ├─ clbs, clbs-run                      # U2 起動スクリプト
│   └─ setup.sh                            # U1–U3 を各マシンに冪等適用
└─ README.md                               # 導入手順・トレードオフ明記
```

### 自分の導入 / 友達の導入
```
/plugin marketplace add <owner>/tech-teku-toolkit
/plugin install brainstorm-harness@tech-teku-toolkit
bash install/setup.sh        # WT の明るい窓・clbs・~/.claude/brainstorm.json を用意（1回だけ）
```

### `setup.sh` の責務（冪等）
1. WT settings.json を検出（`/mnt/c/Users/*/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json`）。
   - `schemes` に `Sunrise Cream` を追加（既存なら更新、二重登録しない）。
   - `profiles.list` に `Brainstorm` プロファイルを追加（GUID は生成・既存なら維持）。`commandline` は現在の WSL ディストロ名を埋め込む。
   - 変更前に settings.json をバックアップ。
2. `~/.local/bin/clbs`・`clbs-run` を配置（実行権限付与）。`clbs-run` 内の statusline パスと launcher を解決。
3. `~/.claude/brainstorm.json` を配置。statusLine のスクリプト絶対パスを解決して書き込む。
4. WT 非検出時（macOS/ネイティブLinux）は U1 をスキップし、「この環境では独立窓の色は未対応。Claude設定とスキルは有効」と表示。
5. `cux` 有無を検出して `clbs-run` の起動コマンドを切替（無ければ `claude` フォールバック）。

---

## 9. エラー処理・堅牢性・リスク

- **冪等性**: `setup.sh` は再実行安全（jq でマージ、二重登録なし、バックアップ）。
- **フォールバック**: `cux` 無 → `claude`。`wt.exe` 無 → 説明を出し通常 Claude Code 継続。
- **セキュリティ注記**: bypassPermissions はブレスト窓（ユーザーが明示起動）に限定。README で「この窓は権限確認をスキップする」ことを明記。グローバル設定は変更しない（オーバーレイのみ）。

### 技術前提の検証状況（詳細は `docs/bootstrap-log/2026-07-02-verify-0.md`）
- **R1 バナー表示** ✅解決: フック stdout は画面表示保証なし → **起動スクリプト echo** を採用（検証 V1）。
- **R2 enabledPlugins オーバーレイ** ✅解決: `--settings` はキー単位上書き（検証 V2）。**ONセットだけ列挙すれば未列挙は無効化**される。狙いどおり動作。
- **R3 statusLine** ✅解決: プラグインでは自動有効化されない（検証 V3）→ **オーバーレイで明示指定**（絶対パスは setup.sh が解決）。
- **R4 `wt.exe -p` のクオート** ✅解決: 絵文字未検証 → ASCII 名 `Brainstorm` 採用（検証 V7 / T2）。
- **T1 `theme` 有効値** ⚠️未確定: `"light"` の可否は非公開ドキュメント → **実装時にローカル `/config` で確認**。不可なら `light-daltonized` 等 or `auto`（ターミナル自体が明るいので実害小）。

---

## 10. 検証（verify）

- **手動**: `clbs` → 明るい新窓が開く／応援バナーが出る／`theme:light`・bypass・厳選スキルが効く／statusline が🌱表示。`/en`・`/jp` の切替。
- **配布**: クリーン想定で `marketplace add` → `install` → `setup.sh` を実行し、冪等性（2回目で壊れない）と WT 反映を確認。
- **回帰**: `setup.sh` がグローバル `~/.claude/settings.json` を破壊しないこと（オーバーレイのみ）を確認。

---

## 11. 未解決・確認したいこと

- ✅ アンブレラ repo 名 = マーケットプレイス名 = `tech-teku-toolkit` で確定（2026-07-02）。
- harnesseed の移設は別タスク（今回は slot と README 導線のみ）で良いか。
