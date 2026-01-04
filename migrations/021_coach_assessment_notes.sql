-- =====================================================
-- Migration 021: Coach Assessment Notes - 教練評估備註
-- =====================================================
-- 創建日期：2026-01-04
-- 描述：建立教練對學員健康評估的私有備註系統
--      每個教練可以獨立記錄對學員評估的觀察和建議
--      學員無法查看這些備註
-- =====================================================

-- 1. 建立教練評估備註表
-- =====================================================

CREATE TABLE public.coach_assessment_notes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- 關聯欄位
    coach_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    assessment_id UUID NOT NULL REFERENCES public.health_assessments(id) ON DELETE CASCADE,
    
    -- 備註內容
    notes TEXT NOT NULL,
    
    -- 時間戳記
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- 確保每個教練對同一份評估只有一條備註
    CONSTRAINT unique_coach_assessment_note UNIQUE(coach_id, assessment_id)
);

-- 2. 建立索引
-- =====================================================

-- 高頻查詢：根據教練 ID 查詢所有備註
CREATE INDEX idx_coach_assessment_notes_coach 
ON public.coach_assessment_notes(coach_id);

-- 高頻查詢：根據評估 ID 查詢所有備註（管理功能）
CREATE INDEX idx_coach_assessment_notes_assessment 
ON public.coach_assessment_notes(assessment_id);

-- 複合索引：快速查詢特定教練對特定評估的備註
CREATE INDEX idx_coach_assessment_notes_coach_assessment 
ON public.coach_assessment_notes(coach_id, assessment_id);

-- 3. 建立 RLS (Row Level Security)
-- =====================================================

ALTER TABLE public.coach_assessment_notes ENABLE ROW LEVEL SECURITY;

-- 政策 1：教練只能查看自己的備註
CREATE POLICY "Coaches can view their own assessment notes"
ON public.coach_assessment_notes
FOR SELECT
USING (auth.uid() = coach_id);

-- 政策 2：教練只能新增自己的備註
CREATE POLICY "Coaches can insert their own assessment notes"
ON public.coach_assessment_notes
FOR INSERT
WITH CHECK (auth.uid() = coach_id);

-- 政策 3：教練只能更新自己的備註
CREATE POLICY "Coaches can update their own assessment notes"
ON public.coach_assessment_notes
FOR UPDATE
USING (auth.uid() = coach_id)
WITH CHECK (auth.uid() = coach_id);

-- 政策 4：教練只能刪除自己的備註
CREATE POLICY "Coaches can delete their own assessment notes"
ON public.coach_assessment_notes
FOR DELETE
USING (auth.uid() = coach_id);

-- 4. 建立更新時間觸發器
-- =====================================================

CREATE OR REPLACE FUNCTION update_coach_assessment_notes_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_coach_assessment_notes_timestamp
BEFORE UPDATE ON public.coach_assessment_notes
FOR EACH ROW
EXECUTE FUNCTION update_coach_assessment_notes_timestamp();

-- 5. 移除舊的 coach_notes 欄位（從 health_assessments 表）
-- =====================================================

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
    ELSE
        RAISE NOTICE 'ℹ️ health_assessments.coach_notes 欄位不存在，無需移除';
    END IF;
END
$$;

-- 6. 新增欄位註解
-- =====================================================

COMMENT ON TABLE public.coach_assessment_notes IS '教練對學員健康評估的私有備註（學員無法查看）';
COMMENT ON COLUMN public.coach_assessment_notes.coach_id IS '教練 ID';
COMMENT ON COLUMN public.coach_assessment_notes.assessment_id IS '健康評估 ID';
COMMENT ON COLUMN public.coach_assessment_notes.notes IS '教練備註內容';

-- 7. 驗證與測試
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '開始驗證 coach_assessment_notes 表結構...';
    
    -- 檢查表格是否建立成功
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'coach_assessment_notes'
    ) THEN
        RAISE EXCEPTION '❌ coach_assessment_notes 表未建立';
    END IF;
    RAISE NOTICE '✅ coach_assessment_notes 表建立成功';
    
    -- 檢查唯一約束
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_schema = 'public' 
        AND table_name = 'coach_assessment_notes' 
        AND constraint_name = 'unique_coach_assessment_note'
    ) THEN
        RAISE WARNING '⚠️ unique_coach_assessment_note 約束未建立';
    ELSE
        RAISE NOTICE '✅ unique_coach_assessment_note 約束建立成功';
    END IF;
    
    -- 檢查索引
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE schemaname = 'public' 
        AND tablename = 'coach_assessment_notes' 
        AND indexname = 'idx_coach_assessment_notes_coach'
    ) THEN
        RAISE WARNING '⚠️ idx_coach_assessment_notes_coach 索引未建立';
    ELSE
        RAISE NOTICE '✅ idx_coach_assessment_notes_coach 索引建立成功';
    END IF;
    
    -- 檢查 RLS 是否啟用
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'coach_assessment_notes' 
        AND rowsecurity = true
    ) THEN
        RAISE WARNING '⚠️ coach_assessment_notes 表 RLS 未啟用';
    ELSE
        RAISE NOTICE '✅ coach_assessment_notes 表 RLS 已啟用';
    END IF;
    
    -- 檢查舊欄位是否已移除
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'health_assessments' 
        AND column_name = 'coach_notes'
    ) THEN
        RAISE WARNING '⚠️ health_assessments.coach_notes 欄位仍存在';
    ELSE
        RAISE NOTICE '✅ health_assessments.coach_notes 欄位已正確移除';
    END IF;
    
    RAISE NOTICE '==========================================';
    RAISE NOTICE '✅ Migration 021 驗證完成';
    RAISE NOTICE '==========================================';
END $$;

-- 8. 測試資料範例（開發環境）
-- =====================================================

/*
-- 測試插入一筆教練備註（需要真實的 coach_id 和 assessment_id）
INSERT INTO public.coach_assessment_notes (
    coach_id,
    assessment_id,
    notes
) VALUES (
    '00000000-0000-0000-0000-000000000001', -- 教練 A 的 ID
    '00000000-0000-0000-0000-000000000100', -- 學員的健康評估 ID
    '需特別注意右膝舊傷，深蹲時建議使用輔助器材，避免膝蓋內扣。'
);

-- 測試查詢：教練查看自己對某學員評估的備註
SELECT 
    can.notes,
    can.created_at,
    can.updated_at,
    ha.user_id as client_id,
    u.display_name as client_name
FROM public.coach_assessment_notes can
JOIN public.health_assessments ha ON can.assessment_id = ha.id
JOIN public.users u ON ha.user_id = u.id
WHERE can.coach_id = '教練ID'
AND can.assessment_id = '評估ID';

-- 測試更新：教練更新自己的備註
UPDATE public.coach_assessment_notes
SET notes = '更新備註內容'
WHERE coach_id = '教練ID'
AND assessment_id = '評估ID';
*/

