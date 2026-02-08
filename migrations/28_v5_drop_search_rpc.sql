-- ============================================================================
-- Migration 28: 移除 search_exercises_v2 RPC 函式
-- ============================================================================
-- 原因：進階搜尋已全面改用客戶端快取（Hive 持久化），不再需要伺服器端 RPC
-- ============================================================================

DROP FUNCTION IF EXISTS search_exercises_v2(TEXT, TEXT[], TEXT[], TEXT, TEXT, BOOLEAN, TEXT, INT);

DO $$ BEGIN
    RAISE NOTICE 'Migration 28 完成：已移除 search_exercises_v2 RPC 函式';
END $$;
