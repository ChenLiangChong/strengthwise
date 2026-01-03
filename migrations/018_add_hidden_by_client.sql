-- ============================================================================
-- 018_add_hidden_by_client.sql
-- 新增學員/教練隱藏筆記功能
-- 創建時間：2026-01-03
-- 更新時間：2026-01-03（新增 hidden_by_coach）
-- ============================================================================
-- 
-- 需求：
-- 1. 學員可以「移除」archived 關係的共享筆記，但不影響教練端查看
-- 2. 教練可以「移除」archived 關係的共享筆記，但不影響學員端查看
-- 3. 重新綁定後，隱藏狀態保持不變（尊重用戶決定）
-- 
-- 解決方案：
-- 1. 新增 session_notes.hidden_by_client 和 hidden_by_coach 欄位
-- 2. 雙方「刪除」共享筆記時改為 UPDATE hidden = true
-- 3. 查詢時自動過濾已隱藏的筆記
-- 4. 真正的 DELETE 只能刪除私人筆記
-- ============================================================================

-- 1. 新增 hidden_by_client 欄位
ALTER TABLE public.session_notes 
ADD COLUMN IF NOT EXISTS hidden_by_client BOOLEAN DEFAULT false;

COMMENT ON COLUMN public.session_notes.hidden_by_client IS 
'學員是否隱藏此筆記（不影響教練端查看）';

-- 2. 新增 hidden_by_coach 欄位 ⭐ NEW
ALTER TABLE public.session_notes 
ADD COLUMN IF NOT EXISTS hidden_by_coach BOOLEAN DEFAULT false;

COMMENT ON COLUMN public.session_notes.hidden_by_coach IS 
'教練是否隱藏此筆記（不影響學員端查看）';

-- 3. 為 hidden_by_client 建立索引（優化查詢）
CREATE INDEX IF NOT EXISTS idx_session_notes_hidden_by_client 
ON public.session_notes(client_id, hidden_by_client)
WHERE hidden_by_client = true;

COMMENT ON INDEX idx_session_notes_hidden_by_client IS 
'優化學員查詢已隱藏筆記的效能（部分索引）';

-- 4. 為 hidden_by_coach 建立索引（優化查詢）⭐ NEW
CREATE INDEX IF NOT EXISTS idx_session_notes_hidden_by_coach 
ON public.session_notes(coach_id, hidden_by_coach)
WHERE hidden_by_coach = true;

COMMENT ON INDEX idx_session_notes_hidden_by_coach IS 
'優化教練查詢已隱藏筆記的效能（部分索引）';

-- 5. 移除舊的政策
DROP POLICY IF EXISTS "Clients delete shared notes after relationship ends" ON public.session_notes;
DROP POLICY IF EXISTS "Clients can hide shared notes after relationship ends" ON public.session_notes;
DROP POLICY IF EXISTS "Coaches can hide shared notes" ON public.session_notes;

-- 6. 新增 UPDATE 政策：學員可以隱藏 archived 關係的共享筆記
CREATE POLICY "Clients can hide shared notes after relationship ends"
  ON public.session_notes FOR UPDATE
  TO authenticated
  USING (
    client_id = auth.uid()
    AND visibility = 'shared'
    AND (
      coach_id IS NULL  -- 教練已刪除
      OR NOT EXISTS (
        SELECT 1 FROM public.coaching_relationships cr
        WHERE cr.coach_id = session_notes.coach_id
        AND cr.client_id = auth.uid()
        AND cr.status = 'active'  -- 關係不是 active
      )
    )
  )
  WITH CHECK (
    client_id = auth.uid()
    AND visibility = 'shared'
    AND hidden_by_client = true  -- 只能設為隱藏
  );

COMMENT ON POLICY "Clients can hide shared notes after relationship ends" ON public.session_notes IS 
'學員可隱藏已結束關係的共享筆記（UPDATE hidden_by_client = true）';

-- 7. 新增 UPDATE 政策：教練可以隱藏共享筆記 ⭐ NEW
CREATE POLICY "Coaches can hide shared notes"
  ON public.session_notes FOR UPDATE
  TO authenticated
  USING (
    coach_id = auth.uid()
    AND visibility = 'shared'
  )
  WITH CHECK (
    coach_id = auth.uid()
    AND visibility = 'shared'
    AND hidden_by_coach = true  -- 只能設為隱藏
  );

COMMENT ON POLICY "Coaches can hide shared notes" ON public.session_notes IS 
'教練可隱藏共享筆記（UPDATE hidden_by_coach = true），不影響學員查看';

-- ============================================================================
-- 驗證
-- ============================================================================

-- 檢查欄位是否新增成功
SELECT 
  column_name, 
  data_type, 
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'session_notes'
  AND column_name IN ('hidden_by_client', 'hidden_by_coach')
ORDER BY column_name;

-- 檢查索引
SELECT 
  indexname, 
  indexdef
FROM pg_indexes
WHERE tablename = 'session_notes'
  AND indexname IN ('idx_session_notes_hidden_by_client', 'idx_session_notes_hidden_by_coach')
ORDER BY indexname;

-- 檢查政策
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE tablename = 'session_notes'
  AND policyname IN (
    'Clients can hide shared notes after relationship ends',
    'Coaches can hide shared notes'
  )
ORDER BY policyname;

-- ============================================================================
-- 完成
-- ============================================================================
-- ✅ 學員可以隱藏 archived 關係的共享筆記
-- ✅ 教練可以隱藏共享筆記（任何時候）
-- ✅ 雙方端不受影響（各自查看時過濾自己隱藏的）
-- ✅ 索引優化查詢效能
-- ✅ RLS 政策確保安全性
-- ✅ 重新綁定後，隱藏狀態保持不變（選項 A）
-- ============================================================================

