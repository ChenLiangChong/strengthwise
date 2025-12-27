-- ============================================================================
-- StrengthWise - 修正 pgroonga 搜尋函式名稱
-- ============================================================================
-- 建立時間：2024-12-27
-- 目標：讓 SQL 函式名稱與 Flutter 端調用一致
-- ============================================================================

-- ============================================================================
-- 1. 重命名主搜尋函式：search_exercises → search_exercises_pgroonga
-- ============================================================================

-- 刪除舊的函式
DROP FUNCTION IF EXISTS search_exercises(TEXT, TEXT, TEXT, INT);

-- 創建新的函式（與 Flutter 端一致）
CREATE OR REPLACE FUNCTION search_exercises_pgroonga(
  search_query TEXT,
  max_results INT DEFAULT 20
)
RETURNS TABLE (
  id TEXT,
  name TEXT,
  name_en TEXT,
  body_part TEXT,
  training_type TEXT,
  equipment TEXT,
  equipment_category TEXT,
  equipment_subcategory TEXT,
  joint_type TEXT,
  level1 TEXT,
  level2 TEXT,
  level3 TEXT,
  level4 TEXT,
  level5 TEXT,
  action_name TEXT,
  description TEXT,
  image_url TEXT,
  video_url TEXT,
  body_parts TEXT[],
  apps TEXT[],
  created_at TIMESTAMPTZ,
  specific_muscle TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.name,
    e.name_en,
    e.body_part,
    e.training_type,
    e.equipment,
    e.equipment_category,
    e.equipment_subcategory,
    e.joint_type,
    e.level1,
    e.level2,
    e.level3,
    e.level4,
    e.level5,
    e.action_name,
    e.description,
    e.image_url,
    e.video_url,
    e.body_parts,
    e.apps,
    e.created_at,
    e.specific_muscle
  FROM exercises e
  WHERE 
    -- 使用 pgroonga 全文搜尋（支援中文）
    (e.name &@~ search_query OR e.name_en &@~ search_query)
  ORDER BY 
    -- 按相關度排序（pgroonga 評分）
    pgroonga_score(tableoid, ctid) DESC,
    -- 次要排序：動作名稱
    e.name ASC
  LIMIT max_results;
END;
$$ LANGUAGE plpgsql STABLE;

-- 添加註解
COMMENT ON FUNCTION search_exercises_pgroonga(TEXT, INT) IS 
'使用 pgroonga 搜尋系統動作，支援繁體中文全文搜尋，按相關度排序';

DO $$ BEGIN
  RAISE NOTICE '✅ search_exercises_pgroonga() 函式已更新';
END $$;

-- ============================================================================
-- 2. 創建自訂動作搜尋函式：search_custom_exercises_pgroonga
-- ============================================================================

DROP FUNCTION IF EXISTS search_custom_exercises(UUID, TEXT, TEXT, INT);

CREATE OR REPLACE FUNCTION search_custom_exercises_pgroonga(
  user_id_param UUID,
  search_query TEXT,
  max_results INT DEFAULT 20
)
RETURNS TABLE (
  id TEXT,
  name TEXT,
  body_part TEXT,
  training_type TEXT,
  equipment TEXT,
  description TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ,
  user_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ce.id,
    ce.name,
    ce.body_part,
    ce.training_type,
    ce.equipment,
    ce.description,
    ce.notes,
    ce.created_at,
    ce.user_id
  FROM custom_exercises ce
  WHERE 
    ce.user_id = user_id_param
    AND (ce.name &@~ search_query OR ce.description &@~ search_query)
  ORDER BY 
    pgroonga_score(tableoid, ctid) DESC,
    ce.name ASC
  LIMIT max_results;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION search_custom_exercises_pgroonga(UUID, TEXT, INT) IS 
'使用 pgroonga 搜尋使用者的自訂動作，支援繁體中文全文搜尋';

DO $$ BEGIN
  RAISE NOTICE '✅ search_custom_exercises_pgroonga() 函式已創建';
END $$;

-- ============================================================================
-- 3. 創建統一搜尋函式：search_all_exercises_pgroonga（系統 + 自訂）
-- ============================================================================

DROP FUNCTION IF EXISTS search_all_exercises(UUID, TEXT, TEXT, TEXT, INT);

CREATE OR REPLACE FUNCTION search_all_exercises_pgroonga(
  user_id_param UUID,
  search_query TEXT,
  max_results INT DEFAULT 20
)
RETURNS TABLE (
  id TEXT,
  name TEXT,
  name_en TEXT,
  body_part TEXT,
  training_type TEXT,
  equipment TEXT,
  description TEXT,
  is_custom BOOLEAN,
  relevance_score FLOAT
) AS $$
BEGIN
  RETURN QUERY
  -- 系統動作
  SELECT 
    e.id,
    e.name,
    e.name_en,
    e.body_part,
    e.training_type,
    e.equipment,
    e.description,
    FALSE AS is_custom,
    pgroonga_score(tableoid, ctid)::FLOAT AS relevance_score
  FROM exercises e
  WHERE 
    (e.name &@~ search_query OR e.name_en &@~ search_query)
  
  UNION ALL
  
  -- 自訂動作
  SELECT 
    ce.id,
    ce.name,
    NULL AS name_en,
    ce.body_part,
    ce.training_type,
    ce.equipment,
    ce.description,
    TRUE AS is_custom,
    pgroonga_score(tableoid, ctid)::FLOAT AS relevance_score
  FROM custom_exercises ce
  WHERE 
    ce.user_id = user_id_param
    AND (ce.name &@~ search_query)
  
  ORDER BY relevance_score DESC, name ASC
  LIMIT max_results;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION search_all_exercises_pgroonga(UUID, TEXT, INT) IS 
'統一搜尋系統動作和自訂動作，按相關度排序';

DO $$ BEGIN
  RAISE NOTICE '✅ search_all_exercises_pgroonga() 函式已創建';
END $$;

-- ============================================================================
-- 4. 驗證 pgroonga 擴展狀態
-- ============================================================================

DO $$
DECLARE
  pgroonga_version TEXT;
  index_count INT;
BEGIN
  -- 檢查 pgroonga 擴展
  SELECT extversion INTO pgroonga_version
  FROM pg_extension
  WHERE extname = 'pgroonga';
  
  IF pgroonga_version IS NULL THEN
    RAISE WARNING '⚠️ pgroonga 擴展未安裝！請在 Supabase Dashboard 中啟用。';
  ELSE
    RAISE NOTICE '✅ pgroonga 擴展已安裝，版本: %', pgroonga_version;
  END IF;
  
  -- 統計 pgroonga 索引數量
  SELECT COUNT(*) INTO index_count
  FROM pg_indexes
  WHERE indexdef LIKE '%pgroonga%';
  
  RAISE NOTICE '✅ pgroonga 索引數量: %', index_count;
  
  -- 檢查搜尋函式
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'search_exercises_pgroonga') THEN
    RAISE NOTICE '✅ search_exercises_pgroonga() 函式可用';
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'search_custom_exercises_pgroonga') THEN
    RAISE NOTICE '✅ search_custom_exercises_pgroonga() 函式可用';
  END IF;
  
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'search_all_exercises_pgroonga') THEN
    RAISE NOTICE '✅ search_all_exercises_pgroonga() 函式可用';
  END IF;
  
END $$;

-- ============================================================================
-- 5. 測試搜尋功能
-- ============================================================================

-- 測試系統動作搜尋（中文）
DO $$
DECLARE
  result_count INT;
BEGIN
  SELECT COUNT(*) INTO result_count
  FROM search_exercises_pgroonga('深蹲', 5);
  
  RAISE NOTICE '✅ 搜尋「深蹲」返回 % 個結果', result_count;
END $$;

-- 測試系統動作搜尋（英文）
DO $$
DECLARE
  result_count INT;
BEGIN
  SELECT COUNT(*) INTO result_count
  FROM search_exercises_pgroonga('squat', 5);
  
  RAISE NOTICE '✅ 搜尋「squat」返回 % 個結果', result_count;
END $$;

RAISE NOTICE '========================================';
RAISE NOTICE '✅ pgroonga 搜尋函式修正完成！';
RAISE NOTICE '========================================';
RAISE NOTICE '可用的 RPC 函式：';
RAISE NOTICE '  - search_exercises_pgroonga(query, max_results)';
RAISE NOTICE '  - search_custom_exercises_pgroonga(user_id, query, max_results)';
RAISE NOTICE '  - search_all_exercises_pgroonga(user_id, query, max_results)';
RAISE NOTICE '========================================';

