#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
從 Supabase 下載所有動作資料

功能：
- 下載所有系統動作（exercises 表格）
- 下載元數據（body_parts, exercise_types, equipments, joint_types）
- 導出為 JSON 和 CSV 格式
- 支援篩選和搜尋

使用方式:
    python scripts/export_exercises_supabase.py

輸出：
- exercises_export.json - 完整 JSON 格式
- exercises_export.csv - CSV 格式（適合 Excel）
- metadata_export.json - 元數據
"""

import sys
import os
import json
import pandas as pd
from datetime import datetime
from typing import List, Dict, Any
from dotenv import load_dotenv
from supabase import create_client, Client

# 設置 UTF-8 輸出
sys.stdout.reconfigure(encoding='utf-8')

# 獲取專案根目錄並載入環境變數
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
ENV_FILE = os.path.join(PROJECT_ROOT, '.env')

# 載入環境變數（處理 BOM）
if os.path.exists(ENV_FILE):
    with open(ENV_FILE, 'r', encoding='utf-8-sig') as f:
        env_content = f.read()
    temp_env = ENV_FILE + '.tmp'
    with open(temp_env, 'w', encoding='utf-8') as f:
        f.write(env_content)
    load_dotenv(temp_env)
    os.remove(temp_env)
    print(f"✅ 已載入環境變數: {ENV_FILE}")
else:
    load_dotenv()

# Supabase 配置
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[ERROR] 請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY 環境變數")
    print("       請確認 .env 文件存在並包含正確的值")
    sys.exit(1)

# 初始化 Supabase Client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def fetch_exercises() -> List[Dict[str, Any]]:
    """獲取所有動作資料"""
    print("\n[1/5] 正在下載動作資料...")
    
    try:
        response = supabase.table('exercises').select('*').is_('user_id', 'null').execute()
        exercises = response.data
        print(f"✅ 成功下載 {len(exercises)} 個動作")
        return exercises
    except Exception as e:
        print(f"❌ 下載失敗: {e}")
        return []

def fetch_metadata() -> Dict[str, List[Dict]]:
    """獲取所有元數據"""
    print("\n[2/5] 正在下載元數據...")
    
    metadata = {}
    tables = ['body_parts', 'exercise_types', 'equipments', 'joint_types']
    
    for table in tables:
        try:
            response = supabase.table(table).select('*').execute()
            metadata[table] = response.data
            print(f"  ✅ {table}: {len(response.data)} 筆")
        except Exception as e:
            print(f"  ❌ {table} 下載失敗: {e}")
            metadata[table] = []
    
    return metadata

def export_to_json(exercises: List[Dict], metadata: Dict, output_dir: str = 'data/exports'):
    """導出為 JSON 格式"""
    print("\n[3/5] 正在導出 JSON 格式...")
    
    # 創建輸出目錄
    os.makedirs(output_dir, exist_ok=True)
    
    # 導出動作
    exercises_file = os.path.join(output_dir, 'exercises_export.json')
    with open(exercises_file, 'w', encoding='utf-8') as f:
        json.dump(exercises, f, ensure_ascii=False, indent=2)
    print(f"  ✅ 動作: {exercises_file}")
    
    # 導出元數據
    metadata_file = os.path.join(output_dir, 'metadata_export.json')
    with open(metadata_file, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    print(f"  ✅ 元數據: {metadata_file}")

def export_to_csv(exercises: List[Dict], output_dir: str = 'data/exports'):
    """導出為 CSV 格式"""
    print("\n[4/5] 正在導出 CSV 格式...")
    
    # 創建輸出目錄
    os.makedirs(output_dir, exist_ok=True)
    
    # 轉換為 DataFrame
    df = pd.DataFrame(exercises)
    
    # 處理 JSONB 欄位（轉為字串）
    for col in ['body_parts', 'muscle_groups']:
        if col in df.columns:
            df[col] = df[col].apply(lambda x: json.dumps(x, ensure_ascii=False) if x else '')
    
    # 導出 CSV
    csv_file = os.path.join(output_dir, 'exercises_export.csv')
    df.to_csv(csv_file, index=False, encoding='utf-8-sig')
    print(f"  ✅ CSV: {csv_file}")

def print_statistics(exercises: List[Dict], metadata: Dict):
    """列印統計資訊"""
    print("\n[5/5] 統計資訊")
    print("=" * 60)
    
    # 動作統計
    print(f"\n📊 動作總數: {len(exercises)}")
    
    # 訓練類型分布
    training_types = {}
    for ex in exercises:
        t_type = ex.get('training_type', '未分類')
        training_types[t_type] = training_types.get(t_type, 0) + 1
    
    print("\n訓練類型分布:")
    for t_type, count in sorted(training_types.items(), key=lambda x: x[1], reverse=True):
        percentage = (count / len(exercises)) * 100
        print(f"  {t_type}: {count} ({percentage:.1f}%)")
    
    # 身體部位分布
    body_parts_count = {}
    for ex in exercises:
        body_part = ex.get('body_part', '未分類')
        if body_part:
            body_parts_count[body_part] = body_parts_count.get(body_part, 0) + 1
    
    print("\n身體部位分布 (Top 5):")
    for part, count in sorted(body_parts_count.items(), key=lambda x: x[1], reverse=True)[:5]:
        percentage = (count / len(exercises)) * 100
        print(f"  {part}: {count} ({percentage:.1f}%)")
    
    # 器材類別分布
    equipment_categories = {}
    for ex in exercises:
        eq_cat = ex.get('equipment_category', '未分類')
        if eq_cat:
            equipment_categories[eq_cat] = equipment_categories.get(eq_cat, 0) + 1
    
    print("\n器材類別分布:")
    for cat, count in sorted(equipment_categories.items(), key=lambda x: x[1], reverse=True):
        percentage = (count / len(exercises)) * 100
        print(f"  {cat}: {count} ({percentage:.1f}%)")
    
    # 元數據統計
    print("\n📦 元數據:")
    for table, data in metadata.items():
        print(f"  {table}: {len(data)} 筆")
    
    print("\n" + "=" * 60)

def main():
    """主函數"""
    print("=" * 60)
    print("StrengthWise - 動作資料導出工具（Supabase 版本）")
    print("=" * 60)
    print(f"時間: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # 1. 下載動作
    exercises = fetch_exercises()
    if not exercises:
        print("\n❌ 無法下載動作資料，程式終止")
        sys.exit(1)
    
    # 2. 下載元數據
    metadata = fetch_metadata()
    
    # 3. 導出 JSON
    export_to_json(exercises, metadata)
    
    # 4. 導出 CSV
    export_to_csv(exercises)
    
    # 5. 統計資訊
    print_statistics(exercises, metadata)
    
    print("\n✅ 導出完成！")
    print("\n輸出文件:")
    print("  - data/exports/exercises_export.json")
    print("  - data/exports/exercises_export.csv")
    print("  - data/exports/metadata_export.json")

if __name__ == "__main__":
    main()

