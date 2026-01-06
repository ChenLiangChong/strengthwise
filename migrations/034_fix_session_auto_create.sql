-- =============================================
-- Migration 034: 修復 session_notes 自動創建觸發器
-- 版本：v3.1
-- 日期：2026-01-06
-- 問題：031 中的 create_session_mode_data() 使用了不存在的欄位
--       錯誤：session_date, note_type, soap
--       正確：title, content, visibility
-- =============================================

-- 1. 添加唯一索引支援 ON CONFLICT（如果不存在）
CREATE UNIQUE INDEX IF NOT EXISTS idx_session_notes_appointment_unique
  ON session_notes(appointment_id) WHERE appointment_id IS NOT NULL;

-- 2. 修正 create_session_mode_data() 函數
CREATE OR REPLACE FUNCTION create_session_mode_data()
RETURNS TRIGGER AS $$
DECLARE
  v_session_note_id UUID;
  v_readiness_id UUID;
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
    
    -- 注意：workout_plans 不自動創建，由教練在 Session Mode 中手動建立
    
    RAISE NOTICE '✅ Session Mode 資料已創建 - appointment: %, session_note: %, readiness: %',
      NEW.id, v_session_note_id, v_readiness_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 完成訊息
-- =============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 034 完成：修復 session_notes 自動創建觸發器';
  RAISE NOTICE '   修正欄位：session_date/note_type/soap → title/content/visibility';
  RAISE NOTICE '   移除 workout_plans 自動創建（改為教練手動建立）';
END $$;

