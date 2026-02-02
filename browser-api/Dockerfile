FROM python:3.13-slim

WORKDIR /app

# Install system dependencies for Playwright/Chrome + VNC + noVNC
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    libxshmfence1 \
    xvfb \
    x11vnc \
    x11-apps \
    fluxbox \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome (the real one!)
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/trusted.gpg.d/google-chrome.gpg && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    rm /etc/apt/sources.list.d/google-chrome.list

# Install noVNC
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/novnc && \
    cd /opt/novnc && \
    ln -s vnc.html index.html

# Install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install websockify

# Install Playwright browsers
RUN playwright install chromium

# Create directories
RUN mkdir -p /app/screenshots /app/chrome-profile

# Copy application files
COPY browser_manager.py .
COPY server.py .
COPY entrypoint.sh .

# Make entrypoint executable
RUN chmod +x /app/entrypoint.sh

EXPOSE 8000 5900 7900

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]

