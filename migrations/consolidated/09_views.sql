-- ============================================================================
-- Views（視圖）
-- 導出時間：2026-01-12 19:57:14
-- ============================================================================

-- ============================================================================
-- VIEW: personal_records_top_by_body_part
-- ============================================================================
CREATE OR REPLACE VIEW personal_records_top_by_body_part AS
 SELECT DISTINCT ON (user_id, body_part) id,
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
  ORDER BY user_id, body_part, max_weight DESC;;

-- ============================================================================
-- VIEW: v_fulltext_search_stats
-- ============================================================================
CREATE OR REPLACE VIEW v_fulltext_search_stats AS
 SELECT schemaname,
    relname AS tablename,
    indexrelname AS indexname,
    idx_scan AS search_count,
    idx_tup_read AS rows_read,
    idx_tup_fetch AS rows_fetched,
    pg_size_pretty(pg_relation_size(indexrelid::regclass)) AS index_size
   FROM pg_stat_user_indexes
  WHERE indexrelname ~~ '%pgroonga%'::text
  ORDER BY idx_scan DESC;;

-- ============================================================================
-- VIEW: v_index_usage_stats
-- ============================================================================
CREATE OR REPLACE VIEW v_index_usage_stats AS
 SELECT schemaname,
    relname AS tablename,
    indexrelname AS indexname,
    idx_scan AS scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched,
    pg_size_pretty(pg_relation_size(indexrelid::regclass)) AS index_size
   FROM pg_stat_user_indexes
  ORDER BY idx_scan DESC;;

-- ============================================================================
-- VIEW: v_training_frequency
-- ============================================================================
CREATE OR REPLACE VIEW v_training_frequency AS
 SELECT user_id,
    date_trunc('week'::text, date::timestamp with time zone) AS week_start,
    count(*) AS training_days,
    sum(workout_count) AS total_workouts,
    sum(total_volume) AS total_volume,
    avg(total_volume) AS avg_daily_volume
   FROM daily_workout_summary
  WHERE date >= (CURRENT_DATE - '90 days'::interval)
  GROUP BY user_id, (date_trunc('week'::text, date::timestamp with time zone))
  ORDER BY user_id, (date_trunc('week'::text, date::timestamp with time zone)) DESC;;
