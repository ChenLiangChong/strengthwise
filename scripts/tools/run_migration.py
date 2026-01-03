#!/usr/bin/env python3
"""
執行單個 Migration 腳本到 Supabase
"""
import os
from supabase import create_client
from dotenv import load_dotenv
import sys

# 載入環境變數
load_dotenv('../.env')

SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
    print("❌ 缺少 Supabase 環境變數")
    sys.exit(1)

# 初始化 Supabase client
supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

def execute_migration(sql_file):
    """執行 SQL 文件"""
    print(f"📦 讀取 {sql_file}...")
    
    with open(sql_file, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    print(f"🚀 執行 SQL...")
    
    try:
        # 執行 SQL（使用 RPC 調用）
        result = supabase.rpc('exec_sql', {'sql': sql_content}).execute()
        print(f"✅ 成功執行 {sql_file}")
        return True
    except Exception as e:
        # 直接使用 postgrest API 執行 SQL
        print(f"⚠️ RPC 方法失敗，嘗試直接執行...")
        print(f"❌ 錯誤: {e}")
        print("\n請手動執行以下 SQL：")
        print("=" * 60)
        print(sql_content)
        print("=" * 60)
        return False

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("用法: python run_migration.py <sql_file>")
        sys.exit(1)
    
    sql_file = sys.argv[1]
    if not os.path.exists(sql_file):
        print(f"❌ 找不到文件: {sql_file}")
        sys.exit(1)
    
    success = execute_migration(sql_file)
    sys.exit(0 if success else 1)

