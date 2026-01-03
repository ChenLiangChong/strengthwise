#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""分析 migrations 的類型和依賴"""
import sys
import os

sys.stdout.reconfigure(encoding='utf-8')

migrations = [
    ("001", "create_core_tables", "CREATE", "建立 exercises, body_parts, exercise_types"),
    ("002", "create_user_tables", "CREATE", "建立 users, workout_plans, workout_templates, custom_exercises"),
    ("004", "create_body_data_table", "CREATE", "建立 body_data"),
    ("008", "update_exercise_naming", "UPDATE", "更新 794 個 exercises（雙語欄位 + 數據）"),
    ("009", "fix_bilingual_metadata_tables", "FIX", "修正雙語元數據表"),
    ("011", "force_sync_body_parts", "FIX", "強制同步 body_parts"),
    ("012", "create_custom_exercises_table", "ALTER", "custom_exercises 增加欄位"),
    ("015", "performance_optimization_phase1_indexes", "OPTIMIZE", "索引優化"),
    ("016", "add_training_type_to_custom_exercises", "ALTER", "custom_exercises 增加 training_type"),
    ("017", "fix_cardio_stretch_body_part", "FIX", "修正心肺/伸展的 body_part"),
    ("018", "performance_optimization_phase2_fulltext", "OPTIMIZE", "pgroonga 全文搜尋"),
    ("019", "add_body_part_and_view", "CREATE", "建立 body_part view"),
    ("020", "fix_pgroonga_function_names", "FIX", "修正 pgroonga 函數名"),
    ("021", "phase1_coaching_relationships", "CREATE", "v2.0 Phase 1"),
    ("022", "phase2_appointments", "CREATE", "v2.0 Phase 2"),
    ("023", "phase3_visual_notes_and_time_preferences", "CREATE", "v2.0 Phase 3"),
    ("024", "storage_policies_session_photos", "POLICY", "Storage RLS"),
    ("025", "phase4a_drawing_canvas", "COMMENT", "Drawing 結構說明"),
    ("026", "performance_optimization_phase3_stats_summary", "CREATE", "統計彙總表"),
]

print("=" * 80)
print("Migrations 分析報告")
print("=" * 80)
print()

# 按類型分組
types = {}
for num, name, mtype, desc in migrations:
    if mtype not in types:
        types[mtype] = []
    types[mtype].append((num, name, desc))

for mtype in ["CREATE", "ALTER", "UPDATE", "FIX", "OPTIMIZE", "POLICY", "COMMENT"]:
    if mtype in types:
        print(f"【{mtype}】({len(types[mtype])} 個)")
        for num, name, desc in types[mtype]:
            print(f"  {num}: {desc}")
        print()

print("=" * 80)
print("最小化方案分析")
print("=" * 80)
print()

print("方案 1：最激進（1-2 個檔案）")
print("  - 001+002+004+008+009+011+012+016+017 合併 → 001_create_all_tables.sql")
print("  - 015+018+019+020+026 合併 → 002_optimization.sql")
print("  - 021-025 保留")
print("  → 總共 7 個檔案")
print()

print("方案 2：按階段合併（3-5 個檔案）")
print("  - 001_v1_core_tables.sql (合併 001+002+004)")
print("  - 002_v1_initial_data.sql (合併 008+009+011)")
print("  - 003_v1_enhancements.sql (合併 012+015+016+017+018+019+020)")
print("  - 004_v1_optimization.sql (026)")
print("  - 005_v2_phase1_coaching.sql (021)")
print("  - 006_v2_phase2_appointments.sql (022)")
print("  - 007_v2_phase3_notes.sql (023+024+025)")
print("  → 總共 7 個檔案")
print()

print("方案 3：保守（保留獨立功能）")
print("  - 合併基礎 CREATE (001+002+004) → 001_core_tables.sql")
print("  - 合併初始數據 (008+009+011) → 002_initial_data.sql")
print("  - 合併優化 (012+015+016+017+018+019+020+026) → 003_optimizations.sql")
print("  - 保留 v2.0 (021, 022, 023, 024, 025)")
print("  → 總共 8 個檔案")
print()

print("=" * 80)
print("建議：方案 2（按階段合併）")
print("=" * 80)
print("原因：")
print("1. 清晰的版本劃分（v1.0 vs v2.0）")
print("2. 易於維護和理解")
print("3. 如果只需要 v1.0，只需執行前 4 個檔案")
print("4. v2.0 功能獨立，可選擇性部署")

