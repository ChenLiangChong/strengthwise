#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
驗證身體部位合併結果
"""

import firebase_admin
from firebase_admin import credentials, firestore

# 初始化 Firebase
cred = credentials.Certificate('strengthwise-service-account.json')
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()

print("=" * 60)
print("驗證身體部位合併結果")
print("=" * 60)

# 檢查 bodyParts 集合
print("\n1. bodyParts 集合:")
parts_ref = db.collection('bodyParts')
parts = list(parts_ref.stream())

print(f"\n總共 {len(parts)} 個身體部位:\n")
for doc in sorted(parts, key=lambda x: x.to_dict().get('name', '')):
    data = doc.to_dict()
    name = data.get('name', '')
    count = data.get('count', 0)
    print(f"  {name:15s} - {count:3d} 個動作")

# 檢查是否還有重複項
print("\n2. 檢查重複項:")
part_names = [doc.to_dict().get('name', '') for doc in parts]
duplicates = ['手臂', '肩部', '背部', '胸部', '腿部']
found_duplicates = [d for d in duplicates if d in part_names]

if found_duplicates:
    print(f"  [警告] 仍存在重複項: {', '.join(found_duplicates)}")
else:
    print(f"  [OK] 沒有發現重複項")

# 檢查 "肩、背" 是否保留
if '肩、背' in part_names:
    print(f"  [OK] '肩、背' 已保留（未拆分）")
else:
    print(f"  [警告] '肩、背' 未找到")

# 抽樣檢查 exercise
print("\n3. 抽樣檢查 exercise (前 5 個):")
exercises_ref = db.collection('exercise')
exercises = list(exercises_ref.limit(5).stream())

for ex in exercises:
    data = ex.to_dict()
    name = data.get('name', 'Unknown')
    bodyParts = data.get('bodyParts', [])
    
    # 檢查是否有舊的部位名稱
    old_parts = [p for p in bodyParts if p in duplicates]
    if old_parts:
        print(f"  [警告] {name}: 仍包含 {old_parts}")
    else:
        print(f"  [OK] {name}: {bodyParts}")

print("\n" + "=" * 60)
print("驗證完成!")
print("=" * 60)

