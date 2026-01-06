-- ============================================================================
-- Migration 037: 修復 daily_workout_summary RLS（允許教練操作學員資料）
-- 作者: AI Assistant
-- 日期: 2026-01-06
-- 目的: 教練在 Session Mode 為學員建立訓練計畫時需要更新 daily_workout_summary
-- ============================================================================

-- ============================================================================
-- 1. 刪除舊的限制性策略
-- ============================================================================

DROP POLICY IF EXISTS "Users can view own daily summary" ON daily_workout_summary;

-- ============================================================================
-- 2. 建立新的 SELECT 策略（用戶 + 教練）
-- ============================================================================

CREATE POLICY "daily_summary_select"
  ON daily_workout_summary
  FOR SELECT
  USING (
    -- 用戶查看自己的
    auth.uid() = user_id
    OR
    -- 教練查看學員的
    EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = daily_workout_summary.user_id
        AND cr.status = 'active'
    )
  );

-- ============================================================================
-- 3. INSERT 策略（用戶 + 教練）
-- ============================================================================

CREATE POLICY "daily_summary_insert"
  ON daily_workout_summary
  FOR INSERT
  WITH CHECK (
    -- 用戶插入自己的
    auth.uid() = user_id
    OR
    -- 教練為學員插入
    EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = user_id
        AND cr.status = 'active'
    )
  );

-- ============================================================================
-- 4. UPDATE 策略（用戶 + 教練）
-- ============================================================================

CREATE POLICY "daily_summary_update"
  ON daily_workout_summary
  FOR UPDATE
  USING (
    -- 用戶更新自己的
    auth.uid() = user_id
    OR
    -- 教練更新學員的
    EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = daily_workout_summary.user_id
        AND cr.status = 'active'
    )
  )
  WITH CHECK (
    auth.uid() = user_id
    OR
    EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = user_id
        AND cr.status = 'active'
    )
  );

-- ============================================================================
-- 5. DELETE 策略（用戶 + 教練）
-- ============================================================================

CREATE POLICY "daily_summary_delete"
  ON daily_workout_summary
  FOR DELETE
  USING (
    -- 用戶刪除自己的
    auth.uid() = user_id
    OR
    -- 教練刪除學員的
    EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = daily_workout_summary.user_id
        AND cr.status = 'active'
    )
  );

-- ============================================================================
-- 6. 同樣修復 personal_records
-- ============================================================================

DROP POLICY IF EXISTS "Users can view own personal records" ON personal_records;

CREATE POLICY "personal_records_select"
  ON personal_records
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR
    EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = personal_records.user_id
        AND cr.status = 'active'
    )
  );

CREATE POLICY "personal_records_insert"
  ON personal_records
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    OR
    EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = user_id
        AND cr.status = 'active'
    )
  );

CREATE POLICY "personal_records_update"
  ON personal_records
  FOR UPDATE
  USING (
    auth.uid() = user_id
    OR
    EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = personal_records.user_id
        AND cr.status = 'active'
    )
  )
  WITH CHECK (
    auth.uid() = user_id
    OR
    EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = user_id
        AND cr.status = 'active'
    )
  );

CREATE POLICY "personal_records_delete"
  ON personal_records
  FOR DELETE
  USING (
    auth.uid() = user_id
    OR
    EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = personal_records.user_id
        AND cr.status = 'active'
    )
  );

-- ============================================================================
-- 完成
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Migration 037 完成 - RLS 修復（教練操作學員資料）';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE '已修復：';
  RAISE NOTICE '  ✓ daily_workout_summary - SELECT/INSERT/UPDATE/DELETE';
  RAISE NOTICE '  ✓ personal_records - SELECT/INSERT/UPDATE/DELETE';
  RAISE NOTICE '';
  RAISE NOTICE '現在教練可以在 Session Mode 為學員建立訓練計畫了';
  RAISE NOTICE '';
END $$;

