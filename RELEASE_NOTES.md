<img src="https://raw.githubusercontent.com/Sunwood-AI-OSS-Hub/cbot/main/assets/release-header-v0.3.0.png" alt="v0.3.0 Release"/>

# v0.3.0 - Agent Integration & Browser API / エージェント統合とブラウザAPI

**Release Date / リリース日:** 2026-02-03

---

## Japanese / 日本語

### 概要

v0.3.0 は、**Cinderella Browser API の統合**と**エージェント命名規則の統一**を含むメジャーアップデートです。

ブラウザ操作機能がサービスとして追加され、設定管理が簡素化されました。また、bot1/bot2/bot3 という命名から agent1/agent2/agent3 への一貫した命名規則への移行が完了しました。

### 新機能 ✨

#### Browser API Service
- **Cinderella Browser API サービス** ([#41](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/41))
  - ブラウザ操作APIを独立したDockerサービスとして追加
  - Playwrightベースのヘッドレスブラウザ操作
  - エージェントからのプログラマティックなWebアクセスを可能に

#### Configuration Templates
- **設定ファイルテンプレート** ([#37](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/37))
  - `config/examples/` ディレクトリに各種設定ファイルのテンプレートを追加
  - セットアップが簡単に

#### Development Planning
- **開発計画ドキュメント** (`PLAN.md`)
  - プロジェクトのロードマップと開発計画を追加
  - サブモジュール設定のドキュメント化

#### Submodules
- **agent-identity サブモジュール** ([#42](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/42))
  - エージェントのアイデンティティ管理をサブモジュール化
  - ヴェスパー・アウレリアン (Agent-12) の追加
  - リリスの追加

- **openclaw サブモジュール**
  - OpenClawコア機能をサブモジュールとして統合

### リファクタリング ♻️

#### Naming Convention Unification
- **bot → agent 命名規則の統一** ([#44](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/44), [#43](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/43))
  - `bot1/bot2/bot3` → `agent1/agent2/agent3` に完全移行
  - 環境変数: `BOT2_*` → `AGENT2_*`, `BOT3_*` → `AGENT3_*`
  - ディレクトリ名の統一
  - Docker Compose サービス名の更新

#### Setup Script Enhancement
- **setup.sh の拡張** ([#44](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/44))
  - 1エージェントずつのセットアップに対応
  - 引数でエージェント番号（1-3）を指定可能
  - `-y/--yes` オプションで非対話モード対応
  - `-h/--help` オプションでヘルプ表示

#### Docker Configuration
- **ボリュームマウント設定の簡素化** ([#40](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/39))
  - 全docker-composeファイルでボリューム設定を統一
  - マウント構成の説明ドキュメントを追加

### バグ修正 🐛

- **GH_PAT環境変数の分離** ([#45](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/45))
  - 各エージェントが専用のGitHub Personal Access Tokenを使用するように修正
  - `.env.example` に `GH_PAT_AGENT2`, `GH_PAT_AGENT3` を追加

- **設定ファイルの整理**
  - 不要な `config/bot3/openclaw.json` を削除
  - `.gitignore` の整理

### セキュリティ 🔒

- **セキュリティレポートの追加**
  - `.gemini_security/security_report_ja.md` を追加
  - Docker CVE-2025-47241関連の注釈と警告を明確化

### ドキュメント 📝

- **README.md / README.en.md の大幅更新**
  - agent命名規則への記載更新
  - setup.sh の使用方法を追加
  - ヘッダー画像の更新

- **セットアップ手順の簡素化** ([#37](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/37))
  - セットアップ手順をよりシンプルに更新

- **Docker ドキュメント**
  - 画像タグのピン方法に関するコメントを追加
  - ボリュームマウント構成の説明を追加

---

## English

### Overview

v0.3.0 is a major update featuring **Cinderella Browser API integration** and **unified agent naming conventions**.

Browser operation functionality has been added as a standalone service, and configuration management has been simplified. The transition from bot1/bot2/bot3 naming to agent1/agent2/agent3 consistent naming convention is now complete.

### What's New ✨

#### Browser API Service
- **Cinderella Browser API Service** ([#41](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/41))
  - Added browser operation API as a standalone Docker service
  - Playwright-based headless browser operations
  - Enables programmatic web access from agents

#### Configuration Templates
- **Configuration File Templates** ([#37](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/37))
  - Added configuration file templates in `config/examples/` directory
  - Simplified setup process

#### Development Planning
- **Development Plan Document** (`PLAN.md`)
  - Added project roadmap and development planning
  - Documented submodule configuration

#### Submodules
- **agent-identity Submodule** ([#42](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/42))
  - Modularized agent identity management
  - Added Vesperia Aurelian (Agent-12)
  - Added Lillis

- **openclaw Submodule**
  - Integrated OpenClaw core functionality as a submodule

### Refactoring ♻️

#### Naming Convention Unification
- **bot → agent naming convention unification** ([#44](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/44), [#43](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/43))
  - Complete transition from `bot1/bot2/bot3` to `agent1/agent2/agent3`
  - Environment variables: `BOT2_*` → `AGENT2_*`, `BOT3_*` → `AGENT3_*`
  - Unified directory names
  - Updated Docker Compose service names

#### Setup Script Enhancement
- **setup.sh expansion** ([#44](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/44))
  - Support for single-agent setup
  - Agent number (1-3) can be specified as argument
  - Non-interactive mode with `-y/--yes` option
  - Help display with `-h/--help` option

#### Docker Configuration
- **Volume mount configuration simplification** ([#40](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/39))
  - Unified volume settings across all docker-compose files
  - Added documentation for mount configuration

### Bug Fixes 🐛

- **GH_PAT environment variable separation** ([#45](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/45))
  - Fixed each agent to use dedicated GitHub Personal Access Tokens
  - Added `GH_PAT_AGENT2`, `GH_PAT_AGENT3` to `.env.example`

- **Configuration file cleanup**
  - Removed unnecessary `config/bot3/openclaw.json`
  - Cleaned up `.gitignore`

### Security 🔒

- **Security report added**
  - Added `.gemini_security/security_report_ja.md`
  - Clarified Docker CVE-2025-47241 related annotations and warnings

### Documentation 📝

- **Major README.md / README.en.md updates**
  - Updated documentation for agent naming convention
  - Added setup.sh usage instructions
  - Updated header image

- **Simplified setup instructions** ([#37](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/37))
  - Updated setup procedures to be more concise

- **Docker documentation**
  - Added comments about image tag pinning
  - Added volume mount configuration explanations

---

## Upgrade Instructions / アップグレード方法

```bash
# Get v0.3.0
git fetch --tags
git checkout v0.3.0

# Update submodules
git submodule update --init --recursive

# Update environment variables (rename BOT_* to AGENT_*)
# .env.example を参照して環境変数を更新してください

# Rebuild and restart
docker-compose down
docker-compose build
docker-compose up -d
```

**Important Notice / 重要なお知らせ:**
- Environment variables have been renamed: `BOT2_*` → `AGENT2_*`, `BOT3_*` → `AGENT3_*`
- 環境変数がリネームされました: `BOT2_*` → `AGENT2_*`, `BOT3_*` → `AGENT3_*`
- Please update your `.env` file accordingly
- `.env` ファイルの更新をお願いします

---

## Full Changelog

[Compare v0.2.1...v0.3.0](https://github.com/Sunwood-AI-OSS-Hub/cbot/compare/v0.2.1...v0.3.0)

---

## Contributors

**@Sunwood-AI-OSS-Hub** and contributors

---

## Related Pull Requests / 関連プルリクエスト

- [#45](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/45) - Fix: GH_PAT環境変数を各エージェント専用に修正
- [#44](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/44) - Refactor: bot2/bot3をagent2/agent3に統一して命名を一貫させる
- [#43](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/43) - Unify bot1 -> agent1 naming across compose, docs, and env
- [#42](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/42) - Feat: agent-identityサブモジュールの追加
- [#41](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/41) - Feat: Cinderella Browser API サービスの定義を追加
- [#40](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/40) - Chore: ボリュームマウント設定を簡素化
- [#39](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/39) - Chore: 不要なDockerfileを削除
- [#38](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/38) - Feat: 設定ファイルテンプレートを追加
- [#37](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/37) - Feat: 設定ファイルテンプレートを追加
- [#36](https://github.com/Sunwood-AI-OSS-Hub/cbot/pull/36) - Security: セキュリティレポートを追加

---

## Docker Images

| Image | Tags | Architectures |
|:------|:-----|:--------------|
| `ghcr.io/sunwood-ai-oss-hub/cbot-agent` | `latest`, `v0.3.0` | linux/amd64, linux/arm64 |
| `ghcr.io/sunwood-ai-oss-hub/cbot-browser-api` | `latest`, `v0.3.0` | linux/amd64, linux/arm64 |
