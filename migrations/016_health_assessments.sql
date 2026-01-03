-- =====================================================
-- Migration 016: Health Assessments - 健康評估系統
-- =====================================================
-- 創建日期：2025-01-03
-- 描述：建立學員健康評估問卷系統（PAR-Q+ 標準）
-- =====================================================

-- 1. 定義列舉類型
-- =====================================================

-- 訓練經驗等級
CREATE TYPE training_level AS ENUM ('beginner', 'intermediate', 'advanced');

-- 職業活動度
CREATE TYPE activity_level AS ENUM ('sedentary', 'light', 'moderate', 'vigorous');

-- 傷病狀態
CREATE TYPE injury_status AS ENUM ('acute', 'subacute', 'chronic', 'post_surgery');

-- 2. 建立健康評估主表
-- =====================================================

CREATE TABLE public.health_assessments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    assessed_by UUID REFERENCES public.users(id) ON DELETE SET NULL, -- 誰建立的（教練或學員自己）
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
    
    -- 心血管系統細節
    -- 範例結構：
    -- {
    --   "high_blood_pressure": true,
    --   "blood_pressure_value": "140/90",
    --   "symptoms": ["shortness_of_breath", "ankle_swelling"],
    --   "family_history": false,
    --   "medication_types": ["beta_blockers", "ace_inhibitors"]
    -- }
    cardiovascular_details JSONB DEFAULT '{}'::jsonb,
    
    -- 骨骼肌肉傷病史（陣列）
    -- 範例結構：
    -- [
    --   {
    --     "site": "右膝",
    --     "status": "chronic",
    --     "diagnosis": "前十字韌帶撕裂",
    --     "limitations": "避免跳躍動作",
    --     "occurred_date": "2023-06-01T00:00:00Z"
    --   }
    -- ]
    musculoskeletal_details JSONB DEFAULT '[]'::jsonb,
    
    -- 代謝與內分泌系統
    -- 範例結構：
    -- {
    --   "diabetes_type": "type_2",
    --   "hba1c": "6.8",
    --   "other_conditions": ["hypothyroidism", "gout"]
    -- }
    metabolic_details JSONB DEFAULT '{}'::jsonb,
    
    -- 呼吸系統
    -- 範例結構：
    -- {
    --   "asthma": true,
    --   "requires_inhaler": true,
    --   "copd": false
    -- }
    respiratory_details JSONB DEFAULT '{}'::jsonb,
    
    -- =========================================
    -- 生活型態與訓練背景
    -- =========================================
    
    -- 訓練經驗等級
    training_experience training_level,
    
    -- 訓練年資（以年為單位）
    training_years NUMERIC(3,1) CHECK (training_years >= 0 AND training_years <= 99.9),
    
    -- 職業活動度
    occupation_activity activity_level,
    
    -- 可用器材（陣列）
    -- 範例：['dumbbells', 'barbells', 'kettlebells', 'resistance_bands', 'bodyweight']
    equipment_access TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    -- 每週可訓練次數
    weekly_sessions INT CHECK (weekly_sessions >= 0 AND weekly_sessions <= 14),
    
    -- 平均睡眠時數
    sleep_hours NUMERIC(3,1) CHECK (sleep_hours >= 0 AND sleep_hours <= 24),
    
    -- =========================================
    -- 訓練目標（JSONB）
    -- =========================================
    -- 範例結構：
    -- {
    --   "primary": "weight_loss",
    --   "target_kg": -8,
    --   "timeframe_months": 3,
    --   "notes": "為婚禮準備"
    -- }
    training_goals JSONB DEFAULT '{}'::jsonb,
    
    -- =========================================
    -- 版本控制與狀態
    -- =========================================
    
    -- 問卷版本號（預留未來問卷更新）
    version INT DEFAULT 1 NOT NULL,
    
    -- 是否為當前有效評估
    is_current BOOLEAN DEFAULT TRUE NOT NULL,
    
    -- 緊急聯絡人（JSONB）
    -- 範例：{"name": "王小明", "phone": "+886912345678", "relationship": "配偶"}
    emergency_contact JSONB,
    
    -- 教練備註（私有）
    coach_notes TEXT,
    
    -- 時間戳記
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 3. 建立索引
-- =====================================================

-- 確保每個學員只有一份「當前有效」的評估（部分唯一索引）
CREATE UNIQUE INDEX unique_current_assessment_per_user
ON public.health_assessments(user_id)
WHERE is_current = TRUE;

-- 高頻查詢：根據 user_id 查詢當前評估（改用一般索引，因為上面已經有唯一索引）
CREATE INDEX idx_health_assessments_user_all
ON public.health_assessments(user_id, is_current);

-- 全文檢索：查詢特定傷病部位
CREATE INDEX idx_health_assessments_injuries 
ON public.health_assessments 
USING gin(musculoskeletal_details);

-- 查詢心血管風險學員
CREATE INDEX idx_health_assessments_cardiovascular 
ON public.health_assessments 
USING gin(cardiovascular_details);

-- 查詢特定訓練經驗的學員
CREATE INDEX idx_health_assessments_training_level 
ON public.health_assessments(training_experience) 
WHERE training_experience IS NOT NULL;

-- 查詢有器材限制的學員
CREATE INDEX idx_health_assessments_equipment 
ON public.health_assessments 
USING gin(equipment_access);

-- 時間序列查詢（歷史評估）
CREATE INDEX idx_health_assessments_date 
ON public.health_assessments(user_id, assessment_date DESC);

-- 4. 建立 RLS (Row Level Security)
-- =====================================================

ALTER TABLE public.health_assessments ENABLE ROW LEVEL SECURITY;

-- 政策 1：學員可以查看和編輯自己的評估
CREATE POLICY "Users can view their own health assessments"
ON public.health_assessments
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own health assessments"
ON public.health_assessments
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own health assessments"
ON public.health_assessments
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 政策 2：教練可以查看和編輯所屬學員的評估
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

-- 5. 建立教練顯示偏好設定表
-- =====================================================

CREATE TABLE public.coach_display_preferences (
    coach_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    
    -- 健康評估在學員詳情頁顯示的欄位
    health_assessment_fields TEXT[] DEFAULT ARRAY[
        'safety_screening',
        'injuries',
        'medications',
        'training_experience',
        'training_goals'
    ],
    
    -- 學員列表排序偏好（預留）
    client_list_sort_by TEXT DEFAULT 'name',
    client_list_sort_order TEXT DEFAULT 'asc',
    
    -- 更新時間
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 啟用 RLS
ALTER TABLE public.coach_display_preferences ENABLE ROW LEVEL SECURITY;

-- 教練只能查看和修改自己的偏好
CREATE POLICY "Coaches can manage their own display preferences"
ON public.coach_display_preferences
FOR ALL
USING (auth.uid() = coach_id)
WITH CHECK (auth.uid() = coach_id);

-- 6. 建立更新時間觸發器
-- =====================================================

CREATE OR REPLACE FUNCTION update_health_assessment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_health_assessment_timestamp
BEFORE UPDATE ON public.health_assessments
FOR EACH ROW
EXECUTE FUNCTION update_health_assessment_timestamp();

CREATE TRIGGER trigger_update_coach_preferences_timestamp
BEFORE UPDATE ON public.coach_display_preferences
FOR EACH ROW
EXECUTE FUNCTION update_health_assessment_timestamp();

-- 7. 新增欄位註解
-- =====================================================

COMMENT ON TABLE public.health_assessments IS '學員健康評估問卷（PAR-Q+ 標準）';
COMMENT ON COLUMN public.health_assessments.is_cleared IS '是否通過安全篩檢（自動計算）';
COMMENT ON COLUMN public.health_assessments.musculoskeletal_details IS '傷病史陣列（JSONB）';
COMMENT ON COLUMN public.health_assessments.cardiovascular_details IS '心血管系統細節（JSONB）';
COMMENT ON COLUMN public.health_assessments.training_goals IS '訓練目標（JSONB）';
COMMENT ON COLUMN public.health_assessments.is_current IS '是否為當前有效評估（每個學員只能有一份）';

COMMENT ON TABLE public.coach_display_preferences IS '教練在學員詳情頁的顯示偏好設定';

-- 8. 驗證與測試
-- =====================================================

DO $$
DECLARE
    test_user_id UUID;
    test_assessment_id TEXT;
BEGIN
    RAISE NOTICE '開始驗證 health_assessments 表結構...';
    
    -- 檢查表格是否建立成功
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'health_assessments'
    ) THEN
        RAISE EXCEPTION '❌ health_assessments 表未建立';
    END IF;
    RAISE NOTICE '✅ health_assessments 表建立成功';
    
    -- 檢查列舉類型
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'training_level') THEN
        RAISE EXCEPTION '❌ training_level 列舉類型未建立';
    END IF;
    RAISE NOTICE '✅ training_level 列舉類型建立成功';
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'activity_level') THEN
        RAISE EXCEPTION '❌ activity_level 列舉類型未建立';
    END IF;
    RAISE NOTICE '✅ activity_level 列舉類型建立成功';
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'injury_status') THEN
        RAISE EXCEPTION '❌ injury_status 列舉類型未建立';
    END IF;
    RAISE NOTICE '✅ injury_status 列舉類型建立成功';
    
    -- 檢查索引
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND tablename = 'health_assessments' 
        AND indexname = 'idx_health_assessments_user_current'
    ) THEN
        RAISE WARNING '⚠️ idx_health_assessments_user_current 索引未建立';
    ELSE
        RAISE NOTICE '✅ idx_health_assessments_user_current 索引建立成功';
    END IF;
    
    -- 檢查 GIN 索引
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND tablename = 'health_assessments' 
        AND indexname = 'idx_health_assessments_injuries'
    ) THEN
        RAISE WARNING '⚠️ idx_health_assessments_injuries GIN 索引未建立';
    ELSE
        RAISE NOTICE '✅ idx_health_assessments_injuries GIN 索引建立成功';
    END IF;
    
    -- 檢查 RLS 是否啟用
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'health_assessments' 
        AND rowsecurity = true
    ) THEN
        RAISE WARNING '⚠️ health_assessments 表 RLS 未啟用';
    ELSE
        RAISE NOTICE '✅ health_assessments 表 RLS 已啟用';
    END IF;
    
    -- 檢查教練偏好表
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'coach_display_preferences'
    ) THEN
        RAISE EXCEPTION '❌ coach_display_preferences 表未建立';
    END IF;
    RAISE NOTICE '✅ coach_display_preferences 表建立成功';
    
    -- 檢查唯一索引（確保每個學員只有一份當前評估）
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND tablename = 'health_assessments' 
        AND indexname = 'unique_current_assessment_per_user'
    ) THEN
        RAISE WARNING '⚠️ unique_current_assessment_per_user 唯一索引未建立';
    ELSE
        RAISE NOTICE '✅ unique_current_assessment_per_user 唯一索引建立成功';
    END IF;
    
    RAISE NOTICE '==========================================';
    RAISE NOTICE '✅ Migration 016 驗證完成';
    RAISE NOTICE '==========================================';
END $$;

-- 9. 測試資料範例（開發環境）
-- =====================================================

-- 測試插入一筆評估資料（注意：需要先有對應的 user_id）
/*
INSERT INTO public.health_assessments (
    user_id,
    heart_disease,
    chest_pain_exercise,
    chest_pain_rest,
    dizziness,
    bone_joint_problem,
    bone_joint_note,
    medication,
    medication_note,
    other_reason,
    musculoskeletal_details,
    training_experience,
    training_years,
    occupation_activity,
    equipment_access,
    training_goals
) VALUES (
    '00000000-0000-0000-0000-000000000000', -- 替換為真實的 user_id
    false,
    false,
    false,
    false,
    true,
    '右膝舊傷',
    false,
    null,
    false,
    '[{"site":"右膝","status":"chronic","limitations":"避免跳躍動作"}]'::jsonb,
    'intermediate',
    2.0,
    'sedentary',
    ARRAY['dumbbells', 'barbells'],
    '{"primary":"weight_loss","target_kg":-8,"timeframe_months":3}'::jsonb
);
*/

-- 測試查詢
/*
-- 1. 查詢學員的當前評估
SELECT * FROM public.health_assessments 
WHERE user_id = '00000000-0000-0000-0000-000000000000' 
AND is_current = TRUE;

-- 2. 查詢所有有膝蓋傷的學員
SELECT user_id, musculoskeletal_details 
FROM public.health_assessments 
WHERE musculoskeletal_details @> '[{"site":"右膝"}]'::jsonb;

-- 3. 查詢未通過安全篩檢的學員
SELECT user_id, heart_disease, chest_pain_exercise, medication 
FROM public.health_assessments 
WHERE is_cleared = FALSE 
AND is_current = TRUE;

-- 4. 查詢訓練經驗為新手的學員
SELECT user_id, training_experience, training_years 
FROM public.health_assessments 
WHERE training_experience = 'beginner' 
AND is_current = TRUE;
*/

