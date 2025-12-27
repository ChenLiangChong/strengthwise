import 'package:get_it/get_it.dart';

import '../interfaces/i_auth_service.dart';
import '../interfaces/i_booking_service.dart';
import '../interfaces/i_custom_exercise_service.dart';
import '../interfaces/i_exercise_service.dart';
import '../interfaces/i_note_service.dart';
import '../interfaces/i_workout_service.dart';
import '../interfaces/i_statistics_service.dart';
import '../interfaces/i_body_data_service.dart';
import '../interfaces/i_user_service.dart';
import '../core/error_handling_service.dart';

import '../../controllers/interfaces/i_auth_controller.dart';
import '../../controllers/interfaces/i_booking_controller.dart';
import '../../controllers/interfaces/i_custom_exercise_controller.dart';
import '../../controllers/interfaces/i_exercise_controller.dart';
import '../../controllers/interfaces/i_note_controller.dart';
import '../../controllers/interfaces/i_workout_controller.dart';
import '../../controllers/interfaces/i_workout_execution_controller.dart';
import '../../controllers/interfaces/i_statistics_controller.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/custom_exercise_controller.dart';
import '../../controllers/exercise_controller.dart';
import '../../controllers/note_controller.dart';
import '../../controllers/workout_controller.dart';
import '../../controllers/workout_execution_controller.dart';
import '../../controllers/statistics_controller.dart';
import '../../controllers/body_data_controller.dart';

/// 控制器註冊器
/// 
/// 負責將所有控制器註冊到服務定位器（工廠模式）
class ControllerRegistry {
  /// 註冊所有控制器層（工廠模式）
  static void registerControllers(GetIt serviceLocator) {
    _registerAuthController(serviceLocator);
    _registerBookingController(serviceLocator);
    _registerCustomExerciseController(serviceLocator);
    _registerExerciseController(serviceLocator);
    _registerNoteController(serviceLocator);
    _registerWorkoutController(serviceLocator);
    _registerWorkoutExecutionController(serviceLocator);
    _registerStatisticsController(serviceLocator);
    _registerBodyDataController(serviceLocator);
  }

  /// 註冊身份驗證控制器
  static void _registerAuthController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IAuthController>()) {
      serviceLocator.registerFactory<IAuthController>(
        () => AuthController(
          authService: serviceLocator<IAuthService>(),
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊預約控制器
  static void _registerBookingController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IBookingController>()) {
      serviceLocator.registerFactory<IBookingController>(
        () => BookingController(
          bookingService: serviceLocator<IBookingService>(),
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊自定義運動控制器
  static void _registerCustomExerciseController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<ICustomExerciseController>()) {
      serviceLocator.registerFactory<ICustomExerciseController>(
        () => CustomExerciseController(
          service: serviceLocator<ICustomExerciseService>(),
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊運動項目控制器
  static void _registerExerciseController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IExerciseController>()) {
      serviceLocator.registerFactory<IExerciseController>(
        () => ExerciseController(
          service: serviceLocator<IExerciseService>(),
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊筆記控制器
  static void _registerNoteController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<INoteController>()) {
      serviceLocator.registerFactory<INoteController>(
        () => NoteController(
          noteService: serviceLocator<INoteService>(),
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊訓練計畫控制器
  static void _registerWorkoutController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IWorkoutController>()) {
      serviceLocator.registerFactory<IWorkoutController>(
        () => WorkoutController(
          workoutService: serviceLocator<IWorkoutService>(),
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊訓練執行控制器
  static void _registerWorkoutExecutionController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IWorkoutExecutionController>()) {
      serviceLocator.registerFactory<IWorkoutExecutionController>(
        () => WorkoutExecutionController(),
      );
    }
  }

  /// 註冊統計控制器
  static void _registerStatisticsController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IStatisticsController>()) {
      serviceLocator.registerFactory<IStatisticsController>(
        () => StatisticsController(
          statisticsService: serviceLocator<IStatisticsService>(),
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊身體數據控制器
  static void _registerBodyDataController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<BodyDataController>()) {
      serviceLocator.registerFactory<BodyDataController>(
        () => BodyDataController(
          bodyDataService: serviceLocator<IBodyDataService>(),
          userService: serviceLocator<IUserService>(),
          errorService: serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }
}

