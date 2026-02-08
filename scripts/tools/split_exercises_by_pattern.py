#!/usr/bin/env python3
"""
將動作 CSV 依動作模式分割成不同檔案
1. 去除所有欄位的前後空格
2. 加入 is_explosive 欄位
3. 按動作模式分組
4. 每個檔案內按主動肌排序
"""

import csv
import os
from pathlib import Path
from collections import defaultdict

# 動作模式分組
PATTERN_GROUPS = {
    # 推類
    'horizontal_push': ('01_horizontal_push', '水平推'),
    'vertical_push': ('02_vertical_push', '垂直推'),
    # 拉類
    'horizontal_pull': ('03_horizontal_pull', '水平拉'),
    'vertical_pull': ('04_vertical_pull', '垂直拉'),
    # 下肢
    'squat': ('05_squat', '蹲'),
    'hinge': ('06_hinge', '髖鉸鏈'),
    'lunge': ('07_lunge', '弓步'),
    # 核心（合併所有核心相關）
    'core': ('08_core', '核心'),
    'anti_extension': ('08_core', '核心'),
    'anti_rotation': ('08_core', '核心'),
    'anti_lateral_flexion': ('08_core', '核心'),
    'anti_lateral': ('08_core', '核心'),
    'anti_flexion': ('08_core', '核心'),
    'core_anti_lateral': ('08_core', '核心'),
    'core_anti_rotation': ('08_core', '核心'),
    'flexion': ('08_core', '核心'),
    'core_flexion': ('08_core', '核心'),
    'rotation': ('08_core', '核心'),
    'core_rotation': ('08_core', '核心'),
    'lateral_flexion': ('08_core', '核心'),
    'rotation (external)': ('08_core', '核心'),
    'rotation (internal)': ('08_core', '核心'),
    # 攜帶
    'carry': ('09_carry', '攜帶'),
    # 孤立
    'isolation_upper': ('10_isolation_upper', '孤立上肢'),
    'isolation_push': ('10_isolation_upper', '孤立上肢'),
    'isolation_pull': ('10_isolation_upper', '孤立上肢'),
    'isolation_lower': ('11_isolation_lower', '孤立下肢'),
    'isolation_squat': ('11_isolation_lower', '孤立下肢'),
    'isolation_hinge': ('11_isolation_lower', '孤立下肢'),
    # 心肺
    'cardio': ('12_cardio', '心肺'),
    # 活動度
    'mobility': ('13_mobility', '活動度'),
    # 爆發力（合併）
    'power': ('14_power', '爆發力'),
    'plyometric': ('14_power', '爆發力'),
    'olympic_lift': ('14_power', '爆發力'),
    'olympic': ('14_power', '爆發力'),
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


def is_explosive(patterns_str: str) -> bool:
    """判斷是否為爆發力動作"""
    if not patterns_str:
        return False
    patterns = [p.strip().lower() for p in patterns_str.split(',')]
    return any(p in EXPLOSIVE_PATTERNS for p in patterns)


def get_group(pattern: str) -> tuple:
    """取得分組資訊"""
    pattern = pattern.strip().lower()
    return PATTERN_GROUPS.get(pattern, ('99_unknown', '未分類'))


def main():
    script_dir = Path(__file__).parent.parent
    input_file = script_dir / 'review_data' / 'exercises_review.csv'
    output_dir = script_dir / 'review_data' / 'split'

    # 清空並重建輸出目錄
    if output_dir.exists():
        for f in output_dir.glob('*.csv'):
            try:
                f.unlink()
            except:
                pass
    output_dir.mkdir(exist_ok=True)

    # 讀取 CSV 並處理
    with open(input_file, 'r', encoding='big5') as f:
        reader = csv.DictReader(f)
        original_fieldnames = list(reader.fieldnames)
        rows = [strip_all_fields(row) for row in reader]

    # 新增 is_explosive 欄位
    fieldnames = original_fieldnames + ['is_explosive']
    for row in rows:
        row['is_explosive'] = 'TRUE' if is_explosive(row.get('動作模式', '')) else 'FALSE'

    print(f"讀取 {len(rows)} 筆資料（已去除空格）")

    # 按分組分類
    groups = defaultdict(list)
    for row in rows:
        pattern = get_primary_pattern(row.get('動作模式', ''))
        group_key, group_name = get_group(pattern)
        groups[group_key].append(row)

    # 輸出各分組檔案
    total = 0
    for group_key in sorted(groups.keys()):
        group_rows = groups[group_key]

        # 按主動肌排序（已去除空格）
        group_rows.sort(key=lambda r: (r.get('主動肌', '') or '').lower())

        output_file = output_dir / f'{group_key}.csv'
        with open(output_file, 'w', encoding='big5', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(group_rows)

        print(f"  {group_key}.csv: {len(group_rows)} 筆")
        total += len(group_rows)

    print(f"\n已輸出至 {output_dir}/")
    print(f"總計 {len(groups)} 個檔案，{total} 筆")


if __name__ == '__main__':
    main()
