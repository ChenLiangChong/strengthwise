-- ============================================================================
-- Migration 026: 修正 workout_plans DELETE RLS 策略
-- ============================================================================
-- 版本：v2.9
-- 日期：2026-01-04
-- 說明：只有創建者可以刪除訓練計畫，學員不能刪除教練創建的計畫
-- ============================================================================

-- ============================================================================
-- 問題說明
-- ============================================================================
-- 
-- 原始策略：
--   USING ((trainee_id = auth.uid()) OR (creator_id = auth.uid()))
-- 
-- 問題：學員（trainee_id）可以刪除教練創建的訓練計畫
-- 
-- 解決方案：只允許創建者（creator_id）刪除
-- 
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. 移除舊的 DELETE 策略
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can delete their own workout plans" ON public.workout_plans;
DROP POLICY IF EXISTS "Users can delete their workout plans" ON public.workout_plans;
DROP POLICY IF EXISTS "Only creators can delete workout plans" ON public.workout_plans;

-- ----------------------------------------------------------------------------
-- 2. 建立新的 DELETE 策略（只有創建者可以刪除）
-- ----------------------------------------------------------------------------

CREATE POLICY "Only creators can delete workout plans"
  ON public.workout_plans 
  FOR DELETE
  TO authenticated
  USING (auth.uid() = creator_id);

-- ----------------------------------------------------------------------------
-- 3. 向後相容：處理舊記錄（creator_id 為 NULL 的情況）
-- ----------------------------------------------------------------------------
-- 
-- 舊記錄可能沒有 creator_id，這種情況下：
-- - 如果 creator_id IS NULL，則允許 trainee_id 刪除（向後相容）
-- 
-- 修改策略以支援這種情況：
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Only creators can delete workout plans" ON public.workout_plans;

CREATE POLICY "Only creators can delete workout plans"
  ON public.workout_plans 
  FOR DELETE
  TO authenticated
  USING (
    -- 新記錄：只有創建者可以刪除
    (creator_id IS NOT NULL AND auth.uid() = creator_id)
    OR
    -- 舊記錄（無 creator_id）：允許 trainee_id 刪除（向後相容）
    (creator_id IS NULL AND auth.uid() = trainee_id)
  );

-- ----------------------------------------------------------------------------
-- 4. 驗證
-- ----------------------------------------------------------------------------

-- 檢查策略是否建立成功
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'workout_plans' 
    AND policyname = 'Only creators can delete workout plans'
  ) THEN
    RAISE EXCEPTION 'Policy creation failed';
  END IF;
  
  RAISE NOTICE '✅ workout_plans DELETE RLS 策略已更新';
END $$;

-- ============================================================================
-- 完成
-- ============================================================================
-- 
-- 新策略效果：
-- - 教練創建的計畫：只有教練可以刪除
-- - 學員自己創建的計畫：學員可以刪除
-- - 舊記錄（無 creator_id）：trainee_id 可以刪除（向後相容）
-- 
-- ============================================================================

