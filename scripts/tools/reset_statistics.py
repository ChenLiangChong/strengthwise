#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
完整重置統計資料
- 清空 daily_workout_summary
- 清空 personal_records
- 觸發所有 workout_plans 重新計算
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

def reset_statistics(user_id: str = None):
    """重置統計資料"""
    print("=" * 60)
    print("重置統計資料")
    print("=" * 60)
    
    if user_id:
        print(f"目標用戶: {user_id}")
    else:
        print("目標: 所有用戶")
    
    try:
        # 步驟 1: 清空 daily_workout_summary
        print("\n步驟 1: 清空 daily_workout_summary...")
        if user_id:
            result = supabase.table('daily_workout_summary')\
                .delete()\
                .eq('user_id', user_id)\
                .execute()
        else:
            result = supabase.rpc('exec_sql', {
                'query': 'TRUNCATE TABLE daily_workout_summary;'
            }).execute()
        print(f"✅ 已清空 daily_workout_summary")
        
        # 步驟 2: 清空 personal_records
        print("\n步驟 2: 清空 personal_records...")
        if user_id:
            result = supabase.table('personal_records')\
                .delete()\
                .eq('user_id', user_id)\
                .execute()
        else:
            result = supabase.rpc('exec_sql', {
                'query': 'TRUNCATE TABLE personal_records;'
            }).execute()
        print(f"✅ 已清空 personal_records")
        
        # 步驟 3: 觸發重新計算
        print("\n步驟 3: 觸發所有訓練記錄重新計算...")
        # 查詢所有訓練記錄
        query = supabase.table('workout_plans').select('id')
        if user_id:
            query = query.eq('trainee_id', user_id)
        
        result = query.execute()
        workout_ids = [row['id'] for row in result.data]
        
        print(f"   找到 {len(workout_ids)} 筆訓練記錄")
        
        # 逐一更新（觸發觸發器）
        for workout_id in workout_ids:
            supabase.table('workout_plans')\
                .update({'updated_at': 'now()'})\
                .eq('id', workout_id)\
                .execute()
        
        print(f"✅ 已更新 {len(workout_ids)} 筆記錄（觸發器已執行）")
        
        # 步驟 4: 驗證結果
        print("\n步驟 4: 驗證結果...")
        
        # 檢查 daily_workout_summary
        query = supabase.table('daily_workout_summary').select('*', count='exact')
        if user_id:
            query = query.eq('user_id', user_id)
        result = query.execute()
        summary_count = result.count if hasattr(result, 'count') else len(result.data)
        print(f"   daily_workout_summary: {summary_count} 筆")
        
        # 檢查 personal_records
        query = supabase.table('personal_records').select('*', count='exact')
        if user_id:
            query = query.eq('user_id', user_id)
        result = query.execute()
        pr_count = result.count if hasattr(result, 'count') else len(result.data)
        print(f"   personal_records: {pr_count} 筆")
        
        print("\n" + "=" * 60)
        print("✅ 統計資料重置完成！")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n❌ 重置失敗: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

def main():
    """主函數"""
    user_id = None
    
    if len(sys.argv) > 1:
        user_id = sys.argv[1]
        print(f"使用命令列指定的 User ID: {user_id}")
    else:
        print("未指定 User ID，將重置所有用戶的統計資料")
        confirm = input("確定要繼續嗎？(y/N): ").strip().lower()
        if confirm != 'y':
            print("已取消")
            sys.exit(0)
    
    reset_statistics(user_id)

if __name__ == "__main__":
    main()

