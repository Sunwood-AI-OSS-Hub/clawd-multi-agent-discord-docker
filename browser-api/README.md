<div align="center">

# Cinderella Browser API

<a href="README_JA.md"><img src="https://img.shields.io/badge/%E3%83%89%E3%82%AD%E3%83%A5%E3%83%A1%E3%83%B3%E3%83%88-%E6%97%A5%E6%9C%AC%E8%AA%9E-white.svg" alt="JA doc"/></a>
<a href="README.md"><img src="https://img.shields.io/badge/Documentation-English-white.svg" alt="EN doc"/></a>

</div>

## Overview

Cinderella Browser API is a browser automation API service powered by Playwright. It features VNC/noVNC support for visualization and allows programmatic control of browser operations via RESTful API.

## Features

- **Playwright Automation**: Control Chrome-based browsers programmatically
- **VNC/noVNC Support**: Real-time visualization of browser operations
- **RESTful API**: Execute browser operations via simple HTTP endpoints
- **Screenshot Capability**: Save page states as images

## Quick Start

```bash
# Start Browser API service
docker compose up browser-api

# Or start with all services
docker compose up -d
```

## API Endpoints

### `GET /`
Get service information.

```json
{
  "service": "Cinderella Browser API",
  "version": "1.0.0",
  "browser_running": true
}
```

### `GET /health`
Health check endpoint.

```json
{
  "running": true
}
```

### `POST /open`
Open a URL in the browser.

**Request:**
```json
{
  "url": "https://example.com",
  "wait_until": "domcontentloaded"
}
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | string | yes | URL to open |
| `wait_until` | string | no | Wait condition (default: `domcontentloaded`) |

**Response:**
```json
{
  "success": true,
  "url": "https://example.com",
  "title": "Example Domain"
}
```

### `GET /snapshot`
Get a list of interactive elements on the page.

Returns information about buttons, links, input fields, and their selectors for interaction.

**Response:**
```json
{
  "success": true,
  "url": "https://example.com",
  "title": "Example Domain",
  "elements": [
    {
      "ref": "@e1",
      "selector": "#submit-button",
      "role": "button",
      "tag": "button",
      "name": "Submit"
    }
  ]
}
```

### `POST /click`
Click an element by selector.

**Request:**
```json
{
  "selector": "#submit-button"
}
```

**Response:**
```json
{
  "success": true,
  "action": "click",
  "selector": "#submit-button"
}
```

### `POST /fill`
Fill an input field with text.

**Request:**
```json
{
  "selector": "input[name='username']",
  "value": "user123"
}
```

**Response:**
```json
{
  "success": true,
  "action": "fill",
  "selector": "input[name='username']",
  "value": "user123"
}
```

### `GET /text`
Get text content of an element by selector.

**Query Parameters:**
- `selector`: Selector of the element to get text from

**Response:**
```json
{
  "success": true,
  "selector": ".content",
  "text": "Sample text content"
}
```

### `POST /screenshot`
Take a screenshot of the current page.

**Request:**
```json
{
  "path": "/app/screenshots/screenshot.png"
}
```

**Response:**
```json
{
  "success": true,
  "path": "/app/screenshots/screenshot.png"
}
```

### `POST /close`
Close the browser.

**Response:**
```json
{
  "success": true,
  "message": "Browser closed"
}
```

## VNC Access

View browser operations in real-time.

- **VNC**: `localhost:5900`
- **noVNC (Browser-based)**: http://localhost:7900

## Ports

| Port | Purpose |
|------|---------|
| 8000 | API Server |
| 5900 | VNC |
| 7900 | noVNC |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DISPLAY` | X display number | `:99` |
| `ALLOWED_ORIGINS` | CORS allowed origins (comma-separated) | Empty (none allowed) |

## File Structure

```
browser-api/
├── Dockerfile              # Docker image definition
├── browser_manager.py      # Browser management (Singleton)
├── server.py               # FastAPI server
├── entrypoint.sh           # Entrypoint script
├── requirements.txt        # Python dependencies
├── tests/                  # Test code
│   └── test_api.py
└── screenshots/            # Screenshot save location (mount)
```

## Usage Examples

### Basic Workflow

```bash
# 1. Open a URL
curl -X POST http://localhost:8000/open \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'

# 2. Get page elements
curl http://localhost:8000/snapshot

# 3. Fill an input field
curl -X POST http://localhost:8000/fill \
  -H "Content-Type: application/json" \
  -d '{"selector": "#search", "value": "Cinderella"}'

# 4. Click a button
curl -X POST http://localhost:8000/click \
  -H "Content-Type: application/json" \
  -d '{"selector": "#search-button"}'

# 5. Take a screenshot
curl -X POST http://localhost:8000/screenshot \
  -H "Content-Type: application/json" \
  -d '{"path": "/app/screenshots/result.png"}'
```

## Docker Compose Configuration

```yaml
browser-api:
  build: ./browser-api
  ports:
    - "8000:8000"  # API
    - "5900:5900"  # VNC
    - "7900:7900"  # noVNC
  volumes:
    - ./browser-api/screenshots:/app/screenshots
  environment:
    - DISPLAY=:99
    - ALLOWED_ORIGINS=*
```

## License

MIT License
