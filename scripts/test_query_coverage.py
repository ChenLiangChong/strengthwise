#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
測試當前 Dart 查詢方式（使用本地 JSON 檔案）

模擬 ExerciseServiceSupabase.getExercisesByFilters() 的查詢邏輯
"""

import json
import sys
from collections import Counter

# 設定輸出編碼
sys.stdout.reconfigure(encoding='utf-8')

def load_exercises():
    """載入本地 exercises.json"""
    with open('database_export/exercises.json', 'r', encoding='utf-8') as f:
        return json.load(f)

def simulate_dart_query(exercises, filters):
    """模擬 Dart 的查詢邏輯"""
    results = exercises.copy()
    
    # 模擬 Dart 的篩選條件
    for key, value in filters.items():
        if key == 'type':
            # query.eq('training_type', value)
            results = [ex for ex in results if ex.get('training_type') == value]
        elif key == 'bodyPart':
            # query.contains('body_parts', [value])
            results = [ex for ex in results if value in (ex.get('body_parts') or [])]
    
    return results

def main():
    """主函數"""
    print("=" * 80)
    print("測試 Dart 查詢方式（使用本地 JSON）")
    print("=" * 80)
    print()
    
    # 載入動作資料
    exercises = load_exercises()
    print(f"[INFO] 已載入 {len(exercises)} 個動作")
    print()
    
    # 測試 1: 查詢所有動作
    print("【測試 1】查詢所有動作")
    print("-" * 80)
    
    # 統計 training_type
    training_types = Counter([ex.get('training_type') for ex in exercises])
    print(f"training_type 分佈:")
    for tt, count in training_types.most_common():
        print(f"  {tt}: {count}")
    
    # 統計 body_parts
    body_parts_list = []
    for ex in exercises:
        bp = ex.get('body_parts', [])
        if bp:
            body_parts_list.extend(bp)
    body_parts = Counter(body_parts_list)
    print(f"\nbody_parts 分佈:")
    for bp, count in body_parts.most_common():
        print(f"  {bp}: {count}")
    
    print("\n" + "=" * 80)
    
    # 測試 2: 阻力訓練
    print("【測試 2】查詢：training_type = '阻力訓練'")
    print("-" * 80)
    
    filters = {'type': '阻力訓練'}
    results = simulate_dart_query(exercises, filters)
    print(f"✅ 查詢到 {len(results)} 個動作")
    
    print("\n" + "=" * 80)
    
    # 測試 3: 阻力訓練 + 腿部
    print("【測試 3】查詢：阻力訓練 + 腿部")
    print("-" * 80)
    print("Dart 代碼:")
    print("  filters['type'] = '阻力訓練'")
    print("  filters['bodyPart'] = '腿部'")
    print()
    
    filters = {'type': '阻力訓練', 'bodyPart': '腿部'}
    results = simulate_dart_query(exercises, filters)
    print(f"✅ 查詢到 {len(results)} 個動作")
    
    if len(results) > 0:
        print(f"\n前 5 個動作範例:")
        for i, ex in enumerate(results[:5], 1):
            print(f"  {i}. {ex['name']}")
            print(f"     training_type: {ex.get('training_type')}")
            print(f"     body_parts: {ex.get('body_parts')}")
    
    print("\n" + "=" * 80)
    
    # 測試 4: 所有身體部位組合
    print("【測試 4】測試所有身體部位組合")
    print("-" * 80)
    
    body_parts_to_test = ['腿部', '胸部', '背部', '肩部', '手', '核心', '全身']
    
    results_summary = {}
    for body_part in body_parts_to_test:
        filters = {'type': '阻力訓練', 'bodyPart': body_part}
        results = simulate_dart_query(exercises, filters)
        
        count = len(results)
        results_summary[body_part] = count
        status = "✅" if count > 0 else "⚠️"
        print(f"{status} {body_part:10s}: {count:3d} 個動作")
    
    print("\n總計:")
    print(f"  可查詢到動作的身體部位: {sum(1 for c in results_summary.values() if c > 0)} / {len(body_parts_to_test)}")
    print(f"  總動作數: {sum(results_summary.values())}")
    
    print("\n" + "=" * 80)
    
    # 測試 5: 檢查覆蓋率
    print("【測試 5】檢查查詢覆蓋率")
    print("-" * 80)
    
    # 所有阻力訓練動作
    all_resistance = simulate_dart_query(exercises, {'type': '阻力訓練'})
    total_resistance = len(all_resistance)
    
    # 透過身體部位查詢的動作（去重）
    queried_ids = set()
    for body_part in body_parts_to_test:
        filters = {'type': '阻力訓練', 'bodyPart': body_part}
        results = simulate_dart_query(exercises, filters)
        queried_ids.update(ex['id'] for ex in results)
    
    queried_count = len(queried_ids)
    
    print(f"總阻力訓練動作數: {total_resistance}")
    print(f"透過身體部位查詢到的動作數（去重）: {queried_count}")
    
    if total_resistance == queried_count:
        print(f"\n✅ 完美！所有動作都可以查詢到")
    else:
        diff = total_resistance - queried_count
        percentage = (diff / total_resistance) * 100
        print(f"\n⚠️ 有 {diff} 個動作（{percentage:.1f}%）無法透過身體部位查詢到")
        
        # 找出無法查詢到的動作
        all_ids = {ex['id'] for ex in all_resistance}
        missing_ids = all_ids - queried_ids
        
        if missing_ids:
            print(f"\n無法查詢到的動作範例（前 10 個）:")
            for i, ex_id in enumerate(list(missing_ids)[:10], 1):
                ex = next((e for e in all_resistance if e['id'] == ex_id), None)
                if ex:
                    print(f"  {i}. {ex['name']}")
                    print(f"     body_part: {ex.get('body_part')}")
                    print(f"     body_parts: {ex.get('body_parts')}")
    
    print("\n" + "=" * 80)
    
    # 測試 6: 檢查其他訓練類型
    print("【測試 6】檢查其他訓練類型的覆蓋率")
    print("-" * 80)
    
    for training_type in ['心肺適能訓練', '活動度與伸展']:
        all_type = simulate_dart_query(exercises, {'type': training_type})
        
        if len(all_type) == 0:
            print(f"\n{training_type}: 無動作")
            continue
        
        # 透過身體部位查詢
        queried_type_ids = set()
        for body_part in body_parts_to_test:
            results = simulate_dart_query(exercises, {'type': training_type, 'bodyPart': body_part})
            queried_type_ids.update(ex['id'] for ex in results)
        
        total = len(all_type)
        queried = len(queried_type_ids)
        missing = total - queried
        
        status = "✅" if missing == 0 else "⚠️"
        print(f"\n{status} {training_type}:")
        print(f"  總動作數: {total}")
        print(f"  可查詢到: {queried}")
        print(f"  無法查詢: {missing}")
    
    print("\n" + "=" * 80)
    print("✅ 測試完成！")
    print("=" * 80)

if __name__ == "__main__":
    main()


