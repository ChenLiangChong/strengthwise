-- =====================================================
-- Phase 3: 視覺化筆記與雙向時間管理系統
-- =====================================================
-- 最後更新：2024-12-29
-- 
-- 本 Migration 包含：
-- 1. session_notes 表（視覺化筆記 + SOAP 格式）
-- 2. client_availability 表（學員時間偏好）
-- 3. Storage Buckets（手繪圖、照片、語音）
-- 4. RLS 策略（15 個策略）
-- =====================================================

-- =====================================================
-- Part 1: session_notes 表（視覺化筆記系統）
-- =====================================================

CREATE TABLE IF NOT EXISTS public.session_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- 關聯欄位
  client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  coach_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
  workout_log_id TEXT REFERENCES public.workout_plans(id) ON DELETE SET NULL, -- Firestore 相容 ID
  
  -- 內容欄位（JSONB 混合內容結構）
  content JSONB NOT NULL DEFAULT '{}',
  
  -- 隱私控制
  visibility TEXT NOT NULL DEFAULT 'private' CHECK (visibility IN ('private', 'shared')),
  
  -- 時間戳
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- 索引優化
  CONSTRAINT session_notes_coach_client_valid CHECK (coach_id != client_id)
);

-- 註解
COMMENT ON TABLE public.session_notes IS '視覺化筆記系統（v2.0 Phase 3）';
COMMENT ON COLUMN public.session_notes.content IS 'JSONB 混合內容：SOAP + 手繪圖 + 照片 + 語音';
COMMENT ON COLUMN public.session_notes.visibility IS 'private: 教練私人筆記 | shared: 學員可見';

-- 索引
CREATE INDEX idx_session_notes_client ON public.session_notes(client_id, created_at DESC);
CREATE INDEX idx_session_notes_coach ON public.session_notes(coach_id, created_at DESC);
CREATE INDEX idx_session_notes_appointment ON public.session_notes(appointment_id) WHERE appointment_id IS NOT NULL;
CREATE INDEX idx_session_notes_workout ON public.session_notes(workout_log_id) WHERE workout_log_id IS NOT NULL;
CREATE INDEX idx_session_notes_visibility ON public.session_notes(visibility, client_id) WHERE visibility = 'shared';

-- JSONB GIN 索引（支援快速標籤搜尋）
CREATE INDEX idx_session_notes_content_gin ON public.session_notes USING gin(content jsonb_path_ops);

-- 自動更新 updated_at
CREATE OR REPLACE FUNCTION public.update_session_notes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER session_notes_updated_at_trigger
BEFORE UPDATE ON public.session_notes
FOR EACH ROW EXECUTE FUNCTION public.update_session_notes_updated_at();

-- =====================================================
-- Part 2: client_availability 表（學員時間偏好）
-- =====================================================

CREATE TABLE IF NOT EXISTS public.client_availability (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- 關聯欄位
  client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  
  -- 時間範圍（使用 PostgreSQL TSTZRANGE）
  time_range TSTZRANGE NOT NULL,
  
  -- 週期性規則（iCal RRULE 格式）
  recurrence_rule TEXT, -- 例如：FREQ=WEEKLY;BYDAY=MO,WE,FR
  
  -- 優先級
  priority TEXT NOT NULL DEFAULT 'available' CHECK (priority IN ('preferred', 'available', 'avoid')),
  
  -- 備註
  notes TEXT,
  
  -- 時間戳
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 註解
COMMENT ON TABLE public.client_availability IS '學員時間偏好系統（v2.0 Phase 3）';
COMMENT ON COLUMN public.client_availability.time_range IS '時間範圍（TSTZRANGE）';
COMMENT ON COLUMN public.client_availability.recurrence_rule IS 'iCal RRULE 格式（支援週期性）';
COMMENT ON COLUMN public.client_availability.priority IS 'preferred: 最佳時段 | available: 可用 | avoid: 避免';

-- 索引（使用 GiST 索引支援範圍查詢）
CREATE INDEX idx_client_availability_client ON public.client_availability(client_id, priority);
CREATE INDEX idx_client_availability_time_range ON public.client_availability USING gist(time_range);
CREATE INDEX idx_client_availability_composite ON public.client_availability USING gist(client_id, time_range);

-- 自動更新 updated_at
CREATE TRIGGER client_availability_updated_at_trigger
BEFORE UPDATE ON public.client_availability
FOR EACH ROW EXECUTE FUNCTION public.update_session_notes_updated_at();

-- =====================================================
-- Part 3: Storage Buckets 配置
-- =====================================================
-- 注意：Supabase Storage Buckets 需要透過 Supabase Dashboard 或 API 創建
-- 以下為文檔說明，實際操作請參考 docs/PHASE3_STORAGE_SETUP.md

/*
需要創建的 3 個 Storage Buckets：

1. coach_drawings（手繪圖片）
   - Public: false
   - File size limit: 5MB
   - Allowed MIME types: image/png, image/jpeg
   - Folder structure: {coach_id}/{session_id}/{filename}.png

2. session_photos（現場照片）
   - Public: false
   - File size limit: 10MB
   - Allowed MIME types: image/jpeg, image/png
   - Folder structure: {coach_id}/{session_id}/{filename}.jpg

3. voice_notes（語音筆記）
   - Public: false
   - File size limit: 20MB
   - Allowed MIME types: audio/m4a, audio/mpeg, audio/wav
   - Folder structure: {coach_id}/{session_id}/{filename}.m4a
*/

-- =====================================================
-- Part 4: RLS 策略（Row Level Security）
-- =====================================================

-- 啟用 RLS
ALTER TABLE public.session_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_availability ENABLE ROW LEVEL SECURITY;

-- ----------------
-- session_notes RLS 策略（8 個）
-- ----------------

-- 1. 教練查看自己撰寫的所有筆記
CREATE POLICY "Coaches view own notes"
ON public.session_notes FOR SELECT
USING (coach_id = auth.uid());

-- 2. 學員查看「已分享」的筆記
CREATE POLICY "Clients view shared notes"
ON public.session_notes FOR SELECT
USING (
  client_id = auth.uid() 
  AND visibility = 'shared'
);

-- 3. 教練創建筆記
CREATE POLICY "Coaches create notes"
ON public.session_notes FOR INSERT
WITH CHECK (
  coach_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.coaching_relationships cr
    WHERE cr.coach_id = auth.uid()
    AND cr.client_id = client_id
    AND cr.status = 'active'
  )
);

-- 4. 教練更新自己的筆記
CREATE POLICY "Coaches update own notes"
ON public.session_notes FOR UPDATE
USING (coach_id = auth.uid())
WITH CHECK (coach_id = auth.uid());

-- 5. 教練刪除自己的筆記
CREATE POLICY "Coaches delete own notes"
ON public.session_notes FOR DELETE
USING (coach_id = auth.uid());

-- 6. 教練查看活躍學員的筆記（跨教練協作場景）
CREATE POLICY "Coaches view active clients notes"
ON public.session_notes FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.coaching_relationships cr
    WHERE cr.coach_id = auth.uid()
    AND cr.client_id = client_id
    AND cr.status = 'active'
  )
);

-- 7. 學員可查看自己所有筆記的「元數據」（但內容受 visibility 限制）
-- 此策略僅供統計用途（例如：學員看到「教練已寫 5 篇筆記，其中 2 篇已分享」）
CREATE POLICY "Clients view own notes metadata"
ON public.session_notes FOR SELECT
USING (client_id = auth.uid());

-- 8. 管理員查看所有筆記（可選，用於數據審計）
CREATE POLICY "Admins view all notes"
ON public.session_notes FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = auth.uid()
    AND u.is_coach = TRUE
    -- 可擴展為檢查 is_admin 欄位
  )
);

-- ----------------
-- client_availability RLS 策略（7 個）
-- ----------------

-- 1. 學員查看自己的時間偏好
CREATE POLICY "Clients view own availability"
ON public.client_availability FOR SELECT
USING (client_id = auth.uid());

-- 2. 學員創建時間偏好
CREATE POLICY "Clients create availability"
ON public.client_availability FOR INSERT
WITH CHECK (client_id = auth.uid());

-- 3. 學員更新自己的時間偏好
CREATE POLICY "Clients update own availability"
ON public.client_availability FOR UPDATE
USING (client_id = auth.uid())
WITH CHECK (client_id = auth.uid());

-- 4. 學員刪除自己的時間偏好
CREATE POLICY "Clients delete own availability"
ON public.client_availability FOR DELETE
USING (client_id = auth.uid());

-- 5. 教練查看活躍學員的時間偏好
CREATE POLICY "Coaches view active clients availability"
ON public.client_availability FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.coaching_relationships cr
    WHERE cr.coach_id = auth.uid()
    AND cr.client_id = client_id
    AND cr.status = 'active'
  )
);

-- 6. 教練可代學員創建時間偏好（可選，視業務需求）
CREATE POLICY "Coaches create clients availability"
ON public.client_availability FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.coaching_relationships cr
    WHERE cr.coach_id = auth.uid()
    AND cr.client_id = client_id
    AND cr.status = 'active'
  )
);

-- 7. 教練可代學員更新時間偏好（可選）
CREATE POLICY "Coaches update clients availability"
ON public.client_availability FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.coaching_relationships cr
    WHERE cr.coach_id = auth.uid()
    AND cr.client_id = client_id
    AND cr.status = 'active'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.coaching_relationships cr
    WHERE cr.coach_id = auth.uid()
    AND cr.client_id = client_id
    AND cr.status = 'active'
  )
);

-- =====================================================
-- Part 5: 輔助函數
-- =====================================================

-- 函數：生成 Signed URL（供 App 層調用）
-- 注意：實際 Signed URL 生成由 Supabase Storage Client 完成
-- 此函數僅為文檔參考，實際實作在 Service 層

/*
Dart/Flutter 實作範例：

```dart
// 生成 24 小時有效的 Signed URL
Future<String> generateSignedUrl(String storagePath) async {
  final signedUrl = await supabase.storage
    .from('coach_drawings')
    .createSignedUrl(storagePath, 86400); // 24 hours
  
  return signedUrl;
}
```
*/

-- =====================================================
-- Part 6: 測試資料（開發環境）
-- =====================================================

-- 測試資料 1：教練創建 session_notes（含 JSONB 結構）
INSERT INTO public.session_notes (
  client_id,
  coach_id,
  content,
  visibility
)
SELECT 
  '1d7f5ed6-7759-4abc-9832-9db791e75e4f'::UUID, -- 學員 UUID
  'd1798674-0b96-4c47-a7c7-ee20a5372a03'::UUID, -- 教練 UUID
  '{
    "soap": {
      "subjective": "學員反應右膝不適",
      "objective": "深蹲時膝蓋內夾，重心偏右",
      "assessment": "可能臀中肌無力",
      "plan": "增加彈力帶訓練"
    },
    "visual_elements": [
      {
        "type": "drawing",
        "storage_path": "coach_drawings/d1798674-0b96-4c47-a7c7-ee20a5372a03/test-session/squat-issue.png",
        "template": "body_side_squat"
      }
    ],
    "quick_tags": ["姿勢問題", "膝蓋", "深蹲"]
  }'::JSONB,
  'shared'
WHERE EXISTS (
  SELECT 1 FROM public.users 
  WHERE id = '1d7f5ed6-7759-4abc-9832-9db791e75e4f'::UUID
)
ON CONFLICT DO NOTHING;

-- 測試資料 2：學員創建 client_availability（週期性時間偏好）
INSERT INTO public.client_availability (
  client_id,
  time_range,
  recurrence_rule,
  priority,
  notes
)
SELECT 
  '1d7f5ed6-7759-4abc-9832-9db791e75e4f'::UUID, -- 學員 UUID
  '[2025-01-06 18:00:00+08, 2025-01-06 20:00:00+08)'::TSTZRANGE,
  'FREQ=WEEKLY;BYDAY=MO,WE,FR',
  'preferred',
  '這是我最常去健身房的時段'
WHERE EXISTS (
  SELECT 1 FROM public.users 
  WHERE id = '1d7f5ed6-7759-4abc-9832-9db791e75e4f'::UUID
)
ON CONFLICT DO NOTHING;

-- =====================================================
-- Part 7: 驗證 SQL
-- =====================================================

-- 驗證 1：檢查表格是否創建成功
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'session_notes'
  ) THEN
    RAISE NOTICE '✅ Table session_notes created successfully';
  ELSE
    RAISE EXCEPTION '❌ Table session_notes creation failed';
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'client_availability'
  ) THEN
    RAISE NOTICE '✅ Table client_availability created successfully';
  ELSE
    RAISE EXCEPTION '❌ Table client_availability creation failed';
  END IF;
END $$;

-- 驗證 2：檢查 RLS 是否啟用
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'session_notes' 
    AND rowsecurity = true
  ) THEN
    RAISE NOTICE '✅ RLS enabled on session_notes';
  ELSE
    RAISE EXCEPTION '❌ RLS not enabled on session_notes';
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'client_availability' 
    AND rowsecurity = true
  ) THEN
    RAISE NOTICE '✅ RLS enabled on client_availability';
  ELSE
    RAISE EXCEPTION '❌ RLS not enabled on client_availability';
  END IF;
END $$;

-- 驗證 3：檢查索引是否創建成功
DO $$
DECLARE
  index_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO index_count
  FROM pg_indexes
  WHERE schemaname = 'public'
  AND tablename IN ('session_notes', 'client_availability');
  
  IF index_count >= 10 THEN
    RAISE NOTICE '✅ Indexes created successfully (% indexes)', index_count;
  ELSE
    RAISE WARNING '⚠️ Expected at least 10 indexes, found %', index_count;
  END IF;
END $$;

-- 驗證 4：檢查 RLS 策略數量
DO $$
DECLARE
  policy_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
  AND tablename IN ('session_notes', 'client_availability');
  
  IF policy_count >= 15 THEN
    RAISE NOTICE '✅ RLS policies created successfully (% policies)', policy_count;
  ELSE
    RAISE WARNING '⚠️ Expected at least 15 policies, found %', policy_count;
  END IF;
END $$;

-- =====================================================
-- Migration 完成
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '🎉 Phase 3 Migration completed successfully!';
  RAISE NOTICE '📝 Next steps:';
  RAISE NOTICE '   1. Configure Storage Buckets in Supabase Dashboard';
  RAISE NOTICE '   2. Run Flutter Model generation';
  RAISE NOTICE '   3. Implement Service layer';
  RAISE NOTICE '   4. Build UI components';
END $$;

