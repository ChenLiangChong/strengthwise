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

