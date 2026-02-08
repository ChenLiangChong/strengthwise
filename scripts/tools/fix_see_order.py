#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修正 SEE 命名順序問題
正確順序：[單雙側] → [姿勢] → [握法] → [角度] → [器材] → [動作]
"""
import csv
import os

CSV_PATH = os.path.join(os.path.dirname(__file__), '..', 'review_data', 'by_muscle_grouped', 'delts.csv')

# SEE 順序修正
FIXES = {
    '6hvpsp4UIyWptRYJYL2l': {
        'cn': '單手站姿彈力帶肩推',
        'en': 'Single Arm Standing Resistance Band Shoulder Press',
    },
    'kBwyh7Q9JvDwqYocu1ht': {
        'cn': '單手弓箭步俯身寬握啞鈴划船',
        'en': 'Single Arm Lunge Stance Bent Over Wide Grip Dumbbell Row',
    },
    'dCCTiw5XFJjogegGQYQT': {
        'cn': '單手半跪姿彈力帶反向飛鳥',
        'en': 'Single Arm Half Kneeling Resistance Band Reverse Fly',
    },
    'Skc0d6OUaWHU2vKSbHvG': {
        'cn': '交替俯身纜繩肩推',
        'en': 'Alternating Bent Over Cable Shoulder Press',
    },
}


def main():
    # 讀取 CSV
    with open(CSV_PATH, 'r', encoding='big5', newline='') as f:
        rows = list(csv.reader(f))
    
    modified = 0
    for row in rows:
        if row and row[0] in FIXES:
            fix = FIXES[row[0]]
            print(f'ID: {row[0][:12]}...')
            print(f'  CN: {row[3]} -> {fix["cn"]}')
            print(f'  EN: {row[4]} -> {fix["en"]}')
            print()
            row[3] = fix['cn']
            row[4] = fix['en']
            modified += 1
    
    # 寫回 CSV
    with open(CSV_PATH, 'w', encoding='big5', newline='') as f:
        writer = csv.writer(f)
        writer.writerows(rows)
    
    print(f'[DONE] Modified {modified} records')


if __name__ == '__main__':
    main()
