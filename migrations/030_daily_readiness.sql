-- =============================================
-- Migration 030: 每日準備度問卷表
-- 版本：v3.0
-- 日期：2026-01-05
-- 功能：課前問卷（睡眠品質、時長、痠痛、壓力、能量）
-- =============================================

-- 每日準備度表
CREATE TABLE IF NOT EXISTS public.daily_readiness (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- 關聯
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  session_note_id UUID REFERENCES public.session_notes(id) ON DELETE SET NULL,
  
  -- 日期（記錄用，每個預約一筆問卷）
  log_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- 量化總分（0-100）
  readiness_score INTEGER CHECK (readiness_score BETWEEN 0 AND 100),
  
  -- 紅綠燈狀態
  traffic_light TEXT CHECK (traffic_light IN ('RED', 'AMBER', 'GREEN')),
  
  -- 詳細指標（JSONB 彈性儲存）
  -- 結構範例：
  -- {
  --   "sleep_quality": 4,      -- 1-5
  --   "sleep_hours": 7,        -- 小時數
  --   "soreness": 3,           -- 1-5（5=無痠痛）
  --   "stress": 4,             -- 1-5（5=無壓力）
  --   "energy_level": 5,       -- 1-5
  --   "notes": "昨天有慢跑"
  -- }
  metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  
  -- 時間戳
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  -- 約束：同一用戶同一預約只能一筆
  UNIQUE(user_id, appointment_id)
);

-- 欄位註解
COMMENT ON TABLE public.daily_readiness IS '學員每日準備度問卷（課前狀態評估）';
COMMENT ON COLUMN public.daily_readiness.readiness_score IS '準備度總分 0-100';
COMMENT ON COLUMN public.daily_readiness.traffic_light IS '紅綠燈狀態：RED=警示、AMBER=注意、GREEN=正常';
COMMENT ON COLUMN public.daily_readiness.metrics IS '詳細指標 JSONB（睡眠、痠痛、壓力、能量）';

-- RLS 政策
ALTER TABLE public.daily_readiness ENABLE ROW LEVEL SECURITY;

-- 學員可以管理自己的問卷
CREATE POLICY "Users can manage own readiness"
  ON public.daily_readiness
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 教練可以查看自己學員的問卷
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

-- 教練可以幫學員填寫問卷
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

-- updated_at 觸發器
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

-- =============================================
-- 完成訊息
-- =============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 030 完成：daily_readiness 表已創建';
  RAISE NOTICE '   學員可填寫課前問卷，教練可查看紅綠燈狀態';
END $$;

