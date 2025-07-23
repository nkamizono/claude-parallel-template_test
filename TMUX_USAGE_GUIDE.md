# tmux並列開発環境の使用ガイド

## tmuxセッションの準備完了！

現在、`claude-parallel-dev`というtmuxセッションが作成されています。

## セッションへのアタッチ方法

```bash
tmux attach-session -t claude-parallel-dev
```

または短縮形:
```bash
tmux a -t claude-parallel-dev
```

## tmux内での操作方法

### 基本操作
- **プレフィックスキー**: `Ctrl+b` （以下、C-bと表記）
- **ウィンドウ切り替え**:
  - `C-b 0` : 親Claude（parent）
  - `C-b 1` : 子Claude1（要件担当）
  - `C-b 2` : 子Claude2（設計担当）
  - `C-b 3` : 子Claude3（実装担当）
  - `C-b 4` : Git管理ウィンドウ
  - `C-b n` : 次のウィンドウ
  - `C-b p` : 前のウィンドウ

### 便利なショートカット（.tmux.conf設定済み）
- `Option+1` (⌥+1) : ウィンドウ1へ直接移動
- `Option+2` (⌥+2) : ウィンドウ2へ直接移動
- `Option+3` (⌥+3) : ウィンドウ3へ直接移動
- `Option+4` (⌥+4) : ウィンドウ4へ直接移動
- `Option+5` (⌥+5) : ウィンドウ5へ直接移動
- `Option+←` (⌥+←) : 前のウィンドウへ
- `Option+→` (⌥+→) : 次のウィンドウへ

### その他の操作
- `C-b d` : セッションからデタッチ（バックグラウンドで実行継続）
- `C-b ?` : キーバインド一覧表示
- `C-b [` : スクロールモード（矢印キーでスクロール、qで終了）

## 各ウィンドウでの作業開始

1. **tmuxセッションにアタッチ**
   ```bash
   tmux attach-session -t claude-parallel-dev
   ```

2. **各ウィンドウでClaudeを起動**
   
   各ウィンドウに移動して`claude`コマンドを実行し、以下のメッセージを送信:

   **ウィンドウ0（親Claude）:**
   ```
   私は親Claudeです。feature/integrationブランチで作業します。
   各子Claudeの成果物を統合し、全体の整合性を確保します。
   development-spec.mdを確認して開始します。
   ```

   **ウィンドウ1（子Claude1）:**
   ```
   私は子Claude1です。feature/requirementsブランチで作業します。
   development-spec.mdに基づいて、Todoアプリケーションのrequirements.mdを作成します。
   ```

   **ウィンドウ2（子Claude2）:**
   ```
   私は子Claude2です。feature/designブランチで作業します。
   子Claude1が作成するrequirements.mdを確認後、design.mdを作成します。
   ```

   **ウィンドウ3（子Claude3）:**
   ```
   私は子Claude3です。feature/implementationブランチで作業します。
   requirements.mdとdesign.mdを確認後、tasks.mdを作成します。
   ```

## 作業の流れ

1. 各ウィンドウでClaudeセッションを開始
2. 子Claude1が要件定義を作成
3. 子Claude2が設計書を作成
4. 子Claude3が実装タスクを作成
5. 親Claudeが統合とレビュー

## トラブルシューティング

### セッションが見つからない場合
```bash
tmux list-sessions
```

### 新しいセッションを作成
```bash
./setup-parallel-tmux.sh
```

### tmuxを終了
```bash
tmux kill-session -t claude-parallel-dev
```

## 注意事項

- 各Claudeは独立したworktreeで作業するため、ファイルの競合は発生しません
- 定期的に`git fetch origin`で他のClaudeの変更を確認してください
- tmuxセッションはデタッチしても継続されるため、後で再接続可能です