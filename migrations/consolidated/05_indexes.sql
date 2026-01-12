-- ============================================================================
-- Indexes（索引）
-- 導出時間：2026-01-12 19:57:12
-- ============================================================================

-- Table: appointments
-- Index: idx_appointments_client (btree)
CREATE INDEX idx_appointments_client ON public.appointments USING btree (client_id);

-- Index: idx_appointments_client_status (btree)
CREATE INDEX idx_appointments_client_status ON public.appointments USING btree (client_id, status);

-- Index: idx_appointments_coach (btree)
CREATE INDEX idx_appointments_coach ON public.appointments USING btree (coach_id);

-- Index: idx_appointments_coach_status (btree)
CREATE INDEX idx_appointments_coach_status ON public.appointments USING btree (coach_id, status);

-- Index: idx_appointments_status (btree)
CREATE INDEX idx_appointments_status ON public.appointments USING btree (status);

-- Index: idx_appointments_time (gist)
CREATE INDEX idx_appointments_time ON public.appointments USING gist (time_range);

-- Index: idx_appointments_workout_plan (btree)
CREATE INDEX idx_appointments_workout_plan ON public.appointments USING btree (workout_plan_id) WHERE (workout_plan_id IS NOT NULL);

-- Index: no_coach_overlap (gist)
CREATE INDEX no_coach_overlap ON public.appointments USING gist (coach_id, time_range) WHERE (status = ANY (ARRAY['requested'::appointment_status, 'confirmed'::appointment_status]));

-- Table: availability_slots
-- Index: idx_availability_slots_coach (btree)
CREATE INDEX idx_availability_slots_coach ON public.availability_slots USING btree (coach_id);

-- Index: idx_availability_slots_coach_time (btree)
CREATE INDEX idx_availability_slots_coach_time ON public.availability_slots USING btree (coach_id) INCLUDE (time_range);

-- Index: idx_availability_slots_time (gist)
CREATE INDEX idx_availability_slots_time ON public.availability_slots USING gist (time_range);

-- Table: body_data
-- Index: idx_body_data_record_date (btree)
CREATE INDEX idx_body_data_record_date ON public.body_data USING btree (record_date DESC);

-- Index: idx_body_data_user_date (btree)
CREATE INDEX idx_body_data_user_date ON public.body_data USING btree (user_id, record_date DESC);

-- Index: idx_body_data_user_date_covering (btree)
CREATE INDEX idx_body_data_user_date_covering ON public.body_data USING btree (user_id, record_date DESC) INCLUDE (weight, body_fat, muscle_mass, bmi);

-- Index: idx_body_data_user_id (btree)
CREATE INDEX idx_body_data_user_id ON public.body_data USING btree (user_id);

-- Table: body_parts
-- Index: idx_body_parts_name (btree)
CREATE INDEX idx_body_parts_name ON public.body_parts USING btree (name);

-- Index: idx_body_parts_name_en (btree)
CREATE INDEX idx_body_parts_name_en ON public.body_parts USING btree (name_en) WHERE (name_en IS NOT NULL);

-- Table: client_availability
-- Index: idx_client_availability_client (btree)
CREATE INDEX idx_client_availability_client ON public.client_availability USING btree (client_id, priority);

-- Index: idx_client_availability_composite (gist)
CREATE INDEX idx_client_availability_composite ON public.client_availability USING gist (client_id, time_range);

-- Index: idx_client_availability_time_range (gist)
CREATE INDEX idx_client_availability_time_range ON public.client_availability USING gist (time_range);

-- Table: coach_assessment_notes
-- Index: idx_coach_assessment_notes_assessment (btree)
CREATE INDEX idx_coach_assessment_notes_assessment ON public.coach_assessment_notes USING btree (assessment_id);

-- Index: idx_coach_assessment_notes_coach (btree)
CREATE INDEX idx_coach_assessment_notes_coach ON public.coach_assessment_notes USING btree (coach_id);

-- Index: idx_coach_assessment_notes_coach_assessment (btree)
CREATE INDEX idx_coach_assessment_notes_coach_assessment ON public.coach_assessment_notes USING btree (coach_id, assessment_id);

-- Table: coach_booking_settings
-- Index: idx_booking_settings_coach (btree)
CREATE INDEX idx_booking_settings_coach ON public.coach_booking_settings USING btree (coach_id);

-- Table: coaches
-- Index: idx_coaches_slug (btree)
CREATE INDEX idx_coaches_slug ON public.coaches USING btree (slug) WHERE (slug IS NOT NULL);

-- Index: idx_coaches_verified_status (btree)
CREATE INDEX idx_coaches_verified_status ON public.coaches USING btree (verified_status);

-- Table: coaching_relationships
-- Index: idx_coaching_rel_client_status (btree)
CREATE INDEX idx_coaching_rel_client_status ON public.coaching_relationships USING btree (client_id, status);

-- Index: idx_coaching_rel_coach_status (btree)
CREATE INDEX idx_coaching_rel_coach_status ON public.coaching_relationships USING btree (coach_id, status);

-- Index: idx_coaching_rel_created_at (btree)
CREATE INDEX idx_coaching_rel_created_at ON public.coaching_relationships USING btree (created_at DESC);

-- Index: idx_coaching_rel_status (btree)
CREATE INDEX idx_coaching_rel_status ON public.coaching_relationships USING btree (status);

-- Table: custom_exercises
-- Index: idx_custom_exercises_body_part (btree)
CREATE INDEX idx_custom_exercises_body_part ON public.custom_exercises USING btree (body_part);

-- Index: idx_custom_exercises_description_pgroonga (pgroonga)
CREATE INDEX idx_custom_exercises_description_pgroonga ON public.custom_exercises USING pgroonga (description) WHERE ((description IS NOT NULL) AND (description <> ''::text));

-- Index: idx_custom_exercises_name_pgroonga (pgroonga)
CREATE INDEX idx_custom_exercises_name_pgroonga ON public.custom_exercises USING pgroonga (name pgroonga_text_term_search_ops_v2);

-- Index: idx_custom_exercises_name_trgm (gin)
CREATE INDEX idx_custom_exercises_name_trgm ON public.custom_exercises USING gin (name gin_trgm_ops);

-- Index: idx_custom_exercises_tracking_mode (btree)
CREATE INDEX idx_custom_exercises_tracking_mode ON public.custom_exercises USING btree (tracking_mode);

-- Index: idx_custom_exercises_user_body_part (btree)
CREATE INDEX idx_custom_exercises_user_body_part ON public.custom_exercises USING btree (user_id, body_part);

-- Index: idx_custom_exercises_user_covering (btree)
CREATE INDEX idx_custom_exercises_user_covering ON public.custom_exercises USING btree (user_id, created_at DESC) INCLUDE (name, body_part, equipment, description);

-- Index: idx_custom_exercises_user_equipment (btree)
CREATE INDEX idx_custom_exercises_user_equipment ON public.custom_exercises USING btree (user_id, equipment);

-- Index: idx_custom_exercises_user_id (btree)
CREATE INDEX idx_custom_exercises_user_id ON public.custom_exercises USING btree (user_id);

-- Table: daily_readiness
-- Index: idx_readiness_appointment (btree)
CREATE INDEX idx_readiness_appointment ON public.daily_readiness USING btree (appointment_id);

-- Index: idx_readiness_metrics (gin)
CREATE INDEX idx_readiness_metrics ON public.daily_readiness USING gin (metrics);

-- Index: idx_readiness_user_date (btree)
CREATE INDEX idx_readiness_user_date ON public.daily_readiness USING btree (user_id, log_date DESC);

-- Table: daily_workout_summary
-- Index: idx_daily_summary_user_date (btree)
CREATE INDEX idx_daily_summary_user_date ON public.daily_workout_summary USING btree (user_id, date DESC);

-- Index: idx_daily_summary_user_updated (btree)
CREATE INDEX idx_daily_summary_user_updated ON public.daily_workout_summary USING btree (user_id, updated_at DESC);

-- Table: exercise_types
-- Index: idx_exercise_types_name (btree)
CREATE INDEX idx_exercise_types_name ON public.exercise_types USING btree (name);

-- Index: idx_exercise_types_name_en (btree)
CREATE INDEX idx_exercise_types_name_en ON public.exercise_types USING btree (name_en) WHERE (name_en IS NOT NULL);

-- Table: exercises
-- Index: idx_exercises_body_part (btree)
CREATE INDEX idx_exercises_body_part ON public.exercises USING btree (body_part);

-- Index: idx_exercises_description_pgroonga (pgroonga)
CREATE INDEX idx_exercises_description_pgroonga ON public.exercises USING pgroonga (description) WHERE ((description IS NOT NULL) AND (description <> ''::text));

-- Index: idx_exercises_equipment (btree)
CREATE INDEX idx_exercises_equipment ON public.exercises USING btree (equipment);

-- Index: idx_exercises_fulltext_combined (pgroonga)
CREATE INDEX idx_exercises_fulltext_combined ON public.exercises USING pgroonga ((((name || ' '::text) || COALESCE(name_en, ''::text))) pgroonga_text_term_search_ops_v2);

-- Index: idx_exercises_name (btree)
CREATE INDEX idx_exercises_name ON public.exercises USING btree (name);

-- Index: idx_exercises_name_en_pgroonga (pgroonga)
CREATE INDEX idx_exercises_name_en_pgroonga ON public.exercises USING pgroonga (name_en pgroonga_text_term_search_ops_v2);

-- Index: idx_exercises_name_pgroonga (pgroonga)
CREATE INDEX idx_exercises_name_pgroonga ON public.exercises USING pgroonga (name pgroonga_text_term_search_ops_v2);

-- Index: idx_exercises_name_trgm (gin)
CREATE INDEX idx_exercises_name_trgm ON public.exercises USING gin (name gin_trgm_ops);

-- Index: idx_exercises_tracking_mode (btree)
CREATE INDEX idx_exercises_tracking_mode ON public.exercises USING btree (tracking_mode);

-- Index: idx_exercises_training_type (btree)
CREATE INDEX idx_exercises_training_type ON public.exercises USING btree (training_type);

-- Index: idx_exercises_training_type_covering (btree)
CREATE INDEX idx_exercises_training_type_covering ON public.exercises USING btree (training_type, body_part) INCLUDE (name, name_en, equipment, equipment_category);

-- Index: idx_exercises_user_id (btree)
CREATE INDEX idx_exercises_user_id ON public.exercises USING btree (user_id);

-- Table: health_assessments
-- Index: idx_health_assessments_cardiovascular (gin)
CREATE INDEX idx_health_assessments_cardiovascular ON public.health_assessments USING gin (cardiovascular_details);

-- Index: idx_health_assessments_date (btree)
CREATE INDEX idx_health_assessments_date ON public.health_assessments USING btree (user_id, assessment_date DESC);

-- Index: idx_health_assessments_equipment (gin)
CREATE INDEX idx_health_assessments_equipment ON public.health_assessments USING gin (equipment_access);

-- Index: idx_health_assessments_injuries (gin)
CREATE INDEX idx_health_assessments_injuries ON public.health_assessments USING gin (musculoskeletal_details);

-- Index: idx_health_assessments_training_level (btree)
CREATE INDEX idx_health_assessments_training_level ON public.health_assessments USING btree (training_experience) WHERE (training_experience IS NOT NULL);

-- Index: idx_health_assessments_user_all (btree)
CREATE INDEX idx_health_assessments_user_all ON public.health_assessments USING btree (user_id, is_current);

-- Table: injury_coach_notes
-- Index: idx_injury_coach_notes_client (btree)
CREATE INDEX idx_injury_coach_notes_client ON public.injury_coach_notes USING btree (client_id);

-- Index: idx_injury_coach_notes_coach (btree)
CREATE INDEX idx_injury_coach_notes_coach ON public.injury_coach_notes USING btree (coach_id);

-- Index: idx_injury_coach_notes_site (btree)
CREATE INDEX idx_injury_coach_notes_site ON public.injury_coach_notes USING btree (client_id, injury_site);

-- Table: invite_codes
-- Index: idx_invite_codes_expires (btree)
CREATE INDEX idx_invite_codes_expires ON public.invite_codes USING btree (expires_at);

-- Table: notes
-- Index: idx_notes_appointment_id (btree)
CREATE INDEX idx_notes_appointment_id ON public.notes USING btree (appointment_id);

-- Index: idx_notes_drawing_points_gin (gin)
CREATE INDEX idx_notes_drawing_points_gin ON public.notes USING gin (drawing_points jsonb_path_ops);

-- Index: idx_notes_updated_at (btree)
CREATE INDEX idx_notes_updated_at ON public.notes USING btree (updated_at DESC);

-- Index: idx_notes_user_covering (btree)
CREATE INDEX idx_notes_user_covering ON public.notes USING btree (user_id, updated_at DESC) INCLUDE (title, text_content);

-- Index: idx_notes_user_id (btree)
CREATE INDEX idx_notes_user_id ON public.notes USING btree (user_id);

-- Index: idx_notes_workout_plan_id (btree)
CREATE INDEX idx_notes_workout_plan_id ON public.notes USING btree (workout_plan_id);

-- Table: personal_records
-- Index: idx_personal_records_body_part (btree)
CREATE INDEX idx_personal_records_body_part ON public.personal_records USING btree (user_id, body_part);

-- Index: idx_pr_exercise (btree)
CREATE INDEX idx_pr_exercise ON public.personal_records USING btree (exercise_id, max_weight DESC);

-- Index: idx_pr_user_weight (btree)
CREATE INDEX idx_pr_user_weight ON public.personal_records USING btree (user_id, max_weight DESC);

-- Table: session_notes
-- Index: idx_session_notes_appointment (btree)
CREATE INDEX idx_session_notes_appointment ON public.session_notes USING btree (appointment_id) WHERE (appointment_id IS NOT NULL);

-- Index: idx_session_notes_client (btree)
CREATE INDEX idx_session_notes_client ON public.session_notes USING btree (client_id, created_at DESC);

-- Index: idx_session_notes_coach (btree)
CREATE INDEX idx_session_notes_coach ON public.session_notes USING btree (coach_id, created_at DESC);

-- Index: idx_session_notes_content_gin (gin)
CREATE INDEX idx_session_notes_content_gin ON public.session_notes USING gin (content jsonb_path_ops);

-- Index: idx_session_notes_hidden_by_client (btree)
CREATE INDEX idx_session_notes_hidden_by_client ON public.session_notes USING btree (client_id, hidden_by_client) WHERE (hidden_by_client = true);

-- Index: idx_session_notes_hidden_by_coach (btree)
CREATE INDEX idx_session_notes_hidden_by_coach ON public.session_notes USING btree (coach_id, hidden_by_coach) WHERE (hidden_by_coach = true);

-- Index: idx_session_notes_title_gin (gin)
CREATE INDEX idx_session_notes_title_gin ON public.session_notes USING gin (to_tsvector('simple'::regconfig, title));

-- Index: idx_session_notes_visibility (btree)
CREATE INDEX idx_session_notes_visibility ON public.session_notes USING btree (visibility, client_id) WHERE (visibility = 'shared'::text);

-- Index: idx_session_notes_workout (btree)
CREATE INDEX idx_session_notes_workout ON public.session_notes USING btree (workout_log_id) WHERE (workout_log_id IS NOT NULL);

-- Table: user_devices
-- Index: idx_user_devices_token (btree)
CREATE INDEX idx_user_devices_token ON public.user_devices USING btree (fcm_token);

-- Index: idx_user_devices_user_id (btree)
CREATE INDEX idx_user_devices_user_id ON public.user_devices USING btree (user_id);

-- Table: users
-- Index: idx_users_email (btree)
CREATE INDEX idx_users_email ON public.users USING btree (email);

-- Index: idx_users_fcm_tokens (gin)
CREATE INDEX idx_users_fcm_tokens ON public.users USING gin (fcm_tokens);

-- Index: idx_users_is_coach (btree)
CREATE INDEX idx_users_is_coach ON public.users USING btree (is_coach);

-- Table: workout_plans
-- Index: idx_workout_plans_appointment (btree)
CREATE INDEX idx_workout_plans_appointment ON public.workout_plans USING btree (appointment_id) WHERE (appointment_id IS NOT NULL);

-- Index: idx_workout_plans_completed (btree)
CREATE INDEX idx_workout_plans_completed ON public.workout_plans USING btree (completed);

-- Index: idx_workout_plans_creator_covering (btree)
CREATE INDEX idx_workout_plans_creator_covering ON public.workout_plans USING btree (creator_id, scheduled_date DESC) INCLUDE (trainee_id, title, completed, total_exercises);

-- Index: idx_workout_plans_creator_id (btree)
CREATE INDEX idx_workout_plans_creator_id ON public.workout_plans USING btree (creator_id);

-- Index: idx_workout_plans_exercises_gin (gin)
CREATE INDEX idx_workout_plans_exercises_gin ON public.workout_plans USING gin (exercises jsonb_path_ops);

-- Index: idx_workout_plans_note_pgroonga (pgroonga)
CREATE INDEX idx_workout_plans_note_pgroonga ON public.workout_plans USING pgroonga (note) WHERE ((note IS NOT NULL) AND (note <> ''::text));

-- Index: idx_workout_plans_pending_partial (btree)
CREATE INDEX idx_workout_plans_pending_partial ON public.workout_plans USING btree (trainee_id, scheduled_date DESC) WHERE (completed = false);

-- Index: idx_workout_plans_scheduled_date (btree)
CREATE INDEX idx_workout_plans_scheduled_date ON public.workout_plans USING btree (scheduled_date);

-- Index: idx_workout_plans_time_range (gist)
CREATE INDEX idx_workout_plans_time_range ON public.workout_plans USING gist (training_time_range);

-- Index: idx_workout_plans_title_pgroonga (pgroonga)
CREATE INDEX idx_workout_plans_title_pgroonga ON public.workout_plans USING pgroonga (title pgroonga_text_term_search_ops_v2);

-- Index: idx_workout_plans_trainee_covering (btree)
CREATE INDEX idx_workout_plans_trainee_covering ON public.workout_plans USING btree (trainee_id, scheduled_date DESC) INCLUDE (title, completed, total_volume, total_exercises, total_sets, plan_type);

-- Index: idx_workout_plans_trainee_id (btree)
CREATE INDEX idx_workout_plans_trainee_id ON public.workout_plans USING btree (trainee_id);

-- Index: idx_workout_plans_trainee_time_range (gist)
CREATE INDEX idx_workout_plans_trainee_time_range ON public.workout_plans USING gist (trainee_id, training_time_range);

-- Index: idx_workout_plans_training_status (btree)
CREATE INDEX idx_workout_plans_training_status ON public.workout_plans USING btree (trainee_id, training_status) WHERE (training_status = ANY (ARRAY['in_progress'::text, 'paused'::text]));

-- Index: workout_plans_no_overlap_trainee (gist)
CREATE INDEX workout_plans_no_overlap_trainee ON public.workout_plans USING gist (trainee_id, training_time_range) WHERE (training_time_range IS NOT NULL);

-- Table: workout_templates
-- Index: idx_workout_templates_exercises_gin (gin)
CREATE INDEX idx_workout_templates_exercises_gin ON public.workout_templates USING gin (exercises jsonb_path_ops);

-- Index: idx_workout_templates_user_id (btree)
CREATE INDEX idx_workout_templates_user_id ON public.workout_templates USING btree (user_id);
