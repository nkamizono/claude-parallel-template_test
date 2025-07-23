# 親Claude用ガイド（Git Worktree版）

## 役割
親Claudeは、独立したworktree（feature/integrationブランチ）で作業し、各子Claudeの成果物を統合・レビューする責任を持ちます。

## 責任範囲

1. **統合管理**
   - 各子Claudeのブランチをマージ
   - コンフリクトの解決
   - 全体の整合性確保

2. **レビュー**
   - 各MDファイルの品質確認
   - 相互参照の検証
   - 技術的な一貫性の確保

3. **プロジェクト管理**
   - マイルストーンの設定
   - 優先順位の決定
   - リリース準備

## 作業環境

```bash
# 親Claude専用のworktree
cd ../worktree-parent

# 作業ブランチ
git branch --show-current  # feature/integration
```

## 初期セットアップ

### 1. Worktreeの確認

```bash
# worktreeの状態確認
git worktree list

# 出力例:
# /path/to/project              abcd123 [main]
# /path/to/worktree-parent      efgh456 [feature/integration]
# /path/to/worktree-child1      ijkl789 [feature/requirements]
# /path/to/worktree-child2      mnop012 [feature/design]
# /path/to/worktree-child3      qrst345 [feature/implementation]
```

### 2. 統合スクリプトの準備

```bash
# 統合作業を自動化するスクリプト
cat > integrate-branches.sh << 'EOF'
#!/bin/bash
set -e

echo "=== 統合作業開始 $(date) ==="

# 最新の変更を取得
git fetch origin

# 各子Claudeのブランチをマージ
BRANCHES=(
  "feature/requirements"
  "feature/design"
  "feature/implementation"
)

for branch in "${BRANCHES[@]}"; do
  echo -e "\n--- Merging $branch ---"
  if git merge origin/$branch --no-ff -m "integrate: $branch を統合 $(date +%Y-%m-%d)"; then
    echo "✓ $branch のマージ成功"
  else
    echo "⚠️  $branch のマージでコンフリクト発生"
    echo "手動で解決してください"
    exit 1
  fi
done

echo -e "\n=== 統合完了 ==="
git log --oneline -5
EOF

chmod +x integrate-branches.sh
```

### 3. 整合性チェックツールの設定

```bash
# MDファイル間の整合性をチェック
cat > check-consistency.sh << 'EOF'
#!/bin/bash

echo "=== MDファイル整合性チェック ==="

# 要件→設計の対応確認
echo -e "\n要件→設計の対応:"
while IFS= read -r req; do
  req_id=$(echo "$req" | grep -oE "REQ[0-9]+")
  if [ ! -z "$req_id" ]; then
    if grep -q "requirements.md#$req_id" docs/design.md; then
      echo "  ✓ $req_id: 設計あり"
    else
      echo "  ⚠️  $req_id: 設計なし"
    fi
  fi
done < <(grep -E "^##.*要件|REQ[0-9]+" docs/requirements.md)

# 設計→タスクの対応確認
echo -e "\n設計→タスクの対応:"
while IFS= read -r design; do
  design_id=$(echo "$design" | grep -oE "[A-Z]+[0-9]+")
  if [ ! -z "$design_id" ]; then
    if grep -q "design.md#$design_id" docs/tasks.md; then
      echo "  ✓ $design_id: タスクあり"
    else
      echo "  ⚠️  $design_id: タスクなし"
    fi
  fi
done < <(grep -E "設計ID|[A-Z]+[0-9]+" docs/design.md | grep -v REQ)

# 結果サマリー
echo -e "\n=== チェック完了 ==="
EOF

chmod +x check-consistency.sh
```

## 日常的な作業フロー

### 1. 朝の同期作業

```bash
# 最新の状態に同期
git fetch origin
git pull origin develop --rebase

# 各子Claudeの進捗確認
echo "=== 各ブランチの最新コミット ==="
for branch in feature/requirements feature/design feature/implementation; do
  echo -e "\n--- $branch ---"
  git log origin/$branch --oneline -3
done
```

### 2. 定期的な統合（日次）

```bash
# 統合スクリプトの実行
./integrate-branches.sh

# 整合性チェック
./check-consistency.sh

# 問題があれば修正
vim docs/requirements.md  # 必要に応じて調整
vim docs/design.md
vim docs/tasks.md

# 修正をコミット
git add docs/
git commit -m "fix: MDファイル間の整合性を修正"

# プッシュ
git push origin feature/integration
```

### 3. レビュー作業

```bash
# レビューノートの作成
cat > docs/review-notes-$(date +%Y%m%d).md << 'EOF'
# レビューノート $(date +%Y-%m-%d)

## 要件レビュー (requirements.md)
- ✓ REQ010: 明確で実装可能
- ⚠️  REQ011: 受入基準が曖昧、詳細化が必要
- 💡 REQ012: パフォーマンス要件の追加を推奨

## 設計レビュー (design.md)
- ✓ PROFILE001: 要件と整合性あり
- ⚠️  NOTIF001: セキュリティ考慮が不足
- 💡 全体的にエラーハンドリングの記載を追加

## タスクレビュー (tasks.md)
- ✓ TASK010-015: 適切に分解されている
- ⚠️  TASK016: 工数見積もりが楽観的すぎる
- 💡 テストタスクの比重を増やすべき

## アクションアイテム
1. 子Claude1: REQ011の詳細化
2. 子Claude2: NOTIF001のセキュリティ設計追加
3. 子Claude3: TASK016の工数再見積もり
EOF

git add docs/review-notes-*.md
git commit -m "review: $(date +%Y-%m-%d)のレビューノート"
```

### 4. コンフリクト解決

```bash
# マージ時にコンフリクトが発生した場合
git status

# コンフリクトファイルの確認
git diff --name-only --diff-filter=U

# 各バージョンの内容確認
git show :1:docs/requirements.md  # ベース
git show :2:docs/requirements.md  # 現在のブランチ
git show :3:docs/requirements.md  # マージしようとしているブランチ

# エディタで解決
vim docs/requirements.md

# 解決後
git add docs/requirements.md
git commit -m "resolve: requirements.mdのコンフリクトを解決"
```

## 高度な統合パターン

### 1. 段階的統合

```bash
# 依存関係に基づいて順次統合
echo "=== Stage 1: 要件の統合 ==="
git merge origin/feature/requirements --no-ff

echo "=== Stage 2: 要件を確認してから設計を統合 ==="
./check-consistency.sh
git merge origin/feature/design --no-ff

echo "=== Stage 3: 設計を確認してからタスクを統合 ==="
./check-consistency.sh
git merge origin/feature/implementation --no-ff
```

### 2. 選択的統合

```bash
# 特定のファイルのみを統合
git checkout origin/feature/requirements -- docs/requirements.md
git add docs/requirements.md
git commit -m "integrate: 要件定義のみを統合"

# 特定のコミットのみを統合
git cherry-pick origin/feature/design~2..origin/feature/design
```

### 3. 統合前のプレビュー

```bash
# マージをシミュレーション
git merge origin/feature/requirements --no-commit --no-ff
git diff --cached
git merge --abort  # 取り消す場合

# 統合後の状態を一時的に確認
git checkout -b test-integration
git merge origin/feature/requirements origin/feature/design origin/feature/implementation
# 確認後
git checkout feature/integration
git branch -D test-integration
```

## コミュニケーション

### 1. 子Claudeへのフィードバック

```bash
# フィードバックディレクトリの作成
mkdir -p feedback/$(date +%Y%m%d)

# 各子Claudeへのフィードバック
cat > feedback/$(date +%Y%m%d)/to-child1.md << 'EOF'
# 子Claude1（要件担当）へのフィードバック

## 良い点
- REQ010の要件定義が明確
- ユーザーストーリーが具体的

## 改善点
- REQ011の受入基準をより具体的に
- 非機能要件（パフォーマンス、セキュリティ）の追加

## 次のアクション
1. REQ011の詳細化（本日中）
2. REQ013-015の新規追加（明日まで）
EOF

# Slackやissueで通知
echo "フィードバックを feedback/$(date +%Y%m%d)/ に配置しました" > ../shared-notes/feedback-notice.txt
```

### 2. 進捗レポートの作成

```bash
# 週次レポートの生成
cat > reports/weekly-$(date +%Y-W%V).md << 'EOF'
# 週次進捗レポート Week $(date +%V)

## サマリー
- 統合回数: 5回
- 解決したコンフリクト: 3件
- 完了した機能: 2つ

## 各ブランチの状況
### feature/requirements
- 新規要件: 5件
- 更新: 3件
- 課題: 特になし

### feature/design
- 新規設計: 4件
- 更新: 2件
- 課題: パフォーマンス設計の見直しが必要

### feature/implementation
- 新規タスク: 10件
- 完了: 6件
- 課題: テストカバレッジが目標未達

## 来週の予定
1. 認証機能の統合完了
2. パフォーマンステストの実施
3. developブランチへのPR作成
EOF
```

## トラブルシューティング

### 1. Worktreeが壊れた場合

```bash
# 状態確認
git worktree list

# 修復
git worktree repair ../worktree-parent

# 再作成が必要な場合
cd ../main-repo
git worktree remove ../worktree-parent
git worktree add ../worktree-parent feature/integration
```

### 2. 統合が複雑になりすぎた場合

```bash
# 統合ブランチをリセット
git reset --hard origin/develop

# 段階的に再統合
git merge origin/feature/requirements --no-ff
# テスト実行
npm test

git merge origin/feature/design --no-ff
# テスト実行
npm test

# 問題があれば個別に対処
```

### 3. プッシュ権限の問題

```bash
# ブランチ保護の確認
git push --dry-run origin feature/integration

# 強制プッシュが必要な場合（注意！）
git push origin feature/integration --force-with-lease
```

## ベストプラクティス

### 1. 定期的な統合
- 最低1日1回は統合を実行
- 金曜日に週次の大規模統合
- 月曜日に新しい週の計画

### 2. コミットメッセージ
```bash
# 良い例
git commit -m "integrate: 要件・設計・タスクを統合 2024-01-20"
git commit -m "fix: REQ010とPROFILE001の整合性を修正"
git commit -m "review: 認証機能の設計レビュー完了"

# 悪い例
git commit -m "統合"
git commit -m "修正"
```

### 3. ブランチの保護
```bash
# developへの直接プッシュを防ぐ
git config --local receive.denyCurrentBranch refuse

# プッシュ前の確認
git log origin/develop..HEAD --oneline
```

### 4. バックアップ
```bash
# 統合前のバックアップ
git tag backup-$(date +%Y%m%d-%H%M%S)

# 定期的なバックアップブランチ
git checkout -b backup/weekly-$(date +%Y-W%V)
git checkout feature/integration
```

## チェックリスト

### 日次チェックリスト
- [ ] 各子Claudeのブランチの最新を確認
- [ ] 統合スクリプトの実行
- [ ] 整合性チェックの実行
- [ ] コンフリクトの解決
- [ ] レビューノートの作成
- [ ] フィードバックの送信

### 週次チェックリスト
- [ ] 全体的な進捗確認
- [ ] developブランチとの差分確認
- [ ] パフォーマンステストの実行
- [ ] セキュリティチェック
- [ ] 週次レポートの作成
- [ ] 来週の計画立案

### リリース前チェックリスト
- [ ] 全機能の統合完了
- [ ] 全テストの成功
- [ ] ドキュメントの最終確認
- [ ] PRの作成とレビュー依頼
- [ ] デプロイ手順の確認
- [ ] ロールバック計画の準備