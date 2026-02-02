#!/bin/bash
set -e

echo "=========================================="
echo "Cinderella Browser API"
echo "=========================================="

# Remove X lock if exists
rm -f /tmp/.X99-lock

# Start Xvfb in background
echo "Starting Xvfb on display :99..."
Xvfb :99 -screen 0 1920x1080x24 -ac &
sleep 3

# Start fluxbox window manager
echo "Starting fluxbox..."
DISPLAY=:99 fluxbox &
sleep 2

# Start x11vnc for remote viewing
echo "Starting x11vnc on port 5900..."
DISPLAY=:99 x11vnc -display :99 -forever -shared -rfbport 5900 -nopw -noxfixes -nowf -nowcr &
sleep 2

# Start websockify for noVNC
echo "Starting noVNC on port 7900..."
cd /opt/novnc && \
python3 -m websockify --web=/opt/novnc 7900 localhost:5900 &
sleep 2

# Set DISPLAY
export DISPLAY=:99

echo ""
echo "=========================================="
echo "✅ All services started!"
echo "=========================================="
echo "🌐 API:      http://localhost:8000"
echo "🌐 noVNC:    http://localhost:7900"
echo "🌐 VNC:      localhost:5900"
echo "=========================================="
echo ""

# Execute the command passed as argument
exec "$@"
