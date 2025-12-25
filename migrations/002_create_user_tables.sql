-- ============================================================================
-- 002_create_user_tables.sql
-- 建立用戶相關表格（使用 Supabase Auth）
-- ============================================================================

-- 啟用 UUID 擴展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

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
  
  -- 評分
  feeling_rating INTEGER DEFAULT 0,  -- 感覺評分（1-5）
  difficulty_rating INTEGER DEFAULT 0,  -- 難度評分（1-5）
  
  -- 備註
  note TEXT,
  muscle_groups JSONB DEFAULT '[]'::jsonb,  -- 鍛鍊肌群
  
  -- 時間戳記
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 約束
  CONSTRAINT valid_feeling_rating CHECK (feeling_rating BETWEEN 0 AND 5),
  CONSTRAINT valid_difficulty_rating CHECK (difficulty_rating BETWEEN 0 AND 5)
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

