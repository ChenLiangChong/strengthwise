#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""創建剩餘的合併 Migrations"""
import sys
import os
import shutil

sys.stdout.reconfigure(encoding='utf-8')

BASE_DIR = "migrations/archived_original"
OUTPUT_DIR = "migrations"

def read_sql(filename):
    filepath = os.path.join(BASE_DIR, filename)
    with open(filepath, 'r', encoding='utf-8') as f:
        return f.read()

def write_sql(filename, content):
    filepath = os.path.join(OUTPUT_DIR, filename)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ 創建: {filepath}")

def copy_sql(old_filename, new_filename):
    src = os.path.join(BASE_DIR, old_filename)
    dst = os.path.join(OUTPUT_DIR, new_filename)
    shutil.copy2(src, dst)
    print(f"✅ 複製: {dst}")

# ============================================================================
# 2. 002_v1_initial_data.sql (008+009+011)
# ============================================================================
print("\n創建 002_v1_initial_data.sql...")

content_002 = f"""-- =====================================================
-- StrengthWise v1.0 - 系統初始數據
-- =====================================================
-- 合併自: 008, 009, 011
-- 最後更新: 2025-01-01
-- 
-- 包含:
-- 1. 794 個系統動作的雙語資料 (008)
-- 2. 元數據表修正 (009)
-- 3. Body Parts 同步 (011)
-- =====================================================

-- PART 1: 更新 794 個系統動作 (來自 008)
{read_sql('008_update_exercise_naming.sql').strip()}

-- =====================================================
-- PART 2: 修正雙語元數據表 (來自 009)
-- =====================================================

{read_sql('009_fix_bilingual_metadata_tables.sql').strip()}

-- =====================================================
-- PART 3: 強制同步 Body Parts (來自 011)
-- =====================================================

{read_sql('011_force_sync_body_parts.sql').strip()}

-- =====================================================
-- 完成訊息
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ v1.0 系統初始數據完成！';
  RAISE NOTICE '   - 794 個系統動作（雙語）';
  RAISE NOTICE '   - 元數據表修正';
  RAISE NOTICE '   - Body Parts 同步';
END $$;
"""

write_sql('002_v1_initial_data.sql', content_002)

# ============================================================================
# 3. 003_v1_enhancements.sql (012+015+016+017+018+019+020)
# ============================================================================
print("\n創建 003_v1_enhancements.sql...")

content_003 = f"""-- =====================================================
-- StrengthWise v1.0 - 功能增強與優化
-- =====================================================
-- 合併自: 012, 015, 016, 017, 018, 019, 020
-- 最後更新: 2025-01-01
-- 
-- 包含:
-- 1. custom_exercises 欄位擴展 (012, 016)
-- 2. 索引優化 Phase 1 (015)
-- 3. Body Part 修正 (017)
-- 4. pgroonga 全文搜尋 (018, 020)
-- 5. Body Part View (019)
-- =====================================================

-- PART 1: custom_exercises 增加欄位 (來自 012)
{read_sql('012_create_custom_exercises_table.sql').strip()}

-- =====================================================
-- PART 2: 索引優化 Phase 1 (來自 015)
-- =====================================================

{read_sql('015_performance_optimization_phase1_indexes.sql').strip()}

-- =====================================================
-- PART 3: custom_exercises 增加 training_type (來自 016)
-- =====================================================

{read_sql('016_add_training_type_to_custom_exercises.sql').strip()}

-- =====================================================
-- PART 4: 修正心肺/伸展的 Body Part (來自 017)
-- =====================================================

{read_sql('017_fix_cardio_stretch_body_part.sql').strip()}

-- =====================================================
-- PART 5: pgroonga 全文搜尋 Phase 2 (來自 018)
-- =====================================================

{read_sql('018_performance_optimization_phase2_fulltext.sql').strip()}

-- =====================================================
-- PART 6: Body Part View (來自 019)
-- =====================================================

{read_sql('019_add_body_part_and_view.sql').strip()}

-- =====================================================
-- PART 7: 修正 pgroonga 函數名 (來自 020)
-- =====================================================

{read_sql('020_fix_pgroonga_function_names.sql').strip()}

-- =====================================================
-- 完成訊息
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ v1.0 功能增強與優化完成！';
  RAISE NOTICE '   - custom_exercises 欄位擴展';
  RAISE NOTICE '   - 索引優化';
  RAISE NOTICE '   - pgroonga 全文搜尋';
  RAISE NOTICE '   - Body Part View';
END $$;
"""

write_sql('003_v1_enhancements.sql', content_003)

# ============================================================================
# 4. 004_v1_optimization.sql (026)
# ============================================================================
print("\n創建 004_v1_optimization.sql...")
copy_sql('026_performance_optimization_phase3_stats_summary.sql', '004_v1_optimization.sql')

# ============================================================================
# 5-7. v2.0 檔案（直接複製）
# ============================================================================
print("\n創建 v2.0 Migration 檔案...")
copy_sql('021_phase1_coaching_relationships.sql', '005_v2_phase1_coaching.sql')
copy_sql('022_phase2_appointments.sql', '006_v2_phase2_appointments.sql')

# 合併 023+024+025
print("\n創建 007_v2_phase3_notes.sql...")

content_007 = f"""-- =====================================================
-- StrengthWise v2.0 Phase 3 - 視覺化筆記系統
-- =====================================================
-- 合併自: 023, 024, 025
-- 最後更新: 2025-01-01
-- 
-- 包含:
-- 1. Session Notes 表格 (023)
-- 2. Storage RLS 策略 (024)
-- 3. Drawing Canvas 結構 (025)
-- =====================================================

-- PART 1: 視覺化筆記與時間偏好 (來自 023)
{read_sql('023_phase3_visual_notes_and_time_preferences.sql').strip()}

-- =====================================================
-- PART 2: Storage RLS 策略 (來自 024)
-- =====================================================

{read_sql('024_storage_policies_session_photos.sql').strip()}

-- =====================================================
-- PART 3: Drawing Canvas 結構說明 (來自 025)
-- =====================================================

{read_sql('025_phase4a_drawing_canvas.sql').strip()}

-- =====================================================
-- 完成訊息
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ v2.0 Phase 3 視覺化筆記系統完成！';
  RAISE NOTICE '   - Session Notes (SOAP 格式)';
  RAISE NOTICE '   - 照片上傳 (Storage RLS)';
  RAISE NOTICE '   - 手繪板 (向量繪圖)';
  RAISE NOTICE '   - 時間偏好設定';
END $$;
"""

write_sql('007_v2_phase3_notes.sql', content_007)

print("\n" + "="*60)
print("✅ 所有 Migration 檔案創建完成！")
print("="*60)
print("\n新的 Migrations 結構:")
print("  001_v1_core_tables.sql          (001+002+004)")
print("  002_v1_initial_data.sql         (008+009+011)")
print("  003_v1_enhancements.sql         (012+015+016+017+018+019+020)")
print("  004_v1_optimization.sql         (026)")
print("  005_v2_phase1_coaching.sql      (021)")
print("  006_v2_phase2_appointments.sql  (022)")
print("  007_v2_phase3_notes.sql         (023+024+025)")
print("\n從 19 個檔案 → 7 個檔案 (-63%)")

