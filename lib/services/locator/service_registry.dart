import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../interfaces/i_auth_service.dart';
import '../interfaces/i_booking_service.dart';
import '../interfaces/i_custom_exercise_service.dart';
import '../interfaces/i_exercise_service.dart';
import '../interfaces/i_note_service.dart';
import '../interfaces/i_user_service.dart';
import '../interfaces/i_workout_service.dart';
import '../interfaces/i_statistics_service.dart';
import '../interfaces/i_favorites_service.dart';
import '../interfaces/i_body_data_service.dart';
import '../interfaces/i_coaching_relationship_service.dart';
import '../interfaces/i_appointment_service.dart';
import '../interfaces/i_availability_slot_service.dart';
import '../interfaces/i_session_note_service.dart';
import '../interfaces/i_client_availability_service.dart';
import '../interfaces/i_drawing_service.dart';
import '../interfaces/i_invite_code_service.dart';
import '../interfaces/i_health_assessment_service.dart';
import '../interfaces/i_coach_display_preferences_service.dart';
import '../interfaces/i_coach_assessment_note_service.dart';
import '../interfaces/i_coach_profile_service.dart';
import '../interfaces/i_readiness_service.dart';
import '../interfaces/i_notification_service.dart';

import '../supabase/auth_service_supabase.dart';
import '../supabase/booking_service_supabase.dart';
import '../supabase/custom_exercise_service_supabase.dart';
import '../supabase/exercise_service_supabase.dart';
import '../supabase/note_service_supabase.dart';
import '../supabase/user_service_supabase.dart';
import '../supabase/workout_service_supabase.dart';
import '../supabase/statistics_service_supabase.dart';
import '../supabase/body_data_service_supabase.dart';
import '../supabase/coaching_relationship_service_supabase.dart';
import '../supabase/health_assessment_service_supabase.dart';
import '../supabase/coach_display_preferences_service_supabase.dart';
import '../supabase/coach_assessment_note_service_supabase.dart';
import '../supabase/coach_profile_service_supabase.dart';
import '../supabase/readiness_service_supabase.dart';
import '../supabase/appointment_service_supabase.dart';
import '../supabase/availability_slot_service_supabase.dart';
import '../supabase/session_note_service_supabase.dart';
import '../supabase/client_availability_service_supabase.dart';
import '../supabase/drawing_service_supabase.dart';
import '../supabase/invite_code_service_supabase.dart';

import '../cache/favorites_service.dart';
import '../cache/statistics_local_cache_service.dart';
import '../cache/workout_plan_local_cache_service.dart';
import '../cache/user_local_cache_service.dart';
import '../cache/relationship_local_cache_service.dart';
import '../core/error_handling_service.dart';
import '../notification/notification_service.dart';
import '../realtime/session_realtime_service.dart';
import '../core/onboarding_service.dart';

/// 服務註冊器
/// 
/// 負責將所有服務註冊到服務定位器
class ServiceRegistry {
  /// 註冊所有服務層（懶加載單例）
  static void registerServices(GetIt serviceLocator) {
    // ⚡ Phase 2：先註冊快取服務（其他服務依賴）
    _registerLocalCacheServices(serviceLocator);
    
    _registerAuthService(serviceLocator);
    _registerBookingService(serviceLocator);
    _registerCustomExerciseService(serviceLocator);
    _registerExerciseService(serviceLocator);
    _registerNoteService(serviceLocator);
    _registerUserService(serviceLocator);
    _registerWorkoutService(serviceLocator);
    _registerStatisticsService(serviceLocator);
    _registerFavoritesService(serviceLocator);
    _registerBodyDataService(serviceLocator);
    _registerCoachingRelationshipService(serviceLocator);
    _registerAppointmentService(serviceLocator);
    _registerAvailabilitySlotService(serviceLocator);
    _registerSessionNoteService(serviceLocator);
    _registerClientAvailabilityService(serviceLocator);
    _registerDrawingService(serviceLocator);
    _registerInviteCodeService(serviceLocator);
    _registerHealthAssessmentService(serviceLocator);
    _registerReadinessService(serviceLocator);
    _registerNotificationService(serviceLocator);
    _registerSessionRealtimeService(serviceLocator);
    _registerOnboardingService(serviceLocator);
  }

  /// ⚡ 註冊本地快取服務（Phase 2 持久化優化）
  static void _registerLocalCacheServices(GetIt serviceLocator) {
    // 統計數據快取
    if (!serviceLocator.isRegistered<StatisticsLocalCacheService>()) {
      serviceLocator.registerLazySingleton<StatisticsLocalCacheService>(
        () => StatisticsLocalCacheService(),
      );
    }

    // 訓練計劃快取
    if (!serviceLocator.isRegistered<WorkoutPlanLocalCacheService>()) {
      serviceLocator.registerLazySingleton<WorkoutPlanLocalCacheService>(
        () => WorkoutPlanLocalCacheService(),
      );
    }

    // ⚡ 用戶資料快取（App 啟動時立即顯示用戶名稱、頭像）
    if (!serviceLocator.isRegistered<UserLocalCacheService>()) {
      serviceLocator.registerLazySingleton<UserLocalCacheService>(
        () => UserLocalCacheService(),
      );
    }

    // ⚡ 教練學員關係快取（首頁立即顯示學員列表）
    if (!serviceLocator.isRegistered<RelationshipLocalCacheService>()) {
      serviceLocator.registerLazySingleton<RelationshipLocalCacheService>(
        () => RelationshipLocalCacheService(),
      );
    }
  }

  /// 註冊身份驗證服務（使用 Supabase 版本）
  static void _registerAuthService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IAuthService>()) {
      serviceLocator.registerLazySingleton<IAuthService>(
        () => AuthServiceSupabase(
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊預約服務（使用 Supabase 版本）
  static void _registerBookingService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IBookingService>()) {
      serviceLocator.registerLazySingleton<IBookingService>(() {
        final bookingService = BookingServiceSupabase(
          supabase: Supabase.instance.client,
          errorService: serviceLocator<ErrorHandlingService>(),
        );
        return bookingService;
      });
    }
  }

  /// 註冊自定義運動服務（使用 Supabase 版本）
  static void _registerCustomExerciseService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<ICustomExerciseService>()) {
      serviceLocator.registerLazySingleton<ICustomExerciseService>(
        () => CustomExerciseServiceSupabase(
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊運動項目服務（使用 Supabase 版本）
  static void _registerExerciseService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IExerciseService>()) {
      serviceLocator.registerLazySingleton<IExerciseService>(
        () => ExerciseServiceSupabase(
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊筆記服務（使用 Supabase 版本）
  static void _registerNoteService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<INoteService>()) {
      serviceLocator.registerLazySingleton<INoteService>(
        () => NoteServiceSupabase(
          supabase: Supabase.instance.client,
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊用戶服務（使用 Supabase 版本）
  static void _registerUserService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IUserService>()) {
      serviceLocator.registerLazySingleton<IUserService>(
        () => UserServiceSupabase(
          errorService: serviceLocator<ErrorHandlingService>(),
          authService: serviceLocator<IAuthService>(),
          localCacheService: serviceLocator<UserLocalCacheService>(),  // ⚡ 注入 Hive 快取
        ),
      );
    }
  }

  /// 註冊訓練計畫服務（使用 Supabase 版本）
  static void _registerWorkoutService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IWorkoutService>()) {
      serviceLocator.registerLazySingleton<IWorkoutService>(
        () {
          final service = WorkoutServiceSupabase(
            errorService: serviceLocator<ErrorHandlingService>(),
            localCacheService: serviceLocator<WorkoutPlanLocalCacheService>(),  // ⚡ 注入 Hive 快取
            statisticsCacheService: serviceLocator<StatisticsLocalCacheService>(),  // ⚡ 統計快取聯動
          );
          // 立即初始化，避免警告
          service.initialize();
          return service;
        },
      );
    }
  }

  /// 註冊統計服務（使用 Supabase 版本）
  static void _registerStatisticsService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IStatisticsService>()) {
      serviceLocator.registerLazySingleton<IStatisticsService>(
        () => StatisticsServiceSupabase(
          supabase: Supabase.instance.client,
          errorService: serviceLocator<ErrorHandlingService>(),
          exerciseService: serviceLocator<IExerciseService>(),
          localCacheService: serviceLocator<StatisticsLocalCacheService>(),  // ⚡ 注入 Hive 快取
        ),
      );
    }
  }

  /// 註冊收藏服務
  static void _registerFavoritesService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IFavoritesService>()) {
      serviceLocator.registerLazySingleton<IFavoritesService>(
        () => FavoritesService(
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊身體數據服務（使用 Supabase 版本）
  static void _registerBodyDataService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IBodyDataService>()) {
      serviceLocator.registerLazySingleton<IBodyDataService>(
        () => BodyDataServiceSupabase(
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊教練-學員關係服務（使用 Supabase 版本）
  static void _registerCoachingRelationshipService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<ICoachingRelationshipService>()) {
      serviceLocator.registerLazySingleton<ICoachingRelationshipService>(
        () => CoachingRelationshipServiceSupabase(
          Supabase.instance.client,
          serviceLocator<ErrorHandlingService>(),
          localCacheService: serviceLocator<RelationshipLocalCacheService>(),  // ⚡ 注入 Hive 快取
        ),
      );
    }
  }

  /// 註冊預約服務（Phase 2）
  static void _registerAppointmentService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IAppointmentService>()) {
      serviceLocator.registerLazySingleton<IAppointmentService>(
        () => AppointmentServiceSupabase(
          supabase: Supabase.instance.client,
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊時段服務（Phase 2）
  static void _registerAvailabilitySlotService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IAvailabilitySlotService>()) {
      serviceLocator.registerLazySingleton<IAvailabilitySlotService>(
        () => AvailabilitySlotServiceSupabase(
          supabase: Supabase.instance.client,
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊課程筆記服務（Phase 3）
  static void _registerSessionNoteService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<ISessionNoteService>()) {
      serviceLocator.registerLazySingleton<ISessionNoteService>(
        () => SessionNoteServiceSupabase(
          Supabase.instance.client,
        ),
      );
    }
  }

  /// 註冊學員時間偏好服務（Phase 3）
  static void _registerClientAvailabilityService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IClientAvailabilityService>()) {
      serviceLocator.registerLazySingleton<IClientAvailabilityService>(
        () => ClientAvailabilityServiceSupabase(
          Supabase.instance.client,
        ),
      );
    }
  }

  /// 註冊繪圖服務（Phase 4A）
  static void _registerDrawingService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IDrawingService>()) {
      serviceLocator.registerLazySingleton<IDrawingService>(
        () => DrawingServiceSupabase(
          Supabase.instance.client,
        ),
      );
    }
  }

  /// 註冊邀請碼服務（v2.2+）
  static void _registerInviteCodeService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IInviteCodeService>()) {
      serviceLocator.registerLazySingleton<IInviteCodeService>(
        () => InviteCodeServiceSupabase(
          Supabase.instance.client,
        ),
      );
    }
  }

  /// 註冊健康評估服務
  static void _registerHealthAssessmentService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IHealthAssessmentService>()) {
      serviceLocator.registerLazySingleton<IHealthAssessmentService>(
        () => HealthAssessmentServiceSupabase(
          Supabase.instance.client,
          serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
    
    // 教練顯示偏好服務
    if (!serviceLocator.isRegistered<ICoachDisplayPreferencesService>()) {
      serviceLocator.registerLazySingleton<ICoachDisplayPreferencesService>(
        () => CoachDisplayPreferencesServiceSupabase(
          supabase: Supabase.instance.client,
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }

    // 教練評估備註服務
    if (!serviceLocator.isRegistered<ICoachAssessmentNoteService>()) {
      serviceLocator.registerLazySingleton<ICoachAssessmentNoteService>(
        () => CoachAssessmentNoteServiceSupabase(
          supabase: Supabase.instance.client,
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }

    // 教練公開檔案服務 ⭐ v2.9
    if (!serviceLocator.isRegistered<ICoachProfileService>()) {
      serviceLocator.registerLazySingleton<ICoachProfileService>(
        () => CoachProfileServiceSupabase(
          supabase: Supabase.instance.client,
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊課前問卷服務（v3.0）
  static void _registerReadinessService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IReadinessService>()) {
      serviceLocator.registerLazySingleton<IReadinessService>(
        () => ReadinessServiceSupabase(
          Supabase.instance.client,
          serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊推播通知服務（v3.0-C）⭐
  static void _registerNotificationService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<INotificationService>()) {
      serviceLocator.registerLazySingleton<INotificationService>(
        () => NotificationService(
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊 Session Realtime 服務（即時同步）⭐ v3.1
  static void _registerSessionRealtimeService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<SessionRealtimeService>()) {
      serviceLocator.registerLazySingleton<SessionRealtimeService>(
        () => SessionRealtimeService(
          supabase: Supabase.instance.client,
        ),
      );
    }
  }

  /// ⭐ v3.2: 註冊 Onboarding 引導服務
  static void _registerOnboardingService(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<OnboardingService>()) {
      serviceLocator.registerLazySingleton<OnboardingService>(
        () => OnboardingService(),
      );
    }
  }
}

