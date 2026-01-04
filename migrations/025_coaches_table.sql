  -- ============================================================
  -- Migration: 025_coaches_table.sql
  -- 版本: v2.9
  -- 描述: 教練公開檔案表
  -- 作者: StrengthWise Team
  -- 日期: 2026-01-04
  -- ============================================================

  -- ============================================================
  -- 1. 建立 coaches 表
  -- ============================================================

  CREATE TABLE public.coaches (
    -- ========== 主鍵（1:1 關聯 users） ==========
    id uuid REFERENCES public.users(id) ON DELETE CASCADE PRIMARY KEY,
    
    -- ========== v2.9 實作：身份與品牌 ==========
    display_name text,                    -- 顯示名稱（可與真名不同）
    headline text,                        -- 專業頭銜（max 160 chars，選填）
    bio text,                             -- 專業介紹（必填）
    
    -- ========== v2.9 實作：專長標籤 ==========
    specialties jsonb DEFAULT '[]'::jsonb,
    -- 儲存格式：["weight_loss", "strength_conditioning", "custom:TRX懸吊訓練"]
    -- 預定義標籤用 key，自定義標籤用 "custom:" 前綴
    
    -- ========== v2.9 實作：證照 ==========
    certifications jsonb DEFAULT '[]'::jsonb,
    -- 儲存格式：[{"org": "NASM", "name": "CPT", "year": 2020}]
    
    -- ========== v2.9 實作：經歷 ==========
    years_experience int DEFAULT 0,
    
    -- ========== v2.9 實作：語言能力 ==========
    languages jsonb DEFAULT '["zh-TW"]'::jsonb,
    -- 儲存格式：["zh-TW", "en"]
    
    -- ========== 未來計劃：服務資訊 ==========
    service_types jsonb DEFAULT '[]'::jsonb,
    -- 儲存格式：["in_person", "online", "hybrid", "group_class"]
    
    hourly_rate_min int,                  -- 最低時薪
    hourly_rate_max int,                  -- 最高時薪
    currency text DEFAULT 'TWD',          -- 幣別
    offers_free_consultation boolean DEFAULT false,  -- 免費諮詢
    
    weekly_availability jsonb DEFAULT '{}'::jsonb,
    -- 儲存格式：{"mon": ["morning", "evening"], "sat": ["morning"]}
    
    -- ========== 未來計劃：地理位置 ==========
    -- 暫不使用 PostGIS，先用經緯度欄位預留
    location_lat double precision,        -- 緯度
    location_lng double precision,        -- 經度
    service_radius_km int,                -- 服務半徑（公里）
    gym_access text,                      -- 合作健身房
    
    -- ========== 未來計劃：審核機制 ==========
    verified_status text DEFAULT 'pending',  -- pending, verified, rejected
    slug text UNIQUE,                     -- URL slug: /coach/unique-slug
    
    -- ========== 未來計劃：評價統計（快取） ==========
    average_rating numeric(3,2) DEFAULT 0,
    review_count int DEFAULT 0,
    
    -- ========== 未來計劃：媒體 ==========
    gallery_images jsonb DEFAULT '[]'::jsonb,  -- 教學案例照片 URLs
    social_links jsonb DEFAULT '{}'::jsonb,    -- 社群連結 {"ig": "...", "fb": "..."}
    
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
  COMMENT ON COLUMN public.coaches.specialties IS '專長標籤 JSONB 陣列（預定義+自定義）';
  COMMENT ON COLUMN public.coaches.certifications IS '證照列表 JSONB 陣列';
  COMMENT ON COLUMN public.coaches.years_experience IS '從業年資';
  COMMENT ON COLUMN public.coaches.languages IS '語言能力 JSONB 陣列';
  COMMENT ON COLUMN public.coaches.verified_status IS '審核狀態：pending/verified/rejected';
  COMMENT ON COLUMN public.coaches.slug IS 'URL 專屬連結';

  -- ============================================================
  -- 2. RLS 政策
  -- ============================================================

  ALTER TABLE public.coaches ENABLE ROW LEVEL SECURITY;

  -- 教練可以讀取自己的資料（必須是教練身份）
  CREATE POLICY "coaches_select_own"
    ON public.coaches FOR SELECT
    USING (
      auth.uid() = id
      AND EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND is_coach = true
      )
    );

  -- 教練可以建立自己的資料（必須是教練身份）
  CREATE POLICY "coaches_insert_own"
    ON public.coaches FOR INSERT
    WITH CHECK (
      auth.uid() = id
      AND EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND is_coach = true
      )
    );

  -- 教練可以更新自己的資料（必須是教練身份）
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

  -- 未來計劃：公開搜尋（需審核機制）
  -- CREATE POLICY "coaches_public_verified"
  --   ON public.coaches FOR SELECT
  --   USING (verified_status = 'verified');

  -- ============================================================
  -- 3. 索引
  -- ============================================================

  -- 基礎索引
  CREATE INDEX idx_coaches_verified_status ON public.coaches(verified_status);
  CREATE INDEX idx_coaches_slug ON public.coaches(slug) WHERE slug IS NOT NULL;

  -- 未來計劃：搜尋索引
  -- CREATE INDEX idx_coaches_specialties ON public.coaches USING GIN (specialties);
  -- CREATE INDEX idx_coaches_fts ON public.coaches USING GIN (to_tsvector('chinese', coalesce(headline, '') || ' ' || coalesce(bio, '')));

  -- ============================================================
  -- 4. 觸發器
  -- ============================================================

-- 建立專用的 updated_at 觸發器函數
-- （不使用 update_updated_at_column，因為那個用的是 profile_updated_at）
CREATE OR REPLACE FUNCTION public.update_coaches_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_coaches_updated_at
  BEFORE UPDATE ON public.coaches
  FOR EACH ROW
  EXECUTE FUNCTION update_coaches_updated_at();

  -- ============================================================
  -- 5. 輔助函數
  -- ============================================================

  -- 取得教練完整資料（users + coaches）
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

  -- ============================================================
  -- 完成
  -- ============================================================

