-- ============================================================
-- Migration 040: 教練創建預約 RLS 策略
-- 版本: v3.1.1
-- 日期: 2026-01-09
-- 目的: 允許教練創建臨時課程（AdHoc Session）
-- ============================================================

-- ============================================================
-- 1. 新增教練創建預約的 RLS 策略
-- ============================================================

-- 教練創建預約（臨時課程）
-- 條件：教練只能為自己的學員創建預約
CREATE POLICY "coaches_create_appointments"
ON public.appointments FOR INSERT
WITH CHECK (
  auth.uid() = coach_id
  AND EXISTS (
    SELECT 1 FROM public.coaching_relationships cr
    WHERE cr.coach_id = auth.uid()
      AND cr.client_id = appointments.client_id
      AND cr.status = 'active'
  )
);

-- ============================================================
-- 驗證
-- ============================================================
-- 執行後可用以下 SQL 驗證策略是否創建成功：
-- SELECT policyname, cmd FROM pg_policies WHERE tablename = 'appointments';
