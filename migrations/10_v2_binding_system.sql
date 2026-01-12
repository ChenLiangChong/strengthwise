-- ============================================================================
-- StrengthWise Migration: 10_v2_binding_system.sql
-- ============================================================================
-- 合併自: 011_fix_qrcode_binding_rls.sql, 013_invite_codes_system.sql, 024_binding_rpc_functions.sql
-- 版本: v2.2+
-- 日期: 2026-01-03 ~ 2026-01-04
-- ============================================================================
-- 
-- 包含:
-- 1. QR Code 綁定 RLS 策略修復
-- 2. 一次性邀請碼系統
-- 3. 綁定 RPC Functions (SECURITY DEFINER)
-- ============================================================================

-- ============================================================================
-- PART 1: QR Code 綁定 RLS 策略修復 (來自 011)
-- ============================================================================
-- 
-- 問題：當前 coaching_relationships 表只允許教練創建關係
-- 解決：新增學員也可以創建關係（用於 QR Code 雙向綁定）

DROP POLICY IF EXISTS "Clients can create coach relationships" ON public.coaching_relationships;

CREATE POLICY "Clients can create coach relationships"
  ON public.coaching_relationships FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = client_id
  );

-- ============================================================================
-- PART 2: 一次性邀請碼系統 (來自 013)
-- ============================================================================
-- 
-- 用途：遠端綁定教練與學員（當無法使用 QR Code 時）
-- 設計原則：生成即用，用完即刪，5 分鐘過期

CREATE TABLE IF NOT EXISTS public.invite_codes (
  code TEXT PRIMARY KEY,
  coach_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '5 minutes')
);

CREATE INDEX IF NOT EXISTS idx_invite_codes_expires ON public.invite_codes(expires_at);

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

-- 任何登入用戶都可以查詢有效的邀請碼
CREATE POLICY "Users can query valid invite codes"
  ON public.invite_codes FOR SELECT
  TO authenticated
  USING (expires_at > NOW());

-- 任何登入用戶都可以刪除邀請碼
CREATE POLICY "Users can delete invite codes"
  ON public.invite_codes FOR DELETE
  TO authenticated
  USING (expires_at > NOW());

-- 自動清理過期邀請碼的函數
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

COMMENT ON TABLE public.invite_codes IS '一次性邀請碼系統（教練邀請學員遠端綁定，生成即用，用完即刪，5 分鐘過期）';
COMMENT ON COLUMN public.invite_codes.code IS '6 位邀請碼（大寫字母+數字，如：A1B2C3）';
COMMENT ON COLUMN public.invite_codes.coach_id IS '教練 ID（只有教練能生成邀請碼）';
COMMENT ON COLUMN public.invite_codes.expires_at IS '過期時間（預設 5 分鐘）';

-- ============================================================================
-- PART 3: 綁定 RPC Functions (來自 024)
-- ============================================================================
-- 
-- 使用 SECURITY DEFINER 繞過 RLS 驗證用戶是否存在

-- ----------------------------------------------------------------------------
-- 3.1 邀請碼綁定 RPC Function
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION bind_coach_by_invite_code(
  p_code TEXT,
  p_trainee_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite_code RECORD;
  v_coach RECORD;
  v_existing RECORD;
  v_relationship_id UUID;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  -- 1. 驗證邀請碼格式
  IF LENGTH(TRIM(UPPER(p_code))) != 6 THEN
    RETURN json_build_object(
      'success', false,
      'error', '邀請碼格式錯誤（應為 6 位字母+數字）'
    );
  END IF;

  -- 2. 查詢邀請碼
  SELECT * INTO v_invite_code
  FROM invite_codes
  WHERE code = UPPER(TRIM(p_code));

  IF v_invite_code IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', '邀請碼不存在或已失效'
    );
  END IF;

  -- 3. 檢查是否過期
  IF v_invite_code.expires_at < v_now THEN
    DELETE FROM invite_codes WHERE code = UPPER(TRIM(p_code));
    RETURN json_build_object(
      'success', false,
      'error', '邀請碼已過期'
    );
  END IF;

  -- 4. 檢查是否自己邀請自己
  IF v_invite_code.coach_id = p_trainee_id THEN
    RETURN json_build_object(
      'success', false,
      'error', '無法使用自己的邀請碼'
    );
  END IF;

  -- 5. 驗證教練是否存在
  SELECT id, email, display_name, is_coach INTO v_coach
  FROM users
  WHERE id = v_invite_code.coach_id;

  IF v_coach IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', '教練帳號不存在，請聯繫教練確認'
    );
  END IF;

  -- 6. 檢查教練是否真的是教練
  IF v_coach.is_coach IS NOT TRUE THEN
    RETURN json_build_object(
      'success', false,
      'error', '該用戶不是教練身份'
    );
  END IF;

  -- 7. 檢查是否已存在關係
  SELECT id, status INTO v_existing
  FROM coaching_relationships
  WHERE coach_id = v_invite_code.coach_id
    AND client_id = p_trainee_id;

  IF v_existing IS NOT NULL THEN
    IF v_existing.status = 'active' THEN
      RETURN json_build_object(
        'success', false,
        'error', '你已經是這位教練的學員了'
      );
    ELSIF v_existing.status = 'archived' THEN
      UPDATE coaching_relationships
      SET status = 'active',
          accepted_at = v_now,
          updated_at = v_now
      WHERE id = v_existing.id;
      
      v_relationship_id := v_existing.id;
    ELSE
      UPDATE coaching_relationships
      SET status = 'active',
          accepted_at = v_now,
          updated_at = v_now
      WHERE id = v_existing.id;
      
      v_relationship_id := v_existing.id;
    END IF;
  ELSE
    -- 8. 創建新關係
    INSERT INTO coaching_relationships (
      coach_id,
      client_id,
      status,
      invited_at,
      accepted_at,
      created_at,
      updated_at
    ) VALUES (
      v_invite_code.coach_id,
      p_trainee_id,
      'active',
      v_now,
      v_now,
      v_now,
      v_now
    )
    RETURNING id INTO v_relationship_id;
  END IF;

  -- 9. 刪除已使用的邀請碼
  DELETE FROM invite_codes WHERE code = UPPER(TRIM(p_code));

  -- 10. 返回成功結果
  RETURN json_build_object(
    'success', true,
    'relationship_id', v_relationship_id,
    'coach_id', v_invite_code.coach_id,
    'coach_name', COALESCE(v_coach.display_name, v_coach.email)
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 3.2 QR Code 綁定 RPC Function
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION bind_by_qr_code(
  p_scanned_user_id UUID,
  p_my_user_id UUID,
  p_my_role TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_scanned_user RECORD;
  v_existing RECORD;
  v_relationship_id UUID;
  v_coach_id UUID;
  v_client_id UUID;
  v_now TIMESTAMPTZ := NOW();
BEGIN
  -- 1. 檢查是否掃描自己
  IF p_scanned_user_id = p_my_user_id THEN
    RETURN json_build_object(
      'success', false,
      'error', '不能綁定自己'
    );
  END IF;

  -- 2. 驗證角色參數
  IF p_my_role NOT IN ('coach', 'client') THEN
    RETURN json_build_object(
      'success', false,
      'error', '角色參數錯誤'
    );
  END IF;

  -- 3. 驗證對方用戶是否存在
  SELECT id, email, display_name, is_coach, is_student INTO v_scanned_user
  FROM users
  WHERE id = p_scanned_user_id;

  IF v_scanned_user IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', '對方用戶不存在或尚未完成註冊'
    );
  END IF;

  -- 4. 確定教練和學員 ID
  IF p_my_role = 'coach' THEN
    v_coach_id := p_my_user_id;
    v_client_id := p_scanned_user_id;
  ELSE
    v_coach_id := p_scanned_user_id;
    v_client_id := p_my_user_id;
  END IF;

  -- 5. 檢查是否已存在關係
  SELECT id, status INTO v_existing
  FROM coaching_relationships
  WHERE coach_id = v_coach_id
    AND client_id = v_client_id;

  IF v_existing IS NOT NULL THEN
    IF v_existing.status = 'active' THEN
      RETURN json_build_object(
        'success', false,
        'error', '已經存在綁定關係'
      );
    ELSIF v_existing.status = 'archived' THEN
      UPDATE coaching_relationships
      SET status = 'active',
          accepted_at = v_now,
          updated_at = v_now
      WHERE id = v_existing.id;
      
      v_relationship_id := v_existing.id;
    ELSE
      UPDATE coaching_relationships
      SET status = 'active',
          accepted_at = v_now,
          updated_at = v_now
      WHERE id = v_existing.id;
      
      v_relationship_id := v_existing.id;
    END IF;
  ELSE
    -- 6. 創建新關係
    INSERT INTO coaching_relationships (
      coach_id,
      client_id,
      status,
      invited_at,
      accepted_at,
      created_at,
      updated_at
    ) VALUES (
      v_coach_id,
      v_client_id,
      'active',
      v_now,
      v_now,
      v_now,
      v_now
    )
    RETURNING id INTO v_relationship_id;
  END IF;

  -- 7. 返回成功結果
  RETURN json_build_object(
    'success', true,
    'relationship_id', v_relationship_id,
    'coach_id', v_coach_id,
    'client_id', v_client_id,
    'scanned_user_name', COALESCE(v_scanned_user.display_name, v_scanned_user.email)
  );
END;
$$;

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 10 完成：綁定系統';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '新增功能：';
  RAISE NOTICE '  ✅ QR Code 雙向綁定 RLS 策略';
  RAISE NOTICE '  ✅ 一次性邀請碼系統（5 分鐘過期）';
  RAISE NOTICE '  ✅ bind_coach_by_invite_code() - 邀請碼綁定';
  RAISE NOTICE '  ✅ bind_by_qr_code() - QR 碼綁定';
  RAISE NOTICE '';
  RAISE NOTICE '優點：';
  RAISE NOTICE '  - SECURITY DEFINER 繞過 RLS，可驗證對方用戶';
  RAISE NOTICE '  - 完整錯誤處理，返回友善訊息';
  RAISE NOTICE '  - 一次 RPC 呼叫完成所有邏輯';
  RAISE NOTICE '';
END $$;
