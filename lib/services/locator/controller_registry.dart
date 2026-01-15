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
import '../interfaces/i_coaching_relationship_service.dart';
import '../interfaces/i_appointment_service.dart';
import '../interfaces/i_availability_slot_service.dart';
import '../interfaces/i_session_note_service.dart';
import '../interfaces/i_client_availability_service.dart';
import '../interfaces/i_drawing_service.dart';
import '../interfaces/i_invite_code_service.dart';
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
import '../../controllers/coaching_relationship_controller.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/availability_slot_controller.dart';
import '../../controllers/session_note_controller.dart';
import '../../controllers/client_availability_controller.dart';
import '../../controllers/drawing_controller.dart';
import '../../controllers/client_management_controller.dart';
import '../../controllers/coach_management_controller.dart';
import '../../controllers/delete_account_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/coach_profile_controller.dart';
import '../../controllers/event_bus_controller.dart';
import '../interfaces/i_coach_profile_service.dart';

/// 控制器註冊器
/// 
/// 負責將所有控制器註冊到服務定位器（工廠模式）
class ControllerRegistry {
  /// 註冊所有控制器層（工廠模式）
  static void registerControllers(GetIt serviceLocator) {
    // ⭐ v3.5: 先註冊 EventBusController（全局單例，其他 Controller 可能依賴）
    _registerEventBusController(serviceLocator);
    
    _registerAuthController(serviceLocator);
    _registerBookingController(serviceLocator);
    _registerCustomExerciseController(serviceLocator);
    _registerExerciseController(serviceLocator);
    _registerNoteController(serviceLocator);
    _registerWorkoutController(serviceLocator);
    _registerWorkoutExecutionController(serviceLocator);
    _registerStatisticsController(serviceLocator);
    _registerBodyDataController(serviceLocator);
    _registerCoachingRelationshipController(serviceLocator);
    _registerAppointmentController(serviceLocator);
    _registerAvailabilitySlotController(serviceLocator);
    _registerSessionNoteController(serviceLocator);
    _registerClientAvailabilityController(serviceLocator);
    _registerDrawingController(serviceLocator);
    _registerClientManagementController(serviceLocator);
    _registerCoachManagementController(serviceLocator);
    _registerDeleteAccountController(serviceLocator);
    _registerProfileController(serviceLocator);
    _registerCoachProfileController(serviceLocator);
  }

  /// ⭐ v3.5: 註冊事件匯流排控制器（全局單例）
  ///
  /// 作為 AppEventBus（Service 層）和 View 層之間的中間層，
  /// 所有頁面共享同一個實例來接收和發布事件。
  static void _registerEventBusController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<EventBusController>()) {
      serviceLocator.registerLazySingleton<EventBusController>(
        () => EventBusController(),
      );
    }
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
  /// ⭐ v3.5: 注入 EventBusController 用於發布模板 CUD 事件
  /// ⭐ v3.6: 注入 IAuthController 用於 EventBus userId fallback
  static void _registerWorkoutController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IWorkoutController>()) {
      serviceLocator.registerFactory<IWorkoutController>(
        () => WorkoutController(
          workoutService: serviceLocator<IWorkoutService>(),
          errorService: serviceLocator<ErrorHandlingService>(),
          eventBusController: serviceLocator<EventBusController>(), // ⭐ v3.5
          authController: serviceLocator<IAuthController>(), // ⭐ v3.6: EventBus fallback
        ),
      );
    }
  }

  /// 註冊訓練執行控制器
  /// ⭐ v3.5: 注入 EventBusController 用於發布訓練更新/完成事件
  static void _registerWorkoutExecutionController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<IWorkoutExecutionController>()) {
      serviceLocator.registerFactory<IWorkoutExecutionController>(
        () => WorkoutExecutionController(
          eventBusController: serviceLocator<EventBusController>(),
        ),
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
  /// ⭐ v3.5: 注入 EventBusController 用於發布身體數據事件
  static void _registerBodyDataController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<BodyDataController>()) {
      serviceLocator.registerFactory<BodyDataController>(
        () => BodyDataController(
          bodyDataService: serviceLocator<IBodyDataService>(),
          userService: serviceLocator<IUserService>(),
          errorService: serviceLocator<ErrorHandlingService>(),
          eventBusController: serviceLocator<EventBusController>(), // ⭐ v3.5
        ),
      );
    }
  }

  /// 註冊教練-學員關係控制器
  static void _registerCoachingRelationshipController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<CoachingRelationshipController>()) {
      serviceLocator.registerFactory<CoachingRelationshipController>(
        () => CoachingRelationshipController(
          serviceLocator<ICoachingRelationshipService>(),
          serviceLocator<IUserService>(),
          serviceLocator<IInviteCodeService>(),
          serviceLocator<ErrorHandlingService>(),
          serviceLocator<EventBusController>(), // ⭐ v3.5: EventBus
        ),
      );
    }
  }

  /// 註冊預約控制器（Phase 2）
  /// ⭐ v3.5: 注入 EventBusController 用於發布預約事件
  static void _registerAppointmentController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<AppointmentController>()) {
      serviceLocator.registerFactory<AppointmentController>(
        () => AppointmentController(
          serviceLocator<IAppointmentService>(),
          serviceLocator<ErrorHandlingService>(),
          serviceLocator<EventBusController>(), // ⭐ v3.5
        ),
      );
    }
  }

  /// 註冊時段控制器（Phase 2）
  static void _registerAvailabilitySlotController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<AvailabilitySlotController>()) {
      serviceLocator.registerFactory<AvailabilitySlotController>(
        () => AvailabilitySlotController(
          serviceLocator<IAvailabilitySlotService>(),
          serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊課程筆記控制器（Phase 3）
  static void _registerSessionNoteController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<SessionNoteController>()) {
      serviceLocator.registerFactory<SessionNoteController>(
        () => SessionNoteController(
          serviceLocator<ISessionNoteService>(),
          serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊學員時間偏好控制器（Phase 3）
  static void _registerClientAvailabilityController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<ClientAvailabilityController>()) {
      serviceLocator.registerFactory<ClientAvailabilityController>(
        () => ClientAvailabilityController(
          serviceLocator<IClientAvailabilityService>(),
          serviceLocator<ErrorHandlingService>(),
          serviceLocator<EventBusController>(), // ⭐ v3.5: EventBus
        ),
      );
    }
  }

  /// 註冊繪圖控制器（Phase 4A）
  static void _registerDrawingController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<DrawingController>()) {
      serviceLocator.registerFactory<DrawingController>(
        () => DrawingController(
          serviceLocator<IDrawingService>(),
          serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊學員管理控制器（Phase 4C - 教練端）
  /// ⭐ v3.5: 注入 EventBusController 用於發布訓練計畫 CUD 事件
  static void _registerClientManagementController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<ClientManagementController>()) {
      serviceLocator.registerFactory<ClientManagementController>(
        () => ClientManagementController(
          serviceLocator<ICoachingRelationshipService>(),
          serviceLocator<IWorkoutService>(),
          serviceLocator<IClientAvailabilityService>(),
          serviceLocator<IUserService>(),
          serviceLocator<ErrorHandlingService>(),
          serviceLocator<EventBusController>(), // ⭐ v3.5
        ),
      );
    }
  }

  /// 註冊教練管理控制器（Phase 4C - 學員端）
  static void _registerCoachManagementController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<CoachManagementController>()) {
      serviceLocator.registerFactory<CoachManagementController>(
        () => CoachManagementController(
          serviceLocator<ICoachingRelationshipService>(),
          serviceLocator<IWorkoutService>(),
          serviceLocator<IUserService>(),
          serviceLocator<ErrorHandlingService>(),
        ),
      );
    }
  }

  /// 註冊刪除帳號控制器
  static void _registerDeleteAccountController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<DeleteAccountController>()) {
      serviceLocator.registerFactory<DeleteAccountController>(
        () => DeleteAccountController(
          userService: serviceLocator<IUserService>(),
        ),
      );
    }
  }

  /// 註冊個人資料控制器
  ///
  /// ⭐ v3.1-B 修復：改為 LazySingleton
  /// 確保所有頁面共享同一個實例，當用戶更新 isCoach 時，
  /// 其他頁面（如 TrainingHubPage）能即時收到 notifyListeners 通知
  /// 
  /// ⭐ v3.5: 新增 IBodyDataService 依賴，用於同步體重到 body_data
  /// ⭐ v3.5: 新增 EventBusController 依賴，用於發布身體數據更新事件
  static void _registerProfileController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<ProfileController>()) {
      serviceLocator.registerLazySingleton<ProfileController>(
        () => ProfileController(
          userService: serviceLocator<IUserService>(),
          authService: serviceLocator<IAuthService>(),
          bodyDataService: serviceLocator<IBodyDataService>(),
          eventBusController: serviceLocator<EventBusController>(),
        ),
      );
    }
  }

  /// 註冊教練公開檔案控制器 ⭐ v2.9
  static void _registerCoachProfileController(GetIt serviceLocator) {
    if (!serviceLocator.isRegistered<CoachProfileController>()) {
      serviceLocator.registerFactory<CoachProfileController>(
        () => CoachProfileController(
          profileService: serviceLocator<ICoachProfileService>(),
          authService: serviceLocator<IAuthService>(),
        ),
      );
    }
  }
}

