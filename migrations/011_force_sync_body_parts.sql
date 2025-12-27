-- ============================================================================
-- StrengthWise - 強制同步 body_part → body_parts（修復版）
-- ============================================================================
-- 
-- 問題: 011 的條件太嚴格，body_parts 已有舊值（['腿']）所以沒更新
-- 解決: 無條件更新所有有 body_part 值的記錄
-- 
-- 創建時間: 2024-12-26
-- ============================================================================

BEGIN;

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE '開始強制同步 body_part → body_parts...';
    RAISE NOTICE '========================================';
END $$;

-- 顯示更新前的狀態
SELECT '===== 更新前狀態 =====' AS info;
SELECT 
  '查詢條件' as query_type,
  '結果數量' as count
UNION ALL
SELECT 'body_parts @> ARRAY[''腿'']', COUNT(*)::TEXT
FROM exercises WHERE body_parts @> ARRAY['腿']
UNION ALL
SELECT 'body_parts @> ARRAY[''腿部'']', COUNT(*)::TEXT
FROM exercises WHERE body_parts @> ARRAY['腿部'];

-- 強制更新：將 body_part 同步到 body_parts（覆蓋舊值）
UPDATE exercises
SET 
    body_parts = ARRAY[body_part]::TEXT[],
    updated_at = NOW()
WHERE body_part IS NOT NULL 
  AND body_part != '';

-- 顯示更新後的狀態
SELECT '===== 更新後狀態 =====' AS info;
SELECT 
  '查詢條件' as query_type,
  '結果數量' as count
UNION ALL
SELECT 'body_parts @> ARRAY[''腿'']', COUNT(*)::TEXT
FROM exercises WHERE body_parts @> ARRAY['腿']
UNION ALL
SELECT 'body_parts @> ARRAY[''腿部'']', COUNT(*)::TEXT
FROM exercises WHERE body_parts @> ARRAY['腿部'];

-- 測試組合查詢
SELECT '===== 測試組合查詢 =====' AS info;
SELECT 
  'training_type = ''阻力訓練'' AND body_parts @> ARRAY[''腿部'']' as query,
  COUNT(*) as count
FROM exercises 
WHERE training_type = '阻力訓練' 
  AND body_parts @> ARRAY['腿部'];

-- 顯示幾個範例
SELECT '===== 更新後的範例 =====' AS info;
SELECT 
  name,
  body_part,
  body_parts,
  training_type
FROM exercises 
WHERE body_parts @> ARRAY['腿部']
LIMIT 5;

COMMIT;

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ 強制同步完成！';
    RAISE NOTICE '========================================';
    RAISE NOTICE '已將所有 body_part 值強制同步到 body_parts 陣列';
    RAISE NOTICE '覆蓋了舊的值（例如 [''腿''] → [''腿部'']）';
    RAISE NOTICE '';
    RAISE NOTICE '下一步: 重啟 Flutter 應用測試！';
    RAISE NOTICE '========================================';
END $$;


