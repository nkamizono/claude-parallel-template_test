# 子Claude用ガイド（Git Worktree版）

## 役割
子Claudeは、独立したworktreeで専門分野に特化した作業を行います。各子Claudeは独自のブランチで作業し、ファイル競合を気にせず並列開発を進められます。

### 各子Claudeの専門分野とブランチ
- **子Claude1**: requirements.md担当（feature/requirementsブランチ）
- **子Claude2**: design.md担当（feature/designブランチ）
- **子Claude3**: tasks.md担当（feature/implementationブランチ）

## 作業環境

```bash
# 各子Claude専用のworktree
cd ../worktree-child1  # 要件担当
cd ../worktree-child2  # 設計担当
cd ../worktree-child3  # 実装担当

# 自分のブランチを確認
git branch --show-current
```

## 初期セットアップ

### 1. Worktreeの確認と初期化

```bash
# worktreeの場所を確認
pwd  # 例: /path/to/worktree-child1

# ブランチの確認
git branch --show-current  # 例: feature/requirements

# リモートの設定確認
git remote -v

# 必要なディレクトリ構造の確認
ls -la
# docs/
# claude-tasks/
# README.md
```

### 2. 作業用スクリプトの準備

```bash
# 日次同期スクリプト
cat > sync-with-develop.sh << 'EOF'
#!/bin/bash
echo "=== developブランチとの同期 ==="

# 最新を取得
git fetch origin

# 現在の状態を表示
echo "現在のブランチ: $(git branch --show-current)"
echo "最新のコミット: $(git log --oneline -1)"

# developからの変更を取り込む
if git pull origin develop --rebase; then
  echo "✓ 同期成功"
else
  echo "⚠️  コンフリクトが発生しました"
  echo "解決後、git rebase --continue を実行してください"
fi
EOF

chmod +x sync-with-develop.sh
```

### 3. 担当ファイルの準備

#### 子Claude1（要件担当）
```bash
# requirements.mdのテンプレート
cat > docs/requirements.md << 'EOF'
# 要件定義書

## プロジェクト概要
[プロジェクトの説明]

## 機能要件

### 要件1: [要件名]
- **要件ID**: REQ001
- **優先度**: 高/中/低
- **ユーザーストーリー**: 
  [ユーザー]として、[目的]のために、[機能]が欲しい
- **受入基準**:
  1. [測定可能な基準1]
  2. [測定可能な基準2]
- **制約事項**: 
  - [技術的制約]
  - [ビジネス制約]

## 非機能要件

### パフォーマンス要件
- レスポンスタイム: 3秒以内
- 同時接続数: 1000ユーザー

### セキュリティ要件
- 認証: OAuth 2.0
- 暗号化: TLS 1.3
EOF
```

#### 子Claude2（設計担当）
```bash
# design.mdのテンプレート
cat > docs/design.md << 'EOF'
# 設計書

## システムアーキテクチャ
[全体構成図]

## 技術スタック
- Frontend: React + TypeScript
- Backend: Node.js + Express
- Database: PostgreSQL
- Cache: Redis

## コンポーネント設計

### コンポーネント1: [名前]
- **設計ID**: AUTH001
- **関連要件**: requirements.md#REQ001
- **概要**: [説明]
- **API設計**:
  ```yaml
  endpoint: /api/auth/login
  method: POST
  request:
    - email: string
    - password: string
  response:
    - token: string
    - expiresIn: number
  ```
- **データモデル**:
  ```typescript
  interface User {
    id: string;
    email: string;
    passwordHash: string;
    createdAt: Date;
  }
  ```
EOF
```

#### 子Claude3（実装担当）
```bash
# tasks.mdのテンプレート
cat > docs/tasks.md << 'EOF'
# タスク管理書

## 実装タスク一覧

### タスク1: [タスク名]
- **タスクID**: TASK001
- **関連要件**: requirements.md#REQ001
- **関連設計**: design.md#AUTH001
- **優先度**: 高
- **見積もり**: 8時間
- **担当**: [担当者]

#### サブタスク
- [ ] データベーススキーマ作成 (2h)
- [ ] APIエンドポイント実装 (3h)
- [ ] フロントエンド統合 (2h)
- [ ] テスト作成 (1h)

#### 完了条件
- [ ] 全エンドポイントが仕様通り動作
- [ ] テストカバレッジ80%以上
- [ ] コードレビュー承認済み

## 進捗管理

### 今週の目標
- TASK001-005の完了
- テストカバレッジ85%達成

### ブロッカー
- なし
EOF
```

## 日常的な作業フロー

### 1. 作業開始時の手順

```bash
# 1. 最新の状態に同期
./sync-with-develop.sh

# 2. 他のブランチの変更を確認（必要に応じて）
git fetch origin
git log --oneline origin/feature/requirements -5  # 子Claude1の場合
git log --oneline origin/feature/design -5        # 子Claude2の場合
git log --oneline origin/feature/implementation -5 # 子Claude3の場合

# 3. 作業開始
echo "=== 本日の作業開始: $(date) ===" >> work-log.md
```

### 2. 担当ファイルの編集

#### 子Claude1（要件担当）の作業例
```bash
# requirements.mdの編集
vim docs/requirements.md

# 新しい要件を追加
cat >> docs/requirements.md << 'EOF'

### 要件10: ユーザープロフィール機能
- **要件ID**: REQ010
- **優先度**: 高
- **ユーザーストーリー**: 
  ユーザーとして、自分のプロフィール情報を管理したい
- **受入基準**:
  1. プロフィール画像をアップロードできる
  2. 自己紹介文を500文字以内で入力できる
  3. プロフィールの公開/非公開を設定できる
- **制約事項**: 
  - 画像サイズは最大5MB
  - JPEG, PNG形式のみサポート
EOF

# 変更をコミット
git add docs/requirements.md
git commit -m "feat(req): ユーザープロフィール機能の要件を追加 #REQ010"
```

#### 子Claude2（設計担当）の作業例
```bash
# 最新の要件を確認
git fetch origin
git show origin/feature/requirements:docs/requirements.md | grep -A 15 "REQ010"

# design.mdに対応する設計を追加
vim docs/design.md

# コミット
git add docs/design.md
git commit -m "design: プロフィール機能の設計を追加 #PROFILE001

- REQ010に対応
- APIエンドポイント定義
- データモデル設計"
```

#### 子Claude3（実装担当）の作業例
```bash
# 最新の設計を確認
git fetch origin
git show origin/feature/design:docs/design.md | grep -A 20 "PROFILE001"

# tasks.mdにタスクを追加
vim docs/tasks.md

# コミット
git add docs/tasks.md
git commit -m "task: プロフィール機能の実装タスクを追加 #TASK010-015

- 5つのサブタスクに分解
- 総工数: 20時間
- 依存: AUTH001の完了"
```

### 3. 作業内容のプッシュ

```bash
# リモートにプッシュ
git push origin $(git branch --show-current)

# プッシュ後の確認
git log origin/$(git branch --show-current)..HEAD --oneline

# 他のClaudeへの通知（オプション）
echo "$(git branch --show-current) を更新しました: $(git log -1 --oneline)" > ../shared-notes/update-$(date +%Y%m%d-%H%M).txt
```

### 4. 他のClaudeの変更を取り込む

```bash
# 依存する変更を選択的に取り込む
# 例: 子Claude2が子Claude1の最新要件を取り込む
git fetch origin
git checkout origin/feature/requirements -- docs/requirements.md

# 取り込んだ内容を確認
git diff --cached

# 必要な部分のみステージング
git reset
git add -p docs/requirements.md

# コミット
git commit -m "sync: 最新の要件定義を取り込み"
```

## コラボレーションパターン

### 1. 順次的な作業フロー

```bash
# 子Claude1 → 子Claude2 → 子Claude3 の流れ

# 子Claude1: 要件定義
git add docs/requirements.md
git commit -m "feat(req): 新機能の要件定義"
git push origin feature/requirements

# 子Claude2: 要件を確認して設計
git fetch origin
git checkout origin/feature/requirements -- docs/requirements.md
# design.mdを編集
git add docs/design.md docs/requirements.md
git commit -m "design: 新機能の設計（REQ011-013対応）"
git push origin feature/design

# 子Claude3: 設計を確認してタスク化
git fetch origin
git checkout origin/feature/design -- docs/design.md
git checkout origin/feature/requirements -- docs/requirements.md
# tasks.mdを編集
git add docs/
git commit -m "task: 新機能の実装タスク定義"
git push origin feature/implementation
```

### 2. 並列作業での調整

```bash
# 複数の子Claudeが同時に作業する場合

# 共有メモの活用
mkdir -p ../shared-notes/$(date +%Y%m%d)

# 作業開始時に宣言
echo "子Claude1: REQ010-012を作業中" > ../shared-notes/$(date +%Y%m%d)/claude1-working.txt

# 作業完了時に通知
echo "子Claude1: REQ010-012完了、レビュー待ち" > ../shared-notes/$(date +%Y%m%d)/claude1-done.txt
```

### 3. フィードバックの処理

```bash
# 親Claudeからのフィードバックを確認
git fetch origin
git log origin/feature/integration --grep="review" --oneline

# フィードバックに基づく修正
vim docs/requirements.md  # または design.md, tasks.md

# 修正をコミット
git add docs/
git commit -m "fix: レビューフィードバックに基づく修正

- REQ010の受入基準を明確化
- 非機能要件を追加"

git push origin $(git branch --show-current)
```

## トラブルシューティング

### 1. コンフリクトの解決

```bash
# rebase中にコンフリクトが発生した場合
git status

# コンフリクトファイルを編集
vim docs/requirements.md

# 解決後
git add docs/requirements.md
git rebase --continue

# またはrebaseを中止
git rebase --abort
```

### 2. 間違ったコミットの修正

```bash
# 直前のコミットを修正
git commit --amend

# 特定のコミットを修正（インタラクティブrebase）
git rebase -i HEAD~3

# pushした後の修正（注意が必要）
git push origin $(git branch --show-current) --force-with-lease
```

### 3. ブランチの同期問題

```bash
# ローカルとリモートの差分確認
git fetch origin
git diff origin/$(git branch --show-current)

# リモートの状態にリセット（注意！）
git reset --hard origin/$(git branch --show-current)

# または、新しいブランチで作業
git checkout -b feature/requirements-fix
```

## ベストプラクティス

### 1. コミットメッセージ

```bash
# 良い例（役割を明確に）
git commit -m "feat(req): 決済機能の要件を追加 #REQ020"
git commit -m "design: 決済APIの設計 #PAYMENT001"
git commit -m "task: 決済機能の実装タスク #TASK020-025"

# type(scope): description #ID の形式を推奨
# type: feat, fix, docs, style, refactor, test, chore
# scope: req, design, task
```

### 2. 作業の粒度

```bash
# 小さく頻繁にコミット
git add docs/requirements.md
git commit -m "feat(req): ユーザー認証の基本要件"

git add docs/requirements.md
git commit -m "feat(req): ユーザー認証の詳細要件とセキュリティ考慮"

# 1日の終わりに必ずプッシュ
git push origin $(git branch --show-current)
```

### 3. ドキュメントの品質

```bash
# Markdownのリンター使用
npm install -g markdownlint-cli
markdownlint docs/*.md

# スペルチェック
npm install -g spellchecker-cli
spellchecker docs/*.md
```

### 4. 定期的な同期

```bash
# 日次同期スクリプト
cat > daily-sync.sh << 'EOF'
#!/bin/bash
echo "=== 日次同期 $(date) ==="

# developとの同期
git fetch origin
git pull origin develop --rebase

# 状態確認
echo -e "\n現在の状態:"
git status -sb
git log --oneline -5

echo -e "\n他のブランチの状態:"
for branch in feature/requirements feature/design feature/implementation; do
  echo "$branch: $(git log origin/$branch --oneline -1)"
done
EOF

chmod +x daily-sync.sh
```

## チェックリスト

### 作業開始時
- [ ] worktreeの場所を確認
- [ ] 正しいブランチにいることを確認
- [ ] developブランチと同期
- [ ] 他のClaudeの最新状況を確認

### 作業中
- [ ] 担当ファイルのみを編集
- [ ] 定期的にコミット（1-2時間ごと）
- [ ] 意味のあるコミットメッセージ
- [ ] 関連するIDを記載

### 作業終了時
- [ ] 全ての変更をコミット
- [ ] リモートにプッシュ
- [ ] 他のClaudeへの影響を確認
- [ ] 作業ログを更新

### 週次レビュー
- [ ] 自分のブランチの履歴を確認
- [ ] 不要なコミットの整理
- [ ] ドキュメントの整合性確認
- [ ] 次週の計画立案