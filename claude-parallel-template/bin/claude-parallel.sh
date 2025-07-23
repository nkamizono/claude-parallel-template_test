#!/bin/bash

# Claude Code並列実行用tmuxスクリプト

# セッション名
SESSION="claude-parallel"

# tmuxセッションが既に存在するかチェック
tmux has-session -t $SESSION 2>/dev/null

if [ $? != 0 ]; then
    # セッションが存在しない場合は新規作成
    
    # 新しいセッションを作成（最初のウィンドウ）
    tmux new-session -d -s $SESSION -n "claude1"
    
    # 2つ目のウィンドウを作成
    tmux new-window -t $SESSION:2 -n "claude2"
    
    # 3つ目のウィンドウを作成
    tmux new-window -t $SESSION:3 -n "claude3"
    
    # 4つ目のウィンドウを作成
    tmux new-window -t $SESSION:4 -n "claude4"
    
    # 各ウィンドウでClaude Codeを起動（権限確認をスキップ）
    tmux send-keys -t $SESSION:1 "claude --dangerously-skip-permissions" C-m
    tmux send-keys -t $SESSION:2 "claude --dangerously-skip-permissions" C-m
    tmux send-keys -t $SESSION:3 "claude --dangerously-skip-permissions" C-m
    tmux send-keys -t $SESSION:4 "claude --dangerously-skip-permissions" C-m
    
    # レイアウトモード：4分割表示用のウィンドウを作成
    tmux new-window -t $SESSION:5 -n "4-panel"
    
    # 4分割レイアウトを作成
    tmux split-window -t $SESSION:5 -h
    tmux split-window -t $SESSION:5.0 -v
    tmux split-window -t $SESSION:5.1 -v
    
    # 各ペインでClaude Codeを起動（権限確認をスキップ）
    tmux send-keys -t $SESSION:5.0 "claude --dangerously-skip-permissions" C-m
    tmux send-keys -t $SESSION:5.1 "claude --dangerously-skip-permissions" C-m
    tmux send-keys -t $SESSION:5.2 "claude --dangerously-skip-permissions" C-m
    tmux send-keys -t $SESSION:5.3 "claude --dangerously-skip-permissions" C-m
    
    # 最初のウィンドウを選択
    tmux select-window -t $SESSION:1
fi

# セッションにアタッチ
tmux attach-session -t $SESSION