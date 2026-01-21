import 'package:flutter/foundation.dart';

/// 環境配置枚舉
enum Environment { 
  development, 
  testing, 
  production 
}

/// 環境配置管理器
class EnvironmentConfig {
  /// 當前環境
  static Environment _currentEnvironment = Environment.development;

  /// 獲取當前環境
  static Environment get current => _currentEnvironment;

  /// 設置當前環境
  static void setEnvironment(Environment env) {
    _currentEnvironment = env;
    
    if (kDebugMode) {
      debugPrint('應用環境設置為: $_currentEnvironment');
    }
  }

  /// 是否為開發環境
  static bool get isDevelopment => _currentEnvironment == Environment.development;

  /// 是否為測試環境
  static bool get isTesting => _currentEnvironment == Environment.testing;

  /// 是否為生產環境
  static bool get isProduction => _currentEnvironment == Environment.production;
}

