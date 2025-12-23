#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
健身動作重新分類工具
作為專業健身教練，重新設計分類結構：
訓練類型 -> 身體部位 -> 特定肌群 -> 器材類型 -> 動作本身
"""

import firebase_admin
from firebase_admin import credentials, firestore
import json
import re

# 初始化 Firebase
cred = credentials.Certificate('strengthwise-service-account.json')
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()

print("=" * 80)
print("健身動作重新分類工具（專業健身教練模式）")
print("=" * 80)

# ============================================
# 分類結構定義
# ============================================

# 身體部位 -> 特定肌群映射
MUSCLE_GROUPS = {
    '胸': {
        '上胸': ['上胸', '斜上推', '上斜', '上傾'],
        '中胸': ['中胸', '平板', '水平'],
        '下胸': ['下胸', '下斜', '下傾'],
        '整體胸肌': []  # 默認
    },
    '背': {
        '闊背肌': ['闊背', '引體', '下拉', '划船'],
        '斜方肌': ['斜方', '聳肩', '提拉'],
        '豎脊肌': ['豎脊', '硬舉', '羅馬尼亞'],
        '中背': ['中背', '划船'],
        '下背': ['下背', '背伸展'],
        '整體背肌': []
    },
    '肩': {
        '前三角': ['前三角', '前舉', '前平舉'],
        '中三角': ['中三角', '側舉', '側平舉'],
        '後三角': ['後三角', '反向飛鳥', '俯身側平舉'],
        '整體三角肌': ['推舉', '肩推']
    },
    '手': {
        '二頭肌': ['二頭', '彎舉', '捲曲'],
        '三頭肌': ['三頭', '下壓', '伸展', '臂屈伸'],
        '前臂': ['前臂', '腕', '握力'],
        '整體手臂': []
    },
    '腿': {
        '股四頭': ['股四頭', '腿推', '深蹲', '蹲舉', '腿伸展', '股四頭肌'],
        '膕繩肌': ['膕繩', '腿彎舉', '腿屈曲', '膕繩肌'],
        '小腿': ['小腿', '提踵', '腓腸肌', '比目魚肌'],
        '內收肌': ['內收', '內側'],
        '整體腿部': []
    },
    '臀': {
        '臀大肌': ['臀大肌', '臀推', '臀橋', '踢腿'],
        '臀中肌': ['臀中肌', '外展', '蚌式'],
        '整體臀部': []
    },
    '核心': {
        '腹直肌': ['腹直肌', '捲腹', '仰臥起坐'],
        '腹斜肌': ['腹斜肌', '側彎', '旋轉', '俄羅斯轉體'],
        '腹橫肌': ['腹橫肌', '平板支撐', '抗旋轉'],
        '整體核心': ['核心']
    },
    '全身': {
        '綜合訓練': []
    }
}

# 器材類型標準化
EQUIPMENT_CATEGORIES = {
    '自由重量': {
        '啞鈴': ['啞鈴'],
        '槓鈴': ['槓鈴', '六角槓', '安全槓'],
        '壺鈴': ['壺鈴'],
    },
    '機械式': {
        '固定器械': ['機械式', '機器', '史密斯'],
        'Cable滑輪': ['Cable', '滑輪', '繩索'],
    },
    '徒手': {
        '自身體重': ['徒手'],
        '輔助器材': ['單槓', '雙槓', '吊環', '彈力繩', '彈力帶'],
    },
    '功能性訓練': {
        '不穩定訓練': ['健身球', '瑞士球', 'BOSU球'],
        '戰繩': ['戰繩'],
        '滑行訓練': ['滑行盤', '滑輪'],
    }
}

# 訓練類型標準化
TRAINING_TYPES = {
    '重訓': ['重訓', '重量訓練', '力量訓練'],
    '有氧': ['有氧', '心肺訓練'],
    '伸展': ['伸展', '柔軟度訓練'],
    '功能性訓練': ['功能性', 'TRX', '戰繩'],
}

# ============================================
# 智能分類函數
# ============================================

def classify_training_type(exercise_data):
    """根據動作名稱判斷訓練類型"""
    name = exercise_data.get('name', '').lower()
    current_type = exercise_data.get('type', '')
    
    # 如果已有正確分類就保留
    for standard_type in TRAINING_TYPES.keys():
        if current_type == standard_type:
            return standard_type
    
    # 根據關鍵字判斷
    if 'trx' in name or '戰繩' in name or '功能性' in name:
        return '功能性訓練'
    elif '伸展' in name or '拉伸' in name:
        return '伸展'
    elif '跑' in name or '跳' in name or '有氧' in name:
        return '有氧'
    else:
        return '重訓'  # 默認

def identify_specific_muscle(exercise_data):
    """識別特定肌群"""
    name = exercise_data.get('name', '')
    bodyParts = exercise_data.get('bodyParts', [])
    
    if not bodyParts:
        return None, None
    
    primary_body_part = bodyParts[0]
    
    if primary_body_part not in MUSCLE_GROUPS:
        return primary_body_part, '整體'
    
    # 根據動作名稱匹配特定肌群
    muscle_groups = MUSCLE_GROUPS[primary_body_part]
    
    for specific_muscle, keywords in muscle_groups.items():
        for keyword in keywords:
            if keyword in name:
                return primary_body_part, specific_muscle
    
    # 默認返回整體
    default_muscle = next((k for k in muscle_groups.keys() if '整體' in k), None)
    return primary_body_part, default_muscle or list(muscle_groups.keys())[0]

def categorize_equipment(equipment_str):
    """將器材歸類到標準分類"""
    if not equipment_str or equipment_str.strip() == '':
        return '徒手', '自身體重'
    
    equipment_lower = equipment_str.lower()
    
    for category, subcategories in EQUIPMENT_CATEGORIES.items():
        for subcategory, keywords in subcategories.items():
            for keyword in keywords:
                if keyword.lower() in equipment_lower:
                    return category, subcategory
    
    # 未分類的器材
    return '其他器材', equipment_str

# ============================================
# 載入並重新分類所有動作
# ============================================

print("\n階段 1: 載入所有動作...")
exercises_ref = db.collection('exercise')
exercises = list(exercises_ref.stream())
print(f"共載入 {len(exercises)} 個動作")

reclassified_exercises = []
stats = {
    'total': len(exercises),
    'updated': 0,
    'missing_body_part': [],
    'missing_equipment': [],
}

print("\n階段 2: 重新分類...")
for ex in exercises:
    data = ex.to_dict()
    exercise_id = ex.id
    
    # 原始資料
    original_type = data.get('type', '')
    original_bodyParts = data.get('bodyParts', [])
    original_equipment = data.get('equipment', '')
    
    # 重新分類
    new_classification = {
        'id': exercise_id,
        'name': data.get('name', ''),
        
        # Level 1: 訓練類型
        'trainingType': classify_training_type(data),
        
        # Level 2: 身體部位（主要肌群）
        'bodyPart': original_bodyParts[0] if original_bodyParts else '',
        
        # Level 3: 特定肌群
        'specificMuscle': None,
        
        # Level 4: 器材類型
        'equipmentCategory': None,
        'equipmentSubcategory': None,
        
        # 原始資料保留
        'original': {
            'type': original_type,
            'bodyParts': original_bodyParts,
            'equipment': original_equipment,
        }
    }
    
    # 識別特定肌群
    body_part, specific_muscle = identify_specific_muscle(data)
    if body_part:
        new_classification['bodyPart'] = body_part
        new_classification['specificMuscle'] = specific_muscle
    else:
        stats['missing_body_part'].append(data.get('name', ''))
    
    # 器材分類
    eq_category, eq_subcategory = categorize_equipment(original_equipment)
    new_classification['equipmentCategory'] = eq_category
    new_classification['equipmentSubcategory'] = eq_subcategory
    
    if not original_equipment or original_equipment.strip() == '':
        stats['missing_equipment'].append(data.get('name', ''))
    
    reclassified_exercises.append(new_classification)

print(f"重新分類完成！")

# ============================================
# 統計分析
# ============================================

print("\n" + "=" * 80)
print("重新分類統計")
print("=" * 80)

# 訓練類型分布
from collections import Counter
training_type_dist = Counter(ex['trainingType'] for ex in reclassified_exercises)
print("\n訓練類型分布:")
for tt, count in sorted(training_type_dist.items(), key=lambda x: -x[1]):
    percentage = (count / len(reclassified_exercises)) * 100
    print(f"  {tt:15s}: {count:4d} 個動作 ({percentage:5.1f}%)")

# 身體部位分布
bodypart_dist = Counter(ex['bodyPart'] for ex in reclassified_exercises if ex['bodyPart'])
print("\n身體部位分布:")
for bp, count in sorted(bodypart_dist.items(), key=lambda x: -x[1]):
    percentage = (count / len(reclassified_exercises)) * 100
    print(f"  {bp:15s}: {count:4d} 個動作 ({percentage:5.1f}%)")

# 器材類別分布
equipment_cat_dist = Counter(ex['equipmentCategory'] for ex in reclassified_exercises)
print("\n器材類別分布:")
for eq, count in sorted(equipment_cat_dist.items(), key=lambda x: -x[1]):
    percentage = (count / len(reclassified_exercises)) * 100
    print(f"  {eq:20s}: {count:4d} 個動作 ({percentage:5.1f}%)")

# 特定肌群範例
print("\n特定肌群範例（胸）:")
chest_exercises = [ex for ex in reclassified_exercises if ex['bodyPart'] == '胸']
chest_muscle_dist = Counter(ex['specificMuscle'] for ex in chest_exercises if ex['specificMuscle'])
for muscle, count in sorted(chest_muscle_dist.items(), key=lambda x: -x[1]):
    print(f"  {muscle:15s}: {count:3d} 個動作")

print("\n特定肌群範例（背）:")
back_exercises = [ex for ex in reclassified_exercises if ex['bodyPart'] == '背']
back_muscle_dist = Counter(ex['specificMuscle'] for ex in back_exercises if ex['specificMuscle'])
for muscle, count in sorted(back_muscle_dist.items(), key=lambda x: -x[1]):
    print(f"  {muscle:15s}: {count:3d} 個動作")

# 問題檢測
print("\n" + "=" * 80)
print("問題檢測")
print("=" * 80)

if stats['missing_body_part']:
    print(f"\n[警告] 發現 {len(stats['missing_body_part'])} 個動作缺少身體部位:")
    for name in stats['missing_body_part'][:10]:
        print(f"  - {name}")
    if len(stats['missing_body_part']) > 10:
        print(f"  ... 還有 {len(stats['missing_body_part']) - 10} 個")

if stats['missing_equipment']:
    print(f"\n[提示] 發現 {len(stats['missing_equipment'])} 個動作缺少器材標註:")
    for name in stats['missing_equipment'][:10]:
        print(f"  - {name}")
    if len(stats['missing_equipment']) > 10:
        print(f"  ... 還有 {len(stats['missing_equipment']) - 10} 個")

# ============================================
# 保存結果
# ============================================

# 保存到 JSON
output_file = 'exercises_reclassified.json'
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(reclassified_exercises, f, ensure_ascii=False, indent=2)
print(f"\n[OK] 重新分類結果已保存到: {output_file}")

# 生成 CSV
import csv
csv_file = 'exercises_reclassified.csv'
if reclassified_exercises:
    with open(csv_file, 'w', encoding='utf-8-sig', newline='') as f:
        fieldnames = ['id', 'name', 'trainingType', 'bodyPart', 'specificMuscle', 
                     'equipmentCategory', 'equipmentSubcategory']
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(reclassified_exercises)
    print(f"[OK] 已保存 CSV 到: {csv_file}")

# ============================================
# 詢問是否更新到 Firestore
# ============================================

print("\n" + "=" * 80)
print("更新到 Firestore")
print("=" * 80)

print("\n建議的新欄位結構:")
print("  - trainingType: 訓練類型（重訓/有氧/伸展/功能性訓練）")
print("  - bodyPart: 身體部位（主要肌群）")
print("  - specificMuscle: 特定肌群（例如：上胸、闊背肌）")
print("  - equipmentCategory: 器材類別（自由重量/機械式/徒手/功能性訓練）")
print("  - equipmentSubcategory: 器材子類別（啞鈴/槓鈴/固定器械等）")

print("\n[提示] 更新腳本已準備好，執行 update_exercise_classification.py 來更新 Firestore")

print("\n" + "=" * 80)
print("重新分類完成！")
print("=" * 80)
print(f"\n生成的文件:")
print(f"  1. {output_file} - 完整分類結果（JSON）")
print(f"  2. {csv_file} - Excel 可讀格式")
print(f"\n下一步:")
print(f"  1. 在 Excel 中查看 {csv_file}")
print(f"  2. 檢查分類是否合理")
print(f"  3. 執行 update_exercise_classification.py 更新到 Firestore")
print("=" * 80)

