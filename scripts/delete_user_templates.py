#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
刪除指定用戶的所有訓練模板
"""

import sys
import os
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

# 目標用戶
TARGET_USER_ID = "UmtFu02WQ4QUoTV3x6AFRbd1ov52"

def main():
    print("=" * 60)
    print("刪除用戶訓練模板")
    print("=" * 60)
    print()
    print(f"目標用戶: {TARGET_USER_ID}")
    print()
    
    # 查詢該用戶的所有模板
    templates_ref = db.collection('workoutTemplates')
    query = templates_ref.where('userId', '==', TARGET_USER_ID)
    docs = query.stream()
    
    doc_ids = []
    for doc in docs:
        doc_ids.append(doc.id)
    
    print(f"找到 {len(doc_ids)} 個訓練模板")
    print()
    
    if len(doc_ids) == 0:
        print("沒有模板需要刪除")
        return
    
    # 刪除所有模板
    for doc_id in doc_ids:
        db.collection('workoutTemplates').document(doc_id).delete()
        print(f"已刪除: {doc_id}")
    
    print()
    print("=" * 60)
    print(f"✓ 完成！已刪除 {len(doc_ids)} 個訓練模板")
    print("=" * 60)

if __name__ == "__main__":
    main()

