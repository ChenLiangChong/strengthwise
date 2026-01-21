/// 測試用 Mock 類
///
/// 使用 mocktail 建立 Service Interface 的 Mock
///
/// 全部 Service 測試計劃（v4.0）
/// - 已有測試：ReadinessService, AppointmentService, WorkoutService, SessionNoteService
/// - 新增測試：StatisticsService, BodyDataService, BookingService 等

import 'package:mocktail/mocktail.dart';

// ============================================================================
// Service Interfaces
// ============================================================================
import 'package:strengthwise/services/interfaces/i_readiness_service.dart';
import 'package:strengthwise/services/interfaces/i_appointment_service.dart';
import 'package:strengthwise/services/interfaces/i_workout_service.dart';
import 'package:strengthwise/services/interfaces/i_session_note_service.dart';
import 'package:strengthwise/services/interfaces/i_statistics_service.dart';
import 'package:strengthwise/services/interfaces/i_exercise_service.dart';
import 'package:strengthwise/services/interfaces/i_body_data_service.dart';
import 'package:strengthwise/services/interfaces/i_booking_service.dart';
import 'package:strengthwise/services/interfaces/i_health_assessment_service.dart';
import 'package:strengthwise/services/interfaces/i_coaching_relationship_service.dart';
import 'package:strengthwise/services/interfaces/i_auth_service.dart';
import 'package:strengthwise/services/interfaces/i_user_service.dart';
import 'package:strengthwise/services/interfaces/i_availability_slot_service.dart';
import 'package:strengthwise/services/interfaces/i_client_availability_service.dart';
import 'package:strengthwise/services/interfaces/i_coach_profile_service.dart';
import 'package:strengthwise/services/interfaces/i_invite_code_service.dart';
import 'package:strengthwise/services/interfaces/i_note_service.dart';
import 'package:strengthwise/services/interfaces/i_custom_exercise_service.dart';
import 'package:strengthwise/services/interfaces/i_favorites_service.dart';
import 'package:strengthwise/services/interfaces/i_drawing_service.dart';
import 'package:strengthwise/services/interfaces/i_coach_display_preferences_service.dart';
import 'package:strengthwise/services/interfaces/i_coach_assessment_note_service.dart';
import 'package:strengthwise/services/interfaces/i_injury_coach_note_service.dart';
import 'package:strengthwise/services/interfaces/i_notification_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/services/cache/statistics_local_cache_service.dart';
import 'package:strengthwise/services/cache/workout_plan_local_cache_service.dart';

// ============================================================================
// Models for Fallback Values
// ============================================================================
import 'package:strengthwise/models/readiness/daily_readiness_model.dart';
import 'package:strengthwise/models/statistics_model.dart';
import 'package:strengthwise/models/exercise_model.dart';
import 'package:strengthwise/models/tracking_mode.dart';
import 'package:strengthwise/models/body_data_record.dart';
import 'package:strengthwise/models/health_assessment_models.dart';
import 'package:strengthwise/models/coaching_relationship_model.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/models/availability_slot_model.dart';
import 'package:strengthwise/models/client_availability_model.dart';
import 'package:strengthwise/models/coach_profile/coach_profile_model.dart';
import 'package:strengthwise/models/invite_code_model.dart';
import 'package:strengthwise/models/note_model.dart';
import 'package:strengthwise/models/custom_exercise_model.dart';
import 'package:strengthwise/models/favorite_exercise_model.dart';
import 'package:strengthwise/models/coach_assessment_note_model.dart';
import 'package:strengthwise/models/injury_coach_note_model.dart';
import 'package:strengthwise/models/drawing_note_model.dart';
import 'package:strengthwise/models/coach_display_preferences_model.dart';

// ============================================================================
// Mock Classes - 已有測試
// ============================================================================

/// IReadinessService Mock
class MockReadinessService extends Mock implements IReadinessService {}

/// IAppointmentService Mock
class MockAppointmentService extends Mock implements IAppointmentService {}

/// IWorkoutService Mock
class MockWorkoutService extends Mock implements IWorkoutService {}

/// ISessionNoteService Mock
class MockSessionNoteService extends Mock implements ISessionNoteService {}

/// INotificationService Mock
class MockNotificationService extends Mock implements INotificationService {}

// ============================================================================
// Mock Classes - P0 核心 Service
// ============================================================================

/// IStatisticsService Mock
class MockStatisticsService extends Mock implements IStatisticsService {}

// ============================================================================
// Mock Classes - P1 重要 Service
// ============================================================================

/// IExerciseService Mock
class MockExerciseService extends Mock implements IExerciseService {}

/// IBodyDataService Mock
class MockBodyDataService extends Mock implements IBodyDataService {}

/// IBookingService Mock
class MockBookingService extends Mock implements IBookingService {}

/// IHealthAssessmentService Mock
class MockHealthAssessmentService extends Mock implements IHealthAssessmentService {}

/// ICoachingRelationshipService Mock
class MockCoachingRelationshipService extends Mock implements ICoachingRelationshipService {}

/// IAuthService Mock
class MockAuthService extends Mock implements IAuthService {}

/// IUserService Mock
class MockUserService extends Mock implements IUserService {}

// ============================================================================
// Mock Classes - P2 次要 Service
// ============================================================================

/// IAvailabilitySlotService Mock
class MockAvailabilitySlotService extends Mock implements IAvailabilitySlotService {}

/// IClientAvailabilityService Mock
class MockClientAvailabilityService extends Mock implements IClientAvailabilityService {}

/// ICoachProfileService Mock
class MockCoachProfileService extends Mock implements ICoachProfileService {}

/// IInviteCodeService Mock
class MockInviteCodeService extends Mock implements IInviteCodeService {}

/// INoteService Mock
class MockNoteService extends Mock implements INoteService {}

/// ICustomExerciseService Mock
class MockCustomExerciseService extends Mock implements ICustomExerciseService {}

// ============================================================================
// Mock Classes - P3 輔助 Service
// ============================================================================

/// IFavoritesService Mock
class MockFavoritesService extends Mock implements IFavoritesService {}

/// IDrawingService Mock
class MockDrawingService extends Mock implements IDrawingService {}

/// ICoachDisplayPreferencesService Mock
class MockCoachDisplayPreferencesService extends Mock implements ICoachDisplayPreferencesService {}

/// ICoachAssessmentNoteService Mock
class MockCoachAssessmentNoteService extends Mock implements ICoachAssessmentNoteService {}

/// IInjuryCoachNoteService Mock
class MockInjuryCoachNoteService extends Mock implements IInjuryCoachNoteService {}

// ============================================================================
// Mock Classes - 核心依賴
// ============================================================================

/// ErrorHandlingService Mock
class MockErrorHandlingService extends Mock implements ErrorHandlingService {}

/// StatisticsLocalCacheService Mock
class MockStatisticsLocalCacheService extends Mock implements StatisticsLocalCacheService {}

/// WorkoutPlanLocalCacheService Mock
class MockWorkoutPlanLocalCacheService extends Mock implements WorkoutPlanLocalCacheService {}

// ============================================================================
// Fallback Values Registration
// ============================================================================

/// 註冊 fallback values（用於 any() matcher）
///
/// 在 setUpAll() 中調用此函數以註冊所有需要的 fallback values
void registerFallbackValues() {
  // -------------------------------------------------------------------------
  // Readiness
  // -------------------------------------------------------------------------
  registerFallbackValue(DailyReadinessModel(
    id: 'fallback',
    userId: 'fallback',
    logDate: DateTime.now(),
    metrics: const ReadinessMetrics(
      sleepQuality: 3,
      sleepHours: 7.0,
      soreness: 3,
      stress: 3,
      energyLevel: 3,
    ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));

  // -------------------------------------------------------------------------
  // Statistics
  // -------------------------------------------------------------------------
  registerFallbackValue(TimeRange.week);
  registerFallbackValue(StatisticsData.empty(TimeRange.week));
  registerFallbackValue(TrainingFrequency(
    totalWorkouts: 0,
    totalHours: 0,
    averageHours: 0,
    consecutiveDays: 0,
    comparisonValue: 0,
  ));

  // -------------------------------------------------------------------------
  // Exercise
  // -------------------------------------------------------------------------
  registerFallbackValue(Exercise(
    id: 'fallback',
    name: 'fallback',
    nameEn: 'fallback',
    bodyParts: ['chest'],
    type: 'strength',
    equipment: 'barbell',
    jointType: 'compound',
    level1: '',
    level2: '',
    level3: '',
    level4: '',
    level5: '',
    trainingType: '重訓',
    bodyPart: '胸',
    specificMuscle: '胸大肌',
    equipmentCategory: '自由重量',
    equipmentSubcategory: '槓鈴',
    description: '',
    videoUrl: '',
    apps: [],
    createdAt: DateTime.now(),
    trackingMode: TrackingMode.weightReps,
  ));

  // -------------------------------------------------------------------------
  // Body Data
  // -------------------------------------------------------------------------
  registerFallbackValue(BodyDataRecord(
    id: 'fallback',
    userId: 'fallback',
    weight: 70.0,
    recordDate: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));

  // -------------------------------------------------------------------------
  // Health Assessment
  // -------------------------------------------------------------------------
  registerFallbackValue(HealthAssessmentModel(
    id: 'fallback',
    userId: 'fallback',
    assessmentDate: DateTime.now(),
    heartDisease: false,
    chestPainExercise: false,
    chestPainRest: false,
    dizziness: false,
    boneJointProblem: false,
    medication: false,
    otherReason: false,
    isCleared: true,
    injuries: const [],
    equipmentAccess: const [],
    version: 1,
    isCurrent: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));

  // -------------------------------------------------------------------------
  // Coaching Relationship
  // -------------------------------------------------------------------------
  registerFallbackValue(CoachingRelationshipModel(
    id: 'fallback',
    coachId: 'fallback',
    clientId: 'fallback',
    status: 'active',
    invitedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));

  // -------------------------------------------------------------------------
  // User
  // -------------------------------------------------------------------------
  registerFallbackValue(UserModel(
    uid: 'fallback',
    email: 'fallback@test.com',
    displayName: 'Fallback User',
  ));

  // -------------------------------------------------------------------------
  // Availability
  // -------------------------------------------------------------------------
  registerFallbackValue(AvailabilitySlotModel(
    id: 'fallback',
    coachId: 'fallback',
    startTime: DateTime.now(),
    endTime: DateTime.now().add(const Duration(hours: 1)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));

  registerFallbackValue(ClientAvailabilityModel(
    id: 'fallback',
    clientId: 'fallback',
    startTime: DateTime.now(),
    endTime: DateTime.now().add(const Duration(hours: 1)),
    priority: AvailabilityPriority.available,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));

  // -------------------------------------------------------------------------
  // Coach Profile
  // -------------------------------------------------------------------------
  registerFallbackValue(CoachProfileModel(
    id: 'fallback',
    displayName: 'Fallback Coach',
  ));

  // -------------------------------------------------------------------------
  // Invite Code
  // -------------------------------------------------------------------------
  registerFallbackValue(InviteCodeModel(
    code: 'FALLBACK',
    coachId: 'fallback',
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 5)),
  ));

  // -------------------------------------------------------------------------
  // Note
  // -------------------------------------------------------------------------
  registerFallbackValue(Note(
    id: 'fallback',
    title: 'Fallback Note',
    textContent: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));

  // -------------------------------------------------------------------------
  // Custom Exercise
  // -------------------------------------------------------------------------
  registerFallbackValue(CustomExercise(
    id: 'fallback',
    name: 'Fallback Exercise',
    userId: 'fallback',
    bodyPart: '胸部',
    createdAt: DateTime.now(),
  ));

  // -------------------------------------------------------------------------
  // Favorites
  // -------------------------------------------------------------------------
  registerFallbackValue(FavoriteExercise(
    exerciseId: 'fallback',
    exerciseName: 'Fallback',
    bodyPart: '胸部',
    addedAt: DateTime.now(),
  ));

  // -------------------------------------------------------------------------
  // Coach Assessment Note
  // -------------------------------------------------------------------------
  registerFallbackValue(CoachAssessmentNoteModel(
    id: 'fallback',
    assessmentId: 'fallback',
    coachId: 'fallback',
    notes: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));

  // -------------------------------------------------------------------------
  // Injury Coach Note
  // -------------------------------------------------------------------------
  registerFallbackValue(InjuryCoachNoteModel(
    id: 'fallback',
    coachId: 'fallback',
    clientId: 'fallback',
    injurySite: 'fallback',
    note: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));

  // -------------------------------------------------------------------------
  // Drawing Note
  // -------------------------------------------------------------------------
  registerFallbackValue(DrawingNoteModel(
    id: 'fallback',
    sessionNoteId: 'fallback',
    templateType: 'note1',
    layers: const [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));

  // -------------------------------------------------------------------------
  // Coach Display Preferences
  // -------------------------------------------------------------------------
  registerFallbackValue(CoachDisplayPreferencesModel(
    coachId: 'fallback',
    healthAssessmentFields: CoachDisplayPreferencesModel.defaultFields,
    updatedAt: DateTime.now(),
  ));
}
