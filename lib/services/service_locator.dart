import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'interfaces/i_auth_service.dart';
import 'interfaces/i_booking_service.dart';
import 'interfaces/i_custom_exercise_service.dart';
import 'interfaces/i_exercise_service.dart';
import 'interfaces/i_note_service.dart';
import 'interfaces/i_user_service.dart';
import 'interfaces/i_workout_service.dart';
import 'interfaces/i_statistics_service.dart';
import 'interfaces/i_favorites_service.dart';
import 'auth_wrapper.dart';
import 'booking_service.dart';
import 'custom_exercise_service.dart';
import 'exercise_service.dart';
import 'note_service.dart';
import 'user_service.dart';
import 'user_migration_service.dart';
import 'workout_service.dart';
import 'statistics_service.dart';
import 'favorites_service.dart';
import 'error_handling_service.dart';
import 'exercise_cache_service.dart';
import 'preload_service.dart';
import 'default_templates_service.dart';
import '../controllers/interfaces/i_auth_controller.dart';
import '../controllers/interfaces/i_booking_controller.dart';
import '../controllers/interfaces/i_custom_exercise_controller.dart';
import '../controllers/interfaces/i_exercise_controller.dart';
import '../controllers/interfaces/i_note_controller.dart';
import '../controllers/interfaces/i_workout_controller.dart';
import '../controllers/interfaces/i_workout_execution_controller.dart';
import '../controllers/interfaces/i_statistics_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';
import '../controllers/custom_exercise_controller.dart';
import '../controllers/exercise_controller.dart';
import '../controllers/note_controller.dart';
import '../controllers/workout_controller.dart';
import '../controllers/workout_execution_controller.dart';
import '../controllers/statistics_controller.dart';

/// 全局服務定位器，用於依賴注入和服務管理
final GetIt serviceLocator = GetIt.instance;

/// 環境配置枚舉
enum Environment { development, testing, production }

/// 當前環境
Environment _currentEnvironment = Environment.development;

/// 設置當前環境
void setEnvironment(Environment env) {
  _currentEnvironment = env;
  
  // 根據環境配置不同的服務行為
  if (kDebugMode) {
    print('應用環境設置為: $_currentEnvironment');
  }
}

/// 初始化服務定位器
/// 
/// 使用懶加載模式（Lazy Singleton）註冊大部分服務，提高啟動性能
/// 只有在第一次請求時才會實例化服務
/// 
/// 返回 Future 以支持非同步初始化過程
Future<void> setupServiceLocator() async {
  try {
    // === 基礎服務（立即實例化） ===
    
    // 註冊錯誤處理服務（單例）- 由於被頻繁使用，采用立即實例化
    if (!serviceLocator.isRegistered<ErrorHandlingService>()) {
      serviceLocator.registerSingleton<ErrorHandlingService>(ErrorHandlingService());
    }
    
    // 初始化緩存服務
    ExerciseCacheService.init();

    // === 服務層（懶加載單例） ===
    _registerServices();
    
    // === 控制器層（工廠模式） ===
    _registerControllers();
    
    // 初始化必要的服務
    await _initializeCriticalServices();
    
    if (kDebugMode) {
      print('服務定位器初始化完成');
    }
  } catch (e) {
    if (kDebugMode) {
      print('服務定位器初始化失敗: $e');
    }
    rethrow;
  }
}

/// 註冊所有服務
void _registerServices() {
  // 身份驗證服務
  if (!serviceLocator.isRegistered<IAuthService>()) {
    serviceLocator.registerLazySingleton<IAuthService>(() => AuthWrapper());
  }
  
  // 預約服務
  if (!serviceLocator.isRegistered<IBookingService>()) {
    // 改回懶加載方式，但在註冊後添加一個初始化程序
    serviceLocator.registerLazySingleton<IBookingService>(() {
      final bookingService = BookingService(
        errorService: serviceLocator<ErrorHandlingService>(),
      );
      // 不要在這裡同步初始化，將在關鍵服務初始化列表中異步初始化
      return bookingService;
    });
  }
  
  // 自定義運動服務
  if (!serviceLocator.isRegistered<ICustomExerciseService>()) {
    serviceLocator.registerLazySingleton<ICustomExerciseService>(() => CustomExerciseService());
  }
  
  // 運動項目服務
  if (!serviceLocator.isRegistered<IExerciseService>()) {
    serviceLocator.registerLazySingleton<IExerciseService>(() => ExerciseService());
  }
  
  // 筆記服務
  if (!serviceLocator.isRegistered<INoteService>()) {
    serviceLocator.registerLazySingleton<INoteService>(() => NoteService(
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }
  
  // 用戶服務
  if (!serviceLocator.isRegistered<IUserService>()) {
    serviceLocator.registerLazySingleton<IUserService>(() => UserService(
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }
  
  // 用戶遷移服務
  if (!serviceLocator.isRegistered<UserMigrationService>()) {
    serviceLocator.registerLazySingleton<UserMigrationService>(() => UserMigrationService(
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }
  
  // 訓練計畫服務
  if (!serviceLocator.isRegistered<IWorkoutService>()) {
    serviceLocator.registerLazySingleton<IWorkoutService>(() => WorkoutService(
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }
  
  // 統計服務
  if (!serviceLocator.isRegistered<IStatisticsService>()) {
    serviceLocator.registerLazySingleton<IStatisticsService>(() => StatisticsService(
      firestore: FirebaseFirestore.instance,
      errorService: serviceLocator<ErrorHandlingService>(),
      exerciseService: serviceLocator<IExerciseService>(),
    ));
  }
  
  // 收藏服務
  if (!serviceLocator.isRegistered<IFavoritesService>()) {
    serviceLocator.registerLazySingleton<IFavoritesService>(() => FavoritesService(
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }
  
  // 默認模板服務
  if (!serviceLocator.isRegistered<DefaultTemplatesService>()) {
    serviceLocator.registerLazySingleton<DefaultTemplatesService>(() => DefaultTemplatesService());
  }
}

/// 註冊所有控制器
void _registerControllers() {
  // 身份驗證控制器
  if (!serviceLocator.isRegistered<IAuthController>()) {
    serviceLocator.registerFactory<IAuthController>(() => AuthController(
      authService: serviceLocator<IAuthService>(),
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }
  
  // 預約控制器
  if (!serviceLocator.isRegistered<IBookingController>()) {
    serviceLocator.registerFactory<IBookingController>(() => BookingController(
      bookingService: serviceLocator<IBookingService>(),
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }
  
  // 自定義運動控制器
  if (!serviceLocator.isRegistered<ICustomExerciseController>()) {
    serviceLocator.registerFactory<ICustomExerciseController>(() => CustomExerciseController(
      service: serviceLocator<ICustomExerciseService>(),
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }
  
  // 運動項目控制器
  if (!serviceLocator.isRegistered<IExerciseController>()) {
    serviceLocator.registerFactory<IExerciseController>(() => ExerciseController(
      service: serviceLocator<IExerciseService>(),
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }
  
  // 筆記控制器
  if (!serviceLocator.isRegistered<INoteController>()) {
    serviceLocator.registerFactory<INoteController>(() => NoteController(
      noteService: serviceLocator<INoteService>(),
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }
  
  // 訓練計畫控制器
  if (!serviceLocator.isRegistered<IWorkoutController>()) {
    serviceLocator.registerFactory<IWorkoutController>(() => WorkoutController(
      workoutService: serviceLocator<IWorkoutService>(),
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }

  // 注册工作执行控制器
  if (!serviceLocator.isRegistered<IWorkoutExecutionController>()) {
    serviceLocator.registerFactory<IWorkoutExecutionController>(() => WorkoutExecutionController());
  }

  // 統計控制器
  if (!serviceLocator.isRegistered<IStatisticsController>()) {
    serviceLocator.registerFactory<IStatisticsController>(() => StatisticsController(
      statisticsService: serviceLocator<IStatisticsService>(),
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }
}

/// 初始化關鍵服務
Future<void> _initializeCriticalServices() async {
  // 初始化預約服務
  try {
    if (serviceLocator.isRegistered<IBookingService>()) {
      final bookingService = serviceLocator<IBookingService>();
      if (!bookingService.isInitialized) {
        if (kDebugMode) {
          print('初始化關鍵服務: 預約服務');
        }
        // 添加超時控制，避免卡住
        await bookingService.initialize().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) {
              print('預約服務初始化超時，將在後台繼續初始化');
            }
            // 在後台繼續嘗試初始化
            Future.microtask(() => bookingService.initialize());
          },
        );
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('初始化預約服務失敗: $e');
    }
    // 記錄錯誤但不拋出
    serviceLocator<ErrorHandlingService>().logError('初始化預約服務失敗: $e');
  }

  // 預加載常用數據 - 僅在生產和開發環境執行
  if (_currentEnvironment != Environment.testing) {
    try {
      // 添加超時控制，避免卡住
      await PreloadService.preloadCommonData().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            print('預加載數據超時，將在後台繼續加載');
          }
          // 在後台繼續加載
          Future.microtask(() => PreloadService.preloadCommonData());
        },
      );
    } catch (e) {
      // 預加載失敗不應阻止應用啟動
      if (kDebugMode) {
        print('預加載數據失敗: $e');
      }
      // 記錄錯誤但不拋出
      serviceLocator<ErrorHandlingService>().logError('預加載數據失敗: $e');
    }
  }
}

/// 重置服務定位器（用於測試）
Future<void> resetServiceLocator() async {
  try {
    // 在重置前清理資源
    await _cleanupServices();
    
    // 重置所有注冊的服務
    serviceLocator.reset();
    
    if (kDebugMode) {
      print('服務定位器已重置');
    }
  } catch (e) {
    if (kDebugMode) {
      print('重置服務定位器時出錯: $e');
    }
  }
}

/// 清理服務資源
Future<void> _cleanupServices() async {
  try {
    // 在這裡添加需要特殊清理的服務
    // 例如關閉數據庫連接、取消訂閱等
    if (serviceLocator.isRegistered<IExerciseService>()) {
      await ExerciseCacheService.clearCache();
    }
  } catch (e) {
    if (kDebugMode) {
      print('清理服務資源時出錯: $e');
    }
  }
} 