-- =====================================================
-- Phase 4A: 完整手繪板系統（向量繪圖方案）
-- =====================================================
-- 最後更新：2024-12-31
-- 
-- 設計說明：
-- 1. 底圖（note1-4.png）= 固定 PNG 檔案，放在 Flutter Assets
--    - 不儲存到資料庫
--    - UI 顯示時從 Assets 載入
-- 2. 繪圖層 = 向量資料（座標、顏色、粗細），儲存到 JSONB
--    - 大小：10-50KB（極小）
--    - 完全可編輯（撤銷、擦除、修改）
--    - 底圖層鎖定（isLocked=true），防止擦除
-- 3. 不需要 Storage（向量資料直接存 JSONB）
-- 
-- 本 Migration 包含：
-- 1. session_notes.content JSONB 結構說明
-- 2. 無需新增 Storage Bucket（向量方案不需要）
-- 3. 無需新增 RLS 策略（使用現有的 session_notes 策略）
-- =====================================================

-- =====================================================
-- Part 1: session_notes.content JSONB 結構說明
-- =====================================================

-- session_notes.content JSONB 結構（完整版）：
-- {
--   "soap": {
--     "subjective": "學員主觀描述",
--     "objective": "教練客觀觀察",
--     "assessment": "評估",
--     "plan": "計劃"
--   },
--   "visual_elements": [
--     {
--       "type": "photo",
--       "storage_path": "coach_id/client_id/timestamp_filename.png",
--       "uploaded_at": "2025-12-31T08:00:00Z"
--     },
--     {
--       "type": "drawing",  // 新增：手繪筆記類型（向量方案）
--       "template_type": "note1",  // 'note1', 'note2', 'note3', 'note4'
--       "drawing_data": {
--         // 注意：底圖（note1.png）不存在這裡
--         // 底圖是固定的 PNG，放在 Flutter Assets 中
--         // UI 顯示時從 Assets 載入，繪圖層疊加在底圖上
--         "layers": [
--           {
--             "id": "layer_1",
--             "name": "繪圖層 1",
--             "is_visible": true,
--             "is_locked": false,  // 若為 true，防止擦除（可用於保護特定標註）
--             "strokes": [
--               {
--                 "id": "stroke_1",
--                 "points": [
--                   {"x": 100.5, "y": 200.3, "pressure": 1.0},
--                   {"x": 105.2, "y": 205.8, "pressure": 1.0}
--                 ],
--                 "color": 4278190080, // Color.value (int)
--                 "stroke_width": 3.0,
--                 "opacity": 1.0,
--                 "tool": "DrawingTool.pencil" // pencil, marker, highlighter
--               }
--             ]
--           }
--         ]
--       },
--       "created_at": "2025-12-31T08:00:00Z",
--       "updated_at": "2025-12-31T08:00:00Z"
--     }
--   ],
--   "quick_tags": ["姿勢調整", "肩膀問題"],
--   "follow_up_date": "2025-01-15T10:00:00Z"
-- }
--
-- 資料量估算：
-- - 單張繪圖（50 個筆劃，每筆劃 20 個點）：~10-50KB
-- - 1,000 張繪圖：~50MB（極小，對資料庫無壓力）
-- - 對比：1,000 張 PNG 圖片：~5GB（100 倍差距！）

-- 更新 content 欄位註解
COMMENT ON COLUMN public.session_notes.content IS 'JSONB 混合內容：SOAP + 手繪圖(drawing_data) + 照片 + 語音 (Phase 4A 更新)';

-- =====================================================
-- Part 2: Storage Bucket - 不需要（向量方案）
-- =====================================================

-- 向量繪圖直接存 JSONB，不需要 Storage
-- Phase 3 的 coach_drawings bucket 可保留，用於未來可能的圖片匯出功能（可選）

-- =====================================================
-- Part 3: RLS 策略 - 使用現有策略
-- =====================================================

-- Drawing 資料存在 session_notes.content JSONB 中
-- 自動繼承 session_notes 的 8 個 RLS 策略：
-- 1. 教練查看自己撰寫的所有筆記
-- 2. 學員查看「已分享」的筆記
-- 3. 教練創建筆記
-- 4. 教練更新自己的筆記
-- 5. 教練刪除自己的筆記
-- 6. 教練查看活躍學員的筆記
-- 7. 學員可查看自己所有筆記的「元數據」
-- 8. 管理員查看所有筆記

-- 無需新增策略 ✅

-- =====================================================
-- Part 4: 驗證
-- =====================================================

-- 驗證 session_notes 表存在
SELECT 
  table_name, 
  column_name, 
  data_type, 
  col_description(
    (table_schema||'.'||table_name)::regclass::oid,
    ordinal_position
  ) as column_comment
FROM information_schema.columns
WHERE table_name = 'session_notes'
ORDER BY ordinal_position;

-- 驗證 Storage Buckets
SELECT 
  id, 
  name, 
  public
FROM storage.buckets
WHERE name IN ('session_photos', 'coach_drawings', 'voice_notes');

-- 驗證 RLS 策略
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd
FROM pg_policies
WHERE tablename = 'session_notes'
ORDER BY policyname;

