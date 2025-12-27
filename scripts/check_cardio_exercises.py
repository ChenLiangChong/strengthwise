#!/usr/bin/env python3
"""檢查心肺適能訓練動作的 body_part 欄位"""
import os
from dotenv import load_dotenv
from supabase import create_client

# 載入環境變數
load_dotenv()
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY')

# 連接 Supabase
supabase = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

# 查詢心肺適能訓練動作
print("📊 檢查心肺適能訓練動作的 body_part 欄位...")
response = supabase.table('exercises').select(
    'id, name, body_part, body_parts, training_type'
).eq('training_type', '心肺適能訓練').execute()

print(f"\n找到 {len(response.data)} 個心肺適能訓練動作：\n")

empty_count = 0
for exercise in response.data[:10]:  # 只顯示前 10 個
    body_part = exercise.get('body_part', '')
    body_parts = exercise.get('body_parts', [])
    
    if not body_part:
        empty_count += 1
    
    print(f"  {exercise['name']}")
    print(f"    - body_part: '{body_part}' {'❌ 空的' if not body_part else '✅'}")
    print(f"    - body_parts: {body_parts}")
    print()

print(f"統計：{empty_count}/{len(response.data)} 個動作的 body_part 欄位為空\n")

# 檢查活動度與伸展
print("\n📊 檢查活動度與伸展動作的 body_part 欄位...")
response2 = supabase.table('exercises').select(
    'id, name, body_part, body_parts, training_type'
).eq('training_type', '活動度與伸展').execute()

print(f"找到 {len(response2.data)} 個活動度與伸展動作")

empty_count2 = 0
for exercise in response2.data[:5]:
    body_part = exercise.get('body_part', '')
    if not body_part:
        empty_count2 += 1
    print(f"  {exercise['name']}: body_part='{body_part}' {'❌' if not body_part else '✅'}")

print(f"\n統計：{empty_count2}/{len(response2.data)} 個動作的 body_part 欄位為空")

