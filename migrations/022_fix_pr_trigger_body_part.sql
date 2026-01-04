-- ============================================================================
-- StrengthWise Migration: 022_fix_pr_trigger_body_part.sql
-- ============================================================================
-- 建立時間：2026-01-04
-- 目標：修復 update_personal_records() 觸發器，自動獲取 body_part
-- ============================================================================

-- ============================================================================
-- 問題說明
-- ============================================================================
-- 原本的 update_personal_records() 觸發器在插入 PR 時沒有設置 body_part 欄位
-- 導致某些 PR 的 body_part 為 NULL 或錯誤值（如「其他」）
-- 
-- 修復內容：
-- 1. 自動從 exercises 或 custom_exercises 表獲取 body_part
-- 2. 確保系統動作和自訂動作都能正確獲取 body_part
-- ============================================================================

-- ============================================================================
-- 更新觸發器函數
-- ============================================================================
-- ⭐ 重要邏輯變更（2026-01-04）：
--   - 取消勾選 set 時會正確回滾 PR
--   - 重新掃描該用戶該動作的所有歷史完成 sets
--   - 找出真正的最大值（不是只增不減）
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
    -- 這樣取消勾選時會正確回滾
    SELECT 
      MAX(set_weight) AS max_weight,
      MAX(set_reps) AS max_reps,
      MAX(set_weight * set_reps) AS max_volume,
      (
        -- 找出最大重量達成的日期和 workout_plan_id
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
    ) AS completed_sets;
    
    -- 設定預設值
    true_max_weight := COALESCE(true_max_weight, 0);
    true_max_reps := COALESCE(true_max_reps, 0);
    true_max_volume := COALESCE(true_max_volume, 0);
    true_achieved_date := COALESCE(true_achieved_date, CURRENT_DATE);
    
    -- ⭐ 根據是否有完成的 set 決定操作
    IF has_any_completed_set AND (true_max_weight > 0 OR true_max_reps > 0) THEN
      -- 有完成的 set：更新或插入 PR
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
      -- ⭐ 如果該動作已經沒有任何完成的 set，刪除 PR 記錄
      DELETE FROM personal_records 
      WHERE user_id = NEW.trainee_id 
        AND exercise_id = exercise_id_val;
    END IF;
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 重新建立觸發器（確保使用新函數）
DROP TRIGGER IF EXISTS trigger_update_pr ON workout_plans;
CREATE TRIGGER trigger_update_pr
  AFTER INSERT OR UPDATE OF completed, exercises
  ON workout_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_personal_records();

-- ============================================================================
-- ⭐ 重新初始化所有 PR（使用新邏輯重新計算）
-- ============================================================================
-- 因為觸發器邏輯變更，需要重新計算所有 PR 以確保數據正確
-- 這會觸發 trigger_update_pr 對所有 workout_plans 重新計算

DO $$
DECLARE
  processed_count INT := 0;
  wp_record RECORD;
BEGIN
  RAISE NOTICE '⏳ 開始重新初始化 PR 記錄...';
  
  -- 1. 清空現有 PR
  TRUNCATE TABLE personal_records;
  RAISE NOTICE '  ✓ 已清空 personal_records 表';
  
  -- 2. ⭐ 直接計算 PR（不更新 updated_at，避免影響統計）
  -- 遍歷所有有動作的訓練計劃，手動呼叫觸發器邏輯
  FOR wp_record IN 
    SELECT id, trainee_id, exercises, completed_date, updated_at
    FROM workout_plans
    WHERE exercises IS NOT NULL 
      AND jsonb_array_length(exercises) > 0
  LOOP
    -- 模擬觸發器邏輯：對每個動作計算 PR
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
      FOR exercise_item IN SELECT * FROM jsonb_array_elements(wp_record.exercises)
      LOOP
        exercise_id_val := exercise_item->>'exerciseId';
        exercise_name_val := exercise_item->>'exerciseName';
        
        -- 獲取 body_part（用 ID 或名稱查詢）
        SELECT COALESCE(
          (SELECT e.body_part FROM exercises e WHERE e.id = exercise_id_val),
          (SELECT ce.body_part FROM custom_exercises ce WHERE ce.id = exercise_id_val),
          (SELECT e.body_part FROM exercises e WHERE e.name = exercise_name_val LIMIT 1),
          (SELECT ce.body_part FROM custom_exercises ce WHERE ce.name = exercise_name_val LIMIT 1),
          '其他'
        ) INTO body_part_val;
        
        -- 計算真正的 PR（掃描所有歷史完成 sets）
        SELECT 
          MAX(set_weight),
          MAX(set_reps),
          MAX(set_weight * set_reps),
          COUNT(*) > 0
        INTO true_max_weight, true_max_reps, true_max_volume, has_any_completed_set
        FROM (
          SELECT 
            COALESCE((s->>'weight')::DECIMAL, 0) AS set_weight,
            COALESCE((s->>'reps')::INT, 0) AS set_reps
          FROM workout_plans wp,
          LATERAL jsonb_array_elements(wp.exercises) AS ex,
          LATERAL jsonb_array_elements(ex->'sets') AS s
          WHERE wp.trainee_id = wp_record.trainee_id
            AND ex->>'exerciseId' = exercise_id_val
            AND (s->>'completed')::BOOLEAN = TRUE
        ) AS completed_sets;
        
        true_max_weight := COALESCE(true_max_weight, 0);
        true_max_reps := COALESCE(true_max_reps, 0);
        true_max_volume := COALESCE(true_max_volume, 0);
        
        -- 獲取達成日期
        SELECT COALESCE(wp2.completed_date::DATE, wp2.updated_at::DATE)
        INTO true_achieved_date
        FROM workout_plans wp2,
        LATERAL jsonb_array_elements(wp2.exercises) AS ex2,
        LATERAL jsonb_array_elements(ex2->'sets') AS s2
        WHERE wp2.trainee_id = wp_record.trainee_id
          AND ex2->>'exerciseId' = exercise_id_val
          AND (s2->>'completed')::BOOLEAN = TRUE
          AND COALESCE((s2->>'weight')::DECIMAL, 0) = true_max_weight
        LIMIT 1;
        
        true_achieved_date := COALESCE(true_achieved_date, CURRENT_DATE);
        
        -- 插入或更新 PR
        IF has_any_completed_set AND (true_max_weight > 0 OR true_max_reps > 0) THEN
          INSERT INTO personal_records (
            user_id, exercise_id, exercise_name, max_weight, max_reps, max_volume,
            achieved_date, workout_plan_id, body_part, updated_at
          ) VALUES (
            wp_record.trainee_id, exercise_id_val, exercise_name_val,
            true_max_weight, true_max_reps, true_max_volume,
            true_achieved_date, wp_record.id, body_part_val, NOW()
          )
          ON CONFLICT (user_id, exercise_id)
          DO UPDATE SET
            max_weight = GREATEST(personal_records.max_weight, true_max_weight),
            max_reps = GREATEST(personal_records.max_reps, true_max_reps),
            max_volume = GREATEST(personal_records.max_volume, true_max_volume),
            achieved_date = CASE 
              WHEN true_max_weight > personal_records.max_weight THEN true_achieved_date
              ELSE personal_records.achieved_date
            END,
            body_part = COALESCE(body_part_val, personal_records.body_part),
            updated_at = NOW();
        END IF;
      END LOOP;
    END;
    
    processed_count := processed_count + 1;
  END LOOP;
  
  RAISE NOTICE '  ✓ 已處理 % 筆訓練計劃', processed_count;
  
  -- 3. 統計結果
  SELECT COUNT(*) INTO processed_count FROM personal_records;
  RAISE NOTICE '  ✓ 新生成 % 筆 PR 記錄', processed_count;
END $$;

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 022 完成：PR 觸發器修復';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '修復內容：';
  RAISE NOTICE '  ✅ update_personal_records() 現在自動獲取 body_part';
  RAISE NOTICE '  ✅ 優先從 exercises 表獲取，其次從 custom_exercises 表';
  RAISE NOTICE '  ✅ 現有錯誤資料已自動修復';
  RAISE NOTICE '';
  RAISE NOTICE '⭐ 核心邏輯變更：';
  RAISE NOTICE '  - 只統計 set.completed = true 的組';
  RAISE NOTICE '  - 部分完成的訓練也會更新 PR';
  RAISE NOTICE '  - ⭐ 取消勾選 set 時會正確回滾 PR！';
  RAISE NOTICE '  - ⭐ 重新掃描所有歷史完成 sets，計算真正最大值';
  RAISE NOTICE '  - ⭐ 如果某動作所有 sets 都取消，則刪除該動作的 PR';
  RAISE NOTICE '';
END $$;

