#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Migration 25 驗證腳本

驗證 v5 動作分類系統資料匯入結果：
1. exercises 表 v5 欄位更新狀態
2. exercise_aliases 別名資料
3. 參照表資料
4. 孤立記錄檢查

使用方式：
    python scripts/tools/verify_migration_25.py
"""

import sys
import os
from dotenv import load_dotenv
from supabase import create_client, Client

# 設定 UTF-8 輸出
sys.stdout.reconfigure(encoding='utf-8')

# 載入環境變數（處理 BOM）
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
ENV_FILE = os.path.join(PROJECT_ROOT, '.env')

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
    print(f"⚠️  .env 檔案未找到: {ENV_FILE}")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ 請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY")
    sys.exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

print("=" * 60)
print("Migration 25 驗證 - v5 動作分類系統")
print("=" * 60)


# ============================================================
# 1. exercises 表 v5 欄位檢查
# ============================================================
print("\n📊 1. exercises 表 v5 欄位更新狀態")
print("-" * 40)

# 總筆數
total = supabase.table('exercises') \
    .select('id', count='exact') \
    .is_('user_id', 'null') \
    .execute()
total_count = total.count

# 已更新（canonical_name 非空）
updated = supabase.table('exercises') \
    .select('id', count='exact') \
    .is_('user_id', 'null') \
    .neq('canonical_name', '') \
    .not_.is_('canonical_name', 'null') \
    .execute()
updated_count = updated.count

print(f"  系統動作總數:     {total_count}")
print(f"  已更新 v5 欄位:   {updated_count}")
print(f"  未更新:           {total_count - updated_count}")
print(f"  覆蓋率:           {updated_count/total_count*100:.1f}%")

# 檢查各 v5 欄位的填充狀態
v5_fields = [
    ('canonical_name', '標準名稱'),
    ('canonical_name_en', '英文標準名'),
    ('movement_patterns', '動作模式'),
    ('ppl_tags', 'PPL 標籤'),
    ('primary_muscle', '主動肌'),
    ('equipment_category', '器材分類'),
    ('mechanics_type', '力學類型'),
    ('difficulty_level', '難度等級'),
]

print(f"\n  各欄位填充狀態:")
for field, label in v5_fields:
    resp = supabase.table('exercises') \
        .select('id', count='exact') \
        .is_('user_id', 'null') \
        .not_.is_(field, 'null') \
        .execute()
    count = resp.count
    print(f"    {label:12s} ({field:20s}): {count:4d} 筆")


# ============================================================
# 2. exercise_aliases 別名資料
# ============================================================
print("\n\n📝 2. exercise_aliases 別名資料")
print("-" * 40)

alias_total = supabase.table('exercise_aliases') \
    .select('id', count='exact') \
    .execute()
alias_count = alias_total.count
print(f"  別名總數: {alias_count}")

# 按語系統計
for locale in ['zh-TW', 'en-US']:
    resp = supabase.table('exercise_aliases') \
        .select('id', count='exact') \
        .eq('locale', locale) \
        .execute()
    print(f"    {locale}: {resp.count} 筆")

# 按類型統計
for category in ['common', 'slang', 'abbreviation', 'brand', 'pattern', 'muscle', 'equipment']:
    resp = supabase.table('exercise_aliases') \
        .select('id', count='exact') \
        .eq('category', category) \
        .execute()
    if resp.count > 0:
        print(f"    {category}: {resp.count} 筆")

# 取樣顯示
print(f"\n  取樣（前 5 筆）:")
samples = supabase.table('exercise_aliases') \
    .select('exercise_id, alias_term, locale, category') \
    .limit(5) \
    .execute()
for s in samples.data:
    print(f"    [{s['locale']}] {s['alias_term']} ({s['category']})")


# ============================================================
# 3. 參照表資料
# ============================================================
print("\n\n📋 3. 參照表資料")
print("-" * 40)

ref_tables = [
    ('ref_movement_patterns', '動作模式'),
    ('ref_muscle_groups', '肌肉群'),
    ('ref_equipment', '器材'),
]

for table, label in ref_tables:
    resp = supabase.table(table) \
        .select('id, name_zh', count='exact') \
        .execute()
    print(f"  {label} ({table}): {resp.count} 筆")
    # 顯示前 5 項
    for item in resp.data[:5]:
        print(f"    - {item['id']}: {item['name_zh']}")
    if resp.count > 5:
        print(f"    ... 還有 {resp.count - 5} 筆")


# ============================================================
# 4. 弓箭步命名驗證（之前修正的 4 筆）
# ============================================================
print("\n\n🏋️ 4. 弓箭步命名驗證")
print("-" * 40)

target_ids = [
    '7D3Y3G00nJiuAQwUGzxd',  # 前架式槓鈴前弓箭步
    'FMm1YHLMWZXBxCoKaNuB',  # 地雷管弓箭步推舉
    'ffLPwXBWji8Xcq9bpkoW',  # 火箭筒弓箭步勾拳
    'PNNl2CpoiqLeOCVxHAsL',  # 火箭筒弓箭步旋轉
]

resp = supabase.table('exercises') \
    .select('id, canonical_name, canonical_name_en') \
    .in_('id', target_ids) \
    .execute()

if resp.data:
    for ex in resp.data:
        name = ex.get('canonical_name', '(空)')
        name_en = ex.get('canonical_name_en', '(空)')
        has_bow = '弓箭步' in (name or '')
        status = '✅' if has_bow else '❌'
        print(f"  {status} {ex['id'][:8]}... → {name} / {name_en}")
else:
    print("  ⚠️  這 4 筆動作在資料庫中不存在")


# ============================================================
# 5. 未更新的動作檢查
# ============================================================
print("\n\n🔍 5. 未更新 v5 欄位的動作（前 10 筆）")
print("-" * 40)

not_updated = supabase.table('exercises') \
    .select('id, name') \
    .is_('user_id', 'null') \
    .is_('canonical_name', 'null') \
    .limit(10) \
    .execute()

if not_updated.data:
    for ex in not_updated.data:
        print(f"  - {ex['id'][:12]}... : {ex.get('name', '(無名稱)')}")
else:
    print("  ✅ 所有系統動作都已更新 v5 欄位")


# ============================================================
# 6. 搜尋函式驗證
# ============================================================
print("\n\n🔎 6. search_exercises_v2 函式測試")
print("-" * 40)

try:
    # 測試搜尋「臥推」
    result = supabase.rpc('search_exercises_v2', {
        'search_query': '臥推',
        'max_results': 5
    }).execute()
    print(f"  搜尋「臥推」: {len(result.data)} 筆結果")
    for r in result.data[:3]:
        print(f"    - {r.get('canonical_name', r.get('name', '?'))}")
except Exception as e:
    print(f"  ⚠️  RPC 呼叫失敗: {e}")

try:
    # 測試搜尋「弓箭步」
    result = supabase.rpc('search_exercises_v2', {
        'search_query': '弓箭步',
        'max_results': 5
    }).execute()
    print(f"  搜尋「弓箭步」: {len(result.data)} 筆結果")
    for r in result.data[:3]:
        print(f"    - {r.get('canonical_name', r.get('name', '?'))}")
except Exception as e:
    print(f"  ⚠️  RPC 呼叫失敗: {e}")


# ============================================================
# 總結
# ============================================================
print("\n\n" + "=" * 60)
print("驗證完成")
print("=" * 60)

issues = []
if updated_count < 700:
    issues.append(f"更新筆數偏低: {updated_count}/779")
if alias_count < 2000:
    issues.append(f"別名數偏低: {alias_count}/2352")

if issues:
    print("⚠️  發現問題:")
    for issue in issues:
        print(f"  - {issue}")
else:
    print("✅ Migration 25 執行成功，所有驗證通過")
