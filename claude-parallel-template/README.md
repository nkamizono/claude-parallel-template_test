# Claude並列開発システム テンプレート

複数のClaude Codeインスタンスを使用して効率的に並列開発を行うためのシステムテンプレートです。

## 🚀 クイックスタート

```bash
# 1. テンプレートをクローン
git clone <this-repo> claude-parallel-template
cd claude-parallel-template

# 2. 新しいプロジェクトを初期化
./init-project.sh

# 3. プロジェクトディレクトリに移動
cd your-project

# 4. 開発設計書を編集
vim development-spec.md

# 5. 開発を開始
./cpd setup  # タスク分割
./cpd start  # セッション開始
```

## 📁 テンプレート構造

```
claude-parallel-template/
├── init-project.sh        # プロジェクト初期化スクリプト
├── config.sh             # 設定ファイルテンプレート
├── bin/                  # 実行スクリプト
│   ├── claude-parallel-dev.sh
│   ├── claude-task-manager.sh
│   ├── claude-review-system.sh
│   └── spec-splitter.py
├── templates/            # ドキュメントテンプレート
│   ├── development-spec-template.md
│   ├── parent-claude-guide.md
│   ├── child-claude-guide.md
│   └── .tmux.conf
├── examples/             # サンプルプロジェクト
│   └── todo-app-spec.md
├── docs/                 # ドキュメント
│   └── DETAILED_MANUAL.md
└── README.md            # このファイル
```

## 🔧 必要な環境

- tmux
- Python 3.6+
- Claude Code
- Git

## 📚 ドキュメント

- [詳細マニュアル](./DETAILED_MANUAL.md) - 完全な操作ガイド
- [サンプル設計書](./examples/todo-app-spec.md) - TODOアプリの例

## 🎯 特徴

- **自動タスク分割**: 開発設計書から自動的にタスクを分割
- **進捗管理**: リアルタイムで各Claudeの進捗を追跡
- **レビューシステム**: 成果物の確認と承認プロセス
- **柔軟な構成**: プロジェクトに応じてClaude数を調整可能

## 💡 使用例

### Web開発プロジェクト
- 親Claude: アーキテクチャ設計、レビュー
- 子Claude1: フロントエンド開発
- 子Claude2: バックエンド開発

### データ分析プロジェクト
- 親Claude: 分析設計、結果統合
- 子Claude1: データ前処理
- 子Claude2: モデル開発

## 🤝 コントリビューション

改善提案やバグ報告は歓迎します。Issueを作成してください。

## 📄 ライセンス

MIT License