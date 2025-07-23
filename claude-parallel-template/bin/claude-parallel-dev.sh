#!/bin/bash

# Claude並列開発統合スクリプト
# 開発設計書に基づいて親Claudeと子Claudeで並列開発を実行

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# セッション名
SESSION="claude-parallel-dev"

# プロジェクトディレクトリ
PROJECT_ROOT="$(pwd)"
CLAUDE_TASKS_DIR="${PROJECT_ROOT}/claude-tasks"

# 初期セットアップ
setup_project() {
    echo -e "${BLUE}=== プロジェクトセットアップ ===${NC}"
    
    # タスク管理システムの初期化
    ./claude-task-manager.sh --init
    
    # 開発設計書が存在するか確認
    if [ ! -f "development-spec.md" ]; then
        echo -e "${YELLOW}development-spec.md が見つかりません。テンプレートをコピーしますか？ (y/n)${NC}"
        read -n 1 confirm
        echo
        if [ "$confirm" = "y" ]; then
            cp development-spec-template.md development-spec.md
            echo -e "${GREEN}テンプレートをコピーしました。development-spec.md を編集してください。${NC}"
            return 1
        fi
    fi
    
    # 設計書を自動分割
    echo -e "${BLUE}設計書を解析してタスクを分割中...${NC}"
    python3 spec-splitter.py development-spec.md -o claude-tasks -g
    
    echo -e "${GREEN}セットアップ完了！${NC}"
}

# tmuxセッションの作成
create_tmux_session() {
    echo -e "${BLUE}=== tmuxセッション作成 ===${NC}"
    
    # 既存セッションをチェック
    tmux has-session -t $SESSION 2>/dev/null
    if [ $? = 0 ]; then
        echo -e "${YELLOW}既存のセッションが見つかりました。削除しますか？ (y/n)${NC}"
        read -n 1 confirm
        echo
        if [ "$confirm" = "y" ]; then
            tmux kill-session -t $SESSION
        else
            return 1
        fi
    fi
    
    # 新しいセッションを作成
    tmux new-session -d -s $SESSION -n "parent-claude"
    
    # 親Claude用ウィンドウ設定
    tmux send-keys -t $SESSION:1 "clear" C-m
    tmux send-keys -t $SESSION:1 "echo -e '${MAGENTA}=== 親Claude ===${NC}'" C-m
    tmux send-keys -t $SESSION:1 "echo '役割: プロジェクト統括、タスク管理、レビュー'" C-m
    tmux send-keys -t $SESSION:1 "echo ''" C-m
    tmux send-keys -t $SESSION:1 "cat claude-tasks/parent/tasks.md" C-m
    tmux send-keys -t $SESSION:1 "echo ''" C-m
    tmux send-keys -t $SESSION:1 "echo '準備ができたら以下のコマンドでClaude Codeを起動:'" C-m
    tmux send-keys -t $SESSION:1 "echo 'claude --dangerously-skip-permissions'" C-m
    
    # 子Claude1用ウィンドウ
    tmux new-window -t $SESSION:2 -n "child1-claude"
    tmux send-keys -t $SESSION:2 "clear" C-m
    tmux send-keys -t $SESSION:2 "echo -e '${CYAN}=== 子Claude1 ===${NC}'" C-m
    tmux send-keys -t $SESSION:2 "echo '役割: 割り当てられたタスクの実装'" C-m
    tmux send-keys -t $SESSION:2 "echo ''" C-m
    tmux send-keys -t $SESSION:2 "cat claude-tasks/child1/tasks.md" C-m
    tmux send-keys -t $SESSION:2 "echo ''" C-m
    tmux send-keys -t $SESSION:2 "echo '準備ができたら以下のコマンドでClaude Codeを起動:'" C-m
    tmux send-keys -t $SESSION:2 "echo 'claude --dangerously-skip-permissions'" C-m
    
    # 子Claude2用ウィンドウ
    tmux new-window -t $SESSION:3 -n "child2-claude"
    tmux send-keys -t $SESSION:3 "clear" C-m
    tmux send-keys -t $SESSION:3 "echo -e '${CYAN}=== 子Claude2 ===${NC}'" C-m
    tmux send-keys -t $SESSION:3 "echo '役割: 割り当てられたタスクの実装'" C-m
    tmux send-keys -t $SESSION:3 "echo ''" C-m
    tmux send-keys -t $SESSION:3 "cat claude-tasks/child2/tasks.md" C-m
    tmux send-keys -t $SESSION:3 "echo ''" C-m
    tmux send-keys -t $SESSION:3 "echo '準備ができたら以下のコマンドでClaude Codeを起動:'" C-m
    tmux send-keys -t $SESSION:3 "echo 'claude --dangerously-skip-permissions'" C-m
    
    # 管理ツール用ウィンドウ
    tmux new-window -t $SESSION:4 -n "management"
    tmux send-keys -t $SESSION:4 "clear" C-m
    tmux send-keys -t $SESSION:4 "echo -e '${YELLOW}=== 管理ツール ===${NC}'" C-m
    tmux send-keys -t $SESSION:4 "echo '利用可能なコマンド:'" C-m
    tmux send-keys -t $SESSION:4 "echo '  ./claude-task-manager.sh    - タスク管理'" C-m
    tmux send-keys -t $SESSION:4 "echo '  ./claude-review-system.sh   - レビューシステム'" C-m
    tmux send-keys -t $SESSION:4 "echo '  ./check-progress.sh         - 進捗確認'" C-m
    tmux send-keys -t $SESSION:4 "echo ''" C-m
    
    # モニタリング用ウィンドウ（4分割）
    tmux new-window -t $SESSION:5 -n "monitoring"
    
    # 4分割レイアウトを作成
    tmux split-window -t $SESSION:5 -h
    tmux split-window -t $SESSION:5.0 -v
    tmux split-window -t $SESSION:5.1 -v
    
    # 各ペインでモニタリングコマンドを実行
    # 左上: 進捗状況
    tmux send-keys -t $SESSION:5.0 "watch -n 30 'echo -e \"${BLUE}=== 進捗状況 ===${NC}\"; tail -20 claude-tasks/shared/progress.md 2>/dev/null || echo \"進捗なし\"'" C-m
    
    # 右上: 問題リスト
    tmux send-keys -t $SESSION:5.1 "watch -n 30 'echo -e \"${RED}=== 問題リスト ===${NC}\"; cat claude-tasks/shared/issues.md 2>/dev/null || echo \"問題なし\"'" C-m
    
    # 左下: ファイル変更監視
    tmux send-keys -t $SESSION:5.2 "watch -n 10 'echo -e \"${GREEN}=== 最近の変更 ===${NC}\"; find claude-tasks -name \"*.md\" -mmin -30 -type f 2>/dev/null | head -10'" C-m
    
    # 右下: タスク統計
    tmux send-keys -t $SESSION:5.3 "watch -n 60 './claude-task-manager.sh --status 2>/dev/null || echo \"統計情報なし\"'" C-m
    
    # 最初のウィンドウを選択
    tmux select-window -t $SESSION:1
    
    echo -e "${GREEN}tmuxセッション作成完了！${NC}"
}

# 進捗確認スクリプト
create_progress_checker() {
    cat > check-progress.sh << 'EOF'
#!/bin/bash

# 進捗確認スクリプト

echo -e "\033[0;34m=== Claude並列開発進捗レポート ===\033[0m"
echo "レポート生成時刻: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# タスク統計
echo -e "\033[1;33m## タスク統計\033[0m"
for role in parent child1 child2; do
    echo -n "$role: "
    todo=$(ls -1 claude-tasks/$role/todo/ 2>/dev/null | wc -l)
    progress=$(ls -1 claude-tasks/$role/in-progress/ 2>/dev/null | wc -l)
    done=$(ls -1 claude-tasks/$role/completed/ 2>/dev/null | wc -l)
    review=$(ls -1 claude-tasks/$role/review/ 2>/dev/null | wc -l)
    total=$((todo + progress + done + review))
    
    if [ $total -gt 0 ]; then
        completion=$((done * 100 / total))
        echo "完了率 $completion% (完了:$done/全体:$total)"
    else
        echo "タスクなし"
    fi
done

echo ""
echo -e "\033[1;33m## 最新の進捗\033[0m"
tail -10 claude-tasks/shared/progress.md 2>/dev/null || echo "進捗報告なし"

echo ""
echo -e "\033[1;33m## アクティブな問題\033[0m"
if [ -f claude-tasks/shared/issues.md ]; then
    grep -E "^##|緊急度: 高" claude-tasks/shared/issues.md | tail -5
else
    echo "報告された問題なし"
fi
EOF
    
    chmod +x check-progress.sh
}

# 使用方法の表示
show_usage() {
    echo -e "${BLUE}=== Claude並列開発システム使用方法 ===${NC}"
    echo ""
    echo "1. 開発設計書(development-spec.md)を準備"
    echo "2. このスクリプトを実行して環境をセットアップ"
    echo "3. tmuxセッション内で各Claudeインスタンスを起動"
    echo "4. 管理ツールを使ってタスクの進捗を管理"
    echo ""
    echo -e "${YELLOW}主要なコマンド:${NC}"
    echo "  ./claude-parallel-dev.sh setup    - 初期セットアップ"
    echo "  ./claude-parallel-dev.sh start    - 開発セッション開始"
    echo "  ./claude-parallel-dev.sh status   - 進捗確認"
    echo "  ./claude-parallel-dev.sh help     - ヘルプ表示"
    echo ""
    echo -e "${YELLOW}tmux操作:${NC}"
    echo "  Ctrl-a → 数字     - ウィンドウ切り替え"
    echo "  Ctrl-a → d        - セッションから離脱"
    echo "  tmux a -t claude-parallel-dev  - 再接続"
}

# メイン処理
case "$1" in
    setup)
        setup_project
        create_progress_checker
        echo -e "${GREEN}セットアップ完了！'./claude-parallel-dev.sh start' で開発を開始してください。${NC}"
        ;;
    start)
        if [ ! -d "$CLAUDE_TASKS_DIR" ]; then
            echo -e "${RED}エラー: 先に 'setup' を実行してください${NC}"
            exit 1
        fi
        create_tmux_session
        echo -e "${GREEN}開発セッションを開始しています...${NC}"
        tmux attach-session -t $SESSION
        ;;
    status)
        if [ -f "check-progress.sh" ]; then
            ./check-progress.sh
        else
            echo -e "${RED}エラー: 進捗確認スクリプトが見つかりません。'setup' を実行してください。${NC}"
        fi
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo -e "${YELLOW}使用方法: $0 {setup|start|status|help}${NC}"
        echo "詳細は '$0 help' を参照してください"
        exit 1
        ;;
esac