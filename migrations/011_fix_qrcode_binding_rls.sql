-- ============================================================================
-- 011_fix_qrcode_binding_rls.sql
-- 修復 QR Code 綁定 RLS 政策
-- 創建時間：2026-01-03
-- 更新時間：2026-01-03 14:15（放寬條件）
-- ============================================================================
-- 
-- 問題：當前 coaching_relationships 表只允許教練創建關係
-- 解決：新增學員也可以創建關係（用於 QR Code 雙向綁定）
-- 
-- 場景：
-- 1. 教練掃描學員 QR Code → coach_id = 教練, client_id = 學員
-- 2. 學員掃描教練 QR Code → coach_id = 教練, client_id = 學員
-- 
-- 兩種情況下，創建者都不同，需要允許兩種角色都能插入數據
-- ============================================================================

-- 刪除舊政策（如果存在）
DROP POLICY IF EXISTS "Clients can create coach relationships" ON public.coaching_relationships;

-- 新增：學員可以創建關係（加入教練）
-- 修改：移除 is_coach = false 限制，支援雙重角色用戶
CREATE POLICY "Clients can create coach relationships"
  ON public.coaching_relationships FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = client_id
  );

-- ============================================================================
-- 說明
-- ============================================================================
-- 
-- 現在有兩條 INSERT 政策（OR 邏輯）：
-- 1. "Coaches can create client relationships" - 教練邀請學員
--    條件: auth.uid() = coach_id AND is_coach = true
-- 2. "Clients can create coach relationships" - 學員加入教練（新增）
--    條件: auth.uid() = client_id
-- 
-- 支援場景：
-- ✅ 純學員加入教練
-- ✅ 教練（同時也是學員）加入另一個教練
-- ✅ 雙重角色用戶的所有場景
-- ============================================================================

