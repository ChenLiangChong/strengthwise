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

