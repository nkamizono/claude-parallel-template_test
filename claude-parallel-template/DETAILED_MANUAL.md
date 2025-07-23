# Claude並列開発システム 詳細操作マニュアル（Git Worktree版）

## 目次

1. [はじめに](#はじめに)
2. [システム概要](#システム概要)
3. [Git Worktreeによる並列開発環境](#git-worktreeによる並列開発環境)
4. [初期セットアップ](#初期セットアップ)
5. [開発フロー詳細](#開発フロー詳細)
6. [各Claudeの具体的な操作手順](#各claudeの具体的な操作手順)
7. [実践的な使用例](#実践的な使用例)
8. [トラブルシューティング](#トラブルシューティング)
9. [ベストプラクティス](#ベストプラクティス)

---

## はじめに

このマニュアルでは、Git Worktreeを活用したClaude並列開発システムの使用方法を説明します。Git Worktreeを使うことで、各Claudeが独立したワークスペースで作業でき、ファイルの競合を防ぎながら効率的な並列開発が可能になります。

### Git Worktreeの利点

- **独立したワークスペース**: 各Claudeが専用のディレクトリで作業
- **ブランチの同時作業**: 複数のブランチを同時に開いて作業可能
- **競合の回避**: ファイルの同時編集による競合を物理的に防止
- **高速な切り替え**: ブランチ切り替えなしで複数の作業を並行実施

## システム概要

### アーキテクチャ

```
メインリポジトリ (main)
├── worktree-parent/     # 親Claude用 (feature/integration)
├── worktree-child1/     # 子Claude1用 (feature/requirements)
├── worktree-child2/     # 子Claude2用 (feature/design)
└── worktree-child3/     # 子Claude3用 (feature/implementation)

各worktreeは独立したブランチで作業:
- 親Claude: 統合とレビュー
- 子Claude1: requirements.md担当
- 子Claude2: design.md担当
- 子Claude3: tasks.md担当
```

### ブランチ戦略

```
main
├── develop
│   ├── feature/integration (親Claude)
│   ├── feature/requirements (子Claude1)
│   ├── feature/design (子Claude2)
│   └── feature/implementation (子Claude3)
└── release/*
```

## Git Worktreeによる並列開発環境

### Worktreeの基本概念

Git Worktreeは、1つのリポジトリから複数の作業ディレクトリを作成し、それぞれで異なるブランチを同時に操作できる機能です。

```bash
# 基本的な使い方
git worktree add <path> <branch>
git worktree list
git worktree remove <path>
```

### 並列開発での活用

各Claudeが独自のworktreeで作業することで：
- ファイルの競合が発生しない
- 独立してコミット・プッシュが可能
- 他のClaudeの作業を妨げない

## 初期セットアップ

### ステップ1: プロジェクトの初期化

```bash
# メインリポジトリのクローン
git clone <repository-url> my-project
cd my-project

# developブランチの作成（まだない場合）
git checkout -b develop
git push -u origin develop
```

### ステップ2: 各Claude用のブランチとWorktreeの作成

```bash
# 親Claude用
git checkout -b feature/integration develop
git worktree add ../worktree-parent feature/integration

# 子Claude1用（要件担当）
git checkout -b feature/requirements develop
git worktree add ../worktree-child1 feature/requirements

# 子Claude2用（設計担当）
git checkout -b feature/design develop
git worktree add ../worktree-child2 feature/design

# 子Claude3用（実装担当）
git checkout -b feature/implementation develop
git worktree add ../worktree-child3 feature/implementation
```

### ステップ3: 各Worktreeの初期設定

```bash
# 各worktreeで必要なディレクトリ構造を作成
for worktree in worktree-parent worktree-child1 worktree-child2 worktree-child3; do
  cd ../$worktree
  mkdir -p docs claude-tasks/{todo,in-progress,completed,review}
  touch docs/{requirements.md,design.md,tasks.md}
  echo "# Worktree: $worktree" > README.md
  git add .
  git commit -m "初期セットアップ: $worktree"
done
```

### ステップ4: tmuxセッションの設定

```bash
#!/bin/bash
# setup-parallel-tmux.sh

# tmuxセッション名
SESSION="claude-parallel-dev"

# 既存セッションを削除
tmux kill-session -t $SESSION 2>/dev/null

# 新しいセッションを作成
tmux new-session -d -s $SESSION -n "parent"

# 親Claude用ウィンドウ
tmux send-keys -t $SESSION:0 "cd ../worktree-parent" C-m
tmux send-keys -t $SESSION:0 "echo '親Claude用worktree (feature/integration)'" C-m

# 子Claude1用ウィンドウ
tmux new-window -t $SESSION:1 -n "child1-req"
tmux send-keys -t $SESSION:1 "cd ../worktree-child1" C-m
tmux send-keys -t $SESSION:1 "echo '子Claude1用worktree (feature/requirements)'" C-m

# 子Claude2用ウィンドウ
tmux new-window -t $SESSION:2 -n "child2-design"
tmux send-keys -t $SESSION:2 "cd ../worktree-child2" C-m
tmux send-keys -t $SESSION:2 "echo '子Claude2用worktree (feature/design)'" C-m

# 子Claude3用ウィンドウ
tmux new-window -t $SESSION:3 -n "child3-impl"
tmux send-keys -t $SESSION:3 "cd ../worktree-child3" C-m
tmux send-keys -t $SESSION:3 "echo '子Claude3用worktree (feature/implementation)'" C-m

# 管理ウィンドウ
tmux new-window -t $SESSION:4 -n "management"
tmux send-keys -t $SESSION:4 "cd .." C-m
tmux send-keys -t $SESSION:4 "git worktree list" C-m

# セッションにアタッチ
tmux attach-session -t $SESSION
```

## 開発フロー詳細

### 1. 作業開始前の同期

各Claudeは作業開始前に最新の状態に同期：

```bash
# 各worktreeで実行
git fetch origin
git pull origin develop --rebase
```

### 2. 独立した作業

#### 子Claude1（要件担当）の作業
```bash
cd ../worktree-child1
# requirements.mdの編集
vim docs/requirements.md
git add docs/requirements.md
git commit -m "feat(req): ユーザー認証要件を追加 #REQ001"
git push origin feature/requirements
```

#### 子Claude2（設計担当）の作業
```bash
cd ../worktree-child2
# 最新の要件を取得
git fetch origin
git checkout origin/feature/requirements -- docs/requirements.md
# design.mdの編集
vim docs/design.md
git add docs/design.md
git commit -m "design: REQ001に対応する認証システム設計を追加"
git push origin feature/design
```

#### 子Claude3（実装担当）の作業
```bash
cd ../worktree-child3
# 最新の設計を取得
git fetch origin
git checkout origin/feature/design -- docs/design.md
# tasks.mdの編集
vim docs/tasks.md
git add docs/tasks.md
git commit -m "task: 認証機能の実装タスクを追加 #TASK001"
git push origin feature/implementation
```

### 3. 親Claudeによる統合

```bash
cd ../worktree-parent

# 各子Claudeの変更を統合
git fetch origin
git merge origin/feature/requirements --no-ff -m "merge: 要件定義を統合"
git merge origin/feature/design --no-ff -m "merge: 設計ドキュメントを統合"
git merge origin/feature/implementation --no-ff -m "merge: 実装タスクを統合"

# 整合性確認
./check-consistency.sh

# 問題なければプッシュ
git push origin feature/integration
```

### 4. 定期的な同期ポイント

```bash
# 同期スクリプト (sync-all-worktrees.sh)
#!/bin/bash

WORKTREES=("worktree-parent" "worktree-child1" "worktree-child2" "worktree-child3")
BASE_BRANCH="develop"

for worktree in "${WORKTREES[@]}"; do
  echo "=== Syncing $worktree ==="
  cd ../$worktree
  git fetch origin
  git pull origin $BASE_BRANCH --rebase
  echo ""
done
```

## 各Claudeの具体的な操作手順

### 親Claude（統合担当）の操作

#### 初回起動時
```bash
cd ../worktree-parent
claude --dangerously-skip-permissions

# 初期化メッセージ
私は親Claudeです。feature/integrationブランチで作業します。
各子Claudeの成果物を統合し、全体の整合性を確保します。
```

#### 日次統合作業
```bash
# 統合スクリプトの作成
cat > daily-integration.sh << 'EOF'
#!/bin/bash
echo "=== 日次統合開始 ==="

# 最新を取得
git fetch origin

# 各ブランチをマージ
for branch in feature/requirements feature/design feature/implementation; do
  echo "Merging $branch..."
  git merge origin/$branch --no-ff -m "daily: $branch を統合 $(date +%Y-%m-%d)"
done

# 整合性チェック
./check-consistency.sh

# 結果を表示
echo "=== 統合完了 ==="
git log --oneline -10
EOF

chmod +x daily-integration.sh
./daily-integration.sh
```

### 子Claude1（要件担当）の操作

#### 作業フロー
```bash
cd ../worktree-child1

# 1. 作業開始時の同期
git pull origin develop --rebase

# 2. 要件の追加
cat >> docs/requirements.md << 'EOF'

## 要件10: ユーザープロフィール機能
- **要件ID**: REQ010
- **優先度**: 高
- **ユーザーストーリー**: 
  ユーザーとして、自分のプロフィール情報を管理したい
- **受入基準**:
  1. プロフィール画像のアップロード
  2. 自己紹介文の編集
  3. 公開/非公開設定
- **制約事項**: 
  - 画像は最大5MB
  - GDPR準拠
EOF

# 3. コミットとプッシュ
git add docs/requirements.md
git commit -m "feat(req): プロフィール機能の要件を追加 #REQ010"
git push origin feature/requirements

# 4. 他のClaudeへの通知
echo "REQ010を追加しました。設計をお願いします。" > ../shared-notes/req-update.txt
```

### 子Claude2（設計担当）の操作

#### 要件に基づく設計作業
```bash
cd ../worktree-child2

# 1. 最新の要件を確認
git fetch origin
git show origin/feature/requirements:docs/requirements.md | grep -A 10 "REQ010"

# 2. 対応する設計を作成
cat >> docs/design.md << 'EOF'

## プロフィール機能設計
- **設計ID**: PROFILE001
- **関連要件**: requirements.md#REQ010
- **API設計**:
  ```yaml
  endpoints:
    - GET /api/users/{id}/profile
    - PUT /api/users/{id}/profile
    - POST /api/users/{id}/profile/image
  ```
- **データモデル**:
  ```typescript
  interface UserProfile {
    userId: string;
    bio: string;
    imageUrl: string;
    isPublic: boolean;
  }
  ```
EOF

# 3. コミットとプッシュ
git add docs/design.md
git commit -m "design: プロフィール機能の設計を追加 #PROFILE001"
git push origin feature/design
```

### 子Claude3（実装担当）の操作

#### タスクの作成
```bash
cd ../worktree-child3

# 1. 最新の設計を確認
git fetch origin
git show origin/feature/design:docs/design.md | grep -A 20 "PROFILE001"

# 2. 実装タスクを作成
cat >> docs/tasks.md << 'EOF'

### タスク10: プロフィール機能の実装
- **タスクID**: TASK010
- **関連要件**: requirements.md#REQ010
- **関連設計**: design.md#PROFILE001
- **サブタスク**:
  - [ ] DBスキーマ作成 (2h)
  - [ ] API実装 (4h)
  - [ ] フロントエンド実装 (6h)
  - [ ] テスト作成 (2h)
- **完了条件**: 
  - 全エンドポイントが動作
  - テストカバレッジ80%以上
EOF

# 3. コミットとプッシュ
git add docs/tasks.md
git commit -m "task: プロフィール機能の実装タスクを追加 #TASK010"
git push origin feature/implementation
```

## 実践的な使用例

### 例1: 機能開発の完全なフロー

#### 1. 要件定義から実装まで

```bash
# 親Claudeが新機能の開発を開始
cd ../worktree-parent
echo "## 新機能: 通知システム" > feature-brief.md
git add feature-brief.md
git commit -m "docs: 通知システムの概要を追加"
git push origin feature/integration

# 子Claude1が要件を定義
cd ../worktree-child1
# requirements.mdに通知システムの要件を追加
git add docs/requirements.md
git commit -m "feat(req): 通知システムの要件を追加 #REQ011-015"
git push origin feature/requirements

# 子Claude2が設計
cd ../worktree-child2
git fetch origin
# 要件を確認して設計を作成
git add docs/design.md
git commit -m "design: 通知システムの設計を追加 #NOTIF001"
git push origin feature/design

# 子Claude3がタスク化
cd ../worktree-child3
git fetch origin
# 設計を確認してタスクを作成
git add docs/tasks.md
git commit -m "task: 通知システムの実装タスクを追加 #TASK011-020"
git push origin feature/implementation
```

#### 2. 親Claudeによる統合とレビュー

```bash
cd ../worktree-parent

# 全ての変更を統合
git fetch origin
git merge origin/feature/requirements --no-ff
git merge origin/feature/design --no-ff
git merge origin/feature/implementation --no-ff

# レビューと調整
vim docs/review-notes.md
git add docs/review-notes.md
git commit -m "review: 通知システムの設計レビュー完了"

# developへのPR作成準備
git push origin feature/integration
# GitHub/GitLabでPRを作成
```

### 例2: 緊急バグ修正での並列作業

```bash
# バグ修正用の新しいworktreeを作成
git worktree add ../hotfix-auth hotfix/auth-bug

# 複数のClaudeで同時に作業
# Claude1: バグの原因調査
cd ../hotfix-auth
git checkout -b investigate/auth-bug
# 調査結果をドキュメント化

# Claude2: 修正の実装
cd ../worktree-child2
git checkout -b fix/auth-bug
# バグ修正の実装

# Claude3: テストの追加
cd ../worktree-child3
git checkout -b test/auth-bug
# リグレッションテストの追加

# 親Claudeが統合
cd ../worktree-parent
git fetch origin
git merge origin/investigate/auth-bug
git merge origin/fix/auth-bug
git merge origin/test/auth-bug
```

## トラブルシューティング

### Worktree関連の問題

#### 1. Worktreeが壊れた場合
```bash
# worktreeの状態確認
git worktree list

# 壊れたworktreeの修復
git worktree repair

# それでも解決しない場合は削除して再作成
git worktree remove ../worktree-child1
git worktree add ../worktree-child1 feature/requirements
```

#### 2. ブランチの競合
```bash
# 各worktreeで最新を取得
cd ../worktree-child1
git fetch origin
git rebase origin/develop

# コンフリクトが発生した場合
git status
# コンフリクトを解決
git add .
git rebase --continue
```

#### 3. Worktreeの移動
```bash
# worktreeを別の場所に移動
git worktree move ../worktree-child1 ../new-location/worktree-child1
```

### 同期の問題

#### 1. 他のClaudeの変更が見えない
```bash
# 強制的に最新を取得
git fetch origin --all
git log --all --oneline --graph

# 特定のファイルを他のブランチから取得
git checkout origin/feature/requirements -- docs/requirements.md
```

#### 2. プッシュできない
```bash
# リモートの状態を確認
git remote -v
git branch -vv

# 上流ブランチを設定
git push -u origin feature/requirements
```

## ベストプラクティス

### 1. Worktree管理

- **命名規則**: worktreeの名前は役割を明確に
- **定期的なクリーンアップ**: 不要なworktreeは削除
- **バックアップ**: 重要な変更は早めにプッシュ

```bash
# Worktreeの健全性チェックスクリプト
cat > check-worktrees.sh << 'EOF'
#!/bin/bash
echo "=== Worktree Status ==="
git worktree list

echo -e "\n=== Branch Status ==="
for dir in ../worktree-*; do
  if [ -d "$dir" ]; then
    echo -e "\n--- $dir ---"
    cd "$dir"
    git status -sb
    git log --oneline -1
  fi
done
EOF
```

### 2. ブランチ戦略

- **Feature Branchの寿命**: 1-2週間以内にマージ
- **定期的なrebase**: developからの乖離を防ぐ
- **明確なコミットメッセージ**: 役割と変更内容を明記

### 3. コミュニケーション

```bash
# 共有ノートシステム
mkdir -p ../shared-notes
cat > ../shared-notes/README.md << 'EOF'
# 共有ノート

## 本日の作業
- 親Claude: 統合とレビュー
- 子Claude1: REQ010-012の作成
- 子Claude2: PROFILE001の設計
- 子Claude3: TASK008-010の実装

## ブロッカー
- なし

## 次回同期: 15:00
EOF
```

### 4. 自動化

```bash
# 日次同期スクリプト
cat > daily-sync.sh << 'EOF'
#!/bin/bash
set -e

echo "=== Daily Sync Starting ==="
date

# 全worktreeで最新を取得
for worktree in ../worktree-*; do
  if [ -d "$worktree" ]; then
    echo -e "\nSyncing $worktree..."
    cd "$worktree"
    git fetch origin
    git pull origin develop --rebase || echo "Rebase needed for $worktree"
  fi
done

# ステータスレポート生成
echo -e "\n=== Status Report ==="
git worktree list
echo -e "\nSync completed at $(date)"
EOF

chmod +x daily-sync.sh
```

### 5. 品質管理

```bash
# Pre-pushフックの設定
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
# MDファイルの整合性チェック
if git diff --cached --name-only | grep -q "\.md$"; then
  echo "Checking MD files consistency..."
  ./check-consistency.sh || exit 1
fi
EOF

chmod +x .git/hooks/pre-push
```

## 高度な使用方法

### 複数プロジェクトの並列管理

```bash
# プロジェクトごとにworktree群を作成
git worktree add ../project-a/worktree-parent feature/project-a
git worktree add ../project-b/worktree-parent feature/project-b

# プロジェクト切り替えスクリプト
cat > switch-project.sh << 'EOF'
#!/bin/bash
PROJECT=$1
tmux send-keys -t claude-parallel-dev:0 "cd ../$PROJECT/worktree-parent" C-m
tmux send-keys -t claude-parallel-dev:1 "cd ../$PROJECT/worktree-child1" C-m
# ... 他のウィンドウも同様
EOF
```

### CI/CD連携

```yaml
# .github/workflows/parallel-dev.yml
name: Parallel Development CI

on:
  push:
    branches:
      - feature/requirements
      - feature/design
      - feature/implementation
      - feature/integration

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check consistency
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/feature/integration" ]]; then
            ./check-consistency.sh
          fi
      - name: Run tests
        run: |
          npm test
```

## まとめ

Git Worktreeを活用した並列開発により：

1. **独立性**: 各Claudeが干渉なく作業可能
2. **効率性**: ブランチ切り替えのオーバーヘッドなし
3. **安全性**: ファイル競合のリスクを排除
4. **柔軟性**: 必要に応じてworktreeを追加/削除
5. **透明性**: 各Claudeの作業が明確に分離

このワークフローにより、複数のClaudeが協調しながら、それぞれが最大のパフォーマンスを発揮できる開発環境を実現できます。