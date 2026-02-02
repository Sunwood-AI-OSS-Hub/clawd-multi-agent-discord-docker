#!/bin/bash
# OpenClaw 3-Bot Setup Script
# This script helps you set up 3 Discord bots using OpenClaw with GLM-4.7

set -e

echo "======================================"
echo "OpenClaw 3-Bot Setup"
echo "======================================"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo ""
    echo "❗ Please edit .env file with your values:"
    echo "   - GLM_API_KEY: Your GLM-4.7 API key"
    echo "   - DISCORD_AGENT1_TOKEN, DISCORD_BOT2_TOKEN, DISCORD_BOT3_TOKEN: Discord bot tokens"
    echo "   - Generate gateway tokens with: openssl rand -hex 32"
    echo ""
    read -p "Press Enter after editing .env file..."
fi

# Source the .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ .env file not found!"
    exit 1
fi

# Check required values
if [ -z "$GLM_API_KEY" ]; then
    echo "❌ GLM_API_KEY is not set in .env"
    exit 1
fi

# Function to setup a bot
setup_bot() {
    local BOT_NUM=$1
    local BOT_NAME="bot$BOT_NUM"
    local DISCORD_TOKEN_VAR="DISCORD_BOT${BOT_NUM}_TOKEN"
    local GATEWAY_TOKEN_VAR="OPENCLAW_BOT${BOT_NUM}_GATEWAY_TOKEN"
    local DISCORD_TOKEN=${!DISCORD_TOKEN_VAR}
    local GATEWAY_TOKEN=${!GATEWAY_TOKEN_VAR}

    echo ""
    echo "======================================"
    echo "Setting up $BOT_NAME"
    echo "======================================"

    # Generate gateway token if not set
    if [ -z "$GATEWAY_TOKEN" ]; then
        echo "Generating gateway token for $BOT_NAME..."
        GATEWAY_TOKEN=$(openssl rand -hex 32)
        echo "Generated GATEWAY_TOKEN: $GATEWAY_TOKEN"
        read -p "Add this to .env as ${GATEWAY_TOKEN_VAR}? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sed -i "s/^${GATEWAY_TOKEN_VAR}=.*/${GATEWAY_TOKEN_VAR}=${GATEWAY_TOKEN}/" .env
        fi
    fi

    # Check Discord token
    if [ -z "$DISCORD_TOKEN" ]; then
        echo "❌ ${DISCORD_TOKEN_VAR} is not set in .env"
        echo "Get your bot token from: https://discord.com/developers/applications"
        exit 1
    fi

    # Setup Discord channel
    echo "Adding Discord channel to $BOT_NAME..."
    if [ "$BOT_NUM" = "1" ]; then
        docker compose --profile cli run --rm openclaw-cli \
            channels add --channel discord --token "$DISCORD_TOKEN"
    else
        # For bot2 and bot3, use the main CLI with custom config directory
        docker compose --profile cli run --rm \
            -v ./config/bot${BOT_NUM}:/home/node/.openclaw \
            openclaw-cli \
            channels add --channel discord --token "$DISCORD_TOKEN"
    fi

    echo "✅ $BOT_NAME setup complete!"
}

# Ask which bot to setup
echo ""
echo "Which bot(s) do you want to setup?"
echo "1) Agent 1"
echo "2) Bot 2"
echo "3) Bot 3"
echo "4) All bots"
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        setup_bot 1
        ;;
    2)
        setup_bot 2
        ;;
    3)
        setup_bot 3
        ;;
    4)
        setup_bot 1
        setup_bot 2
        setup_bot 3
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "======================================"
echo "Setup complete!"
echo "======================================"
echo ""
echo "Start the bots with:"
echo "  docker compose up -d"
echo ""
echo "Or start individual bots:"
echo "  docker compose up -d openclaw-agent1"
echo "  docker compose up -d openclaw-bot2"
echo "  docker compose up -d openclaw-bot3"
echo ""
echo "Access Control UI:"
echo "  Agent 1: http://localhost:18789/"
echo "  Bot 2: http://localhost:18791/"
echo "  Bot 3: http://localhost:18793/"
