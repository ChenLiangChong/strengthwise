import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'service_locator.dart' show Environment;

/// 錯誤處理服務：提供統一的錯誤處理策略
/// 
/// 這個服務負責處理應用程序中的各種錯誤，
/// 統一錯誤日誌記錄，展示用戶友好的錯誤信息，
/// 以及可能的錯誤恢復機制。
class ErrorHandlingService {
  // 單例模式實現
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  
  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;
  
  // 錯誤處理配置
  bool _showDebugErrors = true;
  bool _collectAnalytics = true;
  Duration _snackBarDuration = const Duration(seconds: 4);
  int _maxLogRetention = 100;
  
  // 錯誤日誌存儲
  final List<ErrorLog> _errorLogs = [];
  
  // 錯誤類型計數器
  final Map<String, int> _errorTypeCounter = {};
  
  // 回調函數集合
  final Set<Function(ErrorLog)> _errorCallbacks = {};
  
  /// 私有構造函數，用於實現單例模式
  ErrorHandlingService._internal();
  
  /// 工廠構造函數
  factory ErrorHandlingService() {
    return _instance;
  }
  
  /// 初始化服務
  /// 
  /// 設置環境配置並初始化錯誤處理邏輯
  Future<void> initialize({Environment environment = Environment.development}) async {
    if (_isInitialized) return;
    
    try {
      // 設置環境
      configureForEnvironment(environment);
      
      // 其他初始化操作
      _setupErrorCapture();
      
      _isInitialized = true;
      _logDebug('錯誤處理服務初始化完成');
    } catch (e) {
      // 特殊處理，因為錯誤處理服務本身出錯
      if (kDebugMode) {
        print('[ERROR HANDLER INIT FAILURE] $e');
      }
    }
  }
  
  /// 釋放資源
  Future<void> dispose() async {
    try {
      // 清理錯誤日誌
      _errorLogs.clear();
      _errorTypeCounter.clear();
      _errorCallbacks.clear();
      
      _isInitialized = false;
      if (kDebugMode) {
        print('[ERROR HANDLER] 錯誤處理服務資源已釋放');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ERROR HANDLER] 釋放錯誤處理服務資源時發生錯誤: $e');
      }
    }
  }
  
  /// 根據環境配置服務
  void configureForEnvironment(Environment environment) {
    _environment = environment;
    
    switch (environment) {
      case Environment.development:
        // 開發環境設置
        _showDebugErrors = true;
        _collectAnalytics = false;
        _snackBarDuration = const Duration(seconds: 5);
        _maxLogRetention = 200;
        _logDebug('錯誤處理服務配置為開發環境');
        break;
      case Environment.testing:
        // 測試環境設置
        _showDebugErrors = true;
        _collectAnalytics = true;
        _snackBarDuration = const Duration(seconds: 3);
        _maxLogRetention = 100;
        _logDebug('錯誤處理服務配置為測試環境');
        break;
      case Environment.production:
        // 生產環境設置
        _showDebugErrors = false;
        _collectAnalytics = true;
        _snackBarDuration = const Duration(seconds: 3);
        _maxLogRetention = 50;
        _logDebug('錯誤處理服務配置為生產環境');
        break;
    }
  }
  
  /// 設置全局錯誤捕獲
  void _setupErrorCapture() {
    // 捕獲Flutter框架異常
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };
    
    // 捕獲異步錯誤
    PlatformDispatcher.instance.onError = (error, stack) {
      _handleAsyncError(error, stack);
      return true;
    };
  }
  
  /// 處理Flutter框架錯誤
  void _handleFlutterError(FlutterErrorDetails details) {
    final dynamic exception = details.exception;
    final StackTrace? stackTrace = details.stack;
    
    final errorLog = ErrorLog(
      timestamp: DateTime.now(),
      message: exception.toString(),
      stackTrace: stackTrace,
      type: 'FlutterError',
      source: details.library ?? 'framework',
    );
    
    _processErrorLog(errorLog);
    
    // 根據環境決定是否將錯誤傳遞給Flutter
    if (_environment == Environment.development) {
      FlutterError.dumpErrorToConsole(details);
    }
  }
  
  /// 處理異步錯誤
  void _handleAsyncError(Object error, StackTrace stack) {
    final errorLog = ErrorLog(
      timestamp: DateTime.now(),
      message: error.toString(),
      stackTrace: stack,
      type: 'AsyncError',
      source: 'async',
    );
    
    _processErrorLog(errorLog);
  }
  
  /// 處理錯誤日誌
  void _processErrorLog(ErrorLog log) {
    // 添加到日誌列表
    _errorLogs.add(log);
    
    // 控制日誌大小
    if (_errorLogs.length > _maxLogRetention) {
      _errorLogs.removeAt(0);
    }
    
    // 更新類型計數器
    _errorTypeCounter[log.type] = (_errorTypeCounter[log.type] ?? 0) + 1;
    
    // 打印到控制台（僅開發模式）
    if (kDebugMode) {
      print('[ERROR ${log.type}] ${log.timestamp}: ${log.message}');
      if (log.stackTrace != null) {
        print(log.stackTrace);
      }
    }
    
    // 調用所有注冊的回調
    for (final callback in _errorCallbacks) {
      try {
        callback(log);
      } catch (e) {
        if (kDebugMode) {
          print('[ERROR HANDLER] 錯誤回調執行失敗: $e');
        }
      }
    }
  }
  
  /// 添加錯誤處理回調
  void addErrorCallback(Function(ErrorLog) callback) {
    _errorCallbacks.add(callback);
  }
  
  /// 移除錯誤處理回調
  void removeErrorCallback(Function(ErrorLog) callback) {
    _errorCallbacks.remove(callback);
  }
  
  /// 獲取錯誤日誌
  List<ErrorLog> getErrorLogs() {
    return List.unmodifiable(_errorLogs);
  }
  
  /// 清除所有錯誤日誌
  void clearErrorLogs() {
    _errorLogs.clear();
    _errorTypeCounter.clear();
  }
  
  /// 記錄錯誤到日誌系統
  void logError(String message, {StackTrace? stackTrace, String type = 'General', String source = 'app'}) {
    _ensureInitialized();
    
    final errorLog = ErrorLog(
      timestamp: DateTime.now(),
      message: message,
      stackTrace: stackTrace,
      type: type,
      source: source,
    );
    
    _processErrorLog(errorLog);
  }
  
  /// 記錄信息到日誌系統
  void logInfo(String message, {String source = 'app'}) {
    _ensureInitialized();
    
    if (kDebugMode) {
      print('[INFO $source] $message');
    }
  }
  
  /// 處理一般錯誤並顯示提示
  void handleError(BuildContext context, dynamic error, {String? customMessage, String? type, bool showSnackBar = true}) {
    _ensureInitialized();
    
    // 記錄錯誤
    logError(
      error.toString(),
      stackTrace: error is Error ? error.stackTrace : null,
      type: type ?? 'General',
    );
    
    // 向用戶顯示錯誤提示
    if (showSnackBar && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(customMessage ?? '操作執行失敗: ${_getUserFriendlyMessage(error)}'),
          backgroundColor: Colors.red[700],
          duration: _snackBarDuration,
        ),
      );
    }
  }
  
  /// 處理載入數據時的錯誤
  void handleLoadingError(BuildContext context, dynamic error, {String? customMessage}) {
    _ensureInitialized();
    
    logError(
      '載入數據錯誤: $error',
      stackTrace: error is Error ? error.stackTrace : null,
      type: 'LoadingError',
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(customMessage ?? '載入數據失敗: ${_getUserFriendlyMessage(error)}'),
          backgroundColor: Colors.orange[700],
          duration: _snackBarDuration,
        ),
      );
    }
  }
  
  /// 處理數據保存時的錯誤
  void handleSavingError(BuildContext context, dynamic error, {String? customMessage, VoidCallback? onRetry}) {
    _ensureInitialized();
    
    logError(
      '保存數據錯誤: $error',
      stackTrace: error is Error ? error.stackTrace : null,
      type: 'SavingError',
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(customMessage ?? '保存數據失敗: ${_getUserFriendlyMessage(error)}'),
          backgroundColor: Colors.red[700],
          duration: _snackBarDuration,
          action: onRetry != null ? SnackBarAction(
            label: '重試',
            textColor: Colors.white,
            onPressed: onRetry,
          ) : null,
        ),
      );
    }
  }
  
  /// 將技術錯誤轉換為用戶友好的消息
  String _getUserFriendlyMessage(dynamic error) {
    String errorStr = error.toString().toLowerCase();
    
    // 網絡相關錯誤
    if (error is SocketException || errorStr.contains('socket') || errorStr.contains('network') || 
        errorStr.contains('connection') || errorStr.contains('internet')) {
      return '網絡連接問題，請檢查您的網絡連接';
    }
    
    // 超時錯誤
    if (error is TimeoutException || errorStr.contains('timeout')) {
      return '操作超時，請稍後再試';
    }
    
    // Firebase相關錯誤
    if (errorStr.contains('firebase') || errorStr.contains('firestore')) {
      if (errorStr.contains('permission-denied')) {
        return '您沒有執行此操作的權限';
      } else if (errorStr.contains('not-found')) {
        return '找不到請求的數據';
      } else if (errorStr.contains('already-exists')) {
        return '該數據已存在';
      } else if (errorStr.contains('unauthenticated')) {
        return '您需要登入後才能執行此操作';
      } else {
        return '資料庫操作失敗，請稍後再試';
      }
    }
    
    // 身份驗證錯誤
    if (errorStr.contains('auth') || errorStr.contains('login') || errorStr.contains('sign in')) {
      if (errorStr.contains('password') || errorStr.contains('credential')) {
        return '用戶名或密碼錯誤';
      } else if (errorStr.contains('email') && errorStr.contains('exist')) {
        return '該電子郵件地址未註冊';
      } else {
        return '登入失敗，請檢查您的憑證';
      }
    }
    
    // 未知錯誤或其他類型錯誤
    return '發生了未知錯誤，請稍後再試';
  }
  
  /// 確保服務已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('[ERROR HANDLER] 警告: 錯誤處理服務在初始化前被調用');
      }
      
      // 錯誤處理服務是基礎服務，總是自動初始化
      initialize(environment: _environment);
    }
  }
  
  /// 記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[ERROR HANDLER] $message');
    }
  }
}

/// 錯誤日誌類，用於存儲錯誤信息
class ErrorLog {
  final DateTime timestamp;
  final String message;
  final StackTrace? stackTrace;
  final String type;
  final String source;
  
  ErrorLog({
    required this.timestamp,
    required this.message,
    this.stackTrace,
    required this.type,
    required this.source,
  });
} 