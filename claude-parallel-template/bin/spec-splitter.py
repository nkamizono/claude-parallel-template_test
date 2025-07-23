#!/usr/bin/env python3
"""
開発設計書自動分割スクリプト
開発設計書を解析して、親Claudeと子Claude用のタスクに自動分割します
"""

import os
import re
import json
import argparse
from datetime import datetime
from typing import Dict, List, Tuple

class SpecSplitter:
    def __init__(self, spec_file: str):
        self.spec_file = spec_file
        self.tasks = []
        self.dependencies = {}
        self.claude_assignments = {
            'parent': [],
            'child1': [],
            'child2': []
        }
    
    def parse_spec(self) -> None:
        """開発設計書を解析してタスクを抽出"""
        with open(self.spec_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # タスクセクションを探す
        task_pattern = r'### タスク(\d+): (.+?)\n(.*?)(?=### タスク|\Z)'
        matches = re.findall(task_pattern, content, re.DOTALL)
        
        for match in matches:
            task_num, task_name, task_content = match
            task_info = self._parse_task_content(task_content)
            task_info['number'] = int(task_num)
            task_info['name'] = task_name
            self.tasks.append(task_info)
    
    def _parse_task_content(self, content: str) -> Dict:
        """タスクの内容を解析"""
        task_info = {
            'id': '',
            'priority': 'medium',
            'dependencies': [],
            'assigned_to': None,
            'description': '',
            'input': '',
            'output': '',
            'completion_criteria': ''
        }
        
        # 各フィールドを抽出
        patterns = {
            'id': r'タスクID[:\s]+(\w+)',
            'priority': r'優先度[:\s]+(\S+)',
            'dependencies': r'依存関係[:\s]+(.+)',
            'assigned_to': r'担当[:\s]+(.+)',
            'description': r'概要[:\s]+(.+?)(?=\n-|\Z)',
            'input': r'入力[:\s]+(.+?)(?=\n-|\Z)',
            'output': r'出力[:\s]+(.+?)(?=\n-|\Z)',
            'completion_criteria': r'完了条件[:\s]+(.+?)(?=\n|\Z)'
        }
        
        for field, pattern in patterns.items():
            match = re.search(pattern, content, re.MULTILINE | re.DOTALL)
            if match:
                value = match.group(1).strip()
                if field == 'dependencies':
                    # 依存関係をリストに変換
                    if value.lower() == 'なし':
                        task_info[field] = []
                    else:
                        task_info[field] = [dep.strip() for dep in value.split(',')]
                elif field == 'priority':
                    # 優先度を正規化
                    if '高' in value:
                        task_info[field] = 'high'
                    elif '低' in value:
                        task_info[field] = 'low'
                    else:
                        task_info[field] = 'medium'
                else:
                    task_info[field] = value
        
        return task_info
    
    def analyze_dependencies(self) -> None:
        """タスク間の依存関係を分析"""
        for task in self.tasks:
            task_id = task['id']
            self.dependencies[task_id] = {
                'depends_on': task['dependencies'],
                'depended_by': []
            }
        
        # 逆方向の依存関係も記録
        for task in self.tasks:
            task_id = task['id']
            for dep in task['dependencies']:
                if dep in self.dependencies:
                    self.dependencies[dep]['depended_by'].append(task_id)
    
    def assign_tasks(self) -> None:
        """タスクを各Claudeに割り当て"""
        # 既に担当が指定されているタスクを処理
        for task in self.tasks:
            if task['assigned_to']:
                assigned = task['assigned_to'].lower()
                if 'parent' in assigned or '親' in assigned:
                    self.claude_assignments['parent'].append(task)
                elif 'child1' in assigned or '子1' in assigned:
                    self.claude_assignments['child1'].append(task)
                elif 'child2' in assigned or '子2' in assigned:
                    self.claude_assignments['child2'].append(task)
        
        # 未割り当てタスクを自動割り当て
        unassigned = [t for t in self.tasks if not t['assigned_to']]
        
        # 優先度と依存関係に基づいて割り当て
        high_priority = [t for t in unassigned if t['priority'] == 'high']
        medium_priority = [t for t in unassigned if t['priority'] == 'medium']
        low_priority = [t for t in unassigned if t['priority'] == 'low']
        
        # 親Claudeには高優先度や統合系のタスクを割り当て
        for task in high_priority[:len(high_priority)//3]:
            self.claude_assignments['parent'].append(task)
            task['assigned_to'] = '親Claude'
        
        # 残りを子Claudeに均等に割り当て
        remaining = high_priority[len(high_priority)//3:] + medium_priority + low_priority
        for i, task in enumerate(remaining):
            if i % 2 == 0:
                self.claude_assignments['child1'].append(task)
                task['assigned_to'] = '子Claude1'
            else:
                self.claude_assignments['child2'].append(task)
                task['assigned_to'] = '子Claude2'
    
    def generate_task_files(self, output_dir: str) -> None:
        """各Claude用のタスクファイルを生成"""
        os.makedirs(output_dir, exist_ok=True)
        
        # 各Claude用のディレクトリ作成
        for role in ['parent', 'child1', 'child2']:
            role_dir = os.path.join(output_dir, role)
            os.makedirs(role_dir, exist_ok=True)
            
            # タスクファイル作成
            tasks_file = os.path.join(role_dir, 'tasks.md')
            with open(tasks_file, 'w', encoding='utf-8') as f:
                f.write(f"# {role}のタスク一覧\n\n")
                f.write(f"生成日時: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
                
                if self.claude_assignments[role]:
                    f.write("## 割り当てタスク\n\n")
                    for task in self.claude_assignments[role]:
                        f.write(f"### {task['id']}: {task['name']}\n")
                        f.write(f"- **優先度**: {task['priority']}\n")
                        f.write(f"- **依存関係**: {', '.join(task['dependencies']) if task['dependencies'] else 'なし'}\n")
                        f.write(f"- **概要**: {task['description']}\n")
                        f.write(f"- **入力**: {task['input']}\n")
                        f.write(f"- **出力**: {task['output']}\n")
                        f.write(f"- **完了条件**: {task['completion_criteria']}\n\n")
                else:
                    f.write("現在割り当てられたタスクはありません。\n")
        
        # 共有ディレクトリに依存関係マップを保存
        shared_dir = os.path.join(output_dir, 'shared')
        os.makedirs(shared_dir, exist_ok=True)
        
        deps_file = os.path.join(shared_dir, 'dependencies.json')
        with open(deps_file, 'w', encoding='utf-8') as f:
            json.dump(self.dependencies, f, ensure_ascii=False, indent=2)
        
        # 全体のタスクマップも保存
        task_map_file = os.path.join(shared_dir, 'task_map.md')
        with open(task_map_file, 'w', encoding='utf-8') as f:
            f.write("# タスク割り当てマップ\n\n")
            f.write(f"生成日時: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            for role, tasks in self.claude_assignments.items():
                f.write(f"## {role}\n")
                for task in tasks:
                    f.write(f"- {task['id']}: {task['name']} (優先度: {task['priority']})\n")
                f.write("\n")
    
    def generate_gantt_chart(self, output_file: str) -> None:
        """簡易的なガントチャート（テキスト形式）を生成"""
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("# タスクスケジュール（ガントチャート）\n\n")
            f.write("```\n")
            f.write("タスク     担当      優先度  依存  |----週1----|----週2----|----週3----|\n")
            f.write("-" * 75 + "\n")
            
            for task in sorted(self.tasks, key=lambda x: (x['priority'] != 'high', x['number'])):
                task_id = task['id'].ljust(10)
                assigned = (task['assigned_to'] or '未割当').ljust(10)[:10]
                priority = task['priority'].ljust(6)
                deps = ','.join(task['dependencies'])[:5].ljust(5)
                
                # 優先度に応じてバーの位置を決定
                if task['priority'] == 'high':
                    bar = "████████████"
                elif task['priority'] == 'medium':
                    bar = "    ████████████"
                else:
                    bar = "        ████████████"
                
                f.write(f"{task_id} {assigned} {priority} {deps} |{bar}|\n")
            
            f.write("```\n")

def main():
    parser = argparse.ArgumentParser(description='開発設計書を自動分割してClaude用タスクを生成')
    parser.add_argument('spec_file', help='開発設計書のファイルパス')
    parser.add_argument('-o', '--output', default='claude-tasks', help='出力ディレクトリ')
    parser.add_argument('-g', '--gantt', action='store_true', help='ガントチャートも生成')
    
    args = parser.parse_args()
    
    # 設計書が存在するか確認
    if not os.path.exists(args.spec_file):
        print(f"エラー: 設計書ファイル '{args.spec_file}' が見つかりません")
        return 1
    
    # 分割処理実行
    splitter = SpecSplitter(args.spec_file)
    
    print("開発設計書を解析中...")
    splitter.parse_spec()
    
    print(f"{len(splitter.tasks)}個のタスクを検出しました")
    
    print("依存関係を分析中...")
    splitter.analyze_dependencies()
    
    print("タスクを割り当て中...")
    splitter.assign_tasks()
    
    print("タスクファイルを生成中...")
    splitter.generate_task_files(args.output)
    
    if args.gantt:
        print("ガントチャートを生成中...")
        gantt_file = os.path.join(args.output, 'shared', 'gantt_chart.md')
        splitter.generate_gantt_chart(gantt_file)
    
    # 結果サマリー表示
    print("\n=== 割り当て結果 ===")
    for role, tasks in splitter.claude_assignments.items():
        print(f"{role}: {len(tasks)}タスク")
        for task in tasks:
            print(f"  - {task['id']}: {task['name']} (優先度: {task['priority']})")
    
    print(f"\nタスクファイルが '{args.output}' に生成されました")
    return 0

if __name__ == '__main__':
    exit(main())