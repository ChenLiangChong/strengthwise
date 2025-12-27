#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""檢查訓練類型和自訂動作的資料"""

import sys
import os
from dotenv import load_dotenv
from supabase import create_client, Client
import json

# 設置 UTF-8 輸出
sys.stdout.reconfigure(encoding='utf-8')

# 獲取專案根目錄
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
ENV_FILE = os.path.join(PROJECT_ROOT, '.env')

# 載入環境變數
if os.path.exists(ENV_FILE):
    with open(ENV_FILE, 'r', encoding='utf-8-sig') as f:
        env_content = f.read()
    temp_env = ENV_FILE + '.tmp'
    with open(temp_env, 'w', encoding='utf-8') as f:
        f.write(env_content)
    load_dotenv(temp_env)
    os.remove(temp_env)

# Supabase 配置
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[ERROR] 請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY 環境變數")
    sys.exit(1)

# 初始化 Supabase Client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

USER_ID = 'd1798674-0b96-4c47-a7c7-ee20a5372a03'

def main():
    print("=" * 80)
    print("檢查訓練類型資料")
    print("=" * 80)
    
    try:
        # 1. 查詢 exercise_types 表格
        print("\n📋 查詢 exercise_types 表格...")
        response = supabase.table('exercise_types')\
            .select('name')\
            .order('name')\
            .execute()
        
        print(f"\n找到 {len(response.data)} 個訓練類型:")
        for item in response.data:
            print(f"  - {item['name']}")
        
        # 2. 查詢自訂動作
        print("\n" + "=" * 80)
        print("檢查自訂動作")
        print("=" * 80)
        
        response = supabase.table('custom_exercises')\
            .select('*')\
            .eq('user_id', USER_ID)\
            .execute()
        
        print(f"\n找到 {len(response.data)} 個自訂動作:")
        for ex in response.data:
            print(f"\n動作 ID: {ex['id']}")
            print(f"  名稱: {ex['name']}")
            print(f"  訓練類型: {ex.get('type', '未設定')}")
            print(f"  身體部位: {ex.get('body_parts', '未設定')}")
            print(f"  完整資料:")
            print(f"  {json.dumps(ex, indent=4, ensure_ascii=False)}")
        
        # 3. 檢查訓練記錄中使用的自訂動作
        print("\n" + "=" * 80)
        print("檢查訓練記錄中的自訂動作使用情況")
        print("=" * 80)
        
        response = supabase.table('workout_plans')\
            .select('id, title, exercises')\
            .eq('user_id', USER_ID)\
            .eq('completed', True)\
            .order('completed_date', desc=True)\
            .limit(5)\
            .execute()
        
        custom_exercise_ids = set()
        
        for plan in response.data:
            exercises = plan.get('exercises', [])
            for ex in exercises:
                ex_id = ex.get('exerciseId')
                ex_name = ex.get('exerciseName')
                
                # 檢查是否為自訂動作（ID 以 custom_ 開頭或在 custom_exercises 表中）
                if ex_id:
                    # 檢查是否在系統動作中
                    sys_response = supabase.table('exercises')\
                        .select('id')\
                        .eq('id', ex_id)\
                        .execute()
                    
                    if not sys_response.data:
                        custom_exercise_ids.add(ex_id)
                        print(f"\n找到自訂動作: {ex_name} (ID: {ex_id})")
                        print(f"  出現在訓練: {plan['title']}")
        
        if custom_exercise_ids:
            print(f"\n總共找到 {len(custom_exercise_ids)} 個使用中的自訂動作 ID:")
            for ex_id in custom_exercise_ids:
                print(f"  - {ex_id}")
        else:
            print("\n✅ 沒有找到使用中的自訂動作")
        
    except Exception as e:
        print(f"\n❌ 查詢失敗: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()

