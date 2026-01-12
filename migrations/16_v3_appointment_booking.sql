-- ============================================================================
-- StrengthWise Migration: 16_v3_appointment_booking.sql
-- ============================================================================
-- 合併自: 028_coach_booking_settings.sql, 029_add_rejected_status.sql, 
--        030_daily_readiness.sql, 031_session_auto_create.sql
-- 版本: v3.0
-- 日期: 2026-01-05
-- ============================================================================
-- 
-- 包含:
-- 1. coach_booking_settings 表（教練預約參數）
-- 2. appointment_status 新增 rejected 狀態
-- 3. daily_readiness 表（課前問卷）
-- 4. Session Mode 自動創建觸發器
-- ============================================================================

-- ============================================================================
-- PART 1: 教練預約設定表
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.coach_booking_settings (
  coach_id UUID PRIMARY KEY REFERENCES public.coaches(id) ON DELETE CASCADE,
  
  -- ========== 緩衝機制（預留） ==========
  buffer_before INTERVAL DEFAULT '00:15:00'::interval,
  buffer_after INTERVAL DEFAULT '00:15:00'::interval,
  
  -- ========== 預約限制 ==========
  min_booking_notice INTERVAL NOT NULL DEFAULT '02:00:00'::interval,
  max_booking_window INTERVAL DEFAULT '60 days'::interval,
  
  -- ========== 顆粒度與容量（預留） ==========
  slot_increment INTERVAL DEFAULT '00:30:00'::interval,
  default_session_duration INTERVAL DEFAULT '01:00:00'::interval,
  max_sessions_per_day INTEGER DEFAULT 8,
  
  -- ========== 時區 ==========
  timezone TEXT NOT NULL DEFAULT 'Asia/Taipei',
  
  -- ========== 時間戳 ==========
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 欄位註解
COMMENT ON TABLE public.coach_booking_settings IS '教練預約設定';
COMMENT ON COLUMN public.coach_booking_settings.buffer_before IS '課前準備時間（預留）';
COMMENT ON COLUMN public.coach_booking_settings.buffer_after IS '課後休息時間（預留）';
COMMENT ON COLUMN public.coach_booking_settings.min_booking_notice IS '最短提前預約時間';
COMMENT ON COLUMN public.coach_booking_settings.max_booking_window IS '最遠可預約天數';
COMMENT ON COLUMN public.coach_booking_settings.slot_increment IS '時段步進單位（預留）';
COMMENT ON COLUMN public.coach_booking_settings.default_session_duration IS '預設課程長度（預留）';
COMMENT ON COLUMN public.coach_booking_settings.max_sessions_per_day IS '每日最大課程數';
COMMENT ON COLUMN public.coach_booking_settings.timezone IS '教練時區（IANA 格式）';

-- RLS 政策
ALTER TABLE public.coach_booking_settings ENABLE ROW LEVEL SECURITY;

-- 教練可以管理自己的設定
DROP POLICY IF EXISTS "Coaches can manage own settings" ON public.coach_booking_settings;
CREATE POLICY "Coaches can manage own settings"
  ON public.coach_booking_settings
  FOR ALL
  USING (auth.uid() = coach_id)
  WITH CHECK (auth.uid() = coach_id);

-- 學員可以查看教練的設定
DROP POLICY IF EXISTS "Students can view coach settings" ON public.coach_booking_settings;
CREATE POLICY "Students can view coach settings"
  ON public.coach_booking_settings
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM coaching_relationships
      WHERE client_id = auth.uid() 
        AND coach_id = coach_booking_settings.coach_id
        AND status = 'active'
    )
  );

-- 索引
CREATE INDEX IF NOT EXISTS idx_booking_settings_coach 
  ON coach_booking_settings(coach_id);

-- 觸發器
CREATE OR REPLACE FUNCTION update_coach_booking_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_coach_booking_settings_updated_at ON coach_booking_settings;
CREATE TRIGGER trg_coach_booking_settings_updated_at
  BEFORE UPDATE ON coach_booking_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_coach_booking_settings_updated_at();

-- ============================================================================
-- PART 2: 新增 rejected 狀態
-- ============================================================================
-- 
-- 狀態說明：
-- - requested：學員發起預約請求
-- - confirmed：教練確認預約
-- - rejected：教練拒絕預約請求 ⭐ 新增
-- - completed：上課結束
-- - cancelled：確認後取消

ALTER TYPE appointment_status ADD VALUE IF NOT EXISTS 'rejected';

COMMENT ON COLUMN public.appointments.status IS 
  '預約狀態：requested、confirmed、rejected、completed、cancelled';

-- ============================================================================
-- PART 3: 每日準備度問卷表
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.daily_readiness (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- 關聯
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  session_note_id UUID REFERENCES public.session_notes(id) ON DELETE SET NULL,
  
  -- 日期
  log_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- 量化總分
  readiness_score INTEGER CHECK (readiness_score BETWEEN 0 AND 100),
  
  -- 紅綠燈狀態
  traffic_light TEXT CHECK (traffic_light IN ('RED', 'AMBER', 'GREEN')),
  
  -- 詳細指標（JSONB）
  metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  
  -- 時間戳
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  -- 約束
  UNIQUE(user_id, appointment_id)
);

-- 欄位註解
COMMENT ON TABLE public.daily_readiness IS '學員每日準備度問卷（課前狀態評估）';
COMMENT ON COLUMN public.daily_readiness.readiness_score IS '準備度總分 0-100';
COMMENT ON COLUMN public.daily_readiness.traffic_light IS '紅綠燈狀態：RED/AMBER/GREEN';
COMMENT ON COLUMN public.daily_readiness.metrics IS '詳細指標（睡眠、痠痛、壓力、能量）';

-- RLS 政策
ALTER TABLE public.daily_readiness ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own readiness" ON public.daily_readiness;
CREATE POLICY "Users can manage own readiness"
  ON public.daily_readiness
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Coaches can view students readiness" ON public.daily_readiness;
CREATE POLICY "Coaches can view students readiness"
  ON public.daily_readiness
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM coaching_relationships
      WHERE coach_id = auth.uid() 
        AND client_id = daily_readiness.user_id
        AND status = 'active'
    )
  );

DROP POLICY IF EXISTS "Coaches can insert for students" ON public.daily_readiness;
CREATE POLICY "Coaches can insert for students"
  ON public.daily_readiness
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM coaching_relationships
      WHERE coach_id = auth.uid() 
        AND client_id = daily_readiness.user_id
        AND status = 'active'
    )
  );

-- 索引
CREATE INDEX IF NOT EXISTS idx_readiness_user_date 
  ON daily_readiness(user_id, log_date DESC);

CREATE INDEX IF NOT EXISTS idx_readiness_appointment 
  ON daily_readiness(appointment_id);

CREATE INDEX IF NOT EXISTS idx_readiness_metrics 
  ON daily_readiness USING gin (metrics);

-- 觸發器
CREATE OR REPLACE FUNCTION update_daily_readiness_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_daily_readiness_updated_at ON daily_readiness;
CREATE TRIGGER trg_daily_readiness_updated_at
  BEFORE UPDATE ON daily_readiness
  FOR EACH ROW
  EXECUTE FUNCTION update_daily_readiness_updated_at();

-- ============================================================================
-- PART 4: Session Mode 自動創建觸發器
-- ============================================================================

-- 為 session_notes 添加 appointment_id 欄位
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'session_notes' AND column_name = 'appointment_id'
  ) THEN
    ALTER TABLE session_notes 
    ADD COLUMN appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL;
    
    COMMENT ON COLUMN session_notes.appointment_id IS '關聯的預約 ID（Session Mode）';
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_session_notes_appointment 
  ON session_notes(appointment_id) WHERE appointment_id IS NOT NULL;

-- 為 workout_plans 添加 appointment_id 欄位
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'workout_plans' AND column_name = 'appointment_id'
  ) THEN
    ALTER TABLE workout_plans 
    ADD COLUMN appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL;
    
    COMMENT ON COLUMN workout_plans.appointment_id IS '關聯的預約 ID（Session Mode）';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_workout_plans_appointment 
  ON workout_plans(appointment_id) WHERE appointment_id IS NOT NULL;

-- 自動創建 Session Mode 資料的函數
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
    
    v_start_time := lower(NEW.time_range);
    v_end_time := upper(NEW.time_range);
    
    -- 1. 創建 session_notes
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
    
    -- 3. 創建 workout_plans
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
    
    RAISE NOTICE '✅ Session Mode 資料已創建 - appointment: %, note: %, readiness: %, workout: %',
      NEW.id, v_session_note_id, v_readiness_id, v_workout_plan_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_create_session_mode_data ON appointments;
CREATE TRIGGER trg_create_session_mode_data
  AFTER INSERT OR UPDATE OF status ON appointments
  FOR EACH ROW
  EXECUTE FUNCTION create_session_mode_data();

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 16 完成：預約與 Session Mode';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '新增表格：';
  RAISE NOTICE '  ✅ coach_booking_settings - 教練預約設定';
  RAISE NOTICE '  ✅ daily_readiness - 課前問卷';
  RAISE NOTICE '';
  RAISE NOTICE '新增狀態：';
  RAISE NOTICE '  ✅ appointment_status.rejected';
  RAISE NOTICE '';
  RAISE NOTICE '新增欄位：';
  RAISE NOTICE '  ✅ session_notes.appointment_id';
  RAISE NOTICE '  ✅ workout_plans.appointment_id';
  RAISE NOTICE '';
  RAISE NOTICE '觸發器：';
  RAISE NOTICE '  ✅ 預約確認後自動創建 session_notes, daily_readiness, workout_plans';
  RAISE NOTICE '';
END $$;
