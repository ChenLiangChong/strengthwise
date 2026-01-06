-- =============================================
-- Migration 028: 教練預約設定表（完整版）
-- 版本：v3.0
-- 日期：2026-01-05
-- 功能：儲存教練的預約參數（緩衝、限制、顆粒度）
-- 說明：欄位都有 DEFAULT，目前只用 min_booking_notice，其他為未來預留
-- =============================================

-- 教練預約設定表（1:1 關聯至 coaches）
CREATE TABLE IF NOT EXISTS public.coach_booking_settings (
  coach_id UUID PRIMARY KEY REFERENCES public.coaches(id) ON DELETE CASCADE,
  
  -- ========== 緩衝機制（未來擴展）==========
  buffer_before INTERVAL DEFAULT '00:15:00'::interval,   -- 課前準備時間（預設 15 分鐘）
  buffer_after INTERVAL DEFAULT '00:15:00'::interval,    -- 課後休息時間（預設 15 分鐘）
  
  -- ========== 預約限制（目前使用）==========
  min_booking_notice INTERVAL NOT NULL DEFAULT '02:00:00'::interval,  -- 最短提前預約時間（預設 2 小時）
  max_booking_window INTERVAL DEFAULT '60 days'::interval,            -- 最遠可預約天數（預設 60 天）
  
  -- ========== 顆粒度與容量（未來擴展）==========
  slot_increment INTERVAL DEFAULT '00:30:00'::interval,               -- 時段步進單位（預設 30 分鐘）
  default_session_duration INTERVAL DEFAULT '01:00:00'::interval,     -- 預設課程長度（預設 1 小時）
  max_sessions_per_day INTEGER DEFAULT 8,                             -- 每日最大課程數
  
  -- ========== 時區 ==========
  timezone TEXT NOT NULL DEFAULT 'Asia/Taipei',
  
  -- ========== 時間戳 ==========
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 欄位註解
COMMENT ON TABLE public.coach_booking_settings IS '教練預約設定';
COMMENT ON COLUMN public.coach_booking_settings.buffer_before IS '課前準備時間（未來擴展）';
COMMENT ON COLUMN public.coach_booking_settings.buffer_after IS '課後休息時間（未來擴展）';
COMMENT ON COLUMN public.coach_booking_settings.min_booking_notice IS '最短提前預約時間（目前使用）';
COMMENT ON COLUMN public.coach_booking_settings.max_booking_window IS '最遠可預約天數';
COMMENT ON COLUMN public.coach_booking_settings.slot_increment IS '時段步進單位（未來擴展）';
COMMENT ON COLUMN public.coach_booking_settings.default_session_duration IS '預設課程長度（未來擴展）';
COMMENT ON COLUMN public.coach_booking_settings.max_sessions_per_day IS '每日最大課程數';
COMMENT ON COLUMN public.coach_booking_settings.timezone IS '教練時區（IANA 格式）';

-- RLS 政策
ALTER TABLE public.coach_booking_settings ENABLE ROW LEVEL SECURITY;

-- 教練可以管理自己的設定
CREATE POLICY "Coaches can manage own settings"
  ON public.coach_booking_settings
  FOR ALL
  USING (auth.uid() = coach_id)
  WITH CHECK (auth.uid() = coach_id);

-- 學員可以查看教練的設定（用於過濾可預約時段）
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

-- updated_at 觸發器
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

-- =============================================
-- 完成訊息
-- =============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 028 完成：coach_booking_settings 表已創建（完整版）';
  RAISE NOTICE '   目前使用：min_booking_notice';
  RAISE NOTICE '   未來擴展：buffer_before/after, slot_increment, max_sessions_per_day';
END $$;
