-- =====================================================
-- StrengthWise v1.0 - 功能增強與優化
-- =====================================================
-- 合併自: 012, 015, 016, 017, 018, 019, 020
-- 最後更新: 2025-01-01
-- 
-- 包含:
-- 1. custom_exercises 欄位擴展 (012, 016)
-- 2. 索引優化 Phase 1 (015)
-- 3. Body Part 修正 (017)
-- 4. pgroonga 全文搜尋 (018, 020)
-- 5. Body Part View (019)
-- =====================================================

-- PART 1: custom_exercises 增加欄位 (來自 012)
-- ============================================================
-- StrengthWise - 創建 custom_exercises 表格
-- 用戶自訂動作功能
-- ============================================================
-- 
-- 功能需求：
-- 1. 用戶可以創建自己的動作
-- 2. 可以按身體部位統計（胸/背/腿/肩/手臂/核心）
-- 3. 可以追蹤力量進步（通過 workout_plans 記錄）
-- 4. 可以設定器材類型
-- 
-- 設計原則：
-- - 使用 TEXT ID（與 exercises 表格一致）
-- - 欄位設計與 exercises 表格相容（便於統計時合併查詢）
-- - 簡化欄位（只保留必要的統計欄位）
-- ============================================================

-- 創建 custom_exercises 表格
CREATE TABLE IF NOT EXISTS custom_exercises (
  -- 基本欄位
  id TEXT PRIMARY KEY,                    -- Firestore 相容 ID（20 字符）
  user_id UUID NOT NULL,                  -- 創建者 ID（必須）
  name TEXT NOT NULL,                     -- 動作名稱（必須）
  
  -- 分類欄位（用於統計）
  body_part TEXT NOT NULL,                -- 身體部位：胸部/背部/腿部/肩部/手臂/核心
  equipment TEXT DEFAULT '徒手',          -- 器材：徒手/啞鈴/槓鈴/機械/Cable/其他
  
  -- 詳細資訊（選填）
  description TEXT DEFAULT '',            -- 動作說明
  notes TEXT DEFAULT '',                  -- 個人筆記
  
  -- 時間戳記
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 外鍵約束
  CONSTRAINT fk_custom_exercises_user FOREIGN KEY (user_id) 
    REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- 索引：提升查詢效能
-- ============================================================

-- 按用戶查詢（最常用）
CREATE INDEX IF NOT EXISTS idx_custom_exercises_user_id 
  ON custom_exercises(user_id);

-- 按身體部位查詢（用於統計）
CREATE INDEX IF NOT EXISTS idx_custom_exercises_body_part 
  ON custom_exercises(body_part);

-- 按用戶+身體部位查詢（用於分類統計）
CREATE INDEX IF NOT EXISTS idx_custom_exercises_user_body_part 
  ON custom_exercises(user_id, body_part);

-- 按用戶+器材查詢
CREATE INDEX IF NOT EXISTS idx_custom_exercises_user_equipment 
  ON custom_exercises(user_id, equipment);

-- 全文搜尋索引（用於動作名稱搜尋）
CREATE INDEX IF NOT EXISTS idx_custom_exercises_name_trgm 
  ON custom_exercises USING gin(name gin_trgm_ops);

-- ============================================================
-- Row Level Security (RLS) 策略
-- ============================================================

-- 啟用 RLS
ALTER TABLE custom_exercises ENABLE ROW LEVEL SECURITY;

-- 策略 1：用戶只能查看自己的自訂動作
CREATE POLICY "Users can view own custom exercises"
  ON custom_exercises FOR SELECT
  USING (auth.uid() = user_id);

-- 策略 2：用戶只能創建自己的自訂動作
CREATE POLICY "Users can create own custom exercises"
  ON custom_exercises FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 策略 3：用戶只能更新自己的自訂動作
CREATE POLICY "Users can update own custom exercises"
  ON custom_exercises FOR UPDATE
  USING (auth.uid() = user_id);

-- 策略 4：用戶只能刪除自己的自訂動作
CREATE POLICY "Users can delete own custom exercises"
  ON custom_exercises FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 註解
-- ============================================================

COMMENT ON TABLE custom_exercises IS '用戶自訂動作表格（可統計、可追蹤力量進步）';
COMMENT ON COLUMN custom_exercises.id IS 'Firestore 相容 ID（20 字符隨機字串）';
COMMENT ON COLUMN custom_exercises.user_id IS '創建者 ID（UUID）';
COMMENT ON COLUMN custom_exercises.name IS '動作名稱（例如：我的深蹲變化式）';
COMMENT ON COLUMN custom_exercises.body_part IS '身體部位：胸部/背部/腿部/肩部/手臂/核心';
COMMENT ON COLUMN custom_exercises.equipment IS '器材：徒手/啞鈴/槓鈴/機械/Cable/其他';

-- ============================================================
-- 觸發器：自動更新 updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_custom_exercises_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_custom_exercises_updated_at
  BEFORE UPDATE ON custom_exercises
  FOR EACH ROW
  EXECUTE FUNCTION update_custom_exercises_updated_at();

-- ============================================================
-- 驗證
-- ============================================================

-- 檢查表格是否創建成功
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'custom_exercises'
  ) THEN
    RAISE NOTICE '✅ custom_exercises 表格創建成功';
  ELSE
    RAISE EXCEPTION '❌ custom_exercises 表格創建失敗';
  END IF;
END $$;

-- 檢查索引數量
DO $$
DECLARE
  index_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO index_count
  FROM pg_indexes
  WHERE tablename = 'custom_exercises';
  
  RAISE NOTICE '✅ 創建了 % 個索引', index_count;
END $$;

-- 檢查 RLS 是否啟用
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'custom_exercises' 
    AND rowsecurity = true
  ) THEN
    RAISE NOTICE '✅ Row Level Security 已啟用';
  ELSE
    RAISE WARNING '⚠️  Row Level Security 未啟用';
  END IF;
END $$;

-- =====================================================
-- PART 2: 索引優化 Phase 1 (來自 015)
-- =====================================================

-- ============================================================================
-- StrengthWise - Phase 1 效能優化：索引建立
-- ============================================================================
-- 建立時間：2024-12-27
-- 目標：查詢效能提升 70-90%
-- 預期效益：
--   - 覆蓋索引：減少隨機 I/O 90%+，速度提升 3-5x
--   - 部分索引：微秒級查詢，不受歷史數據量影響
--   - GIN 索引優化：體積減少 50%，速度提升 2-3x
-- 
-- 修正記錄：
--   - 2024-12-27: 修正 body_fat 欄位名稱（不是 body_fat_percentage）
--   - 2024-12-27: 移除動態日期索引（CURRENT_DATE 不是 IMMUTABLE）
-- ============================================================================

-- ============================================================================
-- 1. 覆蓋索引（Covering Indexes）- Index-Only Scan
-- ============================================================================

-- 訓練計劃：受訓者查詢（最高頻）
CREATE INDEX IF NOT EXISTS idx_workout_plans_trainee_covering 
ON workout_plans (trainee_id, scheduled_date DESC) 
INCLUDE (title, completed, total_volume, total_exercises, total_sets, plan_type);

-- 訓練計劃：創建者查詢（教練模式）
CREATE INDEX IF NOT EXISTS idx_workout_plans_creator_covering 
ON workout_plans (creator_id, scheduled_date DESC) 
INCLUDE (trainee_id, title, completed, total_exercises);

-- 訓練模板：使用者查詢
CREATE INDEX IF NOT EXISTS idx_workout_templates_user_covering 
ON workout_templates (user_id, updated_at DESC) 
INCLUDE (title, description, plan_type, training_time);

-- 身體數據：使用者時間序列查詢
CREATE INDEX IF NOT EXISTS idx_body_data_user_date_covering 
ON body_data (user_id, record_date DESC) 
INCLUDE (weight, body_fat, muscle_mass, bmi);

-- 筆記：使用者時間序列查詢
CREATE INDEX IF NOT EXISTS idx_notes_user_covering 
ON notes (user_id, updated_at DESC) 
INCLUDE (title, text_content);

-- 自訂動作：使用者查詢
CREATE INDEX IF NOT EXISTS idx_custom_exercises_user_covering 
ON custom_exercises (user_id, created_at DESC) 
INCLUDE (name, body_part, equipment, description);

-- 動作：訓練類型查詢
CREATE INDEX IF NOT EXISTS idx_exercises_training_type_covering 
ON exercises (training_type, body_part) 
INCLUDE (name, name_en, equipment, equipment_category);

-- ============================================================================
-- 2. 部分索引（Partial Indexes）- 高頻小數據集
-- ============================================================================

-- 未完成訓練（高頻查詢，小數據集）
CREATE INDEX IF NOT EXISTS idx_workout_plans_pending_partial 
ON workout_plans (trainee_id, scheduled_date DESC) 
WHERE completed = false;

-- 注意：移除了動態日期索引（CURRENT_DATE 不是 IMMUTABLE 函數）
-- 今日訓練查詢可使用 pending 索引 + 應用層日期過濾

-- ============================================================================
-- 3. GIN 索引優化（JSONB）
-- ============================================================================

-- 訓練計劃的動作陣列（使用 jsonb_path_ops，體積減少 50%）
CREATE INDEX IF NOT EXISTS idx_workout_plans_exercises_gin 
ON workout_plans 
USING GIN (exercises jsonb_path_ops);

-- 訓練模板的動作陣列
CREATE INDEX IF NOT EXISTS idx_workout_templates_exercises_gin 
ON workout_templates 
USING GIN (exercises jsonb_path_ops);

-- 筆記的繪圖數據（如果需要查詢）
CREATE INDEX IF NOT EXISTS idx_notes_drawing_points_gin 
ON notes 
USING GIN (drawing_points jsonb_path_ops);

-- ============================================================================
-- 4. 索引維護與監控
-- ============================================================================

-- 查看索引使用情況的輔助 View（可選）
CREATE OR REPLACE VIEW v_index_usage_stats AS
SELECT 
  schemaname,
  relname AS tablename,
  indexrelname AS indexname,
  idx_scan AS scans,
  idx_tup_read AS tuples_read,
  idx_tup_fetch AS tuples_fetched,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- ============================================================================
-- 執行後驗證
-- ============================================================================

-- 檢查索引是否成功建立
SELECT 
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND (
    indexname LIKE 'idx_%covering' 
    OR indexname LIKE 'idx_%partial'
    OR indexname LIKE 'idx_%gin'
  )
ORDER BY tablename, indexname;

-- ============================================================================
-- 預期效益說明
-- ============================================================================

/*
1. 覆蓋索引（7 個）：
   - workout_plans（trainee/creator）：列表查詢提升 70-85%
   - workout_templates：模板列表提升 60-80%
   - body_data：身體數據趨勢提升 70-85%
   - notes：筆記列表提升 60-75%
   - custom_exercises：自訂動作列表提升 65-80%
   - exercises：動作篩選提升 60-75%

2. 部分索引（1 個）：
   - pending workouts：未完成訓練查詢 → 微秒級（常駐記憶體）
   
   注意：移除了動態日期索引和預約系統索引
   原因：
   - CURRENT_DATE 不是 IMMUTABLE 函數
   - bookings/available_slots 表格不存在（系統未啟用）

3. GIN 索引（3 個）：
   - exercises JSONB：查詢包含特定動作的訓練 → 提升 50-70%
   - 索引體積減少 50%（使用 jsonb_path_ops）

總體預期：
- 列表頁載入時間：200-300ms → 20-50ms（提升 80-90%）
- 未完成訓練查詢：50-100ms → <5ms（提升 95%+）
- 統計報表查詢：1-2秒 → 100-200ms（提升 85-90%）

實際索引數量：11 個（7 覆蓋 + 1 部分 + 3 GIN）
*/

-- =====================================================
-- PART 3: custom_exercises 增加 training_type (來自 016)
-- =====================================================

-- =====================================================
-- Migration 016: 新增 training_type 到 custom_exercises
-- =====================================================
-- 目的：讓自訂動作也能選擇訓練類型（心肺適能訓練/活動度與伸展/阻力訓練）
-- 並支援雙語系統（中文/英文）
-- 日期：2024-12-27
-- 影響：custom_exercises 表格
-- =====================================================

-- 1. 新增訓練類型欄位（中文 + 英文）
ALTER TABLE custom_exercises 
ADD COLUMN IF NOT EXISTS training_type TEXT DEFAULT '阻力訓練',
ADD COLUMN IF NOT EXISTS training_type_en TEXT DEFAULT 'Resistance Training';

-- 2. 新增身體部位英文欄位
ALTER TABLE custom_exercises 
ADD COLUMN IF NOT EXISTS body_part_en TEXT DEFAULT '';

-- 3. 新增器材英文欄位
ALTER TABLE custom_exercises 
ADD COLUMN IF NOT EXISTS equipment_en TEXT DEFAULT '';

-- 4. 新增註解
COMMENT ON COLUMN custom_exercises.training_type IS '訓練類型（中文）：心肺適能訓練/活動度與伸展/阻力訓練';
COMMENT ON COLUMN custom_exercises.training_type_en IS '訓練類型（英文）：Cardio/Flexibility/Resistance Training';
COMMENT ON COLUMN custom_exercises.body_part_en IS '身體部位（英文）：Chest/Back/Legs/Shoulders/Arms/Core';
COMMENT ON COLUMN custom_exercises.equipment_en IS '器材（英文）：Bodyweight/Dumbbell/Barbell/Machine/Cable/Kettlebell/Resistance Band/Other';

-- 5. 更新現有資料（設定預設值）
UPDATE custom_exercises 
SET training_type = '阻力訓練',
    training_type_en = 'Resistance Training'
WHERE training_type IS NULL;

-- 6. 根據中文身體部位設定英文對應
UPDATE custom_exercises 
SET body_part_en = CASE body_part
    WHEN '胸部' THEN 'Chest'
    WHEN '背部' THEN 'Back'
    WHEN '腿部' THEN 'Legs'
    WHEN '肩部' THEN 'Shoulders'
    WHEN '手臂' THEN 'Arms'
    WHEN '核心' THEN 'Core'
    ELSE 'Other'
END
WHERE body_part_en = '' OR body_part_en IS NULL;

-- 7. 根據中文器材設定英文對應
UPDATE custom_exercises 
SET equipment_en = CASE equipment
    WHEN '徒手' THEN 'Bodyweight'
    WHEN '啞鈴' THEN 'Dumbbell'
    WHEN '槓鈴' THEN 'Barbell'
    WHEN '固定式機械' THEN 'Machine'
    WHEN 'Cable滑輪' THEN 'Cable'
    WHEN '壺鈴' THEN 'Kettlebell'
    WHEN '彈力帶' THEN 'Resistance Band'
    WHEN '其他' THEN 'Other'
    ELSE 'Other'
END
WHERE equipment_en = '' OR equipment_en IS NULL;

-- 8. 驗證
SELECT 
    COUNT(*) as total_custom_exercises,
    COUNT(CASE WHEN training_type IS NOT NULL THEN 1 END) as with_training_type,
    COUNT(CASE WHEN training_type_en IS NOT NULL THEN 1 END) as with_training_type_en,
    COUNT(CASE WHEN body_part_en IS NOT NULL AND body_part_en != '' THEN 1 END) as with_body_part_en,
    COUNT(CASE WHEN equipment_en IS NOT NULL AND equipment_en != '' THEN 1 END) as with_equipment_en
FROM custom_exercises;

-- 預期結果：所有自訂動作都有完整的雙語欄位

-- =====================================================
-- PART 4: 修正心肺/伸展的 Body Part (來自 017)
-- =====================================================

-- =====================================================
-- Migration 017: 修復心肺與伸展動作的 body_part 欄位
-- =====================================================
-- 問題：心肺適能訓練和活動度與伸展動作的 body_part 為空
-- 解決：設置預設值為「全身」
-- =====================================================

-- 1. 檢查哪些訓練類型的動作沒有 body_part
SELECT 
    training_type,
    COUNT(*) as total,
    COUNT(CASE WHEN body_part IS NULL OR body_part = '' THEN 1 END) as without_body_part
FROM exercises
GROUP BY training_type
ORDER BY training_type;

-- 2. 為心肺適能訓練設置預設 body_part
UPDATE exercises
SET body_part = '全身'
WHERE training_type = '心肺適能訓練'
  AND (body_part IS NULL OR body_part = '');

-- 3. 為活動度與伸展設置預設 body_part
UPDATE exercises
SET body_part = '全身'
WHERE training_type = '活動度與伸展'
  AND (body_part IS NULL OR body_part = '');

-- 4. 驗證修復結果
SELECT 
    training_type,
    COUNT(*) as total,
    COUNT(CASE WHEN body_part IS NOT NULL AND body_part != '' THEN 1 END) as with_body_part
FROM exercises
GROUP BY training_type
ORDER BY training_type;

-- 5. 顯示範例
SELECT name, training_type, body_part 
FROM exercises 
WHERE training_type IN ('心肺適能訓練', '活動度與伸展')
LIMIT 10;

-- =====================================================
-- PART 5: pgroonga 全文搜尋 Phase 2 (來自 018)
-- =====================================================

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

-- =====================================================
-- PART 6: Body Part View (來自 019)
-- =====================================================

-- ============================================================================
-- 補充修改：添加 body_part 欄位和 View（2025-12-29）
-- 此文件包含對 019_performance_optimization_phase3_stats_summary.sql 的補充修改
-- ============================================================================

-- ============================================================================
-- 1. 添加 body_part 欄位到 personal_records
-- ============================================================================

ALTER TABLE personal_records
ADD COLUMN IF NOT EXISTS body_part TEXT;

-- 創建索引（加速查詢）
CREATE INDEX IF NOT EXISTS idx_personal_records_body_part 
ON personal_records(user_id, body_part);

-- 更新現有記錄的 body_part（從 exercises 或 custom_exercises 獲取）
UPDATE personal_records pr
SET body_part = COALESCE(
  (SELECT e.body_part FROM exercises e WHERE e.id = pr.exercise_id),
  (SELECT ce.body_part FROM custom_exercises ce WHERE ce.id = pr.exercise_id)
);

DO $$ BEGIN
  RAISE NOTICE 'personal_records.body_part 欄位添加完成 ✓';
END $$;

-- ============================================================================
-- 2. 創建 View：每個部位最大重量記錄
-- 
-- 目的：自動過濾出每個身體部位（胸、背、腿、肩、手）中重量最大的記錄
-- 使用：App 查詢時使用此 View 替代 personal_records 表
-- ============================================================================

CREATE OR REPLACE VIEW personal_records_top_by_body_part AS
SELECT DISTINCT ON (user_id, body_part)
  id,
  user_id,
  exercise_id,
  exercise_name,
  max_weight,
  max_reps,
  max_volume,
  achieved_date,
  workout_plan_id,
  body_part,
  created_at,
  updated_at
FROM personal_records
WHERE body_part IS NOT NULL
ORDER BY user_id, body_part, max_weight DESC;

-- 授予權限
GRANT SELECT ON personal_records_top_by_body_part TO authenticated;
GRANT SELECT ON personal_records_top_by_body_part TO anon;

DO $$ BEGIN
  RAISE NOTICE 'View personal_records_top_by_body_part 建立完成 ✓';
  RAISE NOTICE '  - 每個部位只返回最大重量的記錄';
  RAISE NOTICE '  - 適用於統計頁面的個人最佳記錄顯示';
END $$;

-- ============================================================================
-- 3. 測試查詢
-- ============================================================================

-- 測試：查詢每個部位的最大記錄（應該返回 5 筆）
-- SELECT 
--   body_part,
--   exercise_name,
--   max_weight,
--   max_reps,
--   achieved_date
-- FROM personal_records_top_by_body_part
-- WHERE user_id = 'your_user_id'
-- ORDER BY body_part;

-- =====================================================
-- PART 7: 修正 pgroonga 函數名 (來自 020)
-- =====================================================

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

-- =====================================================
-- 完成訊息
-- =====================================================
DO $$
BEGIN
  RAISE NOTICE '✅ v1.0 功能增強與優化完成！';
  RAISE NOTICE '   - custom_exercises 欄位擴展';
  RAISE NOTICE '   - 索引優化';
  RAISE NOTICE '   - pgroonga 全文搜尋';
  RAISE NOTICE '   - Body Part View';
END $$;
