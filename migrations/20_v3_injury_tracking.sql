-- ============================================================================
-- StrengthWise Migration: 20_v3_injury_tracking.sql
-- ============================================================================
-- 合併自: 042_injury_coach_notes.sql, 043_sleep_hours_range.sql, 
--        044_injury_notes_client_access.sql
-- 版本: v3.3
-- 日期: 2026-01-10
-- ============================================================================
-- 
-- 包含:
-- 1. injury_coach_notes 表（教練傷病備註）
-- 2. health_assessments 睡眠時數範圍欄位
-- 3. 學員可查看自己的傷病備註
-- ============================================================================

-- ============================================================================
-- PART 1: injury_coach_notes 表
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.injury_coach_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  injury_site TEXT NOT NULL,
  note TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(coach_id, client_id, injury_site)
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_injury_coach_notes_client ON injury_coach_notes(client_id);
CREATE INDEX IF NOT EXISTS idx_injury_coach_notes_coach ON injury_coach_notes(coach_id);
CREATE INDEX IF NOT EXISTS idx_injury_coach_notes_site ON injury_coach_notes(client_id, injury_site);

-- RLS
ALTER TABLE injury_coach_notes ENABLE ROW LEVEL SECURITY;

-- SELECT：教練可查看學員傷病，學員可查看自己的
DROP POLICY IF EXISTS injury_notes_select ON injury_coach_notes;
CREATE POLICY injury_notes_select ON injury_coach_notes FOR SELECT
  USING (
    -- 教練：有活躍教練關係
    EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.client_id = injury_coach_notes.client_id
        AND cr.coach_id = auth.uid()
        AND cr.status = 'active'
    )
    OR
    -- 學員：查看自己的傷病備註
    injury_coach_notes.client_id = auth.uid()
  );

-- INSERT：僅教練可新增
DROP POLICY IF EXISTS injury_notes_insert ON injury_coach_notes;
CREATE POLICY injury_notes_insert ON injury_coach_notes FOR INSERT
  WITH CHECK (
    coach_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM coaching_relationships cr
      WHERE cr.client_id = injury_coach_notes.client_id
        AND cr.coach_id = auth.uid()
        AND cr.status = 'active'
    )
  );

-- UPDATE：僅自己可更新
DROP POLICY IF EXISTS injury_notes_update ON injury_coach_notes;
CREATE POLICY injury_notes_update ON injury_coach_notes FOR UPDATE
  USING (coach_id = auth.uid());

-- DELETE：僅自己可刪除
DROP POLICY IF EXISTS injury_notes_delete ON injury_coach_notes;
CREATE POLICY injury_notes_delete ON injury_coach_notes FOR DELETE
  USING (coach_id = auth.uid());

-- 觸發器
CREATE OR REPLACE FUNCTION update_injury_coach_notes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_injury_coach_notes_updated_at ON injury_coach_notes;
CREATE TRIGGER trg_injury_coach_notes_updated_at
  BEFORE UPDATE ON injury_coach_notes
  FOR EACH ROW
  EXECUTE FUNCTION update_injury_coach_notes_updated_at();

-- 欄位註解
COMMENT ON TABLE public.injury_coach_notes IS '教練對學員傷病的備註（每教練獨立）';
COMMENT ON COLUMN public.injury_coach_notes.injury_site IS '傷病部位（對應 InjuryRecord.site）';
COMMENT ON COLUMN public.injury_coach_notes.note IS '教練備註內容';

-- ============================================================================
-- PART 2: 睡眠時數範圍欄位
-- ============================================================================

ALTER TABLE health_assessments 
  ADD COLUMN IF NOT EXISTS sleep_hours_min DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS sleep_hours_max DOUBLE PRECISION;

-- 遷移現有數據
UPDATE health_assessments 
SET 
  sleep_hours_min = sleep_hours, 
  sleep_hours_max = sleep_hours
WHERE sleep_hours IS NOT NULL 
  AND sleep_hours_min IS NULL;

COMMENT ON COLUMN health_assessments.sleep_hours_min IS '睡眠時數最小值';
COMMENT ON COLUMN health_assessments.sleep_hours_max IS '睡眠時數最大值';

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 20 完成：傷病追蹤';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '新增表格：';
  RAISE NOTICE '  ✅ injury_coach_notes - 教練傷病備註';
  RAISE NOTICE '';
  RAISE NOTICE 'RLS 策略：';
  RAISE NOTICE '  ✅ 教練可查看/編輯學員傷病備註';
  RAISE NOTICE '  ✅ 學員可查看自己的傷病備註（唯讀）';
  RAISE NOTICE '';
  RAISE NOTICE '新增欄位：';
  RAISE NOTICE '  ✅ health_assessments.sleep_hours_min';
  RAISE NOTICE '  ✅ health_assessments.sleep_hours_max';
  RAISE NOTICE '';
END $$;
