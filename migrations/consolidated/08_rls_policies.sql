-- ============================================================================
-- RLS Policies（Row Level Security）
-- 導出時間：2026-01-12 19:57:13
-- ============================================================================

-- ============================================================================
-- Table: appointments
-- ============================================================================
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- Policy: clients_create_appointments (INSERT)
DROP POLICY IF EXISTS "clients_create_appointments" ON appointments;
CREATE POLICY "clients_create_appointments" ON appointments
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK (((auth.uid() = client_id) AND (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = appointments.coach_id) AND (cr.client_id = auth.uid()) AND (cr.status = 'active'::text))))));

-- Policy: clients_update_own_appointments (UPDATE)
DROP POLICY IF EXISTS "clients_update_own_appointments" ON appointments;
CREATE POLICY "clients_update_own_appointments" ON appointments
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((auth.uid() = client_id))
    WITH CHECK ((auth.uid() = client_id));

-- Policy: clients_view_own_appointments (SELECT)
DROP POLICY IF EXISTS "clients_view_own_appointments" ON appointments;
CREATE POLICY "clients_view_own_appointments" ON appointments
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((auth.uid() = client_id));

-- Policy: coaches_create_appointments (INSERT)
DROP POLICY IF EXISTS "coaches_create_appointments" ON appointments;
CREATE POLICY "coaches_create_appointments" ON appointments
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK (((auth.uid() = coach_id) AND (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = appointments.client_id) AND (cr.status = 'active'::text))))));

-- Policy: coaches_update_own_appointments (UPDATE)
DROP POLICY IF EXISTS "coaches_update_own_appointments" ON appointments;
CREATE POLICY "coaches_update_own_appointments" ON appointments
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((auth.uid() = coach_id))
    WITH CHECK ((auth.uid() = coach_id));

-- Policy: coaches_view_own_appointments (SELECT)
DROP POLICY IF EXISTS "coaches_view_own_appointments" ON appointments;
CREATE POLICY "coaches_view_own_appointments" ON appointments
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((auth.uid() = coach_id));

-- ============================================================================
-- Table: availability_slots
-- ============================================================================
ALTER TABLE availability_slots ENABLE ROW LEVEL SECURITY;

-- Policy: clients_view_coach_slots (SELECT)
DROP POLICY IF EXISTS "clients_view_coach_slots" ON availability_slots;
CREATE POLICY "clients_view_coach_slots" ON availability_slots
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = availability_slots.coach_id) AND (cr.client_id = auth.uid()) AND (cr.status = 'active'::text)))));

-- Policy: coaches_delete_own_slots (DELETE)
DROP POLICY IF EXISTS "coaches_delete_own_slots" ON availability_slots;
CREATE POLICY "coaches_delete_own_slots" ON availability_slots
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING ((auth.uid() = coach_id));

-- Policy: coaches_insert_own_slots (INSERT)
DROP POLICY IF EXISTS "coaches_insert_own_slots" ON availability_slots;
CREATE POLICY "coaches_insert_own_slots" ON availability_slots
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((auth.uid() = coach_id));

-- Policy: coaches_update_own_slots (UPDATE)
DROP POLICY IF EXISTS "coaches_update_own_slots" ON availability_slots;
CREATE POLICY "coaches_update_own_slots" ON availability_slots
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((auth.uid() = coach_id))
    WITH CHECK ((auth.uid() = coach_id));

-- Policy: coaches_view_own_slots (SELECT)
DROP POLICY IF EXISTS "coaches_view_own_slots" ON availability_slots;
CREATE POLICY "coaches_view_own_slots" ON availability_slots
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((auth.uid() = coach_id));

-- ============================================================================
-- Table: body_data
-- ============================================================================
ALTER TABLE body_data ENABLE ROW LEVEL SECURITY;

-- Policy: Users can delete their own body data (DELETE)
DROP POLICY IF EXISTS "Users can delete their own body data" ON body_data;
CREATE POLICY "Users can delete their own body data" ON body_data
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING ((auth.uid() = user_id));

-- Policy: Users can insert their own body data (INSERT)
DROP POLICY IF EXISTS "Users can insert their own body data" ON body_data;
CREATE POLICY "Users can insert their own body data" ON body_data
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((auth.uid() = user_id));

-- Policy: Users can update their own body data (UPDATE)
DROP POLICY IF EXISTS "Users can update their own body data" ON body_data;
CREATE POLICY "Users can update their own body data" ON body_data
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((auth.uid() = user_id))
    WITH CHECK ((auth.uid() = user_id));

-- Policy: Users can view their own body data (SELECT)
DROP POLICY IF EXISTS "Users can view their own body data" ON body_data;
CREATE POLICY "Users can view their own body data" ON body_data
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((auth.uid() = user_id));

-- ============================================================================
-- Table: body_parts
-- ============================================================================
ALTER TABLE body_parts ENABLE ROW LEVEL SECURITY;

-- Policy: Body parts are viewable by all authenticated users (SELECT)
DROP POLICY IF EXISTS "Body parts are viewable by all authenticated users" ON body_parts;
CREATE POLICY "Body parts are viewable by all authenticated users" ON body_parts
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (true);

-- ============================================================================
-- Table: client_availability
-- ============================================================================
ALTER TABLE client_availability ENABLE ROW LEVEL SECURITY;

-- Policy: Clients create availability (INSERT)
DROP POLICY IF EXISTS "Clients create availability" ON client_availability;
CREATE POLICY "Clients create availability" ON client_availability
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((client_id = auth.uid()));

-- Policy: Clients delete own availability (DELETE)
DROP POLICY IF EXISTS "Clients delete own availability" ON client_availability;
CREATE POLICY "Clients delete own availability" ON client_availability
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING ((client_id = auth.uid()));

-- Policy: Clients update own availability (UPDATE)
DROP POLICY IF EXISTS "Clients update own availability" ON client_availability;
CREATE POLICY "Clients update own availability" ON client_availability
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((client_id = auth.uid()))
    WITH CHECK ((client_id = auth.uid()));

-- Policy: Clients view own availability (SELECT)
DROP POLICY IF EXISTS "Clients view own availability" ON client_availability;
CREATE POLICY "Clients view own availability" ON client_availability
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((client_id = auth.uid()));

-- Policy: Coaches create clients availability (INSERT)
DROP POLICY IF EXISTS "Coaches create clients availability" ON client_availability;
CREATE POLICY "Coaches create clients availability" ON client_availability
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = cr.client_id) AND (cr.status = 'active'::text)))));

-- Policy: Coaches update clients availability (UPDATE)
DROP POLICY IF EXISTS "Coaches update clients availability" ON client_availability;
CREATE POLICY "Coaches update clients availability" ON client_availability
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = cr.client_id) AND (cr.status = 'active'::text)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = cr.client_id) AND (cr.status = 'active'::text)))));

-- Policy: Coaches view active clients availability (SELECT)
DROP POLICY IF EXISTS "Coaches view active clients availability" ON client_availability;
CREATE POLICY "Coaches view active clients availability" ON client_availability
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = cr.client_id) AND (cr.status = 'active'::text)))));

-- ============================================================================
-- Table: coach_assessment_notes
-- ============================================================================
ALTER TABLE coach_assessment_notes ENABLE ROW LEVEL SECURITY;

-- Policy: Coaches can delete their own assessment notes (DELETE)
DROP POLICY IF EXISTS "Coaches can delete their own assessment notes" ON coach_assessment_notes;
CREATE POLICY "Coaches can delete their own assessment notes" ON coach_assessment_notes
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING ((auth.uid() = coach_id));

-- Policy: Coaches can insert their own assessment notes (INSERT)
DROP POLICY IF EXISTS "Coaches can insert their own assessment notes" ON coach_assessment_notes;
CREATE POLICY "Coaches can insert their own assessment notes" ON coach_assessment_notes
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((auth.uid() = coach_id));

-- Policy: Coaches can update their own assessment notes (UPDATE)
DROP POLICY IF EXISTS "Coaches can update their own assessment notes" ON coach_assessment_notes;
CREATE POLICY "Coaches can update their own assessment notes" ON coach_assessment_notes
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((auth.uid() = coach_id))
    WITH CHECK ((auth.uid() = coach_id));

-- Policy: Coaches can view their own assessment notes (SELECT)
DROP POLICY IF EXISTS "Coaches can view their own assessment notes" ON coach_assessment_notes;
CREATE POLICY "Coaches can view their own assessment notes" ON coach_assessment_notes
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((auth.uid() = coach_id));

-- ============================================================================
-- Table: coach_booking_settings
-- ============================================================================
ALTER TABLE coach_booking_settings ENABLE ROW LEVEL SECURITY;

-- Policy: Coaches can manage own settings (ALL)
DROP POLICY IF EXISTS "Coaches can manage own settings" ON coach_booking_settings;
CREATE POLICY "Coaches can manage own settings" ON coach_booking_settings
    AS PERMISSIVE
    FOR ALL
    TO public
    USING ((auth.uid() = coach_id))
    WITH CHECK ((auth.uid() = coach_id));

-- Policy: Students can view coach settings (SELECT)
DROP POLICY IF EXISTS "Students can view coach settings" ON coach_booking_settings;
CREATE POLICY "Students can view coach settings" ON coach_booking_settings
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((EXISTS ( SELECT 1
   FROM coaching_relationships
  WHERE ((coaching_relationships.client_id = auth.uid()) AND (coaching_relationships.coach_id = coach_booking_settings.coach_id) AND (coaching_relationships.status = 'active'::text)))));

-- ============================================================================
-- Table: coach_display_preferences
-- ============================================================================
ALTER TABLE coach_display_preferences ENABLE ROW LEVEL SECURITY;

-- Policy: Coaches can manage their own display preferences (ALL)
DROP POLICY IF EXISTS "Coaches can manage their own display preferences" ON coach_display_preferences;
CREATE POLICY "Coaches can manage their own display preferences" ON coach_display_preferences
    AS PERMISSIVE
    FOR ALL
    TO public
    USING ((auth.uid() = coach_id))
    WITH CHECK ((auth.uid() = coach_id));

-- ============================================================================
-- Table: coaches
-- ============================================================================
ALTER TABLE coaches ENABLE ROW LEVEL SECURITY;

-- Policy: coaches_insert_own (INSERT)
DROP POLICY IF EXISTS "coaches_insert_own" ON coaches;
CREATE POLICY "coaches_insert_own" ON coaches
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK (((auth.uid() = id) AND (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.is_coach = true))))));

-- Policy: coaches_select_by_student (SELECT)
DROP POLICY IF EXISTS "coaches_select_by_student" ON coaches;
CREATE POLICY "coaches_select_by_student" ON coaches
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = coaches.id) AND (cr.client_id = auth.uid()) AND (cr.status = 'active'::text)))));

-- Policy: coaches_select_own (SELECT)
DROP POLICY IF EXISTS "coaches_select_own" ON coaches;
CREATE POLICY "coaches_select_own" ON coaches
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING (((auth.uid() = id) AND (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.is_coach = true))))));

-- Policy: coaches_update_own (UPDATE)
DROP POLICY IF EXISTS "coaches_update_own" ON coaches;
CREATE POLICY "coaches_update_own" ON coaches
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING (((auth.uid() = id) AND (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.is_coach = true))))));

-- ============================================================================
-- Table: coaching_relationships
-- ============================================================================
ALTER TABLE coaching_relationships ENABLE ROW LEVEL SECURITY;

-- Policy: Both parties can archive relationships (UPDATE)
DROP POLICY IF EXISTS "Both parties can archive relationships" ON coaching_relationships;
CREATE POLICY "Both parties can archive relationships" ON coaching_relationships
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING ((((auth.uid() = coach_id) OR (auth.uid() = client_id)) AND (status = 'active'::text)))
    WITH CHECK ((((auth.uid() = coach_id) OR (auth.uid() = client_id)) AND (status = 'archived'::text)));

-- Policy: Both parties can delete relationships (DELETE)
DROP POLICY IF EXISTS "Both parties can delete relationships" ON coaching_relationships;
CREATE POLICY "Both parties can delete relationships" ON coaching_relationships
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING (((auth.uid() = coach_id) OR (auth.uid() = client_id)));

-- Policy: Both parties can reactivate archived relationships (UPDATE)
DROP POLICY IF EXISTS "Both parties can reactivate archived relationships" ON coaching_relationships;
CREATE POLICY "Both parties can reactivate archived relationships" ON coaching_relationships
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING ((((auth.uid() = coach_id) OR (auth.uid() = client_id)) AND (status = 'archived'::text)))
    WITH CHECK ((((auth.uid() = coach_id) OR (auth.uid() = client_id)) AND (status = 'active'::text)));

-- Policy: Clients can accept or reject invitations (UPDATE)
DROP POLICY IF EXISTS "Clients can accept or reject invitations" ON coaching_relationships;
CREATE POLICY "Clients can accept or reject invitations" ON coaching_relationships
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (((auth.uid() = client_id) AND (status = 'pending'::text)))
    WITH CHECK (((auth.uid() = client_id) AND (status = ANY (ARRAY['active'::text, 'rejected'::text]))));

-- Policy: Clients can create coach relationships (INSERT)
DROP POLICY IF EXISTS "Clients can create coach relationships" ON coaching_relationships;
CREATE POLICY "Clients can create coach relationships" ON coaching_relationships
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK ((auth.uid() = client_id));

-- Policy: Clients can view their coach relationships (SELECT)
DROP POLICY IF EXISTS "Clients can view their coach relationships" ON coaching_relationships;
CREATE POLICY "Clients can view their coach relationships" ON coaching_relationships
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING ((auth.uid() = client_id));

-- Policy: Coaches can create client relationships (INSERT)
DROP POLICY IF EXISTS "Coaches can create client relationships" ON coaching_relationships;
CREATE POLICY "Coaches can create client relationships" ON coaching_relationships
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (((auth.uid() = coach_id) AND (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.is_coach = true))))));

-- Policy: Coaches can update their relationships (UPDATE)
DROP POLICY IF EXISTS "Coaches can update their relationships" ON coaching_relationships;
CREATE POLICY "Coaches can update their relationships" ON coaching_relationships
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING ((auth.uid() = coach_id))
    WITH CHECK ((auth.uid() = coach_id));

-- Policy: Coaches can view their client relationships (SELECT)
DROP POLICY IF EXISTS "Coaches can view their client relationships" ON coaching_relationships;
CREATE POLICY "Coaches can view their client relationships" ON coaching_relationships
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING ((auth.uid() = coach_id));

-- ============================================================================
-- Table: custom_exercises
-- ============================================================================
ALTER TABLE custom_exercises ENABLE ROW LEVEL SECURITY;

-- Policy: Trainees can view custom exercises in their workouts (SELECT)
DROP POLICY IF EXISTS "Trainees can view custom exercises in their workouts" ON custom_exercises;
CREATE POLICY "Trainees can view custom exercises in their workouts" ON custom_exercises
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((EXISTS ( SELECT 1
   FROM workout_plans wp,
    LATERAL jsonb_array_elements(wp.exercises) ex(value)
  WHERE ((wp.trainee_id = auth.uid()) AND ((ex.value ->> 'exerciseId'::text) = custom_exercises.id)))));

-- Policy: Users can create own custom exercises (INSERT)
DROP POLICY IF EXISTS "Users can create own custom exercises" ON custom_exercises;
CREATE POLICY "Users can create own custom exercises" ON custom_exercises
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((auth.uid() = user_id));

-- Policy: Users can delete own custom exercises (DELETE)
DROP POLICY IF EXISTS "Users can delete own custom exercises" ON custom_exercises;
CREATE POLICY "Users can delete own custom exercises" ON custom_exercises
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING ((auth.uid() = user_id));

-- Policy: Users can update own custom exercises (UPDATE)
DROP POLICY IF EXISTS "Users can update own custom exercises" ON custom_exercises;
CREATE POLICY "Users can update own custom exercises" ON custom_exercises
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((auth.uid() = user_id));

-- Policy: Users can view own custom exercises (SELECT)
DROP POLICY IF EXISTS "Users can view own custom exercises" ON custom_exercises;
CREATE POLICY "Users can view own custom exercises" ON custom_exercises
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((auth.uid() = user_id));

-- ============================================================================
-- Table: daily_readiness
-- ============================================================================
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Policy: Coaches can insert for students (INSERT)
DROP POLICY IF EXISTS "Coaches can insert for students" ON daily_readiness;
CREATE POLICY "Coaches can insert for students" ON daily_readiness
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((EXISTS ( SELECT 1
   FROM coaching_relationships
  WHERE ((coaching_relationships.coach_id = auth.uid()) AND (coaching_relationships.client_id = daily_readiness.user_id) AND (coaching_relationships.status = 'active'::text)))));

-- Policy: Coaches can view students readiness (SELECT)
DROP POLICY IF EXISTS "Coaches can view students readiness" ON daily_readiness;
CREATE POLICY "Coaches can view students readiness" ON daily_readiness
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((EXISTS ( SELECT 1
   FROM coaching_relationships
  WHERE ((coaching_relationships.coach_id = auth.uid()) AND (coaching_relationships.client_id = daily_readiness.user_id) AND (coaching_relationships.status = 'active'::text)))));

-- Policy: Users can manage own readiness (ALL)
DROP POLICY IF EXISTS "Users can manage own readiness" ON daily_readiness;
CREATE POLICY "Users can manage own readiness" ON daily_readiness
    AS PERMISSIVE
    FOR ALL
    TO public
    USING ((auth.uid() = user_id))
    WITH CHECK ((auth.uid() = user_id));

-- ============================================================================
-- Table: daily_workout_summary
-- ============================================================================
ALTER TABLE daily_workout_summary ENABLE ROW LEVEL SECURITY;

-- Policy: daily_summary_delete (DELETE)
DROP POLICY IF EXISTS "daily_summary_delete" ON daily_workout_summary;
CREATE POLICY "daily_summary_delete" ON daily_workout_summary
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = daily_workout_summary.user_id) AND (cr.status = 'active'::text))))));

-- Policy: daily_summary_insert (INSERT)
DROP POLICY IF EXISTS "daily_summary_insert" ON daily_workout_summary;
CREATE POLICY "daily_summary_insert" ON daily_workout_summary
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = daily_workout_summary.user_id) AND (cr.status = 'active'::text))))));

-- Policy: daily_summary_select (SELECT)
DROP POLICY IF EXISTS "daily_summary_select" ON daily_workout_summary;
CREATE POLICY "daily_summary_select" ON daily_workout_summary
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = daily_workout_summary.user_id) AND (cr.status = 'active'::text))))));

-- Policy: daily_summary_update (UPDATE)
DROP POLICY IF EXISTS "daily_summary_update" ON daily_workout_summary;
CREATE POLICY "daily_summary_update" ON daily_workout_summary
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = daily_workout_summary.user_id) AND (cr.status = 'active'::text))))))
    WITH CHECK (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = daily_workout_summary.user_id) AND (cr.status = 'active'::text))))));

-- ============================================================================
-- Table: exercise_types
-- ============================================================================
ALTER TABLE exercise_types ENABLE ROW LEVEL SECURITY;

-- Policy: Exercise types are viewable by all authenticated users (SELECT)
DROP POLICY IF EXISTS "Exercise types are viewable by all authenticated users" ON exercise_types;
CREATE POLICY "Exercise types are viewable by all authenticated users" ON exercise_types
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING (true);

-- ============================================================================
-- Table: exercises
-- ============================================================================
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;

-- Policy: System exercises are viewable by all authenticated users (SELECT)
DROP POLICY IF EXISTS "System exercises are viewable by all authenticated users" ON exercises;
CREATE POLICY "System exercises are viewable by all authenticated users" ON exercises
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING ((user_id IS NULL));

-- Policy: System exercises are viewable by anonymous users (SELECT)
DROP POLICY IF EXISTS "System exercises are viewable by anonymous users" ON exercises;
CREATE POLICY "System exercises are viewable by anonymous users" ON exercises
    AS PERMISSIVE
    FOR SELECT
    TO anon
    USING ((user_id IS NULL));

-- Policy: Users can create custom exercises (INSERT)
DROP POLICY IF EXISTS "Users can create custom exercises" ON exercises;
CREATE POLICY "Users can create custom exercises" ON exercises
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK ((user_id = (auth.uid())::text));

-- Policy: Users can delete own custom exercises (DELETE)
DROP POLICY IF EXISTS "Users can delete own custom exercises" ON exercises;
CREATE POLICY "Users can delete own custom exercises" ON exercises
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING ((user_id = (auth.uid())::text));

-- Policy: Users can update own custom exercises (UPDATE)
DROP POLICY IF EXISTS "Users can update own custom exercises" ON exercises;
CREATE POLICY "Users can update own custom exercises" ON exercises
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING ((user_id = (auth.uid())::text));

-- Policy: Users can view own custom exercises (SELECT)
DROP POLICY IF EXISTS "Users can view own custom exercises" ON exercises;
CREATE POLICY "Users can view own custom exercises" ON exercises
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING ((user_id = (auth.uid())::text));

-- ============================================================================
-- Table: health_assessments
-- ============================================================================
ALTER TABLE health_assessments ENABLE ROW LEVEL SECURITY;

-- Policy: Coaches can insert their clients' health assessments (INSERT)
DROP POLICY IF EXISTS "Coaches can insert their clients' health assessments" ON health_assessments;
CREATE POLICY "Coaches can insert their clients' health assessments" ON health_assessments
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.client_id = health_assessments.user_id) AND (cr.coach_id = auth.uid()) AND (cr.status = 'active'::text)))));

-- Policy: Coaches can update their clients' health assessments (UPDATE)
DROP POLICY IF EXISTS "Coaches can update their clients' health assessments" ON health_assessments;
CREATE POLICY "Coaches can update their clients' health assessments" ON health_assessments
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.client_id = health_assessments.user_id) AND (cr.coach_id = auth.uid()) AND (cr.status = 'active'::text)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.client_id = health_assessments.user_id) AND (cr.coach_id = auth.uid()) AND (cr.status = 'active'::text)))));

-- Policy: Coaches can view their clients' health assessments (SELECT)
DROP POLICY IF EXISTS "Coaches can view their clients' health assessments" ON health_assessments;
CREATE POLICY "Coaches can view their clients' health assessments" ON health_assessments
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.client_id = health_assessments.user_id) AND (cr.coach_id = auth.uid()) AND (cr.status = 'active'::text)))));

-- Policy: Users can insert their own health assessments (INSERT)
DROP POLICY IF EXISTS "Users can insert their own health assessments" ON health_assessments;
CREATE POLICY "Users can insert their own health assessments" ON health_assessments
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((auth.uid() = user_id));

-- Policy: Users can update their own health assessments (UPDATE)
DROP POLICY IF EXISTS "Users can update their own health assessments" ON health_assessments;
CREATE POLICY "Users can update their own health assessments" ON health_assessments
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((auth.uid() = user_id))
    WITH CHECK ((auth.uid() = user_id));

-- Policy: Users can view their own health assessments (SELECT)
DROP POLICY IF EXISTS "Users can view their own health assessments" ON health_assessments;
CREATE POLICY "Users can view their own health assessments" ON health_assessments
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((auth.uid() = user_id));

-- ============================================================================
-- Table: injury_coach_notes
-- ============================================================================
ALTER TABLE injury_coach_notes ENABLE ROW LEVEL SECURITY;

-- Policy: injury_notes_delete (DELETE)
DROP POLICY IF EXISTS "injury_notes_delete" ON injury_coach_notes;
CREATE POLICY "injury_notes_delete" ON injury_coach_notes
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING ((coach_id = auth.uid()));

-- Policy: injury_notes_insert (INSERT)
DROP POLICY IF EXISTS "injury_notes_insert" ON injury_coach_notes;
CREATE POLICY "injury_notes_insert" ON injury_coach_notes
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK (((coach_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.client_id = injury_coach_notes.client_id) AND (cr.coach_id = auth.uid()) AND (cr.status = 'active'::text))))));

-- Policy: injury_notes_select (SELECT)
DROP POLICY IF EXISTS "injury_notes_select" ON injury_coach_notes;
CREATE POLICY "injury_notes_select" ON injury_coach_notes
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING (((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.client_id = injury_coach_notes.client_id) AND (cr.coach_id = auth.uid()) AND (cr.status = 'active'::text)))) OR (client_id = auth.uid())));

-- Policy: injury_notes_update (UPDATE)
DROP POLICY IF EXISTS "injury_notes_update" ON injury_coach_notes;
CREATE POLICY "injury_notes_update" ON injury_coach_notes
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((coach_id = auth.uid()));

-- ============================================================================
-- Table: invite_codes
-- ============================================================================
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;

-- Policy: Coaches can create invite codes (INSERT)
DROP POLICY IF EXISTS "Coaches can create invite codes" ON invite_codes;
CREATE POLICY "Coaches can create invite codes" ON invite_codes
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (((auth.uid() = coach_id) AND (EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.is_coach = true))))));

-- Policy: Coaches can delete own invite codes (DELETE)
-- ⭐ v5.2 安全修復：限制為教練只能刪除自己的邀請碼
DROP POLICY IF EXISTS "Users can delete invite codes" ON invite_codes;
DROP POLICY IF EXISTS "Coaches can delete own invite codes" ON invite_codes;
CREATE POLICY "Coaches can delete own invite codes" ON invite_codes
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING (auth.uid() = coach_id);

-- Policy: Users can query valid invite codes (SELECT)
DROP POLICY IF EXISTS "Users can query valid invite codes" ON invite_codes;
CREATE POLICY "Users can query valid invite codes" ON invite_codes
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING ((expires_at > now()));

-- ============================================================================
-- Table: notes
-- ============================================================================
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can create notes (INSERT)
DROP POLICY IF EXISTS "Users can create notes" ON notes;
CREATE POLICY "Users can create notes" ON notes
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK ((auth.uid() = user_id));

-- Policy: Users can delete their notes (DELETE)
DROP POLICY IF EXISTS "Users can delete their notes" ON notes;
CREATE POLICY "Users can delete their notes" ON notes
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING ((auth.uid() = user_id));

-- Policy: Users can update their notes (UPDATE)
DROP POLICY IF EXISTS "Users can update their notes" ON notes;
CREATE POLICY "Users can update their notes" ON notes
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING ((auth.uid() = user_id))
    WITH CHECK ((auth.uid() = user_id));

-- Policy: Users can view their notes (SELECT)
DROP POLICY IF EXISTS "Users can view their notes" ON notes;
CREATE POLICY "Users can view their notes" ON notes
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING ((auth.uid() = user_id));

-- ============================================================================
-- Table: personal_records
-- ============================================================================
ALTER TABLE personal_records ENABLE ROW LEVEL SECURITY;

-- Policy: personal_records_delete (DELETE)
DROP POLICY IF EXISTS "personal_records_delete" ON personal_records;
CREATE POLICY "personal_records_delete" ON personal_records
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = personal_records.user_id) AND (cr.status = 'active'::text))))));

-- Policy: personal_records_insert (INSERT)
DROP POLICY IF EXISTS "personal_records_insert" ON personal_records;
CREATE POLICY "personal_records_insert" ON personal_records
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = personal_records.user_id) AND (cr.status = 'active'::text))))));

-- Policy: personal_records_select (SELECT)
DROP POLICY IF EXISTS "personal_records_select" ON personal_records;
CREATE POLICY "personal_records_select" ON personal_records
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = personal_records.user_id) AND (cr.status = 'active'::text))))));

-- Policy: personal_records_update (UPDATE)
DROP POLICY IF EXISTS "personal_records_update" ON personal_records;
CREATE POLICY "personal_records_update" ON personal_records
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = personal_records.user_id) AND (cr.status = 'active'::text))))))
    WITH CHECK (((auth.uid() = user_id) OR (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = personal_records.user_id) AND (cr.status = 'active'::text))))));

-- ============================================================================
-- Table: session_notes
-- ============================================================================
ALTER TABLE session_notes ENABLE ROW LEVEL SECURITY;

-- Policy: Admins view all notes (SELECT)
DROP POLICY IF EXISTS "Admins view all notes" ON session_notes;
CREATE POLICY "Admins view all notes" ON session_notes
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((EXISTS ( SELECT 1
   FROM users u
  WHERE ((u.id = auth.uid()) AND (u.is_coach = true)))));

-- Policy: Clients can hide shared notes after relationship ends (UPDATE)
DROP POLICY IF EXISTS "Clients can hide shared notes after relationship ends" ON session_notes;
CREATE POLICY "Clients can hide shared notes after relationship ends" ON session_notes
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (((client_id = auth.uid()) AND (visibility = 'shared'::text) AND ((coach_id IS NULL) OR (NOT (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = session_notes.coach_id) AND (cr.client_id = auth.uid()) AND (cr.status = 'active'::text))))))))
    WITH CHECK (((client_id = auth.uid()) AND (visibility = 'shared'::text) AND (hidden_by_client = true)));

-- Policy: Clients view own notes metadata (SELECT)
DROP POLICY IF EXISTS "Clients view own notes metadata" ON session_notes;
CREATE POLICY "Clients view own notes metadata" ON session_notes
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((client_id = auth.uid()));

-- Policy: Clients view shared notes (SELECT)
DROP POLICY IF EXISTS "Clients view shared notes" ON session_notes;
CREATE POLICY "Clients view shared notes" ON session_notes
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING (((client_id = auth.uid()) AND (visibility = 'shared'::text)));

-- Policy: Coaches can hide shared notes (UPDATE)
DROP POLICY IF EXISTS "Coaches can hide shared notes" ON session_notes;
CREATE POLICY "Coaches can hide shared notes" ON session_notes
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING (((coach_id = auth.uid()) AND (visibility = 'shared'::text)))
    WITH CHECK (((coach_id = auth.uid()) AND (visibility = 'shared'::text) AND (hidden_by_coach = true)));

-- Policy: Coaches create notes (INSERT)
DROP POLICY IF EXISTS "Coaches create notes" ON session_notes;
CREATE POLICY "Coaches create notes" ON session_notes
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK (((coach_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = cr.client_id) AND (cr.status = 'active'::text))))));

-- Policy: Coaches delete own notes (DELETE)
DROP POLICY IF EXISTS "Coaches delete own notes" ON session_notes;
CREATE POLICY "Coaches delete own notes" ON session_notes
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING ((coach_id = auth.uid()));

-- Policy: Coaches update own notes (UPDATE)
DROP POLICY IF EXISTS "Coaches update own notes" ON session_notes;
CREATE POLICY "Coaches update own notes" ON session_notes
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((coach_id = auth.uid()))
    WITH CHECK ((coach_id = auth.uid()));

-- Policy: Coaches view active clients notes (SELECT)
DROP POLICY IF EXISTS "Coaches view active clients notes" ON session_notes;
CREATE POLICY "Coaches view active clients notes" ON session_notes
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = cr.client_id) AND (cr.status = 'active'::text)))));

-- Policy: Coaches view own notes (SELECT)
DROP POLICY IF EXISTS "Coaches view own notes" ON session_notes;
CREATE POLICY "Coaches view own notes" ON session_notes
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((coach_id = auth.uid()));

-- ============================================================================
-- Table: user_devices
-- ============================================================================
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- Policy: users_manage_own_devices (ALL)
DROP POLICY IF EXISTS "users_manage_own_devices" ON user_devices;
CREATE POLICY "users_manage_own_devices" ON user_devices
    AS PERMISSIVE
    FOR ALL
    TO public
    USING ((auth.uid() = user_id))
    WITH CHECK ((auth.uid() = user_id));

-- ============================================================================
-- Table: users
-- ============================================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Clients can view active coaches profiles (SELECT)
DROP POLICY IF EXISTS "Clients can view active coaches profiles" ON users;
CREATE POLICY "Clients can view active coaches profiles" ON users
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.client_id = auth.uid()) AND (cr.coach_id = users.id) AND (cr.status = 'active'::text)))));

-- Policy: Coaches can view active clients profiles (SELECT)
DROP POLICY IF EXISTS "Coaches can view active clients profiles" ON users;
CREATE POLICY "Coaches can view active clients profiles" ON users
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = users.id) AND (cr.status = 'active'::text)))));

-- Policy: Users can insert their own profile (INSERT)
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
CREATE POLICY "Users can insert their own profile" ON users
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK ((auth.uid() = id));

-- Policy: Users can update their own profile (UPDATE)
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
CREATE POLICY "Users can update their own profile" ON users
    AS PERMISSIVE
    FOR UPDATE
    TO authenticated
    USING ((auth.uid() = id))
    WITH CHECK ((auth.uid() = id));

-- Policy: Users can view their own profile (SELECT)
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
CREATE POLICY "Users can view their own profile" ON users
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING ((auth.uid() = id));

-- ============================================================================
-- Table: workout_plans
-- ============================================================================
ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;

-- Policy: Coaches can create workouts for active clients (INSERT)
DROP POLICY IF EXISTS "Coaches can create workouts for active clients" ON workout_plans;
CREATE POLICY "Coaches can create workouts for active clients" ON workout_plans
    AS PERMISSIVE
    FOR INSERT
    TO authenticated
    WITH CHECK (((auth.uid() = creator_id) AND (EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = workout_plans.trainee_id) AND (cr.status = 'active'::text))))));

-- Policy: Coaches can view active clients workouts (SELECT)
DROP POLICY IF EXISTS "Coaches can view active clients workouts" ON workout_plans;
CREATE POLICY "Coaches can view active clients workouts" ON workout_plans
    AS PERMISSIVE
    FOR SELECT
    TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM coaching_relationships cr
  WHERE ((cr.coach_id = auth.uid()) AND (cr.client_id = workout_plans.trainee_id) AND (cr.status = 'active'::text)))));

-- Policy: Only creators can delete workout plans (DELETE)
DROP POLICY IF EXISTS "Only creators can delete workout plans" ON workout_plans;
CREATE POLICY "Only creators can delete workout plans" ON workout_plans
    AS PERMISSIVE
    FOR DELETE
    TO authenticated
    USING ((((creator_id IS NOT NULL) AND (auth.uid() = creator_id)) OR ((creator_id IS NULL) AND (auth.uid() = trainee_id))));

-- Policy: Users can create their own workout plans (INSERT)
DROP POLICY IF EXISTS "Users can create their own workout plans" ON workout_plans;
CREATE POLICY "Users can create their own workout plans" ON workout_plans
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK (((trainee_id = auth.uid()) OR (creator_id = auth.uid())));

-- Policy: Users can update their own workout plans (UPDATE)
DROP POLICY IF EXISTS "Users can update their own workout plans" ON workout_plans;
CREATE POLICY "Users can update their own workout plans" ON workout_plans
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING (((trainee_id = auth.uid()) OR (creator_id = auth.uid())));

-- Policy: Users can view their own workout plans (SELECT)
DROP POLICY IF EXISTS "Users can view their own workout plans" ON workout_plans;
CREATE POLICY "Users can view their own workout plans" ON workout_plans
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING (((trainee_id = auth.uid()) OR (creator_id = auth.uid())));

-- ============================================================================
-- Table: workout_templates
-- ============================================================================
ALTER TABLE workout_templates ENABLE ROW LEVEL SECURITY;

-- Policy: Users can create their own workout templates (INSERT)
DROP POLICY IF EXISTS "Users can create their own workout templates" ON workout_templates;
CREATE POLICY "Users can create their own workout templates" ON workout_templates
    AS PERMISSIVE
    FOR INSERT
    TO public
    WITH CHECK ((user_id = auth.uid()));

-- Policy: Users can delete their own workout templates (DELETE)
DROP POLICY IF EXISTS "Users can delete their own workout templates" ON workout_templates;
CREATE POLICY "Users can delete their own workout templates" ON workout_templates
    AS PERMISSIVE
    FOR DELETE
    TO public
    USING ((user_id = auth.uid()));

-- Policy: Users can update their own workout templates (UPDATE)
DROP POLICY IF EXISTS "Users can update their own workout templates" ON workout_templates;
CREATE POLICY "Users can update their own workout templates" ON workout_templates
    AS PERMISSIVE
    FOR UPDATE
    TO public
    USING ((user_id = auth.uid()));

-- Policy: Users can view their own workout templates (SELECT)
DROP POLICY IF EXISTS "Users can view their own workout templates" ON workout_templates;
CREATE POLICY "Users can view their own workout templates" ON workout_templates
    AS PERMISSIVE
    FOR SELECT
    TO public
    USING ((user_id = auth.uid()));

-- ============================================================================
-- Table: app_config (v5.1)
-- ============================================================================
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

-- Policy: app_config_public_read (SELECT)
DROP POLICY IF EXISTS "app_config_public_read" ON app_config;
CREATE POLICY "app_config_public_read" ON app_config
    FOR SELECT
    USING (true);
