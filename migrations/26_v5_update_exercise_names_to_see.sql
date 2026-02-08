-- ============================================================================
-- StrengthWise Migration: 26_v5_update_exercise_names_to_see.sql
-- ============================================================================
-- 版本: v5.1
-- 日期: 2026-02-08
-- 目的: 將所有已儲存的動作名稱更新為 SEE 標準名稱（canonical_name）
-- ============================================================================
--
-- 背景：v5.0 引入 canonical_name（SEE 標準中文名），但過去儲存的訓練記錄、
-- 模板、個人記錄仍使用舊的 name。此 migration 一次性更新所有歷史資料，
-- 並修改 trigger 確保未來 PR 也使用 SEE 名稱。
--
-- 影響表格：
-- 1. workout_plans.exercises JSONB → exerciseName + name 欄位
-- 2. workout_templates.exercises JSONB → name 欄位
-- 3. personal_records.exercise_name 欄位
-- 4. update_personal_records() trigger → exercise_name_val 優先用 canonical_name
-- 5. handle_workout_plan_delete() trigger → 同上
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. 更新 workout_plans.exercises JSONB 中的動作名稱
-- ============================================================================
-- exercises JSONB 格式: [{"exerciseId": "xxx", "exerciseName": "舊名", "name": "舊名", ...}]
-- 需要同時更新 exerciseName 和 name 兩個欄位

DO $$
DECLARE
  plan_row RECORD;
  updated_exercises JSONB;
  exercise_item JSONB;
  exercise_id_val TEXT;
  canonical TEXT;
  i INTEGER;
  update_count INTEGER := 0;
BEGIN
  FOR plan_row IN
    SELECT id, exercises
    FROM workout_plans
    WHERE exercises IS NOT NULL
      AND jsonb_array_length(exercises) > 0
  LOOP
    updated_exercises := '[]'::jsonb;

    FOR i IN 0..jsonb_array_length(plan_row.exercises) - 1
    LOOP
      exercise_item := plan_row.exercises->i;
      exercise_id_val := exercise_item->>'exerciseId';

      -- 查找 canonical_name
      SELECT e.canonical_name INTO canonical
      FROM exercises e
      WHERE e.id = exercise_id_val
        AND e.canonical_name IS NOT NULL;

      IF canonical IS NOT NULL THEN
        -- 更新 exerciseName 和 name
        exercise_item := exercise_item || jsonb_build_object(
          'exerciseName', canonical,
          'name', canonical
        );
      END IF;

      updated_exercises := updated_exercises || jsonb_build_array(exercise_item);
    END LOOP;

    -- 只在有變更時更新
    IF updated_exercises != plan_row.exercises THEN
      UPDATE workout_plans SET exercises = updated_exercises WHERE id = plan_row.id;
      update_count := update_count + 1;
    END IF;
  END LOOP;

  RAISE NOTICE '✅ workout_plans: 更新 % 筆計畫的動作名稱', update_count;
END $$;

-- ============================================================================
-- 2. 更新 workout_templates.exercises JSONB 中的動作名稱
-- ============================================================================

DO $$
DECLARE
  tmpl_row RECORD;
  updated_exercises JSONB;
  exercise_item JSONB;
  exercise_id_val TEXT;
  canonical TEXT;
  i INTEGER;
  update_count INTEGER := 0;
BEGIN
  FOR tmpl_row IN
    SELECT id, exercises
    FROM workout_templates
    WHERE exercises IS NOT NULL
      AND jsonb_array_length(exercises) > 0
  LOOP
    updated_exercises := '[]'::jsonb;

    FOR i IN 0..jsonb_array_length(tmpl_row.exercises) - 1
    LOOP
      exercise_item := tmpl_row.exercises->i;
      exercise_id_val := exercise_item->>'exerciseId';

      -- 查找 canonical_name
      SELECT e.canonical_name INTO canonical
      FROM exercises e
      WHERE e.id = exercise_id_val
        AND e.canonical_name IS NOT NULL;

      IF canonical IS NOT NULL THEN
        exercise_item := exercise_item || jsonb_build_object('name', canonical);
      END IF;

      updated_exercises := updated_exercises || jsonb_build_array(exercise_item);
    END LOOP;

    IF updated_exercises != tmpl_row.exercises THEN
      UPDATE workout_templates SET exercises = updated_exercises WHERE id = tmpl_row.id;
      update_count := update_count + 1;
    END IF;
  END LOOP;

  RAISE NOTICE '✅ workout_templates: 更新 % 筆模板的動作名稱', update_count;
END $$;

-- ============================================================================
-- 3. 更新 personal_records.exercise_name
-- ============================================================================

DO $$
DECLARE
  update_count INTEGER;
BEGIN
  UPDATE personal_records pr
  SET exercise_name = e.canonical_name
  FROM exercises e
  WHERE pr.exercise_id = e.id
    AND e.canonical_name IS NOT NULL
    AND pr.exercise_name IS DISTINCT FROM e.canonical_name;

  GET DIAGNOSTICS update_count = ROW_COUNT;
  RAISE NOTICE '✅ personal_records: 更新 % 筆個人記錄的動作名稱', update_count;
END $$;

-- ============================================================================
-- 4. 更新 update_personal_records() trigger
-- ============================================================================
-- 基於 migration 23（v3.3.1）版本，唯一修改：
-- exercise_name_val 改為優先從 exercises.canonical_name 查詢

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

    -- v5.1: 優先使用 canonical_name，回退到 JSONB 中的 exerciseName
    SELECT COALESCE(e.canonical_name, exercise_item->>'exerciseName', exercise_item->>'name', '未知動作')
    INTO exercise_name_val
    FROM exercises e
    WHERE e.id = exercise_id_val;

    -- 如果 exercises 表找不到（自訂動作），從 JSONB 取
    IF exercise_name_val IS NULL THEN
      exercise_name_val := COALESCE(exercise_item->>'exerciseName', exercise_item->>'name', '未知動作');
    END IF;

    -- ⭐ 獲取 body_part
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
            AND COALESCE((s2->>'reps')::INT, 0) > 0
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
          AND COALESCE((s2->>'reps')::INT, 0) > 0
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
        AND COALESCE((s->>'weight')::DECIMAL, 0) > 0
        AND COALESCE((s->>'reps')::INT, 0) > 0
    ) AS completed_sets;

    -- 設定預設值
    true_max_weight := COALESCE(true_max_weight, 0);
    true_max_reps := COALESCE(true_max_reps, 0);
    true_max_volume := COALESCE(true_max_volume, 0);
    true_achieved_date := COALESCE(true_achieved_date, CURRENT_DATE);

    -- ⭐ 根據是否有完成的 set 決定操作
    IF has_any_completed_set AND (true_max_weight > 0 AND true_max_reps > 0) THEN
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
        exercise_name = EXCLUDED.exercise_name,
        max_weight = true_max_weight,
        max_reps = true_max_reps,
        max_volume = true_max_volume,
        achieved_date = true_achieved_date,
        workout_plan_id = true_workout_plan_id,
        body_part = COALESCE(body_part_val, personal_records.body_part),
        updated_at = NOW();
    ELSE
      DELETE FROM personal_records
      WHERE user_id = NEW.trainee_id
        AND exercise_id = exercise_id_val;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 5. 更新 handle_workout_plan_delete() trigger
-- ============================================================================
-- 同樣修改 exercise_name_val 優先使用 canonical_name

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

    -- v5.1: 優先使用 canonical_name
    SELECT COALESCE(e.canonical_name, exercise_item->>'exerciseName', exercise_item->>'name', '未知動作')
    INTO exercise_name_val
    FROM exercises e
    WHERE e.id = exercise_id_val;

    IF exercise_name_val IS NULL THEN
      exercise_name_val := COALESCE(exercise_item->>'exerciseName', exercise_item->>'name', '未知動作');
    END IF;

    -- 獲取 body_part
    SELECT COALESCE(
      (SELECT e.body_part FROM exercises e WHERE e.id = exercise_id_val),
      (SELECT ce.body_part FROM custom_exercises ce WHERE ce.id = exercise_id_val),
      (SELECT e.body_part FROM exercises e WHERE e.name = exercise_name_val LIMIT 1),
      (SELECT ce.body_part FROM custom_exercises ce WHERE ce.name = exercise_name_val LIMIT 1),
      '其他'
    ) INTO body_part_val;

    -- 重新掃描剩餘的歷史記錄，計算新的 PR
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
            AND wp2.id != OLD.id
            AND ex2->>'exerciseId' = exercise_id_val
            AND (s2->>'completed')::BOOLEAN = TRUE
            AND COALESCE((s2->>'weight')::DECIMAL, 0) > 0
            AND COALESCE((s2->>'reps')::INT, 0) > 0
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
          AND COALESCE((s2->>'reps')::INT, 0) > 0
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
        AND wp.id != OLD.id
        AND ex->>'exerciseId' = exercise_id_val
        AND (s->>'completed')::BOOLEAN = TRUE
        AND COALESCE((s->>'weight')::DECIMAL, 0) > 0
        AND COALESCE((s->>'reps')::INT, 0) > 0
    ) AS completed_sets;

    -- 設定預設值
    true_max_weight := COALESCE(true_max_weight, 0);
    true_max_reps := COALESCE(true_max_reps, 0);
    true_max_volume := COALESCE(true_max_volume, 0);
    true_achieved_date := COALESCE(true_achieved_date, CURRENT_DATE);

    IF has_any_completed_set AND (true_max_weight > 0 AND true_max_reps > 0) THEN
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
        exercise_name = EXCLUDED.exercise_name,
        max_weight = true_max_weight,
        max_reps = true_max_reps,
        max_volume = true_max_volume,
        achieved_date = true_achieved_date,
        workout_plan_id = true_workout_plan_id,
        body_part = COALESCE(body_part_val, personal_records.body_part),
        updated_at = NOW();
    ELSE
      DELETE FROM personal_records
      WHERE user_id = OLD.trainee_id
        AND exercise_id = exercise_id_val;
    END IF;
  END LOOP;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- ============================================================================
-- 驗證
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '✅ Migration 26 執行完成';
  RAISE NOTICE '  - workout_plans JSONB exerciseName/name 已更新為 SEE 名稱';
  RAISE NOTICE '  - workout_templates JSONB name 已更新為 SEE 名稱';
  RAISE NOTICE '  - personal_records.exercise_name 已更新為 SEE 名稱';
  RAISE NOTICE '  - update_personal_records() 已更新：優先使用 canonical_name';
  RAISE NOTICE '  - handle_workout_plan_delete() 已更新：優先使用 canonical_name';
END $$;

-- 手動驗證查詢：
-- SELECT exercise_name, exercise_id FROM personal_records LIMIT 10;
-- SELECT id, exercises->0->>'exerciseName' AS first_exercise FROM workout_plans LIMIT 5;
-- SELECT id, exercises->0->>'name' AS first_exercise FROM workout_templates LIMIT 5;
