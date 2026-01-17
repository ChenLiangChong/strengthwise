-- ============================================================================
-- Migration: 33_enable_realtime_availability.sql
-- 描述: 開啟 availability_slots、client_availability、appointments 的 Realtime
-- 版本: v3.9
-- 日期: 2026-01-17
-- ============================================================================

-- 開啟 Realtime for availability_slots
ALTER PUBLICATION supabase_realtime ADD TABLE availability_slots;

-- 開啟 Realtime for client_availability  
ALTER PUBLICATION supabase_realtime ADD TABLE client_availability;

-- 開啟 Realtime for appointments（跨用戶預約更新）
ALTER PUBLICATION supabase_realtime ADD TABLE appointments;

-- ============================================================================
-- 設置 REPLICA IDENTITY FULL（讓 DELETE 事件可以獲取完整 oldRecord）
-- ============================================================================
ALTER TABLE availability_slots REPLICA IDENTITY FULL;
ALTER TABLE client_availability REPLICA IDENTITY FULL;
ALTER TABLE appointments REPLICA IDENTITY FULL;

-- ============================================================================
-- 確認設置成功
-- ============================================================================
-- SELECT relname, relreplident FROM pg_class 
-- WHERE relname IN ('availability_slots', 'client_availability');
-- 結果應為 'f' (full)

-- SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
