#!/bin/bash
# Claude並列開発用tmuxセッションセットアップスクリプト

# tmuxセッション名
SESSION="claude-parallel-dev"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 現在のディレクトリを保存
BASE_DIR=$(pwd)

echo -e "${BLUE}=== Claude並列開発tmuxセッション作成 ===${NC}"

# 既存セッションを削除
tmux kill-session -t $SESSION 2>/dev/null

# 新しいセッションを作成
echo -e "${GREEN}✓ セッション作成中...${NC}"
tmux new-session -d -s $SESSION -n "parent"

# 親Claude用ウィンドウ
tmux send-keys -t $SESSION:0 "cd $BASE_DIR/worktree-parent" C-m
tmux send-keys -t $SESSION:0 "echo -e '${YELLOW}親Claude用worktree (feature/integration)${NC}'" C-m
tmux send-keys -t $SESSION:0 "echo '役割: 各子Claudeの成果物を統合し、全体の整合性を確保'" C-m
tmux send-keys -t $SESSION:0 "echo ''" C-m
tmux send-keys -t $SESSION:0 "echo 'Claudeを起動するには: claude と入力'" C-m

# 子Claude1用ウィンドウ（要件担当）
tmux new-window -t $SESSION:1 -n "child1-req"
tmux send-keys -t $SESSION:1 "cd $BASE_DIR/worktree-child1" C-m
tmux send-keys -t $SESSION:1 "echo -e '${YELLOW}子Claude1用worktree (feature/requirements)${NC}'" C-m
tmux send-keys -t $SESSION:1 "echo '役割: requirements.md（要件定義書）の作成'" C-m
tmux send-keys -t $SESSION:1 "echo ''" C-m
tmux send-keys -t $SESSION:1 "echo 'Claudeを起動するには: claude と入力'" C-m

# 子Claude2用ウィンドウ（設計担当）
tmux new-window -t $SESSION:2 -n "child2-design"
tmux send-keys -t $SESSION:2 "cd $BASE_DIR/worktree-child2" C-m
tmux send-keys -t $SESSION:2 "echo -e '${YELLOW}子Claude2用worktree (feature/design)${NC}'" C-m
tmux send-keys -t $SESSION:2 "echo '役割: design.md（設計書）の作成'" C-m
tmux send-keys -t $SESSION:2 "echo ''" C-m
tmux send-keys -t $SESSION:2 "echo 'Claudeを起動するには: claude と入力'" C-m

# 子Claude3用ウィンドウ（実装担当）
tmux new-window -t $SESSION:3 -n "child3-impl"
tmux send-keys -t $SESSION:3 "cd $BASE_DIR/worktree-child3" C-m
tmux send-keys -t $SESSION:3 "echo -e '${YELLOW}子Claude3用worktree (feature/implementation)${NC}'" C-m
tmux send-keys -t $SESSION:3 "echo '役割: tasks.md（実装タスク管理書）の作成'" C-m
tmux send-keys -t $SESSION:3 "echo ''" C-m
tmux send-keys -t $SESSION:3 "echo 'Claudeを起動するには: claude と入力'" C-m

# 管理ウィンドウ
tmux new-window -t $SESSION:4 -n "management"
tmux send-keys -t $SESSION:4 "cd $BASE_DIR" C-m
tmux send-keys -t $SESSION:4 "echo -e '${BLUE}=== Git Worktree管理ウィンドウ ===${NC}'" C-m
tmux send-keys -t $SESSION:4 "git worktree list" C-m
tmux send-keys -t $SESSION:4 "echo ''" C-m
tmux send-keys -t $SESSION:4 "echo '有用なコマンド:'" C-m
tmux send-keys -t $SESSION:4 "echo '  git worktree list     - worktree一覧'" C-m
tmux send-keys -t $SESSION:4 "echo '  git branch -a         - ブランチ一覧'" C-m
tmux send-keys -t $SESSION:4 "echo '  git log --oneline -5  - 最新のコミット'" C-m

echo -e "${GREEN}✓ tmuxセッション作成完了！${NC}"
echo ""
echo "使い方:"
echo "  1. セッションにアタッチ: tmux attach-session -t $SESSION"
echo "  2. ウィンドウ切り替え:"
echo "     - Ctrl+b → 0-4 : ウィンドウ番号で切り替え"
echo "     - Ctrl+b → n   : 次のウィンドウ"
echo "     - Ctrl+b → p   : 前のウィンドウ"
echo "  3. 各ウィンドウで claude コマンドを実行してClaudeセッションを開始"
echo ""
echo "ウィンドウ構成:"
echo "  0: parent       - 親Claude（統合担当）"
echo "  1: child1-req   - 子Claude1（要件担当）"
echo "  2: child2-design - 子Claude2（設計担当）"
echo "  3: child3-impl  - 子Claude3（実装担当）"
echo "  4: management   - Git管理用"

# セッションにアタッチするか確認
echo ""
read -p "今すぐセッションにアタッチしますか？ (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    tmux attach-session -t $SESSION
fi