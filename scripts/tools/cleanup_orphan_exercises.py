#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
清除不在審核 CSV 中的系統動作

找出 exercises 表中 user_id IS NULL 但不在
exercises_review_audited.csv 的記錄，列出並刪除。

使用方式：
    python3 scripts/tools/cleanup_orphan_exercises.py
    python3 scripts/tools/cleanup_orphan_exercises.py --delete
"""

import sys
import os
import csv
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

# 1. 讀取 CSV 中的 ID
CSV_FILE = os.path.join(PROJECT_ROOT, 'scripts', 'review_data', 'exercises_review_audited.csv')
csv_ids = set()

for encoding in ['big5', 'utf-8']:
    try:
        with open(CSV_FILE, 'r', encoding=encoding) as f:
            reader = csv.DictReader(f)
            for row in reader:
                csv_ids.add(row['id'])
        break
    except (UnicodeDecodeError, KeyError):
        continue

print(f"📄 CSV 動作數: {len(csv_ids)}")

# 2. 查詢資料庫中所有系統動作
# Supabase 預設 limit 1000，需要分批查詢
all_db_exercises = []
page_size = 200
offset = 0

while True:
    resp = supabase.table('exercises') \
        .select('id, name, canonical_name') \
        .is_('user_id', 'null') \
        .order('id') \
        .range(offset, offset + page_size - 1) \
        .execute()
    all_db_exercises.extend(resp.data)
    if len(resp.data) < page_size:
        break
    offset += page_size

db_ids = {ex['id'] for ex in all_db_exercises}
print(f"🗄️  資料庫系統動作數: {len(db_ids)}")

# 3. 找出差集
orphan_ids = db_ids - csv_ids
missing_ids = csv_ids - db_ids

print(f"\n🔍 分析結果:")
print(f"  在 DB 但不在 CSV（待刪除）: {len(orphan_ids)} 筆")
print(f"  在 CSV 但不在 DB（缺失）:   {len(missing_ids)} 筆")

if orphan_ids:
    # 查詢詳細資料
    orphan_list = list(orphan_ids)
    orphan_exercises = []
    # 分批查詢（每批 50 個）
    for i in range(0, len(orphan_list), 50):
        batch = orphan_list[i:i+50]
        resp = supabase.table('exercises') \
            .select('id, name, canonical_name, body_parts, equipment') \
            .in_('id', batch) \
            .execute()
        orphan_exercises.extend(resp.data)

    print(f"\n📋 待刪除的動作:")
    for ex in orphan_exercises:
        name = ex.get('canonical_name') or ex.get('name') or '(無名稱)'
        print(f"  - {ex['id']} : {name}")

if missing_ids:
    print(f"\n⚠️  CSV 中存在但 DB 中缺失的 ID:")
    for mid in sorted(missing_ids):
        print(f"  - {mid}")

# 4. 刪除（需要 --delete 參數）
if '--delete' in sys.argv:
    if not orphan_ids:
        print("\n✅ 沒有需要刪除的記錄")
        sys.exit(0)

    print(f"\n🗑️  開始刪除 {len(orphan_ids)} 筆孤立動作...")

    # 先檢查這些動作是否有關聯的個人紀錄
    orphan_list = list(orphan_ids)
    has_records = []
    for i in range(0, len(orphan_list), 50):
        batch = orphan_list[i:i+50]
        resp = supabase.table('personal_records') \
            .select('exercise_id') \
            .in_('exercise_id', batch) \
            .execute()
        if resp.data:
            has_records.extend([r['exercise_id'] for r in resp.data])

    if has_records:
        unique_has_records = set(has_records)
        print(f"  ⚠️  {len(unique_has_records)} 筆動作有關聯訓練記錄，跳過:")
        for rid in unique_has_records:
            print(f"    - {rid}")
        # 只刪除沒有訓練記錄的
        safe_to_delete = orphan_ids - unique_has_records
    else:
        safe_to_delete = orphan_ids

    if safe_to_delete:
        delete_list = list(safe_to_delete)
        for i in range(0, len(delete_list), 50):
            batch = delete_list[i:i+50]
            supabase.table('exercises') \
                .delete() \
                .in_('id', batch) \
                .execute()
        print(f"  ✅ 已刪除 {len(safe_to_delete)} 筆")
    else:
        print("  ⚠️  所有孤立動作都有訓練記錄，無法刪除")
else:
    if orphan_ids:
        print(f"\n💡 確認後執行以下命令刪除:")
        print(f"   python3 scripts/tools/cleanup_orphan_exercises.py --delete")
