#!/bin/bash

# Claude作業結果レビューシステム

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# プロジェクトルート
PROJECT_ROOT="$(pwd)"
CLAUDE_TASKS_DIR="${PROJECT_ROOT}/claude-tasks"

# レビュー対象のファイルをリスト表示
list_review_items() {
    echo -e "${BLUE}=== レビュー待ちアイテム ===${NC}"
    
    for role in child1 child2; do
        local completed_dir="${CLAUDE_TASKS_DIR}/${role}/completed"
        if [ -d "$completed_dir" ]; then
            local count=$(ls -1 "$completed_dir" 2>/dev/null | wc -l)
            if [ $count -gt 0 ]; then
                echo -e "\n${YELLOW}${role} の完了アイテム:${NC}"
                ls -la "$completed_dir"
            fi
        fi
    done
}

# ファイルの内容を確認
review_file() {
    local claude_id=$1
    local filename=$2
    local filepath="${CLAUDE_TASKS_DIR}/${claude_id}/completed/${filename}"
    
    if [ -f "$filepath" ]; then
        echo -e "${BLUE}=== ファイル内容: ${filename} ===${NC}"
        
        # ファイルの拡張子を取得
        local extension="${filename##*.}"
        
        # 拡張子に応じて適切な表示方法を選択
        case $extension in
            md|txt)
                cat "$filepath"
                ;;
            js|jsx|ts|tsx|py|java|cpp|c|sh)
                # ソースコードの場合は行番号付きで表示
                cat -n "$filepath"
                ;;
            *)
                echo "バイナリファイルまたは未対応の形式です"
                ;;
        esac
    else
        echo -e "${RED}エラー: ファイルが見つかりません${NC}"
    fi
}

# レビューコメントを作成
create_review_comment() {
    local claude_id=$1
    local task_id=$2
    local review_type=$3  # approve, request_changes, comment
    
    local review_file="${CLAUDE_TASKS_DIR}/parent/review/${task_id}_review_$(date +%Y%m%d_%H%M%S).md"
    
    # レビューテンプレート作成
    cat > "$review_file" << EOF
# レビュー: ${task_id}

## レビュー日時
$(date '+%Y-%m-%d %H:%M:%S')

## レビュー担当
親Claude

## レビュー対象
- Claude: ${claude_id}
- タスク: ${task_id}

## レビュー結果
${review_type}

## コメント
EOF
    
    # エディタでレビューコメントを編集
    echo -e "${YELLOW}レビューコメントを入力してください (終了: Ctrl+D):${NC}"
    cat >> "$review_file"
    
    # レビュー結果に応じてファイルを移動
    case $review_type in
        "approve")
            echo -e "\n## 承認済み" >> "$review_file"
            # 成果物を統合ディレクトリに移動
            mkdir -p "${CLAUDE_TASKS_DIR}/parent/approved"
            cp "${CLAUDE_TASKS_DIR}/${claude_id}/completed/"* "${CLAUDE_TASKS_DIR}/parent/approved/" 2>/dev/null
            echo -e "${GREEN}承認されました！成果物を統合ディレクトリに移動しました。${NC}"
            ;;
        "request_changes")
            echo -e "\n## 要修正" >> "$review_file"
            # タスクをreviewディレクトリに移動
            mkdir -p "${CLAUDE_TASKS_DIR}/${claude_id}/review"
            mv "${CLAUDE_TASKS_DIR}/${claude_id}/completed/${task_id}"* "${CLAUDE_TASKS_DIR}/${claude_id}/review/" 2>/dev/null
            echo -e "${YELLOW}修正が必要です。タスクをレビューディレクトリに移動しました。${NC}"
            ;;
        "comment")
            echo -e "\n## コメントのみ" >> "$review_file"
            echo -e "${BLUE}コメントを記録しました。${NC}"
            ;;
    esac
    
    # 進捗記録に追加
    echo -e "\n## $(date '+%Y-%m-%d %H:%M:%S')\n- ${task_id} のレビュー完了 (${review_type})" >> "${CLAUDE_TASKS_DIR}/shared/progress.md"
}

# 自動レビューチェック
auto_review_check() {
    local filepath=$1
    local issues=""
    
    echo -e "${MAGENTA}=== 自動レビューチェック ===${NC}"
    
    # ファイルの拡張子を取得
    local extension="${filepath##*.}"
    
    # 基本的なチェック
    echo "- ファイルサイズチェック..."
    local filesize=$(stat -f%z "$filepath" 2>/dev/null || stat -c%s "$filepath" 2>/dev/null)
    if [ $filesize -gt 1000000 ]; then
        issues="${issues}\n- 警告: ファイルサイズが大きすぎます (${filesize} bytes)"
    fi
    
    # 言語別のチェック
    case $extension in
        js|jsx|ts|tsx)
            echo "- JavaScript/TypeScriptチェック..."
            # console.logの検出
            if grep -q "console\\.log" "$filepath"; then
                issues="${issues}\n- 警告: console.logが含まれています"
            fi
            # TODOコメントの検出
            if grep -q "TODO\\|FIXME" "$filepath"; then
                issues="${issues}\n- 情報: TODO/FIXMEコメントが含まれています"
            fi
            ;;
        py)
            echo "- Pythonチェック..."
            # print文の検出
            if grep -q "^\\s*print(" "$filepath"; then
                issues="${issues}\n- 警告: print文が含まれています"
            fi
            ;;
    esac
    
    # セキュリティチェック
    echo "- セキュリティチェック..."
    if grep -qE "(password|secret|api_key|token)\\s*=\\s*[\"'][^\"']+[\"']" "$filepath"; then
        issues="${issues}\n- ${RED}重要: ハードコードされた認証情報の可能性があります${NC}"
    fi
    
    # 結果表示
    if [ -n "$issues" ]; then
        echo -e "${YELLOW}検出された問題:${issues}${NC}"
    else
        echo -e "${GREEN}自動チェック: 問題なし${NC}"
    fi
}

# 統合前の最終確認
final_integration_check() {
    echo -e "${BLUE}=== 統合前最終確認 ===${NC}"
    
    local approved_dir="${CLAUDE_TASKS_DIR}/parent/approved"
    if [ ! -d "$approved_dir" ]; then
        echo -e "${RED}承認済みファイルがありません${NC}"
        return
    fi
    
    echo -e "${GREEN}承認済みファイル:${NC}"
    ls -la "$approved_dir"
    
    echo -e "\n${YELLOW}これらのファイルをプロジェクトに統合しますか？ (y/n):${NC}"
    read -n 1 confirm
    echo
    
    if [ "$confirm" = "y" ]; then
        # バックアップ作成
        local backup_dir="${PROJECT_ROOT}/backups/$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        
        # 統合実行
        echo -e "${BLUE}統合を実行しています...${NC}"
        
        # ファイルをコピー（実際のプロジェクト構造に応じて調整）
        # 例: cp "$approved_dir"/*.js "${PROJECT_ROOT}/src/"
        
        echo -e "${GREEN}統合完了！バックアップは ${backup_dir} に保存されました。${NC}"
        
        # 統合記録
        echo -e "\n## $(date '+%Y-%m-%d %H:%M:%S')\n- 統合実行: $(ls -1 $approved_dir | wc -l) ファイル" >> "${CLAUDE_TASKS_DIR}/shared/progress.md"
    else
        echo -e "${YELLOW}統合をキャンセルしました${NC}"
    fi
}

# メニュー表示
show_menu() {
    echo -e "\n${BLUE}=== Claudeレビューシステム ===${NC}"
    echo "1) レビュー待ちアイテムを表示"
    echo "2) ファイル内容を確認"
    echo "3) レビューコメントを作成"
    echo "4) 自動レビューチェック実行"
    echo "5) 統合前最終確認"
    echo "6) 終了"
    echo -n "選択してください (1-6): "
}

# メイン処理
main() {
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                list_review_items
                ;;
            2)
                echo -n "Claude ID (child1/child2): "
                read claude_id
                echo -n "ファイル名: "
                read filename
                review_file "$claude_id" "$filename"
                ;;
            3)
                echo -n "Claude ID (child1/child2): "
                read claude_id
                echo -n "タスクID: "
                read task_id
                echo "レビュータイプを選択:"
                echo "1) approve (承認)"
                echo "2) request_changes (修正依頼)"
                echo "3) comment (コメントのみ)"
                echo -n "選択 (1-3): "
                read review_choice
                case $review_choice in
                    1) review_type="approve" ;;
                    2) review_type="request_changes" ;;
                    3) review_type="comment" ;;
                    *) echo -e "${RED}無効な選択${NC}"; continue ;;
                esac
                create_review_comment "$claude_id" "$task_id" "$review_type"
                ;;
            4)
                echo -n "チェックするファイルのパス: "
                read filepath
                auto_review_check "$filepath"
                ;;
            5)
                final_integration_check
                ;;
            6)
                echo -e "${GREEN}終了します${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}無効な選択です${NC}"
                ;;
        esac
    done
}

# スクリプト実行
main