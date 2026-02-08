#!/usr/bin/env python3
"""
排序動作 CSV 以方便人工審核
按照動作模式（Movement Pattern）和主動肌（Primary Muscle）排序
"""

import csv
import sys
from pathlib import Path

# 動作模式優先級（根據 ref_movement_patterns.json 邏輯分組）
MOVEMENT_PATTERN_PRIORITY = {
    # 1. 水平推
    'horizontal_push': 1,
    # 2. 垂直推
    'vertical_push': 2,
    # 3. 水平拉
    'horizontal_pull': 3,
    # 4. 垂直拉
    'vertical_pull': 4,
    # 5. 蹲
    'squat': 5,
    # 6. 髖鉸鏈
    'hinge': 6,
    # 7. 弓步
    'lunge': 7,
    # 8. 核心（所有核心相關）
    'core': 8,
    'anti_extension': 8,
    'anti_rotation': 8,
    'anti_lateral_flexion': 8,
    'anti_lateral': 8,
    'anti_flexion': 8,
    'core_anti_lateral': 8,
    'core_anti_rotation': 8,
    'flexion': 8,
    'core_flexion': 8,
    'rotation': 8,
    'core_rotation': 8,
    'lateral_flexion': 8,
    'rotation (external)': 8,
    'rotation (internal)': 8,
    # 9. 攜帶
    'carry': 9,
    # 10. 孤立-推類
    'isolation_push': 10,
    # 11. 孤立-拉類
    'isolation_pull': 11,
    # 12. 孤立-下肢（舊分類，待轉換）
    'isolation_upper': 10,  # 暫時歸入孤立推
    'isolation_lower': 12,
    'isolation_squat': 12,
    'isolation_hinge': 12,
    # 13. 心肺
    'cardio': 13,
    # 14. 活動度
    'mobility': 14,
    # 15. 爆發力（舊分類）
    'power': 15,
    'plyometric': 15,
    'olympic_lift': 15,
    'olympic': 15,
}

def get_primary_pattern(patterns_str: str) -> str:
    """從複合模式字串中取得第一個模式"""
    if not patterns_str or patterns_str.strip() == '':
        return ''

    # 處理可能的格式：'pattern1, pattern2' 或 ' pattern1, pattern2'
    patterns = [p.strip() for p in patterns_str.split(',')]
    return patterns[0] if patterns else ''

def get_sort_priority(pattern: str) -> int:
    """取得排序優先級，未知模式排在最後"""
    pattern = pattern.strip().lower()
    return MOVEMENT_PATTERN_PRIORITY.get(pattern, 99)

def main():
    # 檔案路徑
    script_dir = Path(__file__).parent.parent
    input_file = script_dir / 'review_data' / 'exercises_review_v2.csv'
    output_file = script_dir / 'review_data' / 'exercises_review_v2_sorted.csv'

    if not input_file.exists():
        print(f"錯誤：找不到輸入檔案 {input_file}")
        sys.exit(1)

    # 讀取 CSV（Big5 編碼）
    rows = []
    with open(input_file, 'r', encoding='big5') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        for row in reader:
            rows.append(row)

    print(f"讀取 {len(rows)} 筆資料")

    # 排序：主要按動作模式優先級，次要按主動肌字母
    def sort_key(row):
        pattern = get_primary_pattern(row.get('動作模式', ''))
        priority = get_sort_priority(pattern)
        primary_muscle = row.get('主動肌', '') or ''
        return (priority, primary_muscle.lower())

    rows.sort(key=sort_key)

    # 統計各類別數量
    pattern_counts = {}
    for row in rows:
        pattern = get_primary_pattern(row.get('動作模式', ''))
        priority = get_sort_priority(pattern)
        key = f"{priority:02d}_{pattern or 'unknown'}"
        pattern_counts[key] = pattern_counts.get(key, 0) + 1

    print("\n各動作模式數量：")
    for key in sorted(pattern_counts.keys()):
        print(f"  {key}: {pattern_counts[key]}")

    # 輸出排序後的 CSV
    with open(output_file, 'w', encoding='big5', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"\n已輸出至 {output_file}")
    print(f"總計 {len(rows)} 筆")

if __name__ == '__main__':
    main()
