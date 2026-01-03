-- =====================================================
-- Migration 014: Client Profile - 學員檔案系統
-- =====================================================
-- 創建日期：2025-01-03
-- 描述：為教練-學員關係新增學員檔案欄位，記錄訓練目標、健康注意事項、訓練偏好
-- =====================================================

-- 1. 新增 client_profile 欄位（JSONB）
ALTER TABLE public.coaching_relationships
ADD COLUMN IF NOT EXISTS client_profile JSONB DEFAULT '{}'::jsonb;

-- 2. 建立 GIN 索引（支援 JSONB 查詢）
CREATE INDEX IF NOT EXISTS idx_coaching_relationships_profile_gin 
ON public.coaching_relationships USING gin(client_profile);

-- 3. 新增欄位註解
COMMENT ON COLUMN public.coaching_relationships.client_profile IS '學員檔案（JSONB）：訓練目標、健康注意事項、訓練偏好、建檔日期';

-- =====================================================
-- JSONB 結構說明
-- =====================================================
/*
client_profile 欄位結構：
{
  "goals": "減重10公斤，改善體態",              // 訓練目標（必填）
  "health_notes": "右膝舊傷，深蹲需注意",      // 健康注意事項（選填）
  "preferences": "不喜歡跑步，偏好重訓",       // 訓練偏好（選填）
  "assessment_date": "2025-01-03T10:00:00Z"   // 建檔日期（自動）
}

範例：
UPDATE coaching_relationships 
SET client_profile = '{
  "goals": "減重10公斤，改善體態",
  "health_notes": "右膝舊傷，深蹲需注意",
  "preferences": "偏好重訓",
  "assessment_date": "2025-01-03T10:00:00Z"
}'::jsonb
WHERE id = 'xxx';
*/

-- =====================================================
-- 驗證
-- =====================================================

DO $$
BEGIN
  -- 檢查欄位是否新增成功
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'coaching_relationships'
    AND column_name = 'client_profile'
  ) THEN
    RAISE NOTICE '✅ Column client_profile added to coaching_relationships';
  ELSE
    RAISE EXCEPTION '❌ Failed to add client_profile column';
  END IF;
  
  -- 檢查 GIN 索引是否創建成功
  IF EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
    AND tablename = 'coaching_relationships'
    AND indexname = 'idx_coaching_relationships_profile_gin'
  ) THEN
    RAISE NOTICE '✅ GIN index idx_coaching_relationships_profile_gin created';
  ELSE
    RAISE WARNING '⚠️ GIN index idx_coaching_relationships_profile_gin not found';
  END IF;
  
  -- 檢查現有資料（應該都有預設值 {}）
  DECLARE
    null_count INTEGER;
  BEGIN
    SELECT COUNT(*) INTO null_count
    FROM public.coaching_relationships
    WHERE client_profile IS NULL;
    
    IF null_count = 0 THEN
      RAISE NOTICE '✅ All relationships have default client_profile value';
    ELSE
      RAISE WARNING '⚠️ Found % relationships without client_profile', null_count;
    END IF;
  END;
END $$;

-- =====================================================
-- 測試查詢（開發環境）
-- =====================================================

-- 1. 查看現有關係的檔案狀態
SELECT 
  id,
  coach_id,
  client_id,
  status,
  client_profile
FROM public.coaching_relationships
ORDER BY created_at DESC
LIMIT 5;

-- 2. 測試 JSONB 查詢（查詢有設定目標的檔案）
/*
SELECT 
  id,
  client_id,
  client_profile->>'goals' as goals,
  client_profile->>'health_notes' as health_notes
FROM public.coaching_relationships
WHERE client_profile->>'goals' IS NOT NULL
  AND client_profile->>'goals' != ''
ORDER BY created_at DESC;
*/

-- 3. 測試更新檔案（範例）
/*
UPDATE public.coaching_relationships
SET client_profile = '{
  "goals": "減重10公斤，改善體態",
  "health_notes": "右膝舊傷，深蹲需注意",
  "preferences": "偏好重訓，不喜歡跑步",
  "assessment_date": "2025-01-03T10:00:00Z"
}'::jsonb
WHERE id = 'YOUR_RELATIONSHIP_ID';
*/

-- =====================================================
-- 完成
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '🎉 Migration 014 completed successfully!';
  RAISE NOTICE '📋 Next steps:';
  RAISE NOTICE '   1. Update CoachingRelationshipModel (add ClientProfile)';
  RAISE NOTICE '   2. Create UI components (EmptyProfileCard, ProfileCard, EditorDialog)';
  RAISE NOTICE '   3. Update ClientInfoTab (replace training goal section)';
END $$;

