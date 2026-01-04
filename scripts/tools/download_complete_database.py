#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Download Complete Supabase Database (v2.8 完整版)

此腳本會下載完整的資料庫結構（20 個表格）
根據 2026-01-04 Supabase 實際表格驗證

更新記錄：
- 2025-01-01: 更新為 16 個表格（包含 Phase 3 表格）
- 2026-01-04: 更新為 20 個表格（新增 v2.3 邀請碼 + v2.8 健康評估系統）

Usage:
    python scripts/tools/download_complete_database.py

Output:
    - database_export/
        |- <timestamp>/
            |- users.json                              
            |- exercises.json                          (794 筆)
            |- custom_exercises.json                   
            |- workout_plans.json                      
            |- workout_templates.json                  
            |- body_data.json                          
            |- notes.json                              (個人筆記)
            |- body_parts.json                         (8 筆)
            |- exercise_types.json                     (3 筆)
            |- coaching_relationships.json             
            |- availability_slots.json                 
            |- appointments.json                       
            |- session_notes.json                      (課程筆記)
            |- client_availability.json                
            |- daily_workout_summary.json              
            |- personal_records.json                   
            |- invite_codes.json                       (邀請碼) ⭐
            |- health_assessments.json                 (健康評估) ⭐
            |- coach_assessment_notes.json             (教練備註) ⭐
            |- coach_display_preferences.json          (教練偏好) ⭐
            |- database_summary.json                   (統計報告)
            |- README.md                               (說明文檔)
"""

import sys
import os
import json
from datetime import datetime
from typing import List, Dict, Any
from dotenv import load_dotenv
from supabase import create_client, Client

# Set UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

# Get project root and load environment variables
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(os.path.dirname(SCRIPT_DIR))
ENV_FILE = os.path.join(PROJECT_ROOT, '.env')

# Load environment variables (handle BOM)
if os.path.exists(ENV_FILE):
    with open(ENV_FILE, 'r', encoding='utf-8-sig') as f:
        env_content = f.read()
    temp_env = ENV_FILE + '.tmp'
    with open(temp_env, 'w', encoding='utf-8') as f:
        f.write(env_content)
    load_dotenv(temp_env)
    os.remove(temp_env)
    print(f"✅ Loaded environment variables: {ENV_FILE}")
else:
    load_dotenv()
    print(f"⚠️  Warning: .env file not found at {ENV_FILE}")

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[ERROR] Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables")
    print("        Make sure .env file exists and contains correct values")
    sys.exit(1)

# Initialize Supabase Client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 完整表格列表（根據 2026-01-04 Supabase 實際驗證）
# v1.0 核心表格（7 個）
CORE_TABLES = [
    "users",
    "exercises",
    "custom_exercises",
    "workout_plans",
    "workout_templates",
    "body_data",
    "notes"  # 個人筆記（v1.0 原始功能）
]

# v1.0 元數據表格（2 個）
METADATA_TABLES = [
    "body_parts",
    "exercise_types"
]

# v2.0 Phase 1 表格（1 個）
PHASE1_TABLES = [
    "coaching_relationships"
]

# v2.0 Phase 2 表格（2 個）
PHASE2_TABLES = [
    "availability_slots",
    "appointments"
]

# v2.0 Phase 3 表格（2 個）
PHASE3_TABLES = [
    "session_notes",       # 課程筆記（SOAP 格式）
    "client_availability"  # 學員時間偏好
]

# 優化表格（2 個）
OPTIMIZATION_TABLES = [
    "daily_workout_summary",
    "personal_records"
]

# v2.3 邀請碼系統（1 個）⭐
INVITE_SYSTEM_TABLES = [
    "invite_codes"
]

# v2.8 健康評估系統（3 個）⭐
HEALTH_ASSESSMENT_TABLES = [
    "health_assessments",
    "coach_assessment_notes",
    "coach_display_preferences"
]

# 合併所有表格（20 個）
ALL_TABLES = (
    CORE_TABLES + 
    METADATA_TABLES + 
    PHASE1_TABLES + 
    PHASE2_TABLES + 
    PHASE3_TABLES + 
    OPTIMIZATION_TABLES +
    INVITE_SYSTEM_TABLES +
    HEALTH_ASSESSMENT_TABLES
)

def ensure_export_dir(timestamp: str) -> str:
    """Ensure export directory exists"""
    export_dir = os.path.join(PROJECT_ROOT, "database_export", timestamp)
    os.makedirs(export_dir, exist_ok=True)
    return export_dir

def download_table(table_name: str):
    """Download all data from specified table"""
    print(f"📥 Downloading {table_name}...", end=" ")
    
    try:
        response = supabase.table(table_name).select("*").execute()
        data = response.data
        print(f"✅ {len(data)} records")
        return data, True
    except Exception as e:
        print(f"❌ Failed: {e}")
        return [], False

def save_json(data: any, filepath: str):
    """Save data as JSON file"""
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2, default=str)

def generate_summary(all_data: Dict[str, List], export_dir: str, timestamp: str):
    """Generate summary report"""
    total_records = sum(len(data) for data in all_data.values())
    
    summary = {
        "export_time": timestamp,
        "export_datetime": datetime.now().isoformat(),
        "total_tables": len(all_data),
        "total_records": total_records,
        "tables": {}
    }
    
    # 分類統計
    categories = {
        "v1.0 Core": CORE_TABLES,
        "v1.0 Metadata": METADATA_TABLES,
        "v2.0 Phase 1": PHASE1_TABLES,
        "v2.0 Phase 2": PHASE2_TABLES,
        "v2.0 Phase 3": PHASE3_TABLES,
        "Optimization": OPTIMIZATION_TABLES,
        "v2.3 Invite System": INVITE_SYSTEM_TABLES,
        "v2.8 Health Assessment": HEALTH_ASSESSMENT_TABLES
    }
    
    for category, tables in categories.items():
        summary["tables"][category] = {}
        for table in tables:
            count = len(all_data.get(table, []))
            summary["tables"][category][table] = count
    
    # 保存 JSON 摘要
    summary_path = os.path.join(export_dir, "database_summary.json")
    save_json(summary, summary_path)
    print(f"\n✅ Saved summary: {summary_path}")
    
    # 生成 README.md
    readme_lines = []
    readme_lines.append("# StrengthWise Database Export")
    readme_lines.append("")
    readme_lines.append(f"**匯出時間**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    readme_lines.append(f"**總表格數**: {len(all_data)} 個")
    readme_lines.append(f"**總記錄數**: {total_records:,} 筆")
    readme_lines.append("")
    readme_lines.append("---")
    readme_lines.append("")
    
    for category, tables in categories.items():
        readme_lines.append(f"## {category}")
        readme_lines.append("")
        readme_lines.append("| 表格名稱 | 記錄數 | 檔案 |")
        readme_lines.append("|---------|--------|------|")
        for table in tables:
            count = len(all_data.get(table, []))
            readme_lines.append(f"| {table} | {count:,} | {table}.json |")
        readme_lines.append("")
    
    readme_lines.append("---")
    readme_lines.append("")
    readme_lines.append("## 檔案說明")
    readme_lines.append("")
    readme_lines.append("- `database_summary.json` - 統計摘要（JSON 格式）")
    readme_lines.append("- `README.md` - 本說明文件")
    readme_lines.append("- `*.json` - 各表格資料")
    readme_lines.append("")
    
    readme_path = os.path.join(export_dir, "README.md")
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write("\n".join(readme_lines))
    print(f"✅ Saved README: {readme_path}")

def main():
    """Main function"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    print("=" * 80)
    print("StrengthWise - Complete Database Download Tool (v2.8)")
    print("=" * 80)
    print(f"⏰ Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"🔗 Supabase: {SUPABASE_URL}")
    print("")
    
    try:
        # Ensure export directory exists
        export_dir = ensure_export_dir(timestamp)
        print(f"📁 Export directory: {export_dir}")
        print("")
        
        # Show table summary
        print(f"📊 Total tables to download: {len(ALL_TABLES)}")
        print(f"   - v1.0 Core: {len(CORE_TABLES)} tables")
        print(f"   - v1.0 Metadata: {len(METADATA_TABLES)} tables")
        print(f"   - v2.0 Phase 1: {len(PHASE1_TABLES)} table")
        print(f"   - v2.0 Phase 2: {len(PHASE2_TABLES)} tables")
        print(f"   - v2.0 Phase 3: {len(PHASE3_TABLES)} tables")
        print(f"   - Optimization: {len(OPTIMIZATION_TABLES)} tables")
        print(f"   - v2.3 Invite System: {len(INVITE_SYSTEM_TABLES)} table ⭐")
        print(f"   - v2.8 Health Assessment: {len(HEALTH_ASSESSMENT_TABLES)} tables ⭐⭐⭐")
        print("")
        print("-" * 80)
        print("")
        
        # Download all tables
        all_data = {}
        success_count = 0
        failed_tables = []
        
        for table_name in ALL_TABLES:
            data, success = download_table(table_name)
            all_data[table_name] = data
            
            if success:
                success_count += 1
                # Save individual JSON file
                filepath = os.path.join(export_dir, f"{table_name}.json")
                save_json(data, filepath)
            else:
                failed_tables.append(table_name)
        
        print("")
        print("-" * 80)
        print("")
        
        # Generate summary
        generate_summary(all_data, export_dir, timestamp)
        
        # Print final summary
        print("")
        print("=" * 80)
        print("📊 Download Summary")
        print("=" * 80)
        print(f"✅ Successfully downloaded: {success_count}/{len(ALL_TABLES)} tables")
        
        if failed_tables:
            print(f"❌ Failed tables: {', '.join(failed_tables)}")
        
        total_records = sum(len(data) for data in all_data.values())
        print(f"📝 Total records: {total_records:,}")
        print("")
        
        # Show top 5 tables by record count
        print("🔝 Top 5 tables by record count:")
        sorted_tables = sorted(all_data.items(), key=lambda x: len(x[1]), reverse=True)
        for i, (table_name, data) in enumerate(sorted_tables[:5], 1):
            print(f"   {i}. {table_name}: {len(data):,} records")
        
        print("")
        print("=" * 80)
        print("✅ Download completed successfully!")
        print("=" * 80)
        print("")
        print(f"📁 Output directory: {export_dir}")
        print("")
        print("📄 Files generated:")
        print(f"   - database_summary.json (統計報告)")
        print(f"   - README.md (說明文檔)")
        print(f"   - {len(all_data)} × *.json (表格資料)")
        print("")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())

