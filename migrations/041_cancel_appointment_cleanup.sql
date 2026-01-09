-- =============================================
-- Migration 041: 預約取消時自動清理資料
-- 版本：v3.1.1
-- 日期：2026-01-09
-- 功能：當預約狀態變為 cancelled 時，自動刪除相關資料
--       - session_notes（由 trigger 創建，appointment_id 關聯）
--       - daily_readiness（由 trigger 創建，appointment_id 關聯）
--       - workout_plans（由教練手動創建，appointment.workout_plan_id 關聯）
-- =============================================

-- 清理預約相關資料的函數
CREATE OR REPLACE FUNCTION cleanup_cancelled_appointment_data()
RETURNS TRIGGER AS $$
DECLARE
  v_deleted_notes INT := 0;
  v_deleted_readiness INT := 0;
  v_deleted_workouts INT := 0;
BEGIN
  -- 只處理狀態變更為 cancelled 的情況
  IF NEW.status = 'cancelled' AND (OLD.status IS NULL OR OLD.status != 'cancelled') THEN
    
    -- 1. 刪除關聯的 session_notes（由 trigger 創建）
    DELETE FROM session_notes 
    WHERE appointment_id = NEW.id;
    GET DIAGNOSTICS v_deleted_notes = ROW_COUNT;
    
    -- 2. 刪除關聯的 daily_readiness（由 trigger 創建）
    DELETE FROM daily_readiness 
    WHERE appointment_id = NEW.id;
    GET DIAGNOSTICS v_deleted_readiness = ROW_COUNT;
    
    -- 3. 如果 appointment.workout_plan_id 有值，刪除教練建立的 workout_plan
    IF NEW.workout_plan_id IS NOT NULL THEN
      DELETE FROM workout_plans 
      WHERE id = NEW.workout_plan_id;
      GET DIAGNOSTICS v_deleted_workouts = ROW_COUNT;
    END IF;
    
    RAISE NOTICE '🗑️ 預約取消清理完成 - appointment: %, 刪除 session_notes: %, daily_readiness: %, workout_plans: %',
      NEW.id, v_deleted_notes, v_deleted_readiness, v_deleted_workouts;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 添加觸發器（在狀態更新後執行）
DROP TRIGGER IF EXISTS trg_cleanup_cancelled_appointment ON appointments;
CREATE TRIGGER trg_cleanup_cancelled_appointment
  AFTER UPDATE OF status ON appointments
  FOR EACH ROW
  WHEN (NEW.status = 'cancelled')
  EXECUTE FUNCTION cleanup_cancelled_appointment_data();

-- =============================================
-- 補充：也處理拒絕（rejected）狀態
-- =============================================
-- rejected 狀態是教練拒絕待確認的預約
-- 此時 trigger 尚未創建資料（只有 confirmed 才會創建）
-- 所以只需要清理可能存在的 session_notes 和 daily_readiness

CREATE OR REPLACE FUNCTION cleanup_rejected_appointment_data()
RETURNS TRIGGER AS $$
BEGIN
  -- 只處理狀態變更為 rejected 的情況
  IF NEW.status = 'rejected' AND (OLD.status IS NULL OR OLD.status != 'rejected') THEN
    
    -- 刪除可能存在的關聯資料（安全起見）
    DELETE FROM session_notes WHERE appointment_id = NEW.id;
    DELETE FROM daily_readiness WHERE appointment_id = NEW.id;
    
    RAISE NOTICE '🗑️ 預約拒絕清理完成 - appointment: %', NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_cleanup_rejected_appointment ON appointments;
CREATE TRIGGER trg_cleanup_rejected_appointment
  AFTER UPDATE OF status ON appointments
  FOR EACH ROW
  WHEN (NEW.status = 'rejected')
  EXECUTE FUNCTION cleanup_rejected_appointment_data();

-- =============================================
-- 完成訊息
-- =============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 041 完成：預約取消/拒絕自動清理觸發器已設置';
  RAISE NOTICE '   - 取消預約時刪除：session_notes, daily_readiness, workout_plan（如有綁定）';
  RAISE NOTICE '   - 拒絕預約時刪除：session_notes, daily_readiness（如有）';
END $$;
