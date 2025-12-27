import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../interfaces/i_auth_service.dart';
import '../interfaces/i_booking_service.dart';
import '../interfaces/i_exercise_service.dart';
import '../supabase/auth_service_supabase.dart';
import '../supabase/exercise_service_supabase.dart';
import '../core/error_handling_service.dart';

import 'environment_config.dart';

/// 服務初始化器
///
/// 負責初始化關鍵服務（異步操作）
class ServiceInitializer {
  /// 初始化關鍵服務
  static Future<void> initializeCriticalServices(GetIt serviceLocator) async {
    // ⚡ 優化：並行初始化（串行 → 並行，減少總時間）
    await Future.wait([
      _initializeAuthService(serviceLocator),
      _initializeBookingService(serviceLocator),
      _initializeExerciseService(serviceLocator),
    ], eagerError: false); // 即使某個失敗，其他繼續

    if (kDebugMode) {
      print('服務定位器設置完成 - Supabase 模式');
    }
  }

  /// 初始化認證服務（AuthService）
  static Future<void> _initializeAuthService(GetIt serviceLocator) async {
    try {
      if (kDebugMode) {
        print('初始化認證服務...');
      }

      final authService = serviceLocator<IAuthService>();
      if (authService is AuthServiceSupabase) {
        await authService.initialize(
          environment: EnvironmentConfig.current,
        );

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
  }

  /// 初始化預約服務
  static Future<void> _initializeBookingService(GetIt serviceLocator) async {
    try {
      if (serviceLocator.isRegistered<IBookingService>()) {
        final bookingService = serviceLocator<IBookingService>();
        if (!bookingService.isInitialized) {
          if (kDebugMode) {
            print('初始化關鍵服務: 預約服務');
          }

          // ⚡ 優化：完全異步，不等待（避免卡頓）
          // 預約服務初始化移到背景執行，不阻塞主線程
          unawaited(bookingService.initialize().then((_) {
            if (kDebugMode) {
              print('預約服務背景初始化完成');
            }
          }).catchError((e) {
            if (kDebugMode) {
              print('預約服務背景初始化失敗: $e');
            }
            serviceLocator<ErrorHandlingService>().logError('預約服務背景初始化失敗: $e');
          }));
          
          if (kDebugMode) {
            print('預約服務已啟動背景初始化（不阻塞 UI）');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('啟動預約服務初始化失敗: $e');
      }
      serviceLocator<ErrorHandlingService>().logError('啟動預約服務初始化失敗: $e');
    }
  }

  /// 初始化運動服務（ExerciseService）
  static Future<void> _initializeExerciseService(GetIt serviceLocator) async {
    try {
      if (kDebugMode) {
        print('初始化運動服務...');
      }

      final exerciseService = serviceLocator<IExerciseService>();
      if (exerciseService is ExerciseServiceSupabase) {
        await exerciseService.initialize(
          environment: EnvironmentConfig.current,
        );

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
  }

  /// 清理服務資源
  static Future<void> cleanupServices() async {
    try {
      // 在這裡添加需要特殊清理的服務
      // 例如關閉數據庫連接、取消訂閱等
    } catch (e) {
      if (kDebugMode) {
        print('清理服務資源時出錯: $e');
      }
    }
  }
}
