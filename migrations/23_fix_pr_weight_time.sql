-- ============================================================================
-- StrengthWise Migration: 23_fix_pr_weight_time.sql
-- ============================================================================
-- 版本: v3.3.1
-- 日期: 2026-01-12
-- ============================================================================
-- 
-- 問題：PR 觸發器會錯誤地統計 weight_time 模式的記錄
-- - weight_time 模式有 weight（如農夫走路 40kg）但沒有 reps
-- - 觸發器原本只檢查 weight > 0，導致這類記錄被納入 PR
-- - 會產生 max_reps = 0, max_volume = 0 的錯誤 PR 數據
-- 
-- 修復：只統計同時有 weight > 0 AND reps > 0 的記錄（weight_reps 模式）
-- ============================================================================

-- ============================================================================
-- PART 1: 更新 update_personal_records() 觸發器函數
-- ============================================================================

CREATE OR REPLACE FUNCTION update_personal_records()
RETURNS TRIGGER AS $$
DECLARE
  exercise_item JSONB;
  exercise_id_val TEXT;
  exercise_name_val TEXT;
  body_part_val TEXT;
  -- 從所有歷史 workouts 計算的真正最大值
  true_max_weight DECIMAL;
  true_max_reps INT;
  true_max_volume DECIMAL;
  true_achieved_date DATE;
  true_workout_plan_id TEXT;
  has_any_completed_set BOOLEAN;
BEGIN
  -- 遍歷當前 workout 的所有動作
  FOR exercise_item IN SELECT * FROM jsonb_array_elements(NEW.exercises)
  LOOP
    exercise_id_val := exercise_item->>'exerciseId';
    exercise_name_val := exercise_item->>'exerciseName';
    
    -- ⭐ 獲取 body_part
    -- 優先順序：
    -- 1. 用 exercise_id 查 exercises 表
    -- 2. 用 exercise_id 查 custom_exercises 表
    -- 3. 用 exercise_name 查 exercises 表（備選：處理 ID 格式不一致的情況）
    -- 4. 用 exercise_name 查 custom_exercises 表
    -- 5. 預設值「其他」
    SELECT COALESCE(
      (SELECT e.body_part FROM exercises e WHERE e.id = exercise_id_val),
      (SELECT ce.body_part FROM custom_exercises ce WHERE ce.id = exercise_id_val),
      (SELECT e.body_part FROM exercises e WHERE e.name = exercise_name_val LIMIT 1),
      (SELECT ce.body_part FROM custom_exercises ce WHERE ce.name = exercise_name_val LIMIT 1),
      '其他'
    ) INTO body_part_val;
    
    -- ⭐ 重新掃描該用戶該動作的所有歷史完成 sets，計算真正的 PR
    -- v3.3.1 修復：只統計同時有 weight > 0 AND reps > 0 的記錄（排除 weight_time 模式）
    SELECT 
      MAX(set_weight) AS max_weight,
      MAX(set_reps) AS max_reps,
      MAX(set_weight * set_reps) AS max_volume,
      (
        SELECT wp_date FROM (
          SELECT 
            COALESCE(wp2.completed_date::DATE, wp2.updated_at::DATE) AS wp_date,
            (s2->>'weight')::DECIMAL AS w
          FROM workout_plans wp2,
          LATERAL jsonb_array_elements(wp2.exercises) AS ex2,
          LATERAL jsonb_array_elements(ex2->'sets') AS s2
          WHERE wp2.trainee_id = NEW.trainee_id
            AND ex2->>'exerciseId' = exercise_id_val
            AND (s2->>'completed')::BOOLEAN = TRUE
            AND COALESCE((s2->>'weight')::DECIMAL, 0) > 0
            AND COALESCE((s2->>'reps')::INT, 0) > 0  -- ⭐ v3.3.1 新增：排除 weight_time
          ORDER BY w DESC
          LIMIT 1
        ) sub
      ) AS achieved_date,
      (
        SELECT wp2.id FROM workout_plans wp2,
        LATERAL jsonb_array_elements(wp2.exercises) AS ex2,
        LATERAL jsonb_array_elements(ex2->'sets') AS s2
        WHERE wp2.trainee_id = NEW.trainee_id
          AND ex2->>'exerciseId' = exercise_id_val
          AND (s2->>'completed')::BOOLEAN = TRUE
          AND COALESCE((s2->>'weight')::DECIMAL, 0) > 0
          AND COALESCE((s2->>'reps')::INT, 0) > 0  -- ⭐ v3.3.1 新增：排除 weight_time
        ORDER BY (s2->>'weight')::DECIMAL DESC
        LIMIT 1
      ) AS workout_plan_id,
      COUNT(*) > 0 AS has_completed
    INTO 
      true_max_weight, 
      true_max_reps, 
      true_max_volume,
      true_achieved_date,
      true_workout_plan_id,
      has_any_completed_set
    FROM (
      SELECT 
        COALESCE((s->>'weight')::DECIMAL, 0) AS set_weight,
        COALESCE((s->>'reps')::INT, 0) AS set_reps
      FROM workout_plans wp,
      LATERAL jsonb_array_elements(wp.exercises) AS ex,
      LATERAL jsonb_array_elements(ex->'sets') AS s
      WHERE wp.trainee_id = NEW.trainee_id
        AND ex->>'exerciseId' = exercise_id_val
        AND (s->>'completed')::BOOLEAN = TRUE
        AND COALESCE((s->>'weight')::DECIMAL, 0) > 0  -- ⭐ v3.3.1 確保有重量
        AND COALESCE((s->>'reps')::INT, 0) > 0        -- ⭐ v3.3.1 確保有次數
    ) AS completed_sets;
    
    -- 設定預設值
    true_max_weight := COALESCE(true_max_weight, 0);
    true_max_reps := COALESCE(true_max_reps, 0);
    true_max_volume := COALESCE(true_max_volume, 0);
    true_achieved_date := COALESCE(true_achieved_date, CURRENT_DATE);
    
    -- ⭐ 根據是否有完成的 set 決定操作
    IF has_any_completed_set AND (true_max_weight > 0 AND true_max_reps > 0) THEN
      -- 有完成的 set（同時有重量和次數）：更新或插入 PR
      INSERT INTO personal_records (
        user_id,
        exercise_id,
        exercise_name,
        max_weight,
        max_reps,
        max_volume,
        achieved_date,
        workout_plan_id,
        body_part,
        updated_at
      ) VALUES (
        NEW.trainee_id,
        exercise_id_val,
        exercise_name_val,
        true_max_weight,
        true_max_reps,
        true_max_volume,
        true_achieved_date,
        true_workout_plan_id,
        body_part_val,
        NOW()
      )
      ON CONFLICT (user_id, exercise_id)
      DO UPDATE SET
        -- ⭐ 直接設定為真正的最大值（不用 GREATEST，允許回滾）
        max_weight = true_max_weight,
        max_reps = true_max_reps,
        max_volume = true_max_volume,
        achieved_date = true_achieved_date,
        workout_plan_id = true_workout_plan_id,
        body_part = COALESCE(body_part_val, personal_records.body_part),
        updated_at = NOW();
    ELSE
      -- ⭐ 如果該動作已經沒有任何完成的 weight_reps set，刪除 PR 記錄
      DELETE FROM personal_records 
      WHERE user_id = NEW.trainee_id 
        AND exercise_id = exercise_id_val;
    END IF;
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PART 2: 更新 handle_workout_plan_delete() 函數
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
  -- 遍歷被刪除 workout 的所有動作
  FOR exercise_item IN SELECT * FROM jsonb_array_elements(OLD.exercises)
  LOOP
    exercise_id_val := exercise_item->>'exerciseId';
    exercise_name_val := exercise_item->>'exerciseName';
    
    -- 獲取 body_part
    SELECT COALESCE(
      (SELECT e.body_part FROM exercises e WHERE e.id = exercise_id_val),
      (SELECT ce.body_part FROM custom_exercises ce WHERE ce.id = exercise_id_val),
      (SELECT e.body_part FROM exercises e WHERE e.name = exercise_name_val LIMIT 1),
      (SELECT ce.body_part FROM custom_exercises ce WHERE ce.name = exercise_name_val LIMIT 1),
      '其他'
    ) INTO body_part_val;
    
    -- 重新掃描剩餘的歷史記錄，計算新的 PR
    -- v3.3.1 修復：只統計同時有 weight > 0 AND reps > 0 的記錄
    SELECT 
      MAX(set_weight) AS max_weight,
      MAX(set_reps) AS max_reps,
      MAX(set_weight * set_reps) AS max_volume,
      (
        SELECT wp_date FROM (
          SELECT 
            COALESCE(wp2.completed_date::DATE, wp2.updated_at::DATE) AS wp_date,
            (s2->>'weight')::DECIMAL AS w
          FROM workout_plans wp2,
          LATERAL jsonb_array_elements(wp2.exercises) AS ex2,
          LATERAL jsonb_array_elements(ex2->'sets') AS s2
          WHERE wp2.trainee_id = OLD.trainee_id
            AND wp2.id != OLD.id  -- 排除被刪除的記錄
            AND ex2->>'exerciseId' = exercise_id_val
            AND (s2->>'completed')::BOOLEAN = TRUE
            AND COALESCE((s2->>'weight')::DECIMAL, 0) > 0
            AND COALESCE((s2->>'reps')::INT, 0) > 0  -- ⭐ v3.3.1
          ORDER BY w DESC
          LIMIT 1
        ) sub
      ) AS achieved_date,
      (
        SELECT wp2.id FROM workout_plans wp2,
        LATERAL jsonb_array_elements(wp2.exercises) AS ex2,
        LATERAL jsonb_array_elements(ex2->'sets') AS s2
        WHERE wp2.trainee_id = OLD.trainee_id
          AND wp2.id != OLD.id
          AND ex2->>'exerciseId' = exercise_id_val
          AND (s2->>'completed')::BOOLEAN = TRUE
          AND COALESCE((s2->>'weight')::DECIMAL, 0) > 0
          AND COALESCE((s2->>'reps')::INT, 0) > 0  -- ⭐ v3.3.1
        ORDER BY (s2->>'weight')::DECIMAL DESC
        LIMIT 1
      ) AS workout_plan_id,
      COUNT(*) > 0 AS has_completed
    INTO 
      true_max_weight, 
      true_max_reps, 
      true_max_volume,
      true_achieved_date,
      true_workout_plan_id,
      has_any_completed_set
    FROM (
      SELECT 
        COALESCE((s->>'weight')::DECIMAL, 0) AS set_weight,
        COALESCE((s->>'reps')::INT, 0) AS set_reps
      FROM workout_plans wp,
      LATERAL jsonb_array_elements(wp.exercises) AS ex,
      LATERAL jsonb_array_elements(ex->'sets') AS s
      WHERE wp.trainee_id = OLD.trainee_id
        AND wp.id != OLD.id  -- 排除被刪除的記錄
        AND ex->>'exerciseId' = exercise_id_val
        AND (s->>'completed')::BOOLEAN = TRUE
        AND COALESCE((s->>'weight')::DECIMAL, 0) > 0  -- ⭐ v3.3.1
        AND COALESCE((s->>'reps')::INT, 0) > 0        -- ⭐ v3.3.1
    ) AS completed_sets;
    
    -- 設定預設值
    true_max_weight := COALESCE(true_max_weight, 0);
    true_max_reps := COALESCE(true_max_reps, 0);
    true_max_volume := COALESCE(true_max_volume, 0);
    true_achieved_date := COALESCE(true_achieved_date, CURRENT_DATE);
    
    -- 根據是否還有剩餘的完成 set 決定操作
    IF has_any_completed_set AND (true_max_weight > 0 AND true_max_reps > 0) THEN
      -- 還有其他 weight_reps 記錄：更新 PR
      INSERT INTO personal_records (
        user_id,
        exercise_id,
        exercise_name,
        max_weight,
        max_reps,
        max_volume,
        achieved_date,
        workout_plan_id,
        body_part,
        updated_at
      ) VALUES (
        OLD.trainee_id,
        exercise_id_val,
        exercise_name_val,
        true_max_weight,
        true_max_reps,
        true_max_volume,
        true_achieved_date,
        true_workout_plan_id,
        body_part_val,
        NOW()
      )
      ON CONFLICT (user_id, exercise_id)
      DO UPDATE SET
        max_weight = true_max_weight,
        max_reps = true_max_reps,
        max_volume = true_max_volume,
        achieved_date = true_achieved_date,
        workout_plan_id = true_workout_plan_id,
        body_part = COALESCE(body_part_val, personal_records.body_part),
        updated_at = NOW();
    ELSE
      -- 該動作已經沒有任何 weight_reps 記錄：刪除 PR
      DELETE FROM personal_records 
      WHERE user_id = OLD.trainee_id 
        AND exercise_id = exercise_id_val;
    END IF;
  END LOOP;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PART 3: 清理可能已經被錯誤統計的 weight_time PR 記錄
-- ============================================================================
-- 
-- 刪除 max_reps = 0 且 max_volume = 0 的異常 PR 記錄
-- 這些很可能是 weight_time 模式產生的錯誤數據

DELETE FROM personal_records
WHERE max_reps = 0 AND max_volume = 0;

-- ============================================================================
-- 驗證
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '✅ Migration 23_fix_pr_weight_time.sql 執行完成';
  RAISE NOTICE '  - update_personal_records() 已更新：只統計 weight > 0 AND reps > 0';
  RAISE NOTICE '  - handle_workout_plan_delete() 已更新：相同邏輯';
  RAISE NOTICE '  - 已清理 max_reps = 0 的異常 PR 記錄';
END $$;
