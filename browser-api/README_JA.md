<div align="center">

# Cinderella Browser API

<a href="README.md"><img src="https://img.shields.io/badge/Documentation-English-white.svg" alt="EN doc"/></a>

</div>

## 概要

Cinderella Browser API は、Playwright を使用したブラウザ自動化 API サービスです。VNC/noVNC による可視化機能を備え、RESTful API からブラウザ操作をプログラム的に制御できます。

## 特徴

- **Playwright による自動化**: Chrome ベースのブラウザをプログラムから制御
- **VNC/noVNC サポート**: ブラウザ操作の様子をリアルタイムで可視化
- **RESTful API**: シンプルな HTTP エンドポイントでブラウザ操作を実行
- **スクリーンショット機能**: ページの状態を画像として保存

## クイックスタート

```bash
# Browser API サービスを起動
docker compose up browser-api

# またはすべてのサービスと一緒に起動
docker compose up -d
```

## API エンドポイント

### `GET /`
サービス情報を取得します。

```json
{
  "service": "Cinderella Browser API",
  "version": "1.0.0",
  "browser_running": true
}
```

### `GET /health`
ヘルスチェックエンドポイント。

```json
{
  "running": true
}
```

### `POST /open`
指定した URL をブラウザで開きます。

**リクエスト:**
```json
{
  "url": "https://example.com",
  "wait_until": "domcontentloaded"
}
```

**パラメータ:**

| パラメータ | 型 | 必須 | 説明 |
|-----------|------|------|------|
| `url` | string | yes | 開く URL |
| `wait_until` | string | no | 待機条件（デフォルト: `domcontentloaded`） |

**レスポンス:**
```json
{
  "success": true,
  "url": "https://example.com",
  "title": "Example Domain"
}
```

### `GET /snapshot`
ページ上のインタラクティブ要素の一覧を取得します。

ボタン、リンク、入力フィールドなどの情報と、それらを操作するためのセレクタを返します。

**レスポンス:**
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
指定したセレクタの要素をクリックします。

**リクエスト:**
```json
{
  "selector": "#submit-button"
}
```

**レスポンス:**
```json
{
  "success": true,
  "action": "click",
  "selector": "#submit-button"
}
```

### `POST /fill`
入力フィールドにテキストを入力します。

**リクエスト:**
```json
{
  "selector": "input[name='username']",
  "value": "user123"
}
```

**レスポンス:**
```json
{
  "success": true,
  "action": "fill",
  "selector": "input[name='username']",
  "value": "user123"
}
```

### `GET /text`
指定したセレクタの要素のテキストを取得します。

**クエリパラメータ:**
- `selector`: テキストを取得する要素のセレクタ

**レスポンス:**
```json
{
  "success": true,
  "selector": ".content",
  "text": "Sample text content"
}
```

### `POST /screenshot`
現在のページのスクリーンショットを撮影します。

**リクエスト:**
```json
{
  "path": "/app/screenshots/screenshot.png"
}
```

**レスポンス:**
```json
{
  "success": true,
  "path": "/app/screenshots/screenshot.png"
}
```

### `POST /close`
ブラウザを閉じます。

**レスポンス:**
```json
{
  "success": true,
  "message": "Browser closed"
}
```

## VNC アクセス

ブラウザ操作の様子をリアルタイムで確認できます。

- **VNC**: `localhost:5900`
- **noVNC（ブラウザベース）**: http://localhost:7900

## ポート

| ポート | 用途 |
|--------|------|
| 8000 | API サーバー |
| 5900 | VNC |
| 7900 | noVNC |

## 環境変数

| 変数名 | 説明 | デフォルト値 |
|--------|------|--------------|
| `DISPLAY` | X ディスプレイ番号 | `:99` |
| `ALLOWED_ORIGINS` | CORS 許可オリジン（カンマ区切り） | 空（許可なし） |

## ファイル構造

```
browser-api/
├── Dockerfile              # Docker イメージ定義
├── browser_manager.py      # ブラウザ管理（Singleton）
├── server.py               # FastAPI サーバー
├── entrypoint.sh           # エントリーポイントスクリプト
├── requirements.txt        # Python 依存関係
├── tests/                  # テストコード
│   └── test_api.py
└── screenshots/            # スクリーンショット保存先（マウント）
```

## 使用例

### 基本的な使用フロー

```bash
# 1. URL を開く
curl -X POST http://localhost:8000/open \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'

# 2. ページ上の要素を取得
curl http://localhost:8000/snapshot

# 3. 入力フィールドに入力
curl -X POST http://localhost:8000/fill \
  -H "Content-Type: application/json" \
  -d '{"selector": "#search", "value": "Cinderella"}'

# 4. ボタンをクリック
curl -X POST http://localhost:8000/click \
  -H "Content-Type: application/json" \
  -d '{"selector": "#search-button"}'

# 5. スクリーンショットを撮る
curl -X POST http://localhost:8000/screenshot \
  -H "Content-Type: application/json" \
  -d '{"path": "/app/screenshots/result.png"}'
```

## Docker Compose 設定

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

## ライセンス

MIT License
