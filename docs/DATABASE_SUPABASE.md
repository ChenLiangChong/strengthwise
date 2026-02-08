# StrengthWise - 資料庫設計

> Supabase PostgreSQL 資料庫架構與最佳實踐

**最後更新**：2026-02-07（v5.0）

---

## 📊 架構總覽

```
Supabase PostgreSQL（28 個表格）
├── 核心表格（7 個）
│   ├── users              - 用戶資料
│   ├── exercises          - 系統動作庫（775 個）
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
├── 動作分類系統（4 個）⭐ v5.0
│   ├── exercise_aliases        - 動作別名表（2344 筆）
│   ├── ref_movement_patterns   - 動作模式參照表
│   ├── ref_muscle_groups       - 肌肉群參照表（25 個）
│   └── ref_equipment           - 器材參照表
│
├── 教練學員系統（8 個）
│   ├── coaching_relationships - 教練學員關係
│   ├── availability_slots     - 教練可用時段
│   ├── appointments           - 預約記錄
│   ├── session_notes          - SOAP 課程筆記
│   ├── client_availability    - 學員時間偏好
│   ├── coaches                - 教練公開檔案
│   ├── coach_booking_settings - 教練預約設定 ⭐ v3.0
│   └── daily_readiness        - 課前問卷 ⭐ v3.0
│
├── 邀請碼系統（1 個）
│   └── invite_codes       - 一次性邀請碼
│
├── 健康評估系統（3 個）
│   ├── health_assessments        - PAR-Q+ 問卷
│   ├── coach_assessment_notes    - 教練備註（私有）
│   └── coach_display_preferences - 顯示偏好
│
├── 推播通知（1 個）⭐ v3.0-C
│   └── user_devices       - 用戶設備（FCM Token 管理）
│
└── 優化表格（2 個）
    ├── daily_workout_summary - 每日訓練統計
    └── personal_records      - 個人記錄彙總
```

### Realtime 配置（v3.9）

以下表格已啟用 Realtime 即時同步：

| 表格 | 用途 | REPLICA IDENTITY |
|------|------|------------------|
| `availability_slots` | 教練可用時段 | FULL |
| `client_availability` | 學員時間偏好 | FULL |
| `appointments` | 預約記錄 | FULL |

**REPLICA IDENTITY FULL**：確保 DELETE 事件可獲取完整 oldRecord 資料，用於跨用戶即時同步。

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
  tracking_mode TEXT DEFAULT 'weight_reps',  -- v3.2+ 追蹤模式
  -- v5.0 動作分類系統 v2 欄位
  canonical_name TEXT,              -- SEE 標準中文名
  canonical_name_en TEXT,           -- SEE 標準英文名
  movement_patterns TEXT[] DEFAULT '{}',  -- 動作模式（可複選）
  ppl_tags TEXT[] DEFAULT '{}',     -- PPL 標籤（可複選）
  primary_muscle TEXT,              -- 主動肌（單選）
  synergist_muscles TEXT[] DEFAULT '{}',  -- 協同肌（可複選）
  mechanics_type TEXT DEFAULT 'compound',  -- 力學類型
  is_unilateral BOOLEAN DEFAULT FALSE,     -- 單邊動作
  difficulty_level TEXT DEFAULT 'beginner', -- 難度等級
  is_explosive BOOLEAN DEFAULT FALSE,       -- 爆發力動作
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_exercises_name_gin ON exercises USING gin(to_tsvector('simple', name));
CREATE INDEX idx_exercises_training_type ON exercises(training_type);
CREATE INDEX idx_exercises_body_part ON exercises(body_part);
-- v5.0 GIN 索引（加速陣列查詢）
CREATE INDEX idx_exercises_movement_patterns ON exercises USING GIN (movement_patterns);
CREATE INDEX idx_exercises_ppl_tags ON exercises USING GIN (ppl_tags);
CREATE INDEX idx_exercises_primary_muscle ON exercises (primary_muscle);
```

**資料統計**：775 個動作（阻力 700+、活動度 30+、心肺 20+）+ 2344 個別名

**tracking_mode 可用值**（v3.2+）：
| 模式 | 說明 | 適用動作 |
|------|------|----------|
| `weight_reps` | 重量 × 次數（預設）| 深蹲、臥推 |
| `weight_time` | 重量 × 時間 | 農夫走路 |
| `reps_only` | 僅次數 | 波比跳、跳箱 |
| `time_only` | 僅時間 | 棒式、靜態支撐 |
| `reps_time` | 次數 × 時間 | 動態伸展 |
| `distance_time` | 距離 + 時間 | 跑步機、划船機 |
| `distance_only` | 僅距離 | 立定跳遠 |
| `calories` | 卡路里 | 風扇車 |

**v5.0 動作分類欄位說明**：

| 欄位 | 類型 | 說明 |
|------|------|------|
| `canonical_name` | TEXT | SEE 標準中文名（Specification-Equipment-Exercise）|
| `canonical_name_en` | TEXT | SEE 標準英文名 |
| `movement_patterns` | TEXT[] | 動作模式（push, pull, squat, hinge, lunge, core, carry 等）|
| `ppl_tags` | TEXT[] | PPL 標籤（push, pull, legs, core, mobility, cardio）|
| `primary_muscle` | TEXT | 主動肌（25 個有效值，詳見 ref_muscle_groups）|
| `synergist_muscles` | TEXT[] | 協同肌 |
| `mechanics_type` | TEXT | compound（多關節）/ isolation（單關節）|
| `is_unilateral` | BOOLEAN | 單邊動作標記 |
| `difficulty_level` | TEXT | beginner / intermediate / advanced |
| `is_explosive` | BOOLEAN | 爆發力動作標記 |

---

### 2.1 exercise_aliases - 動作別名表 ⭐ v5.0

```sql
CREATE TABLE public.exercise_aliases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exercise_id TEXT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  alias_term TEXT NOT NULL,           -- 別名（如「夾腿機」對應「機械髖內收」）
  locale TEXT DEFAULT 'zh-TW',        -- zh-TW, en-US
  category TEXT DEFAULT 'common',     -- common, slang, abbreviation, brand
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_exercise_aliases_exercise_id ON exercise_aliases(exercise_id);
CREATE INDEX idx_exercise_aliases_term ON exercise_aliases(alias_term);
CREATE INDEX idx_exercise_aliases_term_lower ON exercise_aliases(LOWER(alias_term));
```

**RLS**：所有人可讀（公開資料）

---

### 2.2 ref_movement_patterns - 動作模式參照表 ⭐ v5.0

```sql
CREATE TABLE public.ref_movement_patterns (
  id TEXT PRIMARY KEY,                -- 如 'horizontal_push'
  name_zh TEXT NOT NULL,              -- 如 '水平推'
  name_en TEXT NOT NULL,              -- 如 'Horizontal Push'
  parent_id TEXT REFERENCES ref_movement_patterns(id),
  description_zh TEXT,
  description_en TEXT,
  sort_order INT DEFAULT 0
);
```

**動作模式層級結構**：
- **Push**：horizontal_push, vertical_push, isolation_push
- **Pull**：horizontal_pull, vertical_pull, isolation_pull
- **Squat**：isolation_squat
- **Hinge**：isolation_hinge
- **Lunge**
- **Core**：anti_extension, anti_rotation, anti_lateral, flexion, rotation
- **Carry**
- **Cardio**
- **Mobility**

---

### 2.3 ref_muscle_groups - 肌肉群參照表 ⭐ v5.0

```sql
CREATE TABLE public.ref_muscle_groups (
  id TEXT PRIMARY KEY,                -- 如 'pec_major_sternal'
  name_zh TEXT NOT NULL,              -- 如 '胸大肌（胸骨部）'
  name_en TEXT NOT NULL,              -- 如 'Pectoralis Major (Sternal)'
  region TEXT NOT NULL,               -- upper_body, lower_body, core
  parent_group TEXT,                  -- chest, back, shoulders, arms, legs, core
  sort_order INT DEFAULT 0
);
```

**25 個有效主動肌值**：
- **胸**：pec_major_clavicular, pec_major_sternal, pec_minor, serratus_anterior
- **背**：lats, traps, rhomboids, erector_spinae, teres_major
- **肩**：front_delts, side_delts, rear_delts, rotator_cuff
- **手**：biceps, triceps, brachialis, forearms
- **腿**：quads, hamstrings, glutes, adductors, calves, hip_flexors, tibialis_anterior
- **核心**：abs, obliques

---

### 2.4 ref_equipment - 器材參照表 ⭐ v5.0

```sql
CREATE TABLE public.ref_equipment (
  id TEXT PRIMARY KEY,                -- 如 'barbell'
  name_zh TEXT NOT NULL,              -- 如 '槓鈴'
  name_en TEXT NOT NULL,              -- 如 'Barbell'
  description_zh TEXT,
  description_en TEXT,
  sort_order INT DEFAULT 0
);
```

**常用器材**：barbell, dumbbell, kettlebell, cable, machine, bodyweight, smith_machine, suspension, resistance_band, landmine

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
  tracking_mode TEXT DEFAULT 'weight_reps',  -- v3.2+ 追蹤模式
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
  recurrence_rule TEXT,             -- 週期性規則（RFC 5545）
  is_override BOOLEAN DEFAULT FALSE, -- 是否為覆蓋時段
  notes TEXT,                       -- 備註
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
  status appointment_status NOT NULL DEFAULT 'requested',  -- requested/confirmed/rejected/completed/cancelled
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
  appointment_id UUID REFERENCES appointments(id),  -- ⭐ v3.0 Session Mode 關聯
  workout_log_id TEXT,              -- 訓練記錄關聯
  title TEXT,                       -- 筆記標題
  content JSONB DEFAULT '{}'::jsonb, -- SOAP 內容（subjective/objective/assessment/plan）
  visibility TEXT DEFAULT 'coach_only',  -- coach_only / shared
  coach_name TEXT,                  -- 教練名稱快照
  client_name TEXT,                 -- 學員名稱快照
  hidden_by_client BOOLEAN DEFAULT FALSE,
  hidden_by_coach BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE INDEX idx_session_notes_appointment_unique (appointment_id) WHERE appointment_id IS NOT NULL
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

### 13. coach_booking_settings - 教練預約設定 ⭐ v3.0

```sql
CREATE TABLE public.coach_booking_settings (
  coach_id UUID PRIMARY KEY REFERENCES coaches(id) ON DELETE CASCADE,
  
  -- 緩衝機制（未來擴展）
  buffer_before INTERVAL DEFAULT '00:15:00'::interval,
  buffer_after INTERVAL DEFAULT '00:15:00'::interval,
  
  -- 預約限制
  min_booking_notice INTERVAL NOT NULL DEFAULT '02:00:00'::interval,
  max_booking_window INTERVAL DEFAULT '60 days'::interval,
  
  -- 顆粒度與容量（未來擴展）
  slot_increment INTERVAL DEFAULT '00:30:00'::interval,
  default_session_duration INTERVAL DEFAULT '01:00:00'::interval,
  max_sessions_per_day INTEGER DEFAULT 8,
  
  -- 時區
  timezone TEXT NOT NULL DEFAULT 'Asia/Taipei',
  
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

**重要欄位**：
- `min_booking_notice`：最短提前預約時間（目前使用）
- 其他欄位為未來擴展預留

---

### 14. daily_readiness - 課前問卷 ⭐ v3.0

```sql
CREATE TABLE public.daily_readiness (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
  session_note_id UUID REFERENCES session_notes(id) ON DELETE SET NULL,
  log_date DATE NOT NULL DEFAULT CURRENT_DATE,
  readiness_score INTEGER CHECK (readiness_score BETWEEN 0 AND 100),
  traffic_light TEXT CHECK (traffic_light IN ('RED', 'AMBER', 'GREEN')),
  metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, appointment_id)
);
```

**重要欄位**：
- `metrics`：JSONB 儲存 5 個指標（睡眠品質、時長、痠痛、壓力、能量）
- `traffic_light`：紅綠燈狀態（RED/AMBER/GREEN）
- `readiness_score`：0-100 總分

**自動創建**：預約確認時由觸發器 `trg_create_session_mode_data` 自動創建。

---

### 15. user_devices - 用戶設備 ⭐ v3.0-C

```sql
CREATE TABLE public.user_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  device_name TEXT,                    -- 設備名稱（可選）
  last_active TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, fcm_token)           -- 同一用戶同一 Token 只能有一筆
);

CREATE INDEX idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX idx_user_devices_token ON user_devices(fcm_token);
```

**重要欄位**：
- `fcm_token`：Firebase Cloud Messaging Token
- `platform`：android/ios/web
- `last_active`：最後活躍時間（用於清理舊設備）

**RPC 函數**：
- `upsert_device_token()`：添加/更新設備 Token
- `remove_device_token()`：移除設備 Token
- `remove_invalid_tokens()`：批量清理無效 Token
- `get_user_tokens()`：獲取用戶所有 Token

---

### 16. health_assessments - 健康評估問卷

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

### 16. coach_display_preferences - 教練顯示偏好

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

### 17-18. 優化表格

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

## ⚡ RPC 函數

### ~~search_exercises_v2()~~ ❌ 已移除（migration 28）

> **已在 migration 28 移除**。搜尋改為客戶端 Hive 快取搜尋（ExerciseSearchEngine + FuzzySearchEngine），支援離線使用且效能更佳。

---

## 🔐 RLS 策略

### 完整 RLS 策略清單

> 最後更新：2026-01-07

#### daily_workout_summary（每日訓練統計）⭐ v3.1

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | daily_summary_select | `user_id = auth.uid()` 或 活躍教練關係 |
| INSERT | daily_summary_insert | `user_id = auth.uid()` 或 活躍教練關係 |
| UPDATE | daily_summary_update | `user_id = auth.uid()` 或 活躍教練關係 |
| DELETE | daily_summary_delete | `user_id = auth.uid()` 或 活躍教練關係 |

#### personal_records（個人記錄）⭐ v3.1

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | personal_records_select | `user_id = auth.uid()` 或 活躍教練關係 |
| INSERT | personal_records_insert | `user_id = auth.uid()` 或 活躍教練關係 |
| UPDATE | personal_records_update | `user_id = auth.uid()` 或 活躍教練關係 |
| DELETE | personal_records_delete | `user_id = auth.uid()` 或 活躍教練關係 |

#### appointments（預約）

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| SELECT | clients_view_own_appointments | `client_id = auth.uid()` |
| SELECT | coaches_view_own_appointments | `coach_id = auth.uid()` |
| INSERT | clients_create_appointments | `client_id = auth.uid()` + 活躍教練關係 |
| INSERT | coaches_create_appointments | `coach_id = auth.uid()` + 活躍教練關係（v3.1.1 臨時課程）|
| UPDATE | clients_update_own_appointments | `client_id = auth.uid()` |
| UPDATE | coaches_update_own_appointments | `coach_id = auth.uid()` |

**觸發器**（v3.1.1）：

| 觸發器 | 事件 | 說明 |
|--------|------|------|
| `trg_cleanup_cancelled_appointment` | UPDATE status='cancelled' | 刪除關聯的 session_notes、daily_readiness、workout_plan（如有）|
| `trg_cleanup_rejected_appointment` | UPDATE status='rejected' | 刪除關聯的 session_notes、daily_readiness |

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

#### coach_booking_settings（教練預約設定）⭐ v3.0

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| ALL | Coaches can manage own settings | `coach_id = auth.uid()` |
| SELECT | Students can view coach settings | 活躍教練關係 |

#### daily_readiness（課前問卷）⭐ v3.0

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| ALL | Users can manage own readiness | `user_id = auth.uid()` |
| SELECT | Coaches can view students readiness | 活躍教練關係 |
| INSERT | Coaches can insert for students | 活躍教練關係 |

#### user_devices（用戶設備）⭐ v3.0-C

| 操作 | 策略名稱 | 條件 |
|-----|---------|------|
| ALL | users_manage_own_devices | `user_id = auth.uid()` |
| SELECT | Coaches can view students readiness | 活躍教練關係 |
| INSERT | Coaches can insert for students | 活躍教練關係 |

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

**觸發器**（v3.3）：

| 觸發器 | 事件 | 說明 |
|--------|------|------|
| `trg_update_pr` | AFTER INSERT/UPDATE | 更新 personal_records（最大重量、最大次數）|
| `trg_workout_plan_delete` | AFTER DELETE | 重新計算該動作的 PR ⭐ v3.3 |

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

### 文件結構（v3.3 整理後）

```
migrations/
├── consolidated/     # 精簡版（新部署推薦）- 10 個文件
└── 001-22.sql       # 演進版 - 22 個文件
```

### 快速參考

| 檔案 | 版本 | 說明 |
|-----|------|------|
| 001-004 | v1.0 | 核心表格 + 系統資料 + 優化 |
| 005-008 | v2.0 | 教練學員 + 預約 + 筆記 |
| 09-15 | v2.2-v2.9 | 修復 + 健康評估 + 教練系統 |
| 16-19 | v3.0-v3.1 | 預約優化 + Session Mode + RLS |
| 20-22 | v3.2-v3.3 | TrackingMode + PR 觸發器修復 ⭐

---

## 📚 相關文檔

- **歷史記錄**：[docs/archived/DATABASE_HISTORY.md](archived/DATABASE_HISTORY.md)
- **遷移指南**：[migrations/README.md](../migrations/README.md)
- **時間處理**：[docs/DATETIME_UTILS_GUIDE.md](DATETIME_UTILS_GUIDE.md)
