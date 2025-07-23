# 開発設計書 - Todoアプリケーション

## プロジェクト概要
プロジェクト名: Simple Todo App
目的: シンプルで使いやすいTodoアプリケーションの開発
期限: 2024年7月26日

## 並列開発用ドキュメント構成

このプロジェクトは以下の3つのドキュメントから並列開発を行います：

1. **requirements.md** - 要件定義書
   - ビジネス要求とユーザーストーリー
   - 受入基準と制約事項
   - 担当: 子Claude1
   
2. **design.md** - 設計書
   - システムアーキテクチャ
   - 技術スタックとコンポーネント設計
   - データモデルとインターフェース定義
   - 担当: 子Claude2
   
3. **tasks.md** - タスク管理書
   - 実装タスクの詳細リスト
   - 優先順位と依存関係
   - 進捗管理チェックリスト
   - 担当: 子Claude3

## 開発タスク一覧

### タスク1: 要件定義の作成
- **タスクID**: TASK001
- **優先度**: 高
- **依存関係**: なし
- **担当**: 子Claude1
- **関連ドキュメント**: requirements.md
- **概要**: Todoアプリケーションの基本要件を定義
- **入力**: プロジェクト概要
- **出力**: 完成したrequirements.md
- **完了条件**: 全ての要件が明確に定義されている

### タスク2: システム設計
- **タスクID**: TASK002
- **優先度**: 高
- **依存関係**: TASK001
- **担当**: 子Claude2
- **関連ドキュメント**: design.md
- **概要**: アーキテクチャとデータモデルの設計
- **入力**: requirements.md
- **出力**: 完成したdesign.md
- **完了条件**: 実装可能な設計書が完成

### タスク3: 実装タスクの詳細化
- **タスクID**: TASK003
- **優先度**: 高
- **依存関係**: TASK002
- **担当**: 子Claude3
- **関連ドキュメント**: tasks.md
- **概要**: 実装タスクの詳細リストを作成
- **入力**: requirements.md, design.md
- **出力**: 完成したtasks.md
- **完了条件**: 全ての実装タスクが明確に定義されている

### タスク4: 統合とレビュー
- **タスクID**: TASK004
- **優先度**: 高
- **依存関係**: TASK001, TASK002, TASK003
- **担当**: 親Claude
- **関連ドキュメント**: 全ドキュメント
- **概要**: 各ドキュメントの整合性確認と統合
- **入力**: 全てのドキュメント
- **出力**: レビュー済みの統合ドキュメント
- **完了条件**: 全ドキュメントの整合性が確認されている

## ディレクトリ構造
```
claude-parallel-template_test/
├── src/
│   ├── components/    # UIコンポーネント
│   ├── services/      # ビジネスロジック
│   └── utils/         # ユーティリティ関数
├── tests/             # テストファイル
├── docs/              # プロジェクトドキュメント
│   ├── requirements.md  # 要件定義書
│   ├── design.md        # 設計書
│   └── tasks.md         # タスク管理書
├── worktree-parent/   # 親Claude用worktree
├── worktree-child1/   # 子Claude1用worktree（要件）
├── worktree-child2/   # 子Claude2用worktree（設計）
└── worktree-child3/   # 子Claude3用worktree（実装）
```

## 技術スタック
- 言語: JavaScript/TypeScript
- フレームワーク: React
- スタイリング: CSS/Tailwind CSS
- 状態管理: Context API
- ビルドツール: Vite
- テスト: Vitest

## コーディング規約
- 命名規則: camelCase
- インデント: スペース2つ
- コメント: JSDocスタイル
- その他: ESLintの推奨設定に従う

## タスク間の連携方法
1. 各Claudeは自分の担当worktreeとドキュメントで作業
   - 子Claude1: worktree-child1でrequirements.mdを管理
   - 子Claude2: worktree-child2でdesign.mdを管理
   - 子Claude3: worktree-child3でtasks.mdを管理
   - 親Claude: worktree-parentで統合作業
2. 各自のブランチで作業しコミット・プッシュ
3. 親Claudeが定期的に各ブランチをマージして統合
4. ドキュメント間の参照は明確にリンクを記載

## 進捗管理

### 要件関連タスク（子Claude1担当）
- [ ] 基本機能の要件定義
- [ ] ユーザーストーリーの作成
- [ ] 受入基準の定義

### 設計関連タスク（子Claude2担当）
- [ ] アーキテクチャ設計
- [ ] データモデル設計
- [ ] コンポーネント設計

### 実装関連タスク（子Claude3担当）
- [ ] 実装タスクリストの作成
- [ ] 優先順位の設定
- [ ] 工数見積もり

## 注意事項
- 各Claudeは担当ドキュメントを主に編集
- ドキュメント間の整合性を保つため、変更時は関連箇所を明記
- Git Worktreeを使用して並列作業を実施
- 親Claudeは全体の統括とドキュメント間の整合性確認を担当