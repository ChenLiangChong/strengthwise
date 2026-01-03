-- ============================================================================
-- 017_fix_reactivate_relationship.sql
-- 修復重新激活 archived 關係的 RLS 政策
-- 創建時間：2026-01-03
-- ============================================================================
-- 
-- 問題：當關係狀態為 'archived' 時，雙方都無法 UPDATE 將其改回 'active'
-- 原因：現有 UPDATE 政策只允許：
--   1. 教練更新自己創建的關係（任何狀態）
--   2. 學員只能更新 status = 'pending' 的關係
-- 
-- 解決：新增政策允許雙方重新激活 archived 關係
-- ============================================================================

-- 刪除舊政策（如果存在）
DROP POLICY IF EXISTS "Both parties can reactivate archived relationships" ON public.coaching_relationships;

-- 新增：雙方都可以重新激活 archived 關係
CREATE POLICY "Both parties can reactivate archived relationships"
  ON public.coaching_relationships FOR UPDATE
  TO authenticated
  USING (
    (auth.uid() = coach_id OR auth.uid() = client_id)
    AND status = 'archived'
  )
  WITH CHECK (
    (auth.uid() = coach_id OR auth.uid() = client_id)
    AND status = 'active'
  );

COMMENT ON POLICY "Both parties can reactivate archived relationships" ON public.coaching_relationships IS 
'允許教練或學員重新激活已歸檔的關係（重新綁定）';

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

-- 預期結果：
-- 1. "Coaches can update their relationships" - 教練可以更新自己的關係
-- 2. "Clients can accept or reject invitations" - 學員可以接受/拒絕邀請
-- 3. "Both parties can reactivate archived relationships" - 雙方可以重新激活（新增）⭐

-- ============================================================================
-- 完成
-- ============================================================================
-- ✅ 教練可以更新任何自己的關係（包括 archived）
-- ✅ 學員可以接受 pending 邀請
-- ✅ 雙方可以重新激活 archived 關係（重新綁定）
-- ============================================================================

