-- =============================================
-- Migration 029: 新增預約 rejected 狀態
-- 版本：v3.0
-- 日期：2026-01-05
-- 功能：新增 rejected 狀態（教練拒絕預約請求）
-- =============================================

-- 新增 rejected 到 appointment_status enum
-- 注意：ALTER TYPE ADD VALUE 不能在交易中執行，需獨立執行
ALTER TYPE appointment_status ADD VALUE IF NOT EXISTS 'rejected';

-- 更新欄位註解
COMMENT ON COLUMN public.appointments.status IS 
  '預約狀態：requested（待確認）、confirmed（已確認）、rejected（教練拒絕）、completed（已完成）、cancelled（取消）';

-- =============================================
-- 狀態說明
-- =============================================
-- requested  - 學員發起預約請求（待教練確認）
-- confirmed  - 教練確認預約（課程確定）
-- rejected   - 教練拒絕預約請求（課程未發生）⭐ 新增
-- completed  - 上課結束
-- cancelled  - 確認後取消（雙方都可取消，需填原因）
--
-- 語義差異：
-- - rejected：從未發生 - 教練拒絕請求
-- - cancelled：中途取消 - 已確認但後來因故取消
-- =============================================

-- 現有 EXCLUDE 約束 (no_coach_overlap) 不需修改
-- 因為只檢查 status IN ('requested', 'confirmed')
-- rejected/completed/cancelled 不會造成時間衝突

-- =============================================
-- 完成訊息
-- =============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 029 完成：新增 rejected 狀態';
  RAISE NOTICE '   appointment_status 現有 5 種狀態：';
  RAISE NOTICE '   - requested（待確認）';
  RAISE NOTICE '   - confirmed（已確認）';
  RAISE NOTICE '   - rejected（教練拒絕）⭐';
  RAISE NOTICE '   - completed（已完成）';
  RAISE NOTICE '   - cancelled（取消）';
END $$;

