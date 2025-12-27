#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StrengthWise - 生成 Supabase 更新 SQL 腳本
將優化後的動作資料轉換為 SQL UPDATE 語句
"""

import json
import sys
from datetime import datetime

# 設定輸出編碼為 UTF-8
sys.stdout.reconfigure(encoding='utf-8')

def load_optimized_exercises(filepath: str):
    """載入優化後的動作資料"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def escape_sql_string(text: str) -> str:
    """SQL 字串轉義"""
    if text is None:
        return 'NULL'
    # 替換單引號為兩個單引號
    return "'" + text.replace("'", "''") + "'"

def generate_update_sql(exercises: list) -> list:
    """生成 UPDATE SQL 語句（包含英文欄位）"""
    sql_statements = []
    
    # 添加檔頭註解
    sql_statements.append("-- ============================================================================")
    sql_statements.append("-- StrengthWise - 健身動作資料庫命名標準化更新（雙語版）")
    sql_statements.append("-- ")
    sql_statements.append("-- 基於生物力學、解剖學與器材工程學的專業命名系統")
    sql_statements.append("-- 包含中文與英文雙語欄位")
    sql_statements.append(f"-- 生成時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    sql_statements.append(f"-- 總動作數: {len(exercises)}")
    sql_statements.append("-- ============================================================================")
    sql_statements.append("")
    sql_statements.append("-- 步驟 1: 新增英文欄位（如果不存在）")
    sql_statements.append("ALTER TABLE exercises ADD COLUMN IF NOT EXISTS training_type_en TEXT;")
    sql_statements.append("ALTER TABLE exercises ADD COLUMN IF NOT EXISTS body_part_en TEXT;")
    sql_statements.append("ALTER TABLE exercises ADD COLUMN IF NOT EXISTS specific_muscle_en TEXT;")
    sql_statements.append("ALTER TABLE exercises ADD COLUMN IF NOT EXISTS equipment_category_en TEXT;")
    sql_statements.append("ALTER TABLE exercises ADD COLUMN IF NOT EXISTS equipment_subcategory_en TEXT;")
    sql_statements.append("")
    sql_statements.append("-- 步驟 2: 開始更新資料")
    sql_statements.append("BEGIN;")
    sql_statements.append("")
    
    # 為每個動作生成 UPDATE 語句
    for i, ex in enumerate(exercises):
        if (i + 1) % 100 == 0:
            sql_statements.append(f"-- 進度: {i + 1}/{len(exercises)}")
        
        # 構建 UPDATE 語句
        updates = []
        
        # 訓練類型（中文 + 英文）
        if 'training_type_optimized' in ex and ex['training_type_optimized']:
            updates.append(f"training_type = {escape_sql_string(ex['training_type_optimized'])}")
        if 'training_type_en' in ex and ex['training_type_en']:
            updates.append(f"training_type_en = {escape_sql_string(ex['training_type_en'])}")
        
        # 身體部位（中文 + 英文）
        if 'body_part_optimized' in ex and ex['body_part_optimized']:
            updates.append(f"body_part = {escape_sql_string(ex['body_part_optimized'])}")
        if 'body_part_en' in ex and ex['body_part_en']:
            updates.append(f"body_part_en = {escape_sql_string(ex['body_part_en'])}")
        
        # 特定肌群（中文 + 英文）
        if 'specific_muscle_optimized' in ex and ex['specific_muscle_optimized']:
            updates.append(f"specific_muscle = {escape_sql_string(ex['specific_muscle_optimized'])}")
        if 'specific_muscle_en' in ex and ex['specific_muscle_en']:
            updates.append(f"specific_muscle_en = {escape_sql_string(ex['specific_muscle_en'])}")
        
        # 器材類別（中文 + 英文）
        if 'equipment_category_optimized' in ex and ex['equipment_category_optimized']:
            updates.append(f"equipment_category = {escape_sql_string(ex['equipment_category_optimized'])}")
        if 'equipment_category_en' in ex and ex['equipment_category_en']:
            updates.append(f"equipment_category_en = {escape_sql_string(ex['equipment_category_en'])}")
        
        # 器材子類別（中文 + 英文）
        if 'equipment_subcategory_optimized' in ex and ex['equipment_subcategory_optimized']:
            updates.append(f"equipment_subcategory = {escape_sql_string(ex['equipment_subcategory_optimized'])}")
        if 'equipment_subcategory_en' in ex and ex['equipment_subcategory_en']:
            updates.append(f"equipment_subcategory_en = {escape_sql_string(ex['equipment_subcategory_en'])}")
        
        # 更新時間戳
        updates.append(f"updated_at = NOW()")
        
        if updates:
            sql = f"UPDATE exercises SET {', '.join(updates)} WHERE id = {escape_sql_string(ex['id'])};"
            sql_statements.append(sql)
    
    sql_statements.append("")
    sql_statements.append("-- 提交交易")
    sql_statements.append("COMMIT;")
    sql_statements.append("")
    sql_statements.append("-- ============================================================================")
    sql_statements.append("-- 更新完成")
    sql_statements.append("-- ============================================================================")
    
    return sql_statements

def generate_insert_sql(exercises: list) -> list:
    """生成 INSERT SQL 語句（完整替換，包含英文欄位）"""
    sql_statements = []
    
    # 添加檔頭註解
    sql_statements.append("-- ============================================================================")
    sql_statements.append("-- StrengthWise - 健身動作資料庫完整替換（雙語版）")
    sql_statements.append("-- ")
    sql_statements.append("-- 警告：此腳本會刪除所有現有動作並重新插入")
    sql_statements.append("-- 包含中文與英文雙語欄位")
    sql_statements.append(f"-- 生成時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    sql_statements.append(f"-- 總動作數: {len(exercises)}")
    sql_statements.append("-- ============================================================================")
    sql_statements.append("")
    sql_statements.append("-- 步驟 1: 新增英文欄位（如果不存在）")
    sql_statements.append("ALTER TABLE exercises ADD COLUMN IF NOT EXISTS training_type_en TEXT;")
    sql_statements.append("ALTER TABLE exercises ADD COLUMN IF NOT EXISTS body_part_en TEXT;")
    sql_statements.append("ALTER TABLE exercises ADD COLUMN IF NOT EXISTS specific_muscle_en TEXT;")
    sql_statements.append("ALTER TABLE exercises ADD COLUMN IF NOT EXISTS equipment_category_en TEXT;")
    sql_statements.append("ALTER TABLE exercises ADD COLUMN IF NOT EXISTS equipment_subcategory_en TEXT;")
    sql_statements.append("")
    sql_statements.append("-- 步驟 2: 開始交易")
    sql_statements.append("BEGIN;")
    sql_statements.append("")
    sql_statements.append("-- 步驟 3: 刪除所有系統預設動作（user_id IS NULL）")
    sql_statements.append("DELETE FROM exercises WHERE user_id IS NULL;")
    sql_statements.append("")
    
    # 批次插入
    batch_size = 50
    for i in range(0, len(exercises), batch_size):
        batch = exercises[i:i+batch_size]
        sql_statements.append(f"-- 批次 {i//batch_size + 1}: 動作 {i+1} 到 {min(i+batch_size, len(exercises))}")
        sql_statements.append("INSERT INTO exercises (")
        sql_statements.append("  id, name, name_en, action_name,")
        sql_statements.append("  training_type, training_type_en,")
        sql_statements.append("  body_part, body_part_en,")
        sql_statements.append("  body_parts, specific_muscle, specific_muscle_en,")
        sql_statements.append("  equipment, equipment_category, equipment_category_en,")
        sql_statements.append("  equipment_subcategory, equipment_subcategory_en,")
        sql_statements.append("  joint_type, level1, level2, level3, level4, level5,")
        sql_statements.append("  description, image_url, video_url, user_id, updated_at")
        sql_statements.append(") VALUES")
        
        values = []
        for ex in batch:
            # 處理優化後的欄位，如果有優化值則使用優化值，否則使用原值
            training_type = ex.get('training_type_optimized', ex.get('training_type', ''))
            training_type_en = ex.get('training_type_en', '')
            
            body_part = ex.get('body_part_optimized', ex.get('body_part', ''))
            body_part_en = ex.get('body_part_en', '')
            
            specific_muscle = ex.get('specific_muscle_optimized', ex.get('specific_muscle', ''))
            specific_muscle_en = ex.get('specific_muscle_en', '')
            
            equipment_category = ex.get('equipment_category_optimized', ex.get('equipment_category', ''))
            equipment_category_en = ex.get('equipment_category_en', '')
            
            equipment_subcategory = ex.get('equipment_subcategory_optimized', ex.get('equipment_subcategory', ''))
            equipment_subcategory_en = ex.get('equipment_subcategory_en', '')
            
            name_en = ex.get('name_en', '')
            
            # 處理 body_parts 陣列
            body_parts_json = json.dumps(ex.get('body_parts', []), ensure_ascii=False)
            
            value = f"""  (
    {escape_sql_string(ex['id'])},
    {escape_sql_string(ex.get('name', ''))},
    {escape_sql_string(name_en)},
    {escape_sql_string(ex.get('action_name', ''))},
    {escape_sql_string(training_type)},
    {escape_sql_string(training_type_en)},
    {escape_sql_string(body_part)},
    {escape_sql_string(body_part_en)},
    '{body_parts_json}'::jsonb,
    {escape_sql_string(specific_muscle)},
    {escape_sql_string(specific_muscle_en)},
    {escape_sql_string(ex.get('equipment', ''))},
    {escape_sql_string(equipment_category)},
    {escape_sql_string(equipment_category_en)},
    {escape_sql_string(equipment_subcategory)},
    {escape_sql_string(equipment_subcategory_en)},
    {escape_sql_string(ex.get('joint_type', ''))},
    {escape_sql_string(ex.get('level1', ''))},
    {escape_sql_string(ex.get('level2', ''))},
    {escape_sql_string(ex.get('level3', ''))},
    {escape_sql_string(ex.get('level4', ''))},
    {escape_sql_string(ex.get('level5', ''))},
    {escape_sql_string(ex.get('description', ''))},
    {escape_sql_string(ex.get('image_url', ''))},
    {escape_sql_string(ex.get('video_url', ''))},
    NULL,
    NOW()
  )"""
            values.append(value)
        
        sql_statements.append(",\n".join(values))
        sql_statements.append("ON CONFLICT (id) DO UPDATE SET")
        sql_statements.append("  name = EXCLUDED.name,")
        sql_statements.append("  name_en = EXCLUDED.name_en,")
        sql_statements.append("  training_type = EXCLUDED.training_type,")
        sql_statements.append("  training_type_en = EXCLUDED.training_type_en,")
        sql_statements.append("  body_part = EXCLUDED.body_part,")
        sql_statements.append("  body_part_en = EXCLUDED.body_part_en,")
        sql_statements.append("  specific_muscle = EXCLUDED.specific_muscle,")
        sql_statements.append("  specific_muscle_en = EXCLUDED.specific_muscle_en,")
        sql_statements.append("  equipment_category = EXCLUDED.equipment_category,")
        sql_statements.append("  equipment_category_en = EXCLUDED.equipment_category_en,")
        sql_statements.append("  equipment_subcategory = EXCLUDED.equipment_subcategory,")
        sql_statements.append("  equipment_subcategory_en = EXCLUDED.equipment_subcategory_en,")
        sql_statements.append("  updated_at = NOW();")
        sql_statements.append("")
    
    sql_statements.append("-- 提交交易")
    sql_statements.append("COMMIT;")
    sql_statements.append("")
    sql_statements.append("-- ============================================================================")
    sql_statements.append("-- 插入完成")
    sql_statements.append("-- ============================================================================")
    
    return sql_statements

def main():
    """主程序"""
    print("=" * 80)
    print("StrengthWise - 生成 Supabase 更新 SQL 腳本")
    print("=" * 80)
    print()
    
    # 檔案路徑
    input_file = 'database_export/exercises_optimized.json'
    update_sql_file = 'migrations/008_update_exercise_naming.sql'
    insert_sql_file = 'migrations/009_insert_exercises_complete.sql'
    
    # 載入優化後的資料
    print(f"📂 載入優化資料：{input_file}")
    exercises = load_optimized_exercises(input_file)
    print(f"✅ 成功載入 {len(exercises)} 個動作")
    print()
    
    # 生成 UPDATE SQL
    print(f"🔄 生成 UPDATE SQL 腳本：{update_sql_file}")
    update_sql = generate_update_sql(exercises)
    with open(update_sql_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(update_sql))
    print(f"✅ 生成成功（{len(update_sql)} 行）")
    print()
    
    # 生成 INSERT SQL
    print(f"📝 生成 INSERT SQL 腳本：{insert_sql_file}")
    insert_sql = generate_insert_sql(exercises)
    with open(insert_sql_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(insert_sql))
    print(f"✅ 生成成功（{len(insert_sql)} 行）")
    print()
    
    print("=" * 80)
    print("🎉 SQL 腳本生成完成！")
    print("=" * 80)
    print()
    print("📁 輸出檔案：")
    print(f"   1. {update_sql_file} - 更新現有動作（安全）")
    print(f"   2. {insert_sql_file} - 完整替換動作（含新增/刪除）")
    print()
    print("⚠️ 執行前請注意：")
    print("   - 方案 1 (UPDATE): 只更新命名，不影響現有動作")
    print("   - 方案 2 (INSERT): 完整替換，會刪除系統預設動作後重新插入")
    print("   - 建議先在測試環境執行")
    print()
    print("執行方式：")
    print("   1. 登入 Supabase Dashboard")
    print("   2. 進入 SQL Editor")
    print("   3. 複製貼上 SQL 腳本")
    print("   4. 執行")

if __name__ == '__main__':
    main()

