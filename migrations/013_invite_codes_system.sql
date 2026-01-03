-- ============================================================================
-- 一次性邀請碼系統（簡化版）
-- ============================================================================
-- 用途：遠端綁定教練與學員（當無法使用 QR Code 時）
-- 版本：v2.2+
-- 創建日期：2025-01-03
-- 
-- 設計原則：
-- - 生成即用，用完即刪
-- - 5 分鐘過期
-- - 無需歷史記錄和管理介面
-- ============================================================================

-- 創建邀請碼表
CREATE TABLE IF NOT EXISTS public.invite_codes (
  -- 邀請碼（6 位大寫字母+數字，如：A1B2C3）- 作為主鍵
  code TEXT PRIMARY KEY,
  
  -- 邀請者資訊（只有教練能生成邀請碼）
  coach_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  
  -- 時間戳記
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '5 minutes')
);

-- ============================================================================
-- 索引優化
-- ============================================================================

-- 過期邀請碼清理（唯一需要的索引）
CREATE INDEX idx_invite_codes_expires ON public.invite_codes(expires_at);

-- ============================================================================
-- RLS 策略
-- ============================================================================

-- 啟用 RLS
ALTER TABLE public.invite_codes ENABLE ROW LEVEL SECURITY;

-- 教練可以創建邀請碼
CREATE POLICY "Coaches can create invite codes"
  ON public.invite_codes FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = coach_id 
    AND EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() 
      AND is_coach = true
    )
  );

-- 任何登入用戶都可以查詢有效的邀請碼（用於驗證）
CREATE POLICY "Users can query valid invite codes"
  ON public.invite_codes FOR SELECT
  TO authenticated
  USING (expires_at > NOW());

-- 任何登入用戶都可以刪除邀請碼（使用後自動刪除）
CREATE POLICY "Users can delete invite codes"
  ON public.invite_codes FOR DELETE
  TO authenticated
  USING (expires_at > NOW());

-- ============================================================================
-- 自動清理過期邀請碼
-- ============================================================================

-- 創建函數：刪除過期的邀請碼
CREATE OR REPLACE FUNCTION delete_expired_invite_codes()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.invite_codes
  WHERE expires_at < NOW();
END;
$$;

-- 註解：實際部署時可以設定定時任務（如 pg_cron）每 5 分鐘執行一次
-- SELECT cron.schedule('cleanup-invite-codes', '*/5 * * * *', 'SELECT delete_expired_invite_codes();');

-- ============================================================================
-- 註解
-- ============================================================================

COMMENT ON TABLE public.invite_codes IS '一次性邀請碼系統（教練邀請學員遠端綁定，生成即用，用完即刪，5 分鐘過期）';
COMMENT ON COLUMN public.invite_codes.code IS '6 位邀請碼（大寫字母+數字，如：A1B2C3）';
COMMENT ON COLUMN public.invite_codes.coach_id IS '教練 ID（只有教練能生成邀請碼）';
COMMENT ON COLUMN public.invite_codes.expires_at IS '過期時間（預設 5 分鐘）';

