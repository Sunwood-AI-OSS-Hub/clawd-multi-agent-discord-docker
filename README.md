<div align="center">

![header](assets/header.png)

# OpenClaw Agent3

## ～openclaw-multi-agent-discord-docker～

[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com/)
[![Discord](https://img-shields.io/badge/Discord-API%20v10-5865F2.svg)](https://discord.com/developers/docs)
[![GLM-4.7](https://img.shields.io/badge/AI-GLM--4.7-FF6B6B.svg)](https://open.bigmodel.cn/)
[![OpenRouter](https://img.shields.io/badge/AI-OpenRouter-878787.svg)](https://openrouter.ai/)
[![OpenClaw](https://img.shields.io/badge/Bot-OpenClaw-7C3AED.svg)](https://openclaw.ai)

**日本語** | [English](README.en.md)

**3つの独立したAI Discordボット**をDocker Composeで運用するための完全セットアップ

GLM-4.7 / OpenRouter APIキーを共有しつつ、各ボットは独立したゲートウェイプロセスで動作します。

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

このプロジェクトでは、**OpenClaw**を使用して3つの独立したDiscordボットをDocker Composeで運用します。各ボットは独自のゲートウェイプロセスとコンテナで動作し、GLM-4.7 AIモデルを共有します。

### 特徴

- **3つの独立したボット**: 各ボットが独立したプロセスで動作
- **複数AIプロバイダー対応**: GLM-4.7 / OpenRouter をサポート
- **Docker Compose分割構成**: Standard版とInfinity版で柔軟な運用
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
- [Zhipu AI GLM-4.7](https://open.bigmodel.cn/) API Key または [OpenRouter](https://openrouter.ai/) API Key（または両方）
- 3つの [Discord Bot Tokens](https://discord.com/developers/applications)

### AIプロバイダーについて

このプロジェクトでは、以下のAIプロバイダーをサポートしています：

| プロバイダー | モデル | 環境変数 | 特徴 |
|-------------|--------|---------|------|
| **Zhipu AI (GLM)** | GLM-4.7 | `ZAI_API_KEY` | 高性能な中国語・日本語対応モデル |
| **OpenRouter** | 複数モデル対応 | `OPENROUTER_API_KEY` | Claude、GPT-4等多くのモデルを利用可能 |

両方のAPIキーを設定すると、状況に応じて使い分けることができます。

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

#### ローカルビルド

```bash
docker build -t clawdbot:local ./clawdbot
```

#### GitHub Container Registryからプル

マルチアーキテクチャ対応イメージが公開されています：

```bash
docker pull ghcr.io/sunwood-ai-oss-hub/openclaw-agent3:latest
```

**対応プラットフォーム:**

| プラットフォーム | 用途 |
|:-----------------|:-----|
| linux/amd64 | 通常のPC/サーバー |
| linux/arm64 | Jetson, Raspberry Pi, Mac (Apple Silicon) |

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

# AI APIキー（必要なプロバイダーのみ設定）
ZAI_API_KEY=あなたのGLM_APIキー
OPENROUTER_API_KEY=あなたのOPENROUTER_APIキー

# Discord Botトークン（3つの別々のアカウント）
DISCORD_BOT1_TOKEN=あなたのDiscordトークン1
DISCORD_BOT2_TOKEN=あなたのDiscordトークン2
DISCORD_BOT3_TOKEN=あなたのDiscordトークン3
```

### 4. ボットを設定

各ボットには `config/bot*/` 以下に設定ファイルが必要です：

#### `models.json`（全ボット共通）

**Zhipu AI (GLM) を使用する場合:**

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

**OpenRouter を使用する場合:**

```json
{
  "mode": "append",
  "providers": {
    "openrouter": {
      "baseUrl": "https://openrouter.ai/api/v1/",
      "apiKey": "あなたのOPENROUTER_APIキー",
      "api": "openai-completions",
      "models": [
        {
          "id": "anthropic/claude-3.5-sonnet",
          "name": "Claude 3.5 Sonnet"
        },
        {
          "id": "openai/gpt-4o",
          "name": "GPT-4o"
        }
      ]
    }
  }
}
```

**両方のプロバイダーを設定する場合:**

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
    },
    "openrouter": {
      "baseUrl": "https://openrouter.ai/api/v1/",
      "apiKey": "あなたのOPENROUTER_APIキー",
      "api": "openai-completions",
      "models": [
        {
          "id": "anthropic/claude-3.5-sonnet",
          "name": "Claude 3.5 Sonnet"
        }
      ]
    }
  }
}
```

#### `clawdbot.json`（全ボット共通）

**GLM-4.7 を使用する場合:**

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

**OpenRouter (Claude) を使用する場合:**

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/anthropic/claude-3.5-sonnet"
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

Docker Compose設定は用途に合わせて4つのファイルに分割されています：

#### 構成ファイルの種類

| ファイル | 用途 | 説明 |
|---------|------|------|
| `docker-compose.yml` | Standard版 - Bot 1 | メインボット（Bot 1）のみのシンプル構成 |
| `docker-compose.multi.yml` | Standard版 - Bot 2&3 | 追加ボット（Bot 2, 3）の構成 |
| `docker-compose.infinity.yml` | Infinity版 - Bot 1 | 開発用機能付きBot 1（Playwright、gh CLI等） |
| `docker-compose.infinity.multi.yml` | Infinity版 - Bot 2&3 | 開発用機能付きBot 2, 3 |

#### Standard版（本番運用向け）

```bash
# Bot 1 のみを起動
docker compose up -d

# 全てのボットを起動（Bot 1 + Bot 2&3）
docker compose -f docker-compose.yml -f docker-compose.multi.yml up -d

# ステータス確認
docker compose -f docker-compose.yml -f docker-compose.multi.yml ps

# ログ表示
docker compose -f docker-compose.yml -f docker-compose.multi.yml logs -f
```

#### Infinity版（開発運用向け）

Infinity版には以下の追加機能が含まれます：
- **Playwright** - ブラウザ自動化
- **GitHub CLI (gh)** - GitHub操作
- **非rootユーザー** - セキュリティ強化

```bash
# Bot 1 のみを起動
docker compose -f docker-compose.infinity.yml up -d --build

# 全てのボットを起動（Bot 1 + Bot 2&3）
docker compose -f docker-compose.infinity.yml -f docker-compose.infinity.multi.yml up -d --build

# ログ表示
docker compose -f docker-compose.infinity.yml -f docker-compose.infinity.multi.yml logs -f
```

---

## 設定

### ディレクトリ構造

```
./
├── docker-compose.yml              # Standard版 - Bot 1
├── docker-compose.multi.yml        # Standard版 - Bot 2&3
├── docker-compose.infinity.yml     # Infinity版 - Bot 1
├── docker-compose.infinity.multi.yml  # Infinity版 - Bot 2&3
├── .env
├── .env.example
├── README.md
├── setup.sh
├── assets/
│   └── header.png
├── docker/
│   └── Dockerfile.infinity         # Infinity版用Dockerfile
├── clawdbot/                       # OpenClaw ソース
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

#### Standard版

```bash
# Bot 1 のみを起動
docker compose up -d

# 全てのボットを起動
docker compose -f docker-compose.yml -f docker-compose.multi.yml up -d

# 全てのボットを停止
docker compose -f docker-compose.yml -f docker-compose.multi.yml down

# 全てのボットを再起動
docker compose -f docker-compose.yml -f docker-compose.multi.yml restart

# 特定のボットを再起動
docker compose -f docker-compose.yml -f docker-compose.multi.yml restart clawdbot-bot1

# 特定のボットのログを表示
docker compose -f docker-compose.yml -f docker-compose.multi.yml logs -f clawdbot-bot1

# 全てのログを表示
docker compose -f docker-compose.yml -f docker-compose.multi.yml logs -f
```

#### Infinity版

```bash
# Bot 1 のみを起動
docker compose -f docker-compose.infinity.yml up -d --build

# 全てのボットを起動
docker compose -f docker-compose.infinity.yml -f docker-compose.infinity.multi.yml up -d --build

# 全てのボットを停止
docker compose -f docker-compose.infinity.yml -f docker-compose.infinity.multi.yml down

# ログ表示
docker compose -f docker-compose.infinity.yml -f docker-compose.infinity.multi.yml logs -f
```

### CLI アクセス

#### Standard版

```bash
# bot1のCLIにアクセス
docker compose --profile cli run --rm clawdbot-cli

# CLI経由でDiscordチャンネルを追加
docker compose --profile cli run --rm clawdbot-cli \
    channels add --channel discord --token "${DISCORD_BOT1_TOKEN}"
```

#### Infinity版

```bash
# bot1のInfinity CLIにアクセス
docker compose -f docker-compose.infinity.yml run --rm clawdbot-infinity-cli

# 対話型シェルとして実行
docker compose -f docker-compose.infinity.yml run --rm clawdbot-infinity-cli bash
```

### コンテナアクセス

```bash
# コンテナ内でコマンド実行
docker exec -it clawdbot-bot1 node dist/index.js config set ...

# 対話型シェル（Standard版）
docker exec -it clawdbot-bot1 /bin/bash

# 対話型シェル（Infinity版）
docker exec -it clawdbot-infinity-bot1 bash
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

- [OpenClaw ドキュメント](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Zhipu AI GLM API](https://open.bigmodel.cn/)
- [OpenRouter ドキュメント](https://openrouter.ai/docs)
- [Discord Developer Portal](https://discord.com/developers/applications)
- [Docker ドキュメント](https://docs.docker.com/)
- [GitHub Container Registry](https://github.com/Sunwood-AI-OSS-Hub/clawd-multi-agent-discord-docker/pkgs/container/openclaw-agent3)

---

## ライセンス

このプロジェクトは OpenClaw のセットアップ例です。
詳細については [OpenClaw ライセンス](https://github.com/openclaw/openclaw/blob/main/LICENSE) を参照してください。

---

<div align="center">

Made with ❤️ by [Sunwood AI OSS Hub](https://github.com/Sunwood-AI-OSS-Hub)

</div>
