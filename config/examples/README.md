# OpenClaw Config Examples

このディレクトリには、OpenClawボットの設定ファイルのexampleが含まれています。

## ファイル一覧

### AIプロバイダー設定

| ファイル | 説明 | 使用するAI |
|--------|------|-----------|
| `models.json.example` | ZAI (GLM-4.7) の設定 | ZAI |
| `models.openrouter.json.example` | OpenRouter の設定 | OpenRouter |
| `models.both.json.example` | 両方のプロバイダーを設定 | ZAI + OpenRouter |

### ボット設定

| ファイル | 説明 | メインモデル |
|--------|------|------------|
| `openclaw.json.example` | 基本設定（ZAI用） | `zai/glm-4.7` |
| `openclaw.openrouter.json.example` | 基本設定（OpenRouter用） | `openrouter/anthropic/claude-3.5-sonnet` |

## 使い方

### 1. 設定ファイルのコピー

各ボットのconfigディレクトリにコピーします：

```bash
# Agent 1 の場合（ZAIを使用）
cp config/examples/models.json.example config/agent1/models.json
cp config/examples/openclaw.json.example config/agent1/openclaw.json

# Bot 2 の場合（OpenRouterを使用）
cp config/examples/models.openrouter.json.example config/bot2/models.json
cp config/examples/openclaw.openrouter.json.example config/bot2/openclaw.json
```

### 2. 環境変数の設定

`.env` ファイルにAPIキーを設定します：

```bash
# ZAI API Key (GLM-4.7を使用する場合)
ZAI_API_KEY=your_zai_api_key_here

# OpenRouter API Key (OpenRouterを使用する場合)
OPENROUTER_API_KEY=your_openrouter_api_key_here
```

### 3. モデルの切り替え

`openclaw.json` の `primary` を変更して使用するモデルを切り替えます：

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "zai/glm-4.7"  // または "openrouter/anthropic/claude-3.5-sonnet"
      }
    }
  }
}
```

## 設定オプション

### groupPolicy（Discord応答ポリシー）

- `"open"`: 全てのチャンネルで応答
- `"allowlist"`: 許可されたチャンネルのみで応答

### ackReactionScope（リアクション範囲）

- `"all"`: 全てのメッセージにリアクション
- `"group-mentions"`: メンション時のみリアクション

### maxConcurrent（並列処理数）

- `maxConcurrent`: エージェントの並列数
- `subagents.maxConcurrent`: サブエージェントの並列数

## 自動セットアップ

`setup.sh` スクリプトを使用すると、これらの設定ファイルが自動的にコピーされます：

```bash
./setup.sh
```

スクリプトは以下を行います：
1. `.env` ファイルの作成（`.env.example` から）
2. configディレクトリの作成
3. exampleファイルからの設定ファイルのコピー
4. 必要なゲートウェイトークンの生成
