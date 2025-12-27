  -- ============================================================================
  -- StrengthWise - Phase 2 效能優化：全文搜尋優化
  -- ============================================================================
  -- 建立時間：2024-12-27
  -- 目標：搜尋效能提升 70-90%，支援繁體中文全文搜尋
  -- 預期效益：
  --   - pgroonga: 繁體中文搜尋效能提升 85-95%
  --   - 全文搜尋索引：搜尋延遲從 500ms-2s 降至 <50ms
  --   - 智能搜尋函式：統一搜尋入口，支援中英文混合
  -- ============================================================================

  -- ============================================================================
  -- 1. 安裝 pgroonga 擴展（繁體中文支援）
  -- ============================================================================

  -- ⚠️ 注意：pgroonga 需要先在 Supabase Dashboard 中啟用
  -- 路徑：Database → Extensions → 搜尋 "pgroonga" → 點擊 Enable

  CREATE EXTENSION IF NOT EXISTS pgroonga;

  -- 驗證擴展
  DO $$
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgroonga') THEN
      RAISE EXCEPTION 'pgroonga 擴展未安裝！請先在 Supabase Dashboard 中啟用。';
    ELSE
      RAISE NOTICE 'pgroonga 擴展已成功安裝 ✓';
    END IF;
  END $$;

  -- ============================================================================
  -- 2. exercises 表全文搜尋索引
  -- ============================================================================

  -- 中文動作名稱搜尋（使用 pgroonga）
  CREATE INDEX IF NOT EXISTS idx_exercises_name_pgroonga 
  ON exercises USING pgroonga (name pgroonga_text_term_search_ops_v2);

  -- 英文動作名稱搜尋（使用 pgroonga）
  CREATE INDEX IF NOT EXISTS idx_exercises_name_en_pgroonga 
  ON exercises USING pgroonga (name_en pgroonga_text_term_search_ops_v2);

  -- 複合全文搜尋索引（中英文混合搜尋）
  CREATE INDEX IF NOT EXISTS idx_exercises_fulltext_combined 
  ON exercises USING pgroonga (
    (name || ' ' || COALESCE(name_en, '')) 
    pgroonga_text_term_search_ops_v2
  );

  -- 動作描述搜尋（較低優先級，但仍有用）
  CREATE INDEX IF NOT EXISTS idx_exercises_description_pgroonga 
  ON exercises USING pgroonga (description pgroonga_text_full_text_search_ops_v2)
  WHERE description IS NOT NULL AND description != '';

  DO $$ BEGIN
    RAISE NOTICE 'exercises 表全文搜尋索引建立完成 ✓';
  END $$;

  -- ============================================================================
  -- 3. custom_exercises 表全文搜尋索引
  -- ============================================================================

  -- 自訂動作名稱搜尋
  CREATE INDEX IF NOT EXISTS idx_custom_exercises_name_pgroonga 
  ON custom_exercises USING pgroonga (name pgroonga_text_term_search_ops_v2);

  -- 自訂動作描述搜尋
  CREATE INDEX IF NOT EXISTS idx_custom_exercises_description_pgroonga 
  ON custom_exercises USING pgroonga (description pgroonga_text_full_text_search_ops_v2)
  WHERE description IS NOT NULL AND description != '';

  DO $$ BEGIN
    RAISE NOTICE 'custom_exercises 表全文搜尋索引建立完成 ✓';
  END $$;

  -- ============================================================================
  -- 4. workout_plans 表 JSONB 全文搜尋（實驗性）
  -- ============================================================================

  -- 訓練計劃標題搜尋
  CREATE INDEX IF NOT EXISTS idx_workout_plans_title_pgroonga 
  ON workout_plans USING pgroonga (title pgroonga_text_term_search_ops_v2);

  -- 訓練計劃筆記搜尋
  CREATE INDEX IF NOT EXISTS idx_workout_plans_note_pgroonga 
  ON workout_plans USING pgroonga (note pgroonga_text_full_text_search_ops_v2)
  WHERE note IS NOT NULL AND note != '';

  DO $$ BEGIN
    RAISE NOTICE 'workout_plans 表全文搜尋索引建立完成 ✓';
  END $$;

  -- ============================================================================
  -- 5. 智能搜尋函式：search_exercises()
  -- ============================================================================

  -- 統一搜尋入口，支援中英文混合、模糊搜尋、多條件過濾
  CREATE OR REPLACE FUNCTION search_exercises(
    search_query TEXT,
    training_type_filter TEXT DEFAULT NULL,
    body_part_filter TEXT DEFAULT NULL,
    limit_count INT DEFAULT 50
  )
  RETURNS TABLE (
    id TEXT,
    name TEXT,
    name_en TEXT,
    body_part TEXT,
    training_type TEXT,
    equipment TEXT,
    description TEXT,
    relevance_score FLOAT
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
      e.description,
      -- 相關度評分（基於 pgroonga 的相似度）
      pgroonga_score(tableoid, ctid)::FLOAT AS relevance_score
    FROM exercises e
    WHERE 
      -- 全文搜尋條件（中英文混合）
      (e.name &@~ search_query OR e.name_en &@~ search_query)
      -- 訓練類型過濾
      AND (training_type_filter IS NULL OR e.training_type = training_type_filter)
      -- 身體部位過濾
      AND (body_part_filter IS NULL OR e.body_part = body_part_filter)
    ORDER BY relevance_score DESC
    LIMIT limit_count;
  END;
  $$ LANGUAGE plpgsql STABLE;

  DO $$ BEGIN
    RAISE NOTICE '智能搜尋函式 search_exercises() 建立完成 ✓';
  END $$;

  -- ============================================================================
  -- 6. 自訂動作搜尋函式：search_custom_exercises()
  -- ============================================================================

  CREATE OR REPLACE FUNCTION search_custom_exercises(
    user_id_param UUID,
    search_query TEXT,
    training_type_filter TEXT DEFAULT NULL,
    limit_count INT DEFAULT 20
  )
  RETURNS TABLE (
    id TEXT,
    name TEXT,
    body_part TEXT,
    training_type TEXT,
    equipment TEXT,
    description TEXT,
    relevance_score FLOAT
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
      pgroonga_score(tableoid, ctid)::FLOAT AS relevance_score
    FROM custom_exercises ce
    WHERE 
      ce.user_id = user_id_param
      AND (ce.name &@~ search_query)
      AND (training_type_filter IS NULL OR ce.training_type = training_type_filter)
    ORDER BY relevance_score DESC
    LIMIT limit_count;
  END;
  $$ LANGUAGE plpgsql STABLE;

  DO $$ BEGIN
    RAISE NOTICE '自訂動作搜尋函式 search_custom_exercises() 建立完成 ✓';
  END $$;

  -- ============================================================================
  -- 7. 統一搜尋函式：search_all_exercises()（系統 + 自訂）
  -- ============================================================================

  CREATE OR REPLACE FUNCTION search_all_exercises(
    user_id_param UUID,
    search_query TEXT,
    training_type_filter TEXT DEFAULT NULL,
    body_part_filter TEXT DEFAULT NULL,
    limit_count INT DEFAULT 50
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
      AND (training_type_filter IS NULL OR e.training_type = training_type_filter)
      AND (body_part_filter IS NULL OR e.body_part = body_part_filter)
    
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
      AND (training_type_filter IS NULL OR ce.training_type = training_type_filter)
      AND (body_part_filter IS NULL OR ce.body_part = body_part_filter)
    
    ORDER BY relevance_score DESC
    LIMIT limit_count;
  END;
  $$ LANGUAGE plpgsql STABLE;

  DO $$ BEGIN
    RAISE NOTICE '統一搜尋函式 search_all_exercises() 建立完成 ✓';
  END $$;

  -- ============================================================================
  -- 8. 測試與驗證
  -- ============================================================================

  -- 測試 1：繁體中文搜尋
  DO $$
  DECLARE
    test_count INT;
  BEGIN
    SELECT COUNT(*) INTO test_count
    FROM search_exercises('深蹲');
    
    IF test_count > 0 THEN
      RAISE NOTICE '✓ 繁體中文搜尋測試通過（找到 % 個結果）', test_count;
    ELSE
      RAISE WARNING '⚠ 繁體中文搜尋測試失敗（無結果）';
    END IF;
  END $$;

  -- 測試 2：英文搜尋
  DO $$
  DECLARE
    test_count INT;
  BEGIN
    SELECT COUNT(*) INTO test_count
    FROM search_exercises('squat');
    
    IF test_count > 0 THEN
      RAISE NOTICE '✓ 英文搜尋測試通過（找到 % 個結果）', test_count;
    ELSE
      RAISE WARNING '⚠ 英文搜尋測試失敗（無結果）';
    END IF;
  END $$;

  -- 測試 3：混合搜尋
  DO $$
  DECLARE
    test_count INT;
  BEGIN
    SELECT COUNT(*) INTO test_count
    FROM search_exercises('臥推 bench');
    
    IF test_count > 0 THEN
      RAISE NOTICE '✓ 中英混合搜尋測試通過（找到 % 個結果）', test_count;
    ELSE
      RAISE WARNING '⚠ 中英混合搜尋測試失敗（無結果）';
    END IF;
  END $$;

  -- ============================================================================
  -- 9. 索引使用統計視圖
  -- ============================================================================

  CREATE OR REPLACE VIEW v_fulltext_search_stats AS
  SELECT 
    schemaname,
    relname AS tablename,
    indexrelname AS indexname,
    idx_scan AS search_count,
    idx_tup_read AS rows_read,
    idx_tup_fetch AS rows_fetched,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
  FROM pg_stat_user_indexes
  WHERE indexrelname LIKE '%pgroonga%'
  ORDER BY idx_scan DESC;

  DO $$ BEGIN
    RAISE NOTICE '索引使用統計視圖 v_fulltext_search_stats 建立完成 ✓';
  END $$;

-- ============================================================================
-- ✅ Phase 2 完成
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Phase 2 全文搜尋優化完成！';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '已建立：';
  RAISE NOTICE '  - 8 個 pgroonga 全文搜尋索引';
  RAISE NOTICE '  - 3 個智能搜尋函式';
  RAISE NOTICE '  - 1 個索引統計視圖';
  RAISE NOTICE '';
  RAISE NOTICE '測試指令：';
  RAISE NOTICE '  SELECT * FROM search_exercises(''深蹲'');';
  RAISE NOTICE '  SELECT * FROM search_exercises(''squat'');';
  RAISE NOTICE '  SELECT * FROM v_fulltext_search_stats;';
  RAISE NOTICE '';
  RAISE NOTICE '預期效益：';
  RAISE NOTICE '  - 搜尋延遲：500ms-2s → <50ms（提升 90%%+）';
  RAISE NOTICE '  - 支援繁體中文、英文、混合搜尋';
  RAISE NOTICE '  - 相關度排序';
  RAISE NOTICE '';
END $$;

