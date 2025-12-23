#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
更新動作分類到 Firestore
將重新分類的結果更新到資料庫
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json
import sys
import time
import argparse

# 初始化 Firebase
cred = credentials.Certificate('strengthwise-service-account.json')
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()

# 解析參數
parser = argparse.ArgumentParser(description='更新動作分類到 Firestore')
parser.add_argument('--yes', '-y', action='store_true', help='自動確認，不提示')
parser.add_argument('--dry-run', action='store_true', help='模擬運行，不實際更新')
args = parser.parse_args()

print("=" * 80)
print("更新動作分類到 Firestore")
print("=" * 80)

# 載入重新分類的數據
try:
    with open('exercises_reclassified.json', 'r', encoding='utf-8') as f:
        reclassified_exercises = json.load(f)
    print(f"\n[OK] 載入 {len(reclassified_exercises)} 個重新分類的動作")
except FileNotFoundError:
    print("\n[錯誤] 找不到 exercises_reclassified.json")
    print("請先執行 reclassify_exercises.py")
    sys.exit(1)

# 顯示更新計劃
print("\n將為每個動作添加以下新欄位:")
print("  - trainingType: 訓練類型")
print("  - bodyPart: 身體部位（主要肌群）")
print("  - specificMuscle: 特定肌群")
print("  - equipmentCategory: 器材類別")
print("  - equipmentSubcategory: 器材子類別")

if args.dry_run:
    print("\n[模擬模式] 將顯示更新但不實際執行")

# 確認
if not args.yes and not args.dry_run:
    confirm = input(f"\n確定要更新 {len(reclassified_exercises)} 個動作到 Firestore 嗎？(yes/no): ")
    if confirm.lower() != 'yes':
        print("操作已取消")
        sys.exit(0)
else:
    print("\n[自動確認] 開始更新...")

# 更新到 Firestore
print("\n開始更新...")
updated_count = 0
error_count = 0
batch_size = 400
current_batch = 0
batch = db.batch()

for ex in reclassified_exercises:
    exercise_id = ex['id']
    
    # 準備更新數據
    update_data = {
        'trainingType': ex['trainingType'],
        'bodyPart': ex['bodyPart'],
        'specificMuscle': ex['specificMuscle'],
        'equipmentCategory': ex['equipmentCategory'],
        'equipmentSubcategory': ex['equipmentSubcategory'],
    }
    
    if args.dry_run:
        # 模擬模式：只顯示前 5 個
        if updated_count < 5:
            print(f"  [模擬] 更新 {ex['name']}")
            print(f"    訓練類型: {update_data['trainingType']}")
            print(f"    身體部位: {update_data['bodyPart']}")
            print(f"    特定肌群: {update_data['specificMuscle']}")
            print(f"    器材類別: {update_data['equipmentCategory']} / {update_data['equipmentSubcategory']}")
        updated_count += 1
    else:
        try:
            doc_ref = db.collection('exercise').document(exercise_id)
            batch.update(doc_ref, update_data)
            current_batch += 1
            updated_count += 1
            
            # 批次提交
            if current_batch >= batch_size:
                batch.commit()
                print(f"  已更新 {updated_count} / {len(reclassified_exercises)} 個動作...")
                time.sleep(1)
                current_batch = 0
                batch = db.batch()
                
        except Exception as e:
            print(f"  [錯誤] 更新 {ex['name']} 失敗: {e}")
            error_count += 1

# 提交最後一批
if current_batch > 0 and not args.dry_run:
    batch.commit()
    print(f"  已更新 {updated_count} / {len(reclassified_exercises)} 個動作...")

# 完成
print("\n" + "=" * 80)
if args.dry_run:
    print("模擬運行完成！")
    print(f"  - 將更新 {updated_count} 個動作")
else:
    print("更新完成！")
    print(f"  - 成功更新: {updated_count} 個動作")
    if error_count > 0:
        print(f"  - 失敗: {error_count} 個動作")

print("\n建議的新 UI 流程:")
print("  1. 選擇訓練類型（重訓/有氧/伸展/功能性訓練）")
print("  2. 選擇身體部位（胸/背/肩/腿/手/核心/全身/臀）")
print("  3. 選擇特定肌群（例如：胸 → 上胸/中胸/下胸）")
print("  4. 選擇器材類型（自由重量/機械式/徒手/功能性訓練）")
print("  5. 顯示動作列表")

print("\n[重要] 更新後請清除應用快取:")
print("  flutter clean")
print("  flutter run")

print("=" * 80)

