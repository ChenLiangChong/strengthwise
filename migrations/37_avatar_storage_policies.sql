-- ============================================================================
-- StrengthWise Migration: 37_avatar_storage_policies.sql
-- ============================================================================
-- 版本: v5.3
-- 日期: 2026-02-10
-- ============================================================================
--
-- 前置條件：需先在 Supabase Dashboard → Storage 建立 "avatars" bucket
--   - Bucket Name: avatars
--   - Public: true
--   - File Size Limit: 5MB
--   - Allowed MIME Types: image/jpeg, image/png, image/webp
--
-- 路徑結構：{user_id}/avatar.jpg
-- ============================================================================

-- 公開讀取（任何人可看到頭像）
CREATE POLICY "avatars_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- 用戶只能上傳自己的頭像（路徑第一層 = user_id）
CREATE POLICY "avatars_owner_insert"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.uid()::text = (SPLIT_PART(name, '/', 1))
);

-- 用戶只能更新自己的頭像
CREATE POLICY "avatars_owner_update"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (SPLIT_PART(name, '/', 1))
);

-- 用戶只能刪除自己的頭像
CREATE POLICY "avatars_owner_delete"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (SPLIT_PART(name, '/', 1))
);
