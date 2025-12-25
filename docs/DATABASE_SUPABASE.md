# StrengthWise - Supabase PostgreSQL 資料庫設計

> 完整的 Supabase PostgreSQL 資料庫架構文檔

**最後更新**：2024年12月25日

---

## 📊 資料庫架構總覽

StrengthWise 已完全遷移到 **Supabase PostgreSQL**，使用以下架構：

```
Supabase PostgreSQL
├── 核心表格（10 個）
│   ├── users              - 用戶資料
│   ├── exercises          - 系統動作庫（794 個）
│   ├── custom_exercises   - 自訂動作
│   ├── workout_plans      - 訓練計劃（包含記錄）
│   ├── workout_templates  - 訓練模板
│   ├── notes             - 筆記
│   ├── bookings          - 預約
│   ├── available_slots   - 可預約時段
│   ├── notifications     - 通知
│   └── booking_history   - 預約歷史
│
├── 元數據表格（4 個）
│   ├── body_parts        - 身體部位（8 個）
│   ├── exercise_types    - 訓練類型（3 個）
│   ├── equipments        - 器材（21 個）
│   └── joint_types       - 關節類型（2 個）
│
└── 認證系統
    └── auth.users        - Supabase Auth（UUID 主鍵）
```

---

## 🗄️ 核心表格設計

### 1. users - 用戶資料

```sql
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  photo_url TEXT,
  bio TEXT,
  birthday DATE,
  unit_system TEXT DEFAULT 'metric',
  is_coach BOOLEAN DEFAULT FALSE,
  is_student BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**重要欄位說明**：
- `id`: UUID（關聯到 Supabase Auth）
- `is_coach` / `is_student`: 角色標記（向後相容舊的 isTrainer/isTrainee）
- `unit_system`: 單位系統（metric/imperial）

**RLS 策略**：
- 用戶可以讀取和更新自己的資料
- 教練可以查看學員資料

---

### 2. exercises - 系統動作庫

```sql
CREATE TABLE IF NOT EXISTS public.exercises (
  id TEXT PRIMARY KEY,  -- Firestore 相容 ID（20 字符）
  name TEXT NOT NULL,
  action_name TEXT,
  training_type TEXT,
  body_parts JSONB DEFAULT '[]'::jsonb,
  body_part TEXT,
  specific_muscle TEXT,
  equipment TEXT,
  equipment_category TEXT,
  equipment_subcategory TEXT,
  joint_type TEXT,
  muscle_groups JSONB DEFAULT '[]'::jsonb,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 索引優化
  CONSTRAINT exercises_name_unique UNIQUE (name, user_id)
);

-- 全文搜尋索引
CREATE INDEX idx_exercises_name_gin ON public.exercises USING gin(to_tsvector('simple', name));
CREATE INDEX idx_exercises_training_type ON public.exercises (training_type);
CREATE INDEX idx_exercises_body_part ON public.exercises (body_part);
```

**重要欄位說明**：
- `id`: TEXT 類型（20 字符 Firestore ID，例如：`0A5921MGWAyUv7fXcA29`）
- `training_type`: 訓練類型（重訓、有氧、伸展）
- `body_part`: 主要身體部位
- `specific_muscle`: 特定肌群
- `equipment_category`: 器材類別（自由重量、機械式、徒手、功能性訓練）
- `equipment_subcategory`: 器材子類別（啞鈴、槓鈴、Cable 滑輪等）
- `user_id`: NULL = 系統動作，有值 = 自訂動作

**RLS 策略**：
- 所有人可讀取系統動作（`user_id IS NULL`）
- 用戶只能讀寫自己的自訂動作

**資料統計**：
- 系統動作：794 個
- 訓練類型：重訓 93.7%、伸展 3.8%、有氧 2.5%
- 器材類別：徒手 33.1%、機械式 32.6%、自由重量 31.4%

---

### 3. custom_exercises - 自訂動作

```sql
CREATE TABLE IF NOT EXISTS public.custom_exercises (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  training_type TEXT,
  body_parts JSONB DEFAULT '[]'::jsonb,
  equipment TEXT,
  muscle_groups JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**重要欄位說明**：
- `id`: UUID（Supabase 自動生成）
- `user_id`: 創建者（必須）
- 欄位結構與 `exercises` 表相似，簡化版本

**RLS 策略**：
- 用戶只能讀寫自己的自訂動作

---

### 4. workout_plans - 訓練計劃（統一集合）

```sql
CREATE TABLE IF NOT EXISTS public.workout_plans (
  id TEXT PRIMARY KEY,  -- Firestore 相容 ID（20 字符）
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  trainee_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  creator_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  scheduled_date TIMESTAMPTZ,
  completed BOOLEAN DEFAULT FALSE,
  completed_date TIMESTAMPTZ,
  exercises JSONB DEFAULT '[]'::jsonb,  -- 訓練動作（JSON 格式）
  plan_type TEXT DEFAULT 'personal',  -- personal / trainer
  training_time INTEGER,  -- 訓練時長（分鐘）
  total_exercises INTEGER DEFAULT 0,
  total_sets INTEGER DEFAULT 0,
  total_volume DOUBLE PRECISION DEFAULT 0,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引優化
CREATE INDEX idx_workout_plans_trainee ON public.workout_plans (trainee_id, scheduled_date);
CREATE INDEX idx_workout_plans_creator ON public.workout_plans (creator_id, scheduled_date);
CREATE INDEX idx_workout_plans_completed ON public.workout_plans (completed, scheduled_date);
```

**重要欄位說明**：
- `id`: TEXT 類型（20 字符 Firestore ID）
- `completed`: `false` = 未完成的訓練計劃，`true` = 已完成的訓練記錄
- `trainee_id`: 受訓者（單機版 = 自己）
- `creator_id`: 創建者（單機版 = 自己，教練版 = 教練）
- `exercises`: JSONB 格式，存儲動作配置（組數、次數、重量等）

**exercises JSONB 結構**：
```json
[
  {
    "id": "uuid-v4",  // WorkoutExercise 的臨時 ID（UUID）
    "exerciseId": "0A5921MGWAyUv7fXcA29",  // 關聯到 exercises 表的真實 ID（20 字符）
    "name": "槓鈴臥推",
    "sets": 4,
    "reps": 10,
    "weight": 60,
    "restTime": 90,
    "setTargets": [
      {"reps": 10, "weight": 60},
      {"reps": 10, "weight": 60},
      {"reps": 8, "weight": 65},
      {"reps": 8, "weight": 65}
    ],
    "notes": "注意肩胛骨後收"
  }
]
```

**RLS 策略**：
- 用戶可以讀寫自己的訓練計劃（`trainee_id = auth.uid()`）
- 教練可以讀寫學員的訓練計劃（`creator_id = auth.uid()`）

---

### 5. workout_templates - 訓練模板

```sql
CREATE TABLE IF NOT EXISTS public.workout_templates (
  id TEXT PRIMARY KEY,  -- Firestore 相容 ID（20 字符）
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  plan_type TEXT DEFAULT 'personal',
  exercises JSONB DEFAULT '[]'::jsonb,
  training_time INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workout_templates_user ON public.workout_templates (user_id);
```

**重要欄位說明**：
- `id`: TEXT 類型（20 字符 Firestore ID）
- `exercises`: JSONB 格式（同 workout_plans）
- 不包含 `scheduled_date`、`trainee_id` 等計劃專屬欄位

**用途**：
- 快速藍圖，用於創建訓練計劃
- 不包含每組的具體目標（創建計劃時補充）

**RLS 策略**：
- 用戶只能讀寫自己的模板

---

### 6. notes - 筆記

```sql
CREATE TABLE IF NOT EXISTS public.notes (
  id TEXT PRIMARY KEY,  -- Firestore 相容 ID（20 字符）
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  text_content TEXT,
  drawing_points JSONB DEFAULT '[]'::jsonb,  -- 繪圖數據
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notes_user ON public.notes (user_id, created_at DESC);
```

**重要欄位說明**：
- `drawing_points`: JSONB 格式，存儲繪圖路徑

**RLS 策略**：
- 用戶只能讀寫自己的筆記

---

### 7-10. 預約系統表格（bookings, available_slots, notifications, booking_history）

```sql
-- 預約
CREATE TABLE IF NOT EXISTS public.bookings (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  coach_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  slot_id TEXT,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending',  -- pending, confirmed, cancelled, completed, rejected
  date_time TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER,
  cancelled_by TEXT,
  cancelled_at TIMESTAMPTZ,
  confirmed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 可預約時段
CREATE TABLE IF NOT EXISTS public.available_slots (
  id TEXT PRIMARY KEY,
  coach_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  date_time TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER NOT NULL,
  is_booked BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 通知
CREATE TABLE IF NOT EXISTS public.notifications (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  message TEXT NOT NULL,
  booking_id TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 預約歷史
CREATE TABLE IF NOT EXISTS public.booking_history (
  id TEXT PRIMARY KEY,
  original_id TEXT NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  coach_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  status TEXT,
  date_time TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_by UUID REFERENCES public.users(id) ON DELETE SET NULL
);
```

**說明**：預約系統表格已遷移完成，但在單機版中暫未使用。

---

## 📦 元數據表格

### body_parts - 身體部位（8 個）

```sql
CREATE TABLE IF NOT EXISTS public.body_parts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**數據**：胸、背、肩、腿、手、核心、全身、臀

---

### exercise_types - 訓練類型（3 個）

```sql
CREATE TABLE IF NOT EXISTS public.exercise_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**數據**：重訓、有氧、伸展

---

### equipments - 器材（21 個）

```sql
CREATE TABLE IF NOT EXISTS public.equipments (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  category TEXT,
  subcategory TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**數據示例**：啞鈴、槓鈴、Cable 滑輪、固定器械、跑步機等

---

### joint_types - 關節類型（2 個）

```sql
CREATE TABLE IF NOT EXISTS public.joint_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**數據**：單關節、多關節

---

## 🔐 Row Level Security (RLS) 策略

所有表格都啟用 RLS，確保數據安全：

### 通用策略模式

```sql
-- 用戶只能讀寫自己的資料
CREATE POLICY "Users can view their own data" 
  ON table_name FOR SELECT 
  TO authenticated 
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own data" 
  ON table_name FOR INSERT 
  TO authenticated 
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own data" 
  ON table_name FOR UPDATE 
  TO authenticated 
  USING (user_id = auth.uid()) 
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete their own data" 
  ON table_name FOR DELETE 
  TO authenticated 
  USING (user_id = auth.uid());
```

### 特殊策略

**1. exercises 表格**（系統動作 + 自訂動作）
```sql
-- 匿名用戶可以讀取系統動作
CREATE POLICY "System exercises are viewable by anonymous users" 
  ON exercises FOR SELECT 
  TO anon 
  USING (user_id IS NULL);

-- 認證用戶可以讀取所有動作
CREATE POLICY "Authenticated users can view all exercises" 
  ON exercises FOR SELECT 
  TO authenticated 
  USING (user_id IS NULL OR user_id = auth.uid());
```

**2. workout_plans 表格**（訓練計劃）
```sql
-- 用戶可以查看自己的訓練計劃（作為受訓者或創建者）
CREATE POLICY "Users can view their own workout plans" 
  ON workout_plans FOR SELECT 
  TO authenticated 
  USING (trainee_id = auth.uid() OR creator_id = auth.uid());
```

---

## 🔄 資料遷移歷史

### 階段一：系統資料遷移（2024-12-25）

從 Firestore 成功遷移：
- ✅ exercises: 794 個動作
- ✅ body_parts: 8 個身體部位
- ✅ exercise_types: 3 個訓練類型
- ✅ equipments: 21 個器材
- ✅ joint_types: 2 個關節類型

**總計**：828 個文檔，0 個錯誤 ✅

### 階段二：用戶資料遷移（2024-12-25）

- ✅ 新用戶使用 Supabase Auth 註冊
- ✅ 現有 Firebase 用戶保持不變（向後相容）
- ✅ PostgreSQL Trigger 自動創建用戶資料

### 階段三：應用層重構（2024-12-25）

- ✅ 8 個 Service 層重構（Supabase 版本）
- ✅ 8 個 Model 層更新（`fromSupabase()` 方法）
- ✅ 8 個 UI 頁面重構（使用 Supabase Service）

---

## 🔍 查詢範例

### 1. 查詢用戶的訓練計劃

```dart
// 查詢作為受訓者的計劃（未完成）
final plans = await Supabase.instance.client
  .from('workout_plans')
  .select()
  .eq('trainee_id', userId)
  .eq('completed', false)
  .order('scheduled_date', ascending: true);

// 查詢已完成的訓練記錄
final records = await Supabase.instance.client
  .from('workout_plans')
  .select()
  .eq('trainee_id', userId)
  .eq('completed', true)
  .order('completed_date', ascending: false);
```

### 2. 查詢動作庫（5 層篩選）

```dart
// 1. 訓練類型
final exercises = await Supabase.instance.client
  .from('exercises')
  .select()
  .eq('training_type', '重訓');

// 2. + 身體部位
final exercises = await Supabase.instance.client
  .from('exercises')
  .select()
  .eq('training_type', '重訓')
  .contains('body_parts', ['胸']);

// 3. + 特定肌群
final exercises = await Supabase.instance.client
  .from('exercises')
  .select()
  .eq('training_type', '重訓')
  .contains('body_parts', ['胸'])
  .eq('specific_muscle', '上胸');

// 4. + 器材類別
final exercises = await Supabase.instance.client
  .from('exercises')
  .select()
  .eq('training_type', '重訓')
  .contains('body_parts', ['胸'])
  .eq('specific_muscle', '上胸')
  .eq('equipment_category', '自由重量');

// 5. + 器材子類別
final exercises = await Supabase.instance.client
  .from('exercises')
  .select()
  .eq('training_type', '重訓')
  .contains('body_parts', ['胸'])
  .eq('specific_muscle', '上胸')
  .eq('equipment_category', '自由重量')
  .eq('equipment_subcategory', '啞鈴');
```

### 3. 創建訓練計劃

```dart
// 生成 Firestore 相容 ID（20 字符）
final id = generateFirestoreId();

// 創建訓練計劃
await Supabase.instance.client
  .from('workout_plans')
  .insert({
    'id': id,
    'user_id': userId,
    'trainee_id': userId,
    'creator_id': userId,
    'title': '今日訓練',
    'scheduled_date': DateTime.now().toIso8601String(),
    'completed': false,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'plan_type': 'personal',
  });
```

---

## 🎯 最佳實踐

### 1. 型別安全

✅ **必須**：所有資料庫操作透過 Model 類別的 `.fromSupabase()` 和 `.toMap()` 方法

```dart
// ✅ 正確（Supabase）
final record = WorkoutRecord.fromSupabase(data);
await workoutService.createRecord(record);

// ❌ 錯誤
await supabase.from('workout_plans').insert({'title': 'Test'});
```

### 2. Snake_case 轉換

Supabase 使用 `snake_case`，Dart 使用 `camelCase`：

```dart
factory UserModel.fromSupabase(Map<String, dynamic> json) {
  return UserModel(
    uid: json['id'] as String,  // id → uid
    email: json['email'] as String,
    displayName: json['display_name'] as String?,  // display_name → displayName
    isCoach: json['is_coach'] as bool? ?? false,  // is_coach → isCoach
    // ...
  );
}
```

### 3. ID 生成邏輯

```dart
// Firestore 相容 ID（20 字符）
import 'dart:math';

String generateFirestoreId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random.secure();
  final buffer = StringBuffer();

  for (int i = 0; i < 20; i++) {
    buffer.write(chars[random.nextInt(chars.length)]);
  }

  return buffer.toString();
}
```

### 4. 錯誤處理

```dart
try {
  await _workoutService.createRecord(record);
} catch (e) {
  if (e is PostgrestException) {
    // 處理 Supabase 特定錯誤
    _errorService.logError('Supabase 錯誤: ${e.message}', type: 'PostgrestError');
  } else {
    _errorService.logError('創建記錄失敗: $e', type: 'WorkoutServiceError');
  }
  rethrow;
}
```

---

## 📊 效能優化

### 1. 索引策略

已創建的索引：
- `exercises`: `name` (GIN 全文搜尋)、`training_type`、`body_part`
- `workout_plans`: `trainee_id + scheduled_date`、`completed + scheduled_date`
- `workout_templates`: `user_id`
- `notes`: `user_id + created_at DESC`

### 2. 查詢優化

```dart
// ✅ 好：使用索引查詢
final plans = await supabase
  .from('workout_plans')
  .select()
  .eq('trainee_id', userId)  // 使用索引
  .gte('scheduled_date', today)
  .order('scheduled_date');

// ❌ 避免：全表掃描
final plans = await supabase
  .from('workout_plans')
  .select()
  .filter('title', 'ilike', '%胸%');  // 沒有索引，慢
```

### 3. 批次操作

```dart
// ✅ 好：批次插入
final exercises = [...];
await supabase
  .from('exercises')
  .insert(exercises);  // 一次插入多筆

// ❌ 避免：逐筆插入
for (var exercise in exercises) {
  await supabase.from('exercises').insert(exercise);  // N 次查詢
}
```

---

## 🔧 維護指南

### 資料庫備份

Supabase 自動每日備份，也可手動備份：

```bash
# 使用 Supabase CLI
supabase db dump -f backup.sql
```

### Schema 遷移

使用 SQL 遷移文件：

```sql
-- migrations/005_add_new_column.sql
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS new_field TEXT;
```

執行遷移：
```bash
supabase db push
```

---

## 📚 相關文檔

- `AGENTS.md` - Supabase 使用說明
- `docs/DEVELOPMENT_STATUS.md` - 遷移歷史
- `migrations/*.sql` - SQL 遷移腳本
- `lib/services/*_supabase.dart` - Supabase Service 實作

---

**遷移完成時間**：2024年12月25日  
**總遷移數據**：828 個文檔 + 8 個頁面重構  
**遷移成功率**：100% ✅

