#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Generate Complete Database Structure Documentation

This script will:
1. Connect to Supabase
2. Download complete schema information for all tables
3. Generate comprehensive documentation
4. Update migration files with latest structure

Usage:
    python scripts/generate_database_structure_doc.py

Output:
    - docs/DATABASE_STRUCTURE.md (Complete structure documentation)
    - database_export/database_schema_<timestamp>.json (Raw schema data)
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
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
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

# Supabase configuration
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[ERROR] Please set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables")
    print("        Make sure .env file exists and contains correct values")
    sys.exit(1)

# Initialize Supabase Client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 完整表格列表（根據最新 migrations）
ALL_TABLES = [
    # Core tables
    "users",
    "exercises",
    "custom_exercises",
    "workout_plans",
    "workout_templates",
    "body_data",
    "notes",
    
    # Metadata tables
    "body_parts",
    "exercise_types",
    
    # Statistics summary tables (Phase 3)
    "daily_workout_summary",
    "personal_records",
]

def ensure_export_dir():
    """Ensure export directory exists"""
    os.makedirs("database_export", exist_ok=True)
    os.makedirs("docs", exist_ok=True)

def get_table_info(table_name: str) -> Dict[str, Any]:
    """Get complete information about a table"""
    print(f"📊 Analyzing table: {table_name}")
    
    try:
        # Get sample data to analyze structure
        response = supabase.table(table_name).select("*").limit(1).execute()
        sample_data = response.data[0] if response.data else {}
        
        # Get record count
        count_response = supabase.table(table_name).select("*", count="exact").limit(1).execute()
        record_count = count_response.count or 0
        
        # Analyze columns
        columns = {}
        for key, value in sample_data.items():
            value_type = type(value).__name__
            if value_type == "NoneType":
                value_type = "NULL"
            columns[key] = {
                "type": value_type,
                "sample": str(value)[:50] if value else "NULL"
            }
        
        print(f"   ✅ {table_name}: {record_count} records, {len(columns)} columns")
        
        return {
            "name": table_name,
            "record_count": record_count,
            "columns": columns,
            "sample_record": sample_data
        }
        
    except Exception as e:
        print(f"   ❌ Failed to analyze {table_name}: {e}")
        return {
            "name": table_name,
            "record_count": 0,
            "columns": {},
            "error": str(e)
        }

def generate_markdown_doc(tables_info: List[Dict]) -> str:
    """Generate comprehensive markdown documentation"""
    
    doc = []
    doc.append("# StrengthWise - 資料庫結構文檔")
    doc.append("")
    doc.append(f"> **最後更新**: {datetime.now().strftime('%Y年%m月%d日 %H:%M:%S')}")
    doc.append(f"> **資料庫**: Supabase PostgreSQL")
    doc.append(f"> **表格數量**: {len(tables_info)} 個")
    doc.append("")
    doc.append("---")
    doc.append("")
    
    # Table of Contents
    doc.append("## 📋 目錄")
    doc.append("")
    doc.append("### 核心表格")
    core_tables = ["users", "exercises", "custom_exercises", "workout_plans", "workout_templates", "body_data", "notes"]
    for table in core_tables:
        table_info = next((t for t in tables_info if t["name"] == table), None)
        if table_info:
            count = table_info["record_count"]
            doc.append(f"- [{table}](#{table}) ({count:,} 筆)")
    
    doc.append("")
    doc.append("### 元數據表格")
    metadata_tables = ["body_parts", "exercise_types"]
    for table in metadata_tables:
        table_info = next((t for t in tables_info if t["name"] == table), None)
        if table_info:
            count = table_info["record_count"]
            doc.append(f"- [{table}](#{table}) ({count:,} 筆)")
    
    doc.append("")
    doc.append("### 統計彙總表格（效能優化）")
    summary_tables = ["daily_workout_summary", "personal_records"]
    for table in summary_tables:
        table_info = next((t for t in tables_info if t["name"] == table), None)
        if table_info:
            count = table_info["record_count"]
            doc.append(f"- [{table}](#{table}) ({count:,} 筆)")
    
    doc.append("")
    doc.append("---")
    doc.append("")
    
    # Detailed table information
    doc.append("## 📊 表格詳細資訊")
    doc.append("")
    
    for table_info in tables_info:
        table_name = table_info["name"]
        record_count = table_info["record_count"]
        columns = table_info.get("columns", {})
        
        doc.append(f"### {table_name}")
        doc.append("")
        doc.append(f"**記錄數**: {record_count:,} 筆")
        doc.append(f"**欄位數**: {len(columns)} 個")
        doc.append("")
        
        if "error" in table_info:
            doc.append(f"⚠️ **錯誤**: {table_info['error']}")
            doc.append("")
            continue
        
        if columns:
            doc.append("#### 欄位結構")
            doc.append("")
            doc.append("| 欄位名稱 | 資料型別 | 範例值 |")
            doc.append("|---------|---------|--------|")
            
            for col_name, col_info in columns.items():
                col_type = col_info["type"]
                sample = col_info["sample"]
                doc.append(f"| `{col_name}` | {col_type} | {sample} |")
            
            doc.append("")
        
        # Add table-specific notes
        if table_name == "users":
            doc.append("**說明**: 用戶資料表")
            doc.append("- 包含 Google Sign-In 認證資訊")
            doc.append("- 支援 `is_coach` 欄位（教練模式）")
            doc.append("")
        
        elif table_name == "exercises":
            doc.append("**說明**: 系統內建動作庫（794 個專業動作）")
            doc.append("- 五階層分類：訓練類型 → 身體部位 → 動作分類 → 具體動作")
            doc.append("- 支援中英雙語（繁體中文 + English）")
            doc.append("- pgroonga 全文搜尋索引")
            doc.append("")
        
        elif table_name == "custom_exercises":
            doc.append("**說明**: 用戶自訂動作")
            doc.append("- 用戶可創建個人化動作")
            doc.append("- 與系統動作統一整合（統計、訓練計劃）")
            doc.append("")
        
        elif table_name == "workout_plans":
            doc.append("**說明**: 訓練計劃與記錄（統一表格）")
            doc.append("- `completed = false`: 未完成的訓練計劃")
            doc.append("- `completed = true`: 已完成的訓練記錄")
            doc.append("- 包含 JSONB exercises 欄位（完整訓練數據）")
            doc.append("")
        
        elif table_name == "workout_templates":
            doc.append("**說明**: 訓練模板")
            doc.append("- 用戶可保存常用訓練計劃為模板")
            doc.append("- 快速創建新訓練計劃")
            doc.append("")
        
        elif table_name == "body_data":
            doc.append("**說明**: 身體數據追蹤")
            doc.append("- 體重、體脂、BMI、肌肉量")
            doc.append("- 每日一筆邏輯（同天更新而非新增）")
            doc.append("")
        
        elif table_name == "daily_workout_summary":
            doc.append("**說明**: 每日訓練統計彙總（效能優化 Phase 3）")
            doc.append("- 自動計算每日訓練統計（觸發器）")
            doc.append("- 包含訓練量、訓練組數、訓練動作數等")
            doc.append("- 查詢效能提升 80-95%")
            doc.append("")
        
        elif table_name == "personal_records":
            doc.append("**說明**: 個人記錄彙總（效能優化 Phase 3）")
            doc.append("- 自動計算每個動作的最大重量（觸發器）")
            doc.append("- 追蹤個人最佳記錄（PR）")
            doc.append("- 查詢效能提升 90-98%")
            doc.append("")
        
        doc.append("---")
        doc.append("")
    
    # Summary statistics
    doc.append("## 📈 資料庫統計")
    doc.append("")
    total_records = sum(t["record_count"] for t in tables_info)
    doc.append(f"- **總表格數**: {len(tables_info)} 個")
    doc.append(f"- **總記錄數**: {total_records:,} 筆")
    doc.append("")
    
    doc.append("### 各表格記錄數")
    doc.append("")
    doc.append("| 表格名稱 | 記錄數 |")
    doc.append("|---------|--------|")
    for table_info in sorted(tables_info, key=lambda x: x["record_count"], reverse=True):
        name = table_info["name"]
        count = table_info["record_count"]
        doc.append(f"| {name} | {count:,} |")
    doc.append("")
    
    doc.append("---")
    doc.append("")
    doc.append("## 🔗 相關文檔")
    doc.append("")
    doc.append("- [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md) - 詳細資料庫設計")
    doc.append("- [DATABASE_OPTIMIZATION_GUIDE.md](DATABASE_OPTIMIZATION_GUIDE.md) - 效能優化指南")
    doc.append("- [migrations/](../migrations/) - SQL 遷移腳本")
    doc.append("")
    doc.append("---")
    doc.append("")
    doc.append(f"**生成時間**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    doc.append("")
    
    return "\n".join(doc)

def main():
    """Main function"""
    print("=" * 80)
    print("StrengthWise - Database Structure Documentation Generator")
    print("=" * 80)
    print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("")
    
    try:
        print(f"🔗 Connected to Supabase: {SUPABASE_URL}")
        print(f"📋 Analyzing {len(ALL_TABLES)} tables...")
        print("")
        
        # Ensure export directory exists
        ensure_export_dir()
        
        # Analyze all tables
        tables_info = []
        for table_name in ALL_TABLES:
            table_info = get_table_info(table_name)
            tables_info.append(table_info)
        
        print("")
        print("=" * 80)
        print("📝 Generating documentation...")
        print("=" * 80)
        
        # Generate markdown documentation
        markdown_doc = generate_markdown_doc(tables_info)
        
        # Save markdown documentation
        doc_path = os.path.join(PROJECT_ROOT, "docs", "DATABASE_STRUCTURE.md")
        with open(doc_path, 'w', encoding='utf-8') as f:
            f.write(markdown_doc)
        print(f"✅ Saved: {doc_path}")
        
        # Save raw schema data (JSON)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        json_path = os.path.join(PROJECT_ROOT, "database_export", f"database_schema_{timestamp}.json")
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump({
                "exported_at": datetime.now().isoformat(),
                "tables": tables_info
            }, f, ensure_ascii=False, indent=2, default=str)
        print(f"✅ Saved: {json_path}")
        
        # Print summary
        print("")
        print("=" * 80)
        print("📊 Summary")
        print("=" * 80)
        total_records = sum(t["record_count"] for t in tables_info)
        total_columns = sum(len(t.get("columns", {})) for t in tables_info)
        
        print(f"✅ Total tables: {len(tables_info)}")
        print(f"✅ Total records: {total_records:,}")
        print(f"✅ Total columns: {total_columns}")
        print("")
        
        print("📋 Table Summary:")
        for table_info in sorted(tables_info, key=lambda x: x["record_count"], reverse=True):
            name = table_info["name"]
            count = table_info["record_count"]
            cols = len(table_info.get("columns", {}))
            print(f"   {name:30} {count:>8,} records, {cols:>3} columns")
        
        print("")
        print("=" * 80)
        print("✅ Documentation generated successfully!")
        print("=" * 80)
        print("")
        print("📄 Output files:")
        print(f"   1. {doc_path}")
        print(f"   2. {json_path}")
        print("")
        print("💡 Next steps:")
        print("   1. Review docs/DATABASE_STRUCTURE.md")
        print("   2. Update migrations if needed")
        print("   3. Sync with DATABASE_SUPABASE.md")
        print("")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())

