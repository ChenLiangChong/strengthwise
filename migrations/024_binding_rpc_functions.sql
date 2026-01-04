-- =====================================================
-- Migration 024: 綁定 RPC Functions
-- =====================================================
-- 創建日期：2026-01-04
-- 描述：建立 SECURITY DEFINER 的 RPC 函數，處理綁定邏輯
--       在函數內部繞過 RLS 驗證用戶是否存在
-- =====================================================

-- ============================================================================
-- 1. 邀請碼綁定 RPC Function
-- ============================================================================
-- 學員使用邀請碼綁定教練
-- 優點：在資料庫層面完整驗證，返回友善錯誤訊息

CREATE OR REPLACE FUNCTION bind_coach_by_invite_code(
  p_code TEXT,
  p_trainee_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER  -- 繞過 RLS，可查詢任何用戶
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
    -- 刪除過期邀請碼
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

  -- 5. 驗證教練是否存在（SECURITY DEFINER 可繞過 RLS）
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
      -- 重新激活
      UPDATE coaching_relationships
      SET status = 'active',
          accepted_at = v_now,
          updated_at = v_now
      WHERE id = v_existing.id;
      
      v_relationship_id := v_existing.id;
    ELSE
      -- pending 或其他狀態，更新為 active
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

-- ============================================================================
-- 2. QR Code 綁定 RPC Function
-- ============================================================================
-- 掃描 QR Code 後綁定（雙向：教練綁學員 / 學員綁教練）

CREATE OR REPLACE FUNCTION bind_by_qr_code(
  p_scanned_user_id UUID,
  p_my_user_id UUID,
  p_my_role TEXT  -- 'coach' 或 'client'
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
      -- 重新激活
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
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 024 完成：綁定 RPC Functions';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '新增函數：';
  RAISE NOTICE '  ✅ bind_coach_by_invite_code(code, trainee_id) - 邀請碼綁定';
  RAISE NOTICE '  ✅ bind_by_qr_code(scanned_user_id, my_user_id, my_role) - QR 碼綁定';
  RAISE NOTICE '';
  RAISE NOTICE '優點：';
  RAISE NOTICE '  - SECURITY DEFINER 繞過 RLS，可驗證對方用戶';
  RAISE NOTICE '  - 完整錯誤處理，返回友善訊息';
  RAISE NOTICE '  - 一次 RPC 呼叫完成所有邏輯';
  RAISE NOTICE '';
END $$;

