-- ============================================================================
-- StrengthWise Migration: 18_v3_session_mode_fixes.sql
-- ============================================================================
-- 合併自: 034_fix_session_auto_create.sql, 035_fix_session_note_visibility.sql
-- 版本: v3.1
-- 日期: 2026-01-06
-- ============================================================================
-- 
-- 包含:
-- 1. 修復 create_session_mode_data() 函數欄位名稱
-- 2. 修正 session_notes 預設 visibility 為 shared
-- ============================================================================

-- ============================================================================
-- PART 1: 添加唯一索引支援 ON CONFLICT
-- ============================================================================

CREATE UNIQUE INDEX IF NOT EXISTS idx_session_notes_appointment_unique
  ON session_notes(appointment_id) WHERE appointment_id IS NOT NULL;

-- ============================================================================
-- PART 2: 修正 create_session_mode_data() 函數（最終版）
-- ============================================================================
-- 
-- 修正內容：
-- - 使用正確欄位名 (title, content, visibility)
-- - visibility 預設為 'shared'（讓學員能看到）
-- - 移除 workout_plans 自動創建（教練手動建立）

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
    
    v_start_time := lower(NEW.time_range);
    v_end_time := upper(NEW.time_range);
    
    -- 1. 創建 session_notes（visibility = 'shared'）
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
      'shared'
    )
    ON CONFLICT (appointment_id) WHERE appointment_id IS NOT NULL DO NOTHING
    RETURNING id INTO v_session_note_id;
    
    -- 2. 創建 daily_readiness
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
    
    RAISE NOTICE '✅ Session Mode 資料已創建 - appointment: %, note: %, readiness: %',
      NEW.id, v_session_note_id, v_readiness_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- PART 3: 更新現有的 coach_only 筆記為 shared
-- ============================================================================

UPDATE session_notes 
SET visibility = 'shared' 
WHERE visibility = 'coach_only';

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ 
DECLARE
  v_updated_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_updated_count 
  FROM session_notes 
  WHERE visibility = 'shared';
  
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 18 完成：Session Mode 修復';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '修正內容：';
  RAISE NOTICE '  ✅ 修正 create_session_mode_data() 欄位名稱';
  RAISE NOTICE '  ✅ visibility 預設改為 shared';
  RAISE NOTICE '  ✅ 移除 workout_plans 自動創建';
  RAISE NOTICE '  ✅ 已更新筆記數：%', v_updated_count;
  RAISE NOTICE '';
END $$;
