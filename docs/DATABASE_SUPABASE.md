# StrengthWise - 資料庫設計

> Supabase PostgreSQL 資料庫架構與最佳實踐

**最後更新**：2026-01-04（v2.9）

---

## 📊 架構總覽

```
Supabase PostgreSQL（21 個表格）
├── 核心表格（7 個）
│   ├── users              - 用戶資料
│   ├── exercises          - 系統動作庫（794 個）
│   ├── custom_exercises   - 自訂動作
│   ├── workout_plans      - 訓練計劃/記錄
│   ├── workout_templates  - 訓練模板
│   ├── body_data          - 身體數據
│   └── notes              - 個人筆記
│
├── 元數據表格（2 個）
│   ├── body_parts         - 身體部位（8 個）
│   └── exercise_types     - 訓練類型（3 個）
│
├── 教練學員系統（6 個）
│   ├── coaching_relationships - 教練學員關係
│   ├── availability_slots     - 教練可用時段
│   ├── appointments           - 預約記錄
│   ├── session_notes          - SOAP 課程筆記
│   ├── client_availability    - 學員時間偏好
│   └── coaches                - 教練公開檔案 ⭐ v2.9
│
├── 邀請碼系統（1 個）
│   └── invite_codes       - 一次性邀請碼
│
├── 健康評估系統（3 個）
│   ├── health_assessments        - PAR-Q+ 問卷
│   ├── coach_assessment_notes    - 教練備註（私有）
│   └── coach_display_preferences - 顯示偏好
│
└── 優化表格（2 個）
    ├── daily_workout_summary - 每日訓練統計
    └── personal_records      - 個人記錄彙總
```

---

## 🗄️ 表格 Schema

### 1. users - 用戶資料

```sql
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  nickname TEXT,                    -- 暱稱
  photo_url TEXT,
  bio TEXT,
  birthday DATE,
  height DOUBLE PRECISION,          -- 身高（公分）
  weight DOUBLE PRECISION,          -- 體重（公斤）
  gender TEXT,                      -- male/female/other
  gender_visible BOOLEAN DEFAULT TRUE,
  unit_system TEXT DEFAULT 'metric',
  is_coach BOOLEAN DEFAULT FALSE,
  is_student BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**重要欄位**：
- `id`：UUID，關聯 Supabase Auth
- `is_coach` / `is_student`：角色標記
- `unit_system`：單位系統（metric/imperial）

---

### 2. exercises - 系統動作庫

```sql
CREATE TABLE public.exercises (
  id TEXT PRIMARY KEY,              -- Firestore 相容 ID（20 字符）
  name TEXT NOT NULL,               -- 中文名稱
  name_en TEXT,                     -- 英文名稱
  training_type TEXT,               -- 訓練類型
  training_type_en TEXT,
  body_part TEXT,                   -- 主要身體部位
  body_part_en TEXT,
  body_parts TEXT[],                -- 多身體部位（陣列）
  specific_muscle TEXT,             -- 特定肌群
  equipment TEXT,                   -- 器材
  equipment_category TEXT,          -- 器材類別
  equipment_subcategory TEXT,       -- 器材子類別
  action_name TEXT,
  action_name_en TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_exercises_name_gin ON exercises USING gin(to_tsvector('simple', name));
CREATE INDEX idx_exercises_training_type ON exercises(training_type);
CREATE INDEX idx_exercises_body_part ON exercises(body_part);
```

**資料統計**：794 個動作（阻力 744、活動度 30、心肺 20）

---

### 3. custom_exercises - 自訂動作

```sql
CREATE TABLE public.custom_exercises (
  id TEXT PRIMARY KEY,              -- Firestore 相容 ID
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  body_part TEXT NOT NULL,          -- 必填（用於統計）
  equipment TEXT DEFAULT '徒手',
  description TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_custom_exercises_user_id ON custom_exercises(user_id);
```

---

### 4. workout_plans - 訓練計劃/記錄

```sql
CREATE TABLE public.workout_plans (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  trainee_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  creator_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  scheduled_date TIMESTAMPTZ,
  completed BOOLEAN DEFAULT FALSE,  -- false=計劃, true=記錄
  completed_date TIMESTAMPTZ,
  exercises JSONB DEFAULT '[]'::jsonb,
  plan_type TEXT DEFAULT 'personal',
  training_time INTEGER,            -- 訓練時長（分鐘）
  total_exercises INTEGER DEFAULT 0,
  total_sets INTEGER DEFAULT 0,
  total_volume DOUBLE PRECISION DEFAULT 0,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_workout_plans_trainee ON workout_plans(trainee_id, scheduled_date);
CREATE INDEX idx_workout_plans_creator ON workout_plans(creator_id, scheduled_date);
CREATE INDEX idx_workout_plans_completed ON workout_plans(completed, scheduled_date);
```

**exercises JSONB 結構**：
```json
[{
  "id": "uuid-v4",
  "exerciseId": "0A5921MGWAyUv7fXcA29",
  "name": "槓鈴臥推",
  "sets": 4,
  "reps": 10,
  "weight": 60,
  "restTime": 90,
  "setTargets": [{"reps": 10, "weight": 60}, ...],
  "notes": "注意肩胛骨後收"
}]
```

---

### 5. workout_templates - 訓練模板

```sql
CREATE TABLE public.workout_templates (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  plan_type TEXT DEFAULT 'personal',
  exercises JSONB DEFAULT '[]'::jsonb,
  training_time INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workout_templates_user ON workout_templates(user_id);
```

---

### 6. body_data - 身體數據

```sql
CREATE TABLE public.body_data (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  weight DOUBLE PRECISION,          -- 體重（公斤）
  body_fat_percentage DOUBLE PRECISION,
  muscle_mass DOUBLE PRECISION,
  bmi DOUBLE PRECISION,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_body_data_user_date ON body_data(user_id, date DESC);
```

---

### 7. notes - 個人筆記

```sql
CREATE TABLE public.notes (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  text_content TEXT,
  drawing_points JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notes_user ON notes(user_id, created_at DESC);
```

---

### 8. coaching_relationships - 教練學員關係

```sql
CREATE TABLE public.coaching_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending',  -- pending/active/archived/deleted
  coach_name TEXT,                  -- 教練名稱快照
  client_name TEXT,                 -- 學員名稱快照
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(coach_id, client_id)
);
```

---

### 9. availability_slots - 教練可用時段

```sql
CREATE TABLE public.availability_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  time_range TSTZRANGE NOT NULL,    -- PostgreSQL 時間範圍
  rrule TEXT,                       -- 週期性規則（RFC 5545）
  is_available BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  EXCLUDE USING GIST (coach_id WITH =, time_range WITH &&)  -- 防止重疊
);
```

---

### 10. appointments - 預約記錄

```sql
CREATE TABLE public.appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  slot_id UUID REFERENCES availability_slots(id),
  time_range TSTZRANGE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',  -- pending/confirmed/completed/cancelled
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 11. session_notes - SOAP 課程筆記

```sql
CREATE TABLE public.session_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  appointment_id UUID REFERENCES appointments(id),
  subjective TEXT,                  -- S: 主觀
  objective TEXT,                   -- O: 客觀
  assessment TEXT,                  -- A: 評估
  plan TEXT,                        -- P: 計劃
  photos TEXT[],                    -- 照片 URL 陣列
  drawing_data JSONB,               -- 手繪數據
  visibility TEXT DEFAULT 'private', -- private/shared
  coach_name TEXT,                  -- 教練名稱快照
  client_name TEXT,                 -- 學員名稱快照
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

### 12. coaches - 教練公開檔案 ⭐ v2.9

```sql
CREATE TABLE public.coaches (
  id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  
  -- 身份與品牌
  display_name TEXT,                    -- 顯示名稱（品牌名）
  headline TEXT,                        -- 專業頭銜
  bio TEXT,                             -- 專業介紹
  
  -- 專長與證照
  specialties JSONB DEFAULT '[]',       -- 專長標籤（預定義+自定義）
  certifications JSONB DEFAULT '[]',    -- 證照列表
  years_experience INTEGER DEFAULT 0,   -- 從業年資
  languages JSONB DEFAULT '["zh-TW"]',  -- 語言能力
  
  -- 服務資訊（未來計劃）
  service_types JSONB DEFAULT '[]',
  hourly_rate_min INTEGER,
  hourly_rate_max INTEGER,
  currency TEXT DEFAULT 'TWD',
  offers_free_consultation BOOLEAN DEFAULT FALSE,
  weekly_availability JSONB DEFAULT '{}',
  
  -- 地理位置（未來計劃）
  location_lat DOUBLE PRECISION,
  location_lng DOUBLE PRECISION,
  service_radius_km INTEGER,
  gym_access TEXT,
  
  -- 審核與市集（未來計劃）
  verified_status TEXT DEFAULT 'pending',
  slug TEXT UNIQUE,
  average_rating NUMERIC(3,2) DEFAULT 0,
  review_count INTEGER DEFAULT 0,
  
  -- 媒體（未來計劃）
  gallery_images JSONB DEFAULT '[]',
  social_links JSONB DEFAULT '{}',
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**重要欄位**：
- `id`：與 `users.id` 1:1 關聯
- `specialties`：JSONB 陣列，支援預定義標籤 + 自定義（`custom:` 前綴）
- `certifications`：JSONB 陣列，結構化儲存 `{org, name, year}`

**RLS 政策**：
- `coaches_select_own`：教練讀取自己（需 `is_coach=true`）
- `coaches_insert_own`：教練建立自己
- `coaches_update_own`：教練更新自己
- `coaches_select_by_student`：學員可查看自己教練的檔案

---

### 13. health_assessments - 健康評估問卷

```sql
CREATE TABLE public.health_assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- PAR-Q+ 問卷（7 題）
  parq_heart_condition BOOLEAN DEFAULT FALSE,
  parq_chest_pain_activity BOOLEAN DEFAULT FALSE,
  parq_chest_pain_rest BOOLEAN DEFAULT FALSE,
  parq_balance_consciousness BOOLEAN DEFAULT FALSE,
  parq_bone_joint BOOLEAN DEFAULT FALSE,
  parq_blood_pressure_medication BOOLEAN DEFAULT FALSE,
  parq_other_reasons BOOLEAN DEFAULT FALSE,
  
  -- 傷病史
  injury_history JSONB DEFAULT '[]'::jsonb,
  
  -- 生活型態
  occupation TEXT,
  activity_level TEXT,              -- sedentary/light/moderate/active/very_active
  sleep_hours DOUBLE PRECISION,
  stress_level TEXT,                -- low/moderate/high
  
  -- 訓練目標
  fitness_goals TEXT[],
  experience_level TEXT,            -- beginner/intermediate/advanced
  preferred_training_days INTEGER,
  
  -- 緊急聯絡人
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  emergency_contact_relationship TEXT,
  
  -- 免責聲明
  disclaimer_accepted BOOLEAN DEFAULT FALSE,
  disclaimer_accepted_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);
```

---

### 14. coach_assessment_notes - 教練評估備註

```sql
CREATE TABLE public.coach_assessment_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  assessment_id UUID NOT NULL REFERENCES health_assessments(id) ON DELETE CASCADE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(coach_id, assessment_id)  -- 每個教練對每份評估只能有一個備註
);
```

---

### 15. coach_display_preferences - 教練顯示偏好

```sql
CREATE TABLE public.coach_display_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  show_parq BOOLEAN DEFAULT TRUE,
  show_injury_history BOOLEAN DEFAULT TRUE,
  show_occupation BOOLEAN DEFAULT FALSE,
  show_activity_level BOOLEAN DEFAULT TRUE,
  show_sleep_hours BOOLEAN DEFAULT FALSE,
  show_stress_level BOOLEAN DEFAULT FALSE,
  show_fitness_goals BOOLEAN DEFAULT TRUE,
  show_experience_level BOOLEAN DEFAULT TRUE,
  show_preferred_days BOOLEAN DEFAULT FALSE,
  show_emergency_contact BOOLEAN DEFAULT TRUE,
  show_disclaimer BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(coach_id)
);
```

---

### 15-16. 優化表格

```sql
-- 每日訓練統計
CREATE TABLE public.daily_workout_summary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  date DATE NOT NULL,
  workout_count INTEGER DEFAULT 0,
  total_volume NUMERIC(10, 2) DEFAULT 0,
  total_sets INTEGER DEFAULT 0,
  resistance_training_count INTEGER DEFAULT 0,
  cardio_count INTEGER DEFAULT 0,
  mobility_count INTEGER DEFAULT 0,
  UNIQUE(user_id, date)
);

-- 個人記錄彙總
CREATE TABLE public.personal_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  exercise_id TEXT NOT NULL,
  body_part TEXT,                   -- 自動從 exercises 查詢填入
  max_weight NUMERIC(10, 2),
  max_reps INTEGER,
  max_volume NUMERIC(10, 2),
  record_date TIMESTAMPTZ NOT NULL,
  workout_plan_id TEXT,
  UNIQUE(user_id, exercise_id)
);
```

---

## 🔐 RLS 策略

### 完整 RLS 策略清單

> 最後更新：2026-01-04

#### appointments（預約）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | clients_view_own_appointments | `client_id = auth.uid()` |
| SELECT | coaches_view_own_appointments | `coach_id = auth.uid()` |
| INSERT | clients_create_appointments | `client_id = auth.uid()` + 活躍教練關係 |
| UPDATE | clients_update_own_appointments | `client_id = auth.uid()` |
| UPDATE | coaches_update_own_appointments | `coach_id = auth.uid()` |

#### availability_slots（教練時段）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | coaches_view_own_slots | `coach_id = auth.uid()` |
| SELECT | clients_view_coach_slots | 活躍教練關係 |
| INSERT | coaches_insert_own_slots | `coach_id = auth.uid()` |
| UPDATE | coaches_update_own_slots | `coach_id = auth.uid()` |
| DELETE | coaches_delete_own_slots | `coach_id = auth.uid()` |

#### body_data（身體數據）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| ALL | Users can * their own body data | `user_id = auth.uid()` |

#### client_availability（學員時間偏好）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | Clients view own | `client_id = auth.uid()` |
| SELECT | Coaches view active clients | 活躍教練關係 |
| INSERT/UPDATE | Clients/Coaches | 自己或活躍教練關係 |
| DELETE | Clients delete own | `client_id = auth.uid()` |

#### coach_assessment_notes（教練評估備註）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| ALL | Coaches can * their own | `coach_id = auth.uid()` |

#### coach_display_preferences（教練顯示偏好）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| ALL | Coaches can manage own | `coach_id = auth.uid()` |

#### coaches（教練檔案）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | coaches_select_own | `id = auth.uid()` + `is_coach = true` |
| SELECT | coaches_select_by_student | 活躍教練關係 |
| INSERT | coaches_insert_own | `id = auth.uid()` + `is_coach = true` |
| UPDATE | coaches_update_own | `id = auth.uid()` + `is_coach = true` |

#### coaching_relationships（教練學員關係）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | Clients/Coaches can view | `client_id/coach_id = auth.uid()` |
| INSERT | Clients can create | `client_id = auth.uid()` |
| INSERT | Coaches can create | `coach_id = auth.uid()` + `is_coach = true` |
| UPDATE | 狀態變更 | 雙方可封存/恢復，學員可接受/拒絕 |
| DELETE | Both parties can delete | `coach_id/client_id = auth.uid()` |

#### custom_exercises（自訂動作）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| ALL | Users can * own | `user_id = auth.uid()` |
| SELECT | Trainees view in workouts | 動作存在於自己的訓練中 |

#### exercises（系統動作庫）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | System exercises | `user_id IS NULL`（公開） |
| SELECT | Users view own custom | `user_id = auth.uid()` |
| INSERT/UPDATE/DELETE | Users manage own | `user_id = auth.uid()` |

#### health_assessments（健康評估）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | Users view own | `user_id = auth.uid()` |
| SELECT | Coaches view clients | 活躍教練關係 |
| INSERT | Users/Coaches | 自己或活躍教練關係 |
| UPDATE | Users/Coaches | 自己或活躍教練關係 |

#### invite_codes（邀請碼）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | Users can query valid | `expires_at > now()` |
| INSERT | Coaches can create | `coach_id = auth.uid()` + `is_coach = true` |
| DELETE | Users can delete | `expires_at > now()` |

#### notes（個人筆記）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| ALL | Users can * their notes | `user_id = auth.uid()` |

#### session_notes（課程筆記）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | Coaches view own | `coach_id = auth.uid()` |
| SELECT | Clients view shared | `client_id = auth.uid()` + `visibility = 'shared'` |
| INSERT | Coaches create | `coach_id = auth.uid()` + 活躍關係 |
| UPDATE | Coaches update own | `coach_id = auth.uid()` |
| UPDATE | Hide notes | 雙方可隱藏共享筆記 |
| DELETE | Coaches delete own | `coach_id = auth.uid()` |

#### users（用戶）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | Users view own profile | `id = auth.uid()` |
| SELECT | Coaches/Clients view each other | 活躍教練關係 |
| INSERT | Users insert own profile | `id = auth.uid()` |
| UPDATE | Users update own profile | `id = auth.uid()` |

#### workout_plans（訓練計畫）⭐

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | Users can view own | `trainee_id/creator_id = auth.uid()` |
| SELECT | Coaches view clients | 活躍教練關係 |
| INSERT | Users create own | `trainee_id/creator_id = auth.uid()` |
| INSERT | Coaches create for clients | `creator_id = auth.uid()` + 活躍關係 |
| UPDATE | Users update own | `trainee_id/creator_id = auth.uid()` |
| DELETE | Only creators can delete | `creator_id = auth.uid()` ✅ |

> ✅ v2.9 修正：只有創建者可以刪除訓練計畫（Migration 026）

#### workout_templates（訓練模板）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| ALL | Users can * their own | `user_id = auth.uid()` |

---

### 公開表格（無 RLS 限制）

| 表格 | 說明 |
|-----|------|
| body_parts | 身體部位（元數據） |
| exercise_types | 動作類型（元數據） |

---

## 📦 Storage 配置

### session_photos（課程照片）

- **Public**：false（私有）
- **Size Limit**：10 MB
- **MIME Types**：`image/jpeg`, `image/png`

**路徑結構**：`{coach_id}/{client_id}/{filename}`

**RLS**：
- 教練可上傳到自己的資料夾
- 教練可查看自己上傳的照片
- 學員可查看共享筆記的照片

### coach_drawings（標註圖片）

- **Public**：false（私有）
- **Size Limit**：5 MB
- **MIME Types**：`image/png`

---

## 📝 查詢最佳實踐

### 1. 型別安全

```dart
// ✅ 正確：透過 Model 轉換
final record = WorkoutRecord.fromSupabase(data);
await workoutService.createRecord(record);

// ❌ 錯誤：直接操作 Map
await supabase.from('workout_plans').insert({'title': 'Test'});
```

### 2. ID 生成

```dart
// Firestore 相容 ID（20 字符）
String generateFirestoreId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random.secure();
  return List.generate(20, (_) => chars[random.nextInt(chars.length)]).join();
}
```

### 3. Snake_case 轉換

```dart
factory UserModel.fromSupabase(Map<String, dynamic> json) {
  return UserModel(
    uid: json['id'] as String,
    displayName: json['display_name'] as String?,  // snake_case → camelCase
    isCoach: json['is_coach'] as bool? ?? false,
  );
}
```

### 4. 錯誤處理

```dart
try {
  await _workoutService.createRecord(record);
} catch (e) {
  if (e is PostgrestException) {
    _errorService.logError('Supabase 錯誤: ${e.message}');
  }
  rethrow;
}
```

---

## ⚡ 效能優化

### 索引策略

| 類型 | 用途 | 範例 |
|-----|------|------|
| B-Tree | 等值/範圍查詢 | `idx_workout_plans_trainee` |
| GIN | JSONB / 全文搜尋 | `idx_exercises_name_gin` |
| GiST | 範圍排除 | `EXCLUDE USING GIST` |
| 部分索引 | 熱資料優化 | `WHERE completed = FALSE` |

### 分頁策略

```dart
// ❌ Offset 分頁（O(N)，深層分頁慢）
.range(100, 119)

// ✅ Cursor 分頁（O(1)，恆定速度）
.lt('scheduled_date', lastCursor)
.order('scheduled_date', ascending: false)
.limit(20)
```

### 快取策略

- 記憶體快取：5 分鐘有效
- 首頁預載入統計數據
- 動作庫 App 啟動時預載入

### 效能指標

| 項目 | 優化後 |
|-----|--------|
| 統計頁面 | <5ms（快取）|
| 動作搜尋 | <50ms |
| 訓練列表 | <20ms |
| 個人記錄 | <10ms |

---

## 📁 Migrations

**執行順序與詳細說明**：[migrations/README.md](../migrations/README.md)

### 快速參考

| 檔案 | 版本 | 說明 |
|-----|------|------|
| 001-004 | v1.0 | 核心表格 + 系統資料 + 優化 |
| 005-007 | v2.0 | 教練學員 + 預約 + 筆記 |
| 008-010 | v2.x | 修復 + 增強 |
| 016-021 | v2.8 | 健康評估系統 |

---

## 📚 相關文檔

- **歷史記錄**：[docs/archived/DATABASE_HISTORY.md](archived/DATABASE_HISTORY.md)
- **遷移指南**：[migrations/README.md](../migrations/README.md)
- **時間處理**：[docs/DATETIME_UTILS_GUIDE.md](DATETIME_UTILS_GUIDE.md)
