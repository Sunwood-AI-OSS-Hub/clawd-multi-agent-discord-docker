<div align="center">

![header](assets/header-a.png)

# OpenClaw-Docker

[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com/)
[![Discord](https://img.shields.io/badge/Discord-API%20v10-5865F2.svg)](https://discord.com/developers/docs)
[![GLM-4.7](https://img.shields.io/badge/AI-GLM--4.7-FF6B6B.svg)](https://open.bigmodel.cn/)
[![OpenRouter](https://img.shields.io/badge/AI-OpenRouter-878787.svg)](https://openrouter.ai/)
[![OpenClaw](https://img.shields.io/badge/Bot-OpenClaw-7C3AED.svg)](https://openclaw.ai)

<a href="README.md"><img src="https://img.shields.io/badge/%E6%96%87%E6%9B%B8-%E6%97%A5%E6%9C%AC%E8%AA%9E-white.svg" alt="JA doc"/></a>

**A complete setup for running 3 independent AI Discord bots** with Docker Compose

Each bot runs with its own independent gateway process while sharing GLM-4.7 / OpenRouter API keys.

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

This project runs **3 independent Discord bots** using **OpenClaw** with Docker Compose. Each bot operates with its own gateway process and container, sharing the GLM-4.7 AI model.

### Features

- **3 Independent Bots**: Each bot runs as a separate process
- **Multiple AI Providers**: Supports GLM-4.7 / OpenRouter
- **Split Docker Compose Configuration**: Flexible deployment with Standard and Infinity versions
- **Isolated Workspaces**: Dedicated workspace for each bot
- **Easy Configuration**: JSON-based configuration management

---

## Architecture

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
│                   │  (Shared)   │                             │
│                   └───────────┘                             │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
                   ┌───────────────┐
                   │  Discord API   │
                   │  (Each bot has │
                   │ own session)   │
                   └───────────────┘
```

---

## Bot Configuration

| Bot Name | Port | Description |
|----------|------|-------------|
| CL1-Kuroha | 18789 | Agent 1 - Main Agent |
| CL2-Reika  | 18791 | Agent 2 - Support Agent |
| CL3-Sentinel | 18793 | Agent 3 - Monitor Agent |

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose v2](https://docs.docker.com/compose/install/)
- [Zhipu AI GLM-4.7](https://open.bigmodel.cn/) API Key or [OpenRouter](https://openrouter.ai/) API Key (or both)
- 3 [Discord Bot Tokens](https://discord.com/developers/applications)

### AI Providers

This project supports the following AI providers:

| Provider | Models | Environment Variable | Features |
|----------|--------|---------------------|----------|
| **Zhipu AI (GLM)** | GLM-4.7 | `ZAI_API_KEY` | High-performance Chinese/Japanese model |
| **OpenRouter** | Multiple models | `OPENROUTER_API_KEY` | Access to Claude, GPT-4, and many more |

You can configure both API keys and switch between them as needed.

### Discord Bot Required Intents

- Message Content Intent
- Server Members Intent
- Presence Intent

---

## Quick Start

### 1. Clone Repository

```bash
git clone --recursive https://github.com/Sunwood-AI-OSS-Hub/OpenClaw-Docker.git
cd OpenClaw-Docker
```

### 2. Build Docker Image

#### Local Build

```bash
docker build -t openclaw:local ./openclaw
```

#### Pull from GitHub Container Registry

Multi-architecture images are available:

```bash
docker pull ghcr.io/sunwood-ai-oss-hub/agentos-openclaw-base:latest
```

**Supported Platforms:**

| Platform | Use Case |
|----------|----------|
| linux/amd64 | Standard PC/Server |
| linux/arm64 | Jetson, Raspberry Pi, Mac (Apple Silicon) |

### 3. Configure Environment

Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

Generate gateway tokens (3 separate tokens):

```bash
openssl rand -hex 32  # Agent 1
openssl rand -hex 32  # Agent 2
openssl rand -hex 32  # Agent 3
```

Edit `.env`:

```bash
# Gateway tokens (3 unique values)
OPENCLAW_AGENT1_GATEWAY_TOKEN=your_token_1
OPENCLAW_AGENT2_GATEWAY_TOKEN=your_token_2
OPENCLAW_AGENT3_GATEWAY_TOKEN=your_token_3

# AI API Keys (configure only the providers you need)
ZAI_API_KEY=your_glm_api_key
OPENROUTER_API_KEY=your_openrouter_api_key

# Discord Bot Tokens (3 separate accounts)
DISCORD_AGENT1_TOKEN=your_discord_token_1
DISCORD_AGENT2_TOKEN=your_discord_token_2
DISCORD_AGENT3_TOKEN=your_discord_token_3
```

### 4. Configure Bots

Each bot requires configuration files in `config/agent*/`:

#### `models.json` (same for all bots)

**For Zhipu AI (GLM):**

```json
{
  "mode": "append",
  "providers": {
    "zai": {
      "baseUrl": "https://api.zai.ai/v1/",
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

**For OpenRouter:**

```json
{
  "mode": "append",
  "providers": {
    "openrouter": {
      "baseUrl": "https://openrouter.ai/api/v1/",
      "apiKey": "your_openrouter_api_key",
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

**For Both Providers:**

```json
{
  "mode": "append",
  "providers": {
    "zai": {
      "baseUrl": "https://api.zai.ai/v1/",
      "apiKey": "your_glm_api_key",
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
      "apiKey": "your_openrouter_api_key",
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

#### `openclaw.json` (same for all bots)

**For GLM-4.7:**

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

**For OpenRouter (Claude):**

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

### 5. Automated Setup Script

Use the `setup.sh` script to easily set up each agent:

```bash
# Make script executable
chmod +x setup.sh

# Setup Agent 1 (interactive mode)
./setup.sh

# Setup Agent 2 (interactive mode)
./setup.sh 2

# Setup Agent 3 (non-interactive mode)
./setup.sh 3 -y
```

**Script features:**
- Automatic `.env` file creation
- Gateway token generation
- Config directory and workspace initialization
- OpenClaw bootstrap files creation (AGENTS.md, SOUL.md, etc.)
- Automatic GitHub private repository creation and push (when gh command is available)
- Discord channel automatic addition

**Options:**
| Option | Description |
|--------|-------------|
| `-y, --yes` | Non-interactive mode (auto-confirm all prompts) |
| `-h, --help` | Show help message |

**Examples:**
```bash
# Show help
./setup.sh -h

# Setup Agent 2 in non-interactive mode
./setup.sh 2 -y
```

### 6. Start Bots

Docker Compose configurations are split into 4 files for different use cases:

#### Configuration Files

| File | Purpose | Description |
|------|---------|-------------|
| `docker-compose.yml` | Standard - Agent 1 | Simple configuration for main bot (Agent 1) only |
| `docker-compose.multi.yml` | Standard - Agent 2&3 | Additional bots (Agent 2, 3) configuration |
| `docker-compose.infinity.yml` | Infinity - Agent 1 | Development-enabled Agent 1 (Playwright, gh CLI, etc.) |
| `docker-compose.infinity.multi.yml` | Infinity - Agent 2&3 | Development-enabled Agent 2, 3 |

#### Standard Version (Production)

```bash
# Start Agent 1 only
docker compose up -d

# Start all agents (Agent 1 + Agent 2&3)
docker compose -f docker-compose.yml -f docker-compose.multi.yml up -d

# Check status
docker compose -f docker-compose.yml -f docker-compose.multi.yml ps

# View logs
docker compose -f docker-compose.yml -f docker-compose.multi.yml logs -f
```

#### Infinity Version (Development)

The Infinity version includes additional features:
- **Playwright** - Browser automation
- **GitHub CLI (gh)** - GitHub operations
- **Non-root user** - Enhanced security

```bash
# Start Agent 1 only
docker compose -f docker-compose.infinity.yml up -d --build

# Start all agents (Agent 1 + Agent 2&3)
docker compose -f docker-compose.infinity.yml -f docker-compose.infinity.multi.yml up -d --build

# View logs
docker compose -f docker-compose.infinity.yml -f docker-compose.infinity.multi.yml logs -f
```

---

## Configuration

### Directory Structure

```
./
├── docker-compose.yml              # Standard - Agent 1
├── docker-compose.multi.yml        # Standard - Agent 2&3
├── docker-compose.infinity.yml     # Infinity - Agent 1
├── docker-compose.infinity.multi.yml  # Infinity - Agent 2&3
├── .env
├── .env.example
├── README.md
├── setup.sh                        # Single-agent setup script
├── assets/
│   └── header.png
├── docker/
│   └── Dockerfile.infinity         # Infinity version Dockerfile
├── openclaw/                       # OpenClaw source
├── config/
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
│   └── openclaw.json  # Global config
└── workspace/
    ├── agent1/
    ├── agent2/
    └── agent3/
```

### Volume Mount Configuration

Each bot container uses the following volume mounts:

| Host Path | Container Path | Description |
|-----------|----------------|-------------|
| `./config/agent{N}/` | `/home/node/.openclaw/` | Bot configuration files (models, channels, etc.) |
| `./workspace/agent{N}/` | `/home/node/.openclaw/workspace/` | Workspace (skills, temporary files, etc.) |

**Workspace Persistence**: The `./workspace/` directory is mounted to the host to persist data across container restarts. Files created by skills and agents are stored here.

### Configuration Options

#### openclaw.json

| Option | Value | Description |
|--------|-------|-------------|
| `agents.defaults.model.primary` | `zai/glm-4.7` or `openrouter/...` | Primary AI model |
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
| `providers.zai.baseUrl` | ZAI API endpoint | Zhipu AI API URL |
| `providers.zai.api` | `openai-completions` | OpenAI compatibility mode |
| `providers.openrouter.baseUrl` | OpenRouter API endpoint | OpenRouter API URL |
| `providers.openrouter.api` | `openai-completions` | OpenAI compatibility mode |

---

## Commands

### Bot Operations

#### Standard Version

```bash
# Start Agent 1 only
docker compose up -d

# Start all bots
docker compose -f docker-compose.yml -f docker-compose.multi.yml up -d

# Stop all bots
docker compose -f docker-compose.yml -f docker-compose.multi.yml down

# Restart all bots
docker compose -f docker-compose.yml -f docker-compose.multi.yml restart

# Restart specific bot
docker compose -f docker-compose.yml -f docker-compose.multi.yml restart openclaw-agent1

# View logs for specific bot
docker compose -f docker-compose.yml -f docker-compose.multi.yml logs -f openclaw-agent1

# View all logs
docker compose -f docker-compose.yml -f docker-compose.multi.yml logs -f
```

#### Infinity Version

```bash
# Start Agent 1 only
docker compose -f docker-compose.infinity.yml up -d --build

# Start all bots
docker compose -f docker-compose.infinity.yml -f docker-compose.infinity.multi.yml up -d --build

# Stop all bots
docker compose -f docker-compose.infinity.yml -f docker-compose.infinity.multi.yml down

# View logs
docker compose -f docker-compose.infinity.yml -f docker-compose.infinity.multi.yml logs -f
```

### CLI Access

#### Standard Version

```bash
# Access CLI for agent1
docker compose --profile cli run --rm openclaw-cli

# Add Discord channel via CLI
docker compose --profile cli run --rm openclaw-cli \
    channels add --channel discord --token "${DISCORD_AGENT1_TOKEN}"
```

#### Infinity Version

```bash
# Access Infinity CLI for agent1
docker compose -f docker-compose.infinity.yml run --rm openclaw-infinity-cli

# Run as interactive shell
docker compose -f docker-compose.infinity.yml run --rm openclaw-infinity-cli bash
```

### Container Access

```bash
# Execute command in container
docker exec -it openclaw-agent1 node dist/index.js config set ...

# Interactive shell (Standard version)
docker exec -it openclaw-agent1 /bin/bash

# Interactive shell (Infinity version)
docker exec -it openclaw-infinity-agent1 bash
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

**Solution:** Check `config/agent*/openclaw.json`:
```json
{
  "messages": {
    "ackReactionScope": "all"
  }
}
```

---

## References

- [OpenClaw Documentation](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Zhipu AI GLM API](https://open.bigmodel.cn/)
- [OpenRouter Documentation](https://openrouter.ai/docs)
- [Discord Developer Portal](https://discord.com/developers/applications)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Container Registry](https://github.com/Sunwood-AI-OSS-Hub/OpenClaw-Docker/pkgs/container/agentos-openclaw-base)

---

## License

This project is a setup example for OpenClaw.
Please refer to the [OpenClaw License](https://github.com/openclaw/openclaw/blob/main/LICENSE) for details.

---

<div align="center">

Made with ❤️ by [Sunwood AI OSS Hub](https://github.com/Sunwood-AI-OSS-Hub)

</div>
