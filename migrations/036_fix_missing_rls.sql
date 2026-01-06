-- ============================================================================
-- Migration 036: 修復缺失的 RLS 策略
-- 作者: AI Assistant
-- 日期: 2026-01-06
-- 目的: 為 daily_workout_summary 和 personal_records 啟用 RLS
-- ============================================================================

-- ============================================================================
-- 1. daily_workout_summary 表 RLS
-- ============================================================================

-- 啟用 RLS
ALTER TABLE daily_workout_summary ENABLE ROW LEVEL SECURITY;

-- 用戶只能查看自己的統計
CREATE POLICY "Users can view own daily summary"
  ON daily_workout_summary
  FOR SELECT
  USING (
    -- 直接訪問
    auth.uid() = user_id
    OR
    -- 教練可查看學員統計
    EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = daily_workout_summary.user_id
        AND cr.status = 'active'
    )
  );

-- 只有系統（觸發器）可以插入/更新/刪除，不需要用戶策略
-- 使用 SECURITY DEFINER 函數處理

DO $$ BEGIN
  RAISE NOTICE '✓ daily_workout_summary RLS 已啟用';
END $$;

-- ============================================================================
-- 2. personal_records 表 RLS
-- ============================================================================

-- 啟用 RLS
ALTER TABLE personal_records ENABLE ROW LEVEL SECURITY;

-- 用戶只能查看自己的 PR
CREATE POLICY "Users can view own personal records"
  ON personal_records
  FOR SELECT
  USING (
    -- 直接訪問
    auth.uid() = user_id
    OR
    -- 教練可查看學員 PR
    EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = personal_records.user_id
        AND cr.status = 'active'
    )
  );

DO $$ BEGIN
  RAISE NOTICE '✓ personal_records RLS 已啟用';
END $$;

-- ============================================================================
-- 3. 驗證
-- ============================================================================

DO $$ 
DECLARE
  missing_rls INT;
BEGIN
  SELECT COUNT(*) INTO missing_rls
  FROM pg_tables 
  WHERE schemaname = 'public' 
    AND rowsecurity = false
    AND tablename NOT LIKE 'pg_%';
  
  IF missing_rls > 0 THEN
    RAISE WARNING '⚠️ 仍有 % 個表未啟用 RLS', missing_rls;
  ELSE
    RAISE NOTICE '✓ 所有 public 表都已啟用 RLS';
  END IF;
END $$;

-- ============================================================================
-- 完成
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '==============================================';
  RAISE NOTICE 'Migration 036 完成 - RLS 修復';
  RAISE NOTICE '==============================================';
  RAISE NOTICE '';
  RAISE NOTICE '已修復：';
  RAISE NOTICE '  ✓ daily_workout_summary - 用戶/教練可查看';
  RAISE NOTICE '  ✓ personal_records - 用戶/教練可查看';
  RAISE NOTICE '';
  RAISE NOTICE '驗證指令：';
  RAISE NOTICE '  SELECT tablename, rowsecurity FROM pg_tables';
  RAISE NOTICE '  WHERE schemaname = ''public'' ORDER BY tablename;';
  RAISE NOTICE '';
END $$;

