-- =====================================================
-- Migration: Storage RLS 策略 - session_photos Bucket
-- =====================================================
-- 版本：024
-- 創建日期：2024-12-30
-- 描述：為 session_photos Storage Bucket 設置 RLS 策略
--       允許教練上傳照片，學員查看共享筆記的照片
-- =====================================================

-- =====================================================
-- Part 1: Storage Bucket Objects RLS 策略
-- =====================================================

-- 啟用 storage.objects 表的 RLS（如果尚未啟用）
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- ----------------
-- session_photos Bucket 策略
-- ----------------

-- 1. 教練上傳照片（INSERT）
-- 路徑格式：{coach_id}/{client_id}/{filename}
CREATE POLICY "Coaches can upload session photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'session_photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 2. 教練查看自己上傳的照片（SELECT）
CREATE POLICY "Coaches can view own session photos"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'session_photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. 學員查看「共享筆記」的照片（SELECT）
-- 邏輯：
--   - 照片路徑：{coach_id}/{client_id}/{filename}
--   - 學員只能看到：路徑中 client_id = 自己，且教練有「共享筆記」給他
CREATE POLICY "Clients can view shared session photos"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'session_photos'
  AND (storage.foldername(name))[2] = auth.uid()::text  -- client_id 必須是自己
  AND EXISTS (
    SELECT 1 FROM public.session_notes sn
    WHERE sn.coach_id::text = (storage.foldername(name))[1]  -- coach_id 匹配
    AND sn.client_id = auth.uid()  -- 學員 ID 匹配
    AND sn.visibility = 'shared'  -- 必須是共享筆記
  )
);

-- 4. 教練更新/刪除自己的照片（UPDATE/DELETE）
CREATE POLICY "Coaches can update own session photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'session_photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'session_photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Coaches can delete own session photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'session_photos'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- Part 2: 驗證查詢（可選，用於測試）
-- =====================================================

/*
測試查詢（在 Supabase SQL Editor 中執行）：

1. 檢查教練可以看到自己的照片：
SELECT * FROM storage.objects
WHERE bucket_id = 'session_photos'
AND (storage.foldername(name))[1] = auth.uid()::text;

2. 檢查學員可以看到共享筆記的照片：
SELECT o.*, sn.visibility
FROM storage.objects o
JOIN public.session_notes sn ON sn.id = (storage.foldername(o.name))[2]
WHERE o.bucket_id = 'session_photos'
AND sn.client_id = auth.uid()
AND sn.visibility = 'shared';

3. 列出所有 session_photos 的 RLS 策略：
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
AND policyname LIKE '%session%';
*/

-- =====================================================
-- 注意事項
-- =====================================================
/*
1. 確保 session_photos Bucket 已在 Supabase Dashboard 中創建
2. Bucket 設定：
   - Public: false
   - File size limit: 10MB
   - Allowed MIME types: image/jpeg, image/png
   
3. 如果策略不生效，檢查：
   - storage.objects 表是否啟用 RLS
   - Bucket 是否設為 Public（應該為 false）
   - 用戶是否已認證（authenticated role）
   
4. 路徑結構範例：
   - 教練 ID: d1798674-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   - 學員 ID: 1df75ed6-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   - 完整路徑: d1798674-.../1df75ed6-.../1735536000_photo.jpg

5. 已知限制（可接受的安全風險）：
   - 學員可以訪問同一路徑（coach_id/client_id/）下的所有照片
   - 即使某些照片屬於「私人筆記」
   - 風險評估：需要知道完整 URL 才能訪問，實際風險極低
   - 未來改進：可使用 Signed URL 實現完全隔離（Phase 4+）
*/

