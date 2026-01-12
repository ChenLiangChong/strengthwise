-- ============================================================================
-- StrengthWise Migration: 19_v3_rls_and_summary.sql
-- ============================================================================
-- 合併自: 036_fix_missing_rls.sql, 037_fix_daily_summary_rls.sql, 
--        038_fix_daily_summary_trigger.sql, 039_add_scheduled_workout_count.sql,
--        040_coach_create_appointment_rls.sql, 041_cancel_appointment_cleanup.sql
-- 版本: v3.1.1
-- 日期: 2026-01-06 ~ 2026-01-09
-- ============================================================================
-- 
-- 包含:
-- 1. daily_workout_summary 和 personal_records RLS
-- 2. daily_workout_summary 觸發器修復
-- 3. scheduled_workout_count 欄位
-- 4. 教練創建預約 RLS
-- 5. 預約取消/拒絕清理觸發器
-- ============================================================================

-- ============================================================================
-- PART 1: 啟用 RLS
-- ============================================================================

ALTER TABLE daily_workout_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_records ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PART 2: daily_workout_summary RLS 策略
-- ============================================================================

DROP POLICY IF EXISTS "Users can view own daily summary" ON daily_workout_summary;
DROP POLICY IF EXISTS "daily_summary_select" ON daily_workout_summary;
DROP POLICY IF EXISTS "daily_summary_insert" ON daily_workout_summary;
DROP POLICY IF EXISTS "daily_summary_update" ON daily_workout_summary;
DROP POLICY IF EXISTS "daily_summary_delete" ON daily_workout_summary;

CREATE POLICY "daily_summary_select"
  ON daily_workout_summary FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = daily_workout_summary.user_id
        AND cr.status = 'active'
    )
  );

CREATE POLICY "daily_summary_insert"
  ON daily_workout_summary FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = user_id
        AND cr.status = 'active'
    )
  );

CREATE POLICY "daily_summary_update"
  ON daily_workout_summary FOR UPDATE
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = daily_workout_summary.user_id
        AND cr.status = 'active'
    )
  )
  WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = user_id
        AND cr.status = 'active'
    )
  );

CREATE POLICY "daily_summary_delete"
  ON daily_workout_summary FOR DELETE
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = daily_workout_summary.user_id
        AND cr.status = 'active'
    )
  );

-- ============================================================================
-- PART 3: personal_records RLS 策略
-- ============================================================================

DROP POLICY IF EXISTS "Users can view own personal records" ON personal_records;
DROP POLICY IF EXISTS "personal_records_select" ON personal_records;
DROP POLICY IF EXISTS "personal_records_insert" ON personal_records;
DROP POLICY IF EXISTS "personal_records_update" ON personal_records;
DROP POLICY IF EXISTS "personal_records_delete" ON personal_records;

CREATE POLICY "personal_records_select"
  ON personal_records FOR SELECT
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = personal_records.user_id
        AND cr.status = 'active'
    )
  );

CREATE POLICY "personal_records_insert"
  ON personal_records FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = user_id
        AND cr.status = 'active'
    )
  );

CREATE POLICY "personal_records_update"
  ON personal_records FOR UPDATE
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = personal_records.user_id
        AND cr.status = 'active'
    )
  )
  WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = user_id
        AND cr.status = 'active'
    )
  );

CREATE POLICY "personal_records_delete"
  ON personal_records FOR DELETE
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = personal_records.user_id
        AND cr.status = 'active'
    )
  );

-- ============================================================================
-- PART 4: 新增 scheduled_workout_count 欄位
-- ============================================================================

ALTER TABLE daily_workout_summary 
ADD COLUMN IF NOT EXISTS scheduled_workout_count INT DEFAULT 0;

COMMENT ON COLUMN daily_workout_summary.scheduled_workout_count IS '該日期全部排定的訓練計劃數';

-- ============================================================================
-- PART 5: update_daily_workout_summary() 觸發器（最終版）
-- ============================================================================

DROP TRIGGER IF EXISTS trigger_update_daily_summary ON workout_plans;

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

  DELETE FROM daily_workout_summary
  WHERE user_id = target_user_id 
    AND date = target_date
    AND scheduled_workout_count = 0;

  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_daily_summary
  AFTER INSERT OR UPDATE OR DELETE ON workout_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_daily_workout_summary();

-- ============================================================================
-- PART 6: 教練創建預約 RLS 策略
-- ============================================================================

DROP POLICY IF EXISTS "coaches_create_appointments" ON public.appointments;
CREATE POLICY "coaches_create_appointments"
ON public.appointments FOR INSERT
WITH CHECK (
  auth.uid() = coach_id
  AND EXISTS (
    SELECT 1 FROM public.coaching_relationships cr
    WHERE cr.coach_id = auth.uid()
      AND cr.client_id = appointments.client_id
      AND cr.status = 'active'
  )
);

-- ============================================================================
-- PART 7: 預約取消清理觸發器
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_cancelled_appointment_data()
RETURNS TRIGGER AS $$
DECLARE
  v_deleted_notes INT := 0;
  v_deleted_readiness INT := 0;
  v_deleted_workouts INT := 0;
BEGIN
  IF NEW.status = 'cancelled' AND (OLD.status IS NULL OR OLD.status != 'cancelled') THEN
    DELETE FROM session_notes WHERE appointment_id = NEW.id;
    GET DIAGNOSTICS v_deleted_notes = ROW_COUNT;
    
    DELETE FROM daily_readiness WHERE appointment_id = NEW.id;
    GET DIAGNOSTICS v_deleted_readiness = ROW_COUNT;
    
    IF NEW.workout_plan_id IS NOT NULL THEN
      DELETE FROM workout_plans WHERE id = NEW.workout_plan_id;
      GET DIAGNOSTICS v_deleted_workouts = ROW_COUNT;
    END IF;
    
    RAISE NOTICE '🗑️ 預約取消清理 - %: notes=%, readiness=%, workouts=%',
      NEW.id, v_deleted_notes, v_deleted_readiness, v_deleted_workouts;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_cleanup_cancelled_appointment ON appointments;
CREATE TRIGGER trg_cleanup_cancelled_appointment
  AFTER UPDATE OF status ON appointments
  FOR EACH ROW
  WHEN (NEW.status = 'cancelled')
  EXECUTE FUNCTION cleanup_cancelled_appointment_data();

-- 預約拒絕清理
CREATE OR REPLACE FUNCTION cleanup_rejected_appointment_data()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'rejected' AND (OLD.status IS NULL OR OLD.status != 'rejected') THEN
    DELETE FROM session_notes WHERE appointment_id = NEW.id;
    DELETE FROM daily_readiness WHERE appointment_id = NEW.id;
    RAISE NOTICE '🗑️ 預約拒絕清理 - %', NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_cleanup_rejected_appointment ON appointments;
CREATE TRIGGER trg_cleanup_rejected_appointment
  AFTER UPDATE OF status ON appointments
  FOR EACH ROW
  WHEN (NEW.status = 'rejected')
  EXECUTE FUNCTION cleanup_rejected_appointment_data();

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 19 完成：RLS 與統計修復';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'RLS 策略：';
  RAISE NOTICE '  ✅ daily_workout_summary - SELECT/INSERT/UPDATE/DELETE';
  RAISE NOTICE '  ✅ personal_records - SELECT/INSERT/UPDATE/DELETE';
  RAISE NOTICE '  ✅ 教練創建預約策略';
  RAISE NOTICE '';
  RAISE NOTICE '新增欄位：';
  RAISE NOTICE '  ✅ daily_workout_summary.scheduled_workout_count';
  RAISE NOTICE '';
  RAISE NOTICE '觸發器：';
  RAISE NOTICE '  ✅ update_daily_workout_summary() - 基於 set.completed';
  RAISE NOTICE '  ✅ cleanup_cancelled_appointment_data()';
  RAISE NOTICE '  ✅ cleanup_rejected_appointment_data()';
  RAISE NOTICE '';
END $$;
