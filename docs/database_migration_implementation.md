# StrengthWise 資料庫遷移實作指南

**狀態**: 🚀 執行中  
**目標**: 從 Firebase Firestore 遷移到 Supabase PostgreSQL  
**開始日期**: 2025-12-25

---

## 🎯 執行摘要

基於 `docs/database_migration_analysis.md` 的評估結果，我們決定採用 **完全遷移到 Supabase PostgreSQL** 的方案。本文檔記錄完整的實作步驟、技術細節和注意事項。

### 決策理由

1. **成本可預測**: Supabase Pro $25/月，支援到 10,000 活躍用戶
2. **完整 SQL 支援**: 複雜查詢、JOIN、聚合函數
3. **效能更好**: 索引優化、查詢計劃
4. **離線優先**: 配合 PowerSync 實現本地 SQLite 同步

---

## 📋 遷移路線圖

### 階段一：地基工程（Week 1-2）⏳ 進行中

#### 1.1 Supabase 專案設置
- [x] 創建 Supabase 專案
- [x] 取得 API Keys 和 連接資訊
- [ ] 設置環境變數管理
- [ ] 配置 Row Level Security (RLS)

#### 1.2 資料庫 Schema 設計
- [ ] 設計正規化的 PostgreSQL Schema
- [ ] 建立 Migration 腳本
- [ ] 定義外鍵關聯
- [ ] 建立索引策略

#### 1.3 資料遷移
- [ ] 撰寫 Python 遷移腳本
- [ ] 執行資料轉換（NoSQL → SQL）
- [ ] 驗證資料完整性
- [ ] 備份驗證

### 階段二：Flutter 整合（Week 3-4）
- [ ] 安裝 supabase-flutter SDK
- [ ] 重構 Service 層（使用 Supabase Client）
- [ ] 實作離線優先架構（SQLite + PowerSync）
- [ ] 測試與驗證

### 階段三：部署與驗證（Week 5）
- [ ] 灰度發布（部分用戶測試）
- [ ] 效能監控
- [ ] 錯誤處理完善
- [ ] 正式上線

---

## 🗄️ PostgreSQL Schema 設計

### 核心原則

1. **正規化**: 避免資料重複，使用外鍵關聯
2. **可擴展性**: 預留未來功能的欄位空間
3. **效能**: 合理的索引策略
4. **安全性**: Row Level Security (RLS) 確保資料隔離

### 表格設計

#### 1. users 表
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  age INTEGER,
  gender TEXT,
  height DECIMAL(5,2),
  weight DECIMAL(5,2),
  unit_system TEXT DEFAULT 'metric',
  is_coach BOOLEAN DEFAULT false,
  is_student BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 策略：用戶只能查看自己的資料
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id);
```

#### 2. exercises 表（動作庫）
```sql
CREATE TABLE exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  name_en TEXT,
  action_name TEXT,
  training_type TEXT,
  body_part TEXT,
  body_parts TEXT[], -- Array for multiple body parts
  specific_muscle TEXT,
  equipment TEXT,
  equipment_category TEXT,
  equipment_subcategory TEXT,
  joint_type TEXT,
  level1 TEXT,
  level2 TEXT,
  level3 TEXT,
  level4 TEXT,
  level5 TEXT,
  description TEXT,
  image_url TEXT,
  video_url TEXT,
  user_id UUID REFERENCES users(id), -- NULL = 系統內建，有值 = 用戶自定義
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引：常用查詢欄位
CREATE INDEX idx_exercises_training_type ON exercises(training_type);
CREATE INDEX idx_exercises_body_part ON exercises(body_part);
CREATE INDEX idx_exercises_user_id ON exercises(user_id);

-- RLS：系統動作所有人可見，自定義動作只有創建者可見
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "System exercises are viewable by everyone"
  ON exercises FOR SELECT
  USING (user_id IS NULL OR user_id = auth.uid());
```

#### 3. workout_plans 表（訓練計劃）
```sql
CREATE TABLE workout_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  trainee_id UUID NOT NULL REFERENCES users(id),
  creator_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  plan_type TEXT DEFAULT 'self',
  ui_plan_type TEXT,
  scheduled_date TIMESTAMPTZ NOT NULL,
  completed BOOLEAN DEFAULT false,
  completed_date TIMESTAMPTZ,
  training_time TIMESTAMPTZ,
  total_exercises INTEGER DEFAULT 0,
  total_sets INTEGER DEFAULT 0,
  total_volume DECIMAL(10,2) DEFAULT 0,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引：高頻查詢欄位
CREATE INDEX idx_workout_plans_user_id ON workout_plans(user_id);
CREATE INDEX idx_workout_plans_trainee_id ON workout_plans(trainee_id);
CREATE INDEX idx_workout_plans_scheduled_date ON workout_plans(scheduled_date);
CREATE INDEX idx_workout_plans_completed ON workout_plans(completed);

-- RLS：用戶可以查看自己作為 trainee 或 creator 的計劃
ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own workout plans"
  ON workout_plans FOR SELECT
  USING (trainee_id = auth.uid() OR creator_id = auth.uid());
```

#### 4. workout_exercises 表（訓練計劃中的動作）
```sql
CREATE TABLE workout_exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_plan_id UUID NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
  exercise_id UUID NOT NULL REFERENCES exercises(id),
  exercise_name TEXT NOT NULL, -- 冗餘欄位，避免 JOIN
  order_index INTEGER NOT NULL,
  completed BOOLEAN DEFAULT false,
  rest_time INTEGER DEFAULT 90, -- 秒
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_workout_exercises_plan_id ON workout_exercises(workout_plan_id);
CREATE INDEX idx_workout_exercises_order ON workout_exercises(workout_plan_id, order_index);

-- RLS：繼承 workout_plans 的權限
ALTER TABLE workout_exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view exercises in own plans"
  ON workout_exercises FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM workout_plans
      WHERE workout_plans.id = workout_exercises.workout_plan_id
      AND (workout_plans.trainee_id = auth.uid() OR workout_plans.creator_id = auth.uid())
    )
  );
```

#### 5. workout_sets 表（組數記錄）
```sql
CREATE TABLE workout_sets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_exercise_id UUID NOT NULL REFERENCES workout_exercises(id) ON DELETE CASCADE,
  set_number INTEGER NOT NULL,
  reps INTEGER,
  weight DECIMAL(6,2),
  completed BOOLEAN DEFAULT false,
  timestamp TIMESTAMPTZ,
  note TEXT,
  rpe INTEGER, -- Rate of Perceived Exertion (1-10)
  set_type TEXT DEFAULT 'working', -- 'warmup', 'working', 'drop_set', 'failure'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_workout_sets_exercise_id ON workout_sets(workout_exercise_id);

-- RLS：繼承權限
ALTER TABLE workout_sets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view sets in own exercises"
  ON workout_sets FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM workout_exercises we
      JOIN workout_plans wp ON we.workout_plan_id = wp.id
      WHERE we.id = workout_sets.workout_exercise_id
      AND (wp.trainee_id = auth.uid() OR wp.creator_id = auth.uid())
    )
  );
```

#### 6. body_parts 表
```sql
CREATE TABLE body_parts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 公開可讀
ALTER TABLE body_parts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Body parts are viewable by everyone"
  ON body_parts FOR SELECT TO authenticated
  USING (true);
```

#### 7. exercise_types 表
```sql
CREATE TABLE exercise_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 公開可讀
ALTER TABLE exercise_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Exercise types are viewable by everyone"
  ON exercise_types FOR SELECT TO authenticated
  USING (true);
```

#### 8. notes 表
```sql
CREATE TABLE notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT,
  text_content TEXT,
  drawing_points JSONB, -- 儲存繪圖資料
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_notes_user_id ON notes(user_id);

-- RLS
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own notes"
  ON notes FOR ALL
  USING (user_id = auth.uid());
```

---

## 🔧 資料遷移腳本

### 環境設置

#### 1. 安裝依賴
```bash
pip install supabase python-dotenv ijson
```

#### 2. 環境變數配置

創建 `.env` 檔案（⚠️ 不要提交到 git）：
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

創建 `.env.example` 模板：
```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

### 遷移腳本架構

創建 `scripts/migrate_to_supabase.py`：

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StrengthWise 資料庫遷移腳本
從 Firebase Firestore (JSON) 遷移到 Supabase PostgreSQL
"""

import json
import os
import sys
from typing import Dict, List, Any
from datetime import datetime
from supabase import create_client, Client
from dotenv import load_dotenv
import ijson

# 載入環境變數
load_dotenv()

# 初始化 Supabase Client
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("❌ 錯誤：請設置 SUPABASE_URL 和 SUPABASE_SERVICE_ROLE_KEY 環境變數")
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
```

---

## 🔐 安全性配置

### 1. 環境變數管理

**⚠️ 重要**：Secret Key 絕對不能提交到 git！

1. 將 `.env` 加入 `.gitignore`
2. 只提交 `.env.example` 作為模板
3. 在部署環境中設置環境變數

### 2. Row Level Security (RLS)

已在上述 Schema 中配置，確保：
- 用戶只能存取自己的資料
- 系統資料（動作庫、身體部位）所有人可讀
- 教練可以查看學員的訓練計劃

---

## 📱 Flutter 整合

### 1. 安裝依賴

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  flutter_dotenv: ^5.0.2
```

### 2. 初始化 Supabase

```dart
// lib/main.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 載入環境變數
  await dotenv.load(fileName: ".env");
  
  // 初始化 Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(MyApp());
}

// 全域 Supabase Client
final supabase = Supabase.instance.client;
```

### 3. 重構 Service 層

範例：`WorkoutService`

```dart
// lib/services/workout_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutService {
  final SupabaseClient _client = Supabase.instance.client;
  
  /// 取得用戶的訓練計劃
  Future<List<WorkoutPlan>> getUserWorkoutPlans(String userId) async {
    final response = await _client
        .from('workout_plans')
        .select('''
          *,
          workout_exercises (
            *,
            workout_sets (*)
          )
        ''')
        .eq('trainee_id', userId)
        .order('scheduled_date', ascending: false);
    
    return (response as List)
        .map((json) => WorkoutPlan.fromJson(json))
        .toList();
  }
  
  /// 創建訓練計劃
  Future<void> createWorkoutPlan(WorkoutPlan plan) async {
    await _client.from('workout_plans').insert(plan.toJson());
  }
  
  /// 更新組數記錄
  Future<void> updateSet(String setId, {int? reps, double? weight}) async {
    await _client
        .from('workout_sets')
        .update({
          if (reps != null) 'reps': reps,
          if (weight != null) 'weight': weight,
          'completed': true,
        })
        .eq('id', setId);
  }
}
```

---

## ⚡ 效能優化

### 1. 索引策略

已在 Schema 中定義，確保常用查詢高效：
- `workout_plans` 的 `trainee_id` + `scheduled_date`
- `exercises` 的 `training_type` + `body_part`

### 2. 查詢優化

使用 `.select()` 的 nested query 減少往返次數：

```dart
// ✅ 好：一次查詢取得完整計劃
.select('*, workout_exercises(*, workout_sets(*))')

// ❌ 壞：多次查詢
final plan = await getPlan();
for (exercise in plan.exercises) {
  final sets = await getSets(exercise.id); // N+1 問題
}
```

### 3. 離線優先（未來）

可選整合 PowerSync 實現本地 SQLite 同步。

---

## ✅ 驗證清單

- [ ] Schema 創建成功
- [ ] RLS 策略測試通過
- [ ] 資料遷移腳本執行成功
- [ ] 資料完整性驗證（筆數、欄位）
- [ ] Flutter 整合測試
- [ ] 效能測試（查詢速度）
- [ ] 備份原始 Firestore 資料

---

## 📚 參考資源

- [Supabase 官方文檔](https://supabase.com/docs)
- [Supabase Flutter SDK](https://supabase.com/docs/reference/dart/introduction)
- [從 Firebase 遷移到 Supabase](https://supabase.com/docs/guides/migrations/firebase)
- [PostgreSQL 索引優化](https://www.postgresql.org/docs/current/indexes.html)

---

**更新日期**: 2025-12-25  
**狀態**: 🚀 執行中

