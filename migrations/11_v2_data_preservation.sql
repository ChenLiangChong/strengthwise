-- ============================================================================
-- StrengthWise Migration: 11_v2_data_preservation.sql
-- ============================================================================
-- 合併自: 014_client_profile.sql, 015_fix_cascade_to_set_null.sql
-- 版本: v2.3+
-- 日期: 2026-01-04
-- ============================================================================
-- 
-- 包含:
-- 1. client_profile JSONB 欄位（後於 020 移除）
-- 2. ON DELETE CASCADE 改為 ON DELETE SET NULL
-- 3. 姓名快照欄位與自動觸發器
-- ============================================================================

-- ============================================================================
-- PART 1: Client Profile (來自 014) - 臨時欄位，後於 020 移除
-- ============================================================================
-- 
-- 注意：此欄位最終在 migration 020 中被移除
-- 保留此處是為了維持 migration 歷史完整性

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'coaching_relationships' 
    AND column_name = 'client_profile'
  ) THEN
    ALTER TABLE public.coaching_relationships 
    ADD COLUMN client_profile JSONB;
    
    COMMENT ON COLUMN public.coaching_relationships.client_profile 
      IS '學員訓練檔案（訓練目標、健康資訊等）- 已於 migration 020 移除';
      
    RAISE NOTICE '✅ 已新增 coaching_relationships.client_profile 欄位';
  ELSE
    RAISE NOTICE 'ℹ️ client_profile 欄位已存在';
  END IF;
END $$;

-- ============================================================================
-- PART 2: 資料保留策略 - ON DELETE SET NULL (來自 015)
-- ============================================================================
-- 
-- 問題：使用 ON DELETE CASCADE 會在用戶刪除帳號時丟失歷史數據
-- 解決：改用 ON DELETE SET NULL + 姓名快照，保留歷史記錄

-- ----------------------------------------------------------------------------
-- 2.1 新增姓名快照欄位
-- ----------------------------------------------------------------------------

-- coaching_relationships 表
ALTER TABLE public.coaching_relationships
ADD COLUMN IF NOT EXISTS coach_name TEXT,
ADD COLUMN IF NOT EXISTS client_name TEXT;

COMMENT ON COLUMN public.coaching_relationships.coach_name IS '教練姓名快照（帳號刪除後保留）';
COMMENT ON COLUMN public.coaching_relationships.client_name IS '學員姓名快照（帳號刪除後保留）';

-- session_notes 表
ALTER TABLE public.session_notes
ADD COLUMN IF NOT EXISTS coach_name TEXT,
ADD COLUMN IF NOT EXISTS client_name TEXT;

COMMENT ON COLUMN public.session_notes.coach_name IS '教練姓名快照（帳號刪除後保留）';
COMMENT ON COLUMN public.session_notes.client_name IS '學員姓名快照（帳號刪除後保留）';

-- ----------------------------------------------------------------------------
-- 2.2 修改外鍵約束：CASCADE → SET NULL
-- ----------------------------------------------------------------------------

-- coaching_relationships 表
ALTER TABLE public.coaching_relationships
DROP CONSTRAINT IF EXISTS coaching_relationships_coach_id_fkey,
DROP CONSTRAINT IF EXISTS coaching_relationships_client_id_fkey;

ALTER TABLE public.coaching_relationships
ADD CONSTRAINT coaching_relationships_coach_id_fkey
  FOREIGN KEY (coach_id) REFERENCES public.users(id) ON DELETE SET NULL,
ADD CONSTRAINT coaching_relationships_client_id_fkey
  FOREIGN KEY (client_id) REFERENCES public.users(id) ON DELETE SET NULL;

-- session_notes 表
ALTER TABLE public.session_notes
DROP CONSTRAINT IF EXISTS session_notes_coach_id_fkey,
DROP CONSTRAINT IF EXISTS session_notes_client_id_fkey;

ALTER TABLE public.session_notes
ADD CONSTRAINT session_notes_coach_id_fkey
  FOREIGN KEY (coach_id) REFERENCES public.users(id) ON DELETE SET NULL,
ADD CONSTRAINT session_notes_client_id_fkey
  FOREIGN KEY (client_id) REFERENCES public.users(id) ON DELETE SET NULL;

-- ----------------------------------------------------------------------------
-- 2.3 創建姓名快照觸發器
-- ----------------------------------------------------------------------------

-- 保存 coaching_relationships 姓名快照
CREATE OR REPLACE FUNCTION save_relationship_names()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- 儲存教練姓名
  IF NEW.coach_id IS NOT NULL AND NEW.coach_name IS NULL THEN
    SELECT COALESCE(display_name, email) INTO NEW.coach_name
    FROM public.users WHERE id = NEW.coach_id;
  END IF;
  
  -- 儲存學員姓名
  IF NEW.client_id IS NOT NULL AND NEW.client_name IS NULL THEN
    SELECT COALESCE(display_name, email) INTO NEW.client_name
    FROM public.users WHERE id = NEW.client_id;
  END IF;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_save_relationship_names ON public.coaching_relationships;
CREATE TRIGGER trg_save_relationship_names
  BEFORE INSERT ON public.coaching_relationships
  FOR EACH ROW
  EXECUTE FUNCTION save_relationship_names();

-- 保存 session_notes 姓名快照
CREATE OR REPLACE FUNCTION save_session_note_names()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- 儲存教練姓名
  IF NEW.coach_id IS NOT NULL AND NEW.coach_name IS NULL THEN
    SELECT COALESCE(display_name, email) INTO NEW.coach_name
    FROM public.users WHERE id = NEW.coach_id;
  END IF;
  
  -- 儲存學員姓名
  IF NEW.client_id IS NOT NULL AND NEW.client_name IS NULL THEN
    SELECT COALESCE(display_name, email) INTO NEW.client_name
    FROM public.users WHERE id = NEW.client_id;
  END IF;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_save_session_note_names ON public.session_notes;
CREATE TRIGGER trg_save_session_note_names
  BEFORE INSERT ON public.session_notes
  FOR EACH ROW
  EXECUTE FUNCTION save_session_note_names();

-- ----------------------------------------------------------------------------
-- 2.4 回填現有記錄的姓名快照
-- ----------------------------------------------------------------------------

-- 回填 coaching_relationships
UPDATE public.coaching_relationships cr
SET coach_name = (
  SELECT COALESCE(u.display_name, u.email)
  FROM public.users u
  WHERE u.id = cr.coach_id
)
WHERE cr.coach_name IS NULL AND cr.coach_id IS NOT NULL;

UPDATE public.coaching_relationships cr
SET client_name = (
  SELECT COALESCE(u.display_name, u.email)
  FROM public.users u
  WHERE u.id = cr.client_id
)
WHERE cr.client_name IS NULL AND cr.client_id IS NOT NULL;

-- 回填 session_notes
UPDATE public.session_notes sn
SET coach_name = (
  SELECT COALESCE(u.display_name, u.email)
  FROM public.users u
  WHERE u.id = sn.coach_id
)
WHERE sn.coach_name IS NULL AND sn.coach_id IS NOT NULL;

UPDATE public.session_notes sn
SET client_name = (
  SELECT COALESCE(u.display_name, u.email)
  FROM public.users u
  WHERE u.id = sn.client_id
)
WHERE sn.client_name IS NULL AND sn.client_id IS NOT NULL;

-- ============================================================================
-- 完成通知
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '✅ Migration 11 完成：資料保留策略';
  RAISE NOTICE '====================================================================';
  RAISE NOTICE '';
  RAISE NOTICE '變更內容：';
  RAISE NOTICE '  ✅ coaching_relationships.client_profile（臨時欄位）';
  RAISE NOTICE '  ✅ ON DELETE CASCADE → ON DELETE SET NULL';
  RAISE NOTICE '  ✅ 姓名快照欄位（coach_name, client_name）';
  RAISE NOTICE '  ✅ 自動儲存觸發器';
  RAISE NOTICE '  ✅ 現有記錄回填';
  RAISE NOTICE '';
  RAISE NOTICE '優點：';
  RAISE NOTICE '  - 用戶刪除帳號後，歷史記錄依然保留';
  RAISE NOTICE '  - 顯示名稱可從快照欄位讀取';
  RAISE NOTICE '  - 審計與歷史查詢不受影響';
  RAISE NOTICE '';
END $$;
