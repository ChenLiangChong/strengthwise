"""
批量替換 SnackBar 為 SnackBarHelper 的腳本
"""
import re
import os
from pathlib import Path

# 需要處理的文件列表
files = [
    'lib/views/pages/training_page.dart',
    'lib/views/pages/custom_exercises_page.dart',
    'lib/views/pages/workout/template_editor_page.dart',
    'lib/views/pages/booking_page.dart',
    'lib/views/widgets/exercise_selection_navigator.dart',
    'lib/views/widgets/favorite_exercises_list.dart',
]

def add_import_if_needed(content):
    """添加 SnackBarHelper 的 import"""
    if "import '../../utils/snackbar_helper.dart';" in content or "import '../../../utils/snackbar_helper.dart';" in content:
        return content
    
    # 找到最後一個 import 語句
    import_pattern = r"(import\s+['\"].*?['\"];)"
    imports = list(re.finditer(import_pattern, content))
    
    if imports:
        last_import = imports[-1]
        end_pos = last_import.end()
        
        # 判斷需要的層級
        if 'lib/views/pages/' in content or 'lib/views/widgets/' in content:
            if 'lib/views/pages/workout/' in content:
                import_statement = "\nimport '../../../utils/snackbar_helper.dart';"
            else:
                import_statement = "\nimport '../../utils/snackbar_helper.dart';"
        else:
            import_statement = "\nimport '../../utils/snackbar_helper.dart';"
        
        content = content[:end_pos] + import_statement + content[end_pos:]
    
    return content

def replace_snackbar(content):
    """替換 SnackBar 為 SnackBarHelper"""
    
    # 替換成功訊息
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\('([^']*已.*|.*成功.*|.*完成.*)'\)\s*\)\s*\)",
        r"SnackBarHelper.showSuccess(context, '\1')",
        content
    )
    
    # 替換錯誤訊息
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\('([^']*失敗.*|.*錯誤.*)'\)\s*\)\s*\)",
        r"SnackBarHelper.showError(context, '\1')",
        content
    )
    
    # 替換警告訊息
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const\s+SnackBar\(\s*content:\s*Text\('([^']*無法.*|.*不能.*)'\)\s*\)\s*\)",
        r"SnackBarHelper.showWarning(context, '\1')",
        content
    )
    
    # 替換一般訊息 (const SnackBar)
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const\s+SnackBar\(\s*content:\s*Text\('([^']*)'\)\s*\)\s*\)",
        r"SnackBarHelper.showInfo(context, '\1')",
        content
    )
    
    # 替換一般訊息 (SnackBar)
    content = re.sub(
        r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\('([^']*)'\)\s*\)\s*\)",
        r"SnackBarHelper.showInfo(context, '\1')",
        content
    )
    
    return content

def process_file(filepath):
    """處理單個文件"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # 添加 import
        content = add_import_if_needed(content)
        
        # 替換 SnackBar
        content = replace_snackbar(content)
        
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ 已處理: {filepath}")
            return True
        else:
            print(f"⏭️  跳過: {filepath} (無需修改)")
            return False
    except Exception as e:
        print(f"❌ 錯誤: {filepath} - {e}")
        return False

def main():
    """主函數"""
    print("開始批量替換 SnackBar...")
    print("=" * 50)
    
    modified_count = 0
    for file_path in files:
        if os.path.exists(file_path):
            if process_file(file_path):
                modified_count += 1
        else:
            print(f"⚠️  文件不存在: {file_path}")
    
    print("=" * 50)
    print(f"完成！共修改 {modified_count} 個文件")

if __name__ == '__main__':
    main()

