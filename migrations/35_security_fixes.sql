-- ============================================================
-- Migration 35: 安全性修復
-- 版本: v5.2
-- 日期: 2026-02-09
-- ============================================================
-- 修復項目：
-- 1. invite_codes DELETE 政策：任何人可刪 → 只有教練本人可刪自己的
--    （學員使用邀請碼走 RPC bind_coach_by_invite_code，SECURITY DEFINER 處理刪除）
-- ============================================================

-- ============================================================================
-- 1. 修復 invite_codes DELETE 政策
-- ============================================================================
-- 問題：原政策允許任何已認證用戶刪除任何有效邀請碼
-- 修復：限制為教練只能刪除自己的邀請碼

DROP POLICY IF EXISTS "Users can delete invite codes" ON public.invite_codes;

CREATE POLICY "Coaches can delete own invite codes"
  ON public.invite_codes FOR DELETE
  TO authenticated
  USING (auth.uid() = coach_id);
