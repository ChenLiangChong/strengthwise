#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""合併 Migrations 腳本"""
import sys
import os

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

# ============================================================================
# 1. 合併 001_v1_core_tables.sql (001+002+004)
# ============================================================================
print("創建 001_v1_core_tables.sql...")

content_001 = f"""-- =====================================================
-- StrengthWise v1.0 - 核心表格
-- =====================================================
-- 合併自: 001, 002, 004
-- 最後更新: 2025-01-01
-- 
-- 包含表格:
-- 1. exercises (系統動作庫 - 794 個)
-- 2. body_parts, exercise_types (元數據)
-- 3. users (用戶資料)
-- 4. workout_plans (訓練計劃/記錄)
-- 5. workout_templates (訓練模板)
-- 6. custom_exercises (用戶自訂動作)
-- 7. body_data (身體數據)
-- =====================================================

-- 啟用必要的 PostgreSQL 擴展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

{read_sql('001_create_core_tables.sql').replace('-- 啟用必要的 PostgreSQL 擴展', '').replace('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";', '').replace('CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- 用於全文搜尋', '').strip()}

-- ============================================================================
-- PART 2: 用戶相關表格 (來自 002)
-- ============================================================================

{read_sql('002_create_user_tables.sql').replace('-- 啟用 UUID 擴展', '').replace('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";', '').strip()}

-- ============================================================================
-- PART 3: 身體數據表格 (來自 004)
-- ============================================================================

{read_sql('004_create_body_data_table.sql').strip()}

-- =====================================================
-- 完成訊息
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ v1.0 核心表格建立完成！';
  RAISE NOTICE '   - 系統表格: exercises, body_parts, exercise_types';
  RAISE NOTICE '   - 用戶表格: users, workout_plans, workout_templates';
  RAISE NOTICE '   - 其他表格: custom_exercises, body_data';
  RAISE NOTICE '';
  RAISE NOTICE '📋 下一步: 執行 002_v1_initial_data.sql 導入系統動作資料';
END $$;
"""

write_sql('001_v1_core_tables.sql', content_001)

print("\n✅ 完成！")
print(f"   合併檔案: {OUTPUT_DIR}/001_v1_core_tables.sql")
print(f"   包含: 001 + 002 + 004")

