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

