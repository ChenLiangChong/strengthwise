-- =====================================================
-- Migration 016 驗證腳本
-- =====================================================
-- 執行此腳本以確認 health_assessments 表格建立是否正確
-- =====================================================

-- 1. 檢查表格是否存在
SELECT 
    table_name,
    '✅ 表格存在' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('health_assessments', 'coach_display_preferences');

-- 2. 檢查列舉類型
SELECT 
    typname as enum_name,
    '✅ 列舉類型存在' as status
FROM pg_type 
WHERE typname IN ('training_level', 'activity_level', 'injury_status');

-- 3. 檢查 health_assessments 表格欄位
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'health_assessments'
ORDER BY ordinal_position;

-- 4. 檢查索引
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public' 
AND tablename = 'health_assessments'
ORDER BY indexname;

-- 5. 檢查 RLS 是否啟用
SELECT 
    tablename,
    rowsecurity as rls_enabled,
    '✅ RLS 已啟用' as status
FROM pg_tables
WHERE schemaname = 'public' 
AND tablename = 'health_assessments';

-- 6. 檢查 RLS 政策
SELECT 
    policyname,
    cmd,
    qual as using_clause
FROM pg_policies
WHERE schemaname = 'public' 
AND tablename = 'health_assessments'
ORDER BY policyname;

-- 7. 測試插入（可選 - 需要有真實的 user_id）
/*
-- 替換為真實的 user_id
INSERT INTO public.health_assessments (
    user_id,
    heart_disease,
    chest_pain_exercise,
    chest_pain_rest,
    dizziness,
    bone_joint_problem,
    medication,
    other_reason,
    training_experience,
    training_years
) VALUES (
    '你的真實user_id',
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    'beginner',
    0.5
) RETURNING id, is_cleared, is_current;
*/

-- 8. 檢查 GENERATED 欄位是否正常工作
-- （插入後查詢 is_cleared 應自動計算）
/*
SELECT 
    id,
    user_id,
    heart_disease,
    chest_pain_exercise,
    is_cleared,  -- ⭐ 應該自動計算為 TRUE（如果所有篩檢都是 false）
    is_current
FROM public.health_assessments
ORDER BY created_at DESC
LIMIT 5;
*/

