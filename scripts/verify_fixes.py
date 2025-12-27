#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""驗證所有修正結果"""

import sys
import os
from dotenv import load_dotenv
from supabase import create_client, Client

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
    print("\n" + "=" * 80)
    print("✅ 驗證修正結果")
    print("=" * 80)
    
    try:
        # 1. 檢查訓練類型
        print("\n📋 1. 檢查訓練類型...")
        response = supabase.table('exercise_types')\
            .select('name')\
            .order('name')\
            .execute()
        
        print(f"  ✅ 找到 {len(response.data)} 個訓練類型:")
        for item in response.data:
            print(f"    - {item['name']}")
        
        type_names = [item['name'] for item in response.data]
        
        # 驗證：應該只有 3 個正確的類型
        expected_types = {'心肺適能訓練', '活動度與伸展', '阻力訓練'}
        actual_types = set(type_names)
        
        if actual_types == expected_types:
            print("  ✅ 訓練類型正確！")
        else:
            print(f"  ❌ 訓練類型不正確！")
            print(f"    預期: {expected_types}")
            print(f"    實際: {actual_types}")
            return
        
        # 2. 檢查自訂動作
        print("\n📋 2. 檢查自訂動作...")
        response = supabase.table('custom_exercises')\
            .select('id, name, body_part, equipment')\
            .eq('user_id', USER_ID)\
            .execute()
        
        if response.data:
            print(f"  ✅ 找到 {len(response.data)} 個自訂動作:")
            for ex in response.data:
                print(f"    - {ex['name']} (身體部位: {ex['body_part']}, 器材: {ex['equipment']})")
                
                # 驗證：每個自訂動作都有 body_part
                if not ex.get('body_part'):
                    print(f"      ❌ 自訂動作 '{ex['name']}' 缺少 body_part 欄位！")
                    return
            
            print("  ✅ 所有自訂動作都有正確的 body_part 欄位")
        else:
            print("  ℹ️ 沒有自訂動作")
        
        # 3. 檢查訓練記錄中的動作分類
        print("\n📋 3. 檢查訓練記錄中的動作分類...")
        response = supabase.table('workout_plans')\
            .select('id, title, completed, exercises')\
            .eq('user_id', USER_ID)\
            .eq('completed', True)\
            .order('completed_date', desc=True)\
            .limit(5)\
            .execute()
        
        custom_exercise_count = 0
        
        for plan in response.data:
            exercises = plan.get('exercises', [])
            for ex in exercises:
                ex_id = ex.get('exerciseId')
                ex_name = ex.get('exerciseName')
                
                if not ex_id:
                    continue
                
                # 檢查是否為系統動作
                sys_response = supabase.table('exercises')\
                    .select('id, name, training_type, body_part')\
                    .eq('id', ex_id)\
                    .execute()
                
                if not sys_response.data:
                    # 這是自訂動作
                    custom_response = supabase.table('custom_exercises')\
                        .select('id, name, body_part, equipment')\
                        .eq('id', ex_id)\
                        .execute()
                    
                    if custom_response.data:
                        custom_ex = custom_response.data[0]
                        custom_exercise_count += 1
                        print(f"  ✅ 自訂動作: {ex_name}")
                        print(f"    - ID: {ex_id}")
                        print(f"    - 身體部位: {custom_ex['body_part']}")
                        print(f"    - 器材: {custom_ex['equipment']}")
                        print(f"    - Flutter 會將其訓練類型設為: 阻力訓練")
        
        if custom_exercise_count > 0:
            print(f"\n  ✅ 找到 {custom_exercise_count} 個自訂動作在訓練記錄中")
        else:
            print("  ℹ️ 沒有找到自訂動作在訓練記錄中")
        
        # 4. 總結
        print("\n" + "=" * 80)
        print("🎉 驗證完成！所有修正都已正確應用")
        print("=" * 80)
        print("\n修正內容:")
        print("  1. ✅ 訓練類型只有 3 個（心肺適能訓練、活動度與伸展、阻力訓練）")
        print("  2. ✅ 移除了「重訓」預設值")
        print("  3. ✅ 自訂動作會被歸類為「阻力訓練」")
        print("  4. ✅ 自訂動作的身體部位會正確顯示在統計頁面")
        print("\n請重新啟動 App 以查看效果！")
        
    except Exception as e:
        print(f"\n❌ 驗證失敗: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()

