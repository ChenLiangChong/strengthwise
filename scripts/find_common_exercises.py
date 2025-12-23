#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
從 Firestore 查找常見的健身動作用於生成假資料
"""

import sys
import os
import pandas as pd
from firebase_admin import credentials, firestore, initialize_app

# 設置 UTF-8 輸出
sys.stdout.reconfigure(encoding='utf-8')

# 初始化 Firebase
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
cred_path = os.path.join(project_root, 'strengthwise-service-account.json')
cred = credentials.Certificate(cred_path)
initialize_app(cred)
db = firestore.client()

def main():
    print("=" * 60)
    print("查找常見健身動作")
    print("=" * 60)
    print()
    
    # 從 Firestore 讀取動作
    exercises_ref = db.collection('exercises')
    exercises = list(exercises_ref.stream())
    
    print(f"總共有 {len(exercises)} 個動作")
    print()
    
    # 關鍵字搜尋常見動作
    keywords = {
        '臥推': [],
        '深蹲': [],
        '硬舉': [],
        '划船': [],
        '引體': [],
        '肩推': [],
        '彎舉': [],
        '腿推': [],
        '腿彎': [],
        '側平舉': [],
    }
    
    for doc in exercises:
        data = doc.to_dict()
        name = data.get('name', '')
        
        for keyword in keywords:
            if keyword in name:
                keywords[keyword].append({
                    'id': doc.id,
                    'name': name,
                    'bodyPart': data.get('bodyPart', ''),
                    'specificMuscle': data.get('specificMuscle', ''),
                    'equipmentCategory': data.get('equipmentCategory', ''),
                })
    
    # 顯示結果
    for keyword, items in keywords.items():
        print(f"\n【{keyword}】 ({len(items)} 個):")
        for item in items[:5]:  # 只顯示前 5 個
            print(f"  {item['id']}")
            print(f"    名稱: {item['name']}")
            print(f"    部位: {item['bodyPart']} / {item['specificMuscle']}")
            print(f"    器材: {item['equipmentCategory']}")
            print()

if __name__ == "__main__":
    main()

