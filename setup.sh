#!/bin/bash
# OpenClaw Agent Setup Script
# This script helps you set up a single Discord bot using OpenClaw with GLM-4.7

set -e

# Parse arguments
AGENT_NUM=1
AUTO_YES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        [1-9]|[1-9][0-9])
            AGENT_NUM=$1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [agent_number] [options]"
            echo ""
            echo "Arguments:"
            echo "  agent_number    Agent number (1-3, default: 1)"
            echo ""
            echo "Options:"
            echo "  -y, --yes       Auto-confirm all prompts (non-interactive mode)"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0              # Setup Agent 1 interactively"
            echo "  $0 2            # Setup Agent 2 interactively"
            echo "  $0 3 -y         # Setup Agent 3 non-interactively"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use -h or --help for usage"
            exit 1
            ;;
    esac
done

# Validate agent number
if [ "$AGENT_NUM" -lt 1 ] || [ "$AGENT_NUM" -gt 3 ]; then
    echo "❌ Invalid agent number: $AGENT_NUM"
    echo "Agent number must be between 1 and 3"
    exit 1
fi

# Set variables based on agent number
if [ "$AGENT_NUM" = "1" ]; then
    AGENT_NAME="agent1"
    DISCORD_TOKEN_VAR="DISCORD_AGENT1_TOKEN"
    GATEWAY_TOKEN_VAR="OPENCLAW_AGENT1_GATEWAY_TOKEN"
    GATEWAY_PORT="18789"
elif [ "$AGENT_NUM" = "2" ]; then
    AGENT_NAME="agent2"
    DISCORD_TOKEN_VAR="DISCORD_AGENT2_TOKEN"
    GATEWAY_TOKEN_VAR="OPENCLAW_AGENT2_GATEWAY_TOKEN"
    GATEWAY_PORT="18791"
elif [ "$AGENT_NUM" = "3" ]; then
    AGENT_NAME="agent3"
    DISCORD_TOKEN_VAR="DISCORD_AGENT3_TOKEN"
    GATEWAY_TOKEN_VAR="OPENCLAW_AGENT3_GATEWAY_TOKEN"
    GATEWAY_PORT="18793"
fi

echo "======================================"
echo "OpenClaw Agent Setup - Agent $AGENT_NUM"
echo "======================================"
echo ""

# Function to prompt or auto-confirm
prompt_or_auto() {
    local prompt_text="$1"
    if [ "$AUTO_YES" = true ]; then
        return 0
    else
        read -p "$prompt_text" -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo ""
    echo "❗ Please edit .env file with your values:"
    echo "   - ZAI_API_KEY: Your GLM-4.7 API key"
    echo "   - ${DISCORD_TOKEN_VAR}: Discord bot token"
    echo "   - ${GATEWAY_TOKEN_VAR}: Gateway token (generate with: openssl rand -hex 32)"
    echo ""

    if ! prompt_or_auto "Press Enter after editing .env file..."; then
        echo "❌ Setup cancelled. Please edit .env file and run again."
        exit 1
    fi
fi

# Source the .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ .env file not found!"
    exit 1
fi

# Get token values
DISCORD_TOKEN=${!DISCORD_TOKEN_VAR}
GATEWAY_TOKEN=${!GATEWAY_TOKEN_VAR}

# Check required values
if [ -z "$ZAI_API_KEY" ] && [ -z "$OPENROUTER_API_KEY" ]; then
    echo "❌ ZAI_API_KEY or OPENROUTER_API_KEY is not set in .env"
    exit 1
fi

# Generate gateway token if not set
if [ -z "$GATEWAY_TOKEN" ]; then
    echo "Generating gateway token for $AGENT_NAME..."
    GATEWAY_TOKEN=$(openssl rand -hex 32)
    echo "✅ Generated ${GATEWAY_TOKEN_VAR}: $GATEWAY_TOKEN"

    if prompt_or_auto "Add this to .env as ${GATEWAY_TOKEN_VAR}? (y/n) "; then
        sed -i "s/^${GATEWAY_TOKEN_VAR}=.*/${GATEWAY_TOKEN_VAR}=${GATEWAY_TOKEN}/" .env
        echo "✅ Added to .env"
    else
        echo "⚠️  Token not added to .env. Please add it manually."
    fi
fi

# Check Discord token
if [ -z "$DISCORD_TOKEN" ]; then
    echo "❌ ${DISCORD_TOKEN_VAR} is not set in .env"
    echo "Get your bot token from: https://discord.com/developers/applications"
    exit 1
fi

# Create config directory
CONFIG_DIR="./config/${AGENT_NAME}"
WORKSPACE_DIR="./workspace/${AGENT_NAME}"

echo ""
echo "Creating directories: $CONFIG_DIR and $WORKSPACE_DIR"
mkdir -p "$CONFIG_DIR/cron"
mkdir -p "$WORKSPACE_DIR"

# Make workspace writable (Docker runs as uid 1000)
chmod 777 "$WORKSPACE_DIR"

# Copy example configuration files
echo ""
echo "Copying configuration files..."

if [ -z "$OPENROUTER_API_KEY" ] && [ -n "$ZAI_API_KEY" ]; then
    # ZAI only
    cp config/examples/models.json.example "$CONFIG_DIR/models.json"
    cp config/examples/openclaw.json.example "$CONFIG_DIR/openclaw.json"
elif [ -n "$OPENROUTER_API_KEY" ]; then
    # OpenRouter or both
    cp config/examples/models.openrouter.json.example "$CONFIG_DIR/models.json"
    cp config/examples/openclaw.openrouter.json.example "$CONFIG_DIR/openclaw.json"
fi

# Create jobs.json for cron
echo '{"jobs":[]}' > "$CONFIG_DIR/cron/jobs.json"

echo "✅ Configuration files copied to $CONFIG_DIR"

# Initialize workspace files directly (without onboard which requires running gateway)
echo ""
echo "Initializing workspace files for $AGENT_NAME..."

# Check if workspace is already initialized
if [ -f "$WORKSPACE_DIR/AGENTS.md" ]; then
    echo "✅ Workspace files already exist, skipping creation..."
else
    echo "Creating workspace files..."

# Create AGENTS.md (required by OpenClaw)
cat > "$WORKSPACE_DIR/AGENTS.md" << 'EOF'
# OpenClaw Workspace

This workspace is managed by OpenClaw.

## Core Principles

- Treat the workspace as the agent's memory
- Keep files organized and up-to-date
- Use memory/ for daily logs
- Update this file as the agent evolves

## How to Use Memory

1. Create daily memory files in `memory/YYYY-MM-DD.md`
2. Reference important information in MEMORY.md
3. Keep AGENTS.md updated with current instructions
EOF

# Create SOUL.md (persona and tone)
cat > "$WORKSPACE_DIR/SOUL.md" << 'EOF'
# Soul

## Personality

You are a helpful AI assistant.

## Tone

- Friendly and approachable
- Professional but warm
- Clear and concise

## Boundaries

- Respect user privacy
- Ask for clarification when needed
- Admit when you don't know something
EOF

# Create USER.md (user information)
cat > "$WORKSPACE_DIR/USER.md" << 'EOF'
# User

## Who You Are

This is your user profile. Update this with information about yourself.

## Preferences

- Communication style: [Your preference]
- Topics of interest: [Your interests]
- Working hours: [Your schedule]

## Notes

Add any other relevant information about how you like to work.
EOF

# Create IDENTITY.md (agent identity)
cat > "$WORKSPACE_DIR/IDENTITY.md" << 'EOF'
# Identity

## Name

OpenClaw Agent

## Vibe

Helpful, capable, and ready to assist.

## Emoji

🦞

## Role

I am an AI agent powered by OpenClaw, here to help you with tasks, answer questions, and make your work easier.
EOF

# Create TOOLS.md (tools documentation)
cat > "$WORKSPACE_DIR/TOOLS.md" << 'EOF'
# Tools

## Available Tools

This workspace has access to various tools for file operations, code execution, and more.

## Tool Conventions

- Always confirm before making destructive changes
- Use clear, descriptive file names
- Keep code well-documented
- Test changes before committing

## Notes

Add tool-specific notes here as needed.
EOF

# Create HEARTBEAT.md (heartbeat checklist)
cat > "$WORKSPACE_DIR/HEARTBEAT.md" << 'EOF'
# Heartbeat Checklist

## Daily Checks

- [ ] Review recent memory files
- [ ] Check for pending tasks
- [ ] Update workspace as needed

## Weekly Reviews

- [ ] Archive old memory files
- [ ] Update AGENTS.md if needed
- [ ] Review and clean up workspace

## Notes

Keep this checklist short to avoid token burn.
EOF

# Create BOOTSTRAP.md (first-run ritual)
cat > "$WORKSPACE_DIR/BOOTSTRAP.md" << 'EOF'
# Bootstrap Ritual

## First-Time Setup

Welcome to your new OpenClaw workspace! This file will guide you through the initial setup.

## Steps

1. ✅ Workspace initialized
2. ✅ Bootstrap files created
3. ⬜ Review AGENTS.md and update as needed
4. ⬜ Customize SOUL.md to match your personality
5. ⬜ Update USER.md with your information
6. ⬜ Review TOOLS.md and add tool-specific notes
7. ⬜ Delete this file (BOOTSTRAP.md) once setup is complete

## Next Steps

- Start using the agent
- Create daily memory files in memory/
- Update workspace as you learn what works best

## Questions?

Refer to OpenClaw documentation: https://docs.openclaw.ai/
EOF

    # Create workspace subdirectories
    mkdir -p "$WORKSPACE_DIR/memory"
    mkdir -p "$WORKSPACE_DIR/media"
    mkdir -p "$WORKSPACE_DIR/skills"
    mkdir -p "$WORKSPACE_DIR/tmp"
    mkdir -p "$WORKSPACE_DIR/canvas"
    
    echo "✅ Workspace files created"
fi

# Initialize git repo (if not already initialized)
if [ ! -d "$WORKSPACE_DIR/.git" ]; then
    echo ""
    echo "Initializing git repository in $WORKSPACE_DIR..."
    cd "$WORKSPACE_DIR"
    git init -q
    git add AGENTS.md SOUL.md USER.md IDENTITY.md TOOLS.md HEARTBEAT.md BOOTSTRAP.md
    git add memory/ canvas/ skills/ media/
    git commit -q -m "Initial OpenClaw workspace setup"

    # Create GitHub private repo and push (if gh is available)
    if command -v gh &> /dev/null; then
        # Check if gh is authenticated
        if gh auth status &> /dev/null; then
            REPO_NAME="openclaw-${AGENT_NAME}-workspace"

            echo "Creating GitHub private repository: $REPO_NAME..."

            # Create private repo and push (capture exit status before piping)
            GH_OUTPUT=$(gh repo create "$REPO_NAME" --private --source=. --remote=origin --push 2>&1)
            GH_EXIT_CODE=$?
            echo "$GH_OUTPUT" | grep -v "^Deploying"
            
            if [ $GH_EXIT_CODE -eq 0 ]; then
                echo "✅ GitHub repository created and pushed: $REPO_NAME"
                REPO_URL=$(gh repo view --json url -q .url 2>/dev/null || echo "")
                if [ -n "$REPO_URL" ]; then
                    echo "   Repository URL: $REPO_URL"
                fi
            else
                echo "⚠️  GitHub repository creation failed. Creating template remote config..."
                # Use git config commands to set remote instead of overwriting entire config
                git remote add origin "https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git" 2>/dev/null || \
                git remote set-url origin "https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git"
                echo "   Template remote added to git config"
                echo "   Please update the remote URL with:"
                echo "   cd $WORKSPACE_DIR && git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git"
                echo "   Then push: git push -u origin main"
            fi
        else
            echo "⚠️  GitHub CLI (gh) is not authenticated. Skipping remote setup."
            echo "   To authenticate: gh auth login"
            echo "   To add remote manually: git remote add origin <your-private-repo-url>"
            echo "   To push: git push -u origin main"
        fi
    else
        echo "⚠️  GitHub CLI (gh) is not installed. Skipping remote setup."
        echo "   To install: https://cli.github.com/"
        echo "   To add remote manually: git remote add origin <your-private-repo-url>"
        echo "   To push: git push -u origin main"
    fi

    cd - > /dev/null
else
    echo ""
    echo "✅ Git repository already exists at $WORKSPACE_DIR/.git, using existing repository"
fi

# Create today's memory file
TODAY=$(date +%Y-%m-%d)
MEMORY_FILE="$WORKSPACE_DIR/memory/$TODAY.md"

if [ ! -f "$MEMORY_FILE" ]; then
    cat > "$MEMORY_FILE" << EOF
# Memory Log - $TODAY

## Setup

- Workspace initialized for OpenClaw Agent
- Bootstrap files created
- Ready to begin!

## Notes

Add your daily notes here.
EOF
    echo "✅ Created today's memory file: $TODAY.md"
else
    echo "✅ Today's memory file already exists: $TODAY.md"
fi

echo "✅ Workspace initialized at $WORKSPACE_DIR"

# Setup Discord channel
echo ""
echo "Setting up Discord channel for $AGENT_NAME..."
docker compose --profile cli run --rm \
    -e OPENCLAW_GATEWAY_TOKEN=${GATEWAY_TOKEN} \
    -v "$CONFIG_DIR:/home/node/.openclaw" \
    -v "./workspace/${AGENT_NAME}:/home/node/.openclaw/workspace" \
    openclaw-cli \
    channels add --channel discord --token "$DISCORD_TOKEN"

echo ""
echo "======================================"
echo "Setup complete!"
echo "======================================"
echo ""
echo "Start the agent with:"
if [ "$AGENT_NUM" = "1" ]; then
    echo "  docker compose up -d"
else
    echo "  docker compose -f docker-compose.multi.yml up -d"
fi
echo ""
echo "Access Control UI:"
echo "  http://localhost:${GATEWAY_PORT}/"
echo ""
