-- ============================================================================
-- StrengthWise Migration: 023_fix_updated_at.sql
-- ============================================================================
-- 建立時間：2026-01-04
-- 目標：修復被 022 migration 錯誤更新的 updated_at
-- ============================================================================
-- 
-- 問題：022 migration 執行 UPDATE workout_plans SET updated_at = NOW()
-- 導致所有訓練的 updated_at 都變成今天，影響統計系統的時間範圍過濾
-- 
-- 修復邏輯：
-- 對於沒有 completed_date 的訓練，將 updated_at 還原為 created_at
-- ============================================================================

-- 還原 updated_at
UPDATE workout_plans
SET updated_at = created_at
WHERE completed_date IS NULL
  AND updated_at::DATE = CURRENT_DATE;  -- 只修復今天被錯誤更新的

-- 輸出結果
DO $$ 
DECLARE
  fixed_count INT;
BEGIN
  SELECT COUNT(*) INTO fixed_count
  FROM workout_plans
  WHERE completed_date IS NULL
    AND updated_at = created_at;
  
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 023 完成：updated_at 修復';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '已將 completed_date 為 NULL 的訓練計劃，';
  RAISE NOTICE 'updated_at 還原為 created_at';
  RAISE NOTICE '';
END $$;

