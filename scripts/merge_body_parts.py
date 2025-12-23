#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
合併和統一 Firestore 中的身體部位分類
根據 analyze_body_parts.py 的分析結果執行合併
"""

import firebase_admin
from firebase_admin import credentials, firestore
from collections import defaultdict
import sys
import time
import argparse

# 初始化 Firebase
cred = credentials.Certificate('strengthwise-service-account.json')
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()

# 解析命令行參數
parser = argparse.ArgumentParser(description='身體部位合併腳本')
parser.add_argument('--yes', '-y', action='store_true', help='自動確認，不提示')
args = parser.parse_args()

print("=" * 60)
print("身體部位合併腳本")
print("=" * 60)

# 定義合併映射
# 格式：原始名稱 -> 標準名稱列表
BODY_PART_MAPPING = {
    '手臂': ['手'],           # 合併到 "手"
    '肩部': ['肩'],           # 合併到 "肩"
    '背部': ['背'],           # 合併到 "背"
    '胸部': ['胸'],           # 合併到 "胸"
    '腿部': ['腿'],           # 合併到 "腿"
    # 注意：'肩、背' 保持原樣，不在映射中
}

# 反轉映射以便查詢
def get_standard_parts(original_part):
    """將原始部位名稱轉換為標準名稱列表"""
    if original_part in BODY_PART_MAPPING:
        return BODY_PART_MAPPING[original_part]
    else:
        return [original_part]  # 保持原樣

# 確認執行
print(f"\n此腳本將執行以下操作：")
print(f"1. 更新 exercise 集合中的 bodyParts 欄位")
print(f"2. 重建 bodyParts 集合，移除重複項")
print(f"\n合併規則：")
for original, standards in BODY_PART_MAPPING.items():
    print(f"  {original:10s} → {', '.join(standards)}")
print(f"  {'肩、背':10s} → 保持原樣（不變更）")

if not args.yes:
    confirm = input("\n確定要執行合併嗎？(yes/no): ")
    if confirm.lower() != 'yes':
        print("操作已取消")
        sys.exit(0)
else:
    print("\n自動確認模式：開始執行合併...")

# ============================================
# 階段 1: 更新 exercise 集合
# ============================================
print("\n" + "=" * 60)
print("階段 1: 更新 exercise 集合")
print("=" * 60)

exercises_ref = db.collection('exercise')
exercises = exercises_ref.stream()

updated_count = 0
unchanged_count = 0
batch_size = 400
current_batch = 0
batch = db.batch()

# 用於統計
all_body_parts_after = set()
exercises_list = []

# 第一遍：收集所有 exercises
print("\n讀取所有 exercise 文檔...")
for ex in exercises:
    exercises_list.append({
        'ref': exercises_ref.document(ex.id),
        'data': ex.to_dict(),
        'id': ex.id
    })

print(f"共找到 {len(exercises_list)} 個 exercise 文檔")

# 第二遍：處理並更新
print("\n開始更新 bodyParts 欄位...")
for ex_info in exercises_list:
    ex_ref = ex_info['ref']
    ex_data = ex_info['data']
    
    original_body_parts = ex_data.get('bodyParts', [])
    
    # 轉換為標準名稱
    new_body_parts = []
    for part in original_body_parts:
        standard_parts = get_standard_parts(part)
        new_body_parts.extend(standard_parts)
    
    # 去重並排序
    new_body_parts = sorted(list(set(new_body_parts)))
    
    # 記錄所有使用的部位
    all_body_parts_after.update(new_body_parts)
    
    # 檢查是否有變化
    if new_body_parts != original_body_parts:
        # 需要更新
        batch.update(ex_ref, {
            'bodyParts': new_body_parts
        })
        current_batch += 1
        updated_count += 1
        
        if len(original_body_parts) > 0:
            print(f"  更新: {ex_data.get('name', 'Unknown')}")
            print(f"    原始: {original_body_parts}")
            print(f"    新的: {new_body_parts}")
        
        # 批量提交
        if current_batch >= batch_size:
            print(f"\n提交批次 (已更新 {updated_count} 個)...")
            batch.commit()
            time.sleep(1)
            current_batch = 0
            batch = db.batch()
    else:
        unchanged_count += 1

# 提交最後一批
if current_batch > 0:
    print(f"\n提交最後一批 ({current_batch} 個)...")
    batch.commit()

print(f"\n階段 1 完成:")
print(f"  - 已更新: {updated_count} 個 exercise")
print(f"  - 未變更: {unchanged_count} 個 exercise")
print(f"  - 總計: {len(exercises_list)} 個 exercise")

# ============================================
# 階段 2: 重建 bodyParts 集合
# ============================================
print("\n" + "=" * 60)
print("階段 2: 重建 bodyParts 集合")
print("=" * 60)

# 2.1 清空現有的 bodyParts 集合
print("\n清空現有的 bodyParts 集合...")
body_parts_ref = db.collection('bodyParts')
old_docs = body_parts_ref.stream()
deleted_count = 0

for doc in old_docs:
    doc.reference.delete()
    deleted_count += 1

print(f"已刪除 {deleted_count} 個舊記錄")

# 2.2 統計每個標準部位的使用次數
print("\n統計每個部位的使用情況...")
body_part_counts = defaultdict(set)

for ex_info in exercises_list:
    ex_data = ex_info['data']
    body_parts = ex_data.get('bodyParts', [])
    
    # 轉換為標準名稱
    for part in body_parts:
        standard_parts = get_standard_parts(part)
        for std_part in standard_parts:
            body_part_counts[std_part].add(ex_info['id'])

print(f"\n找到 {len(body_part_counts)} 個唯一的標準身體部位")

# 2.3 創建新的 bodyParts 集合
print("\n創建新的 bodyParts 集合...")
batch = db.batch()
created_count = 0

for part_name in sorted(body_part_counts.keys()):
    unique_exercise_count = len(body_part_counts[part_name])
    
    doc_ref = body_parts_ref.document()
    batch.set(doc_ref, {
        'name': part_name,
        'count': unique_exercise_count,
        'description': ''
    })
    created_count += 1
    print(f"  - {part_name:15s}: {unique_exercise_count:3d} 個動作")

batch.commit()
print(f"\n已創建 {created_count} 個新的 bodyParts 記錄")

# ============================================
# 階段 3: 驗證結果
# ============================================
print("\n" + "=" * 60)
print("階段 3: 驗證結果")
print("=" * 60)

# 驗證 exercise 集合
print("\n驗證 exercise 集合...")
exercises = db.collection('exercise').limit(10).stream()
sample_count = 0
for ex in exercises:
    data = ex.to_dict()
    body_parts = data.get('bodyParts', [])
    
    # 檢查是否還有需要合併的項目
    needs_merge = any(part in BODY_PART_MAPPING for part in body_parts)
    
    if needs_merge:
        print(f"  ⚠️ 警告: {data.get('name')} 仍包含需要合併的部位: {body_parts}")
    
    sample_count += 1

if sample_count == 10:
    print(f"  ✓ 抽樣檢查 10 個 exercise，格式正確")

# 驗證 bodyParts 集合
print("\n驗證 bodyParts 集合...")
body_parts = db.collection('bodyParts').stream()
final_parts = []
for doc in body_parts:
    data = doc.to_dict()
    final_parts.append(data['name'])

print(f"  ✓ bodyParts 集合包含 {len(final_parts)} 個部位")
print(f"\n最終的身體部位列表：")
for part in sorted(final_parts):
    print(f"  - {part}")

# ============================================
# 完成
# ============================================
print("\n" + "=" * 60)
print("合併完成！")
print("=" * 60)
print(f"\n統計：")
print(f"  - 更新了 {updated_count} 個 exercise 文檔")
print(f"  - 刪除了 {deleted_count} 個舊的 bodyParts 記錄")
print(f"  - 創建了 {created_count} 個新的 bodyParts 記錄")
print(f"\n主要改變：")
print(f"  - 手臂 → 手")
print(f"  - 肩部 → 肩")
print(f"  - 背部 → 背")
print(f"  - 胸部 → 胸")
print(f"  - 腿部 → 腿")
print(f"  - 肩、背 → 保持原樣（不拆分）")

print(f"\n⚠️ 重要：請在應用中清除快取，確保使用新的資料！")
print(f"   在應用的設定頁面或重新安裝應用")
print("=" * 60)

