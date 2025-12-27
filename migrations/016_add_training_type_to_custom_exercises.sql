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

