#!/bin/bash
set -euo pipefail

# =============================================================================
# Deploy Script - Pull latest Docker image and restart containers
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "==> Pulling latest Docker image..."
docker compose pull

echo "==> Recreating containers with new image..."
docker compose up -d --force-recreate

echo "==> Pruning old images..."
docker image prune -f

echo "==> Deploy complete!"
echo ""
echo "Running containers:"
docker compose ps
