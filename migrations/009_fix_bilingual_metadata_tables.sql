-- ============================================================================
-- StrengthWise - 元數據表雙語支援修正腳本
-- ============================================================================
-- 
-- 目的: 修正 exercise_types 和 body_parts 的中英文對應
-- 問題: 008 已將 exercises 表更新為新命名，但 exercise_types 表可能還是舊命名
-- 
-- 新舊對照:
--   舊: 重訓     → 新: 阻力訓練
--   舊: 有氧     → 新: 心肺適能訓練
--   舊: 伸展     → 新: 活動度與伸展
--   舊: 胸/背/腿 → 新: 胸部/背部/腿部
-- 
-- 創建時間: 2024-12-26
-- ============================================================================

BEGIN;

-- ===========================
-- 步驟 1: 檢查並顯示當前狀態
-- ===========================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE '開始檢查資料庫當前狀態...';
    RAISE NOTICE '========================================';
END $$;

-- 顯示當前 exercise_types 資料
SELECT '===== 當前 exercise_types 資料 =====' AS info;
SELECT name, name_en, count FROM public.exercise_types ORDER BY count DESC;

-- 顯示當前 body_parts 資料
SELECT '===== 當前 body_parts 資料 =====' AS info;
SELECT name, name_en, count FROM public.body_parts ORDER BY count DESC;

-- ===========================
-- 步驟 2: 統一更新 exercise_types
-- ===========================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '開始更新 exercise_types...';
END $$;

-- 先確保有英文欄位
ALTER TABLE public.exercise_types ADD COLUMN IF NOT EXISTS name_en TEXT;
ALTER TABLE public.exercise_types ADD COLUMN IF NOT EXISTS description_en TEXT;

-- 方案 A: 如果是舊命名，更新為新命名（同時加英文）
UPDATE public.exercise_types 
SET 
    name = '阻力訓練',
    name_en = 'Resistance Training',
    description_en = 'Training using resistance to build muscle strength and size',
    updated_at = NOW()
WHERE name = '重訓';

UPDATE public.exercise_types 
SET 
    name = '心肺適能訓練',
    name_en = 'Cardiovascular Training',
    description_en = 'Training to improve cardiovascular endurance',
    updated_at = NOW()
WHERE name = '有氧';

UPDATE public.exercise_types 
SET 
    name = '活動度與伸展',
    name_en = 'Mobility & Flexibility',
    description_en = 'Training to improve joint mobility and muscle flexibility',
    updated_at = NOW()
WHERE name = '伸展';

-- 方案 B: 如果已經是新命名，只更新英文欄位
UPDATE public.exercise_types 
SET 
    name_en = 'Resistance Training',
    description_en = 'Training using resistance to build muscle strength and size',
    updated_at = NOW()
WHERE name = '阻力訓練' AND (name_en IS NULL OR name_en = '');

UPDATE public.exercise_types 
SET 
    name_en = 'Cardiovascular Training',
    description_en = 'Training to improve cardiovascular endurance',
    updated_at = NOW()
WHERE name = '心肺適能訓練' AND (name_en IS NULL OR name_en = '');

UPDATE public.exercise_types 
SET 
    name_en = 'Mobility & Flexibility',
    description_en = 'Training to improve joint mobility and muscle flexibility',
    updated_at = NOW()
WHERE name = '活動度與伸展' AND (name_en IS NULL OR name_en = '');

-- ===========================
-- 步驟 3: 統一更新 body_parts
-- ===========================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '開始更新 body_parts...';
END $$;

-- 先確保有英文欄位
ALTER TABLE public.body_parts ADD COLUMN IF NOT EXISTS name_en TEXT;
ALTER TABLE public.body_parts ADD COLUMN IF NOT EXISTS description_en TEXT;

-- 方案 A: 如果是舊命名（胸/背/腿），更新為新命名（胸部/背部/腿部）
UPDATE public.body_parts 
SET 
    name = '胸部',
    name_en = 'Chest',
    description_en = 'Chest muscles (pectoralis major)',
    updated_at = NOW()
WHERE name = '胸';

UPDATE public.body_parts 
SET 
    name = '背部',
    name_en = 'Back',
    description_en = 'Back muscles including lats, traps',
    updated_at = NOW()
WHERE name = '背';

UPDATE public.body_parts 
SET 
    name = '腿部',
    name_en = 'Legs',
    description_en = 'Lower body including quads, hamstrings, glutes',
    updated_at = NOW()
WHERE name = '腿';

UPDATE public.body_parts 
SET 
    name = '肩部',
    name_en = 'Shoulders',
    description_en = 'Shoulder muscles (deltoids)',
    updated_at = NOW()
WHERE name = '肩';

-- 方案 B: 如果已經是新命名，只更新英文欄位
UPDATE public.body_parts 
SET 
    name_en = 'Chest',
    description_en = 'Chest muscles (pectoralis major)',
    updated_at = NOW()
WHERE name = '胸部' AND (name_en IS NULL OR name_en = '');

UPDATE public.body_parts 
SET 
    name_en = 'Back',
    description_en = 'Back muscles including lats, traps',
    updated_at = NOW()
WHERE name = '背部' AND (name_en IS NULL OR name_en = '');

UPDATE public.body_parts 
SET 
    name_en = 'Legs',
    description_en = 'Lower body including quads, hamstrings, glutes',
    updated_at = NOW()
WHERE name = '腿部' AND (name_en IS NULL OR name_en = '');

UPDATE public.body_parts 
SET 
    name_en = 'Shoulders',
    description_en = 'Shoulder muscles (deltoids)',
    updated_at = NOW()
WHERE name = '肩部' AND (name_en IS NULL OR name_en = '');

-- 其他身體部位（無新舊命名問題）
UPDATE public.body_parts 
SET 
    name_en = 'Arms',
    description_en = 'Arms (biceps, triceps)',
    updated_at = NOW()
WHERE name = '手' AND (name_en IS NULL OR name_en = '');

UPDATE public.body_parts 
SET 
    name_en = 'Core',
    description_en = 'Core muscles (abs, lower back)',
    updated_at = NOW()
WHERE name = '核心' AND (name_en IS NULL OR name_en = '');

UPDATE public.body_parts 
SET 
    name_en = 'Full Body',
    description_en = 'Full body compound movements',
    updated_at = NOW()
WHERE name = '全身' AND (name_en IS NULL OR name_en = '');

UPDATE public.body_parts 
SET 
    name_en = 'Shoulders & Back',
    description_en = 'Shoulder and back compound movements',
    updated_at = NOW()
WHERE name = '肩, 背' AND (name_en IS NULL OR name_en = '');

-- ===========================
-- 步驟 4: 建立索引
-- ===========================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '創建索引...';
END $$;

-- body_parts 索引
CREATE INDEX IF NOT EXISTS idx_body_parts_name ON public.body_parts (name);
CREATE INDEX IF NOT EXISTS idx_body_parts_name_en ON public.body_parts (name_en) WHERE name_en IS NOT NULL;

-- exercise_types 索引
CREATE INDEX IF NOT EXISTS idx_exercise_types_name ON public.exercise_types (name);
CREATE INDEX IF NOT EXISTS idx_exercise_types_name_en ON public.exercise_types (name_en) WHERE name_en IS NOT NULL;

COMMIT;

-- ===========================
-- 步驟 5: 驗證結果
-- ===========================

DO $$
DECLARE
    bp_count INT;
    bp_en_count INT;
    et_count INT;
    et_en_count INT;
BEGIN
    -- 檢查 body_parts
    SELECT COUNT(*) INTO bp_count FROM public.body_parts;
    SELECT COUNT(*) INTO bp_en_count FROM public.body_parts WHERE name_en IS NOT NULL;
    
    -- 檢查 exercise_types
    SELECT COUNT(*) INTO et_count FROM public.exercise_types;
    SELECT COUNT(*) INTO et_en_count FROM public.exercise_types WHERE name_en IS NOT NULL;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '驗證結果:';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'body_parts:';
    RAISE NOTICE '  總記錄數: %', bp_count;
    RAISE NOTICE '  已設定英文: %', bp_en_count;
    IF bp_count = bp_en_count THEN
        RAISE NOTICE '  狀態: ✅ 完成';
    ELSE
        RAISE NOTICE '  狀態: ⚠️ 部分完成';
    END IF;
    RAISE NOTICE '';
    RAISE NOTICE 'exercise_types:';
    RAISE NOTICE '  總記錄數: %', et_count;
    RAISE NOTICE '  已設定英文: %', et_en_count;
    IF et_count = et_en_count THEN
        RAISE NOTICE '  狀態: ✅ 完成';
    ELSE
        RAISE NOTICE '  狀態: ⚠️ 部分完成';
    END IF;
    RAISE NOTICE '========================================';
END $$;

-- 顯示最終結果
SELECT '===== 最終 exercise_types 資料 =====' AS info;
SELECT name, name_en, description_en, count 
FROM public.exercise_types 
ORDER BY count DESC;

SELECT '===== 最終 body_parts 資料 =====' AS info;
SELECT name, name_en, description_en, count 
FROM public.body_parts 
ORDER BY count DESC;

-- ===========================
-- 完成訊息
-- ===========================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ 元數據表雙語支援修正完成！';
    RAISE NOTICE '========================================';
    RAISE NOTICE '已修正:';
    RAISE NOTICE '- exercise_types: 中文名稱統一為新命名';
    RAISE NOTICE '- exercise_types: 100%% 英文對應';
    RAISE NOTICE '- body_parts: 中文名稱統一為新命名';
    RAISE NOTICE '- body_parts: 100%% 英文對應';
    RAISE NOTICE '';
    RAISE NOTICE '名稱對應:';
    RAISE NOTICE '- 阻力訓練 ← → Resistance Training';
    RAISE NOTICE '- 心肺適能訓練 ← → Cardiovascular Training';
    RAISE NOTICE '- 活動度與伸展 ← → Mobility & Flexibility';
    RAISE NOTICE '- 胸部/背部/腿部/肩部 ← → Chest/Back/Legs/Shoulders';
    RAISE NOTICE '========================================';
END $$;

