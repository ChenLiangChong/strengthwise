-- ============================================================================
-- Migration 36: 修復刪除訓練計畫後 daily_workout_summary 殘留
-- ============================================================================
-- 問題：當最後一筆當日計畫被刪除時，INSERT ... SELECT 回傳空結果，
--       ON CONFLICT DO UPDATE 不觸發，舊 summary 行殘留
-- 修復：INSERT 後加 NOT FOUND 檢查，主動刪除殘留行
-- ============================================================================

-- PART 1: 修正觸發器函式
CREATE OR REPLACE FUNCTION update_daily_workout_summary()
RETURNS TRIGGER AS $$
DECLARE
  target_user_id UUID;
  target_date DATE;
BEGIN
  IF TG_OP = 'DELETE' THEN
    target_user_id := OLD.trainee_id;
    target_date := COALESCE(OLD.completed_date::DATE, OLD.scheduled_date::DATE, OLD.updated_at::DATE);
  ELSE
    target_user_id := NEW.trainee_id;
    target_date := COALESCE(NEW.completed_date::DATE, NEW.scheduled_date::DATE, NEW.updated_at::DATE);
  END IF;

  INSERT INTO daily_workout_summary (
    user_id, date, scheduled_workout_count, workout_count, completed_workout_count,
    partial_workout_count, total_exercises, total_sets, total_volume,
    resistance_training_count, cardio_count, mobility_count, total_training_time, updated_at
  )
  SELECT
    target_user_id, target_date,
    COUNT(DISTINCT wp.id) AS scheduled_workout_count,
    COUNT(DISTINCT wp.id) FILTER (
      WHERE EXISTS (
        SELECT 1 FROM jsonb_array_elements(wp.exercises) AS ex,
        jsonb_array_elements(ex->'sets') AS s
        WHERE (s->>'completed')::BOOLEAN = TRUE
      )
    ) AS workout_count,
    COUNT(DISTINCT wp.id) FILTER (WHERE wp.completed = TRUE) AS completed_workout_count,
    COUNT(DISTINCT wp.id) FILTER (
      WHERE wp.completed = FALSE
      AND EXISTS (
        SELECT 1 FROM jsonb_array_elements(wp.exercises) AS ex,
        jsonb_array_elements(ex->'sets') AS s
        WHERE (s->>'completed')::BOOLEAN = TRUE
      )
    ) AS partial_workout_count,
    (
      SELECT COUNT(DISTINCT ex->>'exerciseId')
      FROM workout_plans wp2,
      LATERAL jsonb_array_elements(wp2.exercises) AS ex,
      LATERAL jsonb_array_elements(ex->'sets') AS s
      WHERE wp2.trainee_id = target_user_id
        AND COALESCE(wp2.completed_date::DATE, wp2.scheduled_date::DATE, wp2.updated_at::DATE) = target_date
        AND (s->>'completed')::BOOLEAN = TRUE
    )::INT AS total_exercises,
    (
      SELECT COUNT(*)
      FROM workout_plans wp2,
      LATERAL jsonb_array_elements(wp2.exercises) AS ex,
      LATERAL jsonb_array_elements(ex->'sets') AS s
      WHERE wp2.trainee_id = target_user_id
        AND COALESCE(wp2.completed_date::DATE, wp2.scheduled_date::DATE, wp2.updated_at::DATE) = target_date
        AND (s->>'completed')::BOOLEAN = TRUE
    )::INT AS total_sets,
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
    0, 0, 0, 0, NOW()
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

  -- ⭐ 修復：當該日期已無任何計畫時，INSERT ... SELECT 回傳空結果，
  -- NOT FOUND 為 TRUE，需主動刪除殘留的 summary 行
  IF NOT FOUND THEN
    DELETE FROM daily_workout_summary
    WHERE user_id = target_user_id AND date = target_date;
  END IF;

  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$ LANGUAGE plpgsql;

-- PART 2: 清理現有殘留資料（一次性）
DELETE FROM daily_workout_summary dws
WHERE NOT EXISTS (
  SELECT 1 FROM workout_plans wp
  WHERE wp.trainee_id = dws.user_id
    AND COALESCE(wp.completed_date::DATE, wp.scheduled_date::DATE, wp.updated_at::DATE) = dws.date
);
