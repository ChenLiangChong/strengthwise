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

import '../supabase/auth_service_supabase.dart';
import '../supabase/booking_service_supabase.dart';
import '../supabase/custom_exercise_service_supabase.dart';
import '../supabase/exercise_service_supabase.dart';
import '../supabase/note_service_supabase.dart';
import '../supabase/user_service_supabase.dart';
import '../supabase/workout_service_supabase.dart';
import '../supabase/statistics_service_supabase.dart';
import '../supabase/body_data_service_supabase.dart';

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
}

