# StrengthWise - Supabase PostgreSQL 資料庫設計

> 完整的 Supabase PostgreSQL 資料庫架構文檔

**最後更新**：2026年1月1日 - v2.2 資料庫修復完成 ✅

---

## 🎯 重大架構升級公告（2024-12-28）

### 從靜態動作庫到基於屬性的動態系統 ⭐⭐⭐

**背景**：v1.0 單機版使用傳統預設動作庫（794 個系統動作），但實際使用中發現：
- ❌ 預設動作庫極少被使用（教練偏好自訂動作）
- ❌ 無法支援「身體部位 PR」統計需求（跨動作聚合）
- ❌ 靜態欄位無法描述複合動作的多重屬性

**v2.0 新架構**：屬性驅動的動態動作系統
- ✅ 動作由多個屬性標籤組成（胸部、槓鈴、推）
- ✅ 支援「身體部位 PR」統計（自動聚合）
- ✅ 支援「單一動作進步」追蹤（e1RM 趨勢）
- ✅ 寫入時聚合（O(1) 讀取統計數據）

**詳細設計**：請參考 [docs/SAAS_PLATFORM_ROADMAP.md](SAAS_PLATFORM_ROADMAP.md) 第 2.4 章節

**影響範圍**：
- **新增表格**：`attribute_categories`, `attributes`, `exercise_attributes`, `user_attribute_stats`, `user_exercise_stats`
- **修改表格**：`exercises`（添加 `is_placeholder`, `default_metric`），`workout_sets`（添加 `is_warmup`, `estimated_1rm`）
- **實施時間**：v2.0 Phase 2（預計 3-4 週）

---

## 🔧 v2.2 資料庫修復（2026-01-01）✅

### 修復內容

**1. Personal Records Body Part 欄位** ⭐⭐⭐
- **問題**：`personal_records.body_part` 一直是 `NULL`，導致 `personal_records_top_by_body_part` 視圖無資料
- **修復**：觸發器自動從 `exercises.body_parts[1]` 查詢並填入
- **Migration**：`010_fix_personal_records_body_part.sql`

**2. 統計觸發器支援布林值**
- **問題**：觸發器只支援 `completed: "true"` 字串格式
- **修復**：同時支援字串和布林值（向後相容 100%）
- **Migration**：`009_fix_trigger_bool_support.sql`

**3. 可用時段查詢函數修復**
- **問題**：`get_available_slots()` 函數邏輯錯誤
- **修復**：重新實作函數，正確查詢並排除已預約時段
- **Migration**：`008_fix_get_available_slots.sql`

### 專案整理

**Python 腳本整理**：
- 刪除 6 個臨時檢查工具
- 保留 8 個核心工具
- 更新 `scripts/README.md`

**Migrations 整理**：
- 刪除 3 個臨時 SQL 檔案
- 新增 3 個修復檔案（v2.2）
- 更新 `migrations/README.md`
- 最終結構：19 → 11 個（-42%）

---

## 📊 資料庫架構總覽

StrengthWise 已完全遷移到 **Supabase PostgreSQL**，使用以下架構：

```
Supabase PostgreSQL
├── v1.0 核心表格（7 個）✅ 活躍使用中
│   ├── users              - 用戶資料
│   ├── exercises          - 系統動作庫（794 個）⚠️ v2.0 將重構
│   ├── custom_exercises   - 自訂動作 ⚠️ v2.0 將合併至 exercises
│   ├── workout_plans      - 訓練計劃（包含記錄）
│   ├── workout_templates  - 訓練模板
│   ├── body_data          - 身體數據（體重、體脂等）
│   └── notes             - 筆記
│
├── v1.0 元數據表格（2 個）✅ 活躍使用中
│   ├── body_parts        - 身體部位（8 個）⚠️ v2.0 將遷移至 attributes
│   └── exercise_types    - 訓練類型（3 個）⚠️ v2.0 將遷移至 attributes
│
├── v2.0 新增表格（5 個）📋 規劃中
│   ├── attribute_categories  - 屬性分類（muscle_group, equipment, movement_pattern）
│   ├── attributes            - 屬性標籤（胸部、槓鈴、推）
│   ├── exercise_attributes   - 動作-屬性關聯（多對多）
│   ├── user_attribute_stats  - 身體部位統計（自動更新）
│   └── user_exercise_stats   - 單一動作統計（自動更新）
│
├── 預約系統表格（4 個）⚠️ 已遷移但未啟用
│   ├── bookings          - 預約
│   ├── available_slots   - 可預約時段
│   ├── notifications     - 通知
│   └── booking_history   - 預約歷史
│
└── 認證系統
    └── auth.users        - Supabase Auth（UUID 主鍵）
```

**當前狀態**（2024-12-28）：
- ✅ **v1.0 核心功能**：7 個核心表格 + 2 個元數據表格（完全運作）
- 📋 **v2.0 規劃中**：基於屬性的動態動作庫架構（Phase 2 實施）
- ⚠️ **預約系統**：4 個表格已遷移，但在單機版中未啟用

**架構遷移計劃**（v2.0）：
1. **動作庫重構**：`exercises` + `custom_exercises` → 統一的屬性驅動系統
2. **統計系統升級**：新增 `user_attribute_stats`（身體部位 PR）+ `user_exercise_stats`（單一動作進步）
3. **觸發器自動化**：訓練完成時自動更新統計數據
4. **向後相容**：舊數據通過遷移腳本轉換為標籤格式

---

## 📊 實際資料庫狀態（2025-12-26）

> 以下是當前資料庫的實際數據統計（最後更新：2025-12-26 07:58）

### 核心表格（7 個）

| 表格 | 記錄數 | 說明 |
|------|--------|------|
| **users** | 1 筆 | 使用者資料 |
| **exercises** | 794 筆 | 系統動作庫（雙語完整）<br>- 阻力訓練: 744<br>- 活動度與伸展: 30<br>- 心肺適能訓練: 20 |
| **custom_exercises** | 1 筆 | 自訂動作 |
| **workout_plans** | 24 筆 | 訓練計劃<br>- 已完成: 19<br>- 待完成: 5<br>- 總訓練量: 86,309 kg |
| **workout_templates** | 5 筆 | 訓練模板 |
| **body_data** | 4 筆 | 身體數據<br>- 體重範圍: 75-80 kg |
| **notes** | 0 筆 | 筆記（空） |

### 元數據表格（2 個）

| 表格 | 記錄數 | 說明 |
|------|--------|------|
| **body_parts** | 8 筆 | 身體部位（完整中英雙語）<br>全身、手、核心、肩部、胸部、背部、腿部、肩背複合 |
| **exercise_types** | 3 筆 | 訓練類型（完整中英雙語）<br>阻力訓練、心肺適能訓練、活動度與伸展 |

### 資料品質狀態

- ✅ **雙語系統**：100% 完成（exercises, body_parts, exercise_types 都有中英對照）
- ✅ **ID 格式**：統一使用 20 字符 Firestore 相容 ID
- ✅ **時間戳記**：ISO 8601 格式
- ✅ **訓練數據**：19 次完成的訓練，總訓練量 86,309 kg
- ✅ **動作分類**：794 個系統動作，五階層專業分類

**更新方式**：執行 `python scripts/download_complete_database.py` 即可更新本章節

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
  name_en TEXT,
  training_type TEXT,
  training_type_en TEXT,
  body_part TEXT,
  body_part_en TEXT,
  specific_muscle TEXT,
  equipment TEXT,
  equipment_category TEXT,
  equipment_subcategory TEXT,
  action_name TEXT,
  action_name_en TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 全文搜尋索引
CREATE INDEX idx_exercises_name_gin ON public.exercises USING gin(to_tsvector('simple', name));
CREATE INDEX idx_exercises_training_type ON public.exercises (training_type);
CREATE INDEX idx_exercises_body_part ON public.exercises (body_part);
```

**重要欄位說明**：
- `id`: TEXT 類型（20 字符 Firestore ID，例如：`0A5921MGWAyUv7fXcA29`）
- `name` / `name_en`: 中英雙語動作名稱
- `training_type` / `training_type_en`: 訓練類型（雙語）
- `body_part` / `body_part_en`: 主要身體部位（雙語）
- `specific_muscle`: 特定肌群（中文）
- `equipment_category`: 器材類別（自由重量、機械式、徒手、功能性訓練）
- `equipment_subcategory`: 器材子類別（啞鈴、槓鈴、Cable 滑輪等）

**RLS 策略**：
- 所有認證用戶可讀取系統動作

**資料統計**（2025-12-26）：
- 系統動作：794 個
- 訓練類型：阻力訓練 744、活動度與伸展 30、心肺適能訓練 20
- 器材分布：徒手 33.1%、機械式 32.6%、自由重量 31.4%

---

### 3. custom_exercises - 自訂動作（✨ 2024-12-26）

```sql
CREATE TABLE IF NOT EXISTS public.custom_exercises (
  id TEXT PRIMARY KEY,  -- Firestore 相容 ID（20 字符）
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  body_part TEXT NOT NULL,  -- 身體部位：胸部/背部/腿部/肩部/手臂/核心
  equipment TEXT DEFAULT '徒手',  -- 器材類型
  description TEXT DEFAULT '',  -- 動作說明
  notes TEXT DEFAULT '',  -- 個人筆記
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_custom_exercises_user_id ON public.custom_exercises(user_id);
CREATE INDEX idx_custom_exercises_body_part ON public.custom_exercises(body_part);
CREATE INDEX idx_custom_exercises_user_body_part ON public.custom_exercises(user_id, body_part);
```

**重要欄位說明**：
- `id`: TEXT 類型（20 字符 Firestore 相容 ID）
- `user_id`: 創建者 ID（UUID）
- `body_part`: 身體部位（必填，用於統計）
  - 選項：胸部/背部/腿部/肩部/手臂/核心
- `equipment`: 器材類型
  - 選項：徒手/啞鈴/槓鈴/固定式機械/Cable滑輪/壺鈴/彈力帶/其他
- `description`: 動作說明（最多 200 字符）
- `notes`: 個人筆記（最多 200 字符）

**RLS 策略**：
- 用戶只能查看、創建、更新、刪除自己的自訂動作
- 使用 `auth.uid() = user_id` 保護數據安全

**功能特色**：
- ✅ 支援身體部位分類（可統計）
- ✅ 支援器材分類（可統計）
- ✅ 可在訓練計劃中使用（與系統動作一致）
- ✅ 可追蹤力量進步（透過 `workout_plans`）

**轉換為 Exercise 模型**：
自訂動作可透過 `ExerciseService.getExerciseById()` 查詢，會自動合併 `exercises` 和 `custom_exercises` 表格的結果。

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
- `trainee_id`: 受訓者 ID（v2.0 Phase 4C 啟用）⭐
  - 學員自主訓練：trainee_id = 學員本人 ID
  - 教練指派訓練：trainee_id = 學員 ID, creator_id = 教練 ID
- `creator_id`: 創建者 ID（v2.0 Phase 4C 啟用）⭐
  - 學員自主訓練：creator_id = 學員本人 ID
  - 教練指派訓練：creator_id = 教練 ID
  - 查詢邏輯：透過 trainee_id 查詢學員的所有訓練，透過 creator_id 篩選特定教練的訓練
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

### 6. body_data - 身體數據

```sql
CREATE TABLE IF NOT EXISTS public.body_data (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  weight DOUBLE PRECISION,
  body_fat_percentage DOUBLE PRECISION,
  muscle_mass DOUBLE PRECISION,
  bmi DOUBLE PRECISION,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_body_data_user_date ON public.body_data(user_id, date DESC);
```

**重要欄位說明**：
- `weight`: 體重（公斤）
- `body_fat_percentage`: 體脂率（%）
- `muscle_mass`: 肌肉量（公斤）
- `bmi`: 身體質量指數

**RLS 策略**：
- 用戶只能讀寫自己的身體數據

---

### 7. notes - 筆記

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

### 8-11. 預約系統表格（⚠️ 已遷移但未啟用）

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

**說明**：預約系統表格已從 Firestore 遷移完成，但在當前單機版中暫未啟用。未來教練版本會使用。

---

## 📦 元數據表格

### body_parts - 身體部位（8 個）

```sql
CREATE TABLE IF NOT EXISTS public.body_parts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  name_en TEXT,
  description TEXT,
  description_en TEXT,
  count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**數據**（中英雙語）：
- 全身 (Full Body)
- 手 (Arms)
- 核心 (Core)
- 肩部 (Shoulders)
- 胸部 (Chest)
- 背部 (Back)
- 腿部 (Legs)
- 肩背複合 (Shoulder-Back Complex)

---

### exercise_types - 訓練類型（3 個）

```sql
CREATE TABLE IF NOT EXISTS public.exercise_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  name_en TEXT,
  description TEXT,
  description_en TEXT,
  count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**數據**（中英雙語）：
- 阻力訓練 (Resistance Training)
- 心肺適能訓練 (Cardiovascular Training)
- 活動度與伸展 (Mobility & Stretching)

---

### ~~equipments / joint_types~~ - 已廢棄 🗑️

**說明**：這些元數據表格已不再使用，相關資料已整合到 `exercises` 表格中的對應欄位。

---

## 🎯 v2.0 新增表格設計（規劃中）

### 基於屬性的動態動作庫架構 ⭐⭐⭐

> 詳細設計請參考：[docs/SAAS_PLATFORM_ROADMAP.md](SAAS_PLATFORM_ROADMAP.md) 第 2.4、2.5 章節

#### 1. attribute_categories - 屬性分類

```sql
CREATE TABLE IF NOT EXISTS public.attribute_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL, -- 'muscle_group', 'equipment', 'movement_pattern'
  display_name TEXT NOT NULL, -- '目標肌群', '器材類型', '運動模式'
  is_system BOOLEAN DEFAULT TRUE,
  cardinality TEXT CHECK (cardinality IN ('single_select', 'multi_select')) DEFAULT 'multi_select',
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**用途**：定義標籤的類型，確保前端 UI 呈現清晰的分類選項

**預計數據**：
- `muscle_group`（目標肌群）：胸部、背部、腿部、肩部、手臂、核心
- `equipment`（器材類型）：槓鈴、啞鈴、機械、徒手、Cable 滑輪
- `movement_pattern`（運動模式）：推、拉、蹲、髖鉸鏈

---

#### 2. attributes - 屬性標籤

```sql
CREATE TABLE IF NOT EXISTS public.attributes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES public.attribute_categories(id),
  name TEXT NOT NULL, -- 'Chest', 'Barbell', 'Push'
  created_by UUID REFERENCES public.users(id), -- NULL = 系統標籤
  is_archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (name, category_id, created_by)
);

CREATE INDEX idx_attributes_name ON public.attributes(name text_pattern_ops);
CREATE INDEX idx_attributes_category ON public.attributes(category_id);
CREATE INDEX idx_attributes_creator ON public.attributes(created_by) WHERE created_by IS NOT NULL;
```

**關鍵設計**：`created_by` 欄位實現混合命名空間
- `NULL`：系統全域標籤（所有用戶可見，不可修改）
- 有值：教練私有標籤（僅創建者可見）

**RLS 策略**：
```sql
CREATE POLICY "attributes_access_policy" ON public.attributes
FOR SELECT
USING (
  created_by IS NULL -- 系統標籤
  OR created_by = auth.uid() -- 自己創建的標籤
);
```

---

#### 3. exercise_attributes - 動作-屬性關聯

```sql
CREATE TABLE IF NOT EXISTS public.exercise_attributes (
  exercise_id UUID REFERENCES public.exercises(id) ON DELETE CASCADE,
  attribute_id UUID REFERENCES public.attributes(id) ON DELETE CASCADE,
  PRIMARY KEY (exercise_id, attribute_id)
);

-- 正向查詢索引（查詢動作的所有標籤）
CREATE INDEX idx_ea_exercise ON public.exercise_attributes(exercise_id);

-- 反向查詢索引（查詢所有「胸部」動作）⭐ 核心統計優化
CREATE INDEX idx_ea_attribute ON public.exercise_attributes(attribute_id, exercise_id);
```

**為何使用關聯表而非 JSONB？**
- ✅ JOIN 和 GROUP BY 操作效能更佳（百萬級數據）
- ✅ 外鍵約束確保數據完整性
- ✅ 針對統計查詢可建立覆蓋索引

---

#### 4. user_attribute_stats - 身體部位統計

```sql
CREATE TABLE IF NOT EXISTS public.user_attribute_stats (
  user_id UUID NOT NULL REFERENCES public.users(id),
  attribute_id UUID NOT NULL REFERENCES public.attributes(id),
  total_lifetime_volume BIGINT DEFAULT 0, -- 生涯累積訓練量
  max_session_volume BIGINT DEFAULT 0, -- 身體部位 PR（單次訓練最大量）
  max_session_date TIMESTAMPTZ, -- PR 創建日期
  last_updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, attribute_id)
);

CREATE INDEX idx_user_attr_stats_user ON public.user_attribute_stats(user_id);
CREATE INDEX idx_user_attr_stats_attr ON public.user_attribute_stats(attribute_id);
```

**用途**：支援「身體部位 PR」統計（如胸部最大單次訓練量）

**更新機制**：透過 PostgreSQL Trigger，當訓練記錄狀態變更為 `completed` 時自動更新
- 遍歷該次訓練涉及的所有身體部位標籤
- 計算本次訓練該部位的總訓練量（排除熱身組）
- 更新 `total_lifetime_volume`
- 若本次總量 > `max_session_volume`，則更新 PR 值與日期

**效能優勢**：O(1) 讀取統計數據（儀表板秒開）

---

#### 5. user_exercise_stats - 單一動作統計

```sql
CREATE TABLE IF NOT EXISTS public.user_exercise_stats (
  user_id UUID NOT NULL REFERENCES public.users(id),
  exercise_id UUID NOT NULL REFERENCES public.exercises(id),
  personal_record_weight NUMERIC, -- 最大實際舉起重量
  personal_record_e1rm NUMERIC, -- 最佳估算 1RM（理論極限）
  max_volume_single_session NUMERIC, -- 該動作的單次最大訓練量
  last_performed_at TIMESTAMPTZ, -- 上次訓練時間
  PRIMARY KEY (user_id, exercise_id)
);

CREATE INDEX idx_user_ex_stats_user ON public.user_exercise_stats(user_id);
CREATE INDEX idx_user_ex_stats_recent ON public.user_exercise_stats(last_performed_at DESC);
```

**用途**：支援「單一動作進步」追蹤（如深蹲 1RM 進步曲線）

**更新機制**：透過 PostgreSQL Trigger，每當新增一組 `is_pr = TRUE` 的數據時自動更新

**應用場景**：
- 教練查看學員列表時直接顯示「深蹲 1RM: 150kg」
- 學員查看自訂動作統計卡片
- 無需遍歷歷史日誌

---

#### 6. workout_sets 表修改（添加關鍵欄位）

```sql
ALTER TABLE public.workout_sets
ADD COLUMN is_warmup BOOLEAN DEFAULT FALSE,
ADD COLUMN estimated_1rm NUMERIC GENERATED ALWAYS AS (
  CASE WHEN reps > 0 THEN weight_kg * (1 + reps::numeric / 30.0) ELSE 0 END
) STORED;

CREATE INDEX idx_workout_sets_warmup ON public.workout_sets(is_warmup) WHERE is_warmup = FALSE;
```

**新增欄位**：
- `is_warmup`：標記熱身組，統計時排除
- `estimated_1rm`：生成欄位，自動計算 Epley 公式（寫入時計算，讀取零成本）

**技術優勢**：
- ✅ 標準化強度指標（100kg x 5 vs 110kg x 3 可直接對比）
- ✅ 支援單一動作進步追蹤

---

#### 7. exercises 表修改（添加彈性欄位）

```sql
ALTER TABLE public.exercises
ADD COLUMN is_placeholder BOOLEAN DEFAULT FALSE,
ADD COLUMN default_metric TEXT CHECK (default_metric IN ('weight_reps', 'time', 'distance')) DEFAULT 'weight_reps';

CREATE INDEX idx_exercises_placeholder ON public.exercises(is_placeholder) WHERE is_placeholder = TRUE;
```

**新增欄位**：
- `is_placeholder`：標記佔位符動作（教練可安排抽象動作，學員執行時選擇具體動作）
- `default_metric`：預設記錄方式

**佔位符動作應用場景**：
- 教練安排「水平推」（佔位符）
- 學員根據健身房設備選擇「啞鈴臥推」或「器械推胸」
- 系統記錄實際執行動作，但保留原始模板意圖

---

### v2.0 數據遷移策略

**遷移步驟**：
1. **創建新表結構**：`attribute_categories`, `attributes`, `exercise_attributes`, 統計表
2. **匯入基礎屬性**：從現有 `body_parts` 和 `exercise_types` 轉換為 `attributes`
3. **轉換系統動作**：將 794 個系統動作的靜態欄位轉換為標籤關聯
4. **轉換自訂動作**：合併 `custom_exercises` 至統一的 `exercises` 表
5. **初始化統計表**：計算歷史數據並填充 `user_attribute_stats` 和 `user_exercise_stats`

**向後相容**：
- ✅ 舊的 `body_parts` 和 `exercise_types` 表保留為只讀（向後相容 v1.0）
- ✅ v1.0 App 可繼續使用舊架構
- ✅ v2.0 App 使用新架構，但可讀取舊數據

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

**1. exercises 表格**（系統動作）
```sql
-- 認證用戶可以讀取所有系統動作
CREATE POLICY "Authenticated users can view all exercises" 
  ON exercises FOR SELECT 
  TO authenticated 
  USING (true);
```

**2. custom_exercises 表格**（自訂動作）
```sql
-- 用戶只能讀寫自己的自訂動作
CREATE POLICY "Users can manage their own custom exercises" 
  ON custom_exercises FOR ALL
  TO authenticated 
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
```

**3. workout_plans 表格**（訓練計劃）
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
- ✅ exercises: 794 個動作（雙語完整）
- ✅ body_parts: 8 個身體部位（雙語）
- ✅ exercise_types: 3 個訓練類型（雙語）

**總計**：805 個文檔，0 個錯誤 ✅

### 階段二：用戶資料遷移（2024-12-25）

- ✅ 新用戶使用 Supabase Auth 註冊
- ✅ 現有 Firebase 用戶保持不變（向後相容）
- ✅ PostgreSQL Trigger 自動創建用戶資料

### 階段三：應用層重構（2024-12-25）

- ✅ 8 個 Service 層重構（Supabase 版本）
- ✅ 8 個 Model 層更新（`fromSupabase()` 方法）
- ✅ 8 個 UI 頁面重構（使用 Supabase Service）

---

## 🔍 資料庫查詢架構

### ✅ Clean Architecture 驗證

**架構狀態**：🎉 **完美實現！**

| 層級 | Supabase 使用 | 狀態 |
|------|--------------|------|
| **Controller/Model/View/Utils** | ❌ 0 個直接調用 | ✅ 完全隔離 |
| **Service 層** | ✅ 68 個查詢 | ✅ 集中管理 |

**關鍵優勢**：
- ✅ 100% 透過 Interface 使用 Service
- ✅ 所有查詢集中在 `lib/services/*_supabase.dart`
- ✅ 完全可測試（Mock Service）

### 📊 查詢統計摘要

**總計**：68 個查詢（40 SELECT + 9 INSERT + 12 UPDATE + 7 DELETE）  
**優化率**：51% 已優化（明確欄位選擇）  
**主要表格**：workout_plans (13)、bookings (10)、exercises (6)

---

### 1️⃣ workout_plans（訓練計劃）- 13 個查詢

#### 1.1 SELECT 查詢（7 個）

**✅ 1.1.1 查詢用戶模板列表**（`WorkoutServiceSupabase.getUserTemplates()`）
```dart
// 優化狀態：✅ 已優化（明確欄位）
final response = await _supabase
  .from('workout_templates')
  .select('id, title, description, plan_type, exercises, training_time, updated_at, user_id, created_at')
  .eq('user_id', currentUserId!)
  .order('updated_at', ascending: false);
```

**✅ 1.1.2 查詢模板詳情**（`WorkoutServiceSupabase.getTemplateById()`）
```dart
// 優化狀態：✅ 已優化（明確欄位）
final response = await _supabase
  .from('workout_templates')
  .select('id, user_id, title, description, plan_type, exercises, training_time, created_at, updated_at')
  .eq('id', templateId)
  .single();
```

**✅ 1.1.3 查詢已完成訓練記錄**（`WorkoutServiceSupabase.getUserRecords()`）
```dart
// 優化狀態：✅ 已優化（明確欄位）
final response = await _supabase
  .from('workout_plans')
  .select('id, title, scheduled_date, completed_date, completed, total_volume, total_exercises, total_sets, plan_type, trainee_id, creator_id, user_id, exercises, note, created_at, updated_at')
  .eq('trainee_id', currentUserId!)
  .eq('completed', true)
  .order('completed_date', ascending: false);
```

**✅ 1.1.4 查詢訓練計劃（支援篩選）**（`WorkoutServiceSupabase.getUserPlans()`）
```dart
// 優化狀態：✅ 已優化（明確欄位）
var query = _supabase
  .from('workout_plans')
  .select('id, title, scheduled_date, completed, completed_date, total_volume, total_exercises, total_sets, plan_type, trainee_id, creator_id, user_id, note, training_time, updated_at, created_at, exercises')
  .eq('trainee_id', currentUserId!);

// 可選篩選
if (completed != null) query = query.eq('completed', completed);
if (startDate != null) query = query.gte('scheduled_date', startDate.toIso8601String());
if (endDate != null) query = query.lt('scheduled_date', endDate.toIso8601String());

final response = await query.order('scheduled_date', ascending: completed == false);
```

**⚠️ 1.1.5 查詢記錄詳情**（`WorkoutServiceSupabase.getRecordById()`）
```dart
// 優化狀態：⚠️ 需優化（使用 SELECT *）
final response = await _supabase
  .from('workout_plans')
  .select()  // ⚠️ 應明確指定欄位
  .eq('id', recordId)
  .single();
```

**⚠️ 1.1.6 統計查詢 - 已完成訓練**（`StatisticsServiceSupabase._getCompletedWorkouts()`）
```dart
// 優化狀態：✅ 已優化（只選核心欄位，減少 70-80% 數據傳輸）
final response = await _supabase
  .from('workout_plans')
  .select('id, completed_date, updated_at, exercises, total_volume')
  .eq('trainee_id', userId)
  .eq('completed', true)
  .gte('updated_at', startDate.toIso8601String())
  .lte('updated_at', endDate.add(Duration(days: 1)).toIso8601String());
```

**⚠️ 1.1.7 統計查詢 - 所有已完成訓練**（`StatisticsServiceSupabase._getAllCompletedWorkouts()`）
```dart
// 優化狀態：⚠️ 需優化（使用 SELECT *）
final response = await _supabase
  .from('workout_plans')
  .select()  // ⚠️ 應明確指定欄位
  .eq('trainee_id', userId)
  .eq('completed', true);
```

#### 1.2 INSERT 查詢（2 個）

**✅ 1.2.1 創建訓練模板**（`WorkoutServiceSupabase.createTemplate()`）
```dart
final response = await _supabase
  .from('workout_templates')
  .insert(templateData)
  .select()
  .single();
```

**✅ 1.2.2 創建訓練記錄**（`WorkoutServiceSupabase.createRecord()`）
```dart
final response = await _supabase
  .from('workout_plans')
  .insert(recordData)
  .select()
  .single();
```

#### 1.3 UPDATE 查詢（2 個）

**✅ 1.3.1 更新訓練模板**（`WorkoutServiceSupabase.updateTemplate()`）
```dart
await _supabase
  .from('workout_templates')
  .update(templateData)
  .eq('id', template.id)
  .eq('user_id', currentUserId!);
```

**✅ 1.3.2 更新訓練記錄**（`WorkoutServiceSupabase.updateRecord()`）
```dart
await _supabase
  .from('workout_plans')
  .update(recordData)
  .eq('id', record.id)
  .eq('trainee_id', currentUserId!);
```

#### 1.4 DELETE 查詢（2 個）

**✅ 1.4.1 刪除訓練模板**（`WorkoutServiceSupabase.deleteTemplate()`）
```dart
await _supabase
  .from('workout_templates')
  .delete()
  .eq('id', templateId)
  .eq('user_id', currentUserId!);
```

**✅ 1.4.2 刪除訓練記錄**（`WorkoutServiceSupabase.deleteRecord()`）
```dart
await _supabase
  .from('workout_plans')
  .delete()
  .eq('id', recordId)
  .eq('trainee_id', currentUserId!);
```

---

### 2️⃣ exercises（系統動作）- 6 個查詢

#### 2.1 SELECT 查詢（6 個）

**⚠️ 2.1.1 載入所有動作**（`ExerciseServiceSupabase._preloadAllExercises()`）
```dart
// 優化狀態：⚠️ 需優化（使用 SELECT *，但已有本地快取）
// 說明：App 啟動時預載入，使用本地快取減少網路請求
final response = await _client
  .from('exercises')
  .select()  // ⚠️ 應明確指定欄位
  .timeout(Duration(seconds: 30));
```

**✅ 2.1.2 查詢訓練類型**（`ExerciseServiceSupabase.getExerciseTypes()`）
```dart
// 優化狀態：✅ 已優化（只選 name）
final response = await _client
  .from('exercise_types')
  .select('name')
  .order('name')
  .timeout(Duration(seconds: _queryTimeout));
```

**✅ 2.1.3 查詢身體部位**（`ExerciseServiceSupabase.getBodyParts()`）
```dart
// 優化狀態：✅ 已優化（只選 name）
final response = await _client
  .from('body_parts')
  .select('name')
  .order('name')
  .timeout(Duration(seconds: _queryTimeout));
```

**✅ 2.1.4 查詢分類層級**（`ExerciseServiceSupabase.getCategoriesByLevel()`）
```dart
// 優化狀態：✅ 已優化（只選特定 level 欄位）
var query = _client.from('exercises').select('level$level');

// 添加篩選條件
if (selectedType.isNotEmpty) query = query.eq('training_type', selectedType);
if (selectedBodyPart.isNotEmpty) query = query.contains('body_parts', [selectedBodyPart]);
// ... 其他 level 條件

final response = await query.timeout(Duration(seconds: _queryTimeout));
```

**⚠️ 2.1.5 根據篩選條件查詢動作**（`ExerciseServiceSupabase.getExercisesByFilters()`）
```dart
// 優化狀態：⚠️ 需優化（使用 SELECT *，但已有記憶體快取）
// 說明：優先使用記憶體快取，只在快取未準備時查詢資料庫
var query = _client.from('exercises').select();  // ⚠️ 應明確指定欄位

// 添加篩選條件
for (final entry in filters.entries) {
  if (entry.value.isEmpty) continue;
  if (entry.key == 'bodyPart') query = query.contains('body_parts', [entry.value]);
  else if (entry.key == 'type') query = query.eq('training_type', entry.value);
  else query = query.eq(entry.key, entry.value);
}

final response = await query.timeout(Duration(seconds: _queryTimeout));
```

**⚠️ 2.1.6 查詢單個動作詳情**（`ExerciseServiceSupabase.getExerciseById()`）
```dart
// 優化狀態：⚠️ 需優化（使用 SELECT *）
// 先查系統動作
final response = await _client
  .from('exercises')
  .select()  // ⚠️ 應明確指定欄位
  .eq('id', exerciseId)
  .maybeSingle()
  .timeout(Duration(seconds: _queryTimeout));

// 如果未找到，查自訂動作
if (response == null) {
  final customResponse = await _client
    .from('custom_exercises')
    .select()  // ⚠️ 應明確指定欄位
    .eq('id', exerciseId)
    .maybeSingle()
    .timeout(Duration(seconds: _queryTimeout));
}
```

**✅ 2.1.7 批量查詢動作詳情**（`ExerciseServiceSupabase.getExercisesByIds()`）
```dart
// 優化狀態：✅ 已優化（批量查詢，減少網路請求）
// 批量查詢系統動作
final systemResponse = await _client
  .from('exercises')
  .select()
  .inFilter('id', exerciseIds)
  .timeout(Duration(seconds: _queryTimeout));

// 批量查詢自訂動作（如果有未找到的 ID）
if (notFoundIds.isNotEmpty) {
  final customResponse = await _client
    .from('custom_exercises')
    .select()
    .inFilter('id', notFoundIds)
    .timeout(Duration(seconds: _queryTimeout));
}
```

**✅ 2.1.8 統計查詢 - 批量查詢系統動作 ID**（`StatisticsServiceSupabase._loadExerciseClassifications()`）
```dart
// 優化狀態：✅ 已優化（只選 id，減少數據傳輸）
final systemResponse = await _supabase
  .from('exercises')
  .select('id')
  .inFilter('id', allExerciseIds);
```

---

### 3️⃣ custom_exercises（自訂動作）- 6 個查詢

#### 3.1 SELECT 查詢（3 個）

**⚠️ 3.1.1 查詢用戶自訂動作列表**（`CustomExerciseServiceSupabase.getUserCustomExercises()`）
```dart
// 優化狀態：⚠️ 需優化（使用 SELECT *）
final response = await _supabase
  .from('custom_exercises')
  .select()  // ⚠️ 應明確指定欄位
  .eq('user_id', currentUserId!)
  .order('created_at', ascending: false)
  .timeout(Duration(seconds: _queryTimeout));
```

#### 3.2 INSERT 查詢（1 個）

**✅ 3.2.1 創建自訂動作**（`CustomExerciseServiceSupabase.addCustomExercise()`）
```dart
final response = await _supabase
  .from('custom_exercises')
  .insert({
    'id': id,
    'user_id': currentUserId,
    'name': name,
    'training_type': trainingType,
    'training_type_en': trainingTypeEn,
    'body_part': bodyPart,
    'body_part_en': bodyPartEn,
    'equipment': equipment,
    'equipment_en': equipmentEn,
    'description': description,
    'notes': notes,
  })
  .select()
  .single()
  .timeout(Duration(seconds: _queryTimeout));
```

#### 3.3 UPDATE 查詢（1 個）

**✅ 3.3.1 更新自訂動作**（`CustomExerciseServiceSupabase.updateCustomExercise()`）
```dart
await _supabase
  .from('custom_exercises')
  .update(updateData)
  .eq('id', exerciseId)
  .eq('user_id', currentUserId!)
  .timeout(Duration(seconds: _queryTimeout));
```

#### 3.4 DELETE 查詢（1 個）

**✅ 3.4.1 刪除自訂動作**（`CustomExerciseServiceSupabase.deleteCustomExercise()`）
```dart
await _supabase
  .from('custom_exercises')
  .delete()
  .eq('id', exerciseId)
  .eq('user_id', currentUserId!)
  .timeout(Duration(seconds: _queryTimeout));
```

---

### 4️⃣ users（用戶資料）- 6 個查詢

#### 4.1 SELECT 查詢（3 個）

**✅ 4.1.1 檢查用戶資料完整度**（`UserServiceSupabase.isProfileCompleted()`）
```dart
// 優化狀態：✅ 已優化（只選必要欄位）
final response = await _supabase
  .from('users')
  .select('nickname, height, weight')
  .eq('id', userId)
  .maybeSingle();
```

**⚠️ 4.1.2 查詢當前用戶資料**（`UserServiceSupabase.getCurrentUserProfile()`）
```dart
// 優化狀態：⚠️ 需優化（使用 SELECT *）
final response = await _supabase
  .from('users')
  .select()  // ⚠️ 應明確指定欄位
  .eq('id', userId)
  .maybeSingle();
```

#### 4.2 UPDATE 查詢（3 個）

**✅ 4.2.1 更新用戶資料**（`UserServiceSupabase.updateUserProfile()`）
```dart
await _supabase
  .from('users')
  .update(updateData)
  .eq('id', userId);
```

**✅ 4.2.2 切換用戶角色**（`UserServiceSupabase.toggleUserRole()`）
```dart
await _supabase
  .from('users')
  .update({
    'is_coach': isCoach,
    'is_student': !isCoach,
    'profile_updated_at': DateTime.now().toIso8601String(),
  })
  .eq('id', userId);
```

**✅ 4.2.3 更新用戶體重**（`UserServiceSupabase.updateUserWeight()`）
```dart
await _supabase
  .from('users')
  .update({
    'weight': weight,
    'profile_updated_at': DateTime.now().toIso8601String(),
  })
  .eq('id', userId);
```

---

### 5️⃣ body_data（身體數據）- 5 個查詢

#### 5.1 SELECT 查詢（2 個）

**⚠️ 5.1.1 查詢用戶身體數據記錄**（`BodyDataServiceSupabase.getUserRecords()`）
```dart
// 優化狀態：⚠️ 需優化（使用 SELECT *）
dynamic query = _supabase
  .from('body_data')
  .select()  // ⚠️ 應明確指定欄位
  .eq('user_id', userId);

if (startDate != null) query = query.gte('record_date', startDate.toIso8601String());
if (endDate != null) query = query.lte('record_date', endDate.toIso8601String());
query = query.order('record_date', ascending: false);
if (limit != null) query = query.limit(limit);

final response = await query;
```

**⚠️ 5.1.2 查詢最新身體數據記錄**（`BodyDataServiceSupabase.getLatestRecord()`）
```dart
// 優化狀態：⚠️ 需優化（使用 SELECT *）
final response = await _supabase
  .from('body_data')
  .select()  // ⚠️ 應明確指定欄位
  .eq('user_id', userId)
  .order('record_date', ascending: false)
  .limit(1);
```

#### 5.2 INSERT 查詢（1 個）

**✅ 5.2.1 創建身體數據記錄**（`BodyDataServiceSupabase.createRecord()`）
```dart
await _supabase.from('body_data').insert(data);
```

#### 5.3 UPDATE 查詢（1 個）

**✅ 5.3.1 更新身體數據記錄**（`BodyDataServiceSupabase.updateRecord()`）
```dart
await _supabase
  .from('body_data')
  .update(data)
  .eq('id', record.id);
```

#### 5.4 DELETE 查詢（1 個）

**✅ 5.4.1 刪除身體數據記錄**（`BodyDataServiceSupabase.deleteRecord()`）
```dart
await _supabase
  .from('body_data')
  .delete()
  .eq('id', recordId);
```

---

### 6️⃣ notes（筆記）- 5 個查詢

#### 6.1 SELECT 查詢（2 個）

**⚠️ 6.1.1 查詢用戶筆記列表**（`NoteServiceSupabase.getUserNotes()`）
```dart
// 優化狀態：⚠️ 需優化（使用 SELECT *）
final response = await _supabase
  .from('notes')
  .select()  // ⚠️ 應明確指定欄位
  .eq('user_id', currentUserId!)
  .order('updated_at', ascending: false);
```

**⚠️ 6.1.2 查詢筆記詳情**（`NoteServiceSupabase.getNoteById()`）
```dart
// 優化狀態：⚠️ 需優化（使用 SELECT *）
final response = await _supabase
  .from('notes')
  .select()  // ⚠️ 應明確指定欄位
  .eq('id', noteId)
  .eq('user_id', currentUserId!)
  .maybeSingle();
```

#### 6.2 INSERT 查詢（1 個）

**✅ 6.2.1 創建筆記**（`NoteServiceSupabase.createNote()`）
```dart
await _supabase.from('notes').insert(noteData);
```

#### 6.3 UPDATE 查詢（1 個）

**✅ 6.3.1 更新筆記**（`NoteServiceSupabase.updateNote()`）
```dart
await _supabase
  .from('notes')
  .update({
    'title': note.title,
    'text_content': note.textContent,
    'drawing_points': note.drawingPoints?.map((p) => p.toMap()).toList(),
    'updated_at': now.toIso8601String(),
  })
  .eq('id', note.id)
  .eq('user_id', currentUserId!);
```

#### 6.4 DELETE 查詢（1 個）

**✅ 6.4.1 刪除筆記**（`NoteServiceSupabase.deleteNote()`）
```dart
await _supabase
  .from('notes')
  .delete()
  .eq('id', noteId)
  .eq('user_id', currentUserId!);
```

---

### 7️⃣ bookings（預約系統）- 10 個查詢

> ⚠️ **注意**：預約系統表格已遷移但未啟用，以下查詢僅供參考

#### 7.1 SELECT 查詢（7 個）

**✅ 7.1.1 檢查用戶是否為教練**（`BookingServiceSupabase.isCoach()`）
```dart
final userResponse = await _supabase
  .from('users')
  .select('is_coach')
  .eq('id', userId)
  .maybeSingle();
```

**⚠️ 7.1.2 查詢用戶預約列表**（`BookingServiceSupabase.getUserBookings()`）
```dart
final response = await _supabase
  .from('bookings')
  .select()  // ⚠️ 應明確指定欄位
  .eq('user_id', currentUserId!)
  .order('date_time', ascending: true);
```

**⚠️ 7.1.3 查詢教練預約列表**（`BookingServiceSupabase.getCoachBookings()`）
```dart
final response = await _supabase
  .from('bookings')
  .select()  // ⚠️ 應明確指定欄位
  .eq('coach_id', currentUserId!)
  .order('date_time', ascending: true);
```

**⚠️ 7.1.4-7.1.7 查詢預約詳情**（多個方法）
```dart
final bookingResponse = await _supabase
  .from('bookings')
  .select()  // ⚠️ 應明確指定欄位
  .eq('id', bookingId)
  .maybeSingle();
```

#### 7.2 INSERT 查詢（1 個）

**✅ 7.2.1 創建預約**（`BookingServiceSupabase.createBooking()`）
```dart
await _supabase.from('bookings').insert(bookingData);
```

#### 7.3 UPDATE 查詢（2 個）

**✅ 7.3.1-7.3.2 更新預約狀態**（多個方法）
```dart
await _supabase
  .from('bookings')
  .update(updateData)
  .eq('id', bookingId);
```

---

### 8️⃣ SharedPreferences（本地存儲）- 9 個操作

> 📱 **說明**：收藏功能使用本地存儲，不涉及 Supabase 查詢

#### 8.1 讀取操作（5 個）

**✅ 8.1.1 查詢收藏 ID 列表**（`FavoritesService.getFavoriteExerciseIds()`）
```dart
final jsonString = _prefs!.getString(key);
```

**✅ 8.1.2 查詢收藏詳情列表**（`FavoritesService.getFavoriteExercises()`）
```dart
final jsonString = _prefs!.getString(key);
```

**✅ 8.1.3 檢查是否收藏**（`FavoritesService.isFavorite()`）
```dart
final favorites = await getFavoriteExercises(userId);
return favorites.any((f) => f.exerciseId == exerciseId);
```

#### 8.2 寫入操作（2 個）

**✅ 8.2.1 添加收藏**（`FavoritesService.addFavorite()`）
```dart
await _prefs!.setString(key, jsonString);
```

**✅ 8.2.2 更新最後查看時間**（`FavoritesService.updateLastViewedAt()`）
```dart
await _prefs!.setString(key, jsonString);
```

#### 8.3 刪除操作（2 個）

**✅ 8.3.1 移除收藏**（`FavoritesService.removeFavorite()`）
```dart
await _prefs!.setString(key, jsonString);
```

**✅ 8.3.2 清空所有收藏**（`FavoritesService.clearFavorites()`）
```dart
await _prefs!.remove(key);
```

---

## 🎯 查詢優化建議

### 優先級 1：高頻查詢優化（⚠️ 需立即優化）

**1. 訓練計劃列表查詢**（`getUserPlans()`）
- ✅ **已優化**：明確指定欄位
- ✅ **已優化**：使用索引（`trainee_id`, `scheduled_date`）
- 💡 **建議**：考慮使用覆蓋索引（INCLUDE title, completed）

**2. 統計查詢優化**（`StatisticsServiceSupabase`）
- ✅ **已優化**：只選核心欄位（減少 70-80% 數據傳輸）
- ✅ **已優化**：使用批量查詢（減少 N+1 問題）
- ✅ **已優化**：使用快取（避免重複查詢）

**3. 動作查詢優化**（`ExerciseServiceSupabase`）
- ✅ **已優化**：使用本地快取（App 啟動時預載入）
- ✅ **已優化**：使用記憶體快取（客戶端過濾）
- 💡 **建議**：考慮使用 pgroonga 全文搜尋（已在 Phase 2 實作）

### 優先級 2：SELECT * 查詢優化（⚠️ 需優化）

**需要明確指定欄位的查詢**（共 10 個）：

1. `WorkoutServiceSupabase.getRecordById()` - workout_plans
2. `StatisticsServiceSupabase._getAllCompletedWorkouts()` - workout_plans
3. `ExerciseServiceSupabase._preloadAllExercises()` - exercises
4. `ExerciseServiceSupabase.getExercisesByFilters()` - exercises
5. `ExerciseServiceSupabase.getExerciseById()` - exercises, custom_exercises
6. `CustomExerciseServiceSupabase.getUserCustomExercises()` - custom_exercises
7. `UserServiceSupabase.getCurrentUserProfile()` - users
8. `BodyDataServiceSupabase.getUserRecords()` - body_data
9. `BodyDataServiceSupabase.getLatestRecord()` - body_data
10. `NoteServiceSupabase.getUserNotes()` - notes
11. `NoteServiceSupabase.getNoteById()` - notes

**預期效益**：
- ✅ 減少網路傳輸量 60-80%
- ✅ 增加 Index-Only Scan 機會
- ✅ 提升查詢速度 30-50%

### 優先級 3：分頁優化（💡 未來優化）

**當前狀態**：
- ✅ 訓練列表使用 `order()` 排序
- ⚠️ 未使用 Cursor-based 分頁（目前數據量小，暫不需要）

**建議**：
- 💡 當訓練記錄超過 100 筆時，考慮實作 Cursor-based 分頁
- 💡 參考 `docs/DATABASE_OPTIMIZATION_GUIDE.md` 中的分頁優化章節

---

## 📊 查詢效能監控

### 關鍵指標

| 查詢類型 | 當前平均延遲 | 目標延遲 | 狀態 |
|---------|-------------|---------|------|
| 訓練列表查詢 | <50ms | <50ms | ✅ 達標 |
| 動作搜尋（中文） | <50ms | <50ms | ✅ 達標（Phase 2） |
| 統計頁面載入 | <300ms | <500ms | ✅ 達標（Phase 3） |
| 個人記錄（PR） | <10ms | <50ms | ✅ 超標（Phase 3） |

### 監控建議

**1. 啟用 Supabase Dashboard 查詢監控**
- 進入 Supabase Dashboard → Database → Query Performance
- 查看慢查詢（> 100ms）
- 分析執行計劃（EXPLAIN ANALYZE）

**2. 使用 Flutter DevTools 監控**
```dart
// 添加查詢計時
final stopwatch = Stopwatch()..start();
final response = await supabase.from('workout_plans').select(...);
stopwatch.stop();
print('[QUERY] workout_plans: ${stopwatch.elapsedMilliseconds}ms');
```

**3. 定期檢查索引使用率**
```sql
-- 查看未使用的索引
SELECT * FROM pg_stat_user_indexes 
WHERE idx_scan = 0 AND schemaname = 'public';

-- 查看索引大小
SELECT 
  tablename, 
  indexname, 
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;
```

---

**最後更新**：2024年12月27日  
**查詢總數**：68 個（40 SELECT + 9 INSERT + 12 UPDATE + 7 DELETE）  
**優化狀態**：✅ 35 已優化 / ⚠️ 10 需優化 / 💡 23 建議優化

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

**完整優化指南**：請參考 `docs/DATABASE_OPTIMIZATION_GUIDE.md`

### 關鍵效能指標（基於學術研究）

| 優化項目 | 優化前 | 優化後 | 提升幅度 |
|---------|--------|--------|----------|
| 查詢延遲（平均） | 150-300ms | <50ms | **70-85%** |
| 分頁查詢（深層） | 1-3秒 | <100ms | **90-95%** |
| 全文檢索（中文） | 500ms-2秒 | <50ms | **85-95%** |
| COUNT 查詢 | 2-5秒 | <10ms | **99%** |
| 併發能力 | ~100 用戶 | 10,000+ | **100倍** |

### 1. 索引策略

#### 1.1 B-Tree 索引（已建立）

已建立的基礎索引：
```sql
-- 訓練計劃核心索引
CREATE INDEX idx_workout_plans_trainee ON workout_plans (trainee_id, scheduled_date);
CREATE INDEX idx_workout_plans_creator ON workout_plans (creator_id, scheduled_date);
CREATE INDEX idx_workout_plans_completed ON workout_plans (completed, scheduled_date);

-- 動作查詢索引
CREATE INDEX idx_exercises_name_gin ON exercises USING gin(to_tsvector('simple', name));
CREATE INDEX idx_exercises_training_type ON exercises (training_type);
CREATE INDEX idx_exercises_body_part ON exercises (body_part);

-- 模板索引
CREATE INDEX idx_workout_templates_user ON workout_templates (user_id);

-- 身體數據索引
CREATE INDEX idx_body_data_user_date ON body_data(user_id, date DESC);

-- 筆記索引
CREATE INDEX idx_notes_user ON notes (user_id, created_at DESC);

-- 自訂動作索引
CREATE INDEX idx_custom_exercises_user_id ON custom_exercises(user_id);
CREATE INDEX idx_custom_exercises_body_part ON custom_exercises(body_part);
```

#### 1.2 覆蓋索引（Covering Indexes）⭐ **優化建議**

**概念**：將常查詢的欄位包含在索引中，實現 Index-Only Scan（無需回表）

**建議新增**：
```sql
-- 訓練列表查詢（覆蓋索引）
CREATE INDEX idx_workout_trainee_covering 
ON workout_plans (trainee_id, scheduled_date DESC) 
INCLUDE (title, completed, total_volume, total_exercises);

-- 教練查詢（覆蓋索引）
CREATE INDEX idx_workout_creator_covering 
ON workout_plans (creator_id, scheduled_date DESC) 
INCLUDE (trainee_id, title, completed);

-- 今日訓練（部分索引 + 覆蓋）
CREATE INDEX idx_today_training_covering 
ON workout_plans (trainee_id) 
INCLUDE (title, exercises, total_exercises)
WHERE scheduled_date >= CURRENT_DATE 
  AND scheduled_date < CURRENT_DATE + INTERVAL '1 day';
```

**預期效益**：
- ✅ 減少隨機 I/O 90%+
- ✅ 查詢速度提升 3-5x
- ✅ 列表頁面載入時間從 200ms → 20-30ms

#### 1.3 GIN 索引優化（JSONB）

**當前狀態**：`workout_plans.exercises` 使用 JSONB 存儲

**優化建議**：
```sql
-- 使用 jsonb_path_ops（體積小 50%，速度快 2-3x）
CREATE INDEX idx_workout_exercises_gin 
ON workout_plans 
USING GIN (exercises jsonb_path_ops);
```

**支援查詢**：
```dart
// 查詢包含特定動作的訓練
await supabase
  .from('workout_plans')
  .select()
  .contains('exercises', [{'exerciseId': 'abc123'}]);
```

#### 1.4 部分索引（Partial Indexes）⭐ **高效能優化**

**概念**：只索引特定條件的資料列，索引體積極小，常駐記憶體

**建議新增**：
```sql
-- 未完成訓練（高頻查詢）
CREATE INDEX idx_pending_workouts_partial 
ON workout_plans (trainee_id, scheduled_date DESC) 
WHERE completed = false;

-- 收藏動作（if 有 is_favorite 欄位）
CREATE INDEX idx_favorite_exercises_partial 
ON exercises (user_id, name) 
WHERE is_favorite = true;
```

**效益**：
- ✅ 索引體積 < 5% 原始大小
- ✅ 查詢速度恆定（微秒級）
- ✅ 不受歷史數據量影響

---

### 2. 查詢優化

#### 2.1 避免 SELECT * 反模式

```dart
// ❌ 錯誤：選取所有欄位（浪費 60-80% 頻寬）
final plans = await supabase.from('workout_plans').select();

// ✅ 正確：明確指定欄位
final plans = await supabase
  .from('workout_plans')
  .select('id, title, scheduled_date, completed, total_volume');
```

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

**效益**：
- ✅ 網路傳輸量減少 60-80%
- ✅ 增加 Index-Only Scan 機會
- ✅ CPU 消耗減少 40%+

#### 2.2 分頁策略：Cursor vs Offset

**問題**：傳統 Offset 分頁效能隨頁數線性衰退

```dart
// ❌ 錯誤：Offset 分頁（時間複雜度 O(N)）
final page5 = await supabase
  .from('workout_plans')
  .select()
  .range(80, 99);  // OFFSET 80，需掃描並丟棄前 80 筆
```

**Offset 分頁的問題**：
- ❌ 時間複雜度 O(N)，隨 OFFSET 值增大而變慢
- ❌ 深層分頁（如第 50 頁）可能需要數秒
- ❌ 資料漂移：新資料寫入時會導致重複或遺漏

**解決方案：Cursor-based 分頁**（時間複雜度 O(1)）

```dart
// ✅ 正確：Cursor 分頁
String? lastCursor = null;  // 首次查詢

// 載入下一頁
final nextPage = await supabase
  .from('workout_plans')
  .select('id, title, scheduled_date, completed')
  .eq('trainee_id', userId)
  .lt('scheduled_date', lastCursor ?? DateTime.now().toIso8601String())
  .order('scheduled_date', ascending: false)
  .limit(20);

// 更新游標
if (nextPage.isNotEmpty) {
  lastCursor = nextPage.last['scheduled_date'];
}
```

**Flutter 實作範例**：
```dart
class InfiniteScrollController {
  DateTime? _lastCursor;
  List<WorkoutPlan> _items = [];
  
  Future<void> loadMore() async {
    final newItems = await supabase
      .from('workout_plans')
      .select('id, title, scheduled_date, completed')
      .eq('trainee_id', userId)
      .lt('scheduled_date', _lastCursor?.toIso8601String() ?? 
          DateTime.now().toIso8601String())
      .order('scheduled_date', ascending: false)
      .limit(20);
    
    if (newItems.isNotEmpty) {
      _items.addAll(newItems.map((e) => WorkoutPlan.fromSupabase(e)));
      _lastCursor = DateTime.parse(newItems.last['scheduled_date']);
      notifyListeners();
    }
  }
}
```

**效能對比**：

| 頁數 | Offset 分頁 | Cursor 分頁 | 提升 |
|------|------------|-------------|------|
| 第 1 頁 | ~50ms | ~20ms | 60% |
| 第 10 頁 | ~200ms | ~20ms | 90% |
| 第 50 頁 | ~2000ms | ~20ms | **99%** |

#### 2.3 計數查詢（COUNT）優化

**問題**：PostgreSQL 的 MVCC 機制導致 COUNT(*) 必須全表掃描

```dart
// ❌ 錯誤：exact count（可能需要數秒）
final count = await supabase
  .from('workout_plans')
  .select('*', count: CountOption.exact);
```

**解決方案 1：Planned Count（估計值，極快）**

```dart
// ✅ 正確：planned count（O(1)，讀取統計表）
final count = await supabase
  .from('workout_plans')
  .select('id', count: CountOption.planned);
```

**解決方案 2：Counter Cache（精確值，極快）**

```sql
-- 在 users 表新增計數器欄位
ALTER TABLE users ADD COLUMN total_workouts INTEGER DEFAULT 0;

-- 建立 Trigger 自動更新
CREATE OR REPLACE FUNCTION update_workout_count()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    UPDATE users SET total_workouts = total_workouts + 1 WHERE id = NEW.trainee_id;
  ELSIF (TG_OP = 'DELETE') THEN
    UPDATE users SET total_workouts = total_workouts - 1 WHERE id = OLD.trainee_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER workout_count_trigger
AFTER INSERT OR DELETE ON workout_plans
FOR EACH ROW EXECUTE FUNCTION update_workout_count();
```

**Flutter 讀取**：
```dart
// O(1) 查詢
final user = await supabase
  .from('users')
  .select('total_workouts')
  .eq('id', userId)
  .single();
```

---

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

## 📁 資料庫遷移檔案

> 所有 SQL 遷移腳本位於 `migrations/` 目錄  
> **重大優化**（2025-01-01）：從 19 個檔案合併為 7 個 ✅

### 新的 Migrations 結構（優化後）

**完整說明**：請參考 **[migrations/README.md](../migrations/README.md)**

#### v1.0 核心（4 個檔案）

| 檔案 | 合併自 | 說明 | 大小 |
|------|--------|------|------|
| `001_v1_core_tables.sql` | 001+002+004 | 所有基礎表格（exercises, users, workout_plans, body_data 等） | 23 KB |
| `002_v1_initial_data.sql` | 008+009+011 | 系統資料（794 個動作 + 元數據修正） | 317 KB |
| `003_v1_enhancements.sql` | 012+015+016+017+018+019+020 | 功能增強（自訂動作、索引、全文搜尋、View） | 40 KB |
| `004_v1_optimization.sql` | 026 | 統計彙總表（Materialized View + 觸發器） | 18 KB |

#### v2.0 功能（3 個檔案）

| 檔案 | 合併自 | 說明 | 大小 |
|------|--------|------|------|
| `005_v2_phase1_coaching.sql` | 021 | 教練學員系統（coaching_relationships + 8 RLS） | 8 KB |
| `006_v2_phase2_appointments.sql` | 022 | 預約系統（availability_slots, appointments + 10 RLS） | 13 KB |
| `007_v2_phase3_notes.sql` | 023+024+025 | 視覺化筆記（SOAP 筆記、照片、手繪板、時間偏好） | 26 KB |

**優化成果**：
- ✅ 從 19 個 → 7 個檔案（-63%）
- ✅ 清晰的版本劃分（v1.0 vs v2.0）
- ✅ 只需要 v1.0？執行前 4 個即可
- ✅ 完整功能？執行全部 7 個
- ✅ 舊檔案已歸檔至 `archived_original/`

---

### 如何執行遷移

#### 完整部署（v1.0 + v2.0）

依序執行 **7 個檔案**：

```bash
# v1.0 核心
001_v1_core_tables.sql
002_v1_initial_data.sql
003_v1_enhancements.sql
004_v1_optimization.sql

# v2.0 功能
005_v2_phase1_coaching.sql
006_v2_phase2_appointments.sql
007_v2_phase3_notes.sql
```

#### 僅部署 v1.0（單機版）

只需執行前 **4 個檔案**。

#### 執行方式

**方法 1：Supabase Dashboard**
1. 登入 Supabase Dashboard
2. 進入 SQL Editor
3. 依序貼上每個檔案內容並執行

**方法 2：psql 命令列**
```bash
psql -U postgres -d strengthwise -f migrations/001_v1_core_tables.sql
# ... 依序執行其他檔案
```

**注意事項**：
- ⚠️ 必須按照編號順序執行（001 → 007）
- ⚠️ v2.0 的表格依賴 v1.0 的 `users` 表
- ⚠️ 需要先啟用 `pgroonga` 擴展（全文搜尋）
- ✅ 所有遷移使用 `IF NOT EXISTS`（冪等性）
- ✅ 可以重複執行（不會破壞資料）

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

## 📦 Supabase Storage

### Storage Buckets 配置（Phase 3）

StrengthWise 使用 Supabase Storage 儲存視覺化筆記的圖片資料。

#### Bucket 1: `session_photos`（課程照片）

**用途**：教練拍攝的學員訓練照片

**配置**：
- **Public**: `false`（私有）
- **File Size Limit**: 10 MB
- **Allowed MIME Types**: `image/jpeg`, `image/png`

**資料夾結構**：
```
session_photos/
└── {coach_id}/
    └── {session_id}/
        ├── {timestamp}_{filename}.jpg
        ├── {timestamp}_{filename}.png
        └── ...
```

**Storage RLS 策略**（關鍵安全性）：

```sql
-- 1. 教練上傳照片到自己的資料夾
-- 路徑結構: coach_id/client_id/filename.png
CREATE POLICY "Coaches can upload photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'session_photos' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 2. 教練查看自己上傳的照片
CREATE POLICY "Coaches view own photos"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'session_photos' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. 學員查看「共享筆記」的照片（SELECT）
-- 路徑格式：{coach_id}/{client_id}/{filename}
-- 邏輯：
--   - 學員只能看到：路徑中 client_id = 自己，且教練有「共享筆記」給他
-- 已知限制：如果教練有任何一個共享筆記給學員，學員將能看到該教練為該學員上傳的所有照片，
--           即使某些照片屬於私人筆記。這是因為 Storage RLS 無法精確到筆記 ID 層級。
--           若需更精確控制，需改用 Signed URL 方案。
CREATE POLICY "Clients can view shared session photos"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'session_photos'
  AND ((storage.foldername(name))[2] = (auth.uid())::text) -- client_id 必須是當前用戶
  AND (EXISTS (
    SELECT 1 FROM public.session_notes sn
    WHERE (
      (sn.coach_id::text = (storage.foldername(name))[1]) -- coach_id 匹配
      AND (sn.client_id = auth.uid())                     -- client_id 匹配
      AND (sn.visibility = 'shared')                      -- 筆記必須是共享的
    )
  ))
);
```

#### Bucket 2: `coach_drawings`（標註圖片）

**用途**：教練標註後的圖片（繪圖/箭頭/文字）

**配置**：
- **Public**: `false`（私有）
- **File Size Limit**: 5 MB
- **Allowed MIME Types**: `image/png`（支援透明度）

**資料夾結構**：
```
coach_drawings/
└── {coach_id}/
    └── {session_id}/
        ├── {timestamp}_drawing.png
        └── ...
```

#### Bucket 3: `voice_notes`（語音筆記）

**用途**：教練錄製的語音筆記（Phase 4）

**配置**：
- **Public**: `false`（私有）
- **File Size Limit**: 50 MB
- **Allowed MIME Types**: `audio/mpeg`, `audio/wav`, `audio/m4a`

**資料夾結構**：
```
voice_notes/
└── {coach_id}/
    └── {session_id}/
        ├── {timestamp}_voice.m4a
        └── ...
```

### Storage 使用示例

**Dart 上傳示例**：
```dart
final storage = Supabase.instance.client.storage.from('session_photos');
final file = File(imagePath);
final fileName = '${DateTime.now().millisecondsSinceEpoch}_$originalName';
final storagePath = '$coachId/$sessionId/$fileName';

await storage.upload(
  storagePath,
  file,
  fileOptions: FileOptions(contentType: 'image/jpeg'),
);
```

**Dart 獲取 Signed URL**（有效期 1 小時）：
```dart
final url = await storage.createSignedUrl(storagePath, 3600);
```

### Storage 限制與最佳實踐

**限制**：
- 單檔最大 50 MB
- 總容量視 Supabase 訂閱方案而定
- Signed URL 有效期最長 1 年

**最佳實踐**：
- ✅ 上傳前壓縮圖片（建議 < 2 MB）
- ✅ 使用 Signed URL 保護私有內容
- ✅ 定期清理過期圖片
- ✅ 設置合理的 RLS 策略
- ✅ 監控 Storage 使用量

---

## 📚 相關文檔

- `AGENTS.md` - Supabase 使用說明和開發規範
- `docs/README.md` - 文檔導航
- `docs/DEVELOPMENT_STATUS.md` - 開發狀態和變更記錄
- `docs/DATABASE_OPTIMIZATION_GUIDE.md` - 資料庫優化指南
- `migrations/*.sql` - SQL 遷移腳本
- `lib/services/*_supabase.dart` - Supabase Service 實作
- `scripts/download_complete_database.py` - 資料庫下載工具

---

**遷移完成時間**：2024年12月25日  
**總遷移數據**：805 個文檔 + 8 個頁面重構  
**遷移成功率**：100% ✅  
**最後更新**：2025年12月26日

