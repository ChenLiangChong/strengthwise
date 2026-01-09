-- ============================================================================
-- StrengthWise Migration: 039_add_scheduled_workout_count.sql
-- ============================================================================
-- 建立時間：2026-01-09
-- 目標：新增 scheduled_workout_count 欄位，統計全部訓練計劃（包括 PENDING）
-- ============================================================================
-- 
-- 用戶需求：
-- - 訓練計劃總數 = 全部 workout_plans（包括未開始的 PENDING）
-- - 完整完成 = workout_plans.completed = true
-- - 部分完成 = 有 set.completed 但 workout_plans.completed = false
-- - 未開始 = 沒有任何 set.completed（可計算：總數 - 完整 - 部分）
--
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. 新增欄位
-- ============================================================================

ALTER TABLE daily_workout_summary 
ADD COLUMN IF NOT EXISTS scheduled_workout_count INT DEFAULT 0;

COMMENT ON COLUMN daily_workout_summary.scheduled_workout_count IS '該日期全部排定的訓練計劃數（包括未開始的）';

-- ============================================================================
-- 2. 刪除舊的觸發器
-- ============================================================================

DROP TRIGGER IF EXISTS trigger_update_daily_summary ON workout_plans;

-- ============================================================================
-- 3. 創建新的觸發器函數（增加 scheduled_workout_count）
-- ============================================================================

CREATE OR REPLACE FUNCTION update_daily_workout_summary()
RETURNS TRIGGER AS $$
DECLARE
  target_user_id UUID;
  target_date DATE;
BEGIN
  -- 決定要更新哪個用戶的哪一天
  IF TG_OP = 'DELETE' THEN
    target_user_id := OLD.trainee_id;
    target_date := COALESCE(OLD.completed_date::DATE, OLD.scheduled_date::DATE, OLD.updated_at::DATE);
  ELSE
    target_user_id := NEW.trainee_id;
    target_date := COALESCE(NEW.completed_date::DATE, NEW.scheduled_date::DATE, NEW.updated_at::DATE);
  END IF;

  -- ⭐ 重新聚合該日期的所有訓練數據
  INSERT INTO daily_workout_summary (
    user_id, 
    date, 
    scheduled_workout_count,
    workout_count,
    completed_workout_count,
    partial_workout_count,
    total_exercises, 
    total_sets, 
    total_volume,
    resistance_training_count, 
    cardio_count, 
    mobility_count,
    total_training_time,
    updated_at
  )
  SELECT
    target_user_id AS user_id,
    target_date AS date,
    
    -- ⭐ 新增：全部排定的訓練計劃數（包括 PENDING）
    COUNT(DISTINCT wp.id) AS scheduled_workout_count,
    
    -- 有活動的訓練計劃數（有至少 1 組完成的）
    COUNT(DISTINCT wp.id) FILTER (
      WHERE EXISTS (
        SELECT 1 
        FROM jsonb_array_elements(wp.exercises) AS ex,
        jsonb_array_elements(ex->'sets') AS s
        WHERE (s->>'completed')::BOOLEAN = TRUE
      )
    ) AS workout_count,
    
    -- 完整完成的訓練計劃數
    COUNT(DISTINCT wp.id) FILTER (WHERE wp.completed = TRUE) AS completed_workout_count,
    
    -- 部分完成的訓練計劃數
    COUNT(DISTINCT wp.id) FILTER (
      WHERE wp.completed = FALSE 
      AND EXISTS (
        SELECT 1 
        FROM jsonb_array_elements(wp.exercises) AS ex,
        jsonb_array_elements(ex->'sets') AS s
        WHERE (s->>'completed')::BOOLEAN = TRUE
      )
    ) AS partial_workout_count,
    
    -- 統計有至少 1 組完成的不同動作數
    (
      SELECT COUNT(DISTINCT ex->>'exerciseId')
      FROM workout_plans wp2,
      LATERAL jsonb_array_elements(wp2.exercises) AS ex,
      LATERAL jsonb_array_elements(ex->'sets') AS s
      WHERE wp2.trainee_id = target_user_id
        AND COALESCE(wp2.completed_date::DATE, wp2.scheduled_date::DATE, wp2.updated_at::DATE) = target_date
        AND (s->>'completed')::BOOLEAN = TRUE
    )::INT AS total_exercises,
    
    -- 統計完成的組數
    (
      SELECT COUNT(*)
      FROM workout_plans wp2,
      LATERAL jsonb_array_elements(wp2.exercises) AS ex,
      LATERAL jsonb_array_elements(ex->'sets') AS s
      WHERE wp2.trainee_id = target_user_id
        AND COALESCE(wp2.completed_date::DATE, wp2.scheduled_date::DATE, wp2.updated_at::DATE) = target_date
        AND (s->>'completed')::BOOLEAN = TRUE
    )::INT AS total_sets,
    
    -- 統計完成組的總訓練量
    (
      SELECT COALESCE(SUM(
        COALESCE((s->>'weight')::DECIMAL, 0) * COALESCE((s->>'reps')::INT, 0)
      ), 0)
      FROM workout_plans wp2,
      LATERAL jsonb_array_elements(wp2.exercises) AS ex,
      LATERAL jsonb_array_elements(ex->'sets') AS s
      WHERE wp2.trainee_id = target_user_id
        AND COALESCE(wp2.completed_date::DATE, wp2.scheduled_date::DATE, wp2.updated_at::DATE) = target_date
        AND (s->>'completed')::BOOLEAN = TRUE
    )::DECIMAL(10,2) AS total_volume,
    
    0 AS resistance_training_count,
    0 AS cardio_count,
    0 AS mobility_count,
    0 AS total_training_time,
    NOW() AS updated_at
  FROM workout_plans wp
  WHERE wp.trainee_id = target_user_id
    AND COALESCE(wp.completed_date::DATE, wp.scheduled_date::DATE, wp.updated_at::DATE) = target_date
  GROUP BY target_user_id, target_date
  
  ON CONFLICT (user_id, date) DO UPDATE SET
    scheduled_workout_count = EXCLUDED.scheduled_workout_count,
    workout_count = EXCLUDED.workout_count,
    completed_workout_count = EXCLUDED.completed_workout_count,
    partial_workout_count = EXCLUDED.partial_workout_count,
    total_exercises = EXCLUDED.total_exercises,
    total_sets = EXCLUDED.total_sets,
    total_volume = EXCLUDED.total_volume,
    updated_at = NOW();

  -- ⭐ 修改：只有當該日期沒有任何訓練計劃時才刪除記錄
  DELETE FROM daily_workout_summary
  WHERE user_id = target_user_id 
    AND date = target_date
    AND scheduled_workout_count = 0;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 4. 重新創建觸發器
-- ============================================================================

CREATE TRIGGER trigger_update_daily_summary
  AFTER INSERT OR UPDATE OR DELETE
  ON workout_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_daily_workout_summary();

COMMIT;

-- ============================================================================
-- 5. 重新計算所有現有數據的彙總
-- ============================================================================

-- 先清空
DELETE FROM daily_workout_summary;

-- 使用 CTE 重新計算（包括 scheduled_workout_count）
WITH workout_dates AS (
  SELECT DISTINCT 
    trainee_id,
    COALESCE(completed_date::DATE, scheduled_date::DATE, updated_at::DATE) AS training_date
  FROM workout_plans
  WHERE exercises IS NOT NULL 
    AND jsonb_array_length(exercises) > 0
),
calculated_stats AS (
  SELECT 
    wd.trainee_id AS user_id,
    wd.training_date AS date,
    
    -- ⭐ 新增：scheduled_workout_count（全部排定的訓練計劃）
    (
      SELECT COUNT(DISTINCT wp.id)
      FROM workout_plans wp
      WHERE wp.trainee_id = wd.trainee_id
        AND COALESCE(wp.completed_date::DATE, wp.scheduled_date::DATE, wp.updated_at::DATE) = wd.training_date
    )::INT AS scheduled_workout_count,
    
    -- workout_count（有活動的）
    (
      SELECT COUNT(DISTINCT wp.id)
      FROM workout_plans wp
      WHERE wp.trainee_id = wd.trainee_id
        AND COALESCE(wp.completed_date::DATE, wp.scheduled_date::DATE, wp.updated_at::DATE) = wd.training_date
        AND EXISTS (
          SELECT 1 
          FROM jsonb_array_elements(wp.exercises) AS ex,
          jsonb_array_elements(ex->'sets') AS s
          WHERE (s->>'completed')::BOOLEAN = TRUE
        )
    )::INT AS workout_count,
    
    -- completed_workout_count
    (
      SELECT COUNT(DISTINCT wp.id)
      FROM workout_plans wp
      WHERE wp.trainee_id = wd.trainee_id
        AND COALESCE(wp.completed_date::DATE, wp.scheduled_date::DATE, wp.updated_at::DATE) = wd.training_date
        AND wp.completed = TRUE
    )::INT AS completed_workout_count,
    
    -- partial_workout_count
    (
      SELECT COUNT(DISTINCT wp.id)
      FROM workout_plans wp
      WHERE wp.trainee_id = wd.trainee_id
        AND COALESCE(wp.completed_date::DATE, wp.scheduled_date::DATE, wp.updated_at::DATE) = wd.training_date
        AND wp.completed = FALSE
        AND EXISTS (
          SELECT 1 
          FROM jsonb_array_elements(wp.exercises) AS ex,
          jsonb_array_elements(ex->'sets') AS s
          WHERE (s->>'completed')::BOOLEAN = TRUE
        )
    )::INT AS partial_workout_count,
    
    -- total_exercises
    (
      SELECT COUNT(DISTINCT ex->>'exerciseId')
      FROM workout_plans wp,
      LATERAL jsonb_array_elements(wp.exercises) AS ex,
      LATERAL jsonb_array_elements(ex->'sets') AS s
      WHERE wp.trainee_id = wd.trainee_id
        AND COALESCE(wp.completed_date::DATE, wp.scheduled_date::DATE, wp.updated_at::DATE) = wd.training_date
        AND (s->>'completed')::BOOLEAN = TRUE
    )::INT AS total_exercises,
    
    -- total_sets
    (
      SELECT COUNT(*)
      FROM workout_plans wp,
      LATERAL jsonb_array_elements(wp.exercises) AS ex,
      LATERAL jsonb_array_elements(ex->'sets') AS s
      WHERE wp.trainee_id = wd.trainee_id
        AND COALESCE(wp.completed_date::DATE, wp.scheduled_date::DATE, wp.updated_at::DATE) = wd.training_date
        AND (s->>'completed')::BOOLEAN = TRUE
    )::INT AS total_sets,
    
    -- total_volume
    (
      SELECT COALESCE(SUM(
        COALESCE((s->>'weight')::DECIMAL, 0) * COALESCE((s->>'reps')::INT, 0)
      ), 0)
      FROM workout_plans wp,
      LATERAL jsonb_array_elements(wp.exercises) AS ex,
      LATERAL jsonb_array_elements(ex->'sets') AS s
      WHERE wp.trainee_id = wd.trainee_id
        AND COALESCE(wp.completed_date::DATE, wp.scheduled_date::DATE, wp.updated_at::DATE) = wd.training_date
        AND (s->>'completed')::BOOLEAN = TRUE
    )::DECIMAL(10,2) AS total_volume
    
  FROM workout_dates wd
)
INSERT INTO daily_workout_summary (
  user_id, date, scheduled_workout_count, workout_count, completed_workout_count, partial_workout_count,
  total_exercises, total_sets, total_volume,
  resistance_training_count, cardio_count, mobility_count, total_training_time, updated_at
)
SELECT 
  user_id, date, scheduled_workout_count, workout_count, completed_workout_count, partial_workout_count,
  total_exercises, total_sets, total_volume,
  0, 0, 0, 0, NOW()
FROM calculated_stats
WHERE scheduled_workout_count > 0;

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ 
DECLARE
  record_count INT;
BEGIN
  SELECT COUNT(*) INTO record_count FROM daily_workout_summary;
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE 'Migration 039: scheduled_workout_count added';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '  Generated % daily summary records', record_count;
  RAISE NOTICE '';
END $$;
