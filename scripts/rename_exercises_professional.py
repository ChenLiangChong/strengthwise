#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StrengthWise - 專業健身動作命名系統重塑
根據生物力學、解剖學與器材工程學的標準化命名
"""

import json
import os
import sys
from typing import Dict, List, Tuple
from datetime import datetime

# 設定輸出編碼為 UTF-8
sys.stdout.reconfigure(encoding='utf-8')

# ============================================================================
# 第一層：訓練類型優化對照表
# ============================================================================
TRAINING_TYPE_MAPPING = {
    '重訓': {
        'zh': '阻力訓練',
        'en': 'Resistance Training',
        'category': 'strength'
    },
    '有氧': {
        'zh': '心肺適能訓練',
        'en': 'Cardiovascular Training',
        'category': 'cardio'
    },
    '伸展': {
        'zh': '活動度與伸展',
        'en': 'Mobility & Flexibility',
        'category': 'flexibility'
    },
    '瑜伽': {
        'zh': '瑜伽',
        'en': 'Yoga',
        'category': 'flexibility'
    },
}

# ============================================================================
# 第二層：身體部位優化對照表（解剖學精細化）
# ============================================================================
BODY_PART_MAPPING = {
    '胸': {
        'zh': '胸部',
        'en': 'Chest',
        'scientific': 'Pectoral Region',
        'muscle_groups': ['胸大肌', '胸小肌']
    },
    '背': {
        'zh': '背部',
        'en': 'Back',
        'scientific': 'Dorsal Region',
        'muscle_groups': ['背闊肌', '斜方肌', '菱形肌', '豎脊肌']
    },
    '肩': {
        'zh': '肩部',
        'en': 'Shoulders',
        'scientific': 'Deltoid Complex',
        'muscle_groups': ['三角肌前束', '三角肌中束', '三角肌後束']
    },
    '腿': {
        'zh': '腿部',
        'en': 'Legs',
        'scientific': 'Lower Extremity',
        'muscle_groups': ['股四頭肌', '膕旁肌', '內收肌群']
    },
    '臀': {
        'zh': '臀部',
        'en': 'Glutes',
        'scientific': 'Gluteal Region',
        'muscle_groups': ['臀大肌', '臀中肌', '臀小肌']
    },
    '二頭': {
        'zh': '肱二頭肌',
        'en': 'Biceps',
        'scientific': 'Biceps Brachii',
        'muscle_groups': ['肱二頭肌', '肱肌']
    },
    '三頭': {
        'zh': '肱三頭肌',
        'en': 'Triceps',
        'scientific': 'Triceps Brachii',
        'muscle_groups': ['肱三頭肌長頭', '肱三頭肌外側頭', '肱三頭肌內側頭']
    },
    '核心': {
        'zh': '核心',
        'en': 'Core',
        'scientific': 'Core Musculature',
        'muscle_groups': ['腹直肌', '腹外斜肌', '腹內斜肌', '腹橫肌']
    },
    '小腿': {
        'zh': '小腿',
        'en': 'Calves',
        'scientific': 'Lower Leg',
        'muscle_groups': ['腓腸肌', '比目魚肌']
    },
    '前臂': {
        'zh': '前臂',
        'en': 'Forearms',
        'scientific': 'Antebrachium',
        'muscle_groups': ['前臂屈肌群', '前臂伸肌群']
    },
    '全身': {
        'zh': '全身',
        'en': 'Full Body',
        'scientific': 'Total Body',
        'muscle_groups': ['綜合訓練']
    },
}

# ============================================================================
# 第三層：特定肌群優化對照表（精確到肌肉束）
# ============================================================================
SPECIFIC_MUSCLE_MAPPING = {
    # 胸部細分
    '上胸': {'zh': '胸大肌-鎖骨頭', 'en': 'Upper Chest (Clavicular Head)', 'scientific': 'Pectoralis Major, Clavicular Head'},
    '中胸': {'zh': '胸大肌-胸肋頭', 'en': 'Middle Chest (Sternocostal Head)', 'scientific': 'Pectoralis Major, Sternocostal Head'},
    '下胸': {'zh': '胸大肌-腹部頭', 'en': 'Lower Chest (Abdominal Head)', 'scientific': 'Pectoralis Major, Abdominal Head'},
    '胸肌': {'zh': '胸大肌', 'en': 'Pectoralis Major', 'scientific': 'Pectoralis Major'},
    
    # 背部細分
    '闊背肌': {'zh': '背闊肌', 'en': 'Latissimus Dorsi', 'scientific': 'Latissimus Dorsi'},
    '中背': {'zh': '斜方肌中部', 'en': 'Middle Trapezius', 'scientific': 'Trapezius, Middle Fibers'},
    '下背': {'zh': '下背/豎脊肌', 'en': 'Lower Back / Erector Spinae', 'scientific': 'Erector Spinae'},
    '上背': {'zh': '斜方肌上部', 'en': 'Upper Trapezius', 'scientific': 'Trapezius, Upper Fibers'},
    '斜方肌': {'zh': '斜方肌', 'en': 'Trapezius', 'scientific': 'Trapezius'},
    
    # 肩部細分
    '前三角': {'zh': '三角肌前束', 'en': 'Anterior Deltoid', 'scientific': 'Deltoid, Anterior Fibers'},
    '中三角': {'zh': '三角肌中束', 'en': 'Lateral Deltoid', 'scientific': 'Deltoid, Lateral Fibers'},
    '後三角': {'zh': '三角肌後束', 'en': 'Posterior Deltoid', 'scientific': 'Deltoid, Posterior Fibers'},
    '三角肌': {'zh': '三角肌', 'en': 'Deltoids', 'scientific': 'Deltoid'},
    
    # 腿部細分
    '股四頭': {'zh': '股四頭肌', 'en': 'Quadriceps', 'scientific': 'Quadriceps Femoris'},
    '股直肌': {'zh': '股直肌', 'en': 'Rectus Femoris', 'scientific': 'Rectus Femoris'},
    '股內側肌': {'zh': '股內側肌', 'en': 'Vastus Medialis', 'scientific': 'Vastus Medialis'},
    '股外側肌': {'zh': '股外側肌', 'en': 'Vastus Lateralis', 'scientific': 'Vastus Lateralis'},
    '腿後': {'zh': '膕旁肌群', 'en': 'Hamstrings', 'scientific': 'Hamstrings Complex'},
    '股二頭肌': {'zh': '股二頭肌', 'en': 'Biceps Femoris', 'scientific': 'Biceps Femoris'},
    '內收肌': {'zh': '內收肌群', 'en': 'Adductors', 'scientific': 'Hip Adductors'},
    
    # 臀部細分
    '臀大肌': {'zh': '臀大肌', 'en': 'Gluteus Maximus', 'scientific': 'Gluteus Maximus'},
    '臀中肌': {'zh': '臀中肌', 'en': 'Gluteus Medius', 'scientific': 'Gluteus Medius'},
    
    # 手臂細分
    '二頭': {'zh': '肱二頭肌', 'en': 'Biceps Brachii', 'scientific': 'Biceps Brachii'},
    '三頭': {'zh': '肱三頭肌', 'en': 'Triceps Brachii', 'scientific': 'Triceps Brachii'},
    '三頭長頭': {'zh': '肱三頭肌長頭', 'en': 'Triceps Long Head', 'scientific': 'Triceps Brachii, Long Head'},
    '前臂': {'zh': '前臂肌群', 'en': 'Forearm Muscles', 'scientific': 'Forearm Musculature'},
    
    # 核心細分
    '腹肌': {'zh': '腹直肌', 'en': 'Rectus Abdominis', 'scientific': 'Rectus Abdominis'},
    '腹外斜': {'zh': '腹外斜肌', 'en': 'External Obliques', 'scientific': 'External Obliques'},
    '腹內斜': {'zh': '腹內斜肌', 'en': 'Internal Obliques', 'scientific': 'Internal Obliques'},
    
    # 其他
    '小腿': {'zh': '腓腸肌', 'en': 'Gastrocnemius', 'scientific': 'Gastrocnemius'},
    '綜合訓練': {'zh': '全身綜合', 'en': 'Total Body', 'scientific': 'Total Body Training'},
}

# ============================================================================
# 第四層：器材類別優化對照表（工程學定義）
# ============================================================================
EQUIPMENT_CATEGORY_MAPPING = {
    '自由重量': {
        'zh': '自由重量',
        'en': 'Free Weights',
        'technical': 'Unrestricted Load Path'
    },
    '機械式': {
        'zh': '固定式機械',
        'en': 'Fixed Machines',
        'technical': 'Guided Trajectory Equipment'
    },
    '徒手': {
        'zh': '徒手訓練',
        'en': 'Bodyweight Training',
        'technical': 'Calisthenics'
    },
    '功能性訓練': {
        'zh': '功能性訓練',
        'en': 'Functional Training',
        'technical': 'Multi-Planar Movement'
    },
}

# ============================================================================
# 第五層：器材子類別優化對照表
# ============================================================================
EQUIPMENT_SUBCATEGORY_MAPPING = {
    # 自由重量
    '啞鈴': {'zh': '啞鈴', 'en': 'Dumbbell', 'category': '自由重量'},
    '槓鈴': {'zh': '槓鈴', 'en': 'Barbell', 'category': '自由重量'},
    '壺鈴': {'zh': '壺鈴', 'en': 'Kettlebell', 'category': '自由重量'},
    'EZ槓': {'zh': 'EZ槓', 'en': 'EZ Bar', 'category': '自由重量'},
    
    # 機械式細分
    'Cable滑輪': {'zh': '繩索滑輪系統', 'en': 'Cable Pulley System', 'category': '機械式'},
    '插銷式': {'zh': '插銷式器材', 'en': 'Selectorized Machine', 'category': '機械式'},
    '掛片式': {'zh': '掛片式器材', 'en': 'Plate-Loaded Machine', 'category': '機械式'},
    '史密斯': {'zh': '史密斯機', 'en': 'Smith Machine', 'category': '機械式'},
    '固定器材': {'zh': '固定軌跡器材', 'en': 'Fixed Path Machine', 'category': '機械式'},
    
    # 徒手
    '自身體重': {'zh': '自身體重', 'en': 'Bodyweight', 'category': '徒手'},
    
    # 功能性訓練
    '彈力繩': {'zh': '彈力帶/阻力帶', 'en': 'Resistance Band', 'category': '功能性訓練'},
    'TRX': {'zh': 'TRX懸吊訓練', 'en': 'TRX Suspension', 'category': '功能性訓練'},
    '戰繩': {'zh': '戰繩', 'en': 'Battle Rope', 'category': '功能性訓練'},
    '藥球': {'zh': '藥球', 'en': 'Medicine Ball', 'category': '功能性訓練'},
    '健身球': {'zh': '瑜伽球/穩定球', 'en': 'Stability Ball', 'category': '功能性訓練'},
}

# ============================================================================
# 動作命名語法規則
# ============================================================================
def generate_exercise_name(
    specification: str,  # 規格（角度、握法、姿勢）
    equipment: str,      # 器材
    action: str          # 動作模式
) -> Dict[str, str]:
    """
    生成標準化動作名稱
    語法: [規格] + [器材] + [動作]
    
    範例:
    - 上斜 + 啞鈴 + 臥推
    - 寬握 + 滑輪 + 下拉
    """
    # 中文名稱
    name_zh = f"{specification}{equipment}{action}" if specification else f"{equipment}{action}"
    
    # 英文名稱（待翻譯）
    # 這裡先保留原有英文，後續統一翻譯
    name_en = ""
    
    return {
        'name_zh': name_zh,
        'name_en': name_en
    }

# ============================================================================
# 主要處理函數
# ============================================================================

def load_exercises(filepath: str) -> List[Dict]:
    """載入動作資料"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)

def analyze_current_data(exercises: List[Dict]) -> Dict:
    """分析現有資料結構"""
    stats = {
        'total': len(exercises),
        'training_types': {},
        'body_parts': {},
        'specific_muscles': {},
        'equipment_categories': {},
        'equipment_subcategories': {},
        'joint_types': {},
    }
    
    for ex in exercises:
        # 統計各層級分布
        tt = ex.get('training_type', '')
        if tt:
            stats['training_types'][tt] = stats['training_types'].get(tt, 0) + 1
            
        bp = ex.get('body_part', '')
        if bp:
            stats['body_parts'][bp] = stats['body_parts'].get(bp, 0) + 1
            
        sm = ex.get('specific_muscle', '')
        if sm:
            stats['specific_muscles'][sm] = stats['specific_muscles'].get(sm, 0) + 1
            
        ec = ex.get('equipment_category', '')
        if ec:
            stats['equipment_categories'][ec] = stats['equipment_categories'].get(ec, 0) + 1
            
        es = ex.get('equipment_subcategory', '')
        if es:
            stats['equipment_subcategories'][es] = stats['equipment_subcategories'].get(es, 0) + 1
            
        jt = ex.get('joint_type', '')
        if jt:
            stats['joint_types'][jt] = stats['joint_types'].get(jt, 0) + 1
    
    return stats

def optimize_exercise(exercise: Dict) -> Dict:
    """優化單個動作的命名"""
    optimized = exercise.copy()
    
    # 第一層：訓練類型優化
    old_training_type = exercise.get('training_type', '')
    if old_training_type in TRAINING_TYPE_MAPPING:
        mapping = TRAINING_TYPE_MAPPING[old_training_type]
        optimized['training_type_optimized'] = mapping['zh']
        optimized['training_type_en'] = mapping['en']
    
    # 第二層：身體部位優化
    old_body_part = exercise.get('body_part', '')
    if old_body_part in BODY_PART_MAPPING:
        mapping = BODY_PART_MAPPING[old_body_part]
        optimized['body_part_optimized'] = mapping['zh']
        optimized['body_part_en'] = mapping['en']
        optimized['body_part_scientific'] = mapping['scientific']
    
    # 第三層：特定肌群優化
    old_specific_muscle = exercise.get('specific_muscle', '')
    if old_specific_muscle in SPECIFIC_MUSCLE_MAPPING:
        mapping = SPECIFIC_MUSCLE_MAPPING[old_specific_muscle]
        optimized['specific_muscle_optimized'] = mapping['zh']
        optimized['specific_muscle_en'] = mapping['en']
        optimized['specific_muscle_scientific'] = mapping['scientific']
    
    # 第四層：器材類別優化
    old_eq_category = exercise.get('equipment_category', '')
    if old_eq_category in EQUIPMENT_CATEGORY_MAPPING:
        mapping = EQUIPMENT_CATEGORY_MAPPING[old_eq_category]
        optimized['equipment_category_optimized'] = mapping['zh']
        optimized['equipment_category_en'] = mapping['en']
    
    # 第五層：器材子類別優化
    old_eq_subcategory = exercise.get('equipment_subcategory', '')
    if old_eq_subcategory in EQUIPMENT_SUBCATEGORY_MAPPING:
        mapping = EQUIPMENT_SUBCATEGORY_MAPPING[old_eq_subcategory]
        optimized['equipment_subcategory_optimized'] = mapping['zh']
        optimized['equipment_subcategory_en'] = mapping['en']
    
    return optimized

def generate_report(original_exercises: List[Dict], optimized_exercises: List[Dict], stats: Dict) -> str:
    """生成優化報告"""
    report = []
    report.append("# StrengthWise - 健身動作資料庫命名標準化報告")
    report.append("")
    report.append("> 基於生物力學、解剖學與器材工程學的深度優化")
    report.append("")
    report.append(f"**報告生成時間**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append(f"**總動作數**: {stats['total']}")
    report.append("")
    report.append("---")
    report.append("")
    
    # 第一層統計
    report.append("## 📊 第一層：訓練類型優化統計")
    report.append("")
    report.append("| 原始名稱 | 優化中文 | 優化英文 | 動作數量 |")
    report.append("|---------|---------|---------|---------|")
    for old_name, count in sorted(stats['training_types'].items(), key=lambda x: x[1], reverse=True):
        if old_name in TRAINING_TYPE_MAPPING:
            mapping = TRAINING_TYPE_MAPPING[old_name]
            report.append(f"| {old_name} | {mapping['zh']} | {mapping['en']} | {count} |")
    report.append("")
    
    # 第二層統計
    report.append("## 📊 第二層：身體部位優化統計（Top 15）")
    report.append("")
    report.append("| 原始名稱 | 優化中文 | 優化英文 | 解剖學名稱 | 動作數量 |")
    report.append("|---------|---------|---------|-----------|---------|")
    sorted_body_parts = sorted(stats['body_parts'].items(), key=lambda x: x[1], reverse=True)[:15]
    for old_name, count in sorted_body_parts:
        if old_name in BODY_PART_MAPPING:
            mapping = BODY_PART_MAPPING[old_name]
            report.append(f"| {old_name} | {mapping['zh']} | {mapping['en']} | {mapping['scientific']} | {count} |")
    report.append("")
    
    # 第三層統計
    report.append("## 📊 第三層：特定肌群優化統計（Top 20）")
    report.append("")
    report.append("| 原始名稱 | 優化中文 | 優化英文 | 解剖學名稱 | 動作數量 |")
    report.append("|---------|---------|---------|-----------|---------|")
    sorted_muscles = sorted(stats['specific_muscles'].items(), key=lambda x: x[1], reverse=True)[:20]
    for old_name, count in sorted_muscles:
        if old_name in SPECIFIC_MUSCLE_MAPPING:
            mapping = SPECIFIC_MUSCLE_MAPPING[old_name]
            report.append(f"| {old_name} | {mapping['zh']} | {mapping['en']} | {mapping['scientific']} | {count} |")
    report.append("")
    
    # 第四層統計
    report.append("## 📊 第四層：器材類別優化統計")
    report.append("")
    report.append("| 原始名稱 | 優化中文 | 優化英文 | 技術特徵 | 動作數量 |")
    report.append("|---------|---------|---------|---------|---------|")
    for old_name, count in sorted(stats['equipment_categories'].items(), key=lambda x: x[1], reverse=True):
        if old_name in EQUIPMENT_CATEGORY_MAPPING:
            mapping = EQUIPMENT_CATEGORY_MAPPING[old_name]
            report.append(f"| {old_name} | {mapping['zh']} | {mapping['en']} | {mapping['technical']} | {count} |")
    report.append("")
    
    # 第五層統計
    report.append("## 📊 第五層：器材子類別優化統計（Top 15）")
    report.append("")
    report.append("| 原始名稱 | 優化中文 | 優化英文 | 所屬類別 | 動作數量 |")
    report.append("|---------|---------|---------|---------|---------|")
    sorted_eq_sub = sorted(stats['equipment_subcategories'].items(), key=lambda x: x[1], reverse=True)[:15]
    for old_name, count in sorted_eq_sub:
        if old_name in EQUIPMENT_SUBCATEGORY_MAPPING:
            mapping = EQUIPMENT_SUBCATEGORY_MAPPING[old_name]
            report.append(f"| {old_name} | {mapping['zh']} | {mapping['en']} | {mapping['category']} | {count} |")
    report.append("")
    
    # 優化範例
    report.append("## 🎯 動作優化範例（前 10 個）")
    report.append("")
    report.append("| 原始動作名稱 | 身體部位 | 特定肌群 | 器材 |")
    report.append("|------------|---------|---------|------|")
    for ex in optimized_exercises[:10]:
        bp_opt = ex.get('body_part_optimized', ex.get('body_part', ''))
        sm_opt = ex.get('specific_muscle_optimized', ex.get('specific_muscle', ''))
        eq_opt = ex.get('equipment_subcategory_optimized', ex.get('equipment_subcategory', ''))
        report.append(f"| {ex['name']} | {bp_opt} | {sm_opt} | {eq_opt} |")
    report.append("")
    
    # 關節類型統計
    report.append("## 📊 關節類型分布")
    report.append("")
    report.append("| 關節類型 | 動作數量 | 百分比 |")
    report.append("|---------|---------|--------|")
    for jt, count in sorted(stats['joint_types'].items(), key=lambda x: x[1], reverse=True):
        percentage = (count / stats['total']) * 100
        report.append(f"| {jt} | {count} | {percentage:.1f}% |")
    report.append("")
    
    # 優化總結
    report.append("## ✅ 優化總結")
    report.append("")
    report.append("### 已完成優化")
    report.append(f"- ✅ 訓練類型標準化：{len(TRAINING_TYPE_MAPPING)} 種分類")
    report.append(f"- ✅ 身體部位解剖學命名：{len(BODY_PART_MAPPING)} 個部位")
    report.append(f"- ✅ 特定肌群精細化：{len(SPECIFIC_MUSCLE_MAPPING)} 個肌群")
    report.append(f"- ✅ 器材類別工程學定義：{len(EQUIPMENT_CATEGORY_MAPPING)} 種類別")
    report.append(f"- ✅ 器材子類別細分：{len(EQUIPMENT_SUBCATEGORY_MAPPING)} 種器材")
    report.append("")
    report.append("### 優化原則")
    report.append("1. **解剖學精確性**：所有肌群名稱符合運動解剖學標準")
    report.append("2. **器材工程學**：區分固定式、自由重量、功能性訓練")
    report.append("3. **雙語標準化**：提供繁體中文與英文標準名稱")
    report.append("4. **向後相容**：保留原有欄位，新增優化欄位")
    report.append("")
    
    # 下一步建議
    report.append("## 🚀 下一步工作")
    report.append("")
    report.append("1. **動作名稱英文翻譯**：將所有 `name_en` 欄位翻譯為標準英文")
    report.append("2. **動作描述生成**：為每個動作生成專業的訓練描述")
    report.append("3. **圖片與影片**：補充動作示範圖片與影片")
    report.append("4. **資料庫遷移**：執行 Supabase 更新腳本")
    report.append("")
    
    report.append("---")
    report.append("")
    report.append("**文檔版本**: 1.0")
    report.append(f"**生成時間**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    report.append("**維護者**: StrengthWise 開發團隊")
    
    return "\n".join(report)

def main():
    """主程序"""
    print("=" * 80)
    print("StrengthWise - 專業健身動作命名系統重塑")
    print("=" * 80)
    print()
    
    # 檔案路徑
    input_file = 'database_export/exercises.json'
    output_file = 'database_export/exercises_optimized.json'
    report_file = 'database_export/EXERCISE_RENAMING_REPORT.md'
    
    # 檢查檔案是否存在
    if not os.path.exists(input_file):
        print(f"❌ 錯誤：找不到檔案 {input_file}")
        return
    
    # 載入資料
    print(f"📂 載入動作資料：{input_file}")
    exercises = load_exercises(input_file)
    print(f"✅ 成功載入 {len(exercises)} 個動作")
    print()
    
    # 分析現有資料
    print("📊 分析現有資料結構...")
    stats = analyze_current_data(exercises)
    print(f"   - 訓練類型：{len(stats['training_types'])} 種")
    print(f"   - 身體部位：{len(stats['body_parts'])} 個")
    print(f"   - 特定肌群：{len(stats['specific_muscles'])} 個")
    print(f"   - 器材類別：{len(stats['equipment_categories'])} 種")
    print(f"   - 器材子類別：{len(stats['equipment_subcategories'])} 種")
    print()
    
    # 優化動作命名
    print("🔄 執行命名優化...")
    optimized_exercises = []
    for i, ex in enumerate(exercises):
        if (i + 1) % 100 == 0:
            print(f"   進度：{i + 1}/{len(exercises)}")
        optimized = optimize_exercise(ex)
        optimized_exercises.append(optimized)
    print(f"✅ 完成 {len(optimized_exercises)} 個動作的優化")
    print()
    
    # 儲存優化後的資料
    print(f"💾 儲存優化資料：{output_file}")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(optimized_exercises, f, ensure_ascii=False, indent=2)
    print("✅ 儲存成功")
    print()
    
    # 生成報告
    print(f"📝 生成優化報告：{report_file}")
    report = generate_report(exercises, optimized_exercises, stats)
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(report)
    print("✅ 報告生成成功")
    print()
    
    print("=" * 80)
    print("🎉 命名優化完成！")
    print("=" * 80)
    print()
    print("📁 輸出檔案：")
    print(f"   1. {output_file} - 優化後的動作資料（JSON）")
    print(f"   2. {report_file} - 優化報告（Markdown）")
    print()
    print("下一步：")
    print("   - 查看報告了解優化統計")
    print("   - 檢查優化後的資料是否符合預期")
    print("   - 準備生成 Supabase 更新腳本")

if __name__ == '__main__':
    main()

