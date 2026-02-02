# OpenClaw-Docker 開発計画

……ふふ、これからの計画をまとめておくね。

---

## 概要

このプロジェクトは、**OpenClaw-Docker** を拡張し、以下の機能を追加するための開発計画です。

1. **MultimediaOS-MUGENスキルの統合** - fal.ai APIによる画像生成・動画制作機能の追加
2. **Jetson対応** - NVIDIA Jetsonデバイスでの動作確認と最適化
3. **ハードウェア制御機能** - JetsonのGPIO/CPU/GPU制御機能の実装
4. **ブラウザ自動化とGoogle認証** - PlaywrightによるGoogleアカウント連携（Infinity版）

---

## Phase 1: MultimediaOS-MUGENスキル統合

### 1.1 スキル構造の統合

#### 現状のMultimediaOS-MUGENスキル構造

```
MultimediaOS-MUGEN/
├── .claude/
│   └── skills/
│       └── fal-ai/
│           ├── SKILL.md
│           ├── scripts/
│           │   ├── generate-image.ts
│           │   ├── edit-image.ts
│           │   ├── image-to-video.ts
│           │   └── image-to-video-audio.ts
│           └── references/
```

#### 統合先（OpenClaw-Docker）

```
/prj/cbot/
├── openclaw/
│   └── skills/           # スキル統合先
├── workspace/
│   ├── agent1/
│   ├── bot2/
│   └── bot3/
└── outputs/              # 新規作成：マルチメディア出力用
    ├── images/
    │   ├── generated/
    │   └── edited/
    └── videos/
        └── generated/
```

#### タスク

- [ ] **1.1.1** fal-aiスキルを `openclaw/skills/` に統合
  - スキル定義ファイル（SKILL.md）のコピー
  - スクリプトファイルの配置
  - 依存関係のインストール（pnpm install）

- [ ] **1.1.2** 環境変数の設定
  - `FAL_KEY` の追加（`.env.example` への追記）
  - APIキーの管理方法の決定

- [ ] **1.1.3** 出力ディレクトリの作成
  - `outputs/` ディレクトリ構造の作成
  - Docker Composeでのボリュームマウント設定

### 1.2 Discordボットとの連携

- [ ] **1.2.1** Discordコマンドの追加
  - `/generate-image` - 画像生成コマンド
  - `/edit-image` - 画像編集コマンド
  - `/create-video` - 動画生成コマンド

- [ ] **1.2.2** レスポンス機能の実装
  - 生成結果のDiscordへのアップロード
  - 進捗状況の表示
  - エラーハンドリング

### 1.3 依存関係の管理

```bash
# 追加パッケージ
pnpm add @fal-ai/serverly-client
pnpm add -D typescript
```

---

## Phase 2: Jetson対応

### 2.1 ARM64アーキテクチャ対応確認

#### 現状

Dockerイメージは既にマルチアーキテクチャ対応済み：

| プラットフォーム | 状態 |
|:-----------------|:-----|
| linux/amd64 | ✅ 対応済み |
| linux/arm64 | ✅ 対応済み（理論上） |

#### タスク

- [ ] **2.1.1** 実機での動作確認（Jetson Orin/Nano/Xavier）
  - Dockerイメージのプル/ビルド確認
  - コンテナ起動の確認
  - ボット基本機能の動作確認

- [ ] **2.1.2** パフォーマンス調査
  - CPU/GPU使用率の計測
  - メモリ使用量の確認
  - 起動時間の計測

### 2.2 Jetson固有の最適化

- [ ] **2.2.1** JetPack SDKとの互換性確認
  - CUDAバージョンの確認
  - cuDNNバージョンの確認
  - TensorRTとの統合検討

- [ ] **2.2.2** 電力モードの最適化
  - `nvpmodel` （NVIDIA Power Model）の設定
  - `jetson_clocks` の適用検討
  - 熱スロットリング対策

- [ ] **2.2.3** Docker Compose設定の調整
  - Jetson用の `docker-compose.jetson.yml` 作成
  - リソース制限の調整
  - デバイス（`/dev/video*`, GPU）のマウント設定

### 2.3 トラブルシューティングドキュメント

- [ ] **2.3.1** Jetsonセットアップガイドの作成
  - 初期設定手順
  - よくある問題と解決策
  - パフォーマンスチューニングガイド

---

## Phase 3: ハードウェア制御機能

### 3.1 GPIO制御

#### 目的

JetsonのGPIOピンを使って、外部デバイス（LED、リレー、センサー等）を制御する。

- [ ] **3.1.1** ライブラリ選定
  - `onoff` - Node.js用GPIOライブラリ（要確認）
  - `rpi-gpio` - ラズベパイ用（Jetsonで動作するか検証）
  - Jetson GPIO Pythonライブラリのラッパー検討

- [ ] **3.1.2** スキル実装
  - `skills/gpio-control/SKILL.md` の作成
  - 基本的なGPIO操作（入力/出力）の実装
  - PWM制御の実装

- [ ] **3.1.3** Discordコマンドとの連携
  - `/gpio-set` - GPIOピンの設定
  - `/gpio-read` - GPIOピンの状態読み取り
  - `/pwm-set` - PWM出力の設定

### 3.2 システム制御

- [ ] **3.2.1** CPU/GPU制御
  - CPU周波数の取得・設定
  - GPU周波数の取得・設定
  - 電力モードの切り替え

- [ ] **3.2.2** 温度・電圧モニタリング
  - SoC温度の取得
  - 電圧の取得
  - ファン速度の制御

- [ ] **3.2.3** スキル実装
  - `skills/system-monitor/SKILL.md` の作成
  - システム情報取得スクリプトの実装
  - Discordレポート機能の追加

### 3.3 カメラ・マルチメディア

- [ ] **3.3.1** カメラデバイス対応
  - USBカメラのサポート
  - CSIカメラ（Jetson独自）のサポート
  - GStreamer Pipelineとの連携

- [ ] **3.3.2** 画像処理機能
  - Open.jsとの統合
  - リアルタイム画像処理
  - 顔検出・物体検出

---

## Phase 4: ブラウザ自動化とGoogleアカウント認証

> **Infinity版のみ対応**
> この機能は `docker-compose.infinity.yml` で動作するInfinity版にのみ含まれます。

### 4.1 Playwrightによるブラウザ自動化

#### 現状のInfinity版構成

```
docker/
└── Dockerfile.infinity
    ├── Playwright     # ✅ インストール済み
    ├── GitHub CLI     # ✅ インストール済み
    └── 非rootユーザー   # ✅ 設定済み
```

#### タスク

- [ ] **4.1.1** ブラウザスキルの実装
  - `skills/browser-automation/SKILL.md` の作成
  - 基本的なブラウザ操作（ナビゲーション、スクリーンショット）の実装
  - 要素取得・クリック・入力などの操作実装

- [ ] **4.1.2** セッション管理
  - ブラウザセッションの永続化
  - Cookie/LocalStorageの保存・復元
  - 複数セッションの管理

### 4.2 Googleアカウント認証

#### 目的

エージェントがGoogleアカウントにログインし、各種Googleサービス（Gmail、Google Drive、Google Photos等）を操作できるようにする。

- [ ] **4.2.1** 認証フローの実装
  - Googleログインページへのアクセス
  - メールアドレス・パスワードの入力
  - 2要素認証（2FA）の対応
  - セッションの保存

- [ ] **4.2.2** 認証情報の管理
  - 環境変数による認証情報の管理
    - `GOOGLE_ACCOUNT_EMAIL`
    - `GOOGLE_ACCOUNT_PASSWORD`（またはアプリパスワード）
    - `GOOGLE_2FA_SECRET`（TOTPの場合）
  - 秘密情報の安全な取り扱い
  - セッションファイルの暗号化検討

- [ ] **4.2.3** スキル実装
  - `skills/google-auth/SKILL.md` の作成
  - ログイン・ログアウト機能の実装
  - セッション状態の確認機能

- [ ] **4.2.4** Discordコマンドとの連携
  - `/google-login` - Googleアカウントにログイン
  - `/google-logout` - Googleアカウントからログアウト
  - `/google-status` - 認証状態の確認

### 4.3 Googleサービス連携

- [ ] **4.3.1** Gmail操作
  - メールの取得
  - メールの送信
  - 添付ファイルの操作

- [ ] **4.3.2** Google Drive操作
  - ファイルのアップロード・ダウンロード
  - フォルダの作成・管理
  - 共有設定の変更

- [ ] **4.3.3** Google Photos操作
  - 画像のアップロード
  - アルバムの作成・管理
  - fal-aiスキルとの連携

### 4.4 セキュリティ考慮事項

#### 必須セキュリティ対策

- [ ] **4.4.1** 認証情報の保護
  - パスワードは環境変数で管理（コードにハードコード禁止）
  - セッションファイルはコンテナ内に保存（ホストへマウントしない）
  - ログに認証情報を出力しない

- [ ] **4.4.2** アプリパスワードの使用
  - 通常のパスワードではなくGoogleアプリパスワードを使用
  - 2FA有効アカウントでの認証

- [ ] **4.4.3** アクセス制限
  - 特定のDiscordチャンネル/ユーザーのみ操作可能にする
  - 操作ログの記録

### 4.5 トラブルシューティング

- [ ] **4.5.1** セッション切れ対策
  - 自動再ログイン機能
  - セッション有効期限の監視

- [ ] **4.5.2** 2FA対応
  - TOTP（Time-based One-Time Password）ライブラリの検討
  - SMS認証のサポート検討

- [ ] **4.5.3** CAPTCHA対応
  - reCAPTCHA回避策の検討
  - 手動介入フローの設計

### 4.6 ディレクトリ構造

```
/prj/cbot/
├── openclaw/
│   └── skills/
│       ├── browser-automation/
│       │   ├── SKILL.md
│       │   ├── scripts/
│       │   │   ├── navigate.ts
│       │   │   ├── screenshot.ts
│       │   │   └── session.ts
│       │   └── references/
│       └── google-auth/
│           ├── SKILL.md
│           ├── scripts/
│           │   ├── login.ts
│           │   ├── logout.ts
│           │   ├── gmail.ts
│           │   ├── drive.ts
│           │   └── photos.ts
│           └── references/
├── workspace/
│   └── agent1/
│       └── browser-sessions/  # セッション保存先（ボリュームマウント）
└── config/
    └── browser/
        └── auth-config.json   # 認証設定
```

---

## Phase 5: インテグレーションとテスト

### 4.1 統合テスト

- [ ] **4.1.1** 機能テスト
  - fal-aiスキル × Discordボット
  - ハードウェア制御 × Discordボット
  - マルチボット環境での動作確認

- [ ] **4.1.2** Jetson実機テスト
  - 長時間稼働テスト
  - 負荷テスト
  - 熱問題の検証

### 4.2 ドキュメント整備

- [ ] **4.2.1** READMEの更新
  - Jetson対応の記載
  - ハードウェア制御機能の説明
  - セットアップ手順の追加

- [ ] **4.2.2** APIドキュメント
  - スキルAPIのドキュメント化
  - Discordコマンドリファレンス

---

## リソース

### 外部リソース

- [MultimediaOS-MUGEN](https://github.com/Sunwood-AI-OSS-Hub/MultimediaOS-MUGEN)
- [fal.ai ドキュメント](https://docs.fal.ai/)
- [NVIDIA Jetson Platform](https://developer.nvidia.com/embedded/jetson-platform)
- [Jetson Zoo](https://elinux.org/Jetson_Zoo)

### 関連スキル

- `openclaw/skills/` - 既存スキル群
- `openclaw/extensions/` - 拡張機能

---

## マイルストーン

| マイルストーン | 予定目標 | ステータス |
|--------------|---------|----------|
| M1: fal-aiスキル統合 | 基本的な画像生成機能の動作 | `pending` |
| M2: Jetson起動確認 | Jetsonでのボット動作確認 | `pending` |
| M3: ハードウェア制御 | GPIO/システム制御の実装 | `pending` |
| M4: ブラウザ自動化とGoogle認証 | PlaywrightによるGoogleアカウント連携 | `pending` |
| M5: リリース | v0.3.0 リリース | `pending` |

---

……ふふ、こんな感じでどう？

計画は見つけてくれた人の手で進めていくから、私も手伝うよ。

何か追加したいことがあったら教えてね。
