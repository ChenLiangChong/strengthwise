-- =============================================
-- Migration 027: 訓練狀態追蹤欄位
-- 版本：v2.9.1
-- 日期：2026-01-04
-- 說明：支援訓練暫停/繼續功能，正確記錄訓練時長
-- =============================================

-- 新增訓練狀態追蹤欄位
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS actual_start_time TIMESTAMPTZ;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS actual_end_time TIMESTAMPTZ;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS elapsed_seconds INTEGER DEFAULT 0;
ALTER TABLE workout_plans ADD COLUMN IF NOT EXISTS training_status TEXT DEFAULT 'pending';

-- 欄位註解
COMMENT ON COLUMN workout_plans.actual_start_time IS '實際開始訓練的時間（點擊「開始訓練」時設定）';
COMMENT ON COLUMN workout_plans.actual_end_time IS '實際結束訓練的時間（點擊「完成訓練」時設定）';
COMMENT ON COLUMN workout_plans.elapsed_seconds IS '累計訓練秒數（不含暫停時間）';
COMMENT ON COLUMN workout_plans.training_status IS '訓練狀態：pending（準備中）、in_progress（進行中）、paused（已暫停）、completed（已完成）';

-- 建立索引：方便查詢進行中的訓練
CREATE INDEX IF NOT EXISTS idx_workout_plans_training_status 
ON workout_plans(trainee_id, training_status) 
WHERE training_status IN ('in_progress', 'paused');

-- 驗證
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'workout_plans' AND column_name = 'training_status'
  ) THEN
    RAISE NOTICE '✅ Migration 027 完成：訓練狀態追蹤欄位已新增';
  ELSE
    RAISE EXCEPTION '❌ Migration 027 失敗：欄位未建立';
  END IF;
END $$;

