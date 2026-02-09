-- ============================================================================
-- Migration: 34_app_config.sql
-- 描述: App 全局配置表，用於版本檢查等遠端配置
-- 版本: v5.1
-- 日期: 2026-02-09
-- ============================================================================

-- 建立 app_config 表（key-value 風格，公開讀取）
CREATE TABLE IF NOT EXISTS app_config (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE app_config IS '全局應用配置表（公開讀取，僅管理員可寫）';
COMMENT ON COLUMN app_config.key IS '配置鍵（唯一）';
COMMENT ON COLUMN app_config.value IS 'JSON 格式配置值';
COMMENT ON COLUMN app_config.description IS '配置說明';
COMMENT ON COLUMN app_config.updated_at IS '最後更新時間';

-- RLS 策略：公開讀取，禁止一般用戶寫入
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "app_config_public_read" ON app_config
  FOR SELECT
  USING (true);

-- 只有 service_role 可以寫入（透過 Supabase Dashboard 或 Admin API）
-- 不建立 INSERT/UPDATE/DELETE 的 policy，一般用戶無法寫入

-- 插入初始版本配置
INSERT INTO app_config (key, value, description) VALUES (
  'app_version',
  '{
    "latest_version": "1.1.1",
    "update_url_android": "https://play.google.com/store/apps/details?id=com.strengthwise.fitness",
    "update_url_ios": "",
    "release_notes": ""
  }'::jsonb,
  'App 版本控制配置'
) ON CONFLICT (key) DO NOTHING;
