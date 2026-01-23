<div align="center">

![header](assets/header.svg)

# clawd-multi-agent-discord-docker

[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com/)
[![Discord](https://img.shields.io/badge/Discord-API%20v10-5865F2.svg)](https://discord.com/developers/docs)
[![GLM-4.7](https://img.shields.io/badge/AI-GLM--4.7-FF6B6B.svg)](https://open.bigmodel.cn/)
[![Clawdbot](https://img.shields.io/badge/Bot-Clawdbot-7C3AED.svg)](https://docs.clawd.bot)

**3つの独立したAI Discordボット**をDocker Composeで運用するための完全セットアップ

1つのGLM-4.7 APIキーを共有しつつ、各ボットは独立したゲートウェイプロセスで動作します。

</div>

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Bot Configuration](#bot-configuration)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Commands](#commands)
- [Troubleshooting](#troubleshooting)
- [References](#references)
- [License](#license)

---

## Overview

このプロジェクトでは、**Clawdbot**を使用して3つの独立したDiscordボットをDocker Composeで運用します。各ボットは独自のゲートウェイプロセスとコンテナで動作し、GLM-4.7 AIモデルを共有します。

### Features

- **3 Independent Bots**: 各ボットが独立したプロセスで動作
- **Shared AI Model**: GLM-4.7 APIキーを共有
- **Docker Compose**: ワンコマンドで起動・管理
- **Isolated Workspaces**: 各ボット専用のワークスペース
- **Easy Configuration**: JSONベースの設定管理

---

## Architecture

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

## Bot Configuration

| ボット名 | ポート | 説明 |
|---------|--------|------|
| CL1-Kuroha | 18789 | Bot 1 - Main Agent |
| CL2-Reika  | 18791 | Bot 2 - Support Agent |
| CL3-Sentinel | 18793 | Bot 3 - Monitor Agent |

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) と [Docker Compose v2](https://docs.docker.com/compose/install/)
- [Zhipu AI GLM-4.7](https://open.bigmodel.cn/) API Key
- 3つの [Discord Bot Tokens](https://discord.com/developers/applications)

### Discord Bot Required Intents

- Message Content Intent
- Server Members Intent
- Presence Intent

---

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/Sunwood-AI-OSS-Hub/clawd-multi-agent-discord-docker.git
cd clawd-multi-agent-discord-docker
```

### 2. Build Docker Image

```bash
docker build -t clawdbot:local ./clawdbot
```

### 3. Configure Environment

Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

Generate gateway tokens (3 separate tokens):

```bash
openssl rand -hex 32  # Bot 1
openssl rand -hex 32  # Bot 2
openssl rand -hex 32  # Bot 3
```

Edit `.env`:

```bash
# Gateway tokens (3 unique values)
CLAWDBOT_BOT1_GATEWAY_TOKEN=your_token_1
CLAWDBOT_BOT2_GATEWAY_TOKEN=your_token_2
CLAWDBOT_BOT3_GATEWAY_TOKEN=your_token_3

# GLM 4.7 API Key (shared)
GLM_API_KEY=your_glm_api_key

# Discord Bot Tokens (3 separate accounts)
DISCORD_BOT1_TOKEN=your_discord_token_1
DISCORD_BOT2_TOKEN=your_discord_token_2
DISCORD_BOT3_TOKEN=your_discord_token_3
```

### 4. Configure Bots

Each bot requires configuration files in `config/bot*/`:

#### `models.json` (same for all bots)

```json
{
  "mode": "append",
  "providers": {
    "glm": {
      "baseUrl": "https://open.bigmodel.cn/api/paas/v4/",
      "apiKey": "your_glm_api_key",
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

#### `clawdbot.json` (same for all bots)

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "glm/glm-4.7"
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

### 5. Start Bots

```bash
# Start all bots
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

---

## Configuration

### Directory Structure

```
./
├── docker-compose.yml
├── .env
├── .env.example
├── README.md
├── setup.sh
├── assets/
│   └── header.svg
├── clawdbot/          # Clawdbot source
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
│   └── clawdbot.json  # Global config
└── workspace/
    ├── bot1/
    ├── bot2/
    └── bot3/
```

### Configuration Options

#### clawdbot.json

| Option | Value | Description |
|--------|-------|-------------|
| `agents.defaults.model.primary` | `glm/glm-4.7` | Primary AI model |
| `channels.discord.enabled` | `true` | Enable Discord |
| `channels.discord.groupPolicy` | `open` | Response policy (`open`/`allowlist`) |
| `messages.ackReactionScope` | `all` | Reaction scope (`all`/`group-mentions`) |

**groupPolicy:**
- `open`: Respond in all channels
- `allowlist`: Respond only in allowed channels

**ackReactionScope:**
- `all`: React to all messages
- `group-mentions`: React only to mentions

#### models.json

| Option | Value | Description |
|--------|-------|-------------|
| `mode` | `append` | Append to existing providers |
| `providers.glm.baseUrl` | GLM API endpoint | Zhipu AI API URL |
| `providers.glm.api` | `openai-completions` | OpenAI compatibility mode |

---

## Commands

### Bot Operations

```bash
# Start all bots
docker compose up -d

# Stop all bots
docker compose down

# Restart all bots
docker compose restart

# Restart specific bot
docker compose restart clawdbot-bot1

# View logs for specific bot
docker compose logs -f clawdbot-bot1

# View all logs
docker compose logs -f
```

### CLI Access

```bash
# Access CLI for bot1
docker compose --profile cli run --rm clawdbot-cli

# Add Discord channel via CLI
docker compose --profile cli run --rm clawdbot-cli \
    channels add --channel discord --token "${DISCORD_BOT1_TOKEN}"
```

### Container Access

```bash
# Execute command in container
docker exec -it clawdbot-bot1 node dist/index.js config set ...

# Interactive shell
docker exec -it clawdbot-bot1 /bin/bash
```

---

## Troubleshooting

### "Unknown model: glm/glm-4.7" Error

**Cause:** `models.json` not configured correctly or invalid API key

**Solutions:**
1. Verify `apiKey` in `models.json`
2. Check GLM API key is valid
3. Test GLM API access

### Bot Shows as Offline

**Cause:** Invalid Discord token or missing intents

**Solutions:**
1. Verify Discord token in `.env`
2. Enable **Message Content Intent** in Discord Developer Portal
3. Ensure bot is invited to server

### "gateway already running" Error

**Cause:** Old process still running

**Solution:**
```bash
docker compose down
docker compose up -d
```

### Port Conflicts

**Cause:** Ports 18789, 18791, 18793 already in use

**Solution:**
```bash
# Find process using port
sudo lsof -i :18789

# Kill process
sudo kill -9 <PID>
```

### Reactions Not Working

**Cause:** `ackReactionScope` configuration

**Solution:** Check `config/bot*/clawdbot.json`:
```json
{
  "messages": {
    "ackReactionScope": "all"
  }
}
```

---

## References

- [Clawdbot Documentation](https://docs.clawd.bot)
- [Clawdbot GitHub](https://github.com/clawdbot/clawdbot)
- [Zhipu AI GLM API](https://open.bigmodel.cn/)
- [Discord Developer Portal](https://discord.com/developers/applications)
- [Docker Documentation](https://docs.docker.com/)

---

## License

This project is a setup example for Clawdbot.
Please refer to the [Clawdbot License](https://github.com/clawdbot/clawdbot/blob/main/LICENSE) for details.

---

<div align="center">

Made with ❤️ by [Sunwood AI OSS Hub](https://github.com/Sunwood-AI-OSS-Hub)

</div>
