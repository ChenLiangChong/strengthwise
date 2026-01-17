-- ============================================================
-- Migration 32: Database Webhooks for Availability Notifications
-- ============================================================
-- 版本: v3.9
-- 日期: 2025-01-17
-- 用途: 設定 availability_slots 和 client_availability 表的 Webhooks
-- 注意: 此檔案僅作為文檔參考，Webhooks 需要在 Supabase Dashboard 手動設定
-- ============================================================

-- ============================================================
-- ⚠️ 重要說明
-- ============================================================
-- Supabase Database Webhooks 需要在 Dashboard 中設定，無法透過 SQL 創建。
-- 以下是需要設定的 Webhooks 配置：
-- ============================================================

/*
=== Webhook 1: availability_slots ===

名稱: slot-changes
表格: availability_slots
事件: INSERT, DELETE
URL: https://<project-ref>.supabase.co/functions/v1/push-notify
HTTP Headers:
  - Authorization: Bearer <SUPABASE_ANON_KEY>
  - Content-Type: application/json

=== Webhook 2: client_availability ===

名稱: client-availability-changes
表格: client_availability
事件: INSERT, UPDATE, DELETE
URL: https://<project-ref>.supabase.co/functions/v1/push-notify
HTTP Headers:
  - Authorization: Bearer <SUPABASE_ANON_KEY>
  - Content-Type: application/json

=== 設定步驟 ===

1. 登入 Supabase Dashboard
2. 進入專案 → Database → Webhooks
3. 點擊 "Create a new hook"
4. 填寫以上配置
5. 儲存並啟用

=== 驗證方式 ===

1. 在 availability_slots 表新增一筆資料
2. 檢查 Edge Function logs 是否有收到 payload
3. 確認 FCM 通知是否成功發送

*/

-- 確保 RLS 政策允許讀取相關資料（供 Edge Function 使用）
-- 這些政策應該已經存在，此處僅作確認

-- availability_slots: 教練可以管理自己的時段，學員可以查看教練的時段
-- client_availability: 學員可以管理自己的偏好，教練可以查看學員的偏好

-- 檢查現有 RLS 政策
SELECT tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename IN ('availability_slots', 'client_availability')
ORDER BY tablename, policyname;
