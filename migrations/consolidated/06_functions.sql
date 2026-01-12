-- ============================================================================
-- Functions（自定義函數）
-- 導出時間：consolidated version
-- 說明：已過濾系統函數（pgroonga, btree_gist, pg_trgm）
-- ============================================================================

-- ============================================================================
-- Function: bind_by_qr_code
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.bind_by_qr_code(p_scanned_user_id uuid, p_my_user_id uuid, p_my_role text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$



-- ============================================================================
-- Function: bind_coach_by_invite_code
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.bind_coach_by_invite_code(p_code text, p_trainee_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$



-- ============================================================================
-- Function: check_appointment_conflict
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.check_appointment_conflict(p_coach_id uuid, p_time_range tstzrange, p_exclude_appointment_id uuid DEFAULT NULL::uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$



-- ============================================================================
-- Function: create_session_mode_data
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.create_session_mode_data()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$



-- ============================================================================
-- Function: delete_expired_invite_codes
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.delete_expired_invite_codes()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$



-- ============================================================================
-- Function: delete_user_account
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.delete_user_account(target_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$



-- ============================================================================
-- Function: get_available_slots
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_available_slots(p_coach_id uuid, p_start_time timestamp with time zone, p_end_time timestamp with time zone)
 RETURNS TABLE(slot_id uuid, time_range tstzrange, recurrence_rule text, is_override boolean, notes text, created_at timestamp with time zone, updated_at timestamp with time zone, is_booked boolean, booked_by_client_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$



-- ============================================================================
-- Function: get_coach_client_count
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_coach_client_count(p_coach_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$



-- ============================================================================
-- Function: get_coach_profile
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_coach_profile(coach_uuid uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$

  

-- ============================================================================
-- Function: get_top_personal_records
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_top_personal_records(user_id_param uuid, limit_count integer DEFAULT 10)
 RETURNS TABLE(exercise_id text, exercise_name text, max_weight numeric, max_reps integer, achieved_date date)
 LANGUAGE plpgsql
 STABLE
AS $function$



-- ============================================================================
-- Function: get_training_statistics
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_training_statistics(user_id_param uuid, start_date date DEFAULT (CURRENT_DATE - '30 days'::interval), end_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(total_workouts bigint, total_exercises bigint, total_sets bigint, total_volume numeric, avg_volume_per_workout numeric, resistance_training_ratio numeric, training_days integer)
 LANGUAGE plpgsql
 STABLE
AS $function$



-- ============================================================================
-- Function: get_user_tokens
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_user_tokens(p_user_id uuid)
 RETURNS text[]
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

  

-- ============================================================================
-- Function: handle_new_user
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$



-- ============================================================================
-- Function: handle_workout_plan_delete
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_workout_plan_delete()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: is_active_coaching_relationship
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.is_active_coaching_relationship(p_coach_id uuid, p_client_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$



-- ============================================================================
-- Function: remove_device_token
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.remove_device_token(p_user_id uuid, p_token text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$



-- ============================================================================
-- Function: remove_fcm_token
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.remove_fcm_token(p_user_id uuid, p_token text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$



-- ============================================================================
-- Function: remove_invalid_tokens
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.remove_invalid_tokens(p_tokens text[])
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$



-- ============================================================================
-- Function: save_coaching_relationship_names
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.save_coaching_relationship_names()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: save_session_note_names
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.save_session_note_names()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: search_all_exercises
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.search_all_exercises(user_id_param uuid, search_query text, training_type_filter text DEFAULT NULL::text, body_part_filter text DEFAULT NULL::text, limit_count integer DEFAULT 50)
 RETURNS TABLE(id text, name text, name_en text, body_part text, training_type text, equipment text, description text, is_custom boolean, relevance_score double precision)
 LANGUAGE plpgsql
 STABLE
AS $function$

  

-- ============================================================================
-- Function: search_all_exercises_pgroonga
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.search_all_exercises_pgroonga(user_id_param uuid, search_query text, max_results integer DEFAULT 20)
 RETURNS TABLE(id text, name text, name_en text, body_part text, training_type text, equipment text, description text, is_custom boolean, relevance_score double precision, tracking_mode text)
 LANGUAGE plpgsql
 STABLE
AS $function$



-- ============================================================================
-- Function: search_custom_exercises
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.search_custom_exercises(user_id_param uuid, search_query text, training_type_filter text DEFAULT NULL::text, limit_count integer DEFAULT 20)
 RETURNS TABLE(id text, name text, body_part text, training_type text, equipment text, description text, relevance_score double precision)
 LANGUAGE plpgsql
 STABLE
AS $function$

  

-- ============================================================================
-- Function: search_custom_exercises_pgroonga
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.search_custom_exercises_pgroonga(user_id_param uuid, search_query text, max_results integer DEFAULT 20)
 RETURNS TABLE(id text, name text, body_part text, training_type text, equipment text, description text, notes text, created_at timestamp with time zone, user_id uuid, tracking_mode text)
 LANGUAGE plpgsql
 STABLE
AS $function$



-- ============================================================================
-- Function: search_exercises
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.search_exercises(search_query text, training_type_filter text DEFAULT NULL::text, body_part_filter text DEFAULT NULL::text, limit_count integer DEFAULT 50)
 RETURNS TABLE(id text, name text, name_en text, body_part text, training_type text, equipment text, description text, relevance_score double precision)
 LANGUAGE plpgsql
 STABLE
AS $function$

  

-- ============================================================================
-- Function: search_exercises_pgroonga
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.search_exercises_pgroonga(search_query text, max_results integer DEFAULT 20)
 RETURNS TABLE(id text, name text, name_en text, body_part text, training_type text, equipment text, equipment_category text, equipment_subcategory text, joint_type text, level1 text, level2 text, level3 text, level4 text, level5 text, action_name text, description text, image_url text, video_url text, body_parts text[], apps text[], created_at timestamp with time zone, specific_muscle text, tracking_mode text)
 LANGUAGE plpgsql
 STABLE
AS $function$



-- ============================================================================
-- Function: update_appointments_updated_at
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_appointments_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: update_availability_slots_updated_at
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_availability_slots_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: update_coach_assessment_notes_timestamp
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_coach_assessment_notes_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: update_coach_booking_settings_updated_at
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_coach_booking_settings_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: update_coaches_updated_at
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_coaches_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: update_coaching_relationships_updated_at
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_coaching_relationships_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: update_custom_exercises_updated_at
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_custom_exercises_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: update_daily_readiness_updated_at
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_daily_readiness_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: update_daily_workout_summary
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_daily_workout_summary()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: update_health_assessment_timestamp
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_health_assessment_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: update_injury_coach_notes_updated_at
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_injury_coach_notes_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: update_personal_records
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_personal_records()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: update_session_notes_updated_at
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_session_notes_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: update_updated_at_column
-- Security: SECURITY INVOKER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$



-- ============================================================================
-- Function: upsert_device_token
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.upsert_device_token(p_user_id uuid, p_token text, p_platform text DEFAULT 'android'::text, p_device_name text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$



-- ============================================================================
-- Function: upsert_fcm_token
-- Security: SECURITY DEFINER
-- ============================================================================
CREATE OR REPLACE FUNCTION public.upsert_fcm_token(p_user_id uuid, p_token text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$



