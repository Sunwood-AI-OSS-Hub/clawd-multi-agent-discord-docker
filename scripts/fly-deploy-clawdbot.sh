#!/bin/bash
set -e

# ========================================
# 🦞 Clawdbot Fly.io デプロイスクリプト
# ========================================
#
# 使い方:
#   デプロイ:
#     1. .env.fly.example を .env.fly にコピー
#     2. .env.fly に環境変数を設定
#     3. ./scripts/fly-deploy-clawdbot.sh
#
#   削除:
#     ./scripts/fly-deploy-clawdbot.sh --delete [APP_NAME]
#
# .env.fly がない場合は対話的に設定を求めます
# ----------------------------------------

# スクリプトディレクトリからプロジェクトルートへ移動
cd "$(dirname "$0")/.."

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ========================================
# ユーティリティ関数
# ========================================

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

prompt() {
    local var_name=$1
    local prompt_text=$2
    local default_value=$3

    if [ -n "$default_value" ]; then
        read -p "$(echo -e "${CYAN}$prompt_text [${default_value}]: ${NC}")" input
        eval "$var_name=\"${input:-$default_value}\""
    else
        read -p "$(echo -e "${CYAN}$prompt_text: ${NC}")" input
        eval "$var_name=\"$input\""
    fi
}

prompt_secret() {
    local var_name=$1
    local prompt_text=$2

    read -sp "$(echo -e "${CYAN}$prompt_text: ${NC}")" input
    echo ""
    eval "$var_name=\"$input\""
}

confirm() {
    local prompt_text=$1
    read -p "$(echo -e "${YELLOW}$prompt_text (y/N): ${NC}")" response
    [[ "$response" =~ ^[Yy]$ ]]
}

# ========================================
# .env.fly 読み込み
# ========================================

load_env_file() {
    if [ -f ".env.fly" ]; then
        info ".env.fly を読み込み中..."
        set -a
        source .env.fly
        set +a
        success ".env.fly 読み込み完了"
        return 0
    else
        warn ".env.fly が見つかりません"
        info "対話モードで設定を入力します"
        info "事前に .env.fly.example を .env.fly にコピーすると設定をスキップできます"
        return 1
    fi
}

# ========================================
# 前提条件チェック
# ========================================

check_prerequisites() {
    info "前提条件をチェック中..."

    # flyctl チェック
    if ! command -v fly &> /dev/null; then
        warn "flyctl がインストールされていません"

        if confirm "flyctl をインストールしますか？"; then
            info "flyctl をインストール中..."

            case "$(uname -s)" in
                Darwin)
                    if command -v brew &> /dev/null; then
                        brew install flyctl
                    else
                        curl -L https://fly.io/install.sh | sh
                    fi
                    ;;
                Linux)
                    curl -L https://fly.io/install.sh | sh
                    export PATH="$HOME/.fly/bin:$PATH"
                    ;;
                MINGW*|CYGWIN*|MSYS*)
                    error "Windows では手動でインストールしてください: https://fly.io/docs/hands-on/install-flyctl/"
                    ;;
            esac

            success "flyctl インストール完了"
        else
            error "flyctl が必要です。先にインストールしてください。"
        fi
    else
        success "flyctl: $(fly version | head -n1)"
    fi

    # git チェック
    if ! command -v git &> /dev/null; then
        error "git がインストールされていません"
    fi
    success "git: $(git --version)"

    # Fly.io ログインチェック
    if ! fly auth whoami &> /dev/null; then
        warn "Fly.io にログインしていません"
        info "ブラウザでログインしてください..."
        fly auth login
        success "Fly.io ログイン完了"
    else
        success "Fly.io: $(fly auth whoami)"
    fi
}

# ========================================
# 設定収集
# ========================================

collect_config() {
    echo ""
    info "=== デプロイ設定 ==="
    echo ""

    # .env.fly から読み込めたか確認
    local has_env=false
    if [ -n "${FLY_APP_NAME}" ]; then
        has_env=true
    fi

    # fly.toml からアプリ名を読み取り
    if [ -f "fly.toml" ]; then
        local fly_app=$(grep -E '^app = ' fly.toml | sed -E 's/app = "(.*)"/\1/' | sed -E "s/app = '(.*)'/\1/")
        if [ -n "$fly_app" ]; then
            FLY_APP_NAME="${fly_app}"
        fi
    fi

    # アプリ名
    prompt APP_NAME "アプリ名（半角英数字とハイフン）" "${FLY_APP_NAME:-clawdbot-aquarium}"

    # リージョン選択
    if [ -z "${FLY_REGION}" ]; then
        echo ""
        info "利用可能なリージョン:"
        echo "  nrt - 東京（日本から最速）"
        echo "  sin - シンガポール"
        echo "  syd - シドニー"
        echo "  iad - バージニア（米国東海岸）"
        echo "  sjc - サンノゼ（米国西海岸）"
        echo "  lhr - ロンドン"
    fi
    prompt REGION "リージョン" "${FLY_REGION:-nrt}"

    # メモリサイズ
    if [ -z "${FLY_MEMORY}" ]; then
        echo ""
        info "メモリサイズ（推奨: 2048）:"
        echo "  1024 - 1GB（軽量利用向け）"
        echo "  2048 - 2GB（推奨）"
        echo "  4096 - 4GB（高負荷向け）"
    fi
    prompt MEMORY "メモリ (MB)" "${FLY_MEMORY:-2048}"

    # ボリュームサイズ
    prompt VOLUME_SIZE "データボリュームサイズ (GB)" "${FLY_VOLUME_SIZE:-1}"

    # API キー設定（.env.fly にない場合のみ）
    if ! $has_env || [ -z "${ANTHROPIC_API_KEY}" ]; then
        echo ""
        info "=== API キー設定 ==="
        echo ""

        if confirm "Anthropic API キーを設定しますか？（Claude を使う場合）"; then
            prompt_secret ANTHROPIC_API_KEY "Anthropic API キー (sk-ant-...)"
        fi
    else
        ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
    fi

    if ! $has_env || [ -z "${ZAI_API_KEY}" ]; then
        if confirm "ZAI API キーを設定しますか？"; then
            prompt_secret ZAI_API_KEY "ZAI API キー"
        fi
    else
        ZAI_API_KEY="${ZAI_API_KEY:-}"
    fi

    if ! $has_env || [ -z "${OPENROUTER_API_KEY}" ]; then
        if confirm "OpenRouter API キーを設定しますか？"; then
            prompt_secret OPENROUTER_API_KEY "OpenRouter API キー"
        fi
    else
        OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-}"
    fi

    if ! $has_env || [ -z "${DISCORD_BOT_TOKEN}" ]; then
        if confirm "Discord Bot トークンを設定しますか？"; then
            prompt_secret DISCORD_BOT_TOKEN "Discord Bot トークン"
        fi
    else
        DISCORD_BOT_TOKEN="${DISCORD_BOT_TOKEN:-}"
    fi

    # 確認
    echo ""
    info "=== 設定確認 ==="
    echo "  アプリ名:    ${APP_NAME}"
    echo "  リージョン:  ${REGION}"
    echo "  メモリ:      ${MEMORY}MB"
    echo "  ボリューム:  ${VOLUME_SIZE}GB"
    echo "  Anthropic:   ${ANTHROPIC_API_KEY:+設定済み}${ANTHROPIC_API_KEY:-未設定}"
    echo "  ZAI:         ${ZAI_API_KEY:+設定済み}${ZAI_API_KEY:-未設定}"
    echo "  OpenRouter:  ${OPENROUTER_API_KEY:+設定済み}${OPENROUTER_API_KEY:-未設定}"
    echo "  Discord:     ${DISCORD_BOT_TOKEN:+設定済み}${DISCORD_BOT_TOKEN:-未設定}"
    echo ""

    if ! confirm "この設定でデプロイを続けますか？"; then
        error "キャンセルされました"
    fi
}

# ========================================
# リポジトリ準備
# ========================================

prepare_repository() {
    info "リポジトリを準備中..."

    if [ -d "clawdbot" ]; then
        info "既存の clawdbot サブモジュールを更新..."
        git submodule update --init --recursive --remote
    else
        info "clawdbot サブモジュールを初期化..."
        git submodule update --init --recursive
    fi

    success "リポジトリ準備完了"
}

# ========================================
# fly.toml 設定表示
# ========================================

show_fly_config() {
    info "fly.toml の設定を確認中..."

    if [ ! -f "fly.toml" ]; then
        error "fly.toml が見つかりません。./fly.toml を作成してください"
    fi

    echo ""
    info "=== fly.toml の現在の設定 ==="
    cat fly.toml
    echo ""
    success "fly.toml を使用します"
}

# ========================================
# Fly.io リソース作成
# ========================================

create_fly_resources() {
    info "Fly.io リソースを作成中..."

    # アプリ作成（既存の場合はスキップ）
    if fly apps list | grep -q "^${APP_NAME}"; then
        warn "アプリ ${APP_NAME} は既に存在します"
    else
        fly apps create "${APP_NAME}"
        success "アプリ作成完了: ${APP_NAME}"
    fi

    # ボリューム作成（既存の場合はスキップ）
    if fly volumes list -a "${APP_NAME}" 2>/dev/null | grep -q "clawdbot_data"; then
        warn "ボリュームは既に存在します"
    else
        fly volumes create clawdbot_data \
            --size "${VOLUME_SIZE}" \
            --region "${REGION}" \
            -a "${APP_NAME}" \
            -y
        success "ボリューム作成完了"
    fi
}

# ========================================
# シークレット設定
# ========================================

set_secrets() {
    info "シークレットを設定中..."

    # Gateway トークン生成
    GATEWAY_TOKEN=$(openssl rand -hex 32)
    fly secrets set "CLAWDBOT_GATEWAY_TOKEN=${GATEWAY_TOKEN}" -a "${APP_NAME}"
    success "Gateway トークン設定完了"

    # Anthropic API キー
    if [ -n "${ANTHROPIC_API_KEY}" ]; then
        fly secrets set "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}" -a "${APP_NAME}"
        success "Anthropic API キー設定完了"
    fi

    # ZAI API キー
    if [ -n "${ZAI_API_KEY}" ]; then
        fly secrets set "ZAI_API_KEY=${ZAI_API_KEY}" -a "${APP_NAME}"
        success "ZAI API キー設定完了"
    fi

    # OpenRouter API キー
    if [ -n "${OPENROUTER_API_KEY}" ]; then
        fly secrets set "OPENROUTER_API_KEY=${OPENROUTER_API_KEY}" -a "${APP_NAME}"
        success "OpenRouter API キー設定完了"
    fi

    # Discord Bot トークン
    if [ -n "${DISCORD_BOT_TOKEN}" ]; then
        fly secrets set "DISCORD_BOT_TOKEN=${DISCORD_BOT_TOKEN}" -a "${APP_NAME}"
        success "Discord Bot トークン設定完了"
    fi

    # Gateway トークンを保存
    echo ""
    warn "=== 重要：Gateway トークン ==="
    echo -e "${YELLOW}${GATEWAY_TOKEN}${NC}"
    echo ""
    info "このトークンは Control UI へのログインに必要です"
    info "安全な場所に保存してください"

    # ファイルに保存
    echo "${GATEWAY_TOKEN}" > "${APP_NAME}-gateway-token.txt"
    info "トークンを ${APP_NAME}-gateway-token.txt に保存しました"
}

# ========================================
# デプロイ
# ========================================

deploy() {
    info "デプロイを開始します..."
    echo ""
    warn "初回ビルドには 2〜3 分かかります ☕"
    echo ""

    fly deploy

    success "デプロイ完了！"
}

# ========================================
# 削除機能
# ========================================

delete_app() {
    local app_name=$1

    echo ""
    warn "=== アプリ削除モード ==="
    echo ""

    # アプリ名が未指定の場合は入力を求める
    if [ -z "$app_name" ]; then
        prompt app_name "削除するアプリ名" ""
        if [ -z "$app_name" ]; then
            error "アプリ名が指定されませんでした"
        fi
    fi

    # アプリの存在確認
    if ! fly apps list | grep -q "^${app_name}"; then
        error "アプリ ${app_name} は存在しません"
    fi

    echo -e "${RED}========================================${NC}"
    echo -e "${RED}⚠️  警告: 不可逆的な操作です${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "削除対象: ${YELLOW}${app_name}${NC}"
    echo ""
    echo -e "以下のリソースが削除されます:"
    echo -e "  ${RED}• アプリケーション${NC}"
    echo -e "  ${RED}• ボリューム（データは完全に消えます）${NC}"
    echo -e "  ${RED}• シークレット${NC}"
    echo -e "  ${RED}• デプロイ履歴${NC}"
    echo ""

    # 確認
    if ! confirm "本当に ${app_name} を削除しますか？この操作は取り消せません"; then
        info "キャンセルされました"
        exit 0
    fi

    # 二重確認
    echo ""
    warn "もう一度だけ確認します"
    if ! confirm "本当に本当に削除してよろしいですか？"; then
        info "キャンセルされました"
        exit 0
    fi

    echo ""
    info "削除を開始します..."
    echo ""

    # ボリューム情報を取得（削除前に表示）
    info "ボリューム情報:"
    fly volumes list -a "${app_name}" 2>/dev/null || true
    echo ""

    # アプリ削除（flyctlは関連するボリュームも削除する）
    info "アプリ ${app_name} を削除中..."
    fly apps destroy "${app_name}" -y

    echo ""
    success "削除完了！"
    echo ""
    info "アプリ ${app_name} と関連リソースが削除されました"

    # Gateway トークンファイルがあれば削除
    if [ -f "${app_name}-gateway-token.txt" ]; then
        info "Gateway トークンファイルを削除中..."
        rm -f "${app_name}-gateway-token.txt"
        success "Gateway トークンファイルを削除しました"
    fi
}

# ========================================
# 完了メッセージ
# ========================================

show_completion() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}🎉 デプロイが完了しました！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "アプリ URL:    ${CYAN}https://${APP_NAME}.fly.dev/${NC}"
    echo -e "Control UI:    ${CYAN}https://${APP_NAME}.fly.dev/${NC}"
    echo ""
    echo -e "便利なコマンド:"
    echo -e "  ${YELLOW}fly logs -a ${APP_NAME}${NC}        # ログ確認"
    echo -e "  ${YELLOW}fly status -a ${APP_NAME}${NC}      # ステータス確認"
    echo -e "  ${YELLOW}fly ssh console -a ${APP_NAME}${NC} # SSH 接続"
    echo -e "  ${YELLOW}fly open -a ${APP_NAME}${NC}        # ブラウザで開く"
    echo ""

    if confirm "ログを確認しますか？"; then
        fly logs -a "${APP_NAME}"
    fi
}

# ========================================
# メイン処理
# ========================================

main() {
    # コマンドライン引数をチェック
    if [ "$1" = "--delete" ] || [ "$1" = "-d" ]; then
        delete_app "$2"
        exit 0
    fi

    # ヘルプ表示
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "Clawdbot Fly.io デプロイスクリプト"
        echo ""
        echo "使い方:"
        echo "  $0                    # デプロイ"
        echo "  $0 --delete [APP]     # アプリ削除"
        echo "  $0 -h, --help         # ヘルプ"
        echo ""
        exit 0
    fi

    echo ""
    info "Clawdbot Fly.io デプロイスクリプトを開始します"
    echo ""

    check_prerequisites
    load_env_file || true
    collect_config
    prepare_repository
    show_fly_config
    create_fly_resources
    set_secrets
    deploy
    show_completion
}

# 実行
main "$@"
