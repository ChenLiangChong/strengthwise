import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'core/error_handling_service.dart';
import 'locator/environment_config.dart';
import 'locator/service_registry.dart';
import 'locator/controller_registry.dart';
import 'locator/service_initializer.dart';

// 向外導出環境配置枚舉，保持向後兼容
export 'locator/environment_config.dart' show Environment;

/// 全局服務定位器，用於依賴注入和服務管理
final GetIt serviceLocator = GetIt.instance;

/// 設置當前環境（向後兼容）
void setEnvironment(Environment env) {
  EnvironmentConfig.setEnvironment(env);
}

/// 初始化服務定位器
///
/// 使用懶加載模式（Lazy Singleton）註冊大部分服務，提高啟動性能
/// 只有在第一次請求時才會實例化服務
///
/// [lazyInit] 是否延遲初始化關鍵服務（true = 只註冊，false = 註冊+初始化）
/// 返回 Future 以支持非同步初始化過程
Future<void> setupServiceLocator({bool lazyInit = false}) async {
  try {
    // === 步驟 1：註冊基礎服務（立即實例化） ===
    _registerCoreServices();

    // === 步驟 2：註冊服務層（懶加載單例） ===
    ServiceRegistry.registerServices(serviceLocator);

    // === 步驟 3：註冊控制器層（工廠模式） ===
    ControllerRegistry.registerControllers(serviceLocator);

    // === 步驟 4：初始化關鍵服務（可選） ===
    if (!lazyInit) {
      await ServiceInitializer.initializeCriticalServices(serviceLocator);
    }

    if (kDebugMode) {
      print('服務定位器初始化完成${lazyInit ? '（延遲模式）' : ''}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('服務定位器初始化失敗: $e');
    }
    rethrow;
  }
}

/// 註冊核心基礎服務（立即實例化）
void _registerCoreServices() {
  // 註冊錯誤處理服務（單例）- 由於被頻繁使用，采用立即實例化
  if (!serviceLocator.isRegistered<ErrorHandlingService>()) {
    serviceLocator.registerSingleton<ErrorHandlingService>(
      ErrorHandlingService(),
    );
  }
}

/// 重置服務定位器（用於測試）
Future<void> resetServiceLocator() async {
  try {
    // 在重置前清理資源
    await ServiceInitializer.cleanupServices();

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
