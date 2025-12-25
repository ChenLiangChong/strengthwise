-- Migration: 003_add_user_body_data_fields
-- Date: 2024-12-26
-- Description: 為 users 表新增身體數據欄位（身高、體重、年齡、性別）

-- 新增欄位
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS height DOUBLE PRECISION,  -- 身高（cm）
  ADD COLUMN IF NOT EXISTS weight DOUBLE PRECISION,  -- 體重（kg）
  ADD COLUMN IF NOT EXISTS age INTEGER,              -- 年齡（歲）
  ADD COLUMN IF NOT EXISTS gender TEXT;              -- 性別（男/女/其他）

-- 新增註解
COMMENT ON COLUMN public.users.height IS '身高（單位：公分）';
COMMENT ON COLUMN public.users.weight IS '體重（單位：公斤）';
COMMENT ON COLUMN public.users.age IS '年齡（歲）';
COMMENT ON COLUMN public.users.gender IS '性別（男/女/其他）';

-- 新增檢查約束（確保數據合理性）
ALTER TABLE public.users
  ADD CONSTRAINT check_height_range CHECK (height IS NULL OR (height >= 100 AND height <= 250)),
  ADD CONSTRAINT check_weight_range CHECK (weight IS NULL OR (weight >= 30 AND weight <= 300)),
  ADD CONSTRAINT check_age_range CHECK (age IS NULL OR (age >= 10 AND age <= 120)),
  ADD CONSTRAINT check_gender_value CHECK (gender IS NULL OR gender IN ('男', '女', '其他'));

