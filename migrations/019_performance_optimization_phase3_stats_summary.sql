-- ============================================================================
-- StrengthWise - Phase 3 效能優化：統計查詢優化
-- ============================================================================
-- 建立時間：2024-12-27
-- 目標：統計頁面效能提升 60-80%
-- 預期效益：
--   - 彙總表：預先計算統計數據，查詢從秒級降至毫秒級
--   - 自動觸發器：新增訓練記錄時自動更新統計
--   - RPC 函數：封裝複雜查詢，減少往返次數
-- ============================================================================

-- ============================================================================
-- 1. 每日訓練彙總表（Daily Workout Summary）
-- ============================================================================

CREATE TABLE IF NOT EXISTS daily_workout_summary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  
  -- 訓練統計
  workout_count INT DEFAULT 0,              -- 當天完成的訓練次數
  total_exercises INT DEFAULT 0,            -- 總動作數
  total_sets INT DEFAULT 0,                 -- 總組數
  total_volume DECIMAL(10,2) DEFAULT 0,     -- 總訓練量（kg）
  
  -- 訓練類型分布
  resistance_training_count INT DEFAULT 0,  -- 阻力訓練次數
  cardio_count INT DEFAULT 0,               -- 心肺訓練次數
  mobility_count INT DEFAULT 0,             -- 活動度訓練次數
  
  -- 時間統計
  total_training_time INT DEFAULT 0,        -- 總訓練時間（分鐘）
  
  -- 元數據
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 唯一約束：每個使用者每天只有一條記錄
  UNIQUE(user_id, date)
);

-- 索引：使用者時間序列查詢
CREATE INDEX IF NOT EXISTS idx_daily_summary_user_date 
ON daily_workout_summary (user_id, date DESC);

-- 索引：使用者最近記錄
CREATE INDEX IF NOT EXISTS idx_daily_summary_user_updated 
ON daily_workout_summary (user_id, updated_at DESC);

DO $$ BEGIN
  RAISE NOTICE '每日訓練彙總表 daily_workout_summary 建立完成 ✓';
END $$;

-- ============================================================================
-- 2. 個人記錄表（Personal Records - PR）
-- ============================================================================

CREATE TABLE IF NOT EXISTS personal_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exercise_id TEXT NOT NULL,
  exercise_name TEXT NOT NULL,
  
  -- PR 數據
  max_weight DECIMAL(10,2) DEFAULT 0,       -- 最大重量
  max_reps INT DEFAULT 0,                   -- 單組最多次數
  max_volume DECIMAL(10,2) DEFAULT 0,       -- 單次訓練最大容量
  
  -- 時間記錄
  achieved_date DATE NOT NULL,              -- 達成日期
  workout_plan_id TEXT,                     -- 關聯的訓練計劃
  
  -- 元數據
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 唯一約束：每個使用者每個動作只有一條 PR 記錄
  UNIQUE(user_id, exercise_id)
);

-- 索引：使用者查詢
CREATE INDEX IF NOT EXISTS idx_pr_user_weight 
ON personal_records (user_id, max_weight DESC);

-- 索引：動作 PR
CREATE INDEX IF NOT EXISTS idx_pr_exercise 
ON personal_records (exercise_id, max_weight DESC);

DO $$ BEGIN
  RAISE NOTICE '個人記錄表 personal_records 建立完成 ✓';
END $$;

-- ============================================================================
-- 3. 自動更新每日彙總的觸發器
-- ============================================================================

-- 觸發器函式：更新每日彙總
CREATE OR REPLACE FUNCTION update_daily_workout_summary()
RETURNS TRIGGER AS $$
DECLARE
  training_date DATE;
  v_resistance_count INT := 0;  -- ✅ 重新命名避免衝突
  v_cardio_count INT := 0;      -- ✅ 重新命名避免衝突
  v_mobility_count INT := 0;    -- ✅ 重新命名避免衝突
  exercise_item JSONB;
BEGIN
  -- 取得訓練日期
  IF NEW.completed_date IS NOT NULL THEN
    training_date := NEW.completed_date::DATE;
  ELSE
    training_date := NEW.updated_at::DATE;
  END IF;
  
  -- 如果不是已完成的訓練，跳過
  IF NEW.completed = FALSE THEN
    RETURN NEW;
  END IF;
  
  -- 計算訓練類型分布（遍歷 JSONB 陣列）
  FOR exercise_item IN SELECT * FROM jsonb_array_elements(NEW.exercises)
  LOOP
    CASE (exercise_item->>'trainingType')
      WHEN '阻力訓練' THEN v_resistance_count := v_resistance_count + 1;
      WHEN '心肺適能訓練' THEN v_cardio_count := v_cardio_count + 1;
      WHEN '活動度與伸展' THEN v_mobility_count := v_mobility_count + 1;
      ELSE NULL;
    END CASE;
  END LOOP;
  
  -- 插入或更新彙總記錄
  INSERT INTO daily_workout_summary (
    user_id,
    date,
    workout_count,
    total_exercises,
    total_sets,
    total_volume,
    resistance_training_count,
    cardio_count,
    mobility_count,
    updated_at
  ) VALUES (
    NEW.trainee_id,
    training_date,
    1,
    COALESCE(NEW.total_exercises, 0)::INT,
    COALESCE(NEW.total_sets, 0)::INT,
    COALESCE(NEW.total_volume, 0)::DECIMAL(10,2),
    v_resistance_count,
    v_cardio_count,
    v_mobility_count,
    NOW()
  )
  ON CONFLICT (user_id, date)
  DO UPDATE SET
    workout_count = daily_workout_summary.workout_count + 1,
    total_exercises = daily_workout_summary.total_exercises + COALESCE(NEW.total_exercises, 0)::INT,
    total_sets = daily_workout_summary.total_sets + COALESCE(NEW.total_sets, 0)::INT,
    total_volume = daily_workout_summary.total_volume + COALESCE(NEW.total_volume, 0)::DECIMAL(10,2),
    resistance_training_count = daily_workout_summary.resistance_training_count + v_resistance_count,
    cardio_count = daily_workout_summary.cardio_count + v_cardio_count,
    mobility_count = daily_workout_summary.mobility_count + v_mobility_count,
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 建立觸發器
DROP TRIGGER IF EXISTS trigger_update_daily_summary ON workout_plans;
CREATE TRIGGER trigger_update_daily_summary
  AFTER INSERT OR UPDATE OF completed, exercises, total_volume, total_sets
  ON workout_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_daily_workout_summary();

DO $$ BEGIN
  RAISE NOTICE '每日彙總自動更新觸發器建立完成 ✓';
END $$;

-- ============================================================================
-- 4. 自動更新個人記錄（PR）的觸發器
-- ============================================================================

CREATE OR REPLACE FUNCTION update_personal_records()
RETURNS TRIGGER AS $$
DECLARE
  exercise_item JSONB;
  exercise_id_val TEXT;
  exercise_name_val TEXT;
  max_weight_val DECIMAL;
  max_reps_val INT;
  set_item JSONB;
  current_weight DECIMAL;
  current_reps INT;
BEGIN
  -- 如果不是已完成的訓練，跳過
  IF NEW.completed = FALSE THEN
    RETURN NEW;
  END IF;
  
  -- 遍歷所有動作
  FOR exercise_item IN SELECT * FROM jsonb_array_elements(NEW.exercises)
  LOOP
    exercise_id_val := exercise_item->>'exerciseId';
    exercise_name_val := exercise_item->>'exerciseName';
    max_weight_val := 0;
    max_reps_val := 0;
    
    -- 遍歷所有組數，找出最大重量和次數
    FOR set_item IN SELECT * FROM jsonb_array_elements(exercise_item->'sets')
    LOOP
      -- 只統計已完成的組
      IF (set_item->>'completed')::BOOLEAN = TRUE THEN
        current_weight := COALESCE((set_item->>'weight')::DECIMAL, 0);
        current_reps := COALESCE((set_item->>'reps')::INT, 0);
        
        IF current_weight > max_weight_val THEN
          max_weight_val := current_weight;
        END IF;
        
        IF current_reps > max_reps_val THEN
          max_reps_val := current_reps;
        END IF;
      END IF;
    END LOOP;
    
    -- 更新 PR 記錄（只在新記錄更高時更新）
    IF max_weight_val > 0 OR max_reps_val > 0 THEN
      INSERT INTO personal_records (
        user_id,
        exercise_id,
        exercise_name,
        max_weight,
        max_reps,
        achieved_date,
        workout_plan_id,
        updated_at
      ) VALUES (
        NEW.trainee_id,
        exercise_id_val,
        exercise_name_val,
        max_weight_val,
        max_reps_val,
        COALESCE(NEW.completed_date::DATE, NEW.updated_at::DATE),
        NEW.id,
        NOW()
      )
      ON CONFLICT (user_id, exercise_id)
      DO UPDATE SET
        max_weight = GREATEST(personal_records.max_weight, max_weight_val),
        max_reps = GREATEST(personal_records.max_reps, max_reps_val),
        achieved_date = CASE 
          WHEN max_weight_val > personal_records.max_weight 
            OR max_reps_val > personal_records.max_reps 
          THEN COALESCE(NEW.completed_date::DATE, NEW.updated_at::DATE)
          ELSE personal_records.achieved_date
        END,
        workout_plan_id = CASE 
          WHEN max_weight_val > personal_records.max_weight 
            OR max_reps_val > personal_records.max_reps 
          THEN NEW.id
          ELSE personal_records.workout_plan_id
        END,
        updated_at = NOW();
    END IF;
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 建立觸發器
DROP TRIGGER IF EXISTS trigger_update_pr ON workout_plans;
CREATE TRIGGER trigger_update_pr
  AFTER INSERT OR UPDATE OF completed, exercises
  ON workout_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_personal_records();

DO $$ BEGIN
  RAISE NOTICE '個人記錄（PR）自動更新觸發器建立完成 ✓';
END $$;

-- ============================================================================
-- 5. RPC 函數：快速獲取訓練統計
-- ============================================================================

-- 獲取指定時間範圍的訓練統計
CREATE OR REPLACE FUNCTION get_training_statistics(
  user_id_param UUID,
  start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  total_workouts BIGINT,
  total_exercises BIGINT,
  total_sets BIGINT,
  total_volume NUMERIC,
  avg_volume_per_workout NUMERIC,
  resistance_training_ratio NUMERIC,
  training_days INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    SUM(workout_count)::BIGINT AS total_workouts,
    SUM(total_exercises)::BIGINT AS total_exercises,
    SUM(total_sets)::BIGINT AS total_sets,
    SUM(total_volume)::NUMERIC AS total_volume,
    CASE 
      WHEN SUM(workout_count) > 0 
      THEN ROUND(SUM(total_volume) / SUM(workout_count), 2)
      ELSE 0
    END AS avg_volume_per_workout,
    CASE 
      WHEN SUM(workout_count) > 0 
      THEN ROUND(SUM(resistance_training_count)::NUMERIC / SUM(workout_count), 2)
      ELSE 0
    END AS resistance_training_ratio,
    COUNT(DISTINCT date)::INT AS training_days
  FROM daily_workout_summary
  WHERE user_id = user_id_param
    AND date BETWEEN start_date AND end_date;
END;
$$ LANGUAGE plpgsql STABLE;

DO $$ BEGIN
  RAISE NOTICE 'RPC 函數 get_training_statistics() 建立完成 ✓';
END $$;

-- ============================================================================
-- 6. RPC 函數：快速獲取個人記錄（Top PRs）
-- ============================================================================

CREATE OR REPLACE FUNCTION get_top_personal_records(
  user_id_param UUID,
  limit_count INT DEFAULT 10
)
RETURNS TABLE (
  exercise_id TEXT,
  exercise_name TEXT,
  max_weight NUMERIC,
  max_reps INT,
  achieved_date DATE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    pr.exercise_id,
    pr.exercise_name,
    pr.max_weight,
    pr.max_reps,
    pr.achieved_date
  FROM personal_records pr
  WHERE pr.user_id = user_id_param
  ORDER BY pr.max_weight DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE;

DO $$ BEGIN
  RAISE NOTICE 'RPC 函數 get_top_personal_records() 建立完成 ✓';
END $$;

-- ============================================================================
-- 7. 視圖：訓練頻率分析
-- ============================================================================

CREATE OR REPLACE VIEW v_training_frequency AS
SELECT 
  user_id,
  date_trunc('week', date) AS week_start,
  COUNT(*) AS training_days,
  SUM(workout_count) AS total_workouts,
  SUM(total_volume) AS total_volume,
  AVG(total_volume) AS avg_daily_volume
FROM daily_workout_summary
WHERE date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY user_id, date_trunc('week', date)
ORDER BY user_id, week_start DESC;

DO $$ BEGIN
  RAISE NOTICE '訓練頻率分析視圖 v_training_frequency 建立完成 ✓';
END $$;

-- ============================================================================
-- 8. 初始化現有數據的彙總
-- ============================================================================

-- 為現有已完成的訓練記錄生成彙總數據
DO $$
DECLARE
  processed_count INT := 0;
BEGIN
  -- 使用觸發器函數處理現有數據
  -- 注意：這可能需要一些時間，取決於數據量
  
  -- 刪除現有彙總（重新計算）
  DELETE FROM daily_workout_summary;
  DELETE FROM personal_records;
  
  RAISE NOTICE '開始初始化現有數據的彙總...';
  
  -- 處理所有已完成的訓練計劃
  UPDATE workout_plans 
  SET updated_at = updated_at 
  WHERE completed = TRUE;
  
  -- 統計處理數量
  GET DIAGNOSTICS processed_count = ROW_COUNT;
  
  RAISE NOTICE '✓ 已處理 % 筆訓練記錄', processed_count;
END $$;

-- ============================================================================
-- ✅ Phase 3 完成
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Phase 3 統計查詢優化完成！';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '已建立：';
  RAISE NOTICE '  - 2 個彙總表（daily_workout_summary, personal_records）';
  RAISE NOTICE '  - 2 個自動觸發器（每日彙總 + PR 更新）';
  RAISE NOTICE '  - 2 個 RPC 統計函數';
  RAISE NOTICE '  - 1 個訓練頻率分析視圖';
  RAISE NOTICE '';
  RAISE NOTICE '測試指令：';
  RAISE NOTICE '  SELECT * FROM daily_workout_summary LIMIT 5;';
  RAISE NOTICE '  SELECT * FROM personal_records LIMIT 5;';
  RAISE NOTICE '  SELECT * FROM get_training_statistics(''your_user_id''::UUID);';
  RAISE NOTICE '  SELECT * FROM v_training_frequency WHERE user_id = ''your_user_id''::UUID;';
  RAISE NOTICE '';
  RAISE NOTICE '預期效益：';
  RAISE NOTICE '  - 統計查詢：從秒級降至毫秒級（提升 60-80%%)';
  RAISE NOTICE '  - 自動維護：新增訓練時自動更新統計';
  RAISE NOTICE '  - PR 追蹤：實時更新個人最佳記錄';
  RAISE NOTICE '';
END $$;

