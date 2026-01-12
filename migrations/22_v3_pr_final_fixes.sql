-- ============================================================================
-- StrengthWise Migration: 22_v3_pr_final_fixes.sql
-- ============================================================================
-- 合併自: 046_fix_pr_delete_trigger.sql, 047_fix_exercise_id_format.sql
-- 版本: v3.3
-- 日期: 2026-01-12
-- ============================================================================
-- 
-- 包含:
-- 1. PR DELETE 觸發器（刪除 workout 時重新計算 PR）
-- 2. exerciseId 格式修復（UUID → Firestore ID）
-- 3. personal_records body_part 修復
-- ============================================================================

-- ============================================================================
-- PART 1: handle_workout_plan_delete() 函數
-- ============================================================================

CREATE OR REPLACE FUNCTION handle_workout_plan_delete()
RETURNS TRIGGER AS $$
DECLARE
  exercise_item JSONB;
  exercise_id_val TEXT;
  exercise_name_val TEXT;
  body_part_val TEXT;
  true_max_weight DECIMAL;
  true_max_reps INT;
  true_max_volume DECIMAL;
  true_achieved_date DATE;
  true_workout_plan_id TEXT;
  has_any_completed_set BOOLEAN;
BEGIN
  IF OLD.exercises IS NULL OR jsonb_array_length(OLD.exercises) = 0 THEN
    RETURN OLD;
  END IF;
  
  FOR exercise_item IN SELECT * FROM jsonb_array_elements(OLD.exercises)
  LOOP
    exercise_id_val := exercise_item->>'exerciseId';
    exercise_name_val := exercise_item->>'exerciseName';
    
    IF exercise_id_val IS NULL THEN CONTINUE; END IF;
    
    -- 獲取 body_part
    SELECT COALESCE(
      (SELECT e.body_part FROM exercises e WHERE e.id = exercise_id_val),
      (SELECT ce.body_part FROM custom_exercises ce WHERE ce.id = exercise_id_val),
      (SELECT e.body_part FROM exercises e WHERE e.name = exercise_name_val LIMIT 1),
      (SELECT ce.body_part FROM custom_exercises ce WHERE ce.name = exercise_name_val LIMIT 1),
      '其他'
    ) INTO body_part_val;
    
    -- 重新掃描剩餘歷史完成 sets
    SELECT 
      MAX(set_weight), MAX(set_reps), MAX(set_weight * set_reps),
      (
        SELECT wp_date FROM (
          SELECT COALESCE(wp2.completed_date::DATE, wp2.updated_at::DATE) AS wp_date,
            (s2->>'weight')::DECIMAL AS w
          FROM workout_plans wp2,
          LATERAL jsonb_array_elements(wp2.exercises) AS ex2,
          LATERAL jsonb_array_elements(ex2->'sets') AS s2
          WHERE wp2.trainee_id = OLD.trainee_id
            AND ex2->>'exerciseId' = exercise_id_val
            AND (s2->>'completed')::BOOLEAN = TRUE
            AND COALESCE((s2->>'weight')::DECIMAL, 0) > 0
          ORDER BY w DESC LIMIT 1
        ) sub
      ),
      (
        SELECT wp2.id FROM workout_plans wp2,
        LATERAL jsonb_array_elements(wp2.exercises) AS ex2,
        LATERAL jsonb_array_elements(ex2->'sets') AS s2
        WHERE wp2.trainee_id = OLD.trainee_id
          AND ex2->>'exerciseId' = exercise_id_val
          AND (s2->>'completed')::BOOLEAN = TRUE
          AND COALESCE((s2->>'weight')::DECIMAL, 0) > 0
        ORDER BY (s2->>'weight')::DECIMAL DESC LIMIT 1
      ),
      COUNT(*) > 0
    INTO true_max_weight, true_max_reps, true_max_volume, true_achieved_date, true_workout_plan_id, has_any_completed_set
    FROM (
      SELECT COALESCE((s->>'weight')::DECIMAL, 0) AS set_weight, COALESCE((s->>'reps')::INT, 0) AS set_reps
      FROM workout_plans wp,
      LATERAL jsonb_array_elements(wp.exercises) AS ex,
      LATERAL jsonb_array_elements(ex->'sets') AS s
      WHERE wp.trainee_id = OLD.trainee_id
        AND ex->>'exerciseId' = exercise_id_val
        AND (s->>'completed')::BOOLEAN = TRUE
    ) AS completed_sets;
    
    true_max_weight := COALESCE(true_max_weight, 0);
    true_max_reps := COALESCE(true_max_reps, 0);
    true_max_volume := COALESCE(true_max_volume, 0);
    
    IF has_any_completed_set AND (true_max_weight > 0 OR true_max_reps > 0) THEN
      UPDATE personal_records SET
        max_weight = true_max_weight,
        max_reps = true_max_reps,
        max_volume = true_max_volume,
        achieved_date = COALESCE(true_achieved_date, achieved_date),
        workout_plan_id = true_workout_plan_id,
        body_part = COALESCE(body_part_val, body_part),
        updated_at = NOW()
      WHERE user_id = OLD.trainee_id AND exercise_id = exercise_id_val;
    ELSE
      DELETE FROM personal_records 
      WHERE user_id = OLD.trainee_id AND exercise_id = exercise_id_val;
    END IF;
  END LOOP;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PART 2: DELETE 觸發器
-- ============================================================================

DROP TRIGGER IF EXISTS trigger_update_pr_on_delete ON workout_plans;
CREATE TRIGGER trigger_update_pr_on_delete
  AFTER DELETE ON workout_plans
  FOR EACH ROW
  EXECUTE FUNCTION handle_workout_plan_delete();

-- ============================================================================
-- PART 3: 修復 UUID 格式的 exerciseId
-- ============================================================================

DO $$
DECLARE
  wp_record RECORD;
  ex_item JSONB;
  ex_idx INT;
  ex_id TEXT;
  ex_name TEXT;
  correct_id TEXT;
  updated_exercises JSONB;
  needs_update BOOLEAN;
  fixed_count INT := 0;
  total_fixed INT := 0;
BEGIN
  RAISE NOTICE '🔧 修復 UUID 格式的 exerciseId...';
  
  FOR wp_record IN
    SELECT id, trainee_id, exercises FROM workout_plans
    WHERE exercises IS NOT NULL AND jsonb_array_length(exercises) > 0
  LOOP
    updated_exercises := wp_record.exercises;
    needs_update := FALSE;
    ex_idx := 0;
    
    FOR ex_item IN SELECT * FROM jsonb_array_elements(wp_record.exercises)
    LOOP
      ex_id := ex_item->>'exerciseId';
      ex_name := ex_item->>'exerciseName';
      
      -- UUID 格式檢測
      IF ex_id IS NOT NULL AND ex_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
        SELECT e.id INTO correct_id FROM exercises e WHERE e.name = ex_name LIMIT 1;
        
        IF correct_id IS NULL THEN
          SELECT ce.id INTO correct_id FROM custom_exercises ce WHERE ce.name = ex_name LIMIT 1;
        END IF;
        
        IF correct_id IS NOT NULL AND correct_id != ex_id THEN
          updated_exercises := jsonb_set(
            updated_exercises,
            ARRAY[ex_idx::TEXT, 'exerciseId'],
            to_jsonb(correct_id)
          );
          needs_update := TRUE;
          fixed_count := fixed_count + 1;
        END IF;
      END IF;
      
      ex_idx := ex_idx + 1;
    END LOOP;
    
    IF needs_update THEN
      UPDATE workout_plans
      SET exercises = updated_exercises, updated_at = updated_at
      WHERE id = wp_record.id;
      total_fixed := total_fixed + 1;
    END IF;
  END LOOP;
  
  RAISE NOTICE '✅ 修正了 % 個 exerciseId（% 筆 workout）', fixed_count, total_fixed;
END $$;

-- ============================================================================
-- PART 4: 修復 personal_records body_part
-- ============================================================================

UPDATE personal_records pr
SET body_part = COALESCE(
  (SELECT e.body_part FROM exercises e WHERE e.name = pr.exercise_name LIMIT 1),
  (SELECT ce.body_part FROM custom_exercises ce WHERE ce.name = pr.exercise_name LIMIT 1),
  pr.body_part
)
WHERE pr.body_part = '其他';

-- ============================================================================
-- PART 5: 重新計算所有 PR
-- ============================================================================

DO $$
DECLARE
  processed_count INT := 0;
  user_record RECORD;
  exercise_record RECORD;
  best_weight DECIMAL;
  best_reps INT;
  best_volume DECIMAL;
  best_date DATE;
  best_wp_id TEXT;
  body_part_val TEXT;
BEGIN
  RAISE NOTICE '🔄 重新計算所有 PR...';
  
  TRUNCATE TABLE personal_records;
  
  FOR user_record IN 
    SELECT DISTINCT trainee_id FROM workout_plans
    WHERE exercises IS NOT NULL AND jsonb_array_length(exercises) > 0
  LOOP
    FOR exercise_record IN
      SELECT DISTINCT ex->>'exerciseId' AS exercise_id, ex->>'exerciseName' AS exercise_name
      FROM workout_plans wp,
      LATERAL jsonb_array_elements(wp.exercises) AS ex
      WHERE wp.trainee_id = user_record.trainee_id AND ex->>'exerciseId' IS NOT NULL
    LOOP
      SELECT MAX((s->>'weight')::DECIMAL), MAX((s->>'reps')::INT), MAX((s->>'weight')::DECIMAL * (s->>'reps')::INT)
      INTO best_weight, best_reps, best_volume
      FROM workout_plans wp,
      LATERAL jsonb_array_elements(wp.exercises) AS ex,
      LATERAL jsonb_array_elements(ex->'sets') AS s
      WHERE wp.trainee_id = user_record.trainee_id
        AND ex->>'exerciseId' = exercise_record.exercise_id
        AND (s->>'completed')::BOOLEAN = TRUE;
      
      IF best_weight IS NULL OR best_weight = 0 THEN CONTINUE; END IF;
      
      SELECT COALESCE(wp.completed_date::DATE, wp.updated_at::DATE), wp.id::TEXT
      INTO best_date, best_wp_id
      FROM workout_plans wp,
      LATERAL jsonb_array_elements(wp.exercises) AS ex,
      LATERAL jsonb_array_elements(ex->'sets') AS s
      WHERE wp.trainee_id = user_record.trainee_id
        AND ex->>'exerciseId' = exercise_record.exercise_id
        AND (s->>'completed')::BOOLEAN = TRUE
        AND (s->>'weight')::DECIMAL = best_weight
      ORDER BY COALESCE(wp.completed_date, wp.updated_at) DESC LIMIT 1;
      
      SELECT COALESCE(
        (SELECT e.body_part FROM exercises e WHERE e.id = exercise_record.exercise_id),
        (SELECT ce.body_part FROM custom_exercises ce WHERE ce.id = exercise_record.exercise_id),
        (SELECT e.body_part FROM exercises e WHERE e.name = exercise_record.exercise_name LIMIT 1),
        '其他'
      ) INTO body_part_val;
      
      INSERT INTO personal_records (
        user_id, exercise_id, exercise_name, max_weight, max_reps, max_volume,
        achieved_date, workout_plan_id, body_part, created_at, updated_at
      ) VALUES (
        user_record.trainee_id, exercise_record.exercise_id, exercise_record.exercise_name,
        best_weight, best_reps, best_volume,
        COALESCE(best_date, CURRENT_DATE), best_wp_id, body_part_val, NOW(), NOW()
      )
      ON CONFLICT (user_id, exercise_id) DO NOTHING;
    END LOOP;
    
    processed_count := processed_count + 1;
  END LOOP;
  
  RAISE NOTICE '✅ 處理了 % 個用戶', processed_count;
END $$;

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ 
DECLARE
  pr_count INT;
BEGIN
  SELECT COUNT(*) INTO pr_count FROM personal_records;
  
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 22 完成：PR 最終修復';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '修復內容：';
  RAISE NOTICE '  ✅ DELETE 觸發器（刪除 workout 時重新計算 PR）';
  RAISE NOTICE '  ✅ UUID → Firestore ID 格式修復';
  RAISE NOTICE '  ✅ body_part 修復（透過 exerciseName 查詢）';
  RAISE NOTICE '  ✅ 重新計算所有 PR（% 筆）', pr_count;
  RAISE NOTICE '';
END $$;
