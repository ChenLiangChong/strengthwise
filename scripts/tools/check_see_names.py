#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
檢查 SEE 標準名稱更新狀態

針對指定用戶，檢查：
1. personal_records 是否仍有舊名稱
2. workout_plans JSONB 中的 exerciseName/name 是否已更新
3. workout_templates JSONB 中的 name 是否已更新

使用方式：
    python scripts/tools/check_see_names.py <user_id>
"""

import sys
import os
import json
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

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ 請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY")
    sys.exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 取得用戶 ID
user_id = sys.argv[1] if len(sys.argv) > 1 else 'd1798674-0b96-4c47-a7c7-ee20a5372a03'
print(f"🔍 檢查用戶: {user_id}")
print("=" * 70)

# ============================================================
# 建立 exercise_id → canonical_name 對照表
# ============================================================
print("\n📋 載入 exercises 表的 canonical_name 對照...")
exercises_resp = supabase.table('exercises') \
    .select('id, name, canonical_name') \
    .is_('user_id', 'null') \
    .not_.is_('canonical_name', 'null') \
    .execute()

canonical_map = {}
for e in exercises_resp.data:
    canonical_map[e['id']] = {
        'name': e['name'],
        'canonical_name': e['canonical_name'],
    }
print(f"  有 canonical_name 的動作: {len(canonical_map)} 筆")

# ============================================================
# 1. 檢查 personal_records
# ============================================================
print("\n" + "=" * 70)
print("📊 1. personal_records 檢查")
print("-" * 40)

pr_resp = supabase.table('personal_records') \
    .select('exercise_id, exercise_name, max_weight, body_part') \
    .eq('user_id', user_id) \
    .execute()

pr_total = len(pr_resp.data)
pr_mismatch = []

for pr in pr_resp.data:
    eid = pr['exercise_id']
    stored_name = pr['exercise_name']
    if eid in canonical_map:
        canonical = canonical_map[eid]['canonical_name']
        old_name = canonical_map[eid]['name']
        if stored_name != canonical:
            pr_mismatch.append({
                'exercise_id': eid,
                'stored': stored_name,
                'canonical': canonical,
                'old_name': old_name,
                'max_weight': pr['max_weight'],
            })

print(f"  PR 總數: {pr_total}")
print(f"  名稱不一致: {len(pr_mismatch)}")

if pr_mismatch:
    print("\n  ⚠️  不一致的 PR:")
    for m in pr_mismatch:
        print(f"    [{m['exercise_id'][:8]}...] DB: \"{m['stored']}\" → 應為: \"{m['canonical']}\" (舊名: \"{m['old_name']}\", {m['max_weight']}kg)")

# ============================================================
# 2. 檢查 workout_plans JSONB
# ============================================================
print("\n" + "=" * 70)
print("📊 2. workout_plans JSONB 檢查")
print("-" * 40)

wp_resp = supabase.table('workout_plans') \
    .select('id, title, exercises') \
    .eq('trainee_id', user_id) \
    .not_.is_('exercises', 'null') \
    .order('created_at', desc=True) \
    .limit(50) \
    .execute()

wp_total = len(wp_resp.data)
wp_mismatch_plans = 0
wp_mismatch_exercises = []

for plan in wp_resp.data:
    exercises = plan['exercises'] or []
    for ex in exercises:
        eid = ex.get('exerciseId', '')
        stored_exercise_name = ex.get('exerciseName', '')
        stored_name = ex.get('name', '')

        if eid in canonical_map:
            canonical = canonical_map[eid]['canonical_name']
            old_name = canonical_map[eid]['name']

            if stored_exercise_name != canonical or stored_name != canonical:
                wp_mismatch_exercises.append({
                    'plan_id': plan['id'][:12],
                    'plan_title': plan['title'],
                    'exercise_id': eid[:8],
                    'exerciseName': stored_exercise_name,
                    'name': stored_name,
                    'canonical': canonical,
                })

wp_mismatch_plans = len(set(m['plan_id'] for m in wp_mismatch_exercises))

print(f"  計畫總數（最近 50 筆）: {wp_total}")
print(f"  名稱不一致的計畫: {wp_mismatch_plans}")
print(f"  名稱不一致的動作: {len(wp_mismatch_exercises)}")

if wp_mismatch_exercises:
    print("\n  ⚠️  不一致的動作（前 10 筆）:")
    for m in wp_mismatch_exercises[:10]:
        print(f"    [{m['plan_id']}] \"{m['plan_title']}\"")
        print(f"      exerciseName: \"{m['exerciseName']}\" | name: \"{m['name']}\" → 應為: \"{m['canonical']}\"")

# ============================================================
# 3. 檢查 workout_templates JSONB
# ============================================================
print("\n" + "=" * 70)
print("📊 3. workout_templates JSONB 檢查")
print("-" * 40)

tmpl_resp = supabase.table('workout_templates') \
    .select('id, title, exercises') \
    .eq('user_id', user_id) \
    .not_.is_('exercises', 'null') \
    .execute()

tmpl_total = len(tmpl_resp.data)
tmpl_mismatch = []

for tmpl in tmpl_resp.data:
    exercises = tmpl['exercises'] or []
    for ex in exercises:
        eid = ex.get('exerciseId', '')
        stored_name = ex.get('name', '')

        if eid in canonical_map:
            canonical = canonical_map[eid]['canonical_name']
            if stored_name != canonical:
                tmpl_mismatch.append({
                    'tmpl_id': tmpl['id'][:12],
                    'tmpl_title': tmpl['title'],
                    'exercise_id': eid[:8],
                    'name': stored_name,
                    'canonical': canonical,
                })

print(f"  模板總數: {tmpl_total}")
print(f"  名稱不一致的動作: {len(tmpl_mismatch)}")

if tmpl_mismatch:
    print("\n  ⚠️  不一致的動作:")
    for m in tmpl_mismatch:
        print(f"    [{m['tmpl_id']}] \"{m['tmpl_title']}\" → name: \"{m['name']}\" → 應為: \"{m['canonical']}\"")

# ============================================================
# 總結
# ============================================================
print("\n" + "=" * 70)
print("📋 總結")
print("=" * 70)
total_issues = len(pr_mismatch) + len(wp_mismatch_exercises) + len(tmpl_mismatch)
if total_issues == 0:
    print("✅ 所有名稱已正確更新為 SEE 標準名稱！")
else:
    print(f"⚠️  共發現 {total_issues} 處名稱不一致")
    print(f"  - personal_records: {len(pr_mismatch)}")
    print(f"  - workout_plans: {len(wp_mismatch_exercises)}")
    print(f"  - workout_templates: {len(tmpl_mismatch)}")
    print("\n💡 請在 Supabase SQL Editor 執行 migration 26 來修正")
