-- ============================================================================
-- StrengthWise Migration: 17_v3_fcm_devices.sql
-- ============================================================================
-- 來自: 033_user_devices.sql
-- 版本: v3.0-C
-- 日期: 2026-01-05
-- ============================================================================
-- 
-- 包含:
-- 1. user_devices 表（FCM Token 多設備管理）
-- 2. RPC 函數（upsert/remove/get tokens）
-- ============================================================================

-- ============================================================================
-- PART 1: user_devices 表
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.user_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  device_name TEXT,
  last_active TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, fcm_token)
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON public.user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_token ON public.user_devices(fcm_token);

-- RLS
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_manage_own_devices" ON public.user_devices;
CREATE POLICY "users_manage_own_devices" ON public.user_devices
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 欄位註解
COMMENT ON TABLE public.user_devices IS '用戶設備表（FCM Token 管理）';
COMMENT ON COLUMN public.user_devices.fcm_token IS 'Firebase Cloud Messaging Token';
COMMENT ON COLUMN public.user_devices.platform IS '設備平台：android/ios/web';
COMMENT ON COLUMN public.user_devices.device_name IS '設備名稱（選填）';
COMMENT ON COLUMN public.user_devices.last_active IS '最後活躍時間';

-- ============================================================================
-- PART 2: RPC 函數 - upsert_device_token
-- ============================================================================

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

-- ============================================================================
-- PART 3: RPC 函數 - remove_device_token
-- ============================================================================

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
  v_deleted_count INTEGER;
BEGIN
  DELETE FROM public.user_devices
  WHERE user_id = p_user_id AND fcm_token = p_token;
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count > 0;
END;
$$;

COMMENT ON FUNCTION public.remove_device_token IS '移除指定的設備 FCM Token';

-- ============================================================================
-- PART 4: RPC 函數 - remove_invalid_tokens
-- ============================================================================

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

-- ============================================================================
-- PART 5: RPC 函數 - get_user_tokens
-- ============================================================================

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

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 17 完成：FCM 設備管理';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '新增表格：';
  RAISE NOTICE '  ✅ user_devices - 多設備 FCM Token 管理';
  RAISE NOTICE '';
  RAISE NOTICE 'RPC 函數：';
  RAISE NOTICE '  ✅ upsert_device_token() - 添加/更新 Token';
  RAISE NOTICE '  ✅ remove_device_token() - 移除 Token';
  RAISE NOTICE '  ✅ remove_invalid_tokens() - 批量清理無效 Token';
  RAISE NOTICE '  ✅ get_user_tokens() - 獲取用戶所有 Token';
  RAISE NOTICE '';
END $$;
