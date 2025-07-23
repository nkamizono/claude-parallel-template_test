# Claude並列開発システム（Git Worktree版）

Git Worktreeを活用し、3つのMDファイル（requirements.md、design.md、tasks.md）を基軸に、親Claudeと3人の子Claudeで並列開発を行うシステムです。

## 概要

このシステムは以下の機能を提供します：

1. **Git Worktreeによる独立作業環境** - 各Claudeが専用のディレクトリとブランチで作業
2. **3つのMDファイルによる開発管理** - 要件・設計・タスクを分離して管理
3. **専門化された並列開発** - 各子Claudeが特定のMDファイルを担当
4. **ファイル競合の完全回避** - 物理的に分離されたワークスペース
5. **自動整合性チェック** - MDファイル間の参照を自動検証
6. **統合レビューシステム** - 親Claudeによる全体統括

## システム構成

### Git Worktreeアーキテクチャ

```
メインリポジトリ (main)
├── worktree-parent/     # 親Claude用 (feature/integration)
├── worktree-child1/     # 子Claude1用 (feature/requirements)
├── worktree-child2/     # 子Claude2用 (feature/design)
└── worktree-child3/     # 子Claude3用 (feature/implementation)
```

### 役割分担

```
┌─────────────────────────────────────────────┐
│      親Claude（feature/integration）          │
│  - 各子Claudeの成果物を統合                  │
│  - 3つのMDファイル間の整合性確認            │
│  - コンフリクト解決とレビュー                │
└──────────────┬──────────────────────────────┘
               │
     ┌─────────┴─────────┬─────────────┐
     ▼                   ▼             ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  子Claude1   │   │  子Claude2   │   │  子Claude3   │
│  要件定義    │   │    設計      │   │    実装      │
│requirements.md│   │  design.md   │   │  tasks.md    │
│feature/      │   │feature/      │   │feature/      │
│requirements  │   │design        │   │implementation│
└─────────────┘   └─────────────┘   └─────────────┘
```

## クイックスタート

```bash
# 1. プロジェクトのクローン
git clone <repository-url> my-project
cd my-project

# 2. developブランチの作成
git checkout -b develop
git push -u origin develop

# 3. Git Worktreeのセットアップ
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

# 4. 各worktreeの初期化
for worktree in worktree-parent worktree-child1 worktree-child2 worktree-child3; do
  cd ../$worktree
  mkdir -p docs
  touch docs/{requirements.md,design.md,tasks.md}
  git add .
  git commit -m "初期セットアップ: $worktree"
done

# 5. tmuxセッションの起動
./setup-parallel-tmux.sh
```

## ファイル構成

### メインリポジトリ構造
```
my-project/                        # メインリポジトリ
├── .git/                         # Gitディレクトリ
├── src/                          # ソースコード
├── docs/                         # ドキュメント（マスター）
└── scripts/                      # 管理スクリプト
    ├── setup-parallel-tmux.sh    # tmuxセットアップ
    ├── integrate-branches.sh     # 統合スクリプト
    └── check-consistency.sh      # 整合性チェック
```

### Worktree構造
```
../worktree-parent/               # 親Claude用 (feature/integration)
├── docs/
│   ├── requirements.md          # 統合された要件定義書
│   ├── design.md               # 統合された設計書
│   ├── tasks.md                # 統合されたタスク管理書
│   └── review-notes/           # レビューノート
├── integrate-branches.sh        # 統合スクリプト
└── check-consistency.sh         # 整合性チェック

../worktree-child1/              # 子Claude1用 (feature/requirements)
├── docs/
│   └── requirements.md         # 要件定義書（編集用）
└── sync-with-develop.sh        # 同期スクリプト

../worktree-child2/              # 子Claude2用 (feature/design)
├── docs/
│   ├── requirements.md         # 要件定義書（参照用）
│   └── design.md              # 設計書（編集用）
└── sync-with-develop.sh        # 同期スクリプト

../worktree-child3/              # 子Claude3用 (feature/implementation)
├── docs/
│   ├── requirements.md         # 要件定義書（参照用）
│   ├── design.md              # 設計書（参照用）
│   └── tasks.md               # タスク管理書（編集用）
└── sync-with-develop.sh        # 同期スクリプト
```

## 3つのMDファイルの役割

### 1. requirements.md（要件定義書）
- **担当**: 子Claude1
- **内容**:
  - ユーザーストーリー
  - 受入基準
  - 非機能要件
  - ビジネス制約
- **ID形式**: REQ001, REQ002...

### 2. design.md（設計書）
- **担当**: 子Claude2
- **内容**:
  - システムアーキテクチャ
  - API仕様
  - データモデル
  - 技術選定
- **ID形式**: AUTH001, PROFILE001...

### 3. tasks.md（タスク管理書）
- **担当**: 子Claude3
- **内容**:
  - 実装タスク一覧
  - サブタスク分解
  - 工数見積もり
  - 進捗チェックリスト
- **ID形式**: TASK001, TASK002...

## 使い方

### 1. 各Worktreeでの作業開始

```bash
# tmuxセッションにアタッチ
tmux attach-session -t claude-parallel-dev

# 各ウィンドウで作業開始前の同期
# (各worktreeで実行)
git fetch origin
git pull origin develop --rebase
```

### 2. 各Claudeの初期化

各tmuxウィンドウで以下のコマンドを実行：

```bash
# ウィンドウ0: 親Claude
cd ../worktree-parent
claude --dangerously-skip-permissions

# ウィンドウ1: 子Claude1
cd ../worktree-child1
claude --dangerously-skip-permissions

# ウィンドウ2: 子Claude2
cd ../worktree-child2
claude --dangerously-skip-permissions

# ウィンドウ3: 子Claude3
cd ../worktree-child3
claude --dangerously-skip-permissions
```

### 3. tmuxセッションの構成

- ウィンドウ0: 親Claude（feature/integration）- 統合とレビュー
- ウィンドウ1: 子Claude1（feature/requirements）- requirements.md担当
- ウィンドウ2: 子Claude2（feature/design）- design.md担当
- ウィンドウ3: 子Claude3（feature/implementation）- tasks.md担当
- ウィンドウ4: 管理ツール - worktree状態確認とモニタリング

### 4. 各Claudeでの初期化メッセージ

**親Claude（ウィンドウ0）:**
```
私は親Claudeです。feature/integrationブランチのworktree-parentで作業します。
各子Claudeのブランチ（feature/requirements、feature/design、feature/implementation）を統合し、
3つのMDファイルの整合性を確保します。
```

**子Claude1（ウィンドウ1）:**
```
私は子Claude1です。feature/requirementsブランチのworktree-child1で作業します。
requirements.mdの管理に専念し、他のClaudeとファイル競合することなく
要件定義を進めます。
```

**子Claude2（ウィンドウ2）:**
```
私は子Claude2です。feature/designブランチのworktree-child2で作業します。
design.mdの管理に専念し、最新の要件を取り込みながら
設計作業を進めます。
```

**子Claude3（ウィンドウ3）:**
```
私は子Claude3です。feature/implementationブランチのworktree-child3で作業します。
tasks.mdの管理に専念し、要件と設計を参照しながら
実装タスクを管理します。
```

### 5. Git Worktreeでの作業フロー

#### 日常的な作業サイクル

```bash
# 1. 作業開始時の同期（各worktreeで実行）
./sync-with-develop.sh

# 2. 担当ファイルの編集
# 子Claude1の例
cd ../worktree-child1
vim docs/requirements.md
git add docs/requirements.md
git commit -m "feat(req): ユーザー認証要件を追加 #REQ001"
git push origin feature/requirements

# 3. 他のClaudeの変更を取り込む（必要に応じて）
# 子Claude2の例
cd ../worktree-child2
git fetch origin
git checkout origin/feature/requirements -- docs/requirements.md
vim docs/design.md  # 要件に基づいて設計
git add docs/
git commit -m "design: REQ001に対応する認証設計を追加"
git push origin feature/design

# 4. 親Claudeによる統合
cd ../worktree-parent
./integrate-branches.sh
./check-consistency.sh
git push origin feature/integration
```

### 6. 整合性チェックと進捗管理

```bash
# MDファイル間の整合性チェック（親Claudeのworktreeで実行）
cd ../worktree-parent
./check-consistency.sh

# 出力例:
# === MDファイル整合性チェック ===
# 要件→設計の対応:
#   ✓ REQ001: 設計あり
#   ✓ REQ002: 設計あり
#   ⚠️  REQ003: 設計なし
# 
# 設計→タスクの対応:
#   ✓ AUTH001: タスクあり
#   ⚠️  PROFILE001: タスクなし

# Worktreeの状態確認
git worktree list

# 各ブランチの進捗確認
for branch in feature/requirements feature/design feature/implementation; do
  echo "=== $branch ==="
  git log origin/$branch --oneline -5
done
```

## tmux操作ガイド

| 操作 | キーバインド | 説明 |
|-----|------------|------|
| ウィンドウ切替 | `Ctrl-a` → `1-5` | 指定番号のウィンドウへ |
| ペイン間移動 | `Ctrl-a` → `h/j/k/l` | vim風の移動 |
| セッション離脱 | `Ctrl-a` → `d` | tmuxから離脱 |
| セッション再接続 | `tmux a -t claude-parallel-dev` | セッションに再接続 |

## ワークフロー例

### 新機能追加の流れ（Git Worktree活用）

1. **子Claude1**: requirements.mdに新要件を追加
   ```bash
   cd ../worktree-child1
   vim docs/requirements.md
   # 以下を追加:
   # ## 要件10: ユーザープロフィール機能
   # - **要件ID**: REQ010
   # - **ユーザーストーリー**: ユーザーとして、プロフィールを管理したい
   # - **受入基準**: プロフィール画像のアップロード可能
   
   git add docs/requirements.md
   git commit -m "feat(req): プロフィール機能の要件を追加 #REQ010"
   git push origin feature/requirements
   ```

2. **子Claude2**: 最新要件を取得して設計を追加
   ```bash
   cd ../worktree-child2
   git fetch origin
   git checkout origin/feature/requirements -- docs/requirements.md
   vim docs/design.md
   # REQ010に対応する設計を追加
   
   git add docs/
   git commit -m "design: プロフィール機能の設計を追加 #PROFILE001"
   git push origin feature/design
   ```

3. **子Claude3**: 最新設計を取得してタスクを追加
   ```bash
   cd ../worktree-child3
   git fetch origin
   git checkout origin/feature/design -- docs/design.md
   git checkout origin/feature/requirements -- docs/requirements.md
   vim docs/tasks.md
   # タスクを追加
   
   git add docs/
   git commit -m "task: プロフィール機能の実装タスクを追加 #TASK010"
   git push origin feature/implementation
   ```

4. **親Claude**: 全ブランチを統合してレビュー
   ```bash
   cd ../worktree-parent
   ./integrate-branches.sh
   ./check-consistency.sh
   
   # レビューノート作成
   vim docs/review-notes-$(date +%Y%m%d).md
   git add docs/
   git commit -m "review: プロフィール機能の統合レビュー完了"
   git push origin feature/integration
   ```

## トラブルシューティング

### Git Worktree関連の問題

```bash
# Worktreeの状態確認
git worktree list

# 壊れたWorktreeの修復
git worktree repair

# Worktreeの再作成
git worktree remove ../worktree-child1
git worktree add ../worktree-child1 feature/requirements

# Worktreeの移動
git worktree move ../worktree-child1 ../new-location/worktree-child1
```

### ブランチの同期問題

```bash
# コンフリクトが発生した場合
cd ../worktree-child1
git fetch origin
git rebase origin/develop
# コンフリクトを解決
git add .
git rebase --continue

# 他のClaudeの変更が見えない場合
git fetch origin --all
git log --all --oneline --graph
```

### MDファイル間の不整合

```bash
# 親Claudeのworktreeで整合性チェック
cd ../worktree-parent
./check-consistency.sh

# 手動で最新ファイルを取得して修正
git fetch origin
git checkout origin/feature/requirements -- docs/requirements.md
git checkout origin/feature/design -- docs/design.md
git checkout origin/feature/implementation -- docs/tasks.md
vim docs/*.md  # 必要な調整を実施
```

### tmuxセッションのトラブル

```bash
# セッション一覧確認
tmux ls

# 既存セッション削除
tmux kill-session -t claude-parallel-dev

# 再起動
./setup-parallel-tmux.sh
```

## ベストプラクティス

### 1. Git Worktree管理
- **命名規則**: worktree名は役割を明確に（worktree-parent、worktree-child1など）
- **定期的な同期**: developブランチとの同期を毎日実施
- **ブランチ寿命**: feature branchは1-2週間以内にマージ
- **クリーンアップ**: 不要なworktreeは`git worktree remove`で削除

### 2. MDファイル管理
- **一貫性のあるID体系**: REQ/DESIGN/TASK接頭辞を統一
- **相互参照の明記**: `requirements.md#REQ001`形式で参照
- **編集権限の遵守**: 各子Claudeは担当MDファイルのみ編集
- **参照の更新**: 他のClaudeのファイルは`git checkout origin/branch -- file`で取得

### 3. コミットとプッシュ
- **頻繁なコミット**: 1-2時間ごとにコミット
- **明確なメッセージ**: `type(scope): description #ID`形式
- **早めのプッシュ**: 作業終了時は必ずプッシュ
- **force pushの回避**: `--force-with-lease`を使用

### 4. 統合とレビュー
- **日次統合**: 親Claudeは毎日統合を実施
- **段階的マージ**: requirements → design → implementationの順
- **整合性確認**: 統合後は必ず`check-consistency.sh`を実行
- **レビューノート**: 統合時の問題点と改善案を記録

### 5. コミュニケーション
- **共有ノート活用**: `../shared-notes/`で情報共有
- **ブロッカーの即座報告**: 依存関係の問題は速やかに共有
- **進捗の可視化**: worktree状態を定期的に確認

## 高度な機能

### 自動化スクリプト

```bash
# 日次同期スクリプト
cat > daily-sync-all.sh << 'EOF'
#!/bin/bash
set -e

echo "=== 全worktreeの日次同期 ==="

# 各worktreeで同期
for worktree in ../worktree-*; do
  if [ -d "$worktree" ]; then
    echo "\n同期中: $worktree"
    cd "$worktree"
    git fetch origin
    git pull origin develop --rebase || echo "Rebase needed for $worktree"
  fi
done

# 親Claudeで統合
cd ../worktree-parent
./integrate-branches.sh
./check-consistency.sh

echo "\n=== 同期完了 ==="
EOF

chmod +x daily-sync-all.sh
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
        run: npm test
```

### 複数プロジェクトの管理

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
tmux send-keys -t claude-parallel-dev:2 "cd ../$PROJECT/worktree-child2" C-m
tmux send-keys -t claude-parallel-dev:3 "cd ../$PROJECT/worktree-child3" C-m
EOF
```

## 注意事項

- **Worktreeの独立性**: 各Claudeは自分のworktreeでのみ作業
- **ブランチ保護**: developとmainブランチへの直接プッシュは禁止
- **MDファイルの編集権限**: 各子Claudeは担当MDファイルのみ編集可能
- **相互参照の維持**: ID変更時は関連ファイルも更新
- **定期的な同期**: developブランチとの乖離を防ぐため毎日rebase
- **コンフリクト解決**: 親Claudeが最終的な判断を実施

## サポートとリソース

### 問題解決の手順

1. **Worktree状態の確認**
   ```bash
   git worktree list
   git worktree repair
   ```

2. **ブランチ状態の確認**
   ```bash
   git branch -vv
   git log --all --oneline --graph -10
   ```

3. **ログの確認**
   ```bash
   # 統合ログ
   cat ../worktree-parent/integration.log
   
   # 各worktreeのログ
   git log --oneline -10
   ```

4. **親Claudeへのエスカレーション**
   ```bash
   echo "問題: [詳細]" > ../shared-notes/issues/$(date +%Y%m%d-%H%M).txt
   ```

### 参考資料

- [Git Worktree公式ドキュメント](https://git-scm.com/docs/git-worktree)
- parent-claude-guide.md - 親Claude用の詳細ガイド
- child-claude-guide.md - 子Claude用の詳細ガイド
- DETAILED_MANUAL.md - システム全体の詳細マニュアル