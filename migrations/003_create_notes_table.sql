-- ============================================================================
-- 003_create_notes_table.sql
-- 建立筆記表格
-- ============================================================================

-- ============================================================================
-- notes 表格（用戶筆記）
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.notes (
  -- 主鍵（使用 TEXT 以相容 Firestore ID）
  id TEXT PRIMARY KEY,
  
  -- 用戶關聯
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  
  -- 筆記內容
  title TEXT NOT NULL,
  text_content TEXT,
  drawing_points JSONB DEFAULT '[]'::jsonb,  -- 繪圖點（JSON 格式）
  
  -- 關聯到訓練或預約（可選）
  workout_plan_id TEXT,
  appointment_id TEXT,
  
  -- 時間戳記
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 建立索引
CREATE INDEX idx_notes_user_id ON public.notes(user_id);
CREATE INDEX idx_notes_workout_plan_id ON public.notes(workout_plan_id);
CREATE INDEX idx_notes_appointment_id ON public.notes(appointment_id);
CREATE INDEX idx_notes_updated_at ON public.notes(updated_at DESC);

-- 建立觸發器：自動更新 updated_at
CREATE TRIGGER update_notes_updated_at
  BEFORE UPDATE ON public.notes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- RLS（Row Level Security）策略
-- ============================================================================

-- 啟用 RLS
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

-- 用戶可以讀取自己的筆記
CREATE POLICY "Users can view their notes"
  ON public.notes FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- 用戶可以建立筆記
CREATE POLICY "Users can create notes"
  ON public.notes FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 用戶可以更新自己的筆記
CREATE POLICY "Users can update their notes"
  ON public.notes FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 用戶可以刪除自己的筆記
CREATE POLICY "Users can delete their notes"
  ON public.notes FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================================
-- 完成
-- ============================================================================

