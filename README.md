<div align="center">

![header](assets/header-a.png)

# OpenClaw-Docker

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
│  │  openclaw-   │  │  openclaw-   │  │  openclaw-   │      │
│  │    agent1      │  │    agent2      │  │    agent3      │      │
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
| CL1-Kuroha | 18789 | Agent 1 - メインエージェント |
| CL2-Reika | 18791 | Agent 2 - サポートエージェント |
| CL3-Sentinel | 18793 | Agent 3 - モニターエージェント |

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

### 🚀 シンプルセットアップ

`config/examples/` にある設定ファイルをコピーするだけで、簡単にセットアップできます。

```bash
# 1. リポジトリをクローン
git clone --recursive https://github.com/Sunwood-AI-OSS-Hub/OpenClaw-Docker.git
cd OpenClaw-Docker

# 2. .envファイルを設定
cp .env.example .env
nano .env  # お好みのエディタで編集
```

`.env` に以下を設定：
- `ZAI_API_KEY` または `OPENROUTER_API_KEY`（AIプロバイダーのAPIキー）
- `DISCORD_AGENT1_TOKEN`, `DISCORD_AGENT2_TOKEN`, `DISCORD_AGENT3_TOKEN`（Discordボットトークン）
- ゲートウェイトークン（`openssl rand -hex 32` で生成）

```bash
# 3. 設定ファイルをコピー（ZAIを使用する場合）
for agent in agent1 agent2 agent3; do
    mkdir -p config/$agent/cron
    cp config/examples/models.json.example config/$agent/models.json
    cp config/examples/openclaw.json.example config/$agent/openclaw.json
    echo '{"jobs":[]}' > config/$agent/cron/jobs.json
done
```

OpenRouterを使用する場合は、`models.openrouter.json.example` と `openclaw.openrouter.json.example` をコピーしてください。

```bash
# 4. ボットを起動
docker compose -f docker-compose.yml -f docker-compose.multi.yml up -d
```

### 🔧 自動セットアップスクリプトを使う

`setup.sh` スクリプトを使うと、1つずつエージェントを簡単にセットアップできます。

```bash
# 実行権限を付与
chmod +x setup.sh

# Agent 1 をセットアップ（対話モード）
./setup.sh

# Agent 2 をセットアップ（対話モード）
./setup.sh 2

# Agent 3 をセットアップ（非対話モード）
./setup.sh 3 -y
```

**スクリプトの機能:**
- `.env` ファイルの自動作成
- ゲートウェイトークンの自動生成
- configディレクトリとワークスペースの初期化
- OpenClawブートストラップファイルの作成（AGENTS.md, SOUL.md等）
- GitHubプライベートリポジトリの自動作成とプッシュ（ghコマンド使用時）
- Discordチャンネルの自動追加

**オプション:**
| オプション | 説明 |
|---------|------|
| `-y, --yes` | 非対話モード（すべてのプロンプトに自動でYes） |
| `-h, --help` | ヘルプを表示 |

**例:**
```bash
# ヘルプを表示
./setup.sh -h

# Agent 2 を非対話モードでセットアップ
./setup.sh 2 -y
```

### 📡 リモートマシンでのセットアップ（SSH経由）

WindowsからSSHでJetsonなどのリモートマシンにセットアップする場合：

```bash
# 1. ローカルで.envファイルを準備
# D:\Prj\jetson-nano-ws\.env にAPIキーとトークンを設定

# 2. リモートマシンにSSH接続
ssh maki-jetson
cd ~/Prj

# 3. リポジトリをクローン（まだの場合）
git clone --recursive https://github.com/Sunwood-AI-OSS-Hub/OpenClaw-Docker.git
cd OpenClaw-Docker

# 4. ローカルの.envを転送
# 別のターミナルで：
scp D:\Prj\jetson-nano-ws\.env maki-jetson:~/Prj/OpenClaw-Docker/.env

# 5. 設定ファイルをコピー（SSH接続したターミナルで）
for agent in agent1 agent2 agent3; do
    mkdir -p config/$agent/cron
    cp config/examples/models.json.example config/$agent/models.json
    cp config/examples/openclaw.json.example config/$agent/openclaw.json
    echo '{"jobs":[]}' > config/$agent/cron/jobs.json
done

# 6. ボットを起動
docker compose -f docker-compose.yml -f docker-compose.multi.yml up -d
```

---

### 詳細設定（手動でJSONを編集する場合）

```bash
git clone --recursive https://github.com/Sunwood-AI-OSS-Hub/OpenClaw-Docker.git
cd OpenClaw-Docker
```

#### 2. Dockerイメージをビルド

#### ローカルビルド

```bash
docker build -t openclaw:local ./openclaw
```

#### GitHub Container Registryからプル

マルチアーキテクチャ対応イメージが公開されています：

```bash
docker pull ghcr.io/sunwood-ai-oss-hub/agentos-openclaw-base:latest
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
openssl rand -hex 32  # Agent 1 用
openssl rand -hex 32  # Agent 2 用
openssl rand -hex 32  # Agent 3 用
```

`.env` を編集：

```bash
# ゲートウェイトークン（3つの異なる値）
OPENCLAW_AGENT1_GATEWAY_TOKEN=生成したトークン1
OPENCLAW_AGENT2_GATEWAY_TOKEN=生成したトークン2
OPENCLAW_AGENT3_GATEWAY_TOKEN=生成したトークン3

# AI APIキー（必要なプロバイダーのみ設定）
ZAI_API_KEY=あなたのGLM_APIキー
OPENROUTER_API_KEY=あなたのOPENROUTER_APIキー

# Discord Botトークン（3つの別々のアカウント）
DISCORD_AGENT1_TOKEN=あなたのDiscordトークン1
DISCORD_AGENT2_TOKEN=あなたのDiscordトークン2
DISCORD_AGENT3_TOKEN=あなたのDiscordトークン3
```

### 4. ボットを設定

各ボットには `config/agent*/` 以下に設定ファイルが必要です：

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

#### `openclaw.json`（全ボット共通）

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
| `docker-compose.yml` | Standard版 - Agent 1 | メインボット（Agent 1）のみのシンプル構成 |
| `docker-compose.multi.yml` | Standard版 - Agent 2&3 | 追加ボット（Agent 2, 3）の構成 |
| `docker-compose.infinity.yml` | Infinity版 - Agent 1 | 開発用機能付きAgent 1（Playwright、gh CLI等） |
| `docker-compose.infinity.multi.yml` | Infinity版 - Agent 2&3 | 開発用機能付きAgent 2, 3 |

#### Standard版（本番運用向け）

```bash
# Agent 1 のみを起動
docker compose up -d

# 全てのエージェントを起動（Agent 1 + Agent 2&3）
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
# Agent 1 のみを起動
docker compose -f docker-compose.infinity.yml up -d --build

# 全てのエージェントを起動（Agent 1 + Agent 2&3）
docker compose -f docker-compose.infinity.yml -f docker-compose.infinity.multi.yml up -d --build

# ログ表示
docker compose -f docker-compose.infinity.yml -f docker-compose.infinity.multi.yml logs -f
```

---

## 設定

### ディレクトリ構造

```
./
├── docker-compose.yml              # Standard版 - Agent 1
├── docker-compose.multi.yml        # Standard版 - Agent 2&3
├── docker-compose.infinity.yml     # Infinity版 - Agent 1
├── docker-compose.infinity.multi.yml  # Infinity版 - Agent 2&3
├── .env
├── .env.example
├── README.md
├── setup.sh                        # 1エージェント用セットアップスクリプト
├── assets/
│   └── header.png
├── docker/
│   └── Dockerfile.infinity         # Infinity版用Dockerfile
├── openclaw/                       # OpenClaw ソース
├── config/
│   ├── examples/                   # ⭐ 設定ファイルのexample
│   │   ├── models.json.example           # ZAI用モデル設定
│   │   ├── models.openrouter.json.example # OpenRouter用
│   │   ├── models.both.json.example       # 両方使用
│   │   ├── openclaw.json.example         # ZAI用ボット設定
│   │   └── openclaw.openrouter.json.example # OpenRouter用
│   ├── agent1/
│   │   ├── openclaw.json
│   │   ├── models.json
│   │   └── cron/
│   │       └── jobs.json
│   ├── agent2/
│   │   ├── openclaw.json
│   │   ├── models.json
│   │   └── cron/
│   │       └── jobs.json
│   ├── agent3/
│   │   ├── openclaw.json
│   │   ├── models.json
│   │   └── cron/
│   │       └── jobs.json
│   └── openclaw.json  # グローバル設定
└── workspace/
    ├── agent1/
    ├── agent2/
    └── agent3/
```

### config/examples/ について

`config/examples/` ディレクトリには、設定ファイルのテンプレートが含まれています。これらをコピーして使用することで、簡単に設定できます。

#### 使用方法

```bash
# ZAI (GLM-4.7) を使用する場合
cp config/examples/models.json.example config/agent1/models.json
cp config/examples/openclaw.json.example config/agent1/openclaw.json

# OpenRouter を使用する場合
cp config/examples/models.openrouter.json.example config/agent2/models.json
cp config/examples/openclaw.openrouter.json.example config/agent2/openclaw.json
```

### ボリュームマウント構成

各ボットコンテナでは以下のボリュームマウントが行われます：

| ホストパス | コンテナパス | 説明 |
|-----------|-------------|------|
| `./config/agent{N}/` | `/home/node/.openclaw/` | ボットの設定ファイル（モデル、チャンネル等） |
| `./workspace/agent{N}/` | `/home/node/.openclaw/workspace/` | ワークスペース（スキル、一時ファイル等） |

**ワークスペースの永続化**: `./workspace/` ディレクトリはコンテナの再起動後もデータを保持するためにホスト側にマウントされます。スキルやエージェントが生成したファイルはここに保存されます。

### 設定オプション

#### openclaw.json

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
# Agent 1 のみを起動
docker compose up -d

# 全てのボットを起動
docker compose -f docker-compose.yml -f docker-compose.multi.yml up -d

# 全てのボットを停止
docker compose -f docker-compose.yml -f docker-compose.multi.yml down

# 全てのボットを再起動
docker compose -f docker-compose.yml -f docker-compose.multi.yml restart

# 特定のボットを再起動
docker compose -f docker-compose.yml -f docker-compose.multi.yml restart openclaw-agent1

# 特定のボットのログを表示
docker compose -f docker-compose.yml -f docker-compose.multi.yml logs -f openclaw-agent1

# 全てのログを表示
docker compose -f docker-compose.yml -f docker-compose.multi.yml logs -f
```

#### Infinity版

```bash
# Agent 1 のみを起動
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
# agent1のCLIにアクセス
docker compose --profile cli run --rm openclaw-cli

# CLI経由でDiscordチャンネルを追加
docker compose --profile cli run --rm openclaw-cli \
    channels add --channel discord --token "${DISCORD_AGENT1_TOKEN}"
```

#### Infinity版

```bash
# agent1のInfinity CLIにアクセス
docker compose -f docker-compose.infinity.yml run --rm openclaw-infinity-cli

# 対話型シェルとして実行
docker compose -f docker-compose.infinity.yml run --rm openclaw-infinity-cli bash
```

### コンテナアクセス

```bash
# コンテナ内でコマンド実行
docker exec -it openclaw-agent1 node dist/index.js config set ...

# 対話型シェル（Standard版）
docker exec -it openclaw-agent1 /bin/bash

# 対話型シェル（Infinity版）
docker exec -it openclaw-infinity-agent1 bash
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

**解決策:** `config/agent*/openclaw.json` を確認：
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
- [GitHub Container Registry](https://github.com/Sunwood-AI-OSS-Hub/OpenClaw-Docker/pkgs/container/agentos-openclaw-base)

---

## ライセンス

このプロジェクトは OpenClaw のセットアップ例です。
詳細については [OpenClaw ライセンス](https://github.com/openclaw/openclaw/blob/main/LICENSE) を参照してください。

---

<div align="center">

Made with ❤️ by [Sunwood AI OSS Hub](https://github.com/Sunwood-AI-OSS-Hub)

</div>
