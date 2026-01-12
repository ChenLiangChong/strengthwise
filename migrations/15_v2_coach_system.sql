-- ============================================================================
-- StrengthWise Migration: 15_v2_coach_system.sql
-- ============================================================================
-- 合併自: 025_coaches_table.sql, 026_fix_workout_delete_rls.sql, 027_add_training_status_fields.sql
-- 版本: v2.9 ~ v2.9.1
-- 日期: 2026-01-04
-- ============================================================================
-- 
-- 包含:
-- 1. coaches 表（教練公開檔案）
-- 2. workout_plans DELETE RLS 修正（只有創建者可刪除）
-- 3. 訓練狀態追蹤欄位（暫停/繼續功能）
-- ============================================================================

-- ============================================================================
-- PART 1: 建立 coaches 表
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.coaches (
  -- ========== 主鍵（1:1 關聯 users） ==========
  id uuid REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
  
  -- ========== 身份與品牌 ==========
  display_name text,                    -- 顯示名稱（可與真名不同）
  headline text,                        -- 專業頭銜（max 160 chars，選填）
  bio text,                             -- 專業介紹（必填）
  
  -- ========== 專長標籤 ==========
  specialties jsonb DEFAULT '[]'::jsonb,
  -- 儲存格式：["weight_loss", "strength_conditioning", "custom:TRX懸吊訓練"]
  
  -- ========== 證照 ==========
  certifications jsonb DEFAULT '[]'::jsonb,
  -- 儲存格式：[{"org": "NASM", "name": "CPT", "year": 2020}]
  
  -- ========== 經歷 ==========
  years_experience int DEFAULT 0,
  
  -- ========== 語言能力 ==========
  languages jsonb DEFAULT '["zh-TW"]'::jsonb,
  
  -- ========== 服務資訊（預留） ==========
  service_types jsonb DEFAULT '[]'::jsonb,
  hourly_rate_min int,
  hourly_rate_max int,
  currency text DEFAULT 'TWD',
  offers_free_consultation boolean DEFAULT false,
  weekly_availability jsonb DEFAULT '{}'::jsonb,
  
  -- ========== 地理位置（預留） ==========
  location_lat double precision,
  location_lng double precision,
  service_radius_km int,
  gym_access text,
  
  -- ========== 審核機制（預留） ==========
  verified_status text DEFAULT 'pending',
  slug text UNIQUE,
  
  -- ========== 評價統計（快取） ==========
  average_rating numeric(3,2) DEFAULT 0,
  review_count int DEFAULT 0,
  
  -- ========== 媒體（預留） ==========
  gallery_images jsonb DEFAULT '[]'::jsonb,
  social_links jsonb DEFAULT '{}'::jsonb,
  
  -- ========== 時間戳 ==========
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 表格註解
COMMENT ON TABLE public.coaches IS '教練公開檔案（與 users 1:1 關聯）';
COMMENT ON COLUMN public.coaches.id IS '主鍵，同時為 users.id 的外鍵';
COMMENT ON COLUMN public.coaches.display_name IS '顯示名稱（品牌名）';
COMMENT ON COLUMN public.coaches.headline IS '專業頭銜（一句話描述，max 160 chars）';
COMMENT ON COLUMN public.coaches.bio IS '專業介紹（詳細背景）';
COMMENT ON COLUMN public.coaches.specialties IS '專長標籤 JSONB 陣列';
COMMENT ON COLUMN public.coaches.certifications IS '證照列表 JSONB 陣列';
COMMENT ON COLUMN public.coaches.years_experience IS '從業年資';
COMMENT ON COLUMN public.coaches.languages IS '語言能力 JSONB 陣列';
COMMENT ON COLUMN public.coaches.verified_status IS '審核狀態：pending/verified/rejected';
COMMENT ON COLUMN public.coaches.slug IS 'URL 專屬連結';

-- ============================================================================
-- PART 2: coaches RLS 政策
-- ============================================================================

ALTER TABLE public.coaches ENABLE ROW LEVEL SECURITY;

-- 教練可以讀取自己的資料
DROP POLICY IF EXISTS "coaches_select_own" ON public.coaches;
CREATE POLICY "coaches_select_own"
  ON public.coaches FOR SELECT
  USING (
    auth.uid() = id
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND is_coach = true
    )
  );

-- 教練可以建立自己的資料
DROP POLICY IF EXISTS "coaches_insert_own" ON public.coaches;
CREATE POLICY "coaches_insert_own"
  ON public.coaches FOR INSERT
  WITH CHECK (
    auth.uid() = id
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND is_coach = true
    )
  );

-- 教練可以更新自己的資料
DROP POLICY IF EXISTS "coaches_update_own" ON public.coaches;
CREATE POLICY "coaches_update_own"
  ON public.coaches FOR UPDATE
  USING (
    auth.uid() = id
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND is_coach = true
    )
  );

-- 學員可以查看自己教練的公開檔案
DROP POLICY IF EXISTS "coaches_select_by_student" ON public.coaches;
CREATE POLICY "coaches_select_by_student"
  ON public.coaches FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.coaching_relationships cr
      WHERE cr.coach_id = coaches.id
        AND cr.client_id = auth.uid()
        AND cr.status = 'active'
    )
  );

-- ============================================================================
-- PART 3: coaches 索引
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_coaches_verified_status ON public.coaches(verified_status);
CREATE INDEX IF NOT EXISTS idx_coaches_slug ON public.coaches(slug) WHERE slug IS NOT NULL;

-- ============================================================================
-- PART 4: coaches 觸發器
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_coaches_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_coaches_updated_at ON public.coaches;
CREATE TRIGGER update_coaches_updated_at
  BEFORE UPDATE ON public.coaches
  FOR EACH ROW
  EXECUTE FUNCTION update_coaches_updated_at();

-- ============================================================================
-- PART 5: get_coach_profile() 函數
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_coach_profile(coach_uuid uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'id', u.id,
    'display_name', COALESCE(c.display_name, u.display_name),
    'nickname', u.nickname,
    'photo_url', u.photo_url,
    'headline', c.headline,
    'bio', c.bio,
    'specialties', c.specialties,
    'certifications', c.certifications,
    'years_experience', c.years_experience,
    'languages', c.languages,
    'created_at', c.created_at
  )
  INTO result
  FROM public.users u
  LEFT JOIN public.coaches c ON u.id = c.id
  WHERE u.id = coach_uuid;
  
  RETURN result;
END;
$$;

COMMENT ON FUNCTION public.get_coach_profile IS '取得教練完整資料（users + coaches 合併）';

-- ============================================================================
-- PART 6: workout_plans DELETE RLS 修正
-- ============================================================================

DROP POLICY IF EXISTS "Users can delete their own workout plans" ON public.workout_plans;
DROP POLICY IF EXISTS "Users can delete their workout plans" ON public.workout_plans;
DROP POLICY IF EXISTS "Only creators can delete workout plans" ON public.workout_plans;

-- 新策略：只有創建者可以刪除（含向後相容）
CREATE POLICY "Only creators can delete workout plans"
  ON public.workout_plans 
  FOR DELETE
  TO authenticated
  USING (
    -- 新記錄：只有創建者可以刪除
    (creator_id IS NOT NULL AND auth.uid() = creator_id)
    OR
    -- 舊記錄（無 creator_id）：允許 trainee_id 刪除（向後相容）
    (creator_id IS NULL AND auth.uid() = trainee_id)
  );

-- ============================================================================
-- PART 7: 訓練狀態追蹤欄位
-- ============================================================================

ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS actual_start_time TIMESTAMPTZ;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS actual_end_time TIMESTAMPTZ;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS elapsed_seconds INTEGER DEFAULT 0;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS training_status TEXT DEFAULT 'pending';

COMMENT ON COLUMN workout_plans.actual_start_time IS '實際開始訓練的時間';
COMMENT ON COLUMN workout_plans.actual_end_time IS '實際結束訓練的時間';
COMMENT ON COLUMN workout_plans.elapsed_seconds IS '累計訓練秒數（不含暫停時間）';
COMMENT ON COLUMN workout_plans.training_status IS '訓練狀態：pending/in_progress/paused/completed';

-- 索引：方便查詢進行中的訓練
CREATE INDEX IF NOT EXISTS idx_workout_plans_training_status 
ON workout_plans(trainee_id, training_status) 
WHERE training_status IN ('in_progress', 'paused');

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 15 完成：教練系統與訓練狀態';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '新增表格：';
  RAISE NOTICE '  ✅ coaches - 教練公開檔案';
  RAISE NOTICE '';
  RAISE NOTICE 'RLS 策略：';
  RAISE NOTICE '  ✅ 教練可管理自己的檔案';
  RAISE NOTICE '  ✅ 學員可查看自己教練的檔案';
  RAISE NOTICE '  ✅ workout_plans DELETE 只允許創建者';
  RAISE NOTICE '';
  RAISE NOTICE '新增欄位：';
  RAISE NOTICE '  ✅ workout_plans.actual_start_time';
  RAISE NOTICE '  ✅ workout_plans.actual_end_time';
  RAISE NOTICE '  ✅ workout_plans.elapsed_seconds';
  RAISE NOTICE '  ✅ workout_plans.training_status';
  RAISE NOTICE '';
END $$;
