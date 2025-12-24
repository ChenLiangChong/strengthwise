#!/usr/bin/env python3
"""
批量顏色替換腳本
自動將所有 Colors.green, Colors.purple 等替換為主題色
"""

import re
import os
from pathlib import Path

# 替換規則
REPLACEMENTS = [
    # ElevatedButton.styleFrom 中的綠色
    (
        r"ElevatedButton\.styleFrom\(\s*backgroundColor:\s*Colors\.green,?",
        "ElevatedButton.styleFrom("
    ),
    # FloatingActionButton 中的綠色
    (
        r"FloatingActionButton\((.*?)backgroundColor:\s*Colors\.green,?",
        r"FloatingActionButton(\1"
    ),
    # SnackBar 中的綠色
    (
        r"SnackBar\(\s*(.*?)backgroundColor:\s*Colors\.green,",
        r"SnackBar(\n            \1backgroundColor: Theme.of(context).colorScheme.primary,"
    ),
    # CircleAvatar 中的綠色
    (
        r"CircleAvatar\(\s*backgroundColor:\s*Colors\.green,",
        "CircleAvatar(\n                                            backgroundColor: Theme.of(context).colorScheme.primary,"
    ),
]

def replace_colors_in_file(file_path):
    """在單個文件中替換顏色"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    for pattern, replacement in REPLACEMENTS:
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
    
    # 如果內容有變化，寫回文件
    if content != original_content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    
    return False

def main():
    """主函數"""
    # 要處理的文件列表
    files_to_process = [
        'lib/views/pages/workout/template_editor_page.dart',
        'lib/views/pages/workout/workout_execution_page.dart',
        'lib/views/pages/workout/plan_editor_page.dart',
        'lib/views/pages/workout/template_management_page.dart',
        'lib/views/pages/workout/template_editor_page_clean.dart',
        'lib/views/pages/exercise_detail_page.dart',
    ]
    
    project_root = Path(__file__).parent.parent
    
    modified_files = []
    
    for file_path in files_to_process:
        full_path = project_root / file_path
        if full_path.exists():
            if replace_colors_in_file(full_path):
                modified_files.append(file_path)
                print(f"✅ 已處理: {file_path}")
            else:
                print(f"⏭️  跳過 (無需修改): {file_path}")
        else:
            print(f"❌ 文件不存在: {file_path}")
    
    print(f"\n📊 總結: 成功修改 {len(modified_files)} 個文件")
    
    if modified_files:
        print("\n修改的文件列表:")
        for file_path in modified_files:
            print(f"  - {file_path}")

if __name__ == '__main__':
    main()

