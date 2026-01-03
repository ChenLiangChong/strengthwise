-- ============================================================================
-- 019_fix_client_archive_relationship.sql
-- 修復學員無法解除綁定（archived）的 RLS 政策
-- 創建時間：2026-01-03
-- ============================================================================
-- 
-- 問題：學員無法將 status 從 'active' 更新為 'archived'
-- 原因：現有政策 "Clients can accept or reject invitations" 只允許：
--   USING: status = 'pending'（只能操作 pending 狀態的關係）
--   WITH CHECK: status IN ('active', 'rejected')（只能改為這兩種狀態）
-- 
-- 解決：新增政策允許學員（雙方）解除綁定
-- ============================================================================

-- 刪除舊政策（如果存在）
DROP POLICY IF EXISTS "Both parties can archive relationships" ON public.coaching_relationships;

-- 新增：雙方都可以將 active 關係歸檔（解除綁定）
CREATE POLICY "Both parties can archive relationships"
  ON public.coaching_relationships FOR UPDATE
  TO authenticated
  USING (
    (auth.uid() = coach_id OR auth.uid() = client_id)
    AND status = 'active'
  )
  WITH CHECK (
    (auth.uid() = coach_id OR auth.uid() = client_id)
    AND status = 'archived'
  );

COMMENT ON POLICY "Both parties can archive relationships" ON public.coaching_relationships IS 
'允許教練或學員解除綁定（active → archived）';

-- ============================================================================
-- 驗證
-- ============================================================================

-- 檢查所有 coaching_relationships 的 UPDATE 政策
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual as using_clause,
  with_check
FROM pg_policies
WHERE tablename = 'coaching_relationships'
  AND cmd = 'UPDATE'
ORDER BY policyname;

-- 預期結果（4 個 UPDATE 政策）：
-- 1. "Coaches can update their relationships" - 教練可以更新自己的關係
-- 2. "Clients can accept or reject invitations" - 學員可以接受/拒絕邀請
-- 3. "Both parties can reactivate archived relationships" - 雙方可以重新激活（Migration 017）
-- 4. "Both parties can archive relationships" - 雙方可以解除綁定（本 Migration）⭐ 新增

-- ============================================================================
-- 完成
-- ============================================================================
-- ✅ 教練可以解除綁定（通過 "Coaches can update their relationships"）
-- ✅ 學員可以解除綁定（通過 "Both parties can archive relationships"）⭐ 新增
-- ✅ 雙方可以重新綁定（通過 "Both parties can reactivate archived relationships"）
-- ✅ 學員可以接受/拒絕邀請（通過 "Clients can accept or reject invitations"）
-- ============================================================================

