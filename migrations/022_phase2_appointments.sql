-- ============================================================
-- Phase 2: 預約系統 (Appointments System)
-- ============================================================
-- 功能：教練時段管理 + 學員預約流程
-- 創建時間：2024-12-28
-- 版本：v2.0 Phase 2
-- ============================================================

-- ============================================================
-- 1. 安裝必要擴展
-- ============================================================

-- btree_gist: 支援 Exclusion Constraints（防止時間重疊）
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ============================================================
-- 2. 創建枚舉類型
-- ============================================================

-- 預約狀態
CREATE TYPE appointment_status AS ENUM (
  'requested',   -- 學員請求（待確認）
  'confirmed',   -- 教練確認
  'completed',   -- 已完成
  'cancelled'    -- 已取消
);

-- ============================================================
-- 3. availability_slots 表（教練可用時段）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.availability_slots (
  -- 基礎欄位
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  
  -- 時間範圍（PostgreSQL 原生 Range Type）
  time_range TSTZRANGE NOT NULL,
  
  -- 週期性規則（iCal RRULE 格式，可選）
  recurrence_rule TEXT,
  
  -- 特殊覆蓋（如：休假日）
  is_override BOOLEAN DEFAULT FALSE,
  
  -- 備註
  notes TEXT,
  
  -- 時間戳記
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 約束：時間範圍不能為空
  CONSTRAINT valid_time_range CHECK (NOT isempty(time_range))
);

-- 索引：加速教練查詢
CREATE INDEX idx_availability_slots_coach ON public.availability_slots(coach_id);

-- 索引：時間範圍查詢（GiST 索引支援範圍查詢）
CREATE INDEX idx_availability_slots_time ON public.availability_slots USING GIST(time_range);

-- 複合索引：教練 + 時間範圍
CREATE INDEX idx_availability_slots_coach_time ON public.availability_slots(coach_id) INCLUDE (time_range);

-- ============================================================
-- 4. appointments 表（預約記錄）
-- ============================================================

CREATE TABLE IF NOT EXISTS public.appointments (
  -- 基礎欄位
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  
  -- 時間範圍
  time_range TSTZRANGE NOT NULL,
  
  -- 狀態
  status appointment_status NOT NULL DEFAULT 'requested',
  
  -- 關聯訓練計劃（可選）
  workout_plan_id TEXT REFERENCES public.workout_plans(id) ON DELETE SET NULL,
  
  -- 備註
  notes TEXT,
  client_notes TEXT,  -- 學員備註
  coach_notes TEXT,   -- 教練備註（私密）
  
  -- 取消原因
  cancellation_reason TEXT,
  cancelled_by UUID REFERENCES public.users(id),
  cancelled_at TIMESTAMPTZ,
  
  -- 時間戳記
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 約束：時間範圍不能為空
  CONSTRAINT valid_appointment_time_range CHECK (NOT isempty(time_range)),
  
  -- 約束：教練和學員不能是同一人
  CONSTRAINT different_coach_client CHECK (coach_id != client_id)
);

-- ============================================================
-- 5. 排除約束（防止雙重預約）⭐ 核心功能
-- ============================================================

-- 防止同一教練在同一時段被重複預約
ALTER TABLE public.appointments
ADD CONSTRAINT no_coach_overlap
EXCLUDE USING GIST (
  coach_id WITH =,              -- 同一教練
  time_range WITH &&            -- 時間範圍不可重疊
) WHERE (status IN ('requested', 'confirmed'));  -- 只檢查未取消的預約

-- ============================================================
-- 6. 索引優化
-- ============================================================

-- 基礎索引
CREATE INDEX idx_appointments_coach ON public.appointments(coach_id);
CREATE INDEX idx_appointments_client ON public.appointments(client_id);
CREATE INDEX idx_appointments_status ON public.appointments(status);

-- 時間範圍索引（GiST）
CREATE INDEX idx_appointments_time ON public.appointments USING GIST(time_range);

-- 複合索引：教練 + 狀態（查詢待確認預約）
CREATE INDEX idx_appointments_coach_status ON public.appointments(coach_id, status);

-- 複合索引：學員 + 狀態（查詢我的預約）
CREATE INDEX idx_appointments_client_status ON public.appointments(client_id, status);

-- 關聯訓練計劃索引
CREATE INDEX idx_appointments_workout_plan ON public.appointments(workout_plan_id) WHERE workout_plan_id IS NOT NULL;

-- ============================================================
-- 7. RLS 策略 - availability_slots
-- ============================================================

ALTER TABLE public.availability_slots ENABLE ROW LEVEL SECURITY;

-- 教練查看自己的時段
CREATE POLICY "coaches_view_own_slots"
ON public.availability_slots FOR SELECT
USING (auth.uid() = coach_id);

-- 教練插入自己的時段
CREATE POLICY "coaches_insert_own_slots"
ON public.availability_slots FOR INSERT
WITH CHECK (auth.uid() = coach_id);

-- 教練更新自己的時段
CREATE POLICY "coaches_update_own_slots"
ON public.availability_slots FOR UPDATE
USING (auth.uid() = coach_id)
WITH CHECK (auth.uid() = coach_id);

-- 教練刪除自己的時段
CREATE POLICY "coaches_delete_own_slots"
ON public.availability_slots FOR DELETE
USING (auth.uid() = coach_id);

-- 活躍學員查看自己教練的可用時段
CREATE POLICY "clients_view_coach_slots"
ON public.availability_slots FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.coaching_relationships cr
    WHERE cr.coach_id = availability_slots.coach_id
      AND cr.client_id = auth.uid()
      AND cr.status = 'active'
  )
);

-- ============================================================
-- 8. RLS 策略 - appointments
-- ============================================================

ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- 教練查看自己的所有預約
CREATE POLICY "coaches_view_own_appointments"
ON public.appointments FOR SELECT
USING (auth.uid() = coach_id);

-- 學員查看自己的所有預約
CREATE POLICY "clients_view_own_appointments"
ON public.appointments FOR SELECT
USING (auth.uid() = client_id);

-- 學員創建預約（僅能預約自己的教練）
CREATE POLICY "clients_create_appointments"
ON public.appointments FOR INSERT
WITH CHECK (
  auth.uid() = client_id
  AND EXISTS (
    SELECT 1 FROM public.coaching_relationships cr
    WHERE cr.coach_id = appointments.coach_id
      AND cr.client_id = auth.uid()
      AND cr.status = 'active'
  )
);

-- 教練更新自己的預約（確認/取消）
CREATE POLICY "coaches_update_own_appointments"
ON public.appointments FOR UPDATE
USING (auth.uid() = coach_id)
WITH CHECK (auth.uid() = coach_id);

-- 學員更新自己的預約（取消/修改備註）
CREATE POLICY "clients_update_own_appointments"
ON public.appointments FOR UPDATE
USING (auth.uid() = client_id)
WITH CHECK (auth.uid() = client_id);

-- ============================================================
-- 9. 觸發器：自動更新 updated_at
-- ============================================================

-- availability_slots 更新時間觸發器
CREATE OR REPLACE FUNCTION update_availability_slots_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_availability_slots_updated_at
BEFORE UPDATE ON public.availability_slots
FOR EACH ROW
EXECUTE FUNCTION update_availability_slots_updated_at();

-- appointments 更新時間觸發器
CREATE OR REPLACE FUNCTION update_appointments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_appointments_updated_at
BEFORE UPDATE ON public.appointments
FOR EACH ROW
EXECUTE FUNCTION update_appointments_updated_at();

-- ============================================================
-- 10. 輔助函數：查詢可用時段
-- ============================================================

-- 查詢教練在特定日期範圍內的可用時段（排除已預約時段）
CREATE OR REPLACE FUNCTION get_available_slots(
  p_coach_id UUID,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ
)
RETURNS TABLE (
  slot_id UUID,
  time_range TSTZRANGE,
  is_booked BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    avs.id AS slot_id,
    avs.time_range,
    EXISTS (
      SELECT 1 FROM public.appointments apt
      WHERE apt.coach_id = p_coach_id
        AND apt.time_range && avs.time_range
        AND apt.status IN ('requested', 'confirmed')
    ) AS is_booked
  FROM public.availability_slots avs
  WHERE avs.coach_id = p_coach_id
    AND avs.time_range && tstzrange(p_start_time, p_end_time)
  ORDER BY avs.time_range;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 11. 輔助函數：檢查時段衝突
-- ============================================================

CREATE OR REPLACE FUNCTION check_appointment_conflict(
  p_coach_id UUID,
  p_time_range TSTZRANGE,
  p_exclude_appointment_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_conflict_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_conflict_count
  FROM public.appointments
  WHERE coach_id = p_coach_id
    AND time_range && p_time_range
    AND status IN ('requested', 'confirmed')
    AND (p_exclude_appointment_id IS NULL OR id != p_exclude_appointment_id);
  
  RETURN v_conflict_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 12. 註解（Documentation）
-- ============================================================

COMMENT ON TABLE public.availability_slots IS 'Phase 2: 教練可用時段設定';
COMMENT ON TABLE public.appointments IS 'Phase 2: 預約記錄（學員與教練）';

COMMENT ON COLUMN public.availability_slots.time_range IS '時間範圍（TSTZRANGE），如：[2024-12-28 10:00, 2024-12-28 11:00)';
COMMENT ON COLUMN public.availability_slots.recurrence_rule IS 'iCal RRULE 格式，如：FREQ=WEEKLY;BYDAY=MO,WE,FR';
COMMENT ON COLUMN public.availability_slots.is_override IS '是否為特殊覆蓋（如休假日，優先於週期性規則）';

COMMENT ON COLUMN public.appointments.time_range IS '預約時間範圍（TSTZRANGE）';
COMMENT ON COLUMN public.appointments.status IS '預約狀態：requested（待確認）、confirmed（已確認）、completed（已完成）、cancelled（已取消）';
COMMENT ON COLUMN public.appointments.workout_plan_id IS '關聯的訓練計劃 ID（可選）';

COMMENT ON CONSTRAINT no_coach_overlap ON public.appointments IS '⭐ 核心約束：防止同一教練同一時段被重複預約（GiST 排除約束）';

-- ============================================================
-- Migration 完成
-- ============================================================

-- 顯示完成訊息
DO $$ 
BEGIN 
  RAISE NOTICE '============================================================';
  RAISE NOTICE 'Phase 2 Migration Completed Successfully!';
  RAISE NOTICE '============================================================';
  RAISE NOTICE 'Created Tables:';
  RAISE NOTICE '  - availability_slots (教練可用時段)';
  RAISE NOTICE '  - appointments (預約記錄)';
  RAISE NOTICE '';
  RAISE NOTICE 'Key Features:';
  RAISE NOTICE '  ✅ btree_gist 擴展（支援時間範圍查詢）';
  RAISE NOTICE '  ✅ 排除約束（防止雙重預約）';
  RAISE NOTICE '  ✅ RLS 策略（教練/學員權限控制）';
  RAISE NOTICE '  ✅ 自動更新觸發器';
  RAISE NOTICE '  ✅ 輔助查詢函數';
  RAISE NOTICE '';
  RAISE NOTICE 'Next Steps:';
  RAISE NOTICE '  1. 實作 Model 層（AppointmentModel, AvailabilitySlotModel）';
  RAISE NOTICE '  2. 實作 Service Interface';
  RAISE NOTICE '  3. 實作 Service 層（Supabase 操作）';
  RAISE NOTICE '  4. 實作 Controller 層';
  RAISE NOTICE '  5. 實作 UI 層';
  RAISE NOTICE '============================================================';
END $$;

