import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
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
import 'interfaces/i_body_data_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service_supabase.dart'; // Supabase Auth
import 'booking_service_supabase.dart'; // Supabase Booking Service
import 'custom_exercise_service_supabase.dart'; // Supabase 自訂動作服務
import 'exercise_service_supabase.dart'; // Supabase 運動服務
import 'note_service_supabase.dart'; // Supabase Note Service
import 'user_service_supabase.dart'; // Supabase User Service
import 'workout_service_supabase.dart'; // Supabase 訓練服務
import 'statistics_service_supabase.dart'; // Supabase Statistics Service
import 'favorites_service.dart';
import 'body_data_service_supabase.dart'; // Supabase 身體數據服務
import 'error_handling_service.dart';
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
import '../controllers/body_data_controller.dart';

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
  // 身份驗證服務（使用 Supabase 版本）⭐
  if (!serviceLocator.isRegistered<IAuthService>()) {
    serviceLocator.registerLazySingleton<IAuthService>(
      () => AuthServiceSupabase(
        errorService: serviceLocator<ErrorHandlingService>(),
      ),
    );
  }
  
  // 預約服務（使用 Supabase 版本）⭐
  if (!serviceLocator.isRegistered<IBookingService>()) {
    serviceLocator.registerLazySingleton<IBookingService>(() {
      final bookingService = BookingServiceSupabase(
        supabase: Supabase.instance.client,
        errorService: serviceLocator<ErrorHandlingService>(),
      );
      return bookingService;
    });
  }
  
  // 自定義運動服務（使用 Supabase 版本）⭐
  if (!serviceLocator.isRegistered<ICustomExerciseService>()) {
    serviceLocator.registerLazySingleton<ICustomExerciseService>(
      () => CustomExerciseServiceSupabase(
        errorService: serviceLocator<ErrorHandlingService>(),
      ),
    );
  }
  
  // 運動項目服務（使用 Supabase 版本）
  if (!serviceLocator.isRegistered<IExerciseService>()) {
    serviceLocator.registerLazySingleton<IExerciseService>(
      () => ExerciseServiceSupabase(
        errorService: serviceLocator<ErrorHandlingService>(),
      ),
    );
  }
  
  // 筆記服務（使用 Supabase 版本）⭐
  if (!serviceLocator.isRegistered<INoteService>()) {
    serviceLocator.registerLazySingleton<INoteService>(() => NoteServiceSupabase(
      supabase: Supabase.instance.client,
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }
  
  // 用戶服務（使用 Supabase 版本）⭐
  if (!serviceLocator.isRegistered<IUserService>()) {
    serviceLocator.registerLazySingleton<IUserService>(
      () => UserServiceSupabase(
        errorService: serviceLocator<ErrorHandlingService>(),
      ),
    );
  }
  
  // 訓練計畫服務（使用 Supabase 版本）⭐
  if (!serviceLocator.isRegistered<IWorkoutService>()) {
    serviceLocator.registerLazySingleton<IWorkoutService>(
      () => WorkoutServiceSupabase(
        errorService: serviceLocator<ErrorHandlingService>(),
      ),
    );
  }
  
  // 統計服務（使用 Supabase 版本）⭐
  if (!serviceLocator.isRegistered<IStatisticsService>()) {
    serviceLocator.registerLazySingleton<IStatisticsService>(() => StatisticsServiceSupabase(
      supabase: Supabase.instance.client,
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
  
  // 身體數據服務（使用 Supabase 版本）⭐
  if (!serviceLocator.isRegistered<IBodyDataService>()) {
    serviceLocator.registerLazySingleton<IBodyDataService>(
      () => BodyDataServiceSupabase(
        errorService: serviceLocator<ErrorHandlingService>(),
      ),
    );
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
  
  // 身體數據控制器
  if (!serviceLocator.isRegistered<BodyDataController>()) {
    serviceLocator.registerFactory<BodyDataController>(() => BodyDataController(
      bodyDataService: serviceLocator<IBodyDataService>(),
      userService: serviceLocator<IUserService>(),
      errorService: serviceLocator<ErrorHandlingService>(),
    ));
  }
}

/// 初始化關鍵服務
Future<void> _initializeCriticalServices() async {
  // === 初始化認證服務（AuthService）===
  try {
    if (kDebugMode) {
      print('初始化認證服務...');
    }
    
    final authService = serviceLocator<IAuthService>();
    if (authService is AuthServiceSupabase) {
      await authService.initialize(environment: _currentEnvironment);
      
      if (kDebugMode) {
        print('認證服務初始化完成');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('初始化認證服務失敗: $e');
    }
    // 記錄錯誤但不拋出
    serviceLocator<ErrorHandlingService>().logError('初始化認證服務失敗: $e');
  }

  // === 初始化預約服務 ===
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

  // === 初始化運動服務（ExerciseService）===
  try {
    if (kDebugMode) {
      print('初始化運動服務...');
    }
    
    final exerciseService = serviceLocator<IExerciseService>();
    if (exerciseService is ExerciseServiceSupabase) {
      await exerciseService.initialize(environment: _currentEnvironment);
      
      if (kDebugMode) {
        print('運動服務初始化完成');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('初始化運動服務失敗: $e');
    }
    // 記錄錯誤但不拋出
    serviceLocator<ErrorHandlingService>().logError('初始化運動服務失敗: $e');
  }

  // Supabase 的數據預加載通過各個 Service 的緩存機制實現
  if (kDebugMode) {
    print('服務定位器設置完成 - Supabase 模式');
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
  } catch (e) {
    if (kDebugMode) {
      print('清理服務資源時出錯: $e');
    }
  }
} 