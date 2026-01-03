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
import '../appointment_service_supabase.dart';
import '../availability_slot_service_supabase.dart';
import '../session_note_service_supabase.dart';
import '../client_availability_service_supabase.dart';
import '../drawing_service_supabase.dart';
import '../supabase/invite_code_service_supabase.dart';

import '../cache/favorites_service.dart';
import '../core/error_handling_service.dart';

/// 服務註冊器
/// 
/// 負責將所有服務註冊到服務定位器
class ServiceRegistry {
  /// 註冊所有服務層（懶加載單例）
  static void registerServices(GetIt serviceLocator) {
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
          authService: serviceLocator<IAuthService>(),  // ✅ 注入 AuthService
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
  }
}

