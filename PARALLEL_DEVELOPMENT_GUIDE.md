# 並列開発の詳細実行手順

## 前提条件の確認

現在の状態:
- Git Worktreeが4つ作成済み（parent, child1, child2, child3）
- 各worktreeは独自のブランチを持つ
- 開発仕様書（development-spec.md）が作成済み

## ステップ1: 各Claudeセッションの開始

### 方法1: ターミナルを4つ開く方法（推奨）

1. **ターミナル1 - 子Claude1（要件担当）**
   ```bash
   cd /Users/kamizononaoya/Documents/Dev/claude-parallel-template_test/claude-parallel-template_test/worktree-child1
   claude
   ```
   
   初期メッセージ例:
   ```
   私は子Claude1です。feature/requirementsブランチで作業します。
   development-spec.mdに基づいて、Todoアプリケーションのrequirements.mdを作成します。
   ```

2. **ターミナル2 - 子Claude2（設計担当）**
   ```bash
   cd /Users/kamizononaoya/Documents/Dev/claude-parallel-template_test/claude-parallel-template_test/worktree-child2
   claude
   ```
   
   初期メッセージ例:
   ```
   私は子Claude2です。feature/designブランチで作業します。
   子Claude1が作成するrequirements.mdを確認後、design.mdを作成します。
   ```

3. **ターミナル3 - 子Claude3（実装担当）**
   ```bash
   cd /Users/kamizononaoya/Documents/Dev/claude-parallel-template_test/claude-parallel-template_test/worktree-child3
   claude
   ```
   
   初期メッセージ例:
   ```
   私は子Claude3です。feature/implementationブランチで作業します。
   requirements.mdとdesign.mdを確認後、tasks.mdを作成します。
   ```

4. **ターミナル4 - 親Claude（統合担当）**
   ```bash
   cd /Users/kamizononaoya/Documents/Dev/claude-parallel-template_test/claude-parallel-template_test/worktree-parent
   claude
   ```
   
   初期メッセージ例:
   ```
   私は親Claudeです。feature/integrationブランチで作業します。
   各子Claudeの成果物を統合し、全体の整合性を確保します。
   ```

### 方法2: tmuxを使用する方法

1. **tmuxセッションを作成**
   ```bash
   # tmuxセッション作成スクリプト
   cat > setup-tmux.sh << 'EOF'
   #!/bin/bash
   SESSION="claude-parallel"
   
   # 既存セッションを削除
   tmux kill-session -t $SESSION 2>/dev/null
   
   # 新しいセッションを作成
   tmux new-session -d -s $SESSION -n "child1-req"
   tmux send-keys -t $SESSION:0 "cd worktree-child1" C-m
   
   tmux new-window -t $SESSION:1 -n "child2-design"
   tmux send-keys -t $SESSION:1 "cd worktree-child2" C-m
   
   tmux new-window -t $SESSION:2 -n "child3-impl"
   tmux send-keys -t $SESSION:2 "cd worktree-child3" C-m
   
   tmux new-window -t $SESSION:3 -n "parent"
   tmux send-keys -t $SESSION:3 "cd worktree-parent" C-m
   
   # セッションにアタッチ
   tmux attach-session -t $SESSION
   EOF
   
   chmod +x setup-tmux.sh
   ./setup-tmux.sh
   ```

2. **tmux内でウィンドウを切り替え**
   - `Ctrl+b` + `0-3`: ウィンドウ切り替え
   - `Ctrl+b` + `n`: 次のウィンドウ
   - `Ctrl+b` + `p`: 前のウィンドウ

## ステップ2: 各Claudeの作業手順

### 子Claude1の作業（要件定義）

1. **requirements.mdの作成**
   ```bash
   # worktree-child1で実行
   cat > docs/requirements.md << 'EOF'
   # Todoアプリケーション要件定義書
   
   ## ビジネス要求
   - シンプルで使いやすいタスク管理
   - 個人利用を想定
   
   ## ユーザーストーリー
   1. ユーザーとして、新しいTodoを追加したい
   2. ユーザーとして、Todoを完了にマークしたい
   3. ユーザーとして、Todoを削除したい
   4. ユーザーとして、Todoをフィルタリングしたい
   
   ## 機能要件
   ### 基本機能
   - Todo項目の追加
   - Todo項目の完了/未完了の切り替え
   - Todo項目の削除
   - Todo項目の一覧表示
   
   ### フィルタリング機能
   - 全て表示
   - 未完了のみ表示
   - 完了のみ表示
   
   ## 非機能要件
   - レスポンシブデザイン
   - ローカルストレージでのデータ永続化
   - 高速な操作レスポンス（100ms以内）
   EOF
   ```

2. **コミットとプッシュ**
   ```bash
   git add docs/requirements.md
   git commit -m "feat(req): Todoアプリの要件定義を追加 #REQ001"
   git push origin feature/requirements
   ```

### 子Claude2の作業（設計）

1. **最新の要件を取得**
   ```bash
   # worktree-child2で実行
   git fetch origin
   git checkout origin/feature/requirements -- docs/requirements.md
   ```

2. **design.mdの作成**
   ```bash
   cat > docs/design.md << 'EOF'
   # Todoアプリケーション設計書
   
   ## アーキテクチャ
   - フロントエンド: React + TypeScript
   - 状態管理: Context API
   - データ永続化: LocalStorage
   
   ## コンポーネント設計
   ### TodoApp（メインコンポーネント）
   - TodoList
   - TodoItem
   - AddTodo
   - FilterButtons
   
   ## データモデル
   ```typescript
   interface Todo {
     id: string;
     text: string;
     completed: boolean;
     createdAt: Date;
   }
   
   interface TodoState {
     todos: Todo[];
     filter: 'all' | 'active' | 'completed';
   }
   ```
   
   ## API設計（Context）
   - addTodo(text: string): void
   - toggleTodo(id: string): void
   - deleteTodo(id: string): void
   - setFilter(filter: FilterType): void
   EOF
   ```

3. **コミットとプッシュ**
   ```bash
   git add docs/design.md docs/requirements.md
   git commit -m "design: Todoアプリのシステム設計を追加 #DESIGN001"
   git push origin feature/design
   ```

### 子Claude3の作業（実装タスク）

1. **最新のドキュメントを取得**
   ```bash
   # worktree-child3で実行
   git fetch origin
   git checkout origin/feature/requirements -- docs/requirements.md
   git checkout origin/feature/design -- docs/design.md
   ```

2. **tasks.mdの作成**
   ```bash
   cat > docs/tasks.md << 'EOF'
   # Todoアプリケーション実装タスク
   
   ## タスクリスト
   
   ### 環境構築（2h）
   - [ ] TASK001: Viteプロジェクトの初期化
   - [ ] TASK002: TypeScript設定
   - [ ] TASK003: ESLint/Prettier設定
   - [ ] TASK004: Tailwind CSS設定
   
   ### コンポーネント実装（6h）
   - [ ] TASK005: TodoItemコンポーネント
   - [ ] TASK006: TodoListコンポーネント
   - [ ] TASK007: AddTodoコンポーネント
   - [ ] TASK008: FilterButtonsコンポーネント
   - [ ] TASK009: TodoAppメインコンポーネント
   
   ### 状態管理（3h）
   - [ ] TASK010: TodoContextの実装
   - [ ] TASK011: LocalStorage連携
   
   ### テスト（2h）
   - [ ] TASK012: ユニットテスト作成
   - [ ] TASK013: 統合テスト作成
   
   ## 優先順位
   1. 環境構築（TASK001-004）
   2. 状態管理（TASK010-011）
   3. コンポーネント実装（TASK005-009）
   4. テスト（TASK012-013）
   EOF
   ```

3. **コミットとプッシュ**
   ```bash
   git add docs/tasks.md docs/requirements.md docs/design.md
   git commit -m "task: Todoアプリの実装タスクを追加 #TASK001-013"
   git push origin feature/implementation
   ```

### 親Claudeの作業（統合）

1. **全ての変更を統合**
   ```bash
   # worktree-parentで実行
   git fetch origin
   git merge origin/feature/requirements --no-ff -m "merge: 要件定義を統合"
   git merge origin/feature/design --no-ff -m "merge: 設計ドキュメントを統合"
   git merge origin/feature/implementation --no-ff -m "merge: 実装タスクを統合"
   ```

2. **整合性確認スクリプトの作成と実行**
   ```bash
   cat > check-consistency.sh << 'EOF'
   #!/bin/bash
   echo "=== ドキュメント整合性チェック ==="
   
   # ファイルの存在確認
   for file in docs/requirements.md docs/design.md docs/tasks.md; do
     if [ -f "$file" ]; then
       echo "✓ $file exists"
     else
       echo "✗ $file missing"
       exit 1
     fi
   done
   
   # 相互参照の確認
   echo -e "\n=== 相互参照チェック ==="
   grep -q "requirements.md" docs/design.md && echo "✓ design.md references requirements.md"
   grep -q "design.md" docs/tasks.md && echo "✓ tasks.md references design.md"
   
   echo -e "\n=== チェック完了 ==="
   EOF
   
   chmod +x check-consistency.sh
   ./check-consistency.sh
   ```

3. **統合結果をプッシュ**
   ```bash
   git push origin feature/integration
   ```

## ステップ3: 継続的な同期と協調

### 定期的な同期（各Claude共通）

```bash
# 30分ごとに実行
git fetch origin
git pull origin develop --rebase
```

### 他のClaudeの変更を確認

```bash
# 特定のファイルを他のブランチから取得
git checkout origin/feature/requirements -- docs/requirements.md
```

### 進捗の共有

```bash
# 各Claudeで進捗を記録
echo "- $(date): TASK001完了" >> progress.log
git add progress.log
git commit -m "progress: TASK001を完了"
git push
```

## トラブルシューティング

### 1. マージコンフリクトが発生した場合

```bash
# コンフリクトを解決
git status  # コンフリクトファイルを確認
# エディタでコンフリクトを解決
git add .
git rebase --continue
```

### 2. ブランチが最新でない場合

```bash
git fetch origin
git rebase origin/develop
```

### 3. Worktreeが動作しない場合

```bash
git worktree prune
git worktree list
```

## ベストプラクティス

1. **頻繁なコミット**: 小さな変更ごとにコミット
2. **明確なコミットメッセージ**: 役割とタスクIDを含める
3. **定期的な同期**: 30分ごとに最新を取得
4. **ドキュメントの相互参照**: 関連箇所を明記
5. **進捗の可視化**: progress.logで共有

これらの手順に従って、効率的な並列開発を実施してください。