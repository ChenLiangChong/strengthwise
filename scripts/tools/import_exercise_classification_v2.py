#!/usr/bin/env python3
"""
動作分類系統 v2 匯入腳本

讀取審核完成的 exercises_review_audited.csv，生成：
1. exercises 表 UPDATE 語句
2. exercise_aliases INSERT 語句
3. 參照表初始資料

使用方式：
    python scripts/tools/import_exercise_classification_v2.py

輸出：
    migrations/25_v5_exercise_data_import.sql
"""

import csv
import json
import os
from pathlib import Path
from typing import Optional

# 專案根目錄
PROJECT_ROOT = Path(__file__).parent.parent.parent
REVIEW_DATA_DIR = PROJECT_ROOT / 'scripts' / 'review_data'
REFERENCE_DATA_DIR = PROJECT_ROOT / 'scripts' / 'reference_data'
OUTPUT_FILE = PROJECT_ROOT / 'migrations' / '25_v5_exercise_data_import.sql'


def load_csv(filepath: Path, encoding: str = 'big5') -> list[dict]:
    """載入 CSV 檔案"""
    rows = []
    try:
        with open(filepath, 'r', encoding=encoding) as f:
            reader = csv.DictReader(f)
            for row in reader:
                rows.append(row)
    except UnicodeDecodeError:
        # 嘗試 UTF-8
        with open(filepath, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                rows.append(row)
    return rows


def load_json(filepath: Path) -> list[dict]:
    """載入 JSON 檔案"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)


def escape_sql(value: Optional[str]) -> str:
    """SQL 字串轉義"""
    if value is None or value == '':
        return 'NULL'
    # 轉義單引號
    escaped = value.replace("'", "''")
    return f"'{escaped}'"


def parse_array(value: str) -> list[str]:
    """解析逗號分隔的陣列值"""
    if not value or value.strip() == '':
        return []
    # 處理可能的多種分隔符
    items = []
    for item in value.split(','):
        item = item.strip()
        if item:
            items.append(item)
    return items


def to_pg_array(items: list[str]) -> str:
    """轉換為 PostgreSQL 陣列格式"""
    if not items:
        return "'{}'::TEXT[]"
    escaped = [item.replace("'", "''") for item in items]
    return "ARRAY[" + ", ".join(f"'{item}'" for item in escaped) + "]::TEXT[]"


def generate_update_statement(row: dict) -> str:
    """生成單筆 exercises UPDATE 語句"""
    exercise_id = row.get('id', '')
    if not exercise_id:
        return ''

    # 解析欄位
    canonical_name = row.get('建議中文名', '').strip()
    canonical_name_en = row.get('建議英文名', '').strip()
    movement_patterns = parse_array(row.get('動作模式', ''))
    ppl_tags = parse_array(row.get('PPL標籤', ''))
    primary_muscle = row.get('主動肌', '').strip()
    synergist_muscles = parse_array(row.get('協同肌', ''))
    equipment = row.get('器材', '').strip()
    mechanics_type = row.get('複合/孤立', 'compound').strip()
    is_unilateral = row.get('單邊', 'FALSE').strip().upper() == 'TRUE'
    difficulty_level = row.get('難度', 'beginner').strip()
    is_explosive = row.get('is_explosive', 'FALSE').strip().upper() == 'TRUE'

    # 構建 UPDATE 語句
    sql = f"""UPDATE exercises SET
    canonical_name = {escape_sql(canonical_name)},
    canonical_name_en = {escape_sql(canonical_name_en)},
    movement_patterns = {to_pg_array(movement_patterns)},
    ppl_tags = {to_pg_array(ppl_tags)},
    primary_muscle = {escape_sql(primary_muscle) if primary_muscle else 'NULL'},
    synergist_muscles = {to_pg_array(synergist_muscles)},
    mechanics_type = {escape_sql(mechanics_type)},
    is_unilateral = {str(is_unilateral).upper()},
    difficulty_level = {escape_sql(difficulty_level)},
    is_explosive = {str(is_explosive).upper()}
WHERE id = '{exercise_id}';"""

    return sql


def generate_alias_inserts(row: dict) -> list[str]:
    """生成別名 INSERT 語句"""
    exercise_id = row.get('id', '')
    aliases_str = row.get('別名（逗號分隔）', '') or row.get('別名', '')

    if not exercise_id or not aliases_str:
        return []

    aliases = parse_array(aliases_str)
    statements = []

    for alias in aliases:
        alias = alias.strip()
        if not alias:
            continue

        # 判斷語言
        is_english = all(ord(c) < 128 or c in ',' for c in alias)
        locale = 'en-US' if is_english else 'zh-TW'

        # 判斷類別
        category = 'common'
        if alias.isupper() and len(alias) <= 5:
            category = 'abbreviation'
        elif any(brand in alias.lower() for brand in ['trx', 'hammer', 'cybex']):
            category = 'brand'

        sql = f"""INSERT INTO exercise_aliases (exercise_id, alias_term, locale, category)
VALUES ('{exercise_id}', {escape_sql(alias)}, '{locale}', '{category}')
ON CONFLICT DO NOTHING;"""
        statements.append(sql)

    return statements


def generate_ref_movement_patterns(patterns: list[dict]) -> str:
    """生成動作模式參照表 INSERT 語句"""
    statements = []
    for i, p in enumerate(patterns):
        parent = f"'{p['parent_id']}'" if p.get('parent_id') else 'NULL'
        desc_zh = escape_sql(p.get('description_zh', ''))
        desc_en = escape_sql(p.get('description_en', ''))

        sql = f"""INSERT INTO ref_movement_patterns (id, name_zh, name_en, parent_id, description_zh, description_en, sort_order)
VALUES ('{p['id']}', {escape_sql(p['name_zh'])}, {escape_sql(p['name_en'])}, {parent}, {desc_zh}, {desc_en}, {i})
ON CONFLICT (id) DO UPDATE SET
    name_zh = EXCLUDED.name_zh,
    name_en = EXCLUDED.name_en,
    parent_id = EXCLUDED.parent_id,
    description_zh = EXCLUDED.description_zh,
    description_en = EXCLUDED.description_en,
    sort_order = EXCLUDED.sort_order;"""
        statements.append(sql)

    return '\n'.join(statements)


def generate_ref_muscle_groups(groups: list[dict]) -> str:
    """生成肌肉群參照表 INSERT 語句"""
    statements = []
    order = 0

    for group in groups:
        group_id = group['id']
        region = group['region']

        for muscle in group.get('muscles', []):
            sql = f"""INSERT INTO ref_muscle_groups (id, name_zh, name_en, region, parent_group, sort_order)
VALUES ('{muscle['id']}', {escape_sql(muscle['name_zh'])}, {escape_sql(muscle['name_en'])}, '{region}', '{group_id}', {order})
ON CONFLICT (id) DO UPDATE SET
    name_zh = EXCLUDED.name_zh,
    name_en = EXCLUDED.name_en,
    region = EXCLUDED.region,
    parent_group = EXCLUDED.parent_group,
    sort_order = EXCLUDED.sort_order;"""
            statements.append(sql)
            order += 1

    return '\n'.join(statements)


def generate_ref_equipment(equipment: list[dict]) -> str:
    """生成器材參照表 INSERT 語句"""
    statements = []
    for i, e in enumerate(equipment):
        desc_zh = escape_sql(e.get('description_zh', ''))
        desc_en = escape_sql(e.get('description_en', ''))

        sql = f"""INSERT INTO ref_equipment (id, name_zh, name_en, description_zh, description_en, sort_order)
VALUES ('{e['id']}', {escape_sql(e['name_zh'])}, {escape_sql(e['name_en'])}, {desc_zh}, {desc_en}, {i})
ON CONFLICT (id) DO UPDATE SET
    name_zh = EXCLUDED.name_zh,
    name_en = EXCLUDED.name_en,
    description_zh = EXCLUDED.description_zh,
    description_en = EXCLUDED.description_en,
    sort_order = EXCLUDED.sort_order;"""
        statements.append(sql)

    return '\n'.join(statements)


def main():
    print("=" * 60)
    print("動作分類系統 v2 匯入腳本")
    print("=" * 60)

    # 載入審核資料
    csv_file = REVIEW_DATA_DIR / 'exercises_review_audited.csv'
    print(f"\n📂 載入 CSV: {csv_file}")
    rows = load_csv(csv_file)
    print(f"   → 載入 {len(rows)} 筆資料")

    # 載入參照表
    print("\n📂 載入參照表...")
    patterns = load_json(REFERENCE_DATA_DIR / 'ref_movement_patterns.json')
    print(f"   → 動作模式: {len(patterns)} 項")

    muscle_groups = load_json(REFERENCE_DATA_DIR / 'ref_muscle_groups.json')
    total_muscles = sum(len(g.get('muscles', [])) for g in muscle_groups)
    print(f"   → 肌肉群: {len(muscle_groups)} 區域, {total_muscles} 個肌肉")

    equipment = load_json(REFERENCE_DATA_DIR / 'ref_equipment.json')
    print(f"   → 器材: {len(equipment)} 項")

    # 生成 SQL
    print("\n🔧 生成 SQL...")

    # 統計
    update_count = 0
    alias_count = 0

    update_statements = []
    alias_statements = []

    for row in rows:
        # UPDATE 語句
        update_sql = generate_update_statement(row)
        if update_sql:
            update_statements.append(update_sql)
            update_count += 1

        # 別名語句
        alias_sqls = generate_alias_inserts(row)
        alias_statements.extend(alias_sqls)
        alias_count += len(alias_sqls)

    print(f"   → exercises UPDATE: {update_count} 筆")
    print(f"   → exercise_aliases INSERT: {alias_count} 筆")

    # 組合最終 SQL
    sql_parts = []

    # 檔頭
    sql_parts.append("""-- ============================================================================
-- StrengthWise Migration: 25_v5_exercise_data_import.sql
-- ============================================================================
-- 版本: v5.0
-- 日期: 2026-02-07
-- 生成方式: scripts/tools/import_exercise_classification_v2.py
-- ============================================================================
--
-- 動作分類系統 v2 資料匯入
-- - 更新 779 筆 exercises 資料
-- - 匯入別名資料
-- - 匯入參照表資料
--
-- 參考文檔：docs/planning/EXERCISE_CLASSIFICATION_ANALYSIS.md
-- ============================================================================

BEGIN;
""")

    # Part 1: 參照表資料
    sql_parts.append("""
-- ============================================================================
-- PART 1: 參照表資料
-- ============================================================================

-- 1.1 動作模式參照表
""")
    sql_parts.append(generate_ref_movement_patterns(patterns))

    sql_parts.append("""

-- 1.2 肌肉群參照表
""")
    sql_parts.append(generate_ref_muscle_groups(muscle_groups))

    sql_parts.append("""

-- 1.3 器材參照表
""")
    sql_parts.append(generate_ref_equipment(equipment))

    # Part 2: exercises 更新
    sql_parts.append(f"""

-- ============================================================================
-- PART 2: exercises 表更新（{update_count} 筆）
-- ============================================================================

""")
    sql_parts.append('\n\n'.join(update_statements))

    # Part 3: 別名資料
    sql_parts.append(f"""

-- ============================================================================
-- PART 3: exercise_aliases 匯入（{alias_count} 筆）
-- ============================================================================

""")
    sql_parts.append('\n'.join(alias_statements))

    # 驗證
    sql_parts.append("""

-- ============================================================================
-- PART 4: 驗證
-- ============================================================================

DO $$
DECLARE
    v_updated_count INT;
    v_alias_count INT;
BEGIN
    -- 檢查已更新的記錄數
    SELECT COUNT(*) INTO v_updated_count
    FROM exercises
    WHERE canonical_name IS NOT NULL AND canonical_name != '';

    SELECT COUNT(*) INTO v_alias_count
    FROM exercise_aliases;

    RAISE NOTICE '✅ Migration 25_v5_exercise_data_import.sql 執行完成';
    RAISE NOTICE '   → exercises 已更新: % 筆', v_updated_count;
    RAISE NOTICE '   → exercise_aliases 已匯入: % 筆', v_alias_count;

    -- 驗證關鍵資料
    IF v_updated_count < 700 THEN
        RAISE WARNING '⚠️  更新筆數少於預期（應為 ~779 筆）';
    END IF;
END $$;

COMMIT;
""")

    # 寫入檔案
    print(f"\n📝 寫入: {OUTPUT_FILE}")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        f.write('\n'.join(sql_parts))

    # 統計檔案大小
    file_size = os.path.getsize(OUTPUT_FILE)
    print(f"   → 檔案大小: {file_size / 1024:.1f} KB")

    print("\n" + "=" * 60)
    print("✅ 完成！")
    print(f"   → 輸出檔案: {OUTPUT_FILE}")
    print("=" * 60)


if __name__ == '__main__':
    main()
