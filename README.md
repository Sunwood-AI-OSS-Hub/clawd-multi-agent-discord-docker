<div align="center">

![header](assets/header.png)

# Clawd Agent3

## ～clawd-multi-agent-discord-docker～

[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com/)
[![Discord](https://img-shields.io/badge/Discord-API%20v10-5865F2.svg)](https://discord.com/developers/docs)
[![GLM-4.7](https://img.shields.io/badge/AI-GLM--4.7-FF6B6B.svg)](https://open.bigmodel.cn/)
[![Clawdbot](https://img.shields.io/badge/Bot-Clawdbot-7C3AED.svg)](https://docs.clawd.bot)

**日本語** | [English](README.en.md)

**3つの独立したAI Discordボット**をDocker Composeで運用するための完全セットアップ

1つのGLM-4.7 APIキーを共有しつつ、各ボットは独立したゲートウェイプロセスで動作します。

</div>

---

## 目次

- [概要](#概要)
- [アーキテクチャ](#アーキテクチャ)
- [ボット設定](#ボット設定)
- [前提条件](#前提条件)
- [クイックスタート](#クイックスタート)
- [設定](#設定)
- [コマンド](#コマンド)
- [トラブルシューティング](#トラブルシューティング)
- [参考文献](#参考文献)
- [ライセンス](#ライセンス)

---

## 概要

このプロジェクトでは、**Clawdbot**を使用して3つの独立したDiscordボットをDocker Composeで運用します。各ボットは独自のゲートウェイプロセスとコンテナで動作し、GLM-4.7 AIモデルを共有します。

### 特徴

- **3つの独立したボット**: 各ボットが独立したプロセスで動作
- **共有AIモデル**: GLM-4.7 APIキーを共有
- **Docker Compose**: ワンコマンドで起動・管理
- **分離されたワークスペース**: 各ボット専用のワークスペース
- **簡単な設定**: JSONベースの設定管理

---

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────┐
│                      Docker Host                             │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  clawdbot-   │  │  clawdbot-   │  │  clawdbot-   │      │
│  │    bot1      │  │    bot2      │  │    bot3      │      │
│  │  (CL1-Kuroha)│  │  (CL2-Reika) │  │ (CL3-Sentinel)│     │
│  │              │  │              │  │              │      │
│  │  Gateway     │  │  Gateway     │  │  Gateway     │      │
│  │  Port: 18789 │  │  Port: 18791 │  │  Port: 18793 │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                 │                 │              │
│         └─────────────────┴─────────────────┘              │
│                         │                                   │
│                   ┌─────▼─────┐                             │
│                   │   GLM API  │                             │
│                   │  (共通使用)  │                             │
│                   └───────────┘                             │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
                   ┌───────────────┐
                   │  Discord API   │
                   │  (各ボットが   │
                   │   別セッション) │
                   └───────────────┘
```

---

## ボット設定

| ボット名 | ポート | 説明 |
|---------|--------|------|
| CL1-Kuroha | 18789 | Bot 1 - メインエージェント |
| CL2-Reika | 18791 | Bot 2 - サポートエージェント |
| CL3-Sentinel | 18793 | Bot 3 - モニターエージェント |

---

## 前提条件

- [Docker](https://docs.docker.com/get-docker/) と [Docker Compose v2](https://docs.docker.com/compose/install/)
- [Zhipu AI GLM-4.7](https://open.bigmodel.cn/) API Key
- 3つの [Discord Bot Tokens](https://discord.com/developers/applications)

### Discord Bot に必要なインテント

- Message Content Intent
- Server Members Intent
- Presence Intent

---

## クイックスタート

### 1. リポジトリをクローン

```bash
git clone --recursive https://github.com/Sunwood-AI-OSS-Hub/clawd-multi-agent-discord-docker.git
cd clawd-multi-agent-discord-docker
```

### 2. Dockerイメージをビルド

```bash
docker build -t clawdbot:local ./clawdbot
```

### 3. 環境変数を設定

`.env.example` を `.env` にコピーして、認証情報を入力します：

```bash
cp .env.example .env
```

ゲートウェイトークンを生成します（3つの別々のトークン）：

```bash
openssl rand -hex 32  # Bot 1 用
openssl rand -hex 32  # Bot 2 用
openssl rand -hex 32  # Bot 3 用
```

`.env` を編集：

```bash
# ゲートウェイトークン（3つの異なる値）
CLAWDBOT_BOT1_GATEWAY_TOKEN=生成したトークン1
CLAWDBOT_BOT2_GATEWAY_TOKEN=生成したトークン2
CLAWDBOT_BOT3_GATEWAY_TOKEN=生成したトークン3

# GLM 4.7 APIキー（共通）
ZAI_API_KEY=あなたのGLM_APIキー

# Discord Botトークン（3つの別々のアカウント）
DISCORD_BOT1_TOKEN=あなたのDiscordトークン1
DISCORD_BOT2_TOKEN=あなたのDiscordトークン2
DISCORD_BOT3_TOKEN=あなたのDiscordトークン3
```

### 4. ボットを設定

各ボットには `config/bot*/` 以下に設定ファイルが必要です：

#### `models.json`（全ボット共通）

```json
{
  "mode": "append",
  "providers": {
    "zai": {
      "baseUrl": "https://api.zai.ai/v1/",
      "apiKey": "あなたのGLM_APIキー",
      "api": "openai-completions",
      "models": [
        {
          "id": "glm-4.7",
          "name": "GLM-4.7"
        }
      ]
    }
  }
}
```

#### `clawdbot.json`（全ボット共通）

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "zai/glm-4.7"
      }
    }
  },
  "channels": {
    "discord": {
      "enabled": true,
      "groupPolicy": "open"
    }
  },
  "gateway": {
    "mode": "local"
  },
  "messages": {
    "ackReactionScope": "all"
  }
}
```

### 5. ボットを起動

```bash
# 全てのボットを起動
docker compose up -d

# ステータス確認
docker compose ps

# ログ表示
docker compose logs -f
```

---

## 設定

### ディレクトリ構造

```
./
├── docker-compose.yml
├── .env
├── .env.example
├── README.md
├── setup.sh
├── assets/
│   └── header.png
├── clawdbot/          # Clawdbot ソース
├── config/
│   ├── bot1/
│   │   ├── clawdbot.json
│   │   ├── models.json
│   │   └── cron/
│   │       └── jobs.json
│   ├── bot2/
│   │   ├── clawdbot.json
│   │   ├── models.json
│   │   └── cron/
│   │       └── jobs.json
│   ├── bot3/
│   │   ├── clawdbot.json
│   │   ├── models.json
│   │   └── cron/
│   │       └── jobs.json
│   └── clawdbot.json  # グローバル設定
└── workspace/
    ├── bot1/
    ├── bot2/
    └── bot3/
```

### 設定オプション

#### clawdbot.json

| オプション | 値 | 説明 |
|--------|-------|-------------|
| `agents.defaults.model.primary` | `zai/glm-4.7` | メインAIモデル |
| `channels.discord.enabled` | `true` | Discordを有効化 |
| `channels.discord.groupPolicy` | `open` | レスポンスポリシー（`open`/`allowlist`） |
| `messages.ackReactionScope` | `all` | リアクション範囲（`all`/`group-mentions`） |

**groupPolicy:**
- `open`: 全てのチャンネルで応答
- `allowlist`: 許可されたチャンネルのみで応答

**ackReactionScope:**
- `all`: 全てのメッセージにリアクション
- `group-mentions`: メンション時のみリアクション

#### models.json

| オプション | 値 | 説明 |
|--------|-------|-------------|
| `mode` | `append` | 既存プロバイダーに追加 |
| `providers.zai.baseUrl` | ZAI APIエンドポイント | Zhipu AI API URL |
| `providers.zai.api` | `openai-completions` | OpenAI互換モード |

---

## コマンド

### ボット操作

```bash
# 全てのボットを起動
docker compose up -d

# 全てのボットを停止
docker compose down

# 全てのボットを再起動
docker compose restart

# 特定のボットを再起動
docker compose restart clawdbot-bot1

# 特定のボットのログを表示
docker compose logs -f clawdbot-bot1

# 全てのログを表示
docker compose logs -f
```

### CLI アクセス

```bash
# bot1のCLIにアクセス
docker compose --profile cli run --rm clawdbot-cli

# CLI経由でDiscordチャンネルを追加
docker compose --profile cli run --rm clawdbot-cli \
    channels add --channel discord --token "${DISCORD_BOT1_TOKEN}"
```

### コンテナアクセス

```bash
# コンテナ内でコマンド実行
docker exec -it clawdbot-bot1 node dist/index.js config set ...

# 対話型シェル
docker exec -it clawdbot-bot1 /bin/bash
```

---

## トラブルシューティング

### "Unknown model: glm/glm-4.7" エラー

**原因:** `models.json` の設定ミスまたは無効な API キー

**解決策:**
1. `models.json` 内の `apiKey` を確認
2. GLM APIキーが有効か確認
3. GLM APIアクセスをテスト

### ボットがオフライン表示

**原因:** 無効な Discord トークンまたは不足したインテント

**解決策:**
1. `.env` 内の Discord トークンを確認
2. Discord Developer Portal で **Message Content Intent** を有効化
3. ボットがサーバーに招待されていることを確認

### "gateway already running" エラー

**原因:** 古いプロセスがまだ実行中

**解決策:**
```bash
docker compose down
docker compose up -d
```

### ポート競合

**原因:** ポート 18789, 18791, 18793 が既に使用中

**解決策:**
```bash
# ポートを使用しているプロセスを検索
sudo lsof -i :18789

# プロセスを終了
sudo kill -9 <PID>
```

### リアクションが動作しない

**原因:** `ackReactionScope` の設定

**解決策:** `config/bot*/clawdbot.json` を確認：
```json
{
  "messages": {
    "ackReactionScope": "all"
  }
}
```

---

## 参考文献

- [Clawdbot ドキュメント](https://docs.clawd.bot)
- [Clawdbot GitHub](https://github.com/clawdbot/clawdbot)
- [Zhipu AI GLM API](https://open.bigmodel.cn/)
- [Discord Developer Portal](https://discord.com/developers/applications)
- [Docker ドキュメント](https://docs.docker.com/)

---

## ライセンス

このプロジェクトは Clawdbot のセットアップ例です。
詳細については [Clawdbot ライセンス](https://github.com/clawdbot/clawdbot/blob/main/LICENSE) を参照してください。

---

<div align="center">

Made with ❤️ by [Sunwood AI OSS Hub](https://github.com/Sunwood-AI-OSS-Hub)

</div>
