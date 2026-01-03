-- ============================================================================
-- 015_fix_cascade_to_set_null.sql
-- 修復：刪除用戶時保留歷史數據（使用 SET NULL + 名稱快照）
-- 創建時間：2026-01-03
-- ============================================================================

-- ============================================================================
-- 問題描述
-- ============================================================================
-- 1. coaching_relationships: ON DELETE CASCADE 會刪除所有關係記錄
--    → 解除綁定後無法查看歷史筆記
-- 2. session_notes: ON DELETE CASCADE 會刪除所有筆記
--    → 共享筆記應該保留，但外鍵是 NOT NULL
-- 3. delete_user_account() 函數試圖設 NULL，但違反 NOT NULL 約束
-- 4. ⭐ 新問題：ID 為 NULL 後，無法顯示用戶名稱（UX 問題）
--
-- 解決方案：
-- - coaching_relationships: 允許 NULL + ON DELETE SET NULL + 名稱快照
-- - session_notes: 允許 NULL + ON DELETE SET NULL + 名稱快照
-- - 新增 coach_name, client_name 欄位（保存刪除前的名稱）
-- ============================================================================

-- ============================================================================
-- Part 1: 修改 coaching_relationships 表
-- ============================================================================

-- 1. 新增名稱快照欄位
ALTER TABLE public.coaching_relationships 
ADD COLUMN IF NOT EXISTS coach_name TEXT,
ADD COLUMN IF NOT EXISTS client_name TEXT;

COMMENT ON COLUMN public.coaching_relationships.coach_name IS '教練名稱快照（用戶刪除後仍保留）';
COMMENT ON COLUMN public.coaching_relationships.client_name IS '學員名稱快照（用戶刪除後仍保留）';

-- 2. 刪除舊的外鍵約束
ALTER TABLE public.coaching_relationships 
DROP CONSTRAINT IF EXISTS coaching_relationships_coach_id_fkey;

ALTER TABLE public.coaching_relationships 
DROP CONSTRAINT IF EXISTS coaching_relationships_client_id_fkey;

-- 3. 修改欄位為可 NULL（保留歷史數據）
ALTER TABLE public.coaching_relationships 
ALTER COLUMN coach_id DROP NOT NULL;

ALTER TABLE public.coaching_relationships 
ALTER COLUMN client_id DROP NOT NULL;

-- 4. 新增外鍵約束（ON DELETE SET NULL）
ALTER TABLE public.coaching_relationships 
ADD CONSTRAINT coaching_relationships_coach_id_fkey 
FOREIGN KEY (coach_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE public.coaching_relationships 
ADD CONSTRAINT coaching_relationships_client_id_fkey 
FOREIGN KEY (client_id) REFERENCES public.users(id) ON DELETE SET NULL;

-- 5. ⭐ 先修复 updated_at 触发器（必须在 UPDATE 之前）
-- 原来的 update_updated_at_column() 函数使用了 profile_updated_at
-- 需要重新创建专用的触发器函数
DROP TRIGGER IF EXISTS update_coaching_relationships_updated_at ON public.coaching_relationships;

CREATE OR REPLACE FUNCTION public.update_coaching_relationships_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_coaching_relationships_updated_at
BEFORE UPDATE ON public.coaching_relationships
FOR EACH ROW EXECUTE FUNCTION public.update_coaching_relationships_updated_at();

-- 6. 回填現有記錄的名稱（從 users 表）
UPDATE public.coaching_relationships cr
SET coach_name = COALESCE(u.display_name, u.email)
FROM public.users u
WHERE cr.coach_id = u.id AND cr.coach_name IS NULL;

UPDATE public.coaching_relationships cr
SET client_name = COALESCE(u.display_name, u.email)
FROM public.users u
WHERE cr.client_id = u.id AND cr.client_name IS NULL;

-- 7. 添加註解
COMMENT ON COLUMN public.coaching_relationships.coach_id IS '教練 ID (可為 NULL，用戶刪除後保留歷史記錄)';
COMMENT ON COLUMN public.coaching_relationships.client_id IS '學員 ID (可為 NULL，用戶刪除後保留歷史記錄)';

-- ============================================================================
-- Part 2: 修改 session_notes 表
-- ============================================================================

-- 1. 新增名稱快照欄位
ALTER TABLE public.session_notes 
ADD COLUMN IF NOT EXISTS coach_name TEXT,
ADD COLUMN IF NOT EXISTS client_name TEXT;

COMMENT ON COLUMN public.session_notes.coach_name IS '教練名稱快照（用戶刪除後仍保留）';
COMMENT ON COLUMN public.session_notes.client_name IS '學員名稱快照（用戶刪除後仍保留）';

-- 2. 刪除舊的外鍵約束
ALTER TABLE public.session_notes 
DROP CONSTRAINT IF EXISTS session_notes_coach_id_fkey;

ALTER TABLE public.session_notes 
DROP CONSTRAINT IF EXISTS session_notes_client_id_fkey;

-- 3. 修改欄位為可 NULL（保留共享筆記）
ALTER TABLE public.session_notes 
ALTER COLUMN coach_id DROP NOT NULL;

ALTER TABLE public.session_notes 
ALTER COLUMN client_id DROP NOT NULL;

-- 4. 新增外鍵約束（ON DELETE SET NULL）
ALTER TABLE public.session_notes 
ADD CONSTRAINT session_notes_coach_id_fkey 
FOREIGN KEY (coach_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE public.session_notes 
ADD CONSTRAINT session_notes_client_id_fkey 
FOREIGN KEY (client_id) REFERENCES public.users(id) ON DELETE SET NULL;

-- 5. 回填現有記錄的名稱（從 users 表）
UPDATE public.session_notes sn
SET coach_name = COALESCE(u.display_name, u.email)
FROM public.users u
WHERE sn.coach_id = u.id AND sn.coach_name IS NULL;

UPDATE public.session_notes sn
SET client_name = COALESCE(u.display_name, u.email)
FROM public.users u
WHERE sn.client_id = u.id AND sn.client_name IS NULL;

-- 6. 添加註解
COMMENT ON COLUMN public.session_notes.coach_id IS '教練 ID (可為 NULL，用戶刪除後保留共享筆記)';
COMMENT ON COLUMN public.session_notes.client_id IS '學員 ID (可為 NULL，用戶刪除後保留共享筆記)';

-- 7. 修改 CHECK 約束（允許其中一個為 NULL）
ALTER TABLE public.session_notes 
DROP CONSTRAINT IF EXISTS session_notes_coach_client_valid;

ALTER TABLE public.session_notes 
ADD CONSTRAINT session_notes_coach_client_valid 
CHECK (
  (coach_id IS NOT NULL OR client_id IS NOT NULL) AND 
  (coach_id IS NULL OR client_id IS NULL OR coach_id != client_id)
);

COMMENT ON CONSTRAINT session_notes_coach_client_valid ON public.session_notes IS 
'至少一個 ID 不為 NULL，且若都存在則不能相同';

-- ============================================================================
-- Part 3: 創建觸發器（自動保存名稱快照）
-- ============================================================================

-- 3.1 coaching_relationships 觸發器
CREATE OR REPLACE FUNCTION public.save_coaching_relationship_names()
RETURNS TRIGGER AS $$
DECLARE
  coach_display_name TEXT;
  client_display_name TEXT;
BEGIN
  -- 如果 coach_id 存在且名稱為空，自動填入
  IF NEW.coach_id IS NOT NULL AND NEW.coach_name IS NULL THEN
    SELECT COALESCE(display_name, email) INTO coach_display_name
    FROM public.users WHERE id = NEW.coach_id;
    NEW.coach_name := coach_display_name;
  END IF;
  
  -- 如果 client_id 存在且名稱為空，自動填入
  IF NEW.client_id IS NOT NULL AND NEW.client_name IS NULL THEN
    SELECT COALESCE(display_name, email) INTO client_display_name
    FROM public.users WHERE id = NEW.client_id;
    NEW.client_name := client_display_name;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS coaching_relationship_names_trigger ON public.coaching_relationships;
CREATE TRIGGER coaching_relationship_names_trigger
BEFORE INSERT OR UPDATE ON public.coaching_relationships
FOR EACH ROW EXECUTE FUNCTION public.save_coaching_relationship_names();

-- 3.2 session_notes 觸發器
CREATE OR REPLACE FUNCTION public.save_session_note_names()
RETURNS TRIGGER AS $$
DECLARE
  coach_display_name TEXT;
  client_display_name TEXT;
BEGIN
  -- 如果 coach_id 存在且名稱為空，自動填入
  IF NEW.coach_id IS NOT NULL AND NEW.coach_name IS NULL THEN
    SELECT COALESCE(display_name, email) INTO coach_display_name
    FROM public.users WHERE id = NEW.coach_id;
    NEW.coach_name := coach_display_name;
  END IF;
  
  -- 如果 client_id 存在且名稱為空，自動填入
  IF NEW.client_id IS NOT NULL AND NEW.client_name IS NULL THEN
    SELECT COALESCE(display_name, email) INTO client_display_name
    FROM public.users WHERE id = NEW.client_id;
    NEW.client_name := client_display_name;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS session_note_names_trigger ON public.session_notes;
CREATE TRIGGER session_note_names_trigger
BEFORE INSERT OR UPDATE ON public.session_notes
FOR EACH ROW EXECUTE FUNCTION public.save_session_note_names();

-- ============================================================================
-- Part 4: 新增學員刪除筆記的權限（關係結束後）
-- ============================================================================

-- 學員可以刪除：
-- 1. 關係已結束（archived）的共享筆記
-- 2. 教練已刪除帳號（coach_id = NULL）的共享筆記
CREATE POLICY "Clients delete shared notes after relationship ends"
ON public.session_notes FOR DELETE
USING (
  client_id = auth.uid() 
  AND visibility = 'shared'
  AND (
    -- 情況 1：教練已刪除帳號
    coach_id IS NULL
    OR
    -- 情況 2：關係已結束（archived 或不存在）
    NOT EXISTS (
      SELECT 1 FROM public.coaching_relationships cr
      WHERE cr.coach_id = session_notes.coach_id
      AND cr.client_id = auth.uid()
      AND cr.status = 'active'
    )
  )
);

COMMENT ON POLICY "Clients delete shared notes after relationship ends" ON public.session_notes IS 
'學員可刪除共享筆記：(1) 教練已刪除帳號，或 (2) 關係已結束（archived/不存在）';

-- ============================================================================
-- Part 5: 更新 delete_user_account() 函數
-- ============================================================================

-- ⚠️ 注意：delete_user_account() 函數不需要修改
-- 因為：
-- - DELETE FROM public.users 會觸發 ON DELETE SET NULL
-- - 名稱快照已經在刪除前保存好了
-- - 私有筆記的手動 DELETE 仍然有效
-- - 共享筆記的 UPDATE SET NULL 現在可以成功執行

-- ============================================================================
-- 驗證
-- ============================================================================

-- 檢查外鍵約束
SELECT 
  tc.table_name, 
  kcu.column_name, 
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  rc.delete_rule
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name IN ('coaching_relationships', 'session_notes')
  AND kcu.column_name IN ('coach_id', 'client_id')
ORDER BY tc.table_name, kcu.column_name;

-- 預期結果：
-- coaching_relationships | coach_id  | users | id | SET NULL
-- coaching_relationships | client_id | users | id | SET NULL
-- session_notes          | coach_id  | users | id | SET NULL
-- session_notes          | client_id | users | id | SET NULL

-- 檢查名稱欄位
SELECT 
  table_name, 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns
WHERE table_name IN ('coaching_relationships', 'session_notes')
  AND column_name IN ('coach_name', 'client_name')
ORDER BY table_name, column_name;

-- ============================================================================
-- 完成
-- ============================================================================
-- ✅ coaching_relationships: 用戶刪除後關係保留（ID 設為 NULL，名稱保留）
-- ✅ session_notes: 用戶刪除後共享筆記保留（ID 設為 NULL，名稱保留）
-- ✅ 觸發器自動保存名稱快照（INSERT/UPDATE 時）
-- ✅ UI 可以顯示「張教練」而非「已刪除的教練」
-- ✅ 搜尋功能仍然有效（使用 coach_name, client_name）
-- ✅ 學員可刪除關係結束後的共享筆記
-- ============================================================================

