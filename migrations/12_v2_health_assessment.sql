-- ============================================================================
-- StrengthWise Migration: 12_v2_health_assessment.sql
-- ============================================================================
-- 合併自: 016_health_assessments.sql, 016_health_assessments_verify.sql, 021_coach_assessment_notes.sql
-- 版本: v2.8
-- 日期: 2026-01-03 ~ 2026-01-04
-- ============================================================================
-- 
-- 包含:
-- 1. 健康評估系統（PAR-Q+ 問卷）
-- 2. 列舉類型（training_level, activity_level, injury_status）
-- 3. 教練顯示偏好設定表
-- 4. 教練評估備註系統
-- ============================================================================

-- ============================================================================
-- PART 1: 定義列舉類型
-- ============================================================================

-- 訓練經驗等級
DO $$ BEGIN
  CREATE TYPE training_level AS ENUM ('beginner', 'intermediate', 'advanced');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- 職業活動度
DO $$ BEGIN
  CREATE TYPE activity_level AS ENUM ('sedentary', 'light', 'moderate', 'vigorous');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- 傷病狀態
DO $$ BEGIN
  CREATE TYPE injury_status AS ENUM ('acute', 'subacute', 'chronic', 'post_surgery');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- PART 2: 建立健康評估主表
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.health_assessments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    assessed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    assessment_date TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- =========================================
    -- 基礎安全篩檢（PAR-Q+ 7題）
    -- =========================================
    heart_disease BOOLEAN DEFAULT FALSE NOT NULL,
    heart_disease_note TEXT,
    
    chest_pain_exercise BOOLEAN DEFAULT FALSE NOT NULL,
    
    chest_pain_rest BOOLEAN DEFAULT FALSE NOT NULL,
    
    dizziness BOOLEAN DEFAULT FALSE NOT NULL,
    
    bone_joint_problem BOOLEAN DEFAULT FALSE NOT NULL,
    bone_joint_note TEXT,
    
    medication BOOLEAN DEFAULT FALSE NOT NULL,
    medication_note TEXT,
    
    other_reason BOOLEAN DEFAULT FALSE NOT NULL,
    other_reason_note TEXT,
    
    -- 自動計算：是否通過安全篩檢
    is_cleared BOOLEAN GENERATED ALWAYS AS (
        NOT (heart_disease OR chest_pain_exercise OR chest_pain_rest 
             OR dizziness OR bone_joint_problem OR medication OR other_reason)
    ) STORED,
    
    -- =========================================
    -- 進階評估（JSONB 結構化儲存）
    -- =========================================
    cardiovascular_details JSONB DEFAULT '{}'::jsonb,
    musculoskeletal_details JSONB DEFAULT '[]'::jsonb,
    metabolic_details JSONB DEFAULT '{}'::jsonb,
    respiratory_details JSONB DEFAULT '{}'::jsonb,
    
    -- =========================================
    -- 生活型態與訓練背景
    -- =========================================
    training_experience training_level,
    training_years NUMERIC(3,1) CHECK (training_years >= 0 AND training_years <= 99.9),
    occupation_activity activity_level,
    equipment_access TEXT[] DEFAULT ARRAY[]::TEXT[],
    weekly_sessions INT CHECK (weekly_sessions >= 0 AND weekly_sessions <= 14),
    sleep_hours NUMERIC(3,1) CHECK (sleep_hours >= 0 AND sleep_hours <= 24),
    
    -- =========================================
    -- 訓練目標（JSONB）
    -- =========================================
    training_goals JSONB DEFAULT '{}'::jsonb,
    
    -- =========================================
    -- 版本控制與狀態
    -- =========================================
    version INT DEFAULT 1 NOT NULL,
    is_current BOOLEAN DEFAULT TRUE NOT NULL,
    emergency_contact JSONB,
    
    -- 時間戳記
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- ============================================================================
-- PART 3: 健康評估索引
-- ============================================================================

-- 確保每個學員只有一份「當前有效」的評估
CREATE UNIQUE INDEX IF NOT EXISTS unique_current_assessment_per_user
ON public.health_assessments(user_id)
WHERE is_current = TRUE;

-- 高頻查詢索引
CREATE INDEX IF NOT EXISTS idx_health_assessments_user_all
ON public.health_assessments(user_id, is_current);

-- JSONB GIN 索引
CREATE INDEX IF NOT EXISTS idx_health_assessments_injuries 
ON public.health_assessments USING gin(musculoskeletal_details);

CREATE INDEX IF NOT EXISTS idx_health_assessments_cardiovascular 
ON public.health_assessments USING gin(cardiovascular_details);

-- 訓練經驗索引
CREATE INDEX IF NOT EXISTS idx_health_assessments_training_level 
ON public.health_assessments(training_experience) 
WHERE training_experience IS NOT NULL;

-- 器材索引
CREATE INDEX IF NOT EXISTS idx_health_assessments_equipment 
ON public.health_assessments USING gin(equipment_access);

-- 時間序列索引
CREATE INDEX IF NOT EXISTS idx_health_assessments_date 
ON public.health_assessments(user_id, assessment_date DESC);

-- ============================================================================
-- PART 4: 健康評估 RLS
-- ============================================================================

ALTER TABLE public.health_assessments ENABLE ROW LEVEL SECURITY;

-- 學員可以查看和編輯自己的評估
DROP POLICY IF EXISTS "Users can view their own health assessments" ON public.health_assessments;
CREATE POLICY "Users can view their own health assessments"
ON public.health_assessments
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own health assessments" ON public.health_assessments;
CREATE POLICY "Users can insert their own health assessments"
ON public.health_assessments
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own health assessments" ON public.health_assessments;
CREATE POLICY "Users can update their own health assessments"
ON public.health_assessments
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 教練可以查看和編輯所屬學員的評估
DROP POLICY IF EXISTS "Coaches can view their clients' health assessments" ON public.health_assessments;
CREATE POLICY "Coaches can view their clients' health assessments"
ON public.health_assessments
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.coaching_relationships cr
        WHERE cr.client_id = health_assessments.user_id
        AND cr.coach_id = auth.uid()
        AND cr.status = 'active'
    )
);

DROP POLICY IF EXISTS "Coaches can insert their clients' health assessments" ON public.health_assessments;
CREATE POLICY "Coaches can insert their clients' health assessments"
ON public.health_assessments
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.coaching_relationships cr
        WHERE cr.client_id = health_assessments.user_id
        AND cr.coach_id = auth.uid()
        AND cr.status = 'active'
    )
);

DROP POLICY IF EXISTS "Coaches can update their clients' health assessments" ON public.health_assessments;
CREATE POLICY "Coaches can update their clients' health assessments"
ON public.health_assessments
FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.coaching_relationships cr
        WHERE cr.client_id = health_assessments.user_id
        AND cr.coach_id = auth.uid()
        AND cr.status = 'active'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.coaching_relationships cr
        WHERE cr.client_id = health_assessments.user_id
        AND cr.coach_id = auth.uid()
        AND cr.status = 'active'
    )
);

-- ============================================================================
-- PART 5: 教練顯示偏好設定表
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.coach_display_preferences (
    coach_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    health_assessment_fields TEXT[] DEFAULT ARRAY[
        'safety_screening',
        'injuries',
        'medications',
        'training_experience',
        'training_goals'
    ],
    client_list_sort_by TEXT DEFAULT 'name',
    client_list_sort_order TEXT DEFAULT 'asc',
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

ALTER TABLE public.coach_display_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Coaches can manage their own display preferences" ON public.coach_display_preferences;
CREATE POLICY "Coaches can manage their own display preferences"
ON public.coach_display_preferences
FOR ALL
USING (auth.uid() = coach_id)
WITH CHECK (auth.uid() = coach_id);

-- ============================================================================
-- PART 6: 教練評估備註表
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.coach_assessment_notes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    coach_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    assessment_id UUID NOT NULL REFERENCES public.health_assessments(id) ON DELETE CASCADE,
    notes TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    CONSTRAINT unique_coach_assessment_note UNIQUE(coach_id, assessment_id)
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_coach_assessment_notes_coach 
ON public.coach_assessment_notes(coach_id);

CREATE INDEX IF NOT EXISTS idx_coach_assessment_notes_assessment 
ON public.coach_assessment_notes(assessment_id);

CREATE INDEX IF NOT EXISTS idx_coach_assessment_notes_coach_assessment 
ON public.coach_assessment_notes(coach_id, assessment_id);

-- RLS
ALTER TABLE public.coach_assessment_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Coaches can view their own assessment notes" ON public.coach_assessment_notes;
CREATE POLICY "Coaches can view their own assessment notes"
ON public.coach_assessment_notes
FOR SELECT
USING (auth.uid() = coach_id);

DROP POLICY IF EXISTS "Coaches can insert their own assessment notes" ON public.coach_assessment_notes;
CREATE POLICY "Coaches can insert their own assessment notes"
ON public.coach_assessment_notes
FOR INSERT
WITH CHECK (auth.uid() = coach_id);

DROP POLICY IF EXISTS "Coaches can update their own assessment notes" ON public.coach_assessment_notes;
CREATE POLICY "Coaches can update their own assessment notes"
ON public.coach_assessment_notes
FOR UPDATE
USING (auth.uid() = coach_id)
WITH CHECK (auth.uid() = coach_id);

DROP POLICY IF EXISTS "Coaches can delete their own assessment notes" ON public.coach_assessment_notes;
CREATE POLICY "Coaches can delete their own assessment notes"
ON public.coach_assessment_notes
FOR DELETE
USING (auth.uid() = coach_id);

-- ============================================================================
-- PART 7: 觸發器
-- ============================================================================

-- 健康評估更新時間
CREATE OR REPLACE FUNCTION update_health_assessment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_health_assessment_timestamp ON public.health_assessments;
CREATE TRIGGER trigger_update_health_assessment_timestamp
BEFORE UPDATE ON public.health_assessments
FOR EACH ROW
EXECUTE FUNCTION update_health_assessment_timestamp();

DROP TRIGGER IF EXISTS trigger_update_coach_preferences_timestamp ON public.coach_display_preferences;
CREATE TRIGGER trigger_update_coach_preferences_timestamp
BEFORE UPDATE ON public.coach_display_preferences
FOR EACH ROW
EXECUTE FUNCTION update_health_assessment_timestamp();

-- 教練備註更新時間
CREATE OR REPLACE FUNCTION update_coach_assessment_notes_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_coach_assessment_notes_timestamp ON public.coach_assessment_notes;
CREATE TRIGGER trigger_update_coach_assessment_notes_timestamp
BEFORE UPDATE ON public.coach_assessment_notes
FOR EACH ROW
EXECUTE FUNCTION update_coach_assessment_notes_timestamp();

-- ============================================================================
-- PART 8: 移除舊欄位（如果存在）
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'health_assessments' 
        AND column_name = 'coach_notes'
    ) THEN
        ALTER TABLE public.health_assessments DROP COLUMN coach_notes;
        RAISE NOTICE '✅ health_assessments.coach_notes 欄位已移除';
    END IF;
END $$;

-- ============================================================================
-- PART 9: 欄位註解
-- ============================================================================

COMMENT ON TABLE public.health_assessments IS '學員健康評估問卷（PAR-Q+ 標準）';
COMMENT ON COLUMN public.health_assessments.is_cleared IS '是否通過安全篩檢（自動計算）';
COMMENT ON COLUMN public.health_assessments.musculoskeletal_details IS '傷病史陣列（JSONB）';
COMMENT ON COLUMN public.health_assessments.cardiovascular_details IS '心血管系統細節（JSONB）';
COMMENT ON COLUMN public.health_assessments.training_goals IS '訓練目標（JSONB）';
COMMENT ON COLUMN public.health_assessments.is_current IS '是否為當前有效評估';

COMMENT ON TABLE public.coach_display_preferences IS '教練在學員詳情頁的顯示偏好設定';

COMMENT ON TABLE public.coach_assessment_notes IS '教練對學員健康評估的私有備註（學員無法查看）';
COMMENT ON COLUMN public.coach_assessment_notes.coach_id IS '教練 ID';
COMMENT ON COLUMN public.coach_assessment_notes.assessment_id IS '健康評估 ID';
COMMENT ON COLUMN public.coach_assessment_notes.notes IS '教練備註內容';

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 12 完成：健康評估系統';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '新增表格：';
  RAISE NOTICE '  ✅ health_assessments - PAR-Q+ 健康問卷';
  RAISE NOTICE '  ✅ coach_display_preferences - 教練顯示偏好';
  RAISE NOTICE '  ✅ coach_assessment_notes - 教練私有備註';
  RAISE NOTICE '';
  RAISE NOTICE '列舉類型：';
  RAISE NOTICE '  ✅ training_level (beginner/intermediate/advanced)';
  RAISE NOTICE '  ✅ activity_level (sedentary/light/moderate/vigorous)';
  RAISE NOTICE '  ✅ injury_status (acute/subacute/chronic/post_surgery)';
  RAISE NOTICE '';
  RAISE NOTICE 'RLS 策略：';
  RAISE NOTICE '  ✅ 學員可查看/編輯自己的評估';
  RAISE NOTICE '  ✅ 教練可查看/編輯所屬學員的評估';
  RAISE NOTICE '  ✅ 教練備註僅限教練本人查看';
  RAISE NOTICE '';
END $$;
