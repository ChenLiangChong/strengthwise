-- =====================================================
-- StrengthWise v1.0 - 核心表格
-- =====================================================
-- 合併自: 001, 002, 004
-- 最後更新: 2025-01-01
-- 
-- 包含表格:
-- 1. exercises (系統動作庫 - 794 個)
-- 2. body_parts, exercise_types (元數據)
-- 3. users (用戶資料)
-- 4. workout_plans (訓練計劃/記錄)
-- 5. workout_templates (訓練模板)
-- 6. custom_exercises (用戶自訂動作)
-- 7. body_data (身體數據)
-- =====================================================

-- 啟用必要的 PostgreSQL 擴展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- StrengthWise - Supabase PostgreSQL Schema
-- 階段一：核心表格建立（僅遷移系統資料）
-- ============================================================
-- 
-- 說明：
-- 1. 此遷移只包含系統級資料（exercises 和元數據表）
-- 2. users/workoutPlans 等用戶資料表會在未來需要時再建立
-- 3. 所有表格使用 UUID 主鍵（保持與 Firestore 相容）
-- ============================================================





-- ============================================================
-- 1. exercises 表（動作庫）
-- ============================================================
CREATE TABLE IF NOT EXISTS exercises (
  id TEXT PRIMARY KEY,  -- 使用 Firestore 原有的 ID（TEXT 格式）
  name TEXT NOT NULL,
  name_en TEXT,
  action_name TEXT,
  training_type TEXT,
  body_part TEXT,
  body_parts TEXT[],  -- PostgreSQL 陣列類型
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
  description TEXT DEFAULT '',
  image_url TEXT DEFAULT '',
  video_url TEXT DEFAULT '',
  user_id TEXT,  -- NULL = 系統內建動作，有值 = 用戶自定義動作
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引：提升查詢效能
CREATE INDEX IF NOT EXISTS idx_exercises_training_type ON exercises(training_type);
CREATE INDEX IF NOT EXISTS idx_exercises_body_part ON exercises(body_part);
CREATE INDEX IF NOT EXISTS idx_exercises_equipment ON exercises(equipment);
CREATE INDEX IF NOT EXISTS idx_exercises_user_id ON exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_exercises_name ON exercises(name);

-- 全文搜尋索引（未來可用於動作搜尋）
CREATE INDEX IF NOT EXISTS idx_exercises_name_trgm ON exercises USING gin(name gin_trgm_ops);

COMMENT ON TABLE exercises IS '訓練動作庫（794個系統內建動作 + 未來用戶自定義動作）';
COMMENT ON COLUMN exercises.user_id IS 'NULL = 系統內建動作，有值 = 用戶自定義動作';

-- ============================================================
-- 2. body_parts 表（身體部位元數據）
-- ============================================================
CREATE TABLE IF NOT EXISTS body_parts (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT DEFAULT '',
  count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE body_parts IS '身體部位分類（8個部位：胸、背、腿、肩等）';

-- ============================================================
-- 3. exercise_types 表（訓練類型元數據）
-- ============================================================
CREATE TABLE IF NOT EXISTS exercise_types (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT DEFAULT '',
  count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE exercise_types IS '訓練類型（3種：重訓、有氧、伸展）';

-- ============================================================
-- 4. equipments 表（器材列表元數據）
-- ============================================================
CREATE TABLE IF NOT EXISTS equipments (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT DEFAULT '',
  category TEXT,  -- 器材類別（例如：自由重量、機械式）
  count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE equipments IS '器材列表（21種器材：啞鈴、槓鈴、Cable等）';

-- ============================================================
-- 5. joint_types 表（關節類型元數據）
-- ============================================================
CREATE TABLE IF NOT EXISTS joint_types (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT DEFAULT '',
  count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE joint_types IS '關節類型（2種：單關節、多關節）';

-- ============================================================
-- Row Level Security (RLS) 策略
-- ============================================================

-- exercises: 系統動作所有人可見
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "System exercises are viewable by all authenticated users"
  ON exercises FOR SELECT
  TO authenticated
  USING (user_id IS NULL);

-- 未來用戶自定義動作政策（目前用不到，但預留）
CREATE POLICY "Users can view own custom exercises"
  ON exercises FOR SELECT
  TO authenticated
  USING (user_id = auth.uid()::text);

CREATE POLICY "Users can create custom exercises"
  ON exercises FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "Users can update own custom exercises"
  ON exercises FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid()::text);

CREATE POLICY "Users can delete own custom exercises"
  ON exercises FOR DELETE
  TO authenticated
  USING (user_id = auth.uid()::text);

-- 元數據表：所有已驗證用戶可讀
ALTER TABLE body_parts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Body parts are viewable by all authenticated users"
  ON body_parts FOR SELECT
  TO authenticated
  USING (true);

ALTER TABLE exercise_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Exercise types are viewable by all authenticated users"
  ON exercise_types FOR SELECT
  TO authenticated
  USING (true);

ALTER TABLE equipments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Equipments are viewable by all authenticated users"
  ON equipments FOR SELECT
  TO authenticated
  USING (true);

ALTER TABLE joint_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Joint types are viewable by all authenticated users"
  ON joint_types FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================
-- 完成訊息
-- ============================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Schema 建立完成！';
  RAISE NOTICE '   - exercises: 動作庫（準備接收 794 個系統動作）';
  RAISE NOTICE '   - body_parts: 身體部位（8 個）';
  RAISE NOTICE '   - exercise_types: 訓練類型（3 個）';
  RAISE NOTICE '   - equipments: 器材列表（21 個）';
  RAISE NOTICE '   - joint_types: 關節類型（2 個）';
  RAISE NOTICE '';
  RAISE NOTICE '📋 下一步：執行資料遷移腳本';
END $$;

-- ============================================================================
-- PART 2: 用戶相關表格 (來自 002)
-- ============================================================================

-- ============================================================================
-- 002_create_user_tables.sql
-- 建立用戶相關表格（使用 Supabase Auth）
-- ============================================================================




-- ============================================================================
-- 1. users 表格（公開資料，與 auth.users 同步）
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.users (
  -- 主鍵（對應 Supabase Auth UID）
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- 基本資訊
  email TEXT NOT NULL UNIQUE,
  display_name TEXT,
  photo_url TEXT,
  nickname TEXT,
  
  -- 個人資料
  gender TEXT,
  height DECIMAL(5, 2),  -- 身高（公分）
  weight DECIMAL(5, 2),  -- 體重（公斤）
  age INTEGER,
  birth_date TIMESTAMPTZ,
  
  -- 身份
  is_coach BOOLEAN DEFAULT FALSE,
  is_student BOOLEAN DEFAULT TRUE,
  
  -- 其他設定
  bio TEXT,
  unit_system TEXT DEFAULT 'metric',  -- 'metric' 或 'imperial'
  
  -- 時間戳記
  profile_created_at TIMESTAMPTZ DEFAULT NOW(),
  profile_updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ,
  
  -- 索引
  CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- 建立索引
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_is_coach ON public.users(is_coach);

-- 建立觸發器：自動更新 updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.profile_updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 2. workout_plans 表格（訓練計劃/記錄統一）
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.workout_plans (
  -- 主鍵（使用 TEXT 以相容 Firestore ID）
  id TEXT PRIMARY KEY,
  
  -- 用戶關聯
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,  -- 向後相容
  creator_id UUID REFERENCES public.users(id) ON DELETE CASCADE,  -- 創建者
  trainee_id UUID REFERENCES public.users(id) ON DELETE CASCADE,  -- 受訓者
  
  -- 基本資訊
  title TEXT NOT NULL,
  description TEXT,
  
  -- 訓練類型
  plan_type TEXT,  -- 'self' 或 'trainer'
  ui_plan_type TEXT,  -- UI 顯示的類型（如「力量訓練」）
  
  -- 日期
  scheduled_date TIMESTAMPTZ,
  completed_date TIMESTAMPTZ,
  training_time TIMESTAMPTZ,
  
  -- 訓練內容（JSONB 格式）
  exercises JSONB DEFAULT '[]'::jsonb,
  
  -- 狀態
  completed BOOLEAN DEFAULT FALSE,
  
  -- 統計
  total_exercises INTEGER DEFAULT 0,
  total_sets INTEGER DEFAULT 0,
  total_volume DECIMAL(10, 2) DEFAULT 0,  -- 訓練量（kg）
  
  -- 備註
  note TEXT,
  
  -- 時間戳記
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 建立索引
CREATE INDEX idx_workout_plans_trainee_id ON public.workout_plans(trainee_id);
CREATE INDEX idx_workout_plans_creator_id ON public.workout_plans(creator_id);
CREATE INDEX idx_workout_plans_completed ON public.workout_plans(completed);
CREATE INDEX idx_workout_plans_trainee_completed ON public.workout_plans(trainee_id, completed);
CREATE INDEX idx_workout_plans_creator_completed ON public.workout_plans(creator_id, completed);
CREATE INDEX idx_workout_plans_scheduled_date ON public.workout_plans(scheduled_date);
CREATE INDEX idx_workout_plans_exercises_gin ON public.workout_plans USING gin(exercises);

-- 建立觸發器：自動更新 updated_at
CREATE TRIGGER update_workout_plans_updated_at
  BEFORE UPDATE ON public.workout_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 3. workout_templates 表格（訓練模板）
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.workout_templates (
  -- 主鍵（使用 TEXT 以相容 Firestore ID）
  id TEXT PRIMARY KEY,
  
  -- 用戶關聯
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  
  -- 基本資訊
  title TEXT NOT NULL,
  description TEXT,
  plan_type TEXT,  -- 訓練類型（如「力量訓練」）
  
  -- 訓練內容（JSONB 格式）
  exercises JSONB DEFAULT '[]'::jsonb,
  
  -- 預設訓練時間
  training_time TIMESTAMPTZ,
  
  -- 時間戳記
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 建立索引
CREATE INDEX idx_workout_templates_user_id ON public.workout_templates(user_id);
CREATE INDEX idx_workout_templates_exercises_gin ON public.workout_templates USING gin(exercises);

-- 建立觸發器：自動更新 updated_at
CREATE TRIGGER update_workout_templates_updated_at
  BEFORE UPDATE ON public.workout_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 4. custom_exercises 表格（用戶自訂動作）
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.custom_exercises (
  -- 主鍵（使用 TEXT 以相容 Firestore ID）
  id TEXT PRIMARY KEY,
  
  -- 用戶關聯
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  
  -- 基本資訊
  name TEXT NOT NULL,
  
  -- 時間戳記
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 建立索引
CREATE INDEX idx_custom_exercises_user_id ON public.custom_exercises(user_id);
CREATE INDEX idx_custom_exercises_name ON public.custom_exercises(name);

-- ============================================================================
-- RLS（Row Level Security）策略
-- ============================================================================

-- 啟用 RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.custom_exercises ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- users 表格 RLS 策略
-- ============================================================================

-- 用戶可以讀取自己的資料
CREATE POLICY "Users can view their own profile"
  ON public.users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- 用戶可以更新自己的資料
CREATE POLICY "Users can update their own profile"
  ON public.users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 用戶可以插入自己的資料（註冊時）
CREATE POLICY "Users can insert their own profile"
  ON public.users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- 教練可以查看學員的基本資料（未來功能）
-- CREATE POLICY "Coaches can view trainee profiles"
--   ON public.users FOR SELECT
--   TO authenticated
--   USING (is_coach = true);

-- ============================================================================
-- workout_plans 表格 RLS 策略
-- ============================================================================

-- 用戶可以讀取自己的訓練計劃（作為受訓者或創建者）
CREATE POLICY "Users can view their workout plans"
  ON public.workout_plans FOR SELECT
  TO authenticated
  USING (auth.uid() = trainee_id OR auth.uid() = creator_id);

-- 用戶可以建立訓練計劃
CREATE POLICY "Users can create workout plans"
  ON public.workout_plans FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = creator_id);

-- 用戶可以更新自己的訓練計劃（作為受訓者或創建者）
CREATE POLICY "Users can update their workout plans"
  ON public.workout_plans FOR UPDATE
  TO authenticated
  USING (auth.uid() = trainee_id OR auth.uid() = creator_id)
  WITH CHECK (auth.uid() = trainee_id OR auth.uid() = creator_id);

-- 用戶可以刪除自己的訓練計劃
CREATE POLICY "Users can delete their workout plans"
  ON public.workout_plans FOR DELETE
  TO authenticated
  USING (auth.uid() = trainee_id OR auth.uid() = creator_id);

-- ============================================================================
-- workout_templates 表格 RLS 策略
-- ============================================================================

-- 用戶可以讀取自己的訓練模板
CREATE POLICY "Users can view their templates"
  ON public.workout_templates FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- 用戶可以建立訓練模板
CREATE POLICY "Users can create templates"
  ON public.workout_templates FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 用戶可以更新自己的訓練模板
CREATE POLICY "Users can update their templates"
  ON public.workout_templates FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 用戶可以刪除自己的訓練模板
CREATE POLICY "Users can delete their templates"
  ON public.workout_templates FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================================
-- custom_exercises 表格 RLS 策略
-- ============================================================================

-- 用戶可以讀取自己的自訂動作
CREATE POLICY "Users can view their custom exercises"
  ON public.custom_exercises FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- 用戶可以建立自訂動作
CREATE POLICY "Users can create custom exercises"
  ON public.custom_exercises FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 用戶可以更新自己的自訂動作
CREATE POLICY "Users can update their custom exercises"
  ON public.custom_exercises FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 用戶可以刪除自己的自訂動作
CREATE POLICY "Users can delete their custom exercises"
  ON public.custom_exercises FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================================
-- 觸發器：自動同步 auth.users 到 public.users
-- ============================================================================

-- 當新用戶註冊時，自動在 public.users 建立記錄
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, display_name, photo_url, last_login)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'display_name',
    NEW.raw_user_meta_data->>'photo_url',
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 建立觸發器（在 auth.users 表格上）
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 完成
-- ============================================================================

-- ============================================================================
-- PART 3: 身體數據表格 (來自 004)
-- ============================================================================

-- Migration: 004_create_body_data_table
-- Date: 2024-12-26
-- Description: 創建身體數據記錄表（body_data）

-- 創建表格
CREATE TABLE IF NOT EXISTS public.body_data (
  id TEXT PRIMARY KEY,                     -- Firestore 相容 ID（20 字符）
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  record_date TIMESTAMPTZ NOT NULL,        -- 記錄日期
  weight DOUBLE PRECISION NOT NULL,        -- 體重（kg）
  body_fat DOUBLE PRECISION,               -- 體脂率（%）
  muscle_mass DOUBLE PRECISION,            -- 肌肉量（kg）
  bmi DOUBLE PRECISION,                    -- BMI
  notes TEXT,                              -- 備註
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- 創建索引
CREATE INDEX IF NOT EXISTS idx_body_data_user_id ON public.body_data(user_id);
CREATE INDEX IF NOT EXISTS idx_body_data_record_date ON public.body_data(record_date DESC);
CREATE INDEX IF NOT EXISTS idx_body_data_user_date ON public.body_data(user_id, record_date DESC);

-- 新增註解
COMMENT ON TABLE public.body_data IS '身體數據記錄表';
COMMENT ON COLUMN public.body_data.id IS 'Firestore 相容 ID（20 字符）';
COMMENT ON COLUMN public.body_data.user_id IS '用戶 ID（關聯 users 表）';
COMMENT ON COLUMN public.body_data.record_date IS '記錄日期';
COMMENT ON COLUMN public.body_data.weight IS '體重（單位：公斤）';
COMMENT ON COLUMN public.body_data.body_fat IS '體脂率（%）';
COMMENT ON COLUMN public.body_data.muscle_mass IS '肌肉量（單位：公斤）';
COMMENT ON COLUMN public.body_data.bmi IS 'BMI 指數';
COMMENT ON COLUMN public.body_data.notes IS '備註';

-- 新增檢查約束（確保數據合理性）
ALTER TABLE public.body_data
  ADD CONSTRAINT check_body_data_weight_range CHECK (weight >= 30 AND weight <= 300),
  ADD CONSTRAINT check_body_data_body_fat_range CHECK (body_fat IS NULL OR (body_fat >= 3 AND body_fat <= 60)),
  ADD CONSTRAINT check_body_data_muscle_mass_range CHECK (muscle_mass IS NULL OR (muscle_mass >= 10 AND muscle_mass <= 200)),
  ADD CONSTRAINT check_body_data_bmi_range CHECK (bmi IS NULL OR (bmi >= 10 AND bmi <= 60));

-- 啟用 Row Level Security (RLS)
ALTER TABLE public.body_data ENABLE ROW LEVEL SECURITY;

-- 創建 RLS 策略：用戶只能查看和修改自己的身體數據
CREATE POLICY "Users can view their own body data"
  ON public.body_data FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own body data"
  ON public.body_data FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own body data"
  ON public.body_data FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own body data"
  ON public.body_data FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 完成訊息
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ v1.0 核心表格建立完成！';
  RAISE NOTICE '   - 系統表格: exercises, body_parts, exercise_types';
  RAISE NOTICE '   - 用戶表格: users, workout_plans, workout_templates';
  RAISE NOTICE '   - 其他表格: custom_exercises, body_data';
  RAISE NOTICE '';
  RAISE NOTICE '📋 下一步: 執行 002_v1_initial_data.sql 導入系統動作資料';
END $$;
