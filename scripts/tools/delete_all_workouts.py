#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
刪除所有訓練記錄（workout_plans）

使用方式：
    python scripts/tools/delete_all_workouts.py [user_id]
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
else:
    load_dotenv()

# Supabase 配置
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[ERROR] 請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY 環境變數")
    sys.exit(1)

# 初始化 Supabase Client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def delete_all_workouts(user_id: str):
    """刪除所有訓練記錄"""
    print("=" * 60)
    print("刪除訓練記錄")
    print("=" * 60)
    print(f"目標用戶: {user_id}")
    
    try:
        # 刪除 workout_plans
        result = supabase.table('workout_plans')\
            .delete()\
            .eq('trainee_id', user_id)\
            .execute()
        
        deleted_count = len(result.data) if result.data else 0
        print(f"✅ 已刪除 {deleted_count} 筆訓練記錄")
        
    except Exception as e:
        print(f"❌ 刪除失敗: {e}")
        sys.exit(1)

def main():
    """主函數"""
    user_id = None
    auto_confirm = False
    
    if len(sys.argv) > 1:
        user_id = sys.argv[1]
        auto_confirm = len(sys.argv) > 2 and sys.argv[2] == '-y'
    else:
        print("未指定 User ID")
        user_id = input("請輸入 User ID: ").strip()
        if not user_id:
            print("❌ 必須提供 User ID")
            sys.exit(1)
    
    if not auto_confirm:
        confirm = input(f"確定要刪除用戶 {user_id} 的所有訓練記錄嗎？(y/N): ").strip().lower()
        if confirm != 'y':
            print("已取消")
            sys.exit(0)
    
    delete_all_workouts(user_id)

if __name__ == "__main__":
    main()

