-- ============================================================
-- StrengthWise - 創建 custom_exercises 表格
-- 用戶自訂動作功能
-- ============================================================
-- 
-- 功能需求：
-- 1. 用戶可以創建自己的動作
-- 2. 可以按身體部位統計（胸/背/腿/肩/手臂/核心）
-- 3. 可以追蹤力量進步（通過 workout_plans 記錄）
-- 4. 可以設定器材類型
-- 
-- 設計原則：
-- - 使用 TEXT ID（與 exercises 表格一致）
-- - 欄位設計與 exercises 表格相容（便於統計時合併查詢）
-- - 簡化欄位（只保留必要的統計欄位）
-- ============================================================

-- 創建 custom_exercises 表格
CREATE TABLE IF NOT EXISTS custom_exercises (
  -- 基本欄位
  id TEXT PRIMARY KEY,                    -- Firestore 相容 ID（20 字符）
  user_id UUID NOT NULL,                  -- 創建者 ID（必須）
  name TEXT NOT NULL,                     -- 動作名稱（必須）
  
  -- 分類欄位（用於統計）
  body_part TEXT NOT NULL,                -- 身體部位：胸部/背部/腿部/肩部/手臂/核心
  equipment TEXT DEFAULT '徒手',          -- 器材：徒手/啞鈴/槓鈴/機械/Cable/其他
  
  -- 詳細資訊（選填）
  description TEXT DEFAULT '',            -- 動作說明
  notes TEXT DEFAULT '',                  -- 個人筆記
  
  -- 時間戳記
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 外鍵約束
  CONSTRAINT fk_custom_exercises_user FOREIGN KEY (user_id) 
    REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================================
-- 索引：提升查詢效能
-- ============================================================

-- 按用戶查詢（最常用）
CREATE INDEX IF NOT EXISTS idx_custom_exercises_user_id 
  ON custom_exercises(user_id);

-- 按身體部位查詢（用於統計）
CREATE INDEX IF NOT EXISTS idx_custom_exercises_body_part 
  ON custom_exercises(body_part);

-- 按用戶+身體部位查詢（用於分類統計）
CREATE INDEX IF NOT EXISTS idx_custom_exercises_user_body_part 
  ON custom_exercises(user_id, body_part);

-- 按用戶+器材查詢
CREATE INDEX IF NOT EXISTS idx_custom_exercises_user_equipment 
  ON custom_exercises(user_id, equipment);

-- 全文搜尋索引（用於動作名稱搜尋）
CREATE INDEX IF NOT EXISTS idx_custom_exercises_name_trgm 
  ON custom_exercises USING gin(name gin_trgm_ops);

-- ============================================================
-- Row Level Security (RLS) 策略
-- ============================================================

-- 啟用 RLS
ALTER TABLE custom_exercises ENABLE ROW LEVEL SECURITY;

-- 策略 1：用戶只能查看自己的自訂動作
CREATE POLICY "Users can view own custom exercises"
  ON custom_exercises FOR SELECT
  USING (auth.uid() = user_id);

-- 策略 2：用戶只能創建自己的自訂動作
CREATE POLICY "Users can create own custom exercises"
  ON custom_exercises FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 策略 3：用戶只能更新自己的自訂動作
CREATE POLICY "Users can update own custom exercises"
  ON custom_exercises FOR UPDATE
  USING (auth.uid() = user_id);

-- 策略 4：用戶只能刪除自己的自訂動作
CREATE POLICY "Users can delete own custom exercises"
  ON custom_exercises FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 註解
-- ============================================================

COMMENT ON TABLE custom_exercises IS '用戶自訂動作表格（可統計、可追蹤力量進步）';
COMMENT ON COLUMN custom_exercises.id IS 'Firestore 相容 ID（20 字符隨機字串）';
COMMENT ON COLUMN custom_exercises.user_id IS '創建者 ID（UUID）';
COMMENT ON COLUMN custom_exercises.name IS '動作名稱（例如：我的深蹲變化式）';
COMMENT ON COLUMN custom_exercises.body_part IS '身體部位：胸部/背部/腿部/肩部/手臂/核心';
COMMENT ON COLUMN custom_exercises.equipment IS '器材：徒手/啞鈴/槓鈴/機械/Cable/其他';

-- ============================================================
-- 觸發器：自動更新 updated_at
-- ============================================================

CREATE OR REPLACE FUNCTION update_custom_exercises_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_custom_exercises_updated_at
  BEFORE UPDATE ON custom_exercises
  FOR EACH ROW
  EXECUTE FUNCTION update_custom_exercises_updated_at();

-- ============================================================
-- 驗證
-- ============================================================

-- 檢查表格是否創建成功
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'custom_exercises'
  ) THEN
    RAISE NOTICE '✅ custom_exercises 表格創建成功';
  ELSE
    RAISE EXCEPTION '❌ custom_exercises 表格創建失敗';
  END IF;
END $$;

-- 檢查索引數量
DO $$
DECLARE
  index_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO index_count
  FROM pg_indexes
  WHERE tablename = 'custom_exercises';
  
  RAISE NOTICE '✅ 創建了 % 個索引', index_count;
END $$;

-- 檢查 RLS 是否啟用
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'custom_exercises' 
    AND rowsecurity = true
  ) THEN
    RAISE NOTICE '✅ Row Level Security 已啟用';
  ELSE
    RAISE WARNING '⚠️  Row Level Security 未啟用';
  END IF;
END $$;

