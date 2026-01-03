-- =====================================================
-- 008: 訓練計畫時間範圍欄位 (v2.1) - 無約束版本
-- =====================================================
-- 目的：先添加欄位和索引，不添加排除約束
-- 等清理完衝突數據後再手動添加約束
-- =====================================================

-- 1. 添加 training_time_range 欄位
ALTER TABLE public.workout_plans
ADD COLUMN IF NOT EXISTS training_time_range TSTZRANGE;

-- 2. 為現有數據回填（假設訓練時長為 1 小時）
UPDATE public.workout_plans
SET training_time_range = TSTZRANGE(training_time, training_time + INTERVAL '1 hour')
WHERE training_time IS NOT NULL 
  AND training_time_range IS NULL;

-- 3. 為 training_time_range 欄位添加索引（GiST）
CREATE INDEX IF NOT EXISTS idx_workout_plans_time_range 
ON public.workout_plans 
USING GIST (training_time_range);

-- 4. 為 trainee_id 添加額外的 B-tree 索引
CREATE INDEX IF NOT EXISTS idx_workout_plans_trainee_id 
ON public.workout_plans (trainee_id);

-- 5. 複合索引：trainee_id + training_time_range
CREATE INDEX IF NOT EXISTS idx_workout_plans_trainee_time_range 
ON public.workout_plans 
USING GIST (trainee_id, training_time_range);

-- 6. 啟用 btree_gist 擴展（為後續添加約束做準備）
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- =====================================================
-- 清理衝突數據後，手動執行以下語句添加約束
-- =====================================================
-- ALTER TABLE public.workout_plans
-- ADD CONSTRAINT workout_plans_no_overlap_trainee
-- EXCLUDE USING GIST (
--   trainee_id WITH =,
--   training_time_range WITH &&
-- )
-- WHERE (training_time_range IS NOT NULL);

