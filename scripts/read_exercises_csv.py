#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
從 CSV 讀取動作數據並查找常見動作
"""

import sys
import pandas as pd

# 設置 UTF-8 輸出
sys.stdout.reconfigure(encoding='utf-8')

def main():
    print("=" * 60)
    print("從 CSV 讀取動作數據")
    print("=" * 60)
    print()
    
    # 讀取 CSV
    try:
        df = pd.read_csv('exercises_reclassified.csv', encoding='utf-8')
    except:
        try:
            df = pd.read_csv('exercises_reclassified.csv', encoding='utf-8-sig')
        except:
            df = pd.read_csv('exercises_reclassified.csv', encoding='big5')
    
    print(f"總共有 {len(df)} 個動作")
    print()
    print("前 10 個動作:")
    print(df.head(10)[['id', 'name', 'bodyPart', 'equipmentCategory']])
    print()
    
    # 關鍵字搜尋
    keywords = ['臥推', '深蹲', '硬舉', '划船', '引體', '肩推', '彎舉', '腿推', '腿彎', '側平舉', '提踵']
    
    for keyword in keywords:
        matches = df[df['name'].str.contains(keyword, na=False)]
        if len(matches) > 0:
            print(f"\n【{keyword}】 ({len(matches)} 個):")
            for _, row in matches.head(3).iterrows():
                print(f"  ID: {row['id']}")
                print(f"  名稱: {row['name']}")
                print(f"  部位: {row['bodyPart']} / {row['specificMuscle']}")
                print(f"  器材: {row['equipmentCategory']}")
                print()

if __name__ == "__main__":
    main()

