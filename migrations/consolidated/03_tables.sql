-- ============================================================================
-- Tables（表結構）
-- 導出時間：2026-01-12 19:56:52
-- ============================================================================

-- ============================================================================
-- Table: appointments
-- ============================================================================
CREATE TABLE IF NOT EXISTS appointments (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    coach_id uuid NOT NULL,
    client_id uuid NOT NULL,
    time_range tstzrange NOT NULL,
    status USER-DEFINED NOT NULL DEFAULT 'requested'::appointment_status,
    workout_plan_id text,
    notes text,
    client_notes text,
    coach_notes text,
    cancellation_reason text,
    cancelled_by uuid,
    cancelled_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (id)
);

ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: availability_slots
-- ============================================================================
CREATE TABLE IF NOT EXISTS availability_slots (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    coach_id uuid NOT NULL,
    time_range tstzrange NOT NULL,
    recurrence_rule text,
    is_override boolean DEFAULT false,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (id)
);

ALTER TABLE availability_slots ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: body_data
-- ============================================================================
CREATE TABLE IF NOT EXISTS body_data (
    id text NOT NULL,
    user_id uuid NOT NULL,
    record_date timestamp with time zone NOT NULL,
    weight double precision NOT NULL,
    body_fat double precision,
    muscle_mass double precision,
    bmi double precision,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    PRIMARY KEY (id)
);

ALTER TABLE body_data ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: body_parts
-- ============================================================================
CREATE TABLE IF NOT EXISTS body_parts (
    id text NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text,
    count integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    name_en text,
    description_en text,
    PRIMARY KEY (id),
    UNIQUE (name)
);

ALTER TABLE body_parts ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: client_availability
-- ============================================================================
CREATE TABLE IF NOT EXISTS client_availability (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    client_id uuid NOT NULL,
    time_range tstzrange NOT NULL,
    recurrence_rule text,
    priority text NOT NULL DEFAULT 'available'::text,
    notes text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

ALTER TABLE client_availability ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: coach_assessment_notes
-- ============================================================================
CREATE TABLE IF NOT EXISTS coach_assessment_notes (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    coach_id uuid NOT NULL,
    assessment_id uuid NOT NULL,
    notes text NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (coach_id),
    UNIQUE (assessment_id)
);

ALTER TABLE coach_assessment_notes ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: coach_booking_settings
-- ============================================================================
CREATE TABLE IF NOT EXISTS coach_booking_settings (
    coach_id uuid NOT NULL,
    buffer_before interval DEFAULT '00:15:00'::interval,
    buffer_after interval DEFAULT '00:15:00'::interval,
    min_booking_notice interval NOT NULL DEFAULT '02:00:00'::interval,
    max_booking_window interval DEFAULT '60 days'::interval,
    slot_increment interval DEFAULT '00:30:00'::interval,
    default_session_duration interval DEFAULT '01:00:00'::interval,
    max_sessions_per_day integer DEFAULT 8,
    timezone text NOT NULL DEFAULT 'Asia/Taipei'::text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (coach_id)
);

ALTER TABLE coach_booking_settings ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: coach_display_preferences
-- ============================================================================
CREATE TABLE IF NOT EXISTS coach_display_preferences (
    coach_id uuid NOT NULL,
    health_assessment_fields ARRAY DEFAULT ARRAY['safety_screening'::text, 'injuries'::text, 'medications'::text, 'training_experience'::text, 'training_goals'::text],
    client_list_sort_by text DEFAULT 'name'::text,
    client_list_sort_order text DEFAULT 'asc'::text,
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    PRIMARY KEY (coach_id)
);

ALTER TABLE coach_display_preferences ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: coaches
-- ============================================================================
CREATE TABLE IF NOT EXISTS coaches (
    id uuid NOT NULL,
    display_name text,
    headline text,
    bio text,
    specialties jsonb DEFAULT '[]'::jsonb,
    certifications jsonb DEFAULT '[]'::jsonb,
    years_experience integer DEFAULT 0,
    languages jsonb DEFAULT '["zh-TW"]'::jsonb,
    service_types jsonb DEFAULT '[]'::jsonb,
    hourly_rate_min integer,
    hourly_rate_max integer,
    currency text DEFAULT 'TWD'::text,
    offers_free_consultation boolean DEFAULT false,
    weekly_availability jsonb DEFAULT '{}'::jsonb,
    location_lat double precision,
    location_lng double precision,
    service_radius_km integer,
    gym_access text,
    verified_status text DEFAULT 'pending'::text,
    slug text,
    average_rating numeric DEFAULT 0,
    review_count integer DEFAULT 0,
    gallery_images jsonb DEFAULT '[]'::jsonb,
    social_links jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (slug)
);

ALTER TABLE coaches ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: coaching_relationships
-- ============================================================================
CREATE TABLE IF NOT EXISTS coaching_relationships (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    coach_id uuid,
    client_id uuid,
    status text NOT NULL DEFAULT 'pending'::text,
    invited_at timestamp with time zone DEFAULT now(),
    accepted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    coach_name text,
    client_name text,
    PRIMARY KEY (id),
    UNIQUE (coach_id),
    UNIQUE (client_id)
);

ALTER TABLE coaching_relationships ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: custom_exercises
-- ============================================================================
CREATE TABLE IF NOT EXISTS custom_exercises (
    id text NOT NULL,
    user_id uuid,
    name text NOT NULL,
    body_part text NOT NULL,
    equipment text DEFAULT '徒手'::text,
    description text DEFAULT ''::text,
    notes text DEFAULT ''::text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    training_type text DEFAULT '阻力訓練'::text,
    training_type_en text DEFAULT 'Resistance Training'::text,
    body_part_en text DEFAULT ''::text,
    equipment_en text DEFAULT ''::text,
    tracking_mode text DEFAULT 'weight_reps'::text,
    PRIMARY KEY (id)
);

ALTER TABLE custom_exercises ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: daily_readiness
-- ============================================================================
CREATE TABLE IF NOT EXISTS daily_readiness (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    appointment_id uuid,
    session_note_id uuid,
    log_date date NOT NULL DEFAULT CURRENT_DATE,
    readiness_score integer,
    traffic_light text,
    metrics jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (user_id),
    UNIQUE (appointment_id)
);

ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: daily_workout_summary
-- ============================================================================
CREATE TABLE IF NOT EXISTS daily_workout_summary (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    date date NOT NULL,
    workout_count integer DEFAULT 0,
    total_exercises integer DEFAULT 0,
    total_sets integer DEFAULT 0,
    total_volume numeric DEFAULT 0,
    resistance_training_count integer DEFAULT 0,
    cardio_count integer DEFAULT 0,
    mobility_count integer DEFAULT 0,
    total_training_time integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    completed_workout_count integer DEFAULT 0,
    partial_workout_count integer DEFAULT 0,
    scheduled_workout_count integer DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE (user_id),
    UNIQUE (date)
);

ALTER TABLE daily_workout_summary ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: exercise_types
-- ============================================================================
CREATE TABLE IF NOT EXISTS exercise_types (
    id text NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text,
    count integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    name_en text,
    description_en text,
    PRIMARY KEY (id),
    UNIQUE (name)
);

ALTER TABLE exercise_types ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: exercises
-- ============================================================================
CREATE TABLE IF NOT EXISTS exercises (
    id text NOT NULL,
    name text NOT NULL,
    name_en text,
    action_name text,
    training_type text,
    body_part text,
    body_parts ARRAY,
    specific_muscle text,
    equipment text,
    equipment_category text,
    equipment_subcategory text,
    joint_type text,
    level1 text,
    level2 text,
    level3 text,
    level4 text,
    level5 text,
    description text DEFAULT ''::text,
    image_url text DEFAULT ''::text,
    video_url text DEFAULT ''::text,
    user_id text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    training_type_en text,
    body_part_en text,
    specific_muscle_en text,
    equipment_category_en text,
    equipment_subcategory_en text,
    tracking_mode text DEFAULT 'weight_reps'::text,
    PRIMARY KEY (id)
);

ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: health_assessments
-- ============================================================================
CREATE TABLE IF NOT EXISTS health_assessments (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    assessed_by uuid,
    assessment_date timestamp with time zone NOT NULL DEFAULT now(),
    heart_disease boolean NOT NULL DEFAULT false,
    heart_disease_note text,
    chest_pain_exercise boolean NOT NULL DEFAULT false,
    chest_pain_rest boolean NOT NULL DEFAULT false,
    dizziness boolean NOT NULL DEFAULT false,
    bone_joint_problem boolean NOT NULL DEFAULT false,
    bone_joint_note text,
    medication boolean NOT NULL DEFAULT false,
    medication_note text,
    other_reason boolean NOT NULL DEFAULT false,
    other_reason_note text,
    is_cleared boolean,
    cardiovascular_details jsonb DEFAULT '{}'::jsonb,
    musculoskeletal_details jsonb DEFAULT '[]'::jsonb,
    metabolic_details jsonb DEFAULT '{}'::jsonb,
    respiratory_details jsonb DEFAULT '{}'::jsonb,
    training_experience USER-DEFINED,
    training_years numeric,
    occupation_activity USER-DEFINED,
    equipment_access ARRAY DEFAULT ARRAY[]::text[],
    weekly_sessions integer,
    sleep_hours numeric,
    training_goals jsonb DEFAULT '{}'::jsonb,
    version integer NOT NULL DEFAULT 1,
    is_current boolean NOT NULL DEFAULT true,
    emergency_contact jsonb,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    sleep_hours_min double precision,
    sleep_hours_max double precision,
    PRIMARY KEY (id)
);

ALTER TABLE health_assessments ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: injury_coach_notes
-- ============================================================================
CREATE TABLE IF NOT EXISTS injury_coach_notes (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    coach_id uuid NOT NULL,
    client_id uuid NOT NULL,
    injury_site text NOT NULL,
    note text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (coach_id),
    UNIQUE (client_id),
    UNIQUE (injury_site)
);

ALTER TABLE injury_coach_notes ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: invite_codes
-- ============================================================================
CREATE TABLE IF NOT EXISTS invite_codes (
    code text NOT NULL,
    coach_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    expires_at timestamp with time zone NOT NULL DEFAULT (now() + '00:05:00'::interval),
    PRIMARY KEY (code)
);

ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: notes
-- ============================================================================
CREATE TABLE IF NOT EXISTS notes (
    id text NOT NULL,
    user_id uuid NOT NULL,
    title text NOT NULL,
    text_content text,
    drawing_points jsonb DEFAULT '[]'::jsonb,
    workout_plan_id text,
    appointment_id text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (id)
);

ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: personal_records
-- ============================================================================
CREATE TABLE IF NOT EXISTS personal_records (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    exercise_id text NOT NULL,
    exercise_name text NOT NULL,
    max_weight numeric DEFAULT 0,
    max_reps integer DEFAULT 0,
    max_volume numeric DEFAULT 0,
    achieved_date date NOT NULL,
    workout_plan_id text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    body_part text,
    PRIMARY KEY (id),
    UNIQUE (user_id),
    UNIQUE (exercise_id)
);

ALTER TABLE personal_records ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: session_notes
-- ============================================================================
CREATE TABLE IF NOT EXISTS session_notes (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    client_id uuid,
    coach_id uuid,
    appointment_id uuid,
    workout_log_id text,
    content jsonb NOT NULL DEFAULT '{}'::jsonb,
    visibility text NOT NULL DEFAULT 'private'::text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    title text NOT NULL DEFAULT to_char((now() AT TIME ZONE 'Asia/Taipei'::text), 'MM/DD 課程筆記'::text),
    coach_name text,
    client_name text,
    hidden_by_client boolean DEFAULT false,
    hidden_by_coach boolean DEFAULT false,
    PRIMARY KEY (id)
);

ALTER TABLE session_notes ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: user_devices
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_devices (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    fcm_token text NOT NULL,
    platform text NOT NULL,
    device_name text,
    last_active timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (user_id),
    UNIQUE (fcm_token)
);

ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: users
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
    id uuid NOT NULL,
    email text NOT NULL,
    display_name text,
    photo_url text,
    nickname text,
    gender text,
    height numeric,
    weight numeric,
    age integer,
    birth_date timestamp with time zone,
    is_coach boolean DEFAULT false,
    is_student boolean DEFAULT true,
    bio text,
    unit_system text DEFAULT 'metric'::text,
    profile_created_at timestamp with time zone DEFAULT now(),
    profile_updated_at timestamp with time zone DEFAULT now(),
    last_login timestamp with time zone,
    gender_visible boolean NOT NULL DEFAULT true,
    fcm_tokens ARRAY DEFAULT '{}'::text[],
    PRIMARY KEY (id),
    UNIQUE (email)
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: workout_plans
-- ============================================================================
CREATE TABLE IF NOT EXISTS workout_plans (
    id text NOT NULL,
    user_id uuid,
    creator_id uuid,
    trainee_id uuid,
    title text NOT NULL,
    description text,
    plan_type text,
    ui_plan_type text,
    scheduled_date timestamp with time zone,
    completed_date timestamp with time zone,
    training_time timestamp with time zone,
    exercises jsonb DEFAULT '[]'::jsonb,
    completed boolean DEFAULT false,
    total_exercises integer DEFAULT 0,
    total_sets integer DEFAULT 0,
    total_volume numeric DEFAULT 0,
    note text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    training_time_range tstzrange,
    actual_start_time timestamp with time zone,
    actual_end_time timestamp with time zone,
    elapsed_seconds integer DEFAULT 0,
    training_status text DEFAULT 'pending'::text,
    appointment_id uuid,
    PRIMARY KEY (id)
);

ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: workout_templates
-- ============================================================================
CREATE TABLE IF NOT EXISTS workout_templates (
    id text NOT NULL,
    user_id uuid NOT NULL,
    title text NOT NULL,
    description text,
    plan_type text,
    exercises jsonb DEFAULT '[]'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (id)
);

ALTER TABLE workout_templates ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- Table: app_config (v5.1)
-- ============================================================================
CREATE TABLE IF NOT EXISTS app_config (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;
