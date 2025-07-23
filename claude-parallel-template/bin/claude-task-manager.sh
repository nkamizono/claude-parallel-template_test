#!/bin/bash

# Claude並列開発タスク管理システム

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# プロジェクトルート
PROJECT_ROOT="$(pwd)"
CLAUDE_TASKS_DIR="${PROJECT_ROOT}/claude-tasks"

# ディレクトリ構造の初期化
init_project() {
    echo -e "${BLUE}プロジェクトディレクトリを初期化しています...${NC}"
    
    # メインディレクトリ作成
    mkdir -p "${CLAUDE_TASKS_DIR}"/{parent,child1,child2,shared}
    
    # 各Claudeの作業ディレクトリ作成
    for role in parent child1 child2; do
        mkdir -p "${CLAUDE_TASKS_DIR}/${role}"/{todo,in-progress,completed,review}
    done
    
    # 共有ディレクトリ作成
    mkdir -p "${CLAUDE_TASKS_DIR}/shared"/{instructions,progress,issues}
    
    # 初期ファイル作成
    touch "${CLAUDE_TASKS_DIR}/shared/progress.md"
    touch "${CLAUDE_TASKS_DIR}/shared/issues.md"
    
    echo -e "${GREEN}初期化完了！${NC}"
}

# タスクの割り当て
assign_task() {
    local claude_id=$1
    local task_id=$2
    local task_desc=$3
    
    echo -e "${YELLOW}タスク ${task_id} を ${claude_id} に割り当てています...${NC}"
    
    # タスクファイル作成
    cat > "${CLAUDE_TASKS_DIR}/${claude_id}/todo/${task_id}.md" << EOF
# タスク: ${task_id}

## 概要
${task_desc}

## 割り当て日時
$(date '+%Y-%m-%d %H:%M:%S')

## ステータス
TODO

## 作業指示
1. このタスクを開始する際は、in-progressディレクトリに移動してください
2. 完了したらcompletedディレクトリに成果物を配置してください
3. 問題がある場合はissues.mdに記録してください
EOF
    
    echo -e "${GREEN}タスク割り当て完了！${NC}"
}

# 進捗確認
check_progress() {
    echo -e "${BLUE}=== 進捗状況 ===${NC}"
    
    for role in parent child1 child2; do
        echo -e "\n${YELLOW}${role}:${NC}"
        echo "  TODO: $(ls -1 ${CLAUDE_TASKS_DIR}/${role}/todo/ 2>/dev/null | wc -l) タスク"
        echo "  作業中: $(ls -1 ${CLAUDE_TASKS_DIR}/${role}/in-progress/ 2>/dev/null | wc -l) タスク"
        echo "  完了: $(ls -1 ${CLAUDE_TASKS_DIR}/${role}/completed/ 2>/dev/null | wc -l) タスク"
        echo "  レビュー待ち: $(ls -1 ${CLAUDE_TASKS_DIR}/${role}/review/ 2>/dev/null | wc -l) タスク"
    done
    
    echo -e "\n${BLUE}最新の進捗報告:${NC}"
    tail -n 10 "${CLAUDE_TASKS_DIR}/shared/progress.md" 2>/dev/null || echo "進捗報告はまだありません"
}

# 問題確認
check_issues() {
    echo -e "${RED}=== 報告された問題 ===${NC}"
    cat "${CLAUDE_TASKS_DIR}/shared/issues.md" 2>/dev/null || echo "問題は報告されていません"
}

# 新しい指示を作成
create_instruction() {
    local instruction_title=$1
    local instruction_content=$2
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local filename="${CLAUDE_TASKS_DIR}/shared/instructions/instruction_${timestamp}.md"
    
    cat > "${filename}" << EOF
# 指示: ${instruction_title}

## 発行日時
$(date '+%Y-%m-%d %H:%M:%S')

## 内容
${instruction_content}

## 対象
全Claude

## 優先度
高
EOF
    
    echo -e "${GREEN}新しい指示を作成しました: ${filename}${NC}"
}

# タスクを完了に移動
complete_task() {
    local claude_id=$1
    local task_id=$2
    
    local in_progress_file="${CLAUDE_TASKS_DIR}/${claude_id}/in-progress/${task_id}.md"
    local completed_dir="${CLAUDE_TASKS_DIR}/${claude_id}/completed/"
    
    if [ -f "${in_progress_file}" ]; then
        mv "${in_progress_file}" "${completed_dir}"
        echo -e "${GREEN}タスク ${task_id} を完了に移動しました${NC}"
        
        # 進捗報告に追記
        echo -e "\n## $(date '+%Y-%m-%d %H:%M:%S')\n- ${claude_id} がタスク ${task_id} を完了" >> "${CLAUDE_TASKS_DIR}/shared/progress.md"
    else
        echo -e "${RED}エラー: タスク ${task_id} が作業中ディレクトリに見つかりません${NC}"
    fi
}

# メニュー表示
show_menu() {
    echo -e "\n${BLUE}=== Claude並列開発タスク管理 ===${NC}"
    echo "1) プロジェクト初期化"
    echo "2) タスク割り当て"
    echo "3) 進捗確認"
    echo "4) 問題確認"
    echo "5) 新しい指示を作成"
    echo "6) タスクを完了に移動"
    echo "7) 終了"
    echo -n "選択してください (1-7): "
}

# メイン処理
main() {
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                init_project
                ;;
            2)
                echo -n "Claude ID (parent/child1/child2): "
                read claude_id
                echo -n "タスクID: "
                read task_id
                echo -n "タスク説明: "
                read task_desc
                assign_task "$claude_id" "$task_id" "$task_desc"
                ;;
            3)
                check_progress
                ;;
            4)
                check_issues
                ;;
            5)
                echo -n "指示タイトル: "
                read instruction_title
                echo -n "指示内容: "
                read instruction_content
                create_instruction "$instruction_title" "$instruction_content"
                ;;
            6)
                echo -n "Claude ID (parent/child1/child2): "
                read claude_id
                echo -n "タスクID: "
                read task_id
                complete_task "$claude_id" "$task_id"
                ;;
            7)
                echo -e "${GREEN}終了します${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}無効な選択です${NC}"
                ;;
        esac
    done
}

# スクリプト実行
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "使用方法: $0 [オプション]"
    echo "オプション:"
    echo "  --init    プロジェクトディレクトリを初期化"
    echo "  --status  現在の進捗状況を表示"
    echo "  --help    このヘルプを表示"
else
    case "$1" in
        --init)
            init_project
            ;;
        --status)
            check_progress
            ;;
        *)
            main
            ;;
    esac
fi