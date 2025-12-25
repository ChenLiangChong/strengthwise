-- ============================================================================
-- 004_create_booking_tables.sql
-- 建立預約相關表格（教練功能）
-- ============================================================================

-- ============================================================================
-- bookings 表格（預約記錄）
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.bookings (
  -- 主鍵（使用 TEXT 以相容 Firestore ID）
  id TEXT PRIMARY KEY,
  
  -- 用戶關聯
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,  -- 預約者
  coach_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,  -- 教練
  
  -- 預約資訊
  date_time TIMESTAMPTZ NOT NULL,  -- 預約時間
  duration INTEGER DEFAULT 60,     -- 預約時長（分鐘）
  
  -- 預約狀態
  status TEXT DEFAULT 'pending',   -- 'pending', 'confirmed', 'cancelled', 'completed', 'rejected'
  
  -- 取消資訊
  cancelled_by TEXT,               -- 'user' 或 'coach'
  cancelled_at TIMESTAMPTZ,
  cancel_reason TEXT,
  
  -- 確認資訊
  confirmed_at TIMESTAMPTZ,
  
  -- 完成資訊
  completed_at TIMESTAMPTZ,
  
  -- 關聯時段（如果從可用時段預約）
  slot_id TEXT,
  
  -- 備註
  notes TEXT,
  
  -- 時間戳記
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 約束
  CONSTRAINT valid_status CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed', 'rejected'))
);

-- 建立索引
CREATE INDEX idx_bookings_user_id ON public.bookings(user_id);
CREATE INDEX idx_bookings_coach_id ON public.bookings(coach_id);
CREATE INDEX idx_bookings_status ON public.bookings(status);
CREATE INDEX idx_bookings_date_time ON public.bookings(date_time);
CREATE INDEX idx_bookings_user_date ON public.bookings(user_id, date_time);
CREATE INDEX idx_bookings_coach_date ON public.bookings(coach_id, date_time);

-- 建立觸發器：自動更新 updated_at
CREATE TRIGGER update_bookings_updated_at
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- available_slots 表格（可用時段）
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.available_slots (
  -- 主鍵（使用 TEXT 以相容 Firestore ID）
  id TEXT PRIMARY KEY,
  
  -- 教練關聯
  coach_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  
  -- 時段資訊
  date_time TIMESTAMPTZ NOT NULL,  -- 時段開始時間
  duration INTEGER DEFAULT 60,     -- 時段時長（分鐘）
  
  -- 狀態
  is_booked BOOLEAN DEFAULT FALSE,  -- 是否已被預約
  
  -- 時間戳記
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 建立索引
CREATE INDEX idx_available_slots_coach_id ON public.available_slots(coach_id);
CREATE INDEX idx_available_slots_date_time ON public.available_slots(date_time);
CREATE INDEX idx_available_slots_is_booked ON public.available_slots(is_booked);
CREATE INDEX idx_available_slots_coach_date ON public.available_slots(coach_id, date_time);
CREATE INDEX idx_available_slots_coach_available ON public.available_slots(coach_id, is_booked, date_time);

-- 建立觸發器：自動更新 updated_at
CREATE TRIGGER update_available_slots_updated_at
  BEFORE UPDATE ON public.available_slots
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- notifications 表格（通知）
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  -- 主鍵（使用 TEXT 以相容 Firestore ID）
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  
  -- 用戶關聯
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  
  -- 通知類型和內容
  type TEXT NOT NULL,              -- 'new_booking', 'booking_confirmed', 'booking_cancelled', etc.
  message TEXT NOT NULL,
  
  -- 關聯資料
  booking_id TEXT,
  
  -- 狀態
  is_read BOOLEAN DEFAULT FALSE,
  
  -- 時間戳記
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 建立索引
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX idx_notifications_user_unread ON public.notifications(user_id, is_read);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at DESC);

-- ============================================================================
-- booking_history 表格（預約歷史記錄）
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.booking_history (
  -- 主鍵（使用 SERIAL 自動生成）
  id SERIAL PRIMARY KEY,
  
  -- 原始預約 ID
  original_id TEXT NOT NULL,
  
  -- 保存所有預約資訊（JSONB 格式）
  booking_data JSONB NOT NULL,
  
  -- 刪除資訊
  deleted_by UUID,
  deleted_at TIMESTAMPTZ DEFAULT NOW()
);

-- 建立索引
CREATE INDEX idx_booking_history_original_id ON public.booking_history(original_id);
CREATE INDEX idx_booking_history_deleted_at ON public.booking_history(deleted_at DESC);

-- ============================================================================
-- RLS（Row Level Security）策略
-- ============================================================================

-- 啟用 RLS
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.available_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_history ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- bookings 表格 RLS 策略
-- ============================================================================

-- 用戶可以查看自己的預約（作為預約者或教練）
CREATE POLICY "Users can view their bookings"
  ON public.bookings FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id OR auth.uid() = coach_id);

-- 用戶可以創建預約
CREATE POLICY "Users can create bookings"
  ON public.bookings FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 用戶可以更新自己的預約（作為預約者或教練）
CREATE POLICY "Users can update their bookings"
  ON public.bookings FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id OR auth.uid() = coach_id)
  WITH CHECK (auth.uid() = user_id OR auth.uid() = coach_id);

-- 用戶可以刪除自己的預約
CREATE POLICY "Users can delete their bookings"
  ON public.bookings FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id OR auth.uid() = coach_id);

-- ============================================================================
-- available_slots 表格 RLS 策略
-- ============================================================================

-- 任何認證用戶都可以查看可用時段
CREATE POLICY "Authenticated users can view available slots"
  ON public.available_slots FOR SELECT
  TO authenticated
  USING (true);

-- 教練可以創建自己的可用時段
CREATE POLICY "Coaches can create their slots"
  ON public.available_slots FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = coach_id);

-- 教練可以更新自己的可用時段
CREATE POLICY "Coaches can update their slots"
  ON public.available_slots FOR UPDATE
  TO authenticated
  USING (auth.uid() = coach_id)
  WITH CHECK (auth.uid() = coach_id);

-- 教練可以刪除自己的可用時段
CREATE POLICY "Coaches can delete their slots"
  ON public.available_slots FOR DELETE
  TO authenticated
  USING (auth.uid() = coach_id);

-- ============================================================================
-- notifications 表格 RLS 策略
-- ============================================================================

-- 用戶可以查看自己的通知
CREATE POLICY "Users can view their notifications"
  ON public.notifications FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- 系統可以創建通知（這裡允許任何認證用戶，實際應該限制為系統角色）
CREATE POLICY "System can create notifications"
  ON public.notifications FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 用戶可以更新自己的通知（標記已讀）
CREATE POLICY "Users can update their notifications"
  ON public.notifications FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 用戶可以刪除自己的通知
CREATE POLICY "Users can delete their notifications"
  ON public.notifications FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================================
-- booking_history 表格 RLS 策略
-- ============================================================================

-- 只有系統管理員可以查看預約歷史（這裡暫時允許所有認證用戶）
CREATE POLICY "Authenticated users can view booking history"
  ON public.booking_history FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================================
-- 完成
-- ============================================================================

