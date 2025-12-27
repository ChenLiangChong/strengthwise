#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
測試當前 Dart 查詢方式是否能查到所有動作

模擬 ExerciseServiceSupabase.getExercisesByFilters() 的查詢邏輯
"""

import os
import sys
from supabase import create_client, Client
from dotenv import load_dotenv
from collections import Counter

# 設定輸出編碼
sys.stdout.reconfigure(encoding='utf-8')

# 載入環境變數
load_dotenv()

def get_supabase_client() -> Client:
    """獲取 Supabase 客戶端"""
    url = os.getenv("SUPABASE_URL") or "https://ltaxtzrvdxsyhnblxjmn.supabase.co"
    key = os.getenv("SUPABASE_ANON_KEY") or "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx0YXh0enJ2ZHhzeWhuYmx4am1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ0MTA3NzEsImV4cCI6MjA0OTk4Njc3MX0.gOb-KI7rFU3f_MBj1gqnKuRhJaL1IB5mRbVVg2vd6Qs"
    return create_client(url, key)

def test_dart_query_logic(supabase: Client):
    """測試 Dart 的查詢邏輯"""
    print("=" * 80)
    print("測試 Dart 查詢方式（模擬 ExerciseServiceSupabase.getExercisesByFilters）")
    print("=" * 80)
    print()
    
    # 測試 1: 查詢所有動作（無條件）
    print("【測試 1】查詢所有動作（無條件）")
    print("-" * 80)
    try:
        response = supabase.table('exercises').select('*').execute()
        total_count = len(response.data)
        print(f"✅ 成功：查詢到 {total_count} 個動作")
        
        # 統計 training_type
        training_types = Counter([ex.get('training_type') for ex in response.data])
        print(f"\ntraining_type 分佈:")
        for tt, count in training_types.most_common():
            print(f"  {tt}: {count}")
        
        # 統計 body_parts（陣列欄位）
        body_parts_list = []
        for ex in response.data:
            bp = ex.get('body_parts', [])
            if bp:
                body_parts_list.extend(bp)
        body_parts = Counter(body_parts_list)
        print(f"\nbody_parts 分佈:")
        for bp, count in body_parts.most_common():
            print(f"  {bp}: {count}")
            
    except Exception as e:
        print(f"❌ 失敗：{e}")
    
    print("\n" + "=" * 80)
    
    # 測試 2: 模擬 Dart 的篩選查詢（阻力訓練）
    print("【測試 2】模擬 Dart 查詢：training_type = '阻力訓練'")
    print("-" * 80)
    try:
        query = supabase.table('exercises').select('*')
        query = query.eq('training_type', '阻力訓練')
        response = query.execute()
        
        count = len(response.data)
        print(f"✅ 查詢到 {count} 個阻力訓練動作")
        
    except Exception as e:
        print(f"❌ 失敗：{e}")
    
    print("\n" + "=" * 80)
    
    # 測試 3: 模擬 Dart 的組合查詢（阻力訓練 + 腿部）
    print("【測試 3】模擬 Dart 查詢：阻力訓練 + 腿部")
    print("-" * 80)
    print("Dart 代碼:")
    print("  filters['type'] = '阻力訓練'")
    print("  filters['bodyPart'] = '腿部'")
    print("  query.eq('training_type', value)")
    print("  query.contains('body_parts', [value])")
    print()
    
    try:
        query = supabase.table('exercises').select('*')
        query = query.eq('training_type', '阻力訓練')
        query = query.contains('body_parts', ['腿部'])
        response = query.execute()
        
        count = len(response.data)
        print(f"✅ 查詢到 {count} 個動作（阻力訓練 + 腿部）")
        
        if count > 0:
            print(f"\n前 5 個動作範例:")
            for i, ex in enumerate(response.data[:5], 1):
                print(f"  {i}. {ex['name']}")
                print(f"     training_type: {ex.get('training_type')}")
                print(f"     body_parts: {ex.get('body_parts')}")
        
    except Exception as e:
        print(f"❌ 失敗：{e}")
    
    print("\n" + "=" * 80)
    
    # 測試 4: 測試所有身體部位組合
    print("【測試 4】測試所有身體部位組合（阻力訓練 + 各身體部位）")
    print("-" * 80)
    
    body_parts_to_test = ['腿部', '胸部', '背部', '肩部', '手', '核心', '全身']
    
    results = {}
    for body_part in body_parts_to_test:
        try:
            query = supabase.table('exercises').select('*')
            query = query.eq('training_type', '阻力訓練')
            query = query.contains('body_parts', [body_part])
            response = query.execute()
            
            count = len(response.data)
            results[body_part] = count
            status = "✅" if count > 0 else "⚠️"
            print(f"{status} {body_part:10s}: {count:3d} 個動作")
            
        except Exception as e:
            print(f"❌ {body_part:10s}: 查詢失敗 - {e}")
    
    print("\n總計:")
    print(f"  可查詢到動作的身體部位: {sum(1 for c in results.values() if c > 0)} / {len(body_parts_to_test)}")
    print(f"  總動作數: {sum(results.values())}")
    
    print("\n" + "=" * 80)
    
    # 測試 5: 檢查是否有動作無法被查詢到
    print("【測試 5】檢查是否有動作無法被查詢到")
    print("-" * 80)
    
    try:
        # 獲取所有阻力訓練動作
        all_resistance = supabase.table('exercises').select('*').eq('training_type', '阻力訓練').execute()
        total_resistance = len(all_resistance.data)
        
        # 統計各身體部位的動作數
        queried_count = sum(results.values())
        
        print(f"總阻力訓練動作數: {total_resistance}")
        print(f"透過身體部位查詢到的動作數: {queried_count}")
        
        if total_resistance == queried_count:
            print(f"✅ 完美！所有動作都可以查詢到")
        else:
            diff = total_resistance - queried_count
            print(f"⚠️ 有 {diff} 個動作無法透過身體部位查詢到")
            
            # 找出無法查詢到的動作
            print(f"\n查找無法查詢到的動作...")
            all_ids = {ex['id'] for ex in all_resistance.data}
            
            queried_ids = set()
            for body_part in body_parts_to_test:
                query = supabase.table('exercises').select('id')
                query = query.eq('training_type', '阻力訓練')
                query = query.contains('body_parts', [body_part])
                response = query.execute()
                queried_ids.update(ex['id'] for ex in response.data)
            
            missing_ids = all_ids - queried_ids
            
            if missing_ids:
                print(f"\n無法查詢到的動作 ({len(missing_ids)} 個):")
                for ex_id in list(missing_ids)[:5]:
                    ex = next((e for e in all_resistance.data if e['id'] == ex_id), None)
                    if ex:
                        print(f"  - {ex['name']}")
                        print(f"    body_parts: {ex.get('body_parts')}")
                        print(f"    body_part: {ex.get('body_part')}")
                
    except Exception as e:
        print(f"❌ 失敗：{e}")
    
    print("\n" + "=" * 80)

def main():
    """主函數"""
    try:
        supabase = get_supabase_client()
        print("[INFO] 已連接到 Supabase")
        print()
        
        test_dart_query_logic(supabase)
        
        print("\n✅ 測試完成！")
        
    except Exception as e:
        print(f"\n❌ 錯誤：{e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())


