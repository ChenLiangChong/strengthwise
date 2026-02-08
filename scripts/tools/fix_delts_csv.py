#!/usr/bin/env python3
"""
修正 delts.csv 中的 SEE 命名規範問題
"""
import csv
import os

# 檔案路徑
CSV_PATH = os.path.join(os.path.dirname(__file__), '..', 'review_data', 'by_muscle_grouped', 'delts.csv')

# 需要修正的資料 (id -> 修正內容)
FIXES = {
    # SEE 命名修正：移除「雙手/Two Arm」
    'EmjMil4pfZosVPWYykZi': {
        '中文名': '啞鈴直立划船',
        '英文名': 'Dumbbell Upright Row',
        '別名': '直立划船, Upright Row',
    },
    'GiQPvesUASXOkLuW5v2e': {
        '中文名': '站姿纜繩直立划船',
        '英文名': 'Standing Cable Upright Row',
        '別名': '纜繩直立划船, Cable Upright Row',
    },
    'qadcIHON7xhFgnMH0Ry3': {
        '別名': '直立划船, Smith Upright Row',
    },
    'tXBlrkdtKlmPKGYMnOwV': {
        'PPL標籤': 'pull',  # 修正：push -> pull
        '別名': '啞鈴直立划船, Dumbbell Upright Row',
    },
    'VDcLd9TZQ0csz40CVJ9D': {
        '別名': '啞鈴直立划船, Dumbbell Upright Row',
    },
    'VSTwIVKKMqrlYYBVgfYu': {
        '別名': '纜繩直立划船, Cable Upright Row',
    },
    '0RrJyyFHtD74r3yorad9': {
        '中文名': '俯身纜繩側平舉',
        '英文名': 'Bent Over Cable Lateral Raise',
        '主動肌': 'rear_delts',  # 修正：side_delts -> rear_delts
        '協同肌': 'side_delts, traps, rhomboids',  # 修正：移除 upper_back
        '別名': '纜繩俯身側平舉, Bent Over Cable Rear Delt Fly',
    },
    'ARL1RmTU570PT3HMGUGq': {
        '中文名': '站姿纜繩側平舉',
        '英文名': 'Standing Cable Lateral Raise',
    },
    'JKPHMx0qGHOoSAQYARLE': {
        '別名': '彈力帶側平舉, Band Lateral Raise',
    },
    'tKUhdnnoebLw8Ci11Gd9': {
        '中文名': '啞鈴側平舉',
        '英文名': 'Dumbbell Lateral Raise',
    },
    'UBQv2RMFSe8OYCfbod7g': {
        '別名': '啞鈴側平舉, Dumbbell Lateral Raise',
    },
    'uzcAXsho2c4PIQIy40nQ': {
        '協同肌': 'traps, obliques',  # 修正：移除 upper_back
    },
    'Z8B9ax0mBaDagRJydUwV': {
        '協同肌': 'traps, obliques',  # 修正：移除 upper_back
    },
    'ZkUunF0KrMaGlxgCP3Du': {
        '中文名': '坐姿機械側平舉',
        '英文名': 'Seated Machine Lateral Raise',
        '別名': '機械側平舉, Machine Lateral Raise',
    },
}

# 欄位對應（根據 CSV 結構）
FIELD_MAP = {
    '中文名': 3,      # 第 4 欄（0-indexed = 3）
    '英文名': 4,      # 第 5 欄
    '別名': 5,        # 第 6 欄
    'PPL標籤': 7,     # 第 8 欄
    '主動肌': 8,      # 第 9 欄
    '協同肌': 9,      # 第 10 欄
}


def main():
    # 讀取 CSV（嘗試不同編碼）
    encodings = ['utf-8', 'big5', 'cp950', 'gb2312']
    rows = []
    used_encoding = None
    
    for enc in encodings:
        try:
            with open(CSV_PATH, 'r', encoding=enc, newline='') as f:
                reader = csv.reader(f)
                rows = list(reader)
                used_encoding = enc
                print(f"[OK] Read file with {enc} encoding")
                break
        except (UnicodeDecodeError, UnicodeError):
            continue
    
    if not rows:
        print("[ERROR] Cannot read CSV file")
        return
    
    # 修正資料
    modified_count = 0
    for i, row in enumerate(rows):
        if not row:
            continue
        
        row_id = row[0]
        if row_id in FIXES:
            fixes = FIXES[row_id]
            print(f"\n[FIX] ID: {row_id}")
            
            for field_name, new_value in fixes.items():
                if field_name in FIELD_MAP:
                    col_idx = FIELD_MAP[field_name]
                    old_value = row[col_idx] if col_idx < len(row) else ''
                    row[col_idx] = new_value
                    print(f"   {field_name}: '{old_value}' -> '{new_value}'")
            
            modified_count += 1
    
    # 寫回 CSV
    with open(CSV_PATH, 'w', encoding=used_encoding, newline='') as f:
        writer = csv.writer(f)
        writer.writerows(rows)
    
    print(f"\n[DONE] Modified {modified_count} records")
    print(f"[FILE] Saved to: {CSV_PATH}")


if __name__ == '__main__':
    main()
