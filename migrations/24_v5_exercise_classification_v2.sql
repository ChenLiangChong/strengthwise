-- ============================================================================
-- StrengthWise Migration: 24_v5_exercise_classification_v2.sql
-- ============================================================================
-- 版本: v5.0
-- 日期: 2026-02-07
-- ============================================================================
--
-- 動作分類系統 v2
-- - 新增多維度分類欄位（動作模式、PPL 標籤、主動肌等）
-- - 建立別名搜尋表
-- - 建立參照表
-- - 建立進階搜尋 RPC 函數
--
-- 參考文檔：docs/planning/EXERCISE_CLASSIFICATION_ANALYSIS.md
-- ============================================================================

-- ============================================================================
-- PART 1: 新增 exercises 表欄位
-- ============================================================================

-- 1.1 SEE 標準名稱（Specification-Equipment-Exercise）
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS canonical_name TEXT;
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS canonical_name_en TEXT;

-- 1.2 動作模式（可複選）
-- 有效值：push, horizontal_push, vertical_push, isolation_push,
--         pull, horizontal_pull, vertical_pull, isolation_pull,
--         squat, isolation_squat, hinge, isolation_hinge, lunge,
--         core, anti_extension, anti_rotation, anti_lateral, flexion, rotation,
--         carry, cardio, mobility
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS movement_patterns TEXT[] DEFAULT '{}';

-- 1.3 PPL 標籤（可複選）
-- 有效值：push, pull, legs, core, mobility, cardio
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS ppl_tags TEXT[] DEFAULT '{}';

-- 1.4 主動肌（單選）
-- 有效值：25 個，詳見 ref_muscle_groups.json
-- pec_major_clavicular, pec_major_sternal, pec_minor, serratus_anterior,
-- lats, traps, rhomboids, erector_spinae, teres_major,
-- front_delts, side_delts, rear_delts, rotator_cuff,
-- biceps, triceps, brachialis, forearms,
-- quads, hamstrings, glutes, adductors, calves, hip_flexors, tibialis_anterior,
-- abs, obliques
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS primary_muscle TEXT;

-- 1.5 協同肌（可複選）
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS synergist_muscles TEXT[] DEFAULT '{}';

-- 1.6 力學類型
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS mechanics_type TEXT DEFAULT 'compound';
-- 有效值：compound（多關節）/ isolation（單關節）

-- 1.7 單邊動作標記
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS is_unilateral BOOLEAN DEFAULT FALSE;

-- 1.8 難度等級
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS difficulty_level TEXT DEFAULT 'beginner';
-- 有效值：beginner / intermediate / advanced

-- 1.9 爆發力動作標記
ALTER TABLE exercises ADD COLUMN IF NOT EXISTS is_explosive BOOLEAN DEFAULT FALSE;

-- ============================================================================
-- PART 2: 建立別名表
-- ============================================================================

CREATE TABLE IF NOT EXISTS exercise_aliases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_id TEXT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    alias_term TEXT NOT NULL,
    locale TEXT DEFAULT 'zh-TW',  -- zh-TW, en-US
    category TEXT DEFAULT 'common',  -- common, slang, abbreviation, brand
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 建立索引
CREATE INDEX IF NOT EXISTS idx_exercise_aliases_exercise_id
    ON exercise_aliases(exercise_id);
CREATE INDEX IF NOT EXISTS idx_exercise_aliases_term
    ON exercise_aliases(alias_term);
CREATE INDEX IF NOT EXISTS idx_exercise_aliases_term_lower
    ON exercise_aliases(LOWER(alias_term));

-- 啟用 RLS
ALTER TABLE exercise_aliases ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有人可讀
CREATE POLICY "exercise_aliases_read_all" ON exercise_aliases
    FOR SELECT USING (true);

-- ============================================================================
-- PART 3: 建立參照表
-- ============================================================================

-- 3.1 動作模式參照表
CREATE TABLE IF NOT EXISTS ref_movement_patterns (
    id TEXT PRIMARY KEY,
    name_zh TEXT NOT NULL,
    name_en TEXT NOT NULL,
    parent_id TEXT REFERENCES ref_movement_patterns(id),
    description_zh TEXT,
    description_en TEXT,
    sort_order INT DEFAULT 0
);

-- 3.2 肌肉群參照表
CREATE TABLE IF NOT EXISTS ref_muscle_groups (
    id TEXT PRIMARY KEY,
    name_zh TEXT NOT NULL,
    name_en TEXT NOT NULL,
    region TEXT NOT NULL,  -- upper_body, lower_body, core
    parent_group TEXT,     -- chest, back, shoulders, arms, legs, core
    sort_order INT DEFAULT 0
);

-- 3.3 器材參照表
CREATE TABLE IF NOT EXISTS ref_equipment (
    id TEXT PRIMARY KEY,
    name_zh TEXT NOT NULL,
    name_en TEXT NOT NULL,
    description_zh TEXT,
    description_en TEXT,
    sort_order INT DEFAULT 0
);

-- 啟用 RLS
ALTER TABLE ref_movement_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE ref_muscle_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE ref_equipment ENABLE ROW LEVEL SECURITY;

-- RLS 策略：所有人可讀
CREATE POLICY "ref_movement_patterns_read_all" ON ref_movement_patterns
    FOR SELECT USING (true);
CREATE POLICY "ref_muscle_groups_read_all" ON ref_muscle_groups
    FOR SELECT USING (true);
CREATE POLICY "ref_equipment_read_all" ON ref_equipment
    FOR SELECT USING (true);

-- ============================================================================
-- PART 4: 建立進階搜尋 RPC 函數
-- ============================================================================

-- 4.1 進階搜尋函數（支援別名、動作模式、PPL 篩選）
CREATE OR REPLACE FUNCTION search_exercises_v2(
    search_query TEXT DEFAULT NULL,
    p_movement_patterns TEXT[] DEFAULT NULL,
    p_ppl_tags TEXT[] DEFAULT NULL,
    p_primary_muscle TEXT DEFAULT NULL,
    p_equipment TEXT DEFAULT NULL,
    p_is_explosive BOOLEAN DEFAULT NULL,
    p_difficulty_level TEXT DEFAULT NULL,
    max_results INT DEFAULT 50
)
RETURNS TABLE (
    id TEXT,
    name TEXT,
    name_en TEXT,
    canonical_name TEXT,
    canonical_name_en TEXT,
    body_parts TEXT[],
    training_type TEXT,
    equipment TEXT,
    level1 TEXT,
    level2 TEXT,
    level3 TEXT,
    level4 TEXT,
    level5 TEXT,
    action_name TEXT,
    description TEXT,
    image_url TEXT,
    video_url TEXT,
    body_part TEXT,
    specific_muscle TEXT,
    equipment_category TEXT,
    equipment_subcategory TEXT,
    tracking_mode TEXT,
    movement_patterns TEXT[],
    ppl_tags TEXT[],
    primary_muscle TEXT,
    synergist_muscles TEXT[],
    mechanics_type TEXT,
    is_unilateral BOOLEAN,
    difficulty_level TEXT,
    is_explosive BOOLEAN,
    created_at TIMESTAMPTZ,
    relevance_score FLOAT
) AS $$
BEGIN
    RETURN QUERY
    WITH matched_exercises AS (
        SELECT DISTINCT e.id AS eid
        FROM exercises e
        LEFT JOIN exercise_aliases ea ON e.id = ea.exercise_id
        WHERE
            -- 文字搜尋（名稱 + 別名）
            (search_query IS NULL OR search_query = '' OR
             e.name ILIKE '%' || search_query || '%' OR
             e.name_en ILIKE '%' || search_query || '%' OR
             e.canonical_name ILIKE '%' || search_query || '%' OR
             e.canonical_name_en ILIKE '%' || search_query || '%' OR
             ea.alias_term ILIKE '%' || search_query || '%')
            -- 動作模式篩選
            AND (p_movement_patterns IS NULL OR e.movement_patterns && p_movement_patterns)
            -- PPL 標籤篩選
            AND (p_ppl_tags IS NULL OR e.ppl_tags && p_ppl_tags)
            -- 主動肌篩選
            AND (p_primary_muscle IS NULL OR e.primary_muscle = p_primary_muscle)
            -- 器材篩選
            AND (p_equipment IS NULL OR e.equipment = p_equipment)
            -- 爆發力篩選
            AND (p_is_explosive IS NULL OR e.is_explosive = p_is_explosive)
            -- 難度篩選
            AND (p_difficulty_level IS NULL OR e.difficulty_level = p_difficulty_level)
    )
    SELECT
        e.id,
        e.name,
        e.name_en,
        e.canonical_name,
        e.canonical_name_en,
        e.body_parts,
        e.training_type,
        e.equipment,
        e.level1,
        e.level2,
        e.level3,
        e.level4,
        e.level5,
        e.action_name,
        e.description,
        e.image_url,
        e.video_url,
        e.body_part,
        e.specific_muscle,
        e.equipment_category,
        e.equipment_subcategory,
        e.tracking_mode,
        e.movement_patterns,
        e.ppl_tags,
        e.primary_muscle,
        e.synergist_muscles,
        e.mechanics_type,
        e.is_unilateral,
        e.difficulty_level,
        e.is_explosive,
        e.created_at,
        -- 相關度分數（名稱完全匹配 > 部分匹配 > 別名匹配）
        CASE
            WHEN search_query IS NOT NULL AND search_query != '' THEN
                CASE
                    WHEN LOWER(e.name) = LOWER(search_query) THEN 100.0
                    WHEN LOWER(e.name_en) = LOWER(search_query) THEN 95.0
                    WHEN LOWER(e.canonical_name) = LOWER(search_query) THEN 90.0
                    WHEN e.name ILIKE search_query || '%' THEN 80.0
                    WHEN e.name ILIKE '%' || search_query || '%' THEN 60.0
                    ELSE 40.0
                END
            ELSE 50.0
        END::FLOAT AS relevance_score
    FROM exercises e
    WHERE e.id IN (SELECT eid FROM matched_exercises)
    ORDER BY relevance_score DESC, e.name
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql STABLE;

-- 4.2 建立 exercises 表的 GIN 索引（加速陣列查詢）
CREATE INDEX IF NOT EXISTS idx_exercises_movement_patterns
    ON exercises USING GIN (movement_patterns);
CREATE INDEX IF NOT EXISTS idx_exercises_ppl_tags
    ON exercises USING GIN (ppl_tags);
CREATE INDEX IF NOT EXISTS idx_exercises_synergist_muscles
    ON exercises USING GIN (synergist_muscles);
CREATE INDEX IF NOT EXISTS idx_exercises_primary_muscle
    ON exercises (primary_muscle);
CREATE INDEX IF NOT EXISTS idx_exercises_is_explosive
    ON exercises (is_explosive) WHERE is_explosive = TRUE;
CREATE INDEX IF NOT EXISTS idx_exercises_difficulty_level
    ON exercises (difficulty_level);

-- ============================================================================
-- PART 5: 驗證
-- ============================================================================

DO $$
BEGIN
    -- 驗證新欄位
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'exercises' AND column_name = 'movement_patterns'
    ) THEN
        RAISE EXCEPTION 'Migration failed: movement_patterns column not created';
    END IF;

    -- 驗證別名表
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'exercise_aliases'
    ) THEN
        RAISE EXCEPTION 'Migration failed: exercise_aliases table not created';
    END IF;

    -- 驗證參照表
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'ref_movement_patterns'
    ) THEN
        RAISE EXCEPTION 'Migration failed: ref_movement_patterns table not created';
    END IF;

    RAISE NOTICE '✅ Migration 24_v5_exercise_classification_v2.sql 執行完成';
    RAISE NOTICE '  - exercises 表已新增 v2 欄位';
    RAISE NOTICE '  - exercise_aliases 表已建立';
    RAISE NOTICE '  - ref_movement_patterns, ref_muscle_groups, ref_equipment 表已建立';
    RAISE NOTICE '  - search_exercises_v2() RPC 函數已建立';
    RAISE NOTICE '  - GIN 索引已建立';
END $$;
