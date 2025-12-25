#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StrengthWise 資料庫遷移腳本（直接從 Firestore 讀取）
從 Firebase Firestore 遷移到 Supabase PostgreSQL

⚠️ 重要：
- 只遷移系統級資料（exercises + 元數據）
- 不遷移用戶資料（users, workoutPlans, customExercises）
- 新用戶會從頭開始使用新的資料庫

遷移範圍：
✅ exercise (794 個)
✅ bodyParts (8 個)
✅ exerciseTypes (3 個)
✅ equipments (21 個)
✅ jointTypes (2 個)
❌ users, workoutPlans, workoutTemplates, customExercises（不遷移）

使用方式:
    python scripts/migrate_to_supabase_direct.py
"""

import sys
import io
import os

# 設置輸出編碼為 UTF-8
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

from typing import Dict, List, Any
from datetime import datetime
from supabase import create_client, Client
from dotenv import load_dotenv
from google.cloud import firestore

# 載入環境變數
load_dotenv()

# 初始化 Supabase Client
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("[ERROR] 請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY 環境變數")
    print("       請複製 .env.example 為 .env 並填入正確的值")
    sys.exit(1)

# 初始化 Firestore
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'strengthwise-service-account.json'
firestore_db = firestore.Client(project='strengthwise-91f02')

# 初始化 Supabase
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

class DataMigrator:
    """資料遷移主類別"""
    
    def __init__(self):
        self.stats = {
            'exercises': 0,
            'body_parts': 0,
            'exercise_types': 0,
            'equipments': 0,
            'joint_types': 0,
            'errors': []
        }
    
    def run(self):
        """執行完整遷移流程"""
        print("=" * 60)
        print("[INFO] StrengthWise 資料庫遷移（Firestore -> Supabase）")
        print("=" * 60)
        print("")
        
        # 依序遷移（注意順序：元數據優先）
        self.migrate_body_parts()
        self.migrate_exercise_types()
        self.migrate_equipments()
        self.migrate_joint_types()
        self.migrate_exercises()
        
        # 輸出統計
        self.print_stats()
    
    def migrate_exercises(self):
        """遷移動作庫（794 個）"""
        print("[INFO] 遷移動作庫...")
        
        try:
            # 從 Firestore 讀取
            docs = list(firestore_db.collection('exercise').stream())
            print(f"[OK]   找到 {len(docs)} 個動作")
            
            exercises_batch = []
            for doc in docs:
                exercise = doc.to_dict()
                exercises_batch.append({
                    'id': doc.id,
                    'name': exercise.get('name', ''),
                    'name_en': exercise.get('nameEn', ''),
                    'action_name': exercise.get('actionName', ''),
                    'training_type': exercise.get('trainingType', ''),
                    'body_part': exercise.get('bodyPart', ''),
                    'body_parts': exercise.get('bodyParts', []),
                    'specific_muscle': exercise.get('specificMuscle'),
                    'equipment': exercise.get('equipment', ''),
                    'equipment_category': exercise.get('equipmentCategory', ''),
                    'equipment_subcategory': exercise.get('equipmentSubcategory', ''),
                    'joint_type': exercise.get('jointType', ''),
                    'level1': exercise.get('level1', ''),
                    'level2': exercise.get('level2', ''),
                    'level3': exercise.get('level3', ''),
                    'level4': exercise.get('level4', ''),
                    'level5': exercise.get('level5', ''),
                    'description': exercise.get('description', ''),
                    'image_url': exercise.get('imageUrl', ''),
                    'video_url': exercise.get('videoUrl', ''),
                    'user_id': None,  # 系統內建動作
                    'created_at': self.parse_timestamp(exercise.get('createdAt'))
                })
            
            # 批次寫入（每次 100 筆）
            batch_size = 100
            for i in range(0, len(exercises_batch), batch_size):
                batch = exercises_batch[i:i+batch_size]
                try:
                    supabase.table("exercises").upsert(batch).execute()
                    self.stats['exercises'] += len(batch)
                    print(f"[OK]   遷移進度: {self.stats['exercises']}/{len(exercises_batch)}")
                except Exception as e:
                    error_msg = f"遷移動作失敗 (batch {i}): {e}"
                    print(f"[ERROR] {error_msg}")
                    self.stats['errors'].append(error_msg)
            
            print(f"[OK]   成功遷移 {self.stats['exercises']} 個動作")
            
        except Exception as e:
            error_msg = f"讀取 Firestore exercise 集合失敗: {e}"
            print(f"[ERROR] {error_msg}")
            self.stats['errors'].append(error_msg)
    
    def migrate_body_parts(self):
        """遷移身體部位（8 個）"""
        print("[INFO] 遷移身體部位...")
        
        try:
            docs = list(firestore_db.collection('bodyParts').stream())
            print(f"[OK]   找到 {len(docs)} 個身體部位")
            
            batch = []
            for doc in docs:
                part = doc.to_dict()
                batch.append({
                    'id': doc.id,
                    'name': part.get('name', ''),
                    'description': part.get('description', ''),
                    'count': part.get('count', 0)
                })
            
            if batch:
                supabase.table("body_parts").upsert(batch).execute()
                self.stats['body_parts'] = len(batch)
                print(f"[OK]   成功遷移 {len(batch)} 個身體部位")
                
        except Exception as e:
            error_msg = f"遷移身體部位失敗: {e}"
            print(f"[ERROR] {error_msg}")
            self.stats['errors'].append(error_msg)
    
    def migrate_exercise_types(self):
        """遷移動作類型（3 個）"""
        print("[INFO] 遷移動作類型...")
        
        try:
            docs = list(firestore_db.collection('exerciseTypes').stream())
            print(f"[OK]   找到 {len(docs)} 個動作類型")
            
            batch = []
            for doc in docs:
                type_data = doc.to_dict()
                batch.append({
                    'id': doc.id,
                    'name': type_data.get('name', ''),
                    'description': type_data.get('description', ''),
                    'count': type_data.get('count', 0)
                })
            
            if batch:
                supabase.table("exercise_types").upsert(batch).execute()
                self.stats['exercise_types'] = len(batch)
                print(f"[OK]   成功遷移 {len(batch)} 個動作類型")
                
        except Exception as e:
            error_msg = f"遷移動作類型失敗: {e}"
            print(f"[ERROR] {error_msg}")
            self.stats['errors'].append(error_msg)
    
    def migrate_equipments(self):
        """遷移器材列表（21 個）"""
        print("[INFO] 遷移器材列表...")
        
        try:
            docs = list(firestore_db.collection('equipments').stream())
            print(f"[OK]   找到 {len(docs)} 個器材")
            
            batch = []
            for doc in docs:
                equipment = doc.to_dict()
                batch.append({
                    'id': doc.id,
                    'name': equipment.get('name', ''),
                    'description': equipment.get('description', ''),
                    'category': equipment.get('category', ''),
                    'count': equipment.get('count', 0)
                })
            
            if batch:
                supabase.table("equipments").upsert(batch).execute()
                self.stats['equipments'] = len(batch)
                print(f"[OK]   成功遷移 {len(batch)} 個器材")
                
        except Exception as e:
            error_msg = f"遷移器材失敗: {e}"
            print(f"[ERROR] {error_msg}")
            self.stats['errors'].append(error_msg)
    
    def migrate_joint_types(self):
        """遷移關節類型（2 個）"""
        print("[INFO] 遷移關節類型...")
        
        try:
            docs = list(firestore_db.collection('jointTypes').stream())
            print(f"[OK]   找到 {len(docs)} 個關節類型")
            
            batch = []
            for doc in docs:
                joint = doc.to_dict()
                batch.append({
                    'id': doc.id,
                    'name': joint.get('name', ''),
                    'description': joint.get('description', ''),
                    'count': joint.get('count', 0)
                })
            
            if batch:
                supabase.table("joint_types").upsert(batch).execute()
                self.stats['joint_types'] = len(batch)
                print(f"[OK]   成功遷移 {len(batch)} 個關節類型")
                
        except Exception as e:
            error_msg = f"遷移關節類型失敗: {e}"
            print(f"[ERROR] {error_msg}")
            self.stats['errors'].append(error_msg)
    
    def parse_timestamp(self, ts):
        """解析 Firestore timestamp"""
        if not ts:
            return None
        if isinstance(ts, str):
            # 已經是 ISO 格式
            return ts
        if hasattr(ts, 'seconds'):
            # Firestore Timestamp
            return datetime.fromtimestamp(ts.seconds).isoformat()
        if isinstance(ts, int):
            # Unix timestamp (ms)
            return datetime.fromtimestamp(ts / 1000).isoformat()
        return None
    
    def print_stats(self):
        """輸出遷移統計"""
        print("")
        print("=" * 60)
        print("[INFO] 遷移統計")
        print("=" * 60)
        print(f"動作庫:       {self.stats['exercises']:4d} 個")
        print(f"身體部位:     {self.stats['body_parts']:4d} 個")
        print(f"動作類型:     {self.stats['exercise_types']:4d} 個")
        print(f"器材列表:     {self.stats['equipments']:4d} 個")
        print(f"關節類型:     {self.stats['joint_types']:4d} 個")
        print("=" * 60)
        print(f"總計:         {sum([v for k, v in self.stats.items() if k != 'errors']):4d} 個文檔")
        print(f"錯誤數:       {len(self.stats['errors']):4d} 個")
        
        if self.stats['errors']:
            print("")
            print("[ERROR] 錯誤清單:")
            for error in self.stats['errors']:
                print(f"  - {error}")
        
        print("=" * 60)

def main():
    """主程式入口"""
    print("")
    print("[INFO] 檢查連接...")
    
    # 測試 Firestore 連接
    try:
        test_doc = list(firestore_db.collection('exercise').limit(1).stream())
        print("[OK]   Firestore 連接成功")
    except Exception as e:
        print(f"[ERROR] Firestore 連接失敗: {e}")
        sys.exit(1)
    
    # 測試 Supabase 連接
    try:
        test_query = supabase.table("exercises").select("id").limit(1).execute()
        print("[OK]   Supabase 連接成功")
    except Exception as e:
        print(f"[ERROR] Supabase 連接失敗: {e}")
        print(f"[INFO] 請確保已在 Supabase Dashboard 執行 migrations/001_create_core_tables.sql")
        sys.exit(1)
    
    print("")
    print("[INFO] 開始執行資料遷移...")
    print("")
    
    migrator = DataMigrator()
    migrator.run()
    
    print("")
    print("[OK]   遷移完成！")
    print("")

if __name__ == "__main__":
    main()

