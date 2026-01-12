-- ============================================================================
-- StrengthWise Migration: 09_v2_fixes_and_enhancements.sql
-- ============================================================================
-- 合併自: 009_v2_fixes.sql, 010_v2_enhancements.sql
-- 版本: v2.2-v2.3
-- 日期: 2026-01-02
-- ============================================================================
-- 
-- 包含:
-- 1. get_available_slots() 函數修復
-- 2. 觸發器支援布林值
-- 3. Personal Records 自動填入 body_part
-- 4. 觸發器支援 DELETE 操作
-- 5. 移除 workout_templates.training_time 欄位
-- 6. 新增 users.gender_visible 欄位
-- 7. 修復 custom_exercises RLS 策略
-- 8. 修復 delete_user_account() 函數
-- ============================================================================

BEGIN;

-- ============================================================================
-- PART 1: v2.0/v2.1/v2.2 系列修復 (來自 009)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1.1 修復 get_available_slots() 函數
-- ----------------------------------------------------------------------------

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

-- ----------------------------------------------------------------------------
-- 1.2 修復 update_daily_workout_summary() 函數 - 支援布林值
-- ----------------------------------------------------------------------------

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
      UPDATE daily_workout_summary
      SET 
        total_workouts = GREATEST(total_workouts - 1, 0),
        updated_at = NOW()
      WHERE trainee_id = v_trainee_id AND workout_date = v_date;

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

-- ----------------------------------------------------------------------------
-- 1.3 Personal Records 自動填入 body_part
-- ----------------------------------------------------------------------------

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

  FOR v_exercise IN SELECT * FROM jsonb_array_elements(NEW.exercises)
  LOOP
    v_exercise_id := v_exercise->>'exercise_id';
    v_exercise_name := v_exercise->>'exercise_name';
    
    -- 查詢 body_part
    SELECT e.body_parts->>0 INTO v_body_part
    FROM exercises e
    WHERE e.id = v_exercise_id;
    
    IF v_body_part IS NULL THEN
      SELECT c.body_part INTO v_body_part
      FROM custom_exercises c
      WHERE c.id = v_exercise_id;
    END IF;
    
    FOR v_set IN SELECT * FROM jsonb_array_elements(v_exercise->'sets')
    LOOP
      IF (v_set->>'completed')::BOOLEAN = TRUE THEN
        v_weight := (v_set->>'weight')::NUMERIC;
        v_reps := (v_set->>'reps')::INTEGER;
        v_volume := v_weight * v_reps;
        
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

-- ============================================================================
-- PART 2: v2.2/v2.3 系列功能增強 (來自 010)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1 移除 workout_templates.training_time 欄位
-- ----------------------------------------------------------------------------

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'workout_templates'
      AND column_name = 'training_time'
  ) THEN
    ALTER TABLE public.workout_templates DROP COLUMN training_time;
    RAISE NOTICE '✅ 已刪除 workout_templates.training_time 欄位';
  ELSE
    RAISE NOTICE 'ℹ️ training_time 欄位不存在，跳過';
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 2.2 新增 users.gender_visible 欄位
-- ----------------------------------------------------------------------------

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'users' 
    AND column_name = 'gender_visible'
  ) THEN
    ALTER TABLE public.users 
    ADD COLUMN gender_visible BOOLEAN NOT NULL DEFAULT true;
    
    RAISE NOTICE '✅ 已新增 gender_visible 欄位到 users 表格';
  ELSE
    RAISE NOTICE 'ℹ️ gender_visible 欄位已存在，跳過';
  END IF;
END $$;

UPDATE public.users
SET gender_visible = true
WHERE gender_visible IS NULL;

COMMENT ON COLUMN public.users.gender_visible IS '性別是否對其他人可見（預設：true）';

-- ----------------------------------------------------------------------------
-- 2.3 修復 custom_exercises RLS 策略
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can view their custom exercises" ON public.custom_exercises;
DROP POLICY IF EXISTS "Users can create custom exercises" ON public.custom_exercises;
DROP POLICY IF EXISTS "Users can update their custom exercises" ON public.custom_exercises;
DROP POLICY IF EXISTS "Users can delete their custom exercises" ON public.custom_exercises;

CREATE POLICY "Users can view custom exercises"
  ON public.custom_exercises FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id OR user_id IS NULL
  );

CREATE POLICY "Users can create custom exercises"
  ON public.custom_exercises FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their custom exercises"
  ON public.custom_exercises FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their custom exercises"
  ON public.custom_exercises FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 2.4 修復 delete_user_account() 函數
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION delete_user_account(target_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_counts JSONB;
    coaching_count INT;
    appointment_count INT;
    workout_self_count INT;
    workout_preserved_count INT;
    template_count INT;
    custom_exercise_count INT;
    private_notes_count INT;
    shared_notes_count INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = target_user_id) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;

    SELECT COUNT(*) INTO coaching_count 
    FROM public.coaching_relationships 
    WHERE coach_id = target_user_id OR client_id = target_user_id;

    SELECT COUNT(*) INTO appointment_count 
    FROM public.appointments 
    WHERE coach_id = target_user_id OR client_id = target_user_id;

    SELECT COUNT(*) INTO workout_self_count 
    FROM public.workout_plans 
    WHERE trainee_id = target_user_id;

    SELECT COUNT(*) INTO workout_preserved_count 
    FROM public.workout_plans 
    WHERE creator_id = target_user_id AND trainee_id != target_user_id;

    SELECT COUNT(*) INTO template_count 
    FROM public.workout_templates 
    WHERE user_id = target_user_id;

    SELECT COUNT(*) INTO custom_exercise_count 
    FROM public.custom_exercises 
    WHERE user_id = target_user_id;

    SELECT COUNT(*) INTO private_notes_count 
    FROM public.session_notes 
    WHERE (coach_id = target_user_id OR client_id = target_user_id)
        AND visibility = 'private';

    SELECT COUNT(*) INTO shared_notes_count 
    FROM public.session_notes 
    WHERE (coach_id = target_user_id OR client_id = target_user_id)
        AND visibility = 'shared';

    DELETE FROM public.session_notes 
    WHERE (coach_id = target_user_id OR client_id = target_user_id)
        AND visibility = 'private';

    DELETE FROM public.workout_plans 
    WHERE trainee_id = target_user_id;

    UPDATE public.session_notes 
    SET coach_id = NULL 
    WHERE coach_id = target_user_id AND visibility = 'shared';
    
    UPDATE public.session_notes 
    SET client_id = NULL 
    WHERE client_id = target_user_id AND visibility = 'shared';
    
    DELETE FROM public.users WHERE id = target_user_id;
    
    BEGIN
        DELETE FROM auth.users WHERE id = target_user_id;
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'No permission to delete auth.users';
        WHEN OTHERS THEN
            RAISE NOTICE 'Failed to delete auth.users: %', SQLERRM;
    END;

    RETURN jsonb_build_object(
        'success', true,
        'user_id', target_user_id,
        'deleted', jsonb_build_object(
            'coaching_relationships', coaching_count,
            'appointments', appointment_count,
            'workout_plans_trainee', workout_self_count,
            'workout_templates', template_count,
            'private_notes', private_notes_count,
            'body_data', 'CASCADE',
            'daily_workout_summary', 'CASCADE',
            'personal_records', 'CASCADE'
        ),
        'preserved', jsonb_build_object(
            'custom_exercises', custom_exercise_count,
            'workout_plans_as_coach', workout_preserved_count,
            'shared_notes', shared_notes_count
        ),
        'auth_users_deleted', CASE 
            WHEN EXISTS (SELECT 1 FROM auth.users WHERE id = target_user_id) 
            THEN false 
            ELSE true 
        END
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

GRANT EXECUTE ON FUNCTION delete_user_account(UUID) TO authenticated;

COMMIT;

-- ============================================================================
-- 驗證
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 09 完成：v2.2-v2.3 修復與功能增強';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '修復內容：';
  RAISE NOTICE '  ✅ get_available_slots() 函數修復';
  RAISE NOTICE '  ✅ 觸發器支援布林值（字串和原生布林）';
  RAISE NOTICE '  ✅ Personal Records 自動填入 body_part';
  RAISE NOTICE '  ✅ 觸發器支援 DELETE 操作';
  RAISE NOTICE '';
  RAISE NOTICE '功能增強：';
  RAISE NOTICE '  ✅ workout_templates.training_time 已移除';
  RAISE NOTICE '  ✅ users.gender_visible 已新增';
  RAISE NOTICE '  ✅ custom_exercises RLS 策略已修復';
  RAISE NOTICE '  ✅ delete_user_account() 函數已修復';
  RAISE NOTICE '';
END $$;
