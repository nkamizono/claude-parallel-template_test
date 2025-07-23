#!/bin/bash

# Claude並列開発プロジェクト初期化スクリプト
# 新しいプロジェクトでClaude並列開発システムをセットアップします

set -e  # エラーが発生したら即座に終了

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# テンプレートディレクトリの確認
TEMPLATE_DIR="$(dirname "$0")"
if [ ! -d "$TEMPLATE_DIR/bin" ] || [ ! -d "$TEMPLATE_DIR/templates" ]; then
    echo -e "${RED}エラー: テンプレートディレクトリが正しくありません${NC}"
    echo "このスクリプトはclaude-parallel-templateディレクトリから実行してください"
    exit 1
fi

# ロゴ表示
show_logo() {
    echo -e "${CYAN}"
    cat << 'EOF'
 ____  _                 _        ____                 _ _      _ 
/ ___|| | __ _ _   _  __| | ___  |  _ \ __ _ _ __ __ _| | | ___| |
\___ \| |/ _` | | | |/ _` |/ _ \ | |_) / _` | '__/ _` | | |/ _ \ |
 ___) | | (_| | |_| | (_| |  __/ |  __/ (_| | | | (_| | | |  __/ |
|____/|_|\__,_|\__,_|\__,_|\___| |_|   \__,_|_|  \__,_|_|_|\___|_|
                                                                   
         Development System - Project Initializer
EOF
    echo -e "${NC}"
}

# プロジェクト情報の入力
get_project_info() {
    echo -e "${BLUE}=== プロジェクト情報の入力 ===${NC}"
    echo
    
    # プロジェクト名
    while true; do
        echo -n "プロジェクト名 (英数字とハイフンのみ): "
        read PROJECT_NAME
        if [[ $PROJECT_NAME =~ ^[a-zA-Z0-9-]+$ ]]; then
            break
        else
            echo -e "${RED}エラー: 英数字とハイフンのみ使用できます${NC}"
        fi
    done
    
    # プロジェクトの説明
    echo -n "プロジェクトの説明: "
    read PROJECT_DESCRIPTION
    
    # プロジェクトディレクトリ
    echo -n "プロジェクトディレクトリ (デフォルト: ./$PROJECT_NAME): "
    read PROJECT_DIR
    PROJECT_DIR=${PROJECT_DIR:-"./$PROJECT_NAME"}
    
    # Claudeの構成
    echo
    echo -e "${YELLOW}Claudeの構成を選択してください:${NC}"
    echo "1) 標準 (親1 + 子2)"
    echo "2) シンプル (親1 + 子1)"
    echo "3) 拡張 (親1 + 子3)"
    echo "4) カスタム"
    echo -n "選択 (1-4): "
    read CLAUDE_CONFIG
    
    case $CLAUDE_CONFIG in
        1) CLAUDE_COUNT=3; CLAUDE_SETUP="standard" ;;
        2) CLAUDE_COUNT=2; CLAUDE_SETUP="simple" ;;
        3) CLAUDE_COUNT=4; CLAUDE_SETUP="extended" ;;
        4) 
            echo -n "Claudeの総数: "
            read CLAUDE_COUNT
            CLAUDE_SETUP="custom"
            ;;
        *) CLAUDE_COUNT=3; CLAUDE_SETUP="standard" ;;
    esac
    
    # 技術スタック
    echo
    echo -e "${YELLOW}使用する技術スタックを選択してください:${NC}"
    echo "1) Web開発 (React + Node.js)"
    echo "2) Python開発"
    echo "3) モバイル開発 (React Native)"
    echo "4) その他（後で設定）"
    echo -n "選択 (1-4): "
    read TECH_CHOICE
    
    case $TECH_CHOICE in
        1) TECH_STACK="web" ;;
        2) TECH_STACK="python" ;;
        3) TECH_STACK="mobile" ;;
        *) TECH_STACK="other" ;;
    esac
}

# プロジェクトディレクトリの作成
create_project_structure() {
    echo
    echo -e "${BLUE}=== プロジェクト構造の作成 ===${NC}"
    
    # ディレクトリ作成
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    
    # 基本ディレクトリ構造
    mkdir -p .claude/{bin,config}
    mkdir -p claude-tasks/{parent,shared}
    mkdir -p docs
    mkdir -p logs
    mkdir -p backups
    
    # 子Claudeディレクトリの作成
    for i in $(seq 1 $((CLAUDE_COUNT - 1))); do
        mkdir -p claude-tasks/child${i}/{todo,in-progress,completed,review}
    done
    
    # 共有ディレクトリ
    mkdir -p claude-tasks/shared/{instructions,progress,issues}
    
    echo -e "${GREEN}✓ ディレクトリ構造を作成しました${NC}"
}

# ファイルのコピーと設定
copy_and_configure_files() {
    echo
    echo -e "${BLUE}=== ファイルのコピーと設定 ===${NC}"
    
    # スクリプトのコピー
    cp "$TEMPLATE_DIR/bin/"*.sh .claude/bin/
    cp "$TEMPLATE_DIR/bin/"*.py .claude/bin/
    chmod +x .claude/bin/*.sh
    chmod +x .claude/bin/*.py
    
    # テンプレートのコピー
    cp "$TEMPLATE_DIR/templates/"*.md ./
    cp "$TEMPLATE_DIR/templates/.tmux.conf" ./
    
    # 設定ファイルの作成
    cp "$TEMPLATE_DIR/config.sh" .claude/config/
    
    # 設定ファイルの更新
    sed -i.bak "s/PROJECT_NAME=\".*\"/PROJECT_NAME=\"$PROJECT_NAME\"/" .claude/config/config.sh
    sed -i.bak "s/PROJECT_DESCRIPTION=\".*\"/PROJECT_DESCRIPTION=\"$PROJECT_DESCRIPTION\"/" .claude/config/config.sh
    sed -i.bak "s/CLAUDE_COUNT=.*/CLAUDE_COUNT=$CLAUDE_COUNT/" .claude/config/config.sh
    rm .claude/config/config.sh.bak
    
    # シンボリックリンクの作成（簡単アクセス用）
    ln -sf .claude/bin/claude-parallel-dev.sh ./cpd
    ln -sf .claude/bin/claude-task-manager.sh ./ctm
    ln -sf .claude/bin/claude-review-system.sh ./crs
    
    echo -e "${GREEN}✓ ファイルをコピーしました${NC}"
}

# 技術スタック別の設定
configure_tech_stack() {
    echo
    echo -e "${BLUE}=== 技術スタックの設定 ===${NC}"
    
    case $TECH_STACK in
        "web")
            # package.jsonの作成
            cat > package.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "$PROJECT_DESCRIPTION",
  "main": "index.js",
  "scripts": {
    "dev": "echo 'Development server'",
    "build": "echo 'Build project'",
    "test": "echo 'Run tests'",
    "lint": "echo 'Run linter'"
  },
  "keywords": [],
  "author": "",
  "license": "MIT"
}
EOF
            
            # 基本的なディレクトリ構造
            mkdir -p src/{components,services,utils}
            mkdir -p public
            mkdir -p tests
            
            echo -e "${GREEN}✓ Web開発環境を設定しました${NC}"
            ;;
            
        "python")
            # requirements.txtの作成
            cat > requirements.txt << EOF
# $PROJECT_NAME requirements
# Add your Python dependencies here
EOF
            
            # 基本的なディレクトリ構造
            mkdir -p src/{modules,utils}
            mkdir -p tests
            mkdir -p data
            
            # setup.pyの作成
            cat > setup.py << EOF
from setuptools import setup, find_packages

setup(
    name="$PROJECT_NAME",
    version="1.0.0",
    description="$PROJECT_DESCRIPTION",
    packages=find_packages(),
)
EOF
            
            echo -e "${GREEN}✓ Python開発環境を設定しました${NC}"
            ;;
            
        "mobile")
            # 基本的なディレクトリ構造
            mkdir -p src/{screens,components,services}
            mkdir -p assets
            mkdir -p __tests__
            
            echo -e "${GREEN}✓ モバイル開発環境を設定しました${NC}"
            ;;
    esac
}

# 初期の開発設計書作成
create_initial_spec() {
    echo
    echo -e "${BLUE}=== 初期開発設計書の作成 ===${NC}"
    
    cat > development-spec.md << EOF
# 開発設計書

## プロジェクト概要
プロジェクト名: $PROJECT_NAME
目的: $PROJECT_DESCRIPTION
作成日: $(date '+%Y-%m-%d')

## 開発タスク一覧

### タスク1: プロジェクト初期設定
- **タスクID**: TASK001
- **優先度**: 高
- **依存関係**: なし
- **担当**: 親Claude
- **概要**: プロジェクトの基本設定とディレクトリ構造の確立
- **入力**: プロジェクト要件
- **出力**: 設定済みプロジェクト構造
- **完了条件**: すべての設定ファイルが作成され、動作確認済み

### タスク2: [タスク名をここに記入]
- **タスクID**: TASK002
- **優先度**: 中
- **依存関係**: TASK001
- **担当**: 子Claude1
- **概要**: [タスクの詳細説明]
- **入力**: [必要な入力情報]
- **出力**: [期待される成果物]
- **完了条件**: [完了の判断基準]

## 技術仕様
- 技術スタック: $TECH_STACK
- Claudeの構成: $CLAUDE_SETUP ($CLAUDE_COUNT 台)

## 注意事項
- このファイルを編集して、実際のタスクを追加してください
- タスクIDは一意である必要があります
- 依存関係は慎重に設定してください
EOF
    
    echo -e "${GREEN}✓ 初期開発設計書を作成しました${NC}"
}

# Gitリポジトリの初期化
init_git_repo() {
    echo
    echo -e "${BLUE}=== Gitリポジトリの初期化 ===${NC}"
    
    # .gitignoreの作成
    cat > .gitignore << EOF
# Claude並列開発システム
claude-tasks/*/in-progress/
claude-tasks/*/todo/
claude-tasks/*/review/
logs/
backups/
*.log
*.tmp

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Dependencies
node_modules/
__pycache__/
*.pyc
venv/
env/

# Build
dist/
build/
*.egg-info/
EOF
    
    # Gitリポジトリ初期化
    git init
    git add .
    git commit -m "Initial commit: Claude parallel development system setup"
    
    echo -e "${GREEN}✓ Gitリポジトリを初期化しました${NC}"
}

# 使い方ガイドの作成
create_usage_guide() {
    echo
    echo -e "${BLUE}=== 使い方ガイドの作成 ===${NC}"
    
    cat > QUICK_START.md << EOF
# $PROJECT_NAME - クイックスタートガイド

## セットアップ完了！

プロジェクトのセットアップが完了しました。以下の手順で開発を開始できます。

## 1. 開発設計書の編集

まず、\`development-spec.md\`を編集して、実際のタスクを追加してください：

\`\`\`bash
vim development-spec.md
\`\`\`

## 2. 開発環境の起動

以下のコマンドで開発環境を起動します：

\`\`\`bash
./cpd setup   # タスクの自動分割
./cpd start   # tmuxセッション開始
\`\`\`

## 3. 各Claudeでの作業

各tmuxウィンドウで以下のようにClaudeに指示します：

**親Claude (ウィンドウ1):**
\`\`\`
私は親Claudeです。parent-claude-guide.mdに従って作業を進めます。
\`\`\`

**子Claude (ウィンドウ2,3...):**
\`\`\`
私は子Claude1です。child-claude-guide.mdに従って作業を進めます。
\`\`\`

## ショートカットコマンド

- \`./cpd\` - メイン管理コマンド
- \`./ctm\` - タスク管理
- \`./crs\` - レビューシステム

## tmux操作

- ウィンドウ切替: \`Ctrl-a\` → \`1-5\`
- セッション離脱: \`Ctrl-a\` → \`d\`
- 再接続: \`tmux a -t $PROJECT_NAME-dev\`

## トラブルシューティング

問題が発生した場合は、\`logs/\`ディレクトリのログを確認してください。

詳細なマニュアルは \`DETAILED_MANUAL.md\` を参照してください。
EOF
    
    echo -e "${GREEN}✓ 使い方ガイドを作成しました${NC}"
}

# 最終確認と完了メッセージ
show_completion_message() {
    echo
    echo -e "${GREEN}===================================${NC}"
    echo -e "${GREEN}✓ プロジェクトの初期化が完了しました！${NC}"
    echo -e "${GREEN}===================================${NC}"
    echo
    echo -e "${CYAN}プロジェクト情報:${NC}"
    echo "  名前: $PROJECT_NAME"
    echo "  場所: $(pwd)"
    echo "  Claude構成: $CLAUDE_SETUP ($CLAUDE_COUNT 台)"
    echo
    echo -e "${YELLOW}次のステップ:${NC}"
    echo "1. development-spec.md を編集してタスクを追加"
    echo "2. ./cpd setup でタスクを自動分割"
    echo "3. ./cpd start で開発開始"
    echo
    echo -e "${BLUE}詳細は QUICK_START.md を参照してください${NC}"
}

# メイン処理
main() {
    show_logo
    get_project_info
    create_project_structure
    copy_and_configure_files
    configure_tech_stack
    create_initial_spec
    init_git_repo
    create_usage_guide
    show_completion_message
}

# 実行
main