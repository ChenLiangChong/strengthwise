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

