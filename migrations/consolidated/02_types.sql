-- ============================================================================
-- Types（自定義類型）
-- 導出時間：2026-01-12 19:56:51
-- ============================================================================

-- ENUM: activity_level
DO $$ BEGIN
    CREATE TYPE activity_level AS ENUM ('sedentary', 'light', 'moderate', 'vigorous');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ENUM: appointment_status
DO $$ BEGIN
    CREATE TYPE appointment_status AS ENUM ('requested', 'confirmed', 'completed', 'cancelled', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ENUM: injury_status
DO $$ BEGIN
    CREATE TYPE injury_status AS ENUM ('acute', 'subacute', 'chronic', 'post_surgery');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ENUM: training_level
DO $$ BEGIN
    CREATE TYPE training_level AS ENUM ('beginner', 'intermediate', 'advanced');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
