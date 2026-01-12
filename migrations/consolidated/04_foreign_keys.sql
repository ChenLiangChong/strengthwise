-- ============================================================================
-- Foreign Keys（外鍵關係）
-- 導出時間：2026-01-12 19:57:14
-- ============================================================================

-- Table: appointments
ALTER TABLE appointments
    ADD CONSTRAINT appointments_cancelled_by_fkey
    FOREIGN KEY (cancelled_by)
    REFERENCES users(id)
;

ALTER TABLE appointments
    ADD CONSTRAINT appointments_client_id_fkey
    FOREIGN KEY (client_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

ALTER TABLE appointments
    ADD CONSTRAINT appointments_coach_id_fkey
    FOREIGN KEY (coach_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

ALTER TABLE appointments
    ADD CONSTRAINT appointments_workout_plan_id_fkey
    FOREIGN KEY (workout_plan_id)
    REFERENCES workout_plans(id)
ON DELETE SET NULL
;

-- Table: availability_slots
ALTER TABLE availability_slots
    ADD CONSTRAINT availability_slots_coach_id_fkey
    FOREIGN KEY (coach_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: body_data
ALTER TABLE body_data
    ADD CONSTRAINT body_data_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: client_availability
ALTER TABLE client_availability
    ADD CONSTRAINT client_availability_client_id_fkey
    FOREIGN KEY (client_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: coach_assessment_notes
ALTER TABLE coach_assessment_notes
    ADD CONSTRAINT coach_assessment_notes_assessment_id_fkey
    FOREIGN KEY (assessment_id)
    REFERENCES health_assessments(id)
ON DELETE CASCADE
;

ALTER TABLE coach_assessment_notes
    ADD CONSTRAINT coach_assessment_notes_coach_id_fkey
    FOREIGN KEY (coach_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: coach_booking_settings
ALTER TABLE coach_booking_settings
    ADD CONSTRAINT coach_booking_settings_coach_id_fkey
    FOREIGN KEY (coach_id)
    REFERENCES coaches(id)
ON DELETE CASCADE
;

-- Table: coach_display_preferences
ALTER TABLE coach_display_preferences
    ADD CONSTRAINT coach_display_preferences_coach_id_fkey
    FOREIGN KEY (coach_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: coaches
ALTER TABLE coaches
    ADD CONSTRAINT coaches_id_fkey
    FOREIGN KEY (id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: coaching_relationships
ALTER TABLE coaching_relationships
    ADD CONSTRAINT coaching_relationships_client_id_fkey
    FOREIGN KEY (client_id)
    REFERENCES users(id)
ON DELETE SET NULL
;

ALTER TABLE coaching_relationships
    ADD CONSTRAINT coaching_relationships_coach_id_fkey
    FOREIGN KEY (coach_id)
    REFERENCES users(id)
ON DELETE SET NULL
;

-- Table: custom_exercises
ALTER TABLE custom_exercises
    ADD CONSTRAINT custom_exercises_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
ON DELETE SET NULL
;

-- Table: daily_readiness
ALTER TABLE daily_readiness
    ADD CONSTRAINT daily_readiness_appointment_id_fkey
    FOREIGN KEY (appointment_id)
    REFERENCES appointments(id)
ON DELETE SET NULL
;

ALTER TABLE daily_readiness
    ADD CONSTRAINT daily_readiness_session_note_id_fkey
    FOREIGN KEY (session_note_id)
    REFERENCES session_notes(id)
ON DELETE SET NULL
;

ALTER TABLE daily_readiness
    ADD CONSTRAINT daily_readiness_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: daily_workout_summary
ALTER TABLE daily_workout_summary
    ADD CONSTRAINT daily_workout_summary_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: health_assessments
ALTER TABLE health_assessments
    ADD CONSTRAINT health_assessments_assessed_by_fkey
    FOREIGN KEY (assessed_by)
    REFERENCES users(id)
ON DELETE SET NULL
;

ALTER TABLE health_assessments
    ADD CONSTRAINT health_assessments_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: injury_coach_notes
ALTER TABLE injury_coach_notes
    ADD CONSTRAINT injury_coach_notes_client_id_fkey
    FOREIGN KEY (client_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

ALTER TABLE injury_coach_notes
    ADD CONSTRAINT injury_coach_notes_coach_id_fkey
    FOREIGN KEY (coach_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: invite_codes
ALTER TABLE invite_codes
    ADD CONSTRAINT invite_codes_coach_id_fkey
    FOREIGN KEY (coach_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: notes
ALTER TABLE notes
    ADD CONSTRAINT notes_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: personal_records
ALTER TABLE personal_records
    ADD CONSTRAINT personal_records_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: session_notes
ALTER TABLE session_notes
    ADD CONSTRAINT session_notes_appointment_id_fkey
    FOREIGN KEY (appointment_id)
    REFERENCES appointments(id)
ON DELETE SET NULL
;

ALTER TABLE session_notes
    ADD CONSTRAINT session_notes_client_id_fkey
    FOREIGN KEY (client_id)
    REFERENCES users(id)
ON DELETE SET NULL
;

ALTER TABLE session_notes
    ADD CONSTRAINT session_notes_coach_id_fkey
    FOREIGN KEY (coach_id)
    REFERENCES users(id)
ON DELETE SET NULL
;

ALTER TABLE session_notes
    ADD CONSTRAINT session_notes_workout_log_id_fkey
    FOREIGN KEY (workout_log_id)
    REFERENCES workout_plans(id)
ON DELETE SET NULL
;

-- Table: user_devices
ALTER TABLE user_devices
    ADD CONSTRAINT user_devices_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
ON DELETE CASCADE
;

-- Table: workout_plans
ALTER TABLE workout_plans
    ADD CONSTRAINT workout_plans_appointment_id_fkey
    FOREIGN KEY (appointment_id)
    REFERENCES appointments(id)
ON DELETE SET NULL
;

ALTER TABLE workout_plans
    ADD CONSTRAINT workout_plans_creator_id_fkey
    FOREIGN KEY (creator_id)
    REFERENCES users(id)
ON DELETE SET NULL
;

ALTER TABLE workout_plans
    ADD CONSTRAINT workout_plans_trainee_id_fkey
    FOREIGN KEY (trainee_id)
    REFERENCES users(id)
ON DELETE SET NULL
;

ALTER TABLE workout_plans
    ADD CONSTRAINT workout_plans_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
ON DELETE SET NULL
;

-- Table: workout_templates
ALTER TABLE workout_templates
    ADD CONSTRAINT workout_templates_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
ON DELETE CASCADE
;
