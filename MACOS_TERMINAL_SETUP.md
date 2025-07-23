# macOS Terminal設定ガイド - tmuxでOptionキーを使用する

## 問題と解決方法

macOSのTerminal.appやiTerm2では、デフォルトでOptionキーが特殊文字入力用に設定されているため、tmuxのショートカットが動作しない場合があります。

## Terminal.appでの設定

1. **Terminal.appを開く**
2. **メニューバー → Terminal → 環境設定（Preferences）**
3. **「プロファイル」タブを選択**
4. **使用中のプロファイルを選択**
5. **「キーボード」タブを選択**
6. **「メタキーとしてOptionキーを使用」にチェック**

## iTerm2での設定

1. **iTerm2を開く**
2. **メニューバー → iTerm2 → Preferences（⌘,）**
3. **「Profiles」タブを選択**
4. **使用中のプロファイルを選択**
5. **「Keys」タブを選択**
6. **Left Option Key: 「Esc+」を選択**
7. **Right Option Key: 「Esc+」を選択**

## 設定後の確認

設定後、tmuxセッション内で以下のショートカットが使用可能になります：

- `⌥+1` : 親Claude（ウィンドウ0）へ移動
- `⌥+2` : 子Claude1（ウィンドウ1）へ移動
- `⌥+3` : 子Claude2（ウィンドウ2）へ移動
- `⌥+4` : 子Claude3（ウィンドウ3）へ移動
- `⌥+5` : Git管理（ウィンドウ4）へ移動
- `⌥+←` : 前のウィンドウへ
- `⌥+→` : 次のウィンドウへ

## 代替方法

Optionキーの設定を変更したくない場合は、従来のtmuxコマンドを使用：

- `Ctrl+b` → `0-4` : ウィンドウ番号で切り替え
- `Ctrl+b` → `n` : 次のウィンドウ
- `Ctrl+b` → `p` : 前のウィンドウ

## トラブルシューティング

### ショートカットが動作しない場合

1. **tmux設定を再読み込み**
   ```bash
   tmux source-file ~/.tmux.conf
   ```

2. **tmuxセッションを再起動**
   ```bash
   tmux kill-session -t claude-parallel-dev
   ./setup-parallel-tmux.sh
   ```

3. **Terminal/iTerm2を再起動**

### 特定のキーが入力されてしまう場合

Optionキーが特殊文字を入力してしまう場合は、上記のTerminal設定を確認してください。