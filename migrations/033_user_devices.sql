-- ============================================================
-- Migration 033: 用戶設備表（FCM Token 管理）⭐ v3.0-C
-- ============================================================
-- 用途：獨立的設備表，支援多設備管理和 Token 生命週期追蹤
-- 替代：032 的 users.fcm_tokens 欄位（更完整的方案）
-- 執行環境：Supabase SQL Editor
-- ============================================================

-- 1. 創建 user_devices 表
CREATE TABLE IF NOT EXISTS public.user_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  device_name TEXT,                    -- 設備名稱（可選）
  last_active TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, fcm_token)           -- 同一用戶同一 Token 只能有一筆
);

-- 2. 創建索引
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON public.user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_token ON public.user_devices(fcm_token);

-- 3. 啟用 RLS
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

-- 4. RLS 策略：用戶只能管理自己的設備
CREATE POLICY "users_manage_own_devices" ON public.user_devices
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 5. 創建 RPC 函數：安全地 upsert FCM Token
CREATE OR REPLACE FUNCTION public.upsert_device_token(
  p_user_id UUID,
  p_token TEXT,
  p_platform TEXT DEFAULT 'android',
  p_device_name TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_device_id UUID;
BEGIN
  -- 嘗試更新已存在的 token
  UPDATE public.user_devices
  SET 
    last_active = NOW(),
    updated_at = NOW(),
    device_name = COALESCE(p_device_name, device_name),
    platform = p_platform
  WHERE user_id = p_user_id AND fcm_token = p_token
  RETURNING id INTO v_device_id;
  
  -- 如果不存在，插入新記錄
  IF v_device_id IS NULL THEN
    INSERT INTO public.user_devices (user_id, fcm_token, platform, device_name)
    VALUES (p_user_id, p_token, p_platform, p_device_name)
    RETURNING id INTO v_device_id;
  END IF;
  
  RETURN v_device_id;
END;
$$;

COMMENT ON FUNCTION public.upsert_device_token IS '安全地添加或更新設備 FCM Token';

-- 6. 創建 RPC 函數：移除 FCM Token
CREATE OR REPLACE FUNCTION public.remove_device_token(
  p_user_id UUID,
  p_token TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted_count INTEGER;  -- 修正：ROW_COUNT 返回 INTEGER
BEGIN
  DELETE FROM public.user_devices
  WHERE user_id = p_user_id AND fcm_token = p_token;
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count > 0;
END;
$$;

COMMENT ON FUNCTION public.remove_device_token IS '移除指定的設備 FCM Token';

-- 7. 創建 RPC 函數：清理無效 Token（供 Edge Function 使用）
CREATE OR REPLACE FUNCTION public.remove_invalid_tokens(
  p_tokens TEXT[]
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  DELETE FROM public.user_devices
  WHERE fcm_token = ANY(p_tokens);
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.remove_invalid_tokens IS '批量清理無效的 FCM Token（Edge Function 專用）';

-- 8. 創建 RPC 函數：獲取用戶所有設備的 Token
CREATE OR REPLACE FUNCTION public.get_user_tokens(p_user_id UUID)
RETURNS TEXT[]
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(array_agg(fcm_token), ARRAY[]::TEXT[])
  FROM public.user_devices
  WHERE user_id = p_user_id;
$$;

COMMENT ON FUNCTION public.get_user_tokens IS '獲取用戶所有設備的 FCM Token';

-- ============================================================
-- 驗證
-- ============================================================

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'user_devices'
  ) THEN
    RAISE NOTICE '✅ user_devices 表已創建';
  ELSE
    RAISE EXCEPTION '❌ user_devices 表創建失敗';
  END IF;
END $$;

-- 驗證函數
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'upsert_device_token'
  ) THEN
    RAISE NOTICE '✅ upsert_device_token 函數已創建';
  ELSE
    RAISE EXCEPTION '❌ upsert_device_token 函數創建失敗';
  END IF;
END $$;

