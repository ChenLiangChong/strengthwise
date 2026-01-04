-- =====================================================
-- Migration 020: Remove Client Profile Column
-- =====================================================
-- 創建日期：2026-01-04
-- 描述：移除 coaching_relationships 表中的 client_profile 欄位
--      因為健康評估系統已經完全取代學員檔案功能
-- =====================================================

-- 移除 client_profile 欄位
ALTER TABLE public.coaching_relationships 
DROP COLUMN IF EXISTS client_profile;

-- 記錄完成訊息
DO $$
BEGIN
    RAISE NOTICE '✅ client_profile 欄位已從 coaching_relationships 表移除';
    RAISE NOTICE '   健康評估系統現為學員資料的唯一來源';
END $$;

