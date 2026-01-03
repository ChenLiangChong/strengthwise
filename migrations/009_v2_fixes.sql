-- ============================================================================
-- Migration: 009_v2_fixes.sql
-- 描述: v2.0/v2.1/v2.2 系列修復（合併版本）
-- 日期: 2026-01-02
-- 版本: v2.2
-- ============================================================================

-- 說明：
-- 此檔案合併了以下 4 個修復：
-- 1. get_available_slots() 函數修復
-- 2. 觸發器支援布林值
-- 3. Personal Records 自動填入 body_part
-- 4. 觸發器支援 DELETE 操作

BEGIN;

-- ============================================================================
-- 1. 修復 get_available_slots() 函數
-- ============================================================================

CREATE OR REPLACE FUNCTION get_available_slots(
  input_coach_id UUID,
  input_start_date TIMESTAMPTZ,
  input_end_date TIMESTAMPTZ
)
RETURNS TABLE (
  id UUID,
  coach_id UUID,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  is_available BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id,
    a.coach_id,
    lower(a.time_range) AS start_time,
    upper(a.time_range) AS end_time,
    a.is_available
  FROM availability_slots a
  WHERE a.coach_id = input_coach_id
    AND a.time_range && tstzrange(input_start_date, input_end_date, '[)')
    AND a.is_available = true
    AND NOT EXISTS (
      SELECT 1 
      FROM appointments ap
      WHERE ap.coach_id = input_coach_id
        AND ap.time_range && a.time_range
        AND ap.status IN ('confirmed', 'pending')
    )
  ORDER BY lower(a.time_range);
END;
$$;

-- ============================================================================
-- 2. 觸發器支援布林值
-- ============================================================================

-- 修復 update_daily_workout_summary() 函數
CREATE OR REPLACE FUNCTION update_daily_workout_summary()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_completed BOOLEAN;
  v_date DATE;
  v_trainee_id UUID;
BEGIN
  -- 處理 DELETE 操作
  IF TG_OP = 'DELETE' THEN
    -- 檢查 completed 欄位（支援字串和布林）
    IF OLD.completed IS NOT NULL THEN
      IF (OLD.completed)::TEXT = 'true' THEN
        v_completed := TRUE;
      ELSIF (OLD.completed)::TEXT = 'false' THEN
        v_completed := FALSE;
      ELSE
        v_completed := FALSE;
      END IF;
    ELSE
      v_completed := FALSE;
    END IF;

    v_date := DATE(OLD.scheduled_date);
    v_trainee_id := OLD.trainee_id;

    IF v_completed THEN
      -- 減少統計
      UPDATE daily_workout_summary
      SET 
        total_workouts = GREATEST(total_workouts - 1, 0),
        updated_at = NOW()
      WHERE trainee_id = v_trainee_id AND workout_date = v_date;

      -- 清理空記錄
      DELETE FROM daily_workout_summary
      WHERE trainee_id = v_trainee_id 
        AND workout_date = v_date 
        AND total_workouts = 0;
    END IF;

    RETURN OLD;
  END IF;

  -- 處理 INSERT/UPDATE
  IF NEW.completed IS NOT NULL THEN
    IF (NEW.completed)::TEXT = 'true' THEN
      v_completed := TRUE;
    ELSIF (NEW.completed)::TEXT = 'false' THEN
      v_completed := FALSE;
    ELSE
      v_completed := FALSE;
    END IF;
  ELSE
    v_completed := FALSE;
  END IF;

  v_date := DATE(NEW.scheduled_date);
  v_trainee_id := NEW.trainee_id;

  IF v_completed THEN
    INSERT INTO daily_workout_summary (trainee_id, workout_date, total_workouts)
    VALUES (v_trainee_id, v_date, 1)
    ON CONFLICT (trainee_id, workout_date)
    DO UPDATE SET
      total_workouts = daily_workout_summary.total_workouts + 1,
      updated_at = NOW();
  END IF;

  RETURN NEW;
END;
$$;

-- 重新創建觸發器
DROP TRIGGER IF EXISTS trigger_update_daily_summary ON workout_plans;
CREATE TRIGGER trigger_update_daily_summary
  AFTER INSERT OR UPDATE OR DELETE ON workout_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_daily_workout_summary();

-- ============================================================================
-- 3. Personal Records 自動填入 body_part
-- ============================================================================

CREATE OR REPLACE FUNCTION update_personal_records()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_completed BOOLEAN;
  v_exercise JSONB;
  v_exercise_id TEXT;
  v_exercise_name TEXT;
  v_body_part TEXT;
  v_set JSONB;
  v_weight NUMERIC;
  v_reps INTEGER;
  v_volume NUMERIC;
BEGIN
  -- 檢查 completed 欄位（支援字串和布林）
  IF NEW.completed IS NOT NULL THEN
    IF (NEW.completed)::TEXT = 'true' THEN
      v_completed := TRUE;
    ELSIF (NEW.completed)::TEXT = 'false' THEN
      v_completed := FALSE;
    ELSE
      v_completed := FALSE;
    END IF;
  ELSE
    v_completed := FALSE;
  END IF;

  IF NOT v_completed THEN
    RETURN NEW;
  END IF;

  -- 遍歷每個動作
  FOR v_exercise IN SELECT * FROM jsonb_array_elements(NEW.exercises)
  LOOP
    v_exercise_id := v_exercise->>'exercise_id';
    v_exercise_name := v_exercise->>'exercise_name';
    
    -- ✅ 查詢 body_part
    SELECT e.body_parts->>0 INTO v_body_part
    FROM exercises e
    WHERE e.id = v_exercise_id;
    
    IF v_body_part IS NULL THEN
      SELECT c.body_part INTO v_body_part
      FROM custom_exercises c
      WHERE c.id = v_exercise_id;
    END IF;
    
    -- 遍歷每組
    FOR v_set IN SELECT * FROM jsonb_array_elements(v_exercise->'sets')
    LOOP
      IF (v_set->>'completed')::BOOLEAN = TRUE THEN
        v_weight := (v_set->>'weight')::NUMERIC;
        v_reps := (v_set->>'reps')::INTEGER;
        v_volume := v_weight * v_reps;
        
        -- 更新 PR（包含 body_part）
        INSERT INTO personal_records (
          user_id, exercise_id, exercise_name, body_part,
          max_weight, max_volume, max_reps, recorded_at
        )
        VALUES (
          NEW.trainee_id, v_exercise_id, v_exercise_name, v_body_part,
          v_weight, v_volume, v_reps, NEW.scheduled_date
        )
        ON CONFLICT (user_id, exercise_id)
        DO UPDATE SET
          max_weight = GREATEST(personal_records.max_weight, EXCLUDED.max_weight),
          max_volume = GREATEST(personal_records.max_volume, EXCLUDED.max_volume),
          max_reps = GREATEST(personal_records.max_reps, EXCLUDED.max_reps),
          body_part = COALESCE(EXCLUDED.body_part, personal_records.body_part),
          recorded_at = CASE
            WHEN EXCLUDED.max_weight > personal_records.max_weight 
              OR EXCLUDED.max_volume > personal_records.max_volume
              OR EXCLUDED.max_reps > personal_records.max_reps
            THEN EXCLUDED.recorded_at
            ELSE personal_records.recorded_at
          END;
      END IF;
    END LOOP;
  END LOOP;

  RETURN NEW;
END;
$$;

-- 重新計算現有記錄的 body_part
UPDATE personal_records pr
SET body_part = (
  SELECT e.body_parts->>0
  FROM exercises e
  WHERE e.id = pr.exercise_id
)
WHERE pr.body_part IS NULL;

UPDATE personal_records pr
SET body_part = (
  SELECT c.body_part
  FROM custom_exercises c
  WHERE c.id = pr.exercise_id
)
WHERE pr.body_part IS NULL;

COMMIT;

-- ============================================================================
-- 驗證
-- ============================================================================

-- 檢查函數
SELECT proname, prosrc FROM pg_proc 
WHERE proname IN ('get_available_slots', 'update_daily_workout_summary', 'update_personal_records');

-- 檢查觸發器
SELECT tgname, tgtype, tgenabled 
FROM pg_trigger 
WHERE tgname IN ('trigger_update_daily_summary', 'trigger_update_personal_records');

-- ============================================================================
-- 完成
-- ============================================================================

-- 說明：
-- ✅ get_available_slots() 函數已修復
-- ✅ 觸發器支援布林值（字串和原生布林）
-- ✅ Personal Records 自動填入 body_part
-- ✅ 觸發器支援 DELETE 操作
-- ✅ 統計數據會正確更新

