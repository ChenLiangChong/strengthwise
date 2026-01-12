-- ============================================================================
-- Triggers（觸發器）
-- 導出時間：2026-01-12 19:57:13
-- ============================================================================

-- ============================================================================
-- Table: appointments
-- ============================================================================
-- Trigger: push_notify_appointments (AFTER INSERT)
-- Function: http_request
DROP TRIGGER IF EXISTS push_notify_appointments ON appointments;
CREATE TRIGGER push_notify_appointments AFTER INSERT OR UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request('https://fihkhoogvkccgpbgjhpw.supabase.co/functions/v1/push-notify', 'POST', '{"Content-type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZpaGtob29ndmtjY2dwYmdqaHB3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NjYwMDkxNSwiZXhwIjoyMDgyMTc2OTE1fQ.ldYcEVSioWxcbLJPcRjd9XP-FJP4_2o7rO74hCN6srU"}', '{}', '5000');

-- Trigger: trg_create_session_mode_data (AFTER INSERT)
-- Function: create_session_mode_data
DROP TRIGGER IF EXISTS trg_create_session_mode_data ON appointments;
CREATE TRIGGER trg_create_session_mode_data AFTER INSERT OR UPDATE OF status ON public.appointments FOR EACH ROW EXECUTE FUNCTION create_session_mode_data();

-- Trigger: trigger_update_appointments_updated_at (BEFORE UPDATE)
-- Function: update_appointments_updated_at
DROP TRIGGER IF EXISTS trigger_update_appointments_updated_at ON appointments;
CREATE TRIGGER trigger_update_appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION update_appointments_updated_at();

-- ============================================================================
-- Table: availability_slots
-- ============================================================================
-- Trigger: trigger_update_availability_slots_updated_at (BEFORE UPDATE)
-- Function: update_availability_slots_updated_at
DROP TRIGGER IF EXISTS trigger_update_availability_slots_updated_at ON availability_slots;
CREATE TRIGGER trigger_update_availability_slots_updated_at BEFORE UPDATE ON public.availability_slots FOR EACH ROW EXECUTE FUNCTION update_availability_slots_updated_at();

-- ============================================================================
-- Table: client_availability
-- ============================================================================
-- Trigger: client_availability_updated_at_trigger (BEFORE UPDATE)
-- Function: update_session_notes_updated_at
DROP TRIGGER IF EXISTS client_availability_updated_at_trigger ON client_availability;
CREATE TRIGGER client_availability_updated_at_trigger BEFORE UPDATE ON public.client_availability FOR EACH ROW EXECUTE FUNCTION update_session_notes_updated_at();

-- ============================================================================
-- Table: coach_assessment_notes
-- ============================================================================
-- Trigger: trigger_update_coach_assessment_notes_timestamp (BEFORE UPDATE)
-- Function: update_coach_assessment_notes_timestamp
DROP TRIGGER IF EXISTS trigger_update_coach_assessment_notes_timestamp ON coach_assessment_notes;
CREATE TRIGGER trigger_update_coach_assessment_notes_timestamp BEFORE UPDATE ON public.coach_assessment_notes FOR EACH ROW EXECUTE FUNCTION update_coach_assessment_notes_timestamp();

-- ============================================================================
-- Table: coach_booking_settings
-- ============================================================================
-- Trigger: trg_coach_booking_settings_updated_at (BEFORE UPDATE)
-- Function: update_coach_booking_settings_updated_at
DROP TRIGGER IF EXISTS trg_coach_booking_settings_updated_at ON coach_booking_settings;
CREATE TRIGGER trg_coach_booking_settings_updated_at BEFORE UPDATE ON public.coach_booking_settings FOR EACH ROW EXECUTE FUNCTION update_coach_booking_settings_updated_at();

-- ============================================================================
-- Table: coach_display_preferences
-- ============================================================================
-- Trigger: trigger_update_coach_preferences_timestamp (BEFORE UPDATE)
-- Function: update_health_assessment_timestamp
DROP TRIGGER IF EXISTS trigger_update_coach_preferences_timestamp ON coach_display_preferences;
CREATE TRIGGER trigger_update_coach_preferences_timestamp BEFORE UPDATE ON public.coach_display_preferences FOR EACH ROW EXECUTE FUNCTION update_health_assessment_timestamp();

-- ============================================================================
-- Table: coaches
-- ============================================================================
-- Trigger: update_coaches_updated_at (BEFORE UPDATE)
-- Function: update_coaches_updated_at
DROP TRIGGER IF EXISTS update_coaches_updated_at ON coaches;
CREATE TRIGGER update_coaches_updated_at BEFORE UPDATE ON public.coaches FOR EACH ROW EXECUTE FUNCTION update_coaches_updated_at();

-- ============================================================================
-- Table: coaching_relationships
-- ============================================================================
-- Trigger: coaching_relationship_names_trigger (BEFORE INSERT)
-- Function: save_coaching_relationship_names
DROP TRIGGER IF EXISTS coaching_relationship_names_trigger ON coaching_relationships;
CREATE TRIGGER coaching_relationship_names_trigger BEFORE INSERT OR UPDATE ON public.coaching_relationships FOR EACH ROW EXECUTE FUNCTION save_coaching_relationship_names();

-- Trigger: update_coaching_relationships_updated_at (BEFORE UPDATE)
-- Function: update_coaching_relationships_updated_at
DROP TRIGGER IF EXISTS update_coaching_relationships_updated_at ON coaching_relationships;
CREATE TRIGGER update_coaching_relationships_updated_at BEFORE UPDATE ON public.coaching_relationships FOR EACH ROW EXECUTE FUNCTION update_coaching_relationships_updated_at();

-- ============================================================================
-- Table: custom_exercises
-- ============================================================================
-- Trigger: trigger_update_custom_exercises_updated_at (BEFORE UPDATE)
-- Function: update_custom_exercises_updated_at
DROP TRIGGER IF EXISTS trigger_update_custom_exercises_updated_at ON custom_exercises;
CREATE TRIGGER trigger_update_custom_exercises_updated_at BEFORE UPDATE ON public.custom_exercises FOR EACH ROW EXECUTE FUNCTION update_custom_exercises_updated_at();

-- ============================================================================
-- Table: daily_readiness
-- ============================================================================
-- Trigger: readiness_notify (AFTER UPDATE)
-- Function: http_request
DROP TRIGGER IF EXISTS readiness_notify ON daily_readiness;
CREATE TRIGGER readiness_notify AFTER UPDATE ON public.daily_readiness FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request('https://fihkhoogvkccgpbgjhpw.supabase.co/functions/v1/readiness-notify', 'POST', '{"Content-type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZpaGtob29ndmtjY2dwYmdqaHB3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NjYwMDkxNSwiZXhwIjoyMDgyMTc2OTE1fQ.ldYcEVSioWxcbLJPcRjd9XP-FJP4_2o7rO74hCN6srU"}', '{}', '5000');

-- Trigger: trg_daily_readiness_updated_at (BEFORE UPDATE)
-- Function: update_daily_readiness_updated_at
DROP TRIGGER IF EXISTS trg_daily_readiness_updated_at ON daily_readiness;
CREATE TRIGGER trg_daily_readiness_updated_at BEFORE UPDATE ON public.daily_readiness FOR EACH ROW EXECUTE FUNCTION update_daily_readiness_updated_at();

-- ============================================================================
-- Table: health_assessments
-- ============================================================================
-- Trigger: trigger_update_health_assessment_timestamp (BEFORE UPDATE)
-- Function: update_health_assessment_timestamp
DROP TRIGGER IF EXISTS trigger_update_health_assessment_timestamp ON health_assessments;
CREATE TRIGGER trigger_update_health_assessment_timestamp BEFORE UPDATE ON public.health_assessments FOR EACH ROW EXECUTE FUNCTION update_health_assessment_timestamp();

-- ============================================================================
-- Table: injury_coach_notes
-- ============================================================================
-- Trigger: trg_injury_coach_notes_updated_at (BEFORE UPDATE)
-- Function: update_injury_coach_notes_updated_at
DROP TRIGGER IF EXISTS trg_injury_coach_notes_updated_at ON injury_coach_notes;
CREATE TRIGGER trg_injury_coach_notes_updated_at BEFORE UPDATE ON public.injury_coach_notes FOR EACH ROW EXECUTE FUNCTION update_injury_coach_notes_updated_at();

-- ============================================================================
-- Table: notes
-- ============================================================================
-- Trigger: update_notes_updated_at (BEFORE UPDATE)
-- Function: update_updated_at_column
DROP TRIGGER IF EXISTS update_notes_updated_at ON notes;
CREATE TRIGGER update_notes_updated_at BEFORE UPDATE ON public.notes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Table: session_notes
-- ============================================================================
-- Trigger: session_note_names_trigger (BEFORE INSERT)
-- Function: save_session_note_names
DROP TRIGGER IF EXISTS session_note_names_trigger ON session_notes;
CREATE TRIGGER session_note_names_trigger BEFORE INSERT OR UPDATE ON public.session_notes FOR EACH ROW EXECUTE FUNCTION save_session_note_names();

-- Trigger: session_notes_updated_at_trigger (BEFORE UPDATE)
-- Function: update_session_notes_updated_at
DROP TRIGGER IF EXISTS session_notes_updated_at_trigger ON session_notes;
CREATE TRIGGER session_notes_updated_at_trigger BEFORE UPDATE ON public.session_notes FOR EACH ROW EXECUTE FUNCTION update_session_notes_updated_at();

-- ============================================================================
-- Table: users
-- ============================================================================
-- Trigger: update_users_updated_at (BEFORE UPDATE)
-- Function: update_updated_at_column
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- Table: workout_plans
-- ============================================================================
-- Trigger: trg_update_daily_workout_summary (AFTER INSERT)
-- Function: update_daily_workout_summary
DROP TRIGGER IF EXISTS trg_update_daily_workout_summary ON workout_plans;
CREATE TRIGGER trg_update_daily_workout_summary AFTER INSERT OR UPDATE OF completed, exercises ON public.workout_plans FOR EACH ROW EXECUTE FUNCTION update_daily_workout_summary();

-- Trigger: trg_update_personal_records (AFTER INSERT)
-- Function: update_personal_records
DROP TRIGGER IF EXISTS trg_update_personal_records ON workout_plans;
CREATE TRIGGER trg_update_personal_records AFTER INSERT OR UPDATE OF completed, exercises ON public.workout_plans FOR EACH ROW EXECUTE FUNCTION update_personal_records();

-- Trigger: trigger_update_daily_summary (AFTER INSERT)
-- Function: update_daily_workout_summary
DROP TRIGGER IF EXISTS trigger_update_daily_summary ON workout_plans;
CREATE TRIGGER trigger_update_daily_summary AFTER INSERT OR DELETE OR UPDATE ON public.workout_plans FOR EACH ROW EXECUTE FUNCTION update_daily_workout_summary();

-- Trigger: trigger_update_personal_records (AFTER INSERT)
-- Function: update_personal_records
DROP TRIGGER IF EXISTS trigger_update_personal_records ON workout_plans;
CREATE TRIGGER trigger_update_personal_records AFTER INSERT OR UPDATE ON public.workout_plans FOR EACH ROW EXECUTE FUNCTION update_personal_records();

-- Trigger: trigger_update_pr (AFTER INSERT)
-- Function: update_personal_records
DROP TRIGGER IF EXISTS trigger_update_pr ON workout_plans;
CREATE TRIGGER trigger_update_pr AFTER INSERT OR UPDATE OF completed, exercises ON public.workout_plans FOR EACH ROW EXECUTE FUNCTION update_personal_records();

-- Trigger: trigger_update_pr_on_delete (AFTER DELETE)
-- Function: handle_workout_plan_delete
DROP TRIGGER IF EXISTS trigger_update_pr_on_delete ON workout_plans;
CREATE TRIGGER trigger_update_pr_on_delete AFTER DELETE ON public.workout_plans FOR EACH ROW EXECUTE FUNCTION handle_workout_plan_delete();
