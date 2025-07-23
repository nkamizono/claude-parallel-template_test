#!/bin/bash

# Claude並列開発システム 設定ファイル
# このファイルを編集してプロジェクトに合わせてカスタマイズしてください

# =========================
# プロジェクト設定
# =========================

# プロジェクト名（英数字とハイフンのみ）
PROJECT_NAME="my-project"

# プロジェクトの説明
PROJECT_DESCRIPTION="My awesome project using Claude parallel development"

# プロジェクトルートディレクトリ（絶対パス推奨）
PROJECT_ROOT="$(pwd)"

# =========================
# Claude設定
# =========================

# 使用するClaudeの数（親Claude + 子Claudeの数）
# デフォルト: 3（親1 + 子2）
CLAUDE_COUNT=3

# Claudeの役割名
# 必要に応じて追加・変更可能
CLAUDE_ROLES=(
    "parent:プロジェクト統括・レビュー"
    "child1:フロントエンド開発"
    "child2:バックエンド開発"
)

# Claude起動コマンド
# 環境に応じて変更してください
CLAUDE_COMMAND="claude --dangerously-skip-permissions"

# =========================
# tmux設定
# =========================

# tmuxセッション名
SESSION_NAME="${PROJECT_NAME}-dev"

# tmuxプレフィックスキー（デフォルト: Ctrl-a）
TMUX_PREFIX="C-a"

# =========================
# ディレクトリ設定
# =========================

# Claudeタスク管理ディレクトリ
CLAUDE_TASKS_DIR="${PROJECT_ROOT}/claude-tasks"

# バックアップディレクトリ
BACKUP_DIR="${PROJECT_ROOT}/backups"

# ログディレクトリ
LOG_DIR="${PROJECT_ROOT}/logs"

# =========================
# タスク管理設定
# =========================

# タスクの優先度レベル
PRIORITY_LEVELS=("high" "medium" "low")

# デフォルトの優先度
DEFAULT_PRIORITY="medium"

# タスクの自動割り当て方法
# balanced: 均等に割り当て
# priority: 優先度に基づいて割り当て
# manual: 手動割り当てのみ
TASK_ASSIGNMENT_METHOD="balanced"

# =========================
# レビュー設定
# =========================

# 自動レビューチェック項目
AUTO_REVIEW_CHECKS=(
    "console.log検出:JavaScript"
    "print文検出:Python"
    "TODO/FIXME検出:全言語"
    "ハードコード認証情報:全言語"
)

# レビュー承認後の自動統合
AUTO_INTEGRATION=false

# =========================
# 通知設定
# =========================

# 進捗通知間隔（秒）
PROGRESS_NOTIFICATION_INTERVAL=1800  # 30分

# 問題発生時の通知
ISSUE_NOTIFICATION=true

# =========================
# 開発環境設定
# =========================

# 使用する言語/フレームワーク
TECH_STACK=(
    "言語:JavaScript/TypeScript"
    "フロントエンド:React"
    "バックエンド:Node.js"
    "データベース:PostgreSQL"
)

# コーディング規約
CODING_STANDARDS=(
    "インデント:スペース2つ"
    "命名規則:camelCase"
    "最大行長:100文字"
)

# =========================
# デバッグ設定
# =========================

# デバッグモード（詳細なログ出力）
DEBUG_MODE=false

# ドライラン（実際の変更を行わない）
DRY_RUN=false

# =========================
# カスタム設定
# =========================

# プロジェクト固有の設定をここに追加
# 例:
# API_ENDPOINT="https://api.example.com"
# DATABASE_NAME="myproject_db"

# =========================
# 関数定義
# =========================

# プロジェクト固有の初期化処理
custom_init() {
    # ここにプロジェクト固有の初期化処理を記述
    # 例: 特定のディレクトリ作成、設定ファイルのコピーなど
    return 0
}

# プロジェクト固有の検証処理
custom_validate() {
    # ここにプロジェクト固有の検証処理を記述
    # 例: 必要なツールの存在確認、権限チェックなど
    return 0
}