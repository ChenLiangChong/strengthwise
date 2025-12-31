#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""檢查訓練計劃中的動作數據"""

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
    print("檢查訓練計劃數據")
    print("=" * 80)
    
    try:
        # 查詢最近一筆訓練計劃
        response = supabase.table('workout_plans')\
            .select('id, title, completed, exercises')\
            .eq('user_id', USER_ID)\
            .order('scheduled_date', desc=True)\
            .limit(1)\
            .execute()
        
        if not response.data:
            print("❌ 沒有找到訓練計劃")
            return
        
        plan = response.data[0]
        
        print(f"\n📋 訓練計劃 ID: {plan['id']}")
        print(f"📝 標題: {plan['title']}")
        print(f"✅ 完成狀態: {plan['completed']}")
        print(f"\n🏋️ Exercises 欄位內容:")
        print("-" * 80)
        
        exercises = plan['exercises']
        
        if not exercises:
            print("❌ exercises 欄位是空的！")
        elif isinstance(exercises, list):
            print(f"✅ exercises 是陣列，長度: {len(exercises)}")
            
            if len(exercises) > 0:
                print(f"\n第一個動作的結構:")
                print(json.dumps(exercises[0], indent=2, ensure_ascii=False))
                
                # 檢查必要欄位
                first_ex = exercises[0]
                print(f"\n欄位檢查:")
                print(f"  - 有 'exerciseId': {'exerciseId' in first_ex}")
                print(f"  - 有 'exerciseName': {'exerciseName' in first_ex}")
                print(f"  - 有 'sets': {'sets' in first_ex}")
                print(f"  - 有 'completed': {'completed' in first_ex}")
                
                if 'sets' in first_ex:
                    sets = first_ex['sets']
                    if isinstance(sets, list):
                        print(f"  - sets 是陣列，長度: {len(sets)}")
                        if len(sets) > 0:
                            print(f"\n第一組的結構:")
                            print(json.dumps(sets[0], indent=2, ensure_ascii=False))
                    else:
                        print(f"  - ❌ sets 不是陣列！類型: {type(sets)}")
            else:
                print("❌ exercises 陣列是空的！")
        else:
            print(f"❌ exercises 不是陣列！類型: {type(exercises)}")
            print(f"內容: {exercises}")
        
    except Exception as e:
        print(f"\n❌ 查詢失敗: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()

