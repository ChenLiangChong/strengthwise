#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
重新匯出 exercises 表格（使用更新後的資料）

這個腳本會從 Supabase 下載最新的 exercises 資料
"""

import os
import json
import sys
from datetime import datetime

# 設定輸出編碼
sys.stdout.reconfigure(encoding='utf-8')

def export_from_supabase_sql():
    """使用 SQL 查詢匯出（如果 Python SDK 無法連線）"""
    print("=" * 80)
    print("Supabase Exercises 匯出工具")
    print("=" * 80)
    print()
    print("⚠️ Python SDK 無法連線到 Supabase")
    print()
    print("請手動執行以下步驟：")
    print()
    print("1. 開啟 Supabase Dashboard SQL Editor")
    print("   https://supabase.com/dashboard/project/YOUR_PROJECT/sql")
    print()
    print("2. 執行以下 SQL：")
    print("-" * 80)
    print("""
-- 匯出所有 exercises 資料（JSON 格式）
SELECT jsonb_pretty(jsonb_agg(row_to_json(exercises.*)))
FROM exercises;
    """)
    print("-" * 80)
    print()
    print("3. 複製 SQL 執行結果（整個 JSON）")
    print()
    print("4. 將結果儲存為：database_export/exercises_latest.json")
    print()
    print("5. 然後執行：python scripts/test_query_coverage.py")
    print()
    print("=" * 80)

def main():
    """主函數"""
    try:
        from supabase import create_client
        from dotenv import load_dotenv
        
        load_dotenv()
        
        url = os.getenv("SUPABASE_URL") or "https://ltaxtzrvdxsyhnblxjmn.supabase.co"
        key = os.getenv("SUPABASE_ANON_KEY") or "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx0YXh0enJ2ZHhzeWhuYmx4am1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ0MTA3NzEsImV4cCI6MjA0OTk4Njc3MX0.gOb-KI7rFU3f_MBj1gqnKuRhJaL1IB5mRbVVg2vd6Qs"
        
        supabase = create_client(url, key)
        
        print("=" * 80)
        print("Supabase Exercises 匯出工具")
        print("=" * 80)
        print()
        print("[INFO] 正在連線到 Supabase...")
        
        # 嘗試查詢
        response = supabase.table('exercises').select('*').limit(1).execute()
        
        print("[INFO] ✅ 連線成功！")
        print("[INFO] 正在下載所有 exercises 資料...")
        
        # 下載所有資料
        response = supabase.table('exercises').select('*').execute()
        exercises = response.data
        
        print(f"[INFO] 已下載 {len(exercises)} 個動作")
        
        # 儲存為 JSON
        output_file = 'database_export/exercises_latest.json'
        os.makedirs('database_export', exist_ok=True)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(exercises, f, ensure_ascii=False, indent=2, default=str)
        
        print(f"[INFO] 已儲存至：{output_file}")
        
        # 顯示統計
        from collections import Counter
        
        training_types = Counter([ex.get('training_type') for ex in exercises])
        print("\ntraining_type 分佈:")
        for tt, count in training_types.most_common():
            print(f"  {tt}: {count}")
        
        # body_parts 統計
        body_parts_list = []
        for ex in exercises:
            bp = ex.get('body_parts', [])
            if bp:
                body_parts_list.extend(bp)
        body_parts = Counter(body_parts_list)
        print("\nbody_parts 分佈 (前10):")
        for bp, count in body_parts.most_common(10):
            print(f"  {bp}: {count}")
        
        print("\n✅ 匯出完成！")
        print("=" * 80)
        
        return 0
        
    except Exception as e:
        print(f"\n❌ 連線失敗：{e}")
        print()
        export_from_supabase_sql()
        return 1

if __name__ == "__main__":
    exit(main())


