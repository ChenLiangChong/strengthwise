-- ============================================================================
-- StrengthWise Migration: 21_v3_tracking_mode.sql
-- ============================================================================
-- 合併自: 044_tracking_mode.sql, 044b_tracking_mode_manual.sql, 
--        045_search_tracking_mode.sql
-- 版本: v3.2+
-- 日期: 2026-01-12
-- ============================================================================
-- 
-- 包含:
-- 1. exercises/custom_exercises 新增 tracking_mode 欄位
-- 2. tracking_mode 預設值設定
-- 3. 搜尋函數更新（包含 tracking_mode）
-- ============================================================================

-- ============================================================================
-- PART 1: exercises 表新增 tracking_mode 欄位
-- ============================================================================

ALTER TABLE exercises 
ADD COLUMN IF NOT EXISTS tracking_mode TEXT DEFAULT 'weight_reps';

COMMENT ON COLUMN exercises.tracking_mode IS 
'追蹤模式：weight_reps/weight_time/reps_only/time_only/reps_time/distance_time/distance_only/calories';

CREATE INDEX IF NOT EXISTS idx_exercises_tracking_mode 
ON exercises(tracking_mode);

-- ============================================================================
-- PART 2: custom_exercises 表新增 tracking_mode 欄位
-- ============================================================================

ALTER TABLE custom_exercises 
ADD COLUMN IF NOT EXISTS tracking_mode TEXT DEFAULT 'weight_reps';

COMMENT ON COLUMN custom_exercises.tracking_mode IS 
'追蹤模式：weight_reps/weight_time/reps_only/time_only/reps_time/distance_time/distance_only/calories';

CREATE INDEX IF NOT EXISTS idx_custom_exercises_tracking_mode 
ON custom_exercises(tracking_mode);

-- ============================================================================
-- PART 3: 更新現有動作的 tracking_mode
-- ============================================================================

-- 心肺適能訓練 → distance_time
UPDATE exercises 
SET tracking_mode = 'distance_time'
WHERE training_type = '心肺適能訓練'
  AND (tracking_mode IS NULL OR tracking_mode = 'weight_reps');

-- 活動度與伸展 → time_only
UPDATE exercises 
SET tracking_mode = 'time_only'
WHERE training_type = '活動度與伸展'
  AND (tracking_mode IS NULL OR tracking_mode = 'weight_reps');

-- 阻力訓練保持 weight_reps
UPDATE exercises 
SET tracking_mode = 'weight_reps'
WHERE tracking_mode IS NULL;

-- 自訂動作設定預設值
UPDATE custom_exercises 
SET tracking_mode = 'weight_reps'
WHERE tracking_mode IS NULL;

-- ============================================================================
-- PART 4: 手動設定特定動作（來自 044b）
-- ============================================================================

-- calories: 1 個動作
UPDATE exercises SET tracking_mode = 'calories' WHERE id IN ('T8ZdklS0Acfw0cffrLue');

-- distance_time: 6 個動作
UPDATE exercises SET tracking_mode = 'distance_time' WHERE id IN ('yRDbJbJfCcYMIVAcFxqC', 'YGk22Ck9WigYaGrEpLoN', '0mwjK0S7F6EV8PC9Ohj6', 'yfZnBreHL5pf1jMyBAPa', 'Kao6qgQ9KoGXuZOxOK7X', 'CrPGoUkHbnkfqn0gYC4a');

-- reps_only: 7 個動作
UPDATE exercises SET tracking_mode = 'reps_only' WHERE id IN ('eeLwxu5ezkMBpyEJdSMB', 'K9Q4WAM7wgCT7YaaK9Ss', 'LnbmMVbWMmHnxtdHS3me', 'i76EufqlOOoVXzTSYkfo', 'bpR31H1Nb0uzhtKeRFrI', 'md0PfFEskJdPPjAqh6Qf', 'TEPpYv5OzBVoH8gvPcsh');

-- reps_time: 30 個動作
UPDATE exercises SET tracking_mode = 'reps_time' WHERE id IN ('VrcppDYPkUbY0JEblH0K', '7UemmcAgteYtVPs7DevN', 'L6h1rWAmj5Gnw39z84Dc', '1P9tu2NHGF5g8CaqDQ51', '4Heh4sIQNoF3ey80W7yG', 'N8bUPRj0SwwFUEKRt5ip', 'zYo7sr8m5s0hXLwKPJJV', 'YvoiJxA37vqymV53J9LL', 'b7g9tPXJIMszVFDuBON1', 'uMfzQRdFiER7H04AnK5I', 'bCJ9LqBuNEGalKZjAxxG', 'MheifPWSVPyL6tkrDJeq', '9dD9QZSooQoQlYTzQ4bh', 'eZhpfwO3r4h8Bh0ekS5F', 'IL7eohuPjoyBACg7aoUm', 'WMztpPrBtEcjzHDHW5sB', 'QMQf1gjVqKchXPTK4xiw', 'RmTeaBVOmFp2sX9FNzM4', '7E0NiWEExkkj7HGYCNyx', 'QiKIAdJ1trGEYHsmJvXn', 'RVdSbGax8QQlYagyu23v', 'qqYdQ40scYpuYvIhlCNB', 'ae56ikNoQ0LdxD6EVz9Y', 'qfDpGK0YksOcjPbWOZow', 'qfXjlwagzxuQGsRAkM0d', 'ppOE2s7BH5i7C6KfpXKm', 'btXldJ9MiE6AkH9dFQdj', 'HIxJvtHCyoKtHQeyYRbL', 'U5hlYjuGdKRBFOccmHus', 'y14vRYRb2M6f8Dne9W9j');

-- time_only: 2 個動作
UPDATE exercises SET tracking_mode = 'time_only' WHERE id IN ('u1w8DyUEKppzOrUZsOaT', 'w9dMH2z3EjjRFZ1zC4RM');

-- weight_time: 4 個動作
UPDATE exercises SET tracking_mode = 'weight_time' WHERE id IN ('kvk1vyp2qYvcMPfrzUT8', 'vhvHLd6BFu561MuRogQg', 'LKaYRSShFpTVC4SgHXCD', 'K4mqZDi4YEfL8N2RlwC3');

-- ============================================================================
-- PART 5: 更新搜尋函數
-- ============================================================================

-- 系統動作搜尋
CREATE OR REPLACE FUNCTION search_exercises_pgroonga(
  search_query TEXT,
  max_results INT DEFAULT 20
)
RETURNS TABLE (
  id TEXT, name TEXT, name_en TEXT, body_part TEXT, training_type TEXT,
  equipment TEXT, equipment_category TEXT, equipment_subcategory TEXT,
  joint_type TEXT, level1 TEXT, level2 TEXT, level3 TEXT, level4 TEXT, level5 TEXT,
  action_name TEXT, description TEXT, image_url TEXT, video_url TEXT,
  body_parts TEXT[], apps TEXT[], created_at TIMESTAMPTZ,
  specific_muscle TEXT, tracking_mode TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id, e.name, e.name_en, e.body_part, e.training_type,
    e.equipment, e.equipment_category, e.equipment_subcategory,
    e.joint_type, e.level1, e.level2, e.level3, e.level4, e.level5,
    e.action_name, e.description, e.image_url, e.video_url,
    e.body_parts, e.apps, e.created_at,
    e.specific_muscle, e.tracking_mode
  FROM exercises e
  WHERE (e.name &@~ search_query OR e.name_en &@~ search_query)
  ORDER BY pgroonga_score(tableoid, ctid) DESC, e.name ASC
  LIMIT max_results;
END;
$$ LANGUAGE plpgsql STABLE;

-- 自訂動作搜尋
CREATE OR REPLACE FUNCTION search_custom_exercises_pgroonga(
  user_id_param UUID,
  search_query TEXT,
  max_results INT DEFAULT 20
)
RETURNS TABLE (
  id TEXT, name TEXT, body_part TEXT, training_type TEXT, equipment TEXT,
  description TEXT, notes TEXT, created_at TIMESTAMPTZ, user_id UUID, tracking_mode TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ce.id, ce.name, ce.body_part, ce.training_type, ce.equipment,
    ce.description, ce.notes, ce.created_at, ce.user_id, ce.tracking_mode
  FROM custom_exercises ce
  WHERE ce.user_id = user_id_param
    AND (ce.name &@~ search_query OR ce.description &@~ search_query)
  ORDER BY pgroonga_score(tableoid, ctid) DESC, ce.name ASC
  LIMIT max_results;
END;
$$ LANGUAGE plpgsql STABLE;

-- 統一搜尋
CREATE OR REPLACE FUNCTION search_all_exercises_pgroonga(
  user_id_param UUID,
  search_query TEXT,
  max_results INT DEFAULT 20
)
RETURNS TABLE (
  id TEXT, name TEXT, name_en TEXT, body_part TEXT, training_type TEXT,
  equipment TEXT, description TEXT, is_custom BOOLEAN, relevance_score FLOAT, tracking_mode TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id, e.name, e.name_en, e.body_part, e.training_type,
    e.equipment, e.description, FALSE AS is_custom,
    pgroonga_score(tableoid, ctid)::FLOAT AS relevance_score, e.tracking_mode
  FROM exercises e
  WHERE (e.name &@~ search_query OR e.name_en &@~ search_query)
  UNION ALL
  SELECT 
    ce.id, ce.name, NULL AS name_en, ce.body_part, ce.training_type,
    ce.equipment, ce.description, TRUE AS is_custom,
    pgroonga_score(tableoid, ctid)::FLOAT AS relevance_score, ce.tracking_mode
  FROM custom_exercises ce
  WHERE ce.user_id = user_id_param AND (ce.name &@~ search_query)
  ORDER BY relevance_score DESC, name ASC
  LIMIT max_results;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 21 完成：TrackingMode';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '新增欄位：';
  RAISE NOTICE '  ✅ exercises.tracking_mode';
  RAISE NOTICE '  ✅ custom_exercises.tracking_mode';
  RAISE NOTICE '';
  RAISE NOTICE '追蹤模式：';
  RAISE NOTICE '  - weight_reps：重量 × 次數（預設）';
  RAISE NOTICE '  - weight_time：重量 × 時間';
  RAISE NOTICE '  - reps_only：僅次數';
  RAISE NOTICE '  - time_only：僅時間';
  RAISE NOTICE '  - reps_time：次數 × 時間';
  RAISE NOTICE '  - distance_time：距離 + 時間';
  RAISE NOTICE '  - distance_only：僅距離';
  RAISE NOTICE '  - calories：卡路里';
  RAISE NOTICE '';
  RAISE NOTICE '更新函數：';
  RAISE NOTICE '  ✅ search_exercises_pgroonga()';
  RAISE NOTICE '  ✅ search_custom_exercises_pgroonga()';
  RAISE NOTICE '  ✅ search_all_exercises_pgroonga()';
  RAISE NOTICE '';
END $$;
