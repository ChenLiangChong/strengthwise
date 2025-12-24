#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StrengthWise 資料庫遷移腳本
從 Firebase Firestore (JSON) 遷移到 Supabase PostgreSQL

使用方式:
    python scripts/migrate_to_supabase.py data/database/database_export_for_migration.json
"""

import json
import os
import sys
from typing import Dict, List, Any
from datetime import datetime
from supabase import create_client, Client
from dotenv import load_dotenv

# 載入環境變數
load_dotenv()

# 初始化 Supabase Client
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ 錯誤：請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY 環境變數")
    print("   請複製 .env.example 為 .env 並填入正確的值")
    sys.exit(1)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

class DataMigrator:
    """資料遷移主類別"""
    
    def __init__(self, json_file_path: str):
        self.json_file_path = json_file_path
        self.stats = {
            'users': 0,
            'exercises': 0,
            'workout_plans': 0,
            'workout_exercises': 0,
            'workout_sets': 0,
            'body_parts': 0,
            'exercise_types': 0,
            'notes': 0,
            'errors': []
        }
    
    def run(self):
        """執行完整遷移流程"""
        print("=" * 60)
        print("🚀 StrengthWise 資料庫遷移")
        print("=" * 60)
        
        # 載入 JSON 資料
        print("\n📂 載入資料檔案...")
        with open(self.json_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        collections = data.get('collections', {})
        
        # 依序遷移（注意順序：先父表，後子表）
        self.migrate_body_parts(collections.get('bodyParts', {}))
        self.migrate_exercise_types(collections.get('exerciseTypes', {}))
        self.migrate_users(collections.get('users', {}))
        self.migrate_exercises(collections.get('exercise', {}))
        self.migrate_workout_plans(collections.get('workoutPlans', {}))
        self.migrate_notes(collections.get('notes', {}))
        
        # 輸出統計
        self.print_stats()
    
    def migrate_users(self, users_data: Dict):
        """遷移用戶資料"""
        print("\n👤 遷移用戶資料...")
        
        if not users_data or 'sample_documents' not in users_data:
            print("  ⚠️  無用戶資料")
            return
        
        users_batch = []
        for doc in users_data['sample_documents']:
            user = doc['data']
            users_batch.append({
                'id': doc['id'],
                'email': user.get('email'),
                'display_name': user.get('displayName'),
                'avatar_url': user.get('photoURL'),
                'age': user.get('age'),
                'gender': user.get('gender'),
                'height': user.get('height'),
                'weight': user.get('weight'),
                'unit_system': user.get('unitSystem', 'metric'),
                'is_coach': user.get('isCoach', False),
                'is_student': user.get('isStudent', True),
                'created_at': self.parse_timestamp(user.get('profileCreatedAt')),
                'updated_at': self.parse_timestamp(user.get('profileUpdatedAt'))
            })
        
        if users_batch:
            try:
                response = supabase.table("users").upsert(users_batch).execute()
                self.stats['users'] = len(users_batch)
                print(f"  ✅ 成功遷移 {len(users_batch)} 個用戶")
            except Exception as e:
                error_msg = f"遷移用戶失敗: {e}"
                print(f"  ❌ {error_msg}")
                self.stats['errors'].append(error_msg)
    
    def migrate_exercises(self, exercises_data: Dict):
        """遷移動作庫"""
        print("\n💪 遷移動作庫...")
        
        if not exercises_data or 'sample_documents' not in exercises_data:
            print("  ⚠️  無動作資料")
            return
        
        exercises_batch = []
        for doc in exercises_data['sample_documents']:
            exercise = doc['data']
            exercises_batch.append({
                'id': doc['id'],
                'name': exercise.get('name'),
                'name_en': exercise.get('nameEn'),
                'action_name': exercise.get('actionName'),
                'training_type': exercise.get('trainingType'),
                'body_part': exercise.get('bodyPart'),
                'body_parts': exercise.get('bodyParts', []),
                'specific_muscle': exercise.get('specificMuscle'),
                'equipment': exercise.get('equipment'),
                'equipment_category': exercise.get('equipmentCategory'),
                'equipment_subcategory': exercise.get('equipmentSubcategory'),
                'joint_type': exercise.get('jointType'),
                'level1': exercise.get('level1'),
                'level2': exercise.get('level2'),
                'level3': exercise.get('level3'),
                'level4': exercise.get('level4'),
                'level5': exercise.get('level5'),
                'description': exercise.get('description'),
                'image_url': exercise.get('imageUrl'),
                'video_url': exercise.get('videoUrl'),
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
                print(f"  ✅ 遷移進度: {self.stats['exercises']}/{len(exercises_batch)}")
            except Exception as e:
                error_msg = f"遷移動作失敗 (batch {i}): {e}"
                print(f"  ❌ {error_msg}")
                self.stats['errors'].append(error_msg)
    
    def migrate_workout_plans(self, plans_data: Dict):
        """遷移訓練計劃（包含 exercises 和 sets）"""
        print("\n📋 遷移訓練計劃...")
        
        if not plans_data or 'sample_documents' not in plans_data:
            print("  ⚠️  無訓練計劃資料")
            return
        
        for doc in plans_data['sample_documents']:
            plan = doc['data']
            
            # 1. 插入 workout_plan
            plan_record = {
                'id': doc['id'],
                'user_id': plan.get('userId'),
                'trainee_id': plan.get('traineeId'),
                'creator_id': plan.get('creatorId'),
                'title': plan.get('title'),
                'description': plan.get('description'),
                'plan_type': plan.get('planType'),
                'ui_plan_type': plan.get('uiPlanType'),
                'scheduled_date': self.parse_timestamp(plan.get('scheduledDate')),
                'completed': plan.get('completed', False),
                'completed_date': self.parse_timestamp(plan.get('completedDate')),
                'training_time': self.parse_timestamp(plan.get('trainingTime')),
                'total_exercises': plan.get('totalExercises', 0),
                'total_sets': plan.get('totalSets', 0),
                'total_volume': plan.get('totalVolume', 0),
                'note': plan.get('note'),
                'created_at': self.parse_timestamp(plan.get('createdAt')),
                'updated_at': self.parse_timestamp(plan.get('updatedAt'))
            }
            
            try:
                supabase.table("workout_plans").upsert([plan_record]).execute()
                self.stats['workout_plans'] += 1
                
                # 2. 插入 workout_exercises 和 workout_sets
                exercises = plan.get('exercises', [])
                for idx, exercise in enumerate(exercises):
                    exercise_record = {
                        'workout_plan_id': doc['id'],
                        'exercise_id': exercise.get('exerciseId'),
                        'exercise_name': exercise.get('exerciseName'),
                        'order_index': idx,
                        'completed': exercise.get('completed', False),
                        'rest_time': exercise.get('restTime', 90),
                        'notes': exercise.get('notes')
                    }
                    
                    ex_response = supabase.table("workout_exercises").insert([exercise_record]).execute()
                    workout_exercise_id = ex_response.data[0]['id']
                    self.stats['workout_exercises'] += 1
                    
                    # 3. 插入 sets
                    sets = exercise.get('sets', [])
                    if isinstance(sets, list):
                        sets_batch = []
                        for set_data in sets:
                            if isinstance(set_data, dict):
                                sets_batch.append({
                                    'workout_exercise_id': workout_exercise_id,
                                    'set_number': set_data.get('setNumber'),
                                    'reps': set_data.get('reps'),
                                    'weight': set_data.get('weight'),
                                    'completed': set_data.get('completed', False),
                                    'timestamp': set_data.get('timestamp'),
                                    'note': set_data.get('note')
                                })
                        
                        if sets_batch:
                            supabase.table("workout_sets").insert(sets_batch).execute()
                            self.stats['workout_sets'] += len(sets_batch)
                
                print(f"  ✅ 計劃 '{plan.get('title')}' ({len(exercises)} 動作)")
                
            except Exception as e:
                error_msg = f"遷移計劃失敗 ({doc['id']}): {e}"
                print(f"  ❌ {error_msg}")
                self.stats['errors'].append(error_msg)
    
    def migrate_body_parts(self, body_parts_data: Dict):
        """遷移身體部位"""
        print("\n🦴 遷移身體部位...")
        
        if not body_parts_data or 'sample_documents' not in body_parts_data:
            print("  ⚠️  無身體部位資料")
            return
        
        batch = []
        for doc in body_parts_data['sample_documents']:
            part = doc['data']
            batch.append({
                'id': doc['id'],
                'name': part.get('name'),
                'description': part.get('description'),
                'count': part.get('count', 0)
            })
        
        if batch:
            try:
                supabase.table("body_parts").upsert(batch).execute()
                self.stats['body_parts'] = len(batch)
                print(f"  ✅ 成功遷移 {len(batch)} 個身體部位")
            except Exception as e:
                error_msg = f"遷移身體部位失敗: {e}"
                print(f"  ❌ {error_msg}")
                self.stats['errors'].append(error_msg)
    
    def migrate_exercise_types(self, types_data: Dict):
        """遷移動作類型"""
        print("\n🏋️ 遷移動作類型...")
        
        if not types_data or 'sample_documents' not in types_data:
            print("  ⚠️  無動作類型資料")
            return
        
        batch = []
        for doc in types_data['sample_documents']:
            type_data = doc['data']
            batch.append({
                'id': doc['id'],
                'name': type_data.get('name'),
                'description': type_data.get('description'),
                'count': type_data.get('count', 0)
            })
        
        if batch:
            try:
                supabase.table("exercise_types").upsert(batch).execute()
                self.stats['exercise_types'] = len(batch)
                print(f"  ✅ 成功遷移 {len(batch)} 個動作類型")
            except Exception as e:
                error_msg = f"遷移動作類型失敗: {e}"
                print(f"  ❌ {error_msg}")
                self.stats['errors'].append(error_msg)
    
    def migrate_notes(self, notes_data: Dict):
        """遷移筆記"""
        print("\n📝 遷移筆記...")
        
        if not notes_data or 'sample_documents' not in notes_data:
            print("  ⚠️  無筆記資料")
            return
        
        batch = []
        for doc in notes_data['sample_documents']:
            note = doc['data']
            batch.append({
                'id': doc['id'],
                'user_id': note.get('userId'),
                'title': note.get('title'),
                'text_content': note.get('textContent'),
                'drawing_points': note.get('drawingPoints'),
                'created_at': self.parse_timestamp(note.get('createdAt')),
                'updated_at': self.parse_timestamp(note.get('updatedAt'))
            })
        
        if batch:
            try:
                supabase.table("notes").upsert(batch).execute()
                self.stats['notes'] = len(batch)
                print(f"  ✅ 成功遷移 {len(batch)} 筆筆記")
            except Exception as e:
                error_msg = f"遷移筆記失敗: {e}"
                print(f"  ❌ {error_msg}")
                self.stats['errors'].append(error_msg)
    
    def parse_timestamp(self, ts):
        """解析 Firestore timestamp"""
        if not ts:
            return None
        if isinstance(ts, str):
            # 已經是 ISO 格式
            return ts
        if isinstance(ts, int):
            # Unix timestamp (ms)
            return datetime.fromtimestamp(ts / 1000).isoformat()
        return None
    
    def print_stats(self):
        """輸出遷移統計"""
        print("\n" + "=" * 60)
        print("📊 遷移統計")
        print("=" * 60)
        print(f"用戶:         {self.stats['users']}")
        print(f"動作庫:       {self.stats['exercises']}")
        print(f"訓練計劃:     {self.stats['workout_plans']}")
        print(f"訓練動作:     {self.stats['workout_exercises']}")
        print(f"組數記錄:     {self.stats['workout_sets']}")
        print(f"身體部位:     {self.stats['body_parts']}")
        print(f"動作類型:     {self.stats['exercise_types']}")
        print(f"筆記:         {self.stats['notes']}")
        print(f"錯誤數:       {len(self.stats['errors'])}")
        
        if self.stats['errors']:
            print("\n❌ 錯誤清單:")
            for error in self.stats['errors']:
                print(f"  - {error}")
        
        print("=" * 60)

def main():
    """主程式入口"""
    if len(sys.argv) < 2:
        print("使用方式: python migrate_to_supabase.py <json_file_path>")
        print("範例: python scripts/migrate_to_supabase.py data/database/database_export_for_migration.json")
        sys.exit(1)
    
    json_file = sys.argv[1]
    
    if not os.path.exists(json_file):
        print(f"❌ 錯誤：檔案不存在 {json_file}")
        sys.exit(1)
    
    migrator = DataMigrator(json_file)
    migrator.run()
    
    print("\n✅ 遷移完成！")

if __name__ == "__main__":
    main()

