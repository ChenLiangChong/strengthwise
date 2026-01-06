-- =============================================
-- Migration 032: 預約確認自動創建資料
-- 版本：v3.0
-- 日期：2026-01-05
-- 功能：當預約狀態變為 confirmed 時，自動創建相關資料
--       - 空的 session_notes
--       - 未填寫的 daily_readiness
--       - 空的 workout_plans（關聯到預約）
-- =============================================

-- 自動創建 Session Mode 相關資料的函數
CREATE OR REPLACE FUNCTION create_session_mode_data()
RETURNS TRIGGER AS $$
DECLARE
  v_session_note_id UUID;
  v_readiness_id UUID;
  v_workout_plan_id UUID;
  v_start_time TIMESTAMPTZ;
  v_end_time TIMESTAMPTZ;
BEGIN
  -- 只處理狀態變更為 confirmed 的情況
  IF NEW.status = 'confirmed' AND (OLD.status IS NULL OR OLD.status != 'confirmed') THEN
    
    -- 從 time_range 取得開始和結束時間
    v_start_time := lower(NEW.time_range);
    v_end_time := upper(NEW.time_range);
    
    -- 1. 創建空的 session_notes
    -- ⚠️ v3.1 修正：使用正確的欄位名 (title, content, visibility)
    INSERT INTO session_notes (
      coach_id,
      client_id,
      appointment_id,
      title,
      content,
      visibility
    ) VALUES (
      NEW.coach_id,
      NEW.client_id,
      NEW.id,
      '課程筆記 - ' || to_char(v_start_time, 'YYYY-MM-DD HH24:MI'),
      '{}'::jsonb,
      'coach_only'
    )
    ON CONFLICT (appointment_id) WHERE appointment_id IS NOT NULL DO NOTHING
    RETURNING id INTO v_session_note_id;
    
    -- 2. 創建未填寫的 daily_readiness（如果不存在）
    INSERT INTO daily_readiness (
      user_id,
      appointment_id,
      session_note_id,
      log_date,
      metrics
    ) VALUES (
      NEW.client_id,
      NEW.id,
      v_session_note_id,
      v_start_time::date,
      '{}'::jsonb
    )
    ON CONFLICT (user_id, appointment_id) DO NOTHING
    RETURNING id INTO v_readiness_id;
    
    -- 3. 創建空的 workout_plans（關聯到預約）
    -- 注意：如果教練之後從模板創建，會更新這筆記錄
    INSERT INTO workout_plans (
      user_id,
      created_by,
      title,
      scheduled_date,
      start_time,
      end_time,
      appointment_id,
      notes
    ) VALUES (
      NEW.client_id,
      NEW.coach_id,
      '課程訓練 - ' || to_char(v_start_time, 'YYYY-MM-DD HH24:MI'),
      v_start_time::date,
      v_start_time,
      v_end_time,
      NEW.id,
      '（由 Session Mode 自動創建）'
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_workout_plan_id;
    
    RAISE NOTICE '✅ Session Mode 資料已創建 - appointment: %, session_note: %, readiness: %, workout: %',
      NEW.id, v_session_note_id, v_readiness_id, v_workout_plan_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 添加觸發器
DROP TRIGGER IF EXISTS trg_create_session_mode_data ON appointments;
CREATE TRIGGER trg_create_session_mode_data
  AFTER INSERT OR UPDATE OF status ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION create_session_mode_data();

-- 為 session_notes 添加 appointment_id 欄位（如果不存在）
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'session_notes' AND column_name = 'appointment_id'
  ) THEN
    ALTER TABLE session_notes 
    ADD COLUMN appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL;
    
    CREATE UNIQUE INDEX IF NOT EXISTS idx_session_notes_appointment 
      ON session_notes(appointment_id) WHERE appointment_id IS NOT NULL;
    
    COMMENT ON COLUMN session_notes.appointment_id IS '關聯的預約 ID（Session Mode 使用）';
  END IF;
END $$;

-- 為 workout_plans 添加 appointment_id 欄位（如果不存在）
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'workout_plans' AND column_name = 'appointment_id'
  ) THEN
    ALTER TABLE workout_plans 
    ADD COLUMN appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL;
    
    CREATE INDEX IF NOT EXISTS idx_workout_plans_appointment 
      ON workout_plans(appointment_id) WHERE appointment_id IS NOT NULL;
    
    COMMENT ON COLUMN workout_plans.appointment_id IS '關聯的預約 ID（Session Mode 使用）';
  END IF;
END $$;

-- =============================================
-- 完成訊息
-- =============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 032 完成：預約確認自動創建資料觸發器已設置';
  RAISE NOTICE '   預約確認後自動創建：session_notes, daily_readiness, workout_plans';
END $$;

