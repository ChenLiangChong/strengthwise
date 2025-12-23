#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
健身動作分析工具
下載所有動作數據並進行分類分析
"""

import firebase_admin
from firebase_admin import credentials, firestore
from collections import defaultdict, Counter
import json
import csv
from datetime import datetime

# 初始化 Firebase
cred = credentials.Certificate('strengthwise-service-account.json')
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()

print("=" * 80)
print("健身動作分析工具")
print("=" * 80)

# ============================================
# 階段 1: 下載所有動作數據
# ============================================
print("\n階段 1: 下載所有動作數據...")

exercises_ref = db.collection('exercise')
exercises = list(exercises_ref.stream())

print(f"總共下載 {len(exercises)} 個動作")

# 轉換為列表
exercises_data = []
for ex in exercises:
    data = ex.to_dict()
    data['id'] = ex.id
    exercises_data.append(data)

# 保存完整數據到 JSON
with open('exercises_data.json', 'w', encoding='utf-8') as f:
    json.dump(exercises_data, f, ensure_ascii=False, indent=2, default=str)
print(f"[OK] 已保存完整數據到: exercises_data.json")

# 保存到 CSV（方便在 Excel 中查看）
csv_file = 'exercises_data.csv'
if exercises_data:
    keys = ['id', 'name', 'nameEn', 'type', 'bodyParts', 'equipment', 'jointType', 
            'level1', 'level2', 'level3', 'level4', 'level5']
    
    with open(csv_file, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=keys, extrasaction='ignore')
        writer.writeheader()
        for ex in exercises_data:
            # 處理 bodyParts 列表
            row = ex.copy()
            if 'bodyParts' in row and isinstance(row['bodyParts'], list):
                row['bodyParts'] = ', '.join(row['bodyParts'])
            writer.writerow(row)
    
    print(f"[OK] 已保存 CSV 到: {csv_file}")

# ============================================
# 階段 2: 統計分析
# ============================================
print("\n" + "=" * 80)
print("階段 2: 統計分析")
print("=" * 80)

# 2.1 訓練類型分布
print("\n2.1 訓練類型分布:")
type_counts = Counter(ex.get('type', '未分類') for ex in exercises_data)
for type_name, count in sorted(type_counts.items(), key=lambda x: -x[1]):
    percentage = (count / len(exercises_data)) * 100
    print(f"  {type_name:20s}: {count:4d} 個動作 ({percentage:5.1f}%)")

# 2.2 身體部位分布
print("\n2.2 身體部位分布:")
bodypart_counts = Counter()
for ex in exercises_data:
    bodyParts = ex.get('bodyParts', [])
    if isinstance(bodyParts, list):
        for part in bodyParts:
            if part:
                bodypart_counts[part] += 1

for part, count in sorted(bodypart_counts.items(), key=lambda x: -x[1]):
    percentage = (count / len(exercises_data)) * 100
    print(f"  {part:15s}: {count:4d} 個動作 ({percentage:5.1f}%)")

# 2.3 器材使用統計
print("\n2.3 器材使用統計:")
equipment_counts = Counter(ex.get('equipment', '未分類') for ex in exercises_data)
for equipment, count in sorted(equipment_counts.items(), key=lambda x: -x[1])[:15]:
    percentage = (count / len(exercises_data)) * 100
    print(f"  {equipment:20s}: {count:4d} 個動作 ({percentage:5.1f}%)")

# 2.4 關節類型分布
print("\n2.4 關節類型分布:")
joint_counts = Counter(ex.get('jointType', '未分類') for ex in exercises_data)
for joint_type, count in sorted(joint_counts.items(), key=lambda x: -x[1]):
    percentage = (count / len(exercises_data)) * 100
    print(f"  {joint_type:15s}: {count:4d} 個動作 ({percentage:5.1f}%)")

# ============================================
# 階段 3: 階層分類分析
# ============================================
print("\n" + "=" * 80)
print("階段 3: 階層分類分析")
print("=" * 80)

# 3.1 Level1 分布
print("\n3.1 Level 1 分類:")
level1_counts = Counter(ex.get('level1', '未分類') for ex in exercises_data)
for level1, count in sorted(level1_counts.items(), key=lambda x: -x[1]):
    percentage = (count / len(exercises_data)) * 100
    print(f"  {level1:20s}: {count:4d} 個動作 ({percentage:5.1f}%)")

# 3.2 各訓練類型的 Level1 分布
print("\n3.2 各訓練類型的 Level1 分布:")
type_level1_dist = defaultdict(lambda: defaultdict(int))
for ex in exercises_data:
    type_name = ex.get('type', '未分類')
    level1 = ex.get('level1', '未分類')
    type_level1_dist[type_name][level1] += 1

for type_name in sorted(type_level1_dist.keys()):
    print(f"\n  【{type_name}】")
    for level1, count in sorted(type_level1_dist[type_name].items(), key=lambda x: -x[1]):
        print(f"    - {level1:20s}: {count:3d} 個動作")

# ============================================
# 階段 4: 問題檢測
# ============================================
print("\n" + "=" * 80)
print("階段 4: 問題檢測與建議")
print("=" * 80)

issues = []

# 4.1 檢測缺少身體部位的動作
print("\n4.1 檢測缺少身體部位的動作:")
no_bodyparts = [ex for ex in exercises_data 
                if not ex.get('bodyParts') or len(ex.get('bodyParts', [])) == 0]
if no_bodyparts:
    print(f"  [警告] 發現 {len(no_bodyparts)} 個動作沒有設定身體部位:")
    for ex in no_bodyparts[:10]:
        print(f"    - {ex.get('name', 'Unknown')}")
    if len(no_bodyparts) > 10:
        print(f"    ... 還有 {len(no_bodyparts) - 10} 個")
    issues.append(f"有 {len(no_bodyparts)} 個動作缺少身體部位標籤")
else:
    print("  [OK] 所有動作都有身體部位標籤")

# 4.2 檢測缺少分類階層的動作
print("\n4.2 檢測缺少分類階層的動作:")
no_level1 = [ex for ex in exercises_data if not ex.get('level1')]
if no_level1:
    print(f"  [警告] 發現 {len(no_level1)} 個動作沒有 Level1 分類:")
    for ex in no_level1[:10]:
        print(f"    - {ex.get('name', 'Unknown')} ({ex.get('type', '未分類')})")
    if len(no_level1) > 10:
        print(f"    ... 還有 {len(no_level1) - 10} 個")
    issues.append(f"有 {len(no_level1)} 個動作缺少 Level1 分類")
else:
    print("  [OK] 所有動作都有 Level1 分類")

# 4.3 檢測身體部位標籤不一致
print("\n4.3 檢測身體部位標籤變異:")
# 尋找可能的同義詞或拼寫變異
all_parts = set()
for ex in exercises_data:
    bodyParts = ex.get('bodyParts', [])
    if isinstance(bodyParts, list):
        all_parts.update(bodyParts)

# 檢查相似的部位名稱
similar_parts = []
parts_list = sorted(all_parts)
for i, part1 in enumerate(parts_list):
    for part2 in parts_list[i+1:]:
        # 檢查包含關係或相似度
        if part1 in part2 or part2 in part1:
            similar_parts.append((part1, part2))

if similar_parts:
    print(f"  [警告] 發現可能相似的身體部位標籤:")
    for part1, part2 in similar_parts:
        count1 = bodypart_counts.get(part1, 0)
        count2 = bodypart_counts.get(part2, 0)
        print(f"    - '{part1}' ({count1}) vs '{part2}' ({count2})")
    issues.append(f"發現 {len(similar_parts)} 對可能需要合併的身體部位")
else:
    print("  [OK] 未發現明顯需要合併的身體部位")

# 4.4 檢測單一動作有多個身體部位
print("\n4.4 多部位動作分布:")
multi_parts_dist = Counter()
for ex in exercises_data:
    bodyParts = ex.get('bodyParts', [])
    if isinstance(bodyParts, list):
        multi_parts_dist[len(bodyParts)] += 1

for num_parts, count in sorted(multi_parts_dist.items()):
    percentage = (count / len(exercises_data)) * 100
    print(f"  {num_parts} 個部位: {count:4d} 個動作 ({percentage:5.1f}%)")

# 列出訓練最多部位的動作
max_parts = max(len(ex.get('bodyParts', [])) for ex in exercises_data)
if max_parts > 3:
    print(f"\n  訓練 {max_parts} 個部位的動作:")
    for ex in exercises_data:
        if len(ex.get('bodyParts', [])) == max_parts:
            print(f"    - {ex.get('name')}: {', '.join(ex.get('bodyParts', []))}")

# ============================================
# 階段 5: 分類優化建議
# ============================================
print("\n" + "=" * 80)
print("階段 5: 分類優化建議")
print("=" * 80)

suggestions = []

# 5.1 身體部位分組建議
print("\n5.1 身體部位分組建議:")
print("  建議的主要分類:")
primary_groups = {
    '全身': ['全身'],
    '上肢': ['手', '前臂', '手肘', '手腕', '二頭肌', '三頭肌'],
    '肩部': ['肩', '前三角', '中三角', '後三角'],
    '胸部': ['胸', '上胸', '中胸', '下胸'],
    '背部': ['背', '上背', '中背', '下背', '闊背肌', '斜方肌', '豎脊肌'],
    '核心': ['核心', '腹', '腹直肌', '腹斜肌', '腹橫肌'],
    '下肢': ['腿', '股四頭', '膕繩肌', '小腿', '內收肌', '外展肌'],
    '臀部': ['臀', '臀大肌', '臀中肌'],
}

for group, parts in primary_groups.items():
    existing_parts = [p for p in parts if p in all_parts]
    total_count = sum(bodypart_counts.get(p, 0) for p in existing_parts)
    if existing_parts:
        print(f"  【{group}】({total_count} 個動作):")
        for part in existing_parts:
            count = bodypart_counts.get(part, 0)
            print(f"    - {part:15s}: {count:3d} 個動作")

suggestions.append("建議實作「主要肌群」和「細分肌群」兩層分類")

# 5.2 訓練類型優化建議
print("\n5.2 訓練類型優化建議:")
if len(type_counts) < 5:
    print("  [OK] 訓練類型數量合理")
elif len(type_counts) > 10:
    print(f"  [警告] 訓練類型過多 ({len(type_counts)} 種)，建議整合")
    suggestions.append(f"考慮整合訓練類型（當前有 {len(type_counts)} 種）")

# 找出動作數量很少的類型
rare_types = [(t, c) for t, c in type_counts.items() if c < 10]
if rare_types:
    print(f"  [警告] 以下訓練類型動作數量較少，建議合併:")
    for type_name, count in sorted(rare_types, key=lambda x: x[1]):
        print(f"    - {type_name}: {count} 個動作")
    suggestions.append(f"有 {len(rare_types)} 個訓練類型動作數量過少")

# 5.3 階層分類優化
print("\n5.3 階層分類建議:")
empty_levels = []
for level_name in ['level1', 'level2', 'level3', 'level4', 'level5']:
    filled_count = sum(1 for ex in exercises_data if ex.get(level_name))
    fill_rate = (filled_count / len(exercises_data)) * 100
    print(f"  {level_name}: {fill_rate:5.1f}% 填充率")
    if fill_rate < 50:
        empty_levels.append(level_name)

if empty_levels:
    suggestions.append(f"階層 {', '.join(empty_levels)} 使用率低，建議重新設計分類結構")

# ============================================
# 階段 6: 生成報告
# ============================================
print("\n" + "=" * 80)
print("階段 6: 生成分析報告")
print("=" * 80)

report = {
    'generated_at': datetime.now().isoformat(),
    'total_exercises': len(exercises_data),
    'statistics': {
        'training_types': dict(type_counts),
        'body_parts': dict(bodypart_counts),
        'equipment': dict(equipment_counts),
        'joint_types': dict(joint_counts),
        'level1_distribution': dict(level1_counts),
    },
    'issues': issues,
    'suggestions': suggestions,
    'primary_groups': {
        group: {
            'parts': parts,
            'total_count': sum(bodypart_counts.get(p, 0) for p in parts if p in all_parts)
        }
        for group, parts in primary_groups.items()
    }
}

report_file = 'exercises_analysis_report.json'
with open(report_file, 'w', encoding='utf-8') as f:
    json.dump(report, f, ensure_ascii=False, indent=2)

print(f"\n[OK] 分析報告已保存到: {report_file}")

# ============================================
# 總結
# ============================================
print("\n" + "=" * 80)
print("分析總結")
print("=" * 80)

print(f"\n數據概況:")
print(f"  - 總動作數: {len(exercises_data)}")
print(f"  - 訓練類型: {len(type_counts)} 種")
print(f"  - 身體部位: {len(bodypart_counts)} 個")
print(f"  - 器材類型: {len(equipment_counts)} 種")

print(f"\n發現的問題:")
if issues:
    for i, issue in enumerate(issues, 1):
        print(f"  {i}. {issue}")
else:
    print("  [OK] 未發現明顯問題")

print(f"\n優化建議:")
if suggestions:
    for i, suggestion in enumerate(suggestions, 1):
        print(f"  {i}. {suggestion}")
else:
    print("  [OK] 目前分類結構良好")

print("\n" + "=" * 80)
print("分析完成！")
print("=" * 80)
print(f"\n生成的文件:")
print(f"  1. exercises_data.json - 完整動作數據")
print(f"  2. exercises_data.csv - Excel 可讀格式")
print(f"  3. exercises_analysis_report.json - 分析報告")
print("\n建議:")
print("  1. 在 Excel 中打開 exercises_data.csv 查看詳細數據")
print("  2. 閱讀 exercises_analysis_report.json 了解優化建議")
print("  3. 根據建議調整動作分類結構")
print("=" * 80)

