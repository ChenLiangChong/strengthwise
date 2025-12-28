-- ============================================================================

-- 021_phase1_coaching_relationships.sql
-- v2.0 Phase 1：教練-學員綁定機制
-- 創建時間：2024-12-28
-- ============================================================================

-- ============================================================================
-- 1. 角色枚舉類型（可選，當前使用 BOOLEAN）
-- ============================================================================
-- 未來如需擴展角色（如 admin），可使用：
-- CREATE TYPE public.app_role AS ENUM ('admin', 'coach', 'client');
-- 當前階段使用 is_coach, is_student BOOLEAN 已足夠

-- ============================================================================
-- 2. coaching_relationships 表格（教練-學員綁定關係）
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.coaching_relationships (
  -- 主鍵
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- 教練和學員關聯
  coach_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  
  -- 關係狀態
  status TEXT NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'active', 'archived', 'rejected')
  ),
  
  -- 備註（教練內部使用）
  notes TEXT,
  
  -- 邀請相關
  invited_at TIMESTAMPTZ DEFAULT NOW(),
  accepted_at TIMESTAMPTZ,
  
  -- 時間戳記
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 約束
  CONSTRAINT unique_coach_client UNIQUE(coach_id, client_id),
  CONSTRAINT no_self_coaching CHECK (coach_id != client_id)
);

-- ============================================================================
-- 3. 建立索引
-- ============================================================================

-- 教練查詢自己的學員列表（核心查詢）
CREATE INDEX idx_coaching_rel_coach_status ON public.coaching_relationships(coach_id, status);

-- 學員查詢自己的教練列表
CREATE INDEX idx_coaching_rel_client_status ON public.coaching_relationships(client_id, status);

-- 狀態查詢
CREATE INDEX idx_coaching_rel_status ON public.coaching_relationships(status);

-- 時間範圍查詢
CREATE INDEX idx_coaching_rel_created_at ON public.coaching_relationships(created_at DESC);

-- ============================================================================
-- 4. 觸發器：自動更新 updated_at
-- ============================================================================
CREATE TRIGGER update_coaching_relationships_updated_at
  BEFORE UPDATE ON public.coaching_relationships
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. RLS 策略
-- ============================================================================
ALTER TABLE public.coaching_relationships ENABLE ROW LEVEL SECURITY;

-- 教練可以查看自己發起的關係
CREATE POLICY "Coaches can view their client relationships"
  ON public.coaching_relationships FOR SELECT
  TO authenticated
  USING (auth.uid() = coach_id);

-- 學員可以查看與自己相關的關係
CREATE POLICY "Clients can view their coach relationships"
  ON public.coaching_relationships FOR SELECT
  TO authenticated
  USING (auth.uid() = client_id);

-- 教練可以創建關係（邀請學員）
CREATE POLICY "Coaches can create client relationships"
  ON public.coaching_relationships FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = coach_id
    AND EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND is_coach = true
    )
  );

-- 教練可以更新自己的關係（修改備註、歸檔）
CREATE POLICY "Coaches can update their relationships"
  ON public.coaching_relationships FOR UPDATE
  TO authenticated
  USING (auth.uid() = coach_id)
  WITH CHECK (auth.uid() = coach_id);

-- 學員可以接受或拒絕邀請（狀態從 pending 改為 active/rejected）
CREATE POLICY "Clients can accept or reject invitations"
  ON public.coaching_relationships FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = client_id 
    AND status = 'pending'
  )
  WITH CHECK (
    auth.uid() = client_id 
    AND status IN ('active', 'rejected')
  );

-- 雙方都可以刪除關係（解除綁定）
CREATE POLICY "Both parties can delete relationships"
  ON public.coaching_relationships FOR DELETE
  TO authenticated
  USING (auth.uid() = coach_id OR auth.uid() = client_id);

-- ============================================================================
-- 6. 更新 users 表的 RLS 策略（跨角色查詢）
-- ============================================================================

-- 教練可以查看活躍學員的基本資料
CREATE POLICY "Coaches can view active clients profiles"
  ON public.users FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = public.users.id
        AND cr.status = 'active'
    )
  );

-- ============================================================================
-- 7. 更新 workout_plans 的 RLS 策略（教練查看學員訓練）
-- ============================================================================

-- 教練可以查看活躍學員的訓練計劃
CREATE POLICY "Coaches can view active clients workouts"
  ON public.workout_plans FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = public.workout_plans.trainee_id
        AND cr.status = 'active'
    )
  );

-- 教練可以為活躍學員創建訓練計劃
CREATE POLICY "Coaches can create workouts for active clients"
  ON public.workout_plans FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = creator_id
    AND EXISTS (
      SELECT 1 FROM public.coaching_relationships cr
      WHERE cr.coach_id = auth.uid()
        AND cr.client_id = public.workout_plans.trainee_id
        AND cr.status = 'active'
    )
  );

-- ============================================================================
-- 8. 輔助函式：檢查教練-學員關係
-- ============================================================================
CREATE OR REPLACE FUNCTION public.is_active_coaching_relationship(
  p_coach_id UUID,
  p_client_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.coaching_relationships
    WHERE coach_id = p_coach_id
      AND client_id = p_client_id
      AND status = 'active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 9. 輔助函式：獲取教練的學員數量
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_coach_client_count(
  p_coach_id UUID
)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM public.coaching_relationships
    WHERE coach_id = p_coach_id
      AND status = 'active'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 10. 測試數據（開發環境用，可選）
-- ============================================================================
-- 執行後可刪除此段

-- 範例：假設當前用戶想測試教練功能
-- UPDATE public.users SET is_coach = true WHERE id = auth.uid();

-- 範例：創建測試綁定關係
-- INSERT INTO public.coaching_relationships (coach_id, client_id, status)
-- VALUES (
--   'COACH_UUID',
--   'CLIENT_UUID',
--   'active'
-- );

-- ============================================================================
-- 完成 ✅
-- ============================================================================

-- 驗證表格已建立
SELECT 
  'coaching_relationships 表格已建立' AS message,
  COUNT(*) AS record_count
FROM public.coaching_relationships;

