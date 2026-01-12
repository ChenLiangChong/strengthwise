-- ============================================================================
-- StrengthWise Migration: 13_v2_relationship_rls.sql
-- ============================================================================
-- 合併自: 017_fix_reactivate_relationship.sql, 018_add_hidden_by_client.sql, 
--        019_fix_client_archive_relationship.sql, 020_remove_client_profile.sql
-- 版本: v2.8
-- 日期: 2026-01-04
-- ============================================================================
-- 
-- 包含:
-- 1. 允許雙方重新激活已歸檔的關係
-- 2. 允許雙方歸檔關係
-- 3. session_notes 隱藏欄位（hidden_by_client, hidden_by_coach）
-- 4. 移除 client_profile 欄位（被 health_assessments 取代）
-- ============================================================================

-- ============================================================================
-- PART 1: 允許雙方重新激活已歸檔的關係 (來自 017)
-- ============================================================================

DROP POLICY IF EXISTS "Both parties can reactivate archived relationships" ON public.coaching_relationships;

CREATE POLICY "Both parties can reactivate archived relationships"
ON public.coaching_relationships
FOR UPDATE
USING (
    (auth.uid() = coach_id OR auth.uid() = client_id)
    AND status = 'archived'
)
WITH CHECK (
    (auth.uid() = coach_id OR auth.uid() = client_id)
    AND status = 'active'
);

-- ============================================================================
-- PART 2: session_notes 隱藏欄位 (來自 018)
-- ============================================================================
-- 
-- 用途：允許用戶「隱藏」共享筆記，而非刪除
-- 場景：教練關係結束後，學員/教練可以隱藏對方的筆記

-- 新增隱藏欄位
ALTER TABLE public.session_notes
ADD COLUMN IF NOT EXISTS hidden_by_client BOOLEAN DEFAULT FALSE NOT NULL,
ADD COLUMN IF NOT EXISTS hidden_by_coach BOOLEAN DEFAULT FALSE NOT NULL;

COMMENT ON COLUMN public.session_notes.hidden_by_client IS '學員是否隱藏此筆記';
COMMENT ON COLUMN public.session_notes.hidden_by_coach IS '教練是否隱藏此筆記';

-- 索引
CREATE INDEX IF NOT EXISTS idx_session_notes_hidden_by_client 
ON public.session_notes(client_id, hidden_by_client) 
WHERE hidden_by_client = FALSE;

CREATE INDEX IF NOT EXISTS idx_session_notes_hidden_by_coach 
ON public.session_notes(coach_id, hidden_by_coach) 
WHERE hidden_by_coach = FALSE;

-- RLS：允許學員隱藏筆記（僅更新 hidden_by_client 欄位）
DROP POLICY IF EXISTS "Clients can hide shared notes" ON public.session_notes;
CREATE POLICY "Clients can hide shared notes"
ON public.session_notes
FOR UPDATE
USING (
    auth.uid() = client_id 
    AND visibility = 'shared'
)
WITH CHECK (
    auth.uid() = client_id 
    AND visibility = 'shared'
);

-- RLS：允許教練隱藏筆記（僅更新 hidden_by_coach 欄位）
DROP POLICY IF EXISTS "Coaches can hide shared notes" ON public.session_notes;
CREATE POLICY "Coaches can hide shared notes"
ON public.session_notes
FOR UPDATE
USING (
    auth.uid() = coach_id 
    AND visibility = 'shared'
)
WITH CHECK (
    auth.uid() = coach_id 
    AND visibility = 'shared'
);

-- ============================================================================
-- PART 3: 允許雙方歸檔關係 (來自 019)
-- ============================================================================

DROP POLICY IF EXISTS "Both parties can archive relationships" ON public.coaching_relationships;

CREATE POLICY "Both parties can archive relationships"
ON public.coaching_relationships
FOR UPDATE
USING (
    (auth.uid() = coach_id OR auth.uid() = client_id)
    AND status = 'active'
)
WITH CHECK (
    (auth.uid() = coach_id OR auth.uid() = client_id)
    AND status = 'archived'
);

-- ============================================================================
-- PART 4: 移除 client_profile 欄位 (來自 020)
-- ============================================================================
-- 
-- 原因：client_profile 功能已被 health_assessments 系統取代

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'coaching_relationships' 
        AND column_name = 'client_profile'
    ) THEN
        ALTER TABLE public.coaching_relationships DROP COLUMN client_profile;
        RAISE NOTICE '✅ coaching_relationships.client_profile 欄位已移除';
    ELSE
        RAISE NOTICE 'ℹ️ client_profile 欄位不存在，無需移除';
    END IF;
END $$;

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 13 完成：關係 RLS 與筆記隱藏';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'RLS 策略：';
  RAISE NOTICE '  ✅ 雙方可重新激活已歸檔的關係';
  RAISE NOTICE '  ✅ 雙方可歸檔活躍的關係';
  RAISE NOTICE '';
  RAISE NOTICE '新增欄位：';
  RAISE NOTICE '  ✅ session_notes.hidden_by_client';
  RAISE NOTICE '  ✅ session_notes.hidden_by_coach';
  RAISE NOTICE '';
  RAISE NOTICE '移除欄位：';
  RAISE NOTICE '  ✅ coaching_relationships.client_profile（被 health_assessments 取代）';
  RAISE NOTICE '';
END $$;
