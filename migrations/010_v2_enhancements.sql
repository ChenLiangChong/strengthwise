-- ============================================================================
-- Migration: 010_v2_enhancements.sql
-- 描述: v2.2/v2.3 系列功能增強（合併版本）
-- 日期: 2026-01-02
-- 版本: v2.3
-- ============================================================================

-- 說明：
-- 此檔案合併了以下功能增強：
-- 1. 移除 workout_templates.training_time 欄位
-- 2. 新增 users.gender_visible 欄位
-- 3. 修復 custom_exercises RLS 策略
-- 4. 修復 delete_user_account() 函數

BEGIN;

-- ============================================================================
-- 1. 移除 workout_templates.training_time 欄位
-- ============================================================================

-- 檢查並刪除欄位
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'workout_templates'
      AND column_name = 'training_time'
  ) THEN
    ALTER TABLE public.workout_templates DROP COLUMN training_time;
    RAISE NOTICE '✅ 已刪除 workout_templates.training_time 欄位';
  ELSE
    RAISE NOTICE 'ℹ️ training_time 欄位不存在，跳過';
  END IF;
END $$;

-- ============================================================================
-- 2. 新增 users.gender_visible 欄位
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'users' 
    AND column_name = 'gender_visible'
  ) THEN
    ALTER TABLE public.users 
    ADD COLUMN gender_visible BOOLEAN NOT NULL DEFAULT true;
    
    RAISE NOTICE '✅ 已新增 gender_visible 欄位到 users 表格';
  ELSE
    RAISE NOTICE 'ℹ️  gender_visible 欄位已存在，跳過';
  END IF;
END $$;

-- 確保現有用戶的 gender_visible 為 true
UPDATE public.users
SET gender_visible = true
WHERE gender_visible IS NULL;

COMMENT ON COLUMN public.users.gender_visible IS '性別是否對其他人可見（預設：true）';

-- ============================================================================
-- 3. 修復 custom_exercises RLS 策略
-- ============================================================================

-- 刪除舊策略
DROP POLICY IF EXISTS "Users can view their custom exercises" ON public.custom_exercises;
DROP POLICY IF EXISTS "Users can create custom exercises" ON public.custom_exercises;
DROP POLICY IF EXISTS "Users can update their custom exercises" ON public.custom_exercises;
DROP POLICY IF EXISTS "Users can delete their custom exercises" ON public.custom_exercises;

-- 重新創建策略（允許 user_id 為 NULL 的記錄可見）
CREATE POLICY "Users can view custom exercises"
  ON public.custom_exercises FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id OR user_id IS NULL
  );

CREATE POLICY "Users can create custom exercises"
  ON public.custom_exercises FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their custom exercises"
  ON public.custom_exercises FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their custom exercises"
  ON public.custom_exercises FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================================
-- 4. 修復 delete_user_account() 函數
-- ============================================================================

CREATE OR REPLACE FUNCTION delete_user_account(target_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_counts JSONB;
    coaching_count INT;
    appointment_count INT;
    workout_self_count INT;
    workout_preserved_count INT;
    template_count INT;
    custom_exercise_count INT;
    private_notes_count INT;
    shared_notes_count INT;
BEGIN
    -- 檢查用戶是否存在
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = target_user_id) THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'User not found'
        );
    END IF;

    -- 統計教練學員關係（✅ 使用 client_id）
    SELECT COUNT(*) INTO coaching_count 
    FROM public.coaching_relationships 
    WHERE coach_id = target_user_id OR client_id = target_user_id;

    -- 統計預約記錄
    SELECT COUNT(*) INTO appointment_count 
    FROM public.appointments 
    WHERE coach_id = target_user_id OR client_id = target_user_id;

    -- 統計訓練計劃
    SELECT COUNT(*) INTO workout_self_count 
    FROM public.workout_plans 
    WHERE trainee_id = target_user_id;

    SELECT COUNT(*) INTO workout_preserved_count 
    FROM public.workout_plans 
    WHERE creator_id = target_user_id AND trainee_id != target_user_id;

    SELECT COUNT(*) INTO template_count 
    FROM public.workout_templates 
    WHERE user_id = target_user_id;

    SELECT COUNT(*) INTO custom_exercise_count 
    FROM public.custom_exercises 
    WHERE user_id = target_user_id;

    -- ✅ 統計筆記（使用 visibility）
    SELECT COUNT(*) INTO private_notes_count 
    FROM public.session_notes 
    WHERE (coach_id = target_user_id OR client_id = target_user_id)
        AND visibility = 'private';

    SELECT COUNT(*) INTO shared_notes_count 
    FROM public.session_notes 
    WHERE (coach_id = target_user_id OR client_id = target_user_id)
        AND visibility = 'shared';

    -- ✅ 刪除私人筆記
    DELETE FROM public.session_notes 
    WHERE (coach_id = target_user_id OR client_id = target_user_id)
        AND visibility = 'private';

    -- 刪除訓練計劃
    DELETE FROM public.workout_plans 
    WHERE trainee_id = target_user_id;

    -- ✅ 保留共享筆記（設為 NULL）
    UPDATE public.session_notes 
    SET coach_id = NULL 
    WHERE coach_id = target_user_id AND visibility = 'shared';
    
    UPDATE public.session_notes 
    SET client_id = NULL 
    WHERE client_id = target_user_id AND visibility = 'shared';
    
    -- 刪除用戶
    DELETE FROM public.users WHERE id = target_user_id;
    
    -- 嘗試刪除 auth.users
    BEGIN
        DELETE FROM auth.users WHERE id = target_user_id;
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'No permission to delete auth.users';
        WHEN OTHERS THEN
            RAISE NOTICE 'Failed to delete auth.users: %', SQLERRM;
    END;

    -- 返回結果
    RETURN jsonb_build_object(
        'success', true,
        'user_id', target_user_id,
        'deleted', jsonb_build_object(
            'coaching_relationships', coaching_count,
            'appointments', appointment_count,
            'workout_plans_trainee', workout_self_count,
            'workout_templates', template_count,
            'private_notes', private_notes_count,
            'body_data', 'CASCADE',
            'daily_workout_summary', 'CASCADE',
            'personal_records', 'CASCADE'
        ),
        'preserved', jsonb_build_object(
            'custom_exercises', custom_exercise_count,
            'workout_plans_as_coach', workout_preserved_count,
            'shared_notes', shared_notes_count
        ),
        'auth_users_deleted', CASE 
            WHEN EXISTS (SELECT 1 FROM auth.users WHERE id = target_user_id) 
            THEN false 
            ELSE true 
        END
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

GRANT EXECUTE ON FUNCTION delete_user_account(UUID) TO authenticated;

COMMIT;

-- ============================================================================
-- 驗證
-- ============================================================================

-- 檢查 users 表格結構
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'users'
  AND column_name IN ('gender_visible')
ORDER BY ordinal_position;

-- 檢查 workout_templates 表格結構
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'workout_templates'
  AND column_name = 'training_time';

-- 檢查函數
SELECT proname FROM pg_proc 
WHERE proname = 'delete_user_account';

-- ============================================================================
-- 完成
-- ============================================================================

-- 說明：
-- ✅ workout_templates.training_time 已移除
-- ✅ users.gender_visible 已新增
-- ✅ custom_exercises RLS 策略已修復
-- ✅ delete_user_account() 函數已修復

