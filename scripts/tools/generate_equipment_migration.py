#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成 Migration 27: exercises.equipment 欄位更新 SQL

從 exercises_review_audited.csv 讀取每個動作的 equipment 值，
按 equipment 分組後生成批量 UPDATE SQL。

使用方式：
    python scripts/tools/generate_equipment_migration.py
"""

import csv
import os
import sys
from collections import defaultdict

sys.stdout.reconfigure(encoding='utf-8')

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
CSV_PATH = os.path.join(PROJECT_ROOT, 'scripts', 'review_data', 'exercises_review_audited.csv')
OUTPUT_PATH = os.path.join(PROJECT_ROOT, 'migrations', '27_v5_fix_equipment_column.sql')

# ref_equipment 有效 ID（migration 25 定義的 19 個）
VALID_EQUIPMENT_IDS = {
    'bodyweight', 'barbell', 'ez_bar', 'dumbbell', 'kettlebell',
    'cable', 'machine', 'smith_machine', 'suspension', 'resistance_band',
    'medicine_ball', 'battle_rope', 'sled', 'vipr', 'foam_roller',
    'cardio_machine', 'ab_wheel', 'landmine', 'log_bar',
}

def main():
    # 讀取 CSV（Big5 編碼）
    print(f'📖 讀取 CSV: {CSV_PATH}')
    equipment_groups = defaultdict(list)
    total = 0

    with open(CSV_PATH, 'r', encoding='big5') as f:
        reader = csv.DictReader(f)
        for row in reader:
            exercise_id = row.get('id', '').strip()
            equipment = row.get('器材', '').strip()
            if exercise_id and equipment:
                equipment_groups[equipment].append(exercise_id)
                total += 1

    print(f'  總計: {total} 筆動作')
    print(f'  Equipment 類型: {len(equipment_groups)} 種')
    print()

    # 驗證所有 equipment 值
    unknown = set(equipment_groups.keys()) - VALID_EQUIPMENT_IDS
    if unknown:
        print(f'⚠️  未在 ref_equipment 中的值: {unknown}')
        print('  這些動作的 equipment 將被設為最接近的值或需要手動處理')
    else:
        print('✅ 所有 equipment 值都有對應的 ref_equipment.id')
    print()

    # 生成 SQL
    print(f'📝 生成 SQL: {OUTPUT_PATH}')

    lines = []
    lines.append('-- ============================================================================')
    lines.append('-- StrengthWise Migration: 27_v5_fix_equipment_column.sql')
    lines.append('-- ============================================================================')
    lines.append('-- 版本: v5.0')
    lines.append(f'-- 日期: 2026-02-08')
    lines.append('-- 生成方式: scripts/tools/generate_equipment_migration.py')
    lines.append('-- ============================================================================')
    lines.append('--')
    lines.append('-- 修復 exercises.equipment 欄位')
    lines.append('-- 原始值為 Firestore 舊格式，更新為 ref_equipment.id 標準格式')
    lines.append('--')
    lines.append(f'-- 更新: {total} 筆 exercises')
    lines.append(f'-- Equipment 類型: {len(equipment_groups)} 種')
    lines.append('-- ============================================================================')
    lines.append('')
    lines.append('BEGIN;')
    lines.append('')

    # 按 equipment 排序生成 UPDATE
    for equipment in sorted(equipment_groups.keys()):
        ids = sorted(equipment_groups[equipment])
        count = len(ids)

        # 標記非標準值
        marker = ''
        if equipment not in VALID_EQUIPMENT_IDS:
            marker = ' -- ⚠️ 不在 ref_equipment 中'

        lines.append(f'-- {equipment}: {count} 筆{marker}')

        # 分批（每批 50 個 ID，避免 SQL 過長）
        batch_size = 50
        for i in range(0, len(ids), batch_size):
            batch = ids[i:i + batch_size]
            id_list = ', '.join(f"'{eid}'" for eid in batch)
            lines.append(f"UPDATE exercises SET equipment = '{equipment}' WHERE id IN ({id_list});")

        lines.append('')

    # 處理 specialty → 加入 ref_equipment 或映射
    if 'specialty' in equipment_groups:
        lines.append('-- specialty 器材：加入 ref_equipment 表')
        lines.append("INSERT INTO ref_equipment (id, name_zh, name_en, description_zh, description_en, sort_order)")
        lines.append("VALUES ('specialty', '特殊器材', 'Specialty Equipment', '特殊訓練器材', 'Specialized training equipment', 19)")
        lines.append("ON CONFLICT (id) DO UPDATE SET")
        lines.append("    name_zh = EXCLUDED.name_zh,")
        lines.append("    name_en = EXCLUDED.name_en,")
        lines.append("    description_zh = EXCLUDED.description_zh,")
        lines.append("    description_en = EXCLUDED.description_en,")
        lines.append("    sort_order = EXCLUDED.sort_order;")
        lines.append('')

    # 驗證區塊
    lines.append('-- ============================================================================')
    lines.append('-- 驗證')
    lines.append('-- ============================================================================')
    lines.append('')
    lines.append('DO $$')
    lines.append('DECLARE')
    lines.append('    matched_count INTEGER;')
    lines.append('    total_system INTEGER;')
    lines.append('    unmatched_count INTEGER;')
    lines.append('BEGIN')
    lines.append("    SELECT COUNT(*) INTO total_system FROM exercises WHERE user_id IS NULL;")
    lines.append("    SELECT COUNT(*) INTO matched_count FROM exercises WHERE user_id IS NULL AND equipment IN (SELECT id FROM ref_equipment);")
    lines.append("    unmatched_count := total_system - matched_count;")
    lines.append('')
    lines.append("    RAISE NOTICE '======================================';")
    lines.append("    RAISE NOTICE 'Equipment 更新驗證';")
    lines.append("    RAISE NOTICE '--------------------------------------';")
    lines.append("    RAISE NOTICE '  系統動作總數: %', total_system;")
    lines.append("    RAISE NOTICE '  Equipment 匹配: %', matched_count;")
    lines.append("    RAISE NOTICE '  未匹配: %', unmatched_count;")
    lines.append("    RAISE NOTICE '======================================';")
    lines.append('')
    lines.append('    IF unmatched_count > 0 THEN')
    lines.append("        RAISE WARNING '⚠️ 有 % 筆動作的 equipment 不在 ref_equipment 中', unmatched_count;")
    lines.append('    ELSE')
    lines.append("        RAISE NOTICE '✅ 所有系統動作的 equipment 都匹配 ref_equipment';")
    lines.append('    END IF;')
    lines.append('END $$;')
    lines.append('')
    lines.append('COMMIT;')
    lines.append('')

    # 寫入檔案
    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))

    print(f'✅ 已生成 {OUTPUT_PATH}')
    print()

    # 輸出統計
    print('📊 統計:')
    for equipment in sorted(equipment_groups.keys()):
        count = len(equipment_groups[equipment])
        marker = ' ⚠️' if equipment not in VALID_EQUIPMENT_IDS else ''
        print(f'  {equipment}: {count} 筆{marker}')


if __name__ == '__main__':
    main()
