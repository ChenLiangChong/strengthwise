#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""檢查並清理錯誤的訓練類型"""

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

def main():
    print("=" * 80)
    print("檢查訓練類型資料")
    print("=" * 80)
    
    try:
        # 查詢所有訓練類型
        response = supabase.table('exercise_types')\
            .select('name')\
            .order('name')\
            .execute()
        
        print(f"\n✅ 找到 {len(response.data)} 個訓練類型:")
        for item in response.data:
            print(f"  - {item['name']}")
        
        # 檢查是否有「重訓」這個類型
        type_names = [item['name'] for item in response.data]
        
        if '重訓' in type_names:
            print("\n⚠️ 發現錯誤的「重訓」訓練類型！")
            
            # 詢問是否刪除
            response_input = input("\n是否要刪除「重訓」訓練類型？(y/n): ")
            
            if response_input.lower() == 'y':
                print("\n正在刪除「重訓」訓練類型...")
                supabase.table('exercise_types')\
                    .delete()\
                    .eq('name', '重訓')\
                    .execute()
                print("✅ 已刪除「重訓」訓練類型")
                
                # 再次檢查
                response = supabase.table('exercise_types')\
                    .select('name')\
                    .order('name')\
                    .execute()
                
                print(f"\n✅ 目前有 {len(response.data)} 個訓練類型:")
                for item in response.data:
                    print(f"  - {item['name']}")
            else:
                print("\n取消刪除操作")
        else:
            print("\n✅ 沒有找到錯誤的「重訓」訓練類型")
        
        # 檢查是否有「自訂」這個類型
        if '自訂' in type_names:
            print("\n⚠️ 發現「自訂」訓練類型")
            response_input = input("\n是否要刪除「自訂」訓練類型？(y/n): ")
            
            if response_input.lower() == 'y':
                print("\n正在刪除「自訂」訓練類型...")
                supabase.table('exercise_types')\
                    .delete()\
                    .eq('name', '自訂')\
                    .execute()
                print("✅ 已刪除「自訂」訓練類型")
        
        print("\n" + "=" * 80)
        print("檢查是否有使用錯誤訓練類型的動作")
        print("=" * 80)
        
        # 檢查 exercises 表格中是否有「重訓」或「自訂」的動作
        for wrong_type in ['重訓', '自訂']:
            response = supabase.table('exercises')\
                .select('id, name, training_type')\
                .eq('training_type', wrong_type)\
                .execute()
            
            if response.data:
                print(f"\n⚠️ 找到 {len(response.data)} 個使用「{wrong_type}」訓練類型的動作:")
                for ex in response.data[:5]:  # 只顯示前 5 個
                    print(f"  - {ex['name']} (ID: {ex['id']})")
                
                if len(response.data) > 5:
                    print(f"  ... 還有 {len(response.data) - 5} 個")
            else:
                print(f"\n✅ 沒有找到使用「{wrong_type}」訓練類型的動作")
        
    except Exception as e:
        print(f"\n❌ 操作失敗: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()

