-- ============================================================
-- StrengthWise - Supabase PostgreSQL Schema
-- 階段一：核心表格建立（僅遷移系統資料）
-- ============================================================
-- 
-- 說明：
-- 1. 此遷移只包含系統級資料（exercises 和元數據表）
-- 2. users/workoutPlans 等用戶資料表會在未來需要時再建立
-- 3. 所有表格使用 UUID 主鍵（保持與 Firestore 相容）
-- ============================================================

-- 啟用必要的 PostgreSQL 擴展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- 用於全文搜尋

-- ============================================================
-- 1. exercises 表（動作庫）
-- ============================================================
CREATE TABLE IF NOT EXISTS exercises (
  id TEXT PRIMARY KEY,  -- 使用 Firestore 原有的 ID（TEXT 格式）
  name TEXT NOT NULL,
  name_en TEXT,
  action_name TEXT,
  training_type TEXT,
  body_part TEXT,
  body_parts TEXT[],  -- PostgreSQL 陣列類型
  specific_muscle TEXT,
  equipment TEXT,
  equipment_category TEXT,
  equipment_subcategory TEXT,
  joint_type TEXT,
  level1 TEXT,
  level2 TEXT,
  level3 TEXT,
  level4 TEXT,
  level5 TEXT,
  description TEXT DEFAULT '',
  image_url TEXT DEFAULT '',
  video_url TEXT DEFAULT '',
  user_id TEXT,  -- NULL = 系統內建動作，有值 = 用戶自定義動作
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引：提升查詢效能
CREATE INDEX IF NOT EXISTS idx_exercises_training_type ON exercises(training_type);
CREATE INDEX IF NOT EXISTS idx_exercises_body_part ON exercises(body_part);
CREATE INDEX IF NOT EXISTS idx_exercises_equipment ON exercises(equipment);
CREATE INDEX IF NOT EXISTS idx_exercises_user_id ON exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_exercises_name ON exercises(name);

-- 全文搜尋索引（未來可用於動作搜尋）
CREATE INDEX IF NOT EXISTS idx_exercises_name_trgm ON exercises USING gin(name gin_trgm_ops);

COMMENT ON TABLE exercises IS '訓練動作庫（794個系統內建動作 + 未來用戶自定義動作）';
COMMENT ON COLUMN exercises.user_id IS 'NULL = 系統內建動作，有值 = 用戶自定義動作';

-- ============================================================
-- 2. body_parts 表（身體部位元數據）
-- ============================================================
CREATE TABLE IF NOT EXISTS body_parts (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT DEFAULT '',
  count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE body_parts IS '身體部位分類（8個部位：胸、背、腿、肩等）';

-- ============================================================
-- 3. exercise_types 表（訓練類型元數據）
-- ============================================================
CREATE TABLE IF NOT EXISTS exercise_types (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT DEFAULT '',
  count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE exercise_types IS '訓練類型（3種：重訓、有氧、伸展）';

-- ============================================================
-- 4. equipments 表（器材列表元數據）
-- ============================================================
CREATE TABLE IF NOT EXISTS equipments (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT DEFAULT '',
  category TEXT,  -- 器材類別（例如：自由重量、機械式）
  count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE equipments IS '器材列表（21種器材：啞鈴、槓鈴、Cable等）';

-- ============================================================
-- 5. joint_types 表（關節類型元數據）
-- ============================================================
CREATE TABLE IF NOT EXISTS joint_types (
  id TEXT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT DEFAULT '',
  count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE joint_types IS '關節類型（2種：單關節、多關節）';

-- ============================================================
-- Row Level Security (RLS) 策略
-- ============================================================

-- exercises: 系統動作所有人可見
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "System exercises are viewable by all authenticated users"
  ON exercises FOR SELECT
  TO authenticated
  USING (user_id IS NULL);

-- 未來用戶自定義動作政策（目前用不到，但預留）
CREATE POLICY "Users can view own custom exercises"
  ON exercises FOR SELECT
  TO authenticated
  USING (user_id = auth.uid()::text);

CREATE POLICY "Users can create custom exercises"
  ON exercises FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid()::text);

CREATE POLICY "Users can update own custom exercises"
  ON exercises FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid()::text);

CREATE POLICY "Users can delete own custom exercises"
  ON exercises FOR DELETE
  TO authenticated
  USING (user_id = auth.uid()::text);

-- 元數據表：所有已驗證用戶可讀
ALTER TABLE body_parts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Body parts are viewable by all authenticated users"
  ON body_parts FOR SELECT
  TO authenticated
  USING (true);

ALTER TABLE exercise_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Exercise types are viewable by all authenticated users"
  ON exercise_types FOR SELECT
  TO authenticated
  USING (true);

ALTER TABLE equipments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Equipments are viewable by all authenticated users"
  ON equipments FOR SELECT
  TO authenticated
  USING (true);

ALTER TABLE joint_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Joint types are viewable by all authenticated users"
  ON joint_types FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================
-- 完成訊息
-- ============================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Schema 建立完成！';
  RAISE NOTICE '   - exercises: 動作庫（準備接收 794 個系統動作）';
  RAISE NOTICE '   - body_parts: 身體部位（8 個）';
  RAISE NOTICE '   - exercise_types: 訓練類型（3 個）';
  RAISE NOTICE '   - equipments: 器材列表（21 個）';
  RAISE NOTICE '   - joint_types: 關節類型（2 個）';
  RAISE NOTICE '';
  RAISE NOTICE '📋 下一步：執行資料遷移腳本';
END $$;

