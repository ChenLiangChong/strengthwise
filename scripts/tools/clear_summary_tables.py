#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
清空統計彙總表（daily_workout_summary 和 personal_records）

用途：
- 當手動刪除 workout_plans 資料時，需要清空對應的統計表
- 或者重新初始化統計資料

使用方式：
    python scripts/tools/clear_summary_tables.py [user_id]
"""

import sys
import os
from dotenv import load_dotenv
from supabase import create_client, Client

# Set UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

# Get project root and load environment variables
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
ENV_FILE = os.path.join(PROJECT_ROOT, '.env')

# Load environment variables (handle BOM)
if os.path.exists(ENV_FILE):
    with open(ENV_FILE, 'r', encoding='utf-8-sig') as f:
        env_content = f.read()
    temp_env = ENV_FILE + '.tmp'
    with open(temp_env, 'w', encoding='utf-8') as f:
        f.write(env_content)
    load_dotenv(temp_env)
    os.remove(temp_env)
    print(f"✅ Loaded environment variables: {ENV_FILE}")
else:
    load_dotenv()
    print(f"⚠️  Warning: .env file not found at {ENV_FILE}")

# Supabase 配置
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[ERROR] 請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY 環境變數")
    sys.exit(1)

# 初始化 Supabase Client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def clear_summary_tables(user_id: str):
    """清空指定用戶的統計彙總表"""
    print("=" * 60)
    print("清空統計彙總表")
    print("=" * 60)
    print(f"目標用戶: {user_id}")
    
    try:
        # 清空 daily_workout_summary
        result1 = supabase.table('daily_workout_summary')\
            .delete()\
            .eq('user_id', user_id)\
            .execute()
        deleted_summary = len(result1.data) if result1.data else 0
        print(f"✅ 已清空 daily_workout_summary: {deleted_summary} 筆")
        
        # 清空 personal_records
        result2 = supabase.table('personal_records')\
            .delete()\
            .eq('user_id', user_id)\
            .execute()
        deleted_pr = len(result2.data) if result2.data else 0
        print(f"✅ 已清空 personal_records: {deleted_pr} 筆")
        
        print("=" * 60)
        print("完成！統計表已清空")
        print("提示：新增 workout_plans 時，觸發器會自動重新生成統計資料")
        
    except Exception as e:
        print(f"❌ 清空失敗: {e}")
        sys.exit(1)

def main():
    """主函數"""
    if len(sys.argv) < 2:
        print("❌ 必須指定 User ID")
        print("用法: python clear_summary_tables.py <user_uuid>")
        sys.exit(1)
    
    user_id = sys.argv[1]
    print(f"使用命令列指定的 User ID: {user_id}")
    clear_summary_tables(user_id)

if __name__ == "__main__":
    main()

