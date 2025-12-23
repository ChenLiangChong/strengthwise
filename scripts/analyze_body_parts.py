#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
分析 Firestore 中的身體部位分類
找出重複和需要合併的項目
"""

import firebase_admin
from firebase_admin import credentials, firestore
from collections import defaultdict
import json

# 初始化 Firebase
cred = credentials.Certificate('strengthwise-service-account.json')
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()

print("=" * 60)
print("開始分析身體部位分類")
print("=" * 60)

# 1. 獲取所有身體部位
print("\n1. 獲取 bodyParts 集合...")
body_parts_ref = db.collection('bodyParts')
body_parts_docs = body_parts_ref.stream()

body_parts_list = []
for doc in body_parts_docs:
    data = doc.to_dict()
    body_parts_list.append({
        'id': doc.id,
        'name': data.get('name', ''),
        'count': data.get('count', 0)
    })

print(f"找到 {len(body_parts_list)} 個身體部位")
body_parts_list.sort(key=lambda x: x['name'])

print("\n身體部位列表：")
for part in body_parts_list:
    print(f"  - {part['name']:15s} (動作數: {part['count']:3d}, ID: {part['id']})")

# 2. 從 exercise 集合分析實際使用情況
print("\n2. 分析 exercise 集合中的 bodyParts 使用情況...")
exercises_ref = db.collection('exercise')
exercises = exercises_ref.stream()

# 統計每個 bodyPart 出現的次數和包含它的動作
bodypart_usage = defaultdict(lambda: {'count': 0, 'exercises': []})

for ex in exercises:
    data = ex.to_dict()
    body_parts = data.get('bodyParts', [])
    exercise_name = data.get('name', '')
    
    for part in body_parts:
        bodypart_usage[part]['count'] += 1
        bodypart_usage[part]['exercises'].append({
            'id': ex.id,
            'name': exercise_name
        })

print(f"\n在 exercise 集合中實際使用的身體部位：")
for part, info in sorted(bodypart_usage.items()):
    print(f"  - {part:15s}: {info['count']:3d} 個動作")

# 3. 識別需要合併的項目
print("\n3. 識別需要合併的身體部位...")

# 定義合併規則：將相似的部位合併為標準名稱
merge_mapping = {
    # 標準名稱: [需要合併的變體]
    '全身': ['全身'],
    '手': ['手', '手臂'],  # 合併 "手" 和 "手臂"
    '核心': ['核心'],
    '肩': ['肩', '肩部'],  # 合併 "肩" 和 "肩部"
    '肩、背': ['肩、背'],  # 保持原樣，不拆分
    '背': ['背', '背部'],  # 合併 "背" 和 "背部"
    '胸': ['胸', '胸部'],  # 合併 "胸" 和 "胸部"
    '腿': ['腿', '腿部'],  # 合併 "腿" 和 "腿部"
    '臀': ['臀'],
    '腹': ['腹'],
    '手肘': ['手肘'],
    '手腕': ['手腕'],
    '前臂': ['前臂'],
    '二頭肌': ['二頭肌'],
    '三頭肌': ['三頭肌'],
    '前三角': ['前三角'],
    '中三角': ['中三角'],
    '後三角': ['後三角'],
    '上胸': ['上胸'],
    '中胸': ['中胸'],
    '下胸': ['下胸'],
    '上背': ['上背'],
    '中背': ['中背'],
    '下背': ['下背'],
    '闊背肌': ['闊背肌'],
    '斜方肌': ['斜方肌'],
    '豎脊肌': ['豎脊肌'],
    '股四頭': ['股四頭'],
    '膕繩肌': ['膕繩肌'],
    '臀大肌': ['臀大肌'],
    '臀中肌': ['臀中肌'],
    '小腿': ['小腿'],
    '內收肌': ['內收肌'],
    '外展肌': ['外展肌'],
    '腹直肌': ['腹直肌'],
    '腹斜肌': ['腹斜肌'],
    '腹橫肌': ['腹橫肌'],
}

# 反轉映射：從變體到標準名稱
reverse_mapping = {}
for standard, variants in merge_mapping.items():
    for variant in variants:
        reverse_mapping[variant] = [standard]

print("\n合併規則：")
for original, targets in reverse_mapping.items():
    if len(targets) == 1 and targets[0] != original:
        print(f"  {original:15s} → {targets[0]}")

# 4. 計算合併後的統計
print("\n4. 計算合併後的統計...")
merged_stats = defaultdict(lambda: {'count': 0, 'exercises': set()})

for part, info in bodypart_usage.items():
    if part in reverse_mapping:
        targets = reverse_mapping[part]
        for target in targets:
            merged_stats[target]['count'] += info['count']
            for ex in info['exercises']:
                merged_stats[target]['exercises'].add(ex['id'])
    else:
        # 未在映射中的保持原樣
        merged_stats[part]['count'] = info['count']
        merged_stats[part]['exercises'] = set(ex['id'] for ex in info['exercises'])

print("\n合併後的身體部位統計：")
for part in sorted(merged_stats.keys()):
    info = merged_stats[part]
    unique_exercises = len(info['exercises'])
    print(f"  - {part:15s}: {unique_exercises:3d} 個唯一動作")

# 5. 生成合併計劃
print("\n5. 生成合併計劃...")

merge_plan = {
    'mapping': reverse_mapping,
    'before': {
        'bodyParts_count': len(body_parts_list),
        'unique_parts_in_exercises': len(bodypart_usage)
    },
    'after': {
        'unique_parts': len(merged_stats)
    }
}

# 保存到 JSON 文件
with open('body_parts_merge_plan.json', 'w', encoding='utf-8') as f:
    json.dump(merge_plan, f, ensure_ascii=False, indent=2)

print(f"\n合併計劃已保存到: body_parts_merge_plan.json")

# 6. 總結
print("\n" + "=" * 60)
print("分析總結")
print("=" * 60)
print(f"當前狀態：")
print(f"  - bodyParts 集合: {len(body_parts_list)} 個項目")
print(f"  - exercise 中使用: {len(bodypart_usage)} 個不同部位")
print(f"\n合併後：")
print(f"  - 將減少到: {len(merged_stats)} 個唯一部位")
print(f"  - 減少: {len(bodypart_usage) - len(merged_stats)} 個重複項")

print("\n主要合併項目：")
print(f"  - 手 + 手臂 → 手")
print(f"  - 胸 + 胸部 → 胸")
print(f"  - 肩 + 肩部 → 肩")
print(f"  - 背 + 背部 → 背")
print(f"  - 腿 + 腿部 → 腿")
print(f"  - 肩、背 → 保持原樣（不拆分）")

print("\n下一步：執行 merge_body_parts.py 來應用合併")
print("=" * 60)

