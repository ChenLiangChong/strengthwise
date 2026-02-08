#!/usr/bin/env python3
"""
將動作 CSV 依主動肌分割成不同檔案
1. 去除所有欄位的前後空格
2. 加入 is_explosive 欄位
3. 按主動肌分組（相似肌群合併）
4. 每個檔案內按動作模式排序
"""

import csv
from pathlib import Path
from collections import defaultdict

# 相似肌群合併對照表
MUSCLE_GROUPS = {
    # 臀部 → glutes
    'glutes': 'glutes',
    'glute_max': 'glutes',
    'glute_med': 'glutes',
    'glute_medius': 'glutes',

    # 旋轉肌群 → rotator_cuff
    'rotator_cuff': 'rotator_cuff',
    'rotator_cuff_infraspinatus': 'rotator_cuff',
    'rotator_cuff_infraspinatus,_teres_minor': 'rotator_cuff',
    'rotator_cuff_subscapularis': 'rotator_cuff',
    'infraspinatus': 'rotator_cuff',
    'infraspinatus,_teres_minor': 'rotator_cuff',
    'subscapularis': 'rotator_cuff',

    # 上背 → upper_back
    'upper_back': 'upper_back',
    'upper_back_rhomboids,_traps': 'upper_back',
    'upper_back_traps': 'upper_back',

    # 胸肌 → pecs
    'chest': 'pecs',
    'mid_pecs': 'pecs',
    'pec_major': 'pecs',
    'pec_major_clavicular': 'pecs',
    'pec_major_sternal': 'pecs',

    # 核心 → core
    'core': 'core',
    'abs': 'core',
    'obliques': 'core',
    'rectus_abdominis': 'core',

    # 小腿 → calves
    'calves': 'calves',
    'gastrocnemius': 'calves',
    'soleus': 'calves',

    # 三角肌 → delts
    'shoulders': 'delts',
    'front_delts': 'delts',
    'side_delts': 'delts',
    'rear_delts': 'delts',

    # 背部 → back（籠統的 back 合併到 lats）
    'back': 'back_general',
    'lats': 'lats',

    # 其他保持原名
}

# 動作模式排序優先級
PATTERN_PRIORITY = {
    'horizontal_push': 1,
    'vertical_push': 2,
    'horizontal_pull': 3,
    'vertical_pull': 4,
    'squat': 5,
    'hinge': 6,
    'lunge': 7,
    'core': 8, 'anti_extension': 8, 'anti_rotation': 8, 'anti_lateral_flexion': 8,
    'anti_lateral': 8, 'anti_flexion': 8, 'core_anti_lateral': 8, 'core_anti_rotation': 8,
    'flexion': 8, 'core_flexion': 8, 'rotation': 8, 'core_rotation': 8,
    'lateral_flexion': 8, 'rotation (external)': 8, 'rotation (internal)': 8,
    'carry': 9,
    'isolation_upper': 10, 'isolation_push': 10, 'isolation_pull': 10,
    'isolation_lower': 11, 'isolation_squat': 11, 'isolation_hinge': 11,
    'cardio': 12,
    'mobility': 13,
    'power': 14, 'plyometric': 14, 'olympic_lift': 14, 'olympic': 14,
}

# 爆發力相關的動作模式
EXPLOSIVE_PATTERNS = {'power', 'plyometric', 'olympic_lift', 'olympic'}


def strip_all_fields(row: dict) -> dict:
    """去除所有欄位的前後空格"""
    return {k: (v.strip() if isinstance(v, str) else v) for k, v in row.items()}


def get_primary_pattern(patterns_str: str) -> str:
    """從複合模式字串中取得第一個模式"""
    if not patterns_str:
        return ''
    patterns = [p.strip() for p in patterns_str.split(',')]
    return patterns[0] if patterns else ''


def get_pattern_priority(pattern: str) -> int:
    """取得動作模式排序優先級"""
    return PATTERN_PRIORITY.get(pattern.lower(), 99)


def is_explosive(patterns_str: str) -> bool:
    """判斷是否為爆發力動作"""
    if not patterns_str:
        return False
    patterns = [p.strip().lower() for p in patterns_str.split(',')]
    return any(p in EXPLOSIVE_PATTERNS for p in patterns)


def normalize_muscle_name(muscle: str) -> str:
    """標準化肌肉名稱"""
    if not muscle:
        return 'unknown'
    # 移除特殊字元，用底線取代空格
    name = muscle.lower().replace(' ', '_').replace('/', '_').replace('(', '').replace(')', '')
    return name


def get_muscle_group(muscle: str) -> str:
    """取得肌群分組名稱"""
    normalized = normalize_muscle_name(muscle)
    return MUSCLE_GROUPS.get(normalized, normalized)


def main():
    script_dir = Path(__file__).parent.parent
    input_file = script_dir / 'review_data' / 'exercises_review.csv'
    output_dir = script_dir / 'review_data' / 'by_muscle_grouped'

    # 建立輸出目錄
    output_dir.mkdir(exist_ok=True)

    # 讀取 CSV 並處理
    with open(input_file, 'r', encoding='big5') as f:
        reader = csv.DictReader(f)
        original_fieldnames = list(reader.fieldnames)
        rows = [strip_all_fields(row) for row in reader]

    # 新增欄位：is_explosive, 原始主動肌
    fieldnames = original_fieldnames + ['原始主動肌', 'is_explosive']
    for row in rows:
        original_muscle = row.get('主動肌', '') or 'unknown'
        row['原始主動肌'] = original_muscle
        row['is_explosive'] = 'TRUE' if is_explosive(row.get('動作模式', '')) else 'FALSE'

    print(f"讀取 {len(rows)} 筆資料（已去除空格）")

    # 按肌群分組
    groups = defaultdict(list)
    for row in rows:
        muscle = row.get('主動肌', '') or 'unknown'
        group = get_muscle_group(muscle)
        groups[group].append(row)

    # 輸出各分組檔案
    print(f"\n按肌群分割（共 {len(groups)} 組）：")

    total = 0
    for group_name in sorted(groups.keys()):
        group_rows = groups[group_name]

        # 按原始主動肌 + 動作模式優先級排序
        group_rows.sort(key=lambda r: (
            r.get('原始主動肌', '').lower(),
            get_pattern_priority(get_primary_pattern(r.get('動作模式', ''))),
            r.get('動作模式', '')
        ))

        output_file = output_dir / f'{group_name}.csv'

        with open(output_file, 'w', encoding='big5', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(group_rows)

        # 統計原始肌肉名稱
        original_muscles = defaultdict(int)
        for r in group_rows:
            original_muscles[r['原始主動肌']] += 1

        muscle_breakdown = ', '.join(f"{k}({v})" for k, v in sorted(original_muscles.items()))
        print(f"  {group_name}.csv: {len(group_rows)} 筆 ← {muscle_breakdown}")
        total += len(group_rows)

    print(f"\n已輸出至 {output_dir}/")
    print(f"總計 {len(groups)} 個檔案，{total} 筆")


if __name__ == '__main__':
    main()
