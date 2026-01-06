-- =============================================
-- Migration 035: 修正 session_notes 預設 visibility 為 shared
-- 版本：v3.1
-- 日期：2026-01-06
-- 問題：034 中設定 visibility = 'coach_only'，導致學員看不到筆記
-- 解決：改為 'shared'，讓學員能即時看到教練的照片、標籤等
-- =============================================

-- 1. 更新 create_session_mode_data() 函數
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
    -- ⭐ v3.1 修正：visibility 改為 'shared'，讓學員能看到
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
      'shared'  -- ⭐ 修正：從 'coach_only' 改為 'shared'
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

-- 2. 更新現有的 coach_only 為 shared（讓現有筆記也能被學員看到）
UPDATE session_notes 
SET visibility = 'shared' 
WHERE visibility = 'coach_only';

-- =============================================
-- 完成訊息
-- =============================================
DO $$
DECLARE
  v_updated_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_updated_count 
  FROM session_notes 
  WHERE visibility = 'shared';
  
  RAISE NOTICE '✅ Migration 035 完成：修正 session_notes visibility';
  RAISE NOTICE '   預設值：coach_only → shared';
  RAISE NOTICE '   已更新筆記數：%', v_updated_count;
END $$;

