#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
v4 欄位完整性檢查

檢查 exercises 表的 v4 欄位（body_part, training_type）是否有空值，
確保 DB trigger 向後兼容不會出問題。

同時交叉比對 v5 欄位（primary_muscle, ppl_tags）覆蓋率。

使用方式：
    python scripts/tools/check_v4_fields.py
"""

import sys
import os
from dotenv import load_dotenv
from supabase import create_client, Client

sys.stdout.reconfigure(encoding='utf-8')

# 載入環境變數
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
print("v4 / v5 欄位完整性檢查")
print("=" * 60)

# ============================================================
# 1. 系統動作總數
# ============================================================
total = supabase.table('exercises') \
    .select('id', count='exact') \
    .is_('user_id', 'null') \
    .execute()
total_count = total.count
print(f"\n📊 系統動作總數: {total_count}")

# ============================================================
# 2. v4 欄位檢查
# ============================================================
print("\n" + "=" * 60)
print("🔍 v4 欄位檢查（trigger 向後兼容）")
print("-" * 40)

v4_fields = ['body_part', 'training_type', 'specific_muscle',
             'equipment_category', 'equipment_subcategory']

for field in v4_fields:
    # 空值（NULL 或空字串）
    null_resp = supabase.table('exercises') \
        .select('id, name', count='exact') \
        .is_('user_id', 'null') \
        .is_(field, 'null') \
        .execute()
    null_count = null_resp.count

    empty_resp = supabase.table('exercises') \
        .select('id, name', count='exact') \
        .is_('user_id', 'null') \
        .eq(field, '') \
        .execute()
    empty_count = empty_resp.count

    missing = null_count + empty_count
    icon = "✅" if missing == 0 else "⚠️"
    print(f"  {icon} {field}: {total_count - missing}/{total_count} 有值"
          f" (NULL={null_count}, 空字串={empty_count})")

    # 列出缺失的動作（最多 10 筆）
    if missing > 0 and missing <= 20:
        samples = null_resp.data[:10] if null_count > 0 else empty_resp.data[:10]
        for s in samples:
            print(f"     → {s['id']}: {s['name']}")

# ============================================================
# 3. v5 欄位檢查
# ============================================================
print("\n" + "=" * 60)
print("🔍 v5 欄位檢查（客戶端計算依賴）")
print("-" * 40)

v5_fields = ['primary_muscle', 'ppl_tags', 'movement_patterns',
             'canonical_name', 'difficulty_level', 'mechanics_type']

for field in v5_fields:
    null_resp = supabase.table('exercises') \
        .select('id, name', count='exact') \
        .is_('user_id', 'null') \
        .is_(field, 'null') \
        .execute()
    null_count = null_resp.count

    filled = total_count - null_count
    icon = "✅" if null_count == 0 else "⚠️"
    print(f"  {icon} {field}: {filled}/{total_count} 有值 (NULL={null_count})")

    if 0 < null_count <= 10:
        for s in null_resp.data[:10]:
            print(f"     → {s['id']}: {s['name']}")

# ============================================================
# 4. v4 ↔ v5 交叉比對
# ============================================================
print("\n" + "=" * 60)
print("🔍 v4 ↔ v5 交叉比對")
print("-" * 40)

# 查所有動作的 v4 body_part + v5 primary_muscle
all_exercises = supabase.table('exercises') \
    .select('id, name, body_part, training_type, primary_muscle, ppl_tags') \
    .is_('user_id', 'null') \
    .execute()

v4_has_v5_missing = []
v5_has_v4_missing = []

for ex in all_exercises.data:
    has_v4 = bool(ex.get('body_part'))
    has_v5 = bool(ex.get('primary_muscle'))

    if has_v4 and not has_v5:
        v4_has_v5_missing.append(ex)
    elif has_v5 and not has_v4:
        v5_has_v4_missing.append(ex)

print(f"  有 v4 body_part 但缺 v5 primary_muscle: {len(v4_has_v5_missing)}")
for ex in v4_has_v5_missing[:5]:
    print(f"     → {ex['id']}: {ex['name']} (body_part={ex['body_part']})")

print(f"  有 v5 primary_muscle 但缺 v4 body_part: {len(v5_has_v4_missing)}")
for ex in v5_has_v4_missing[:5]:
    print(f"     → {ex['id']}: {ex['name']} (primary_muscle={ex['primary_muscle']})")

# ppl_tags 為空陣列的情況
empty_ppl = [ex for ex in all_exercises.data
             if not ex.get('ppl_tags') or ex['ppl_tags'] == []]
print(f"\n  ppl_tags 為空陣列或 NULL: {len(empty_ppl)}")
for ex in empty_ppl[:5]:
    print(f"     → {ex['id']}: {ex['name']}")

# ============================================================
# 5. 統計摘要
# ============================================================
print("\n" + "=" * 60)
print("📋 結論")
print("-" * 40)

all_v4_ok = all(
    bool(ex.get('body_part')) and bool(ex.get('training_type'))
    for ex in all_exercises.data
)
all_v5_ok = all(
    bool(ex.get('primary_muscle')) and bool(ex.get('ppl_tags'))
    and ex['ppl_tags'] != []
    for ex in all_exercises.data
)

if all_v4_ok:
    print("  ✅ v4 欄位完整 → DB trigger 向後兼容安全")
else:
    print("  ⚠️  v4 欄位有缺失 → 需要確認 trigger 是否受影響")

if all_v5_ok:
    print("  ✅ v5 欄位完整 → 客戶端統計計算可靠")
else:
    print("  ⚠️  v5 欄位有缺失 → 部分動作可能不納入統計")

print()
