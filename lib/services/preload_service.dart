import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'error_handling_service.dart';
import 'interfaces/i_exercise_service.dart';
import 'exercise_cache_service.dart';
import 'service_locator.dart' show Environment, serviceLocator;

/// 預加載服務：負責在應用啟動時高效地預加載常用數據
/// 
/// 特性：
/// 1. 支持基於用戶習慣的智能預加載
/// 2. 可配置的預加載範圍和優先級
/// 3. 提供實時進度報告
/// 4. 內建錯誤恢復機制
class PreloadService {
  // 服務依賴
  static late FirebaseFirestore _firestore;
  static late ErrorHandlingService _errorService;
  static IExerciseService? _exerciseService;
  
  // 服務狀態
  static bool _isInitialized = false;
  static Environment _environment = Environment.development;
  
  // 預加載配置
  static bool _preloadEnabled = true;
  static bool _useUserHistory = true;
  static int _maxConcurrentPreloads = 3;
  static int _maxItemsPerCategory = 20;
  static int _retryAttempts = 2;
  static Duration _retryDelay = const Duration(seconds: 1);
  
  // 進度追蹤
  static final StreamController<PreloadProgress> _progressController = 
      StreamController<PreloadProgress>.broadcast();
  static int _totalTasks = 0;
  static int _completedTasks = 0;
  static bool _isPreloading = false;
  static Set<String> _failedTasks = {};
  
  // 用戶使用習慣追蹤
  static Map<String, int> _exerciseTypeUsageCount = {};
  static Map<String, int> _bodyPartUsageCount = {};
  static DateTime? _lastPreloadTime;
  
  /// 初始化服務
  static Future<void> initialize({
    FirebaseFirestore? firestore,
    ErrorHandlingService? errorService,
    IExerciseService? exerciseService,
    Environment environment = Environment.development,
  }) async {
    if (_isInitialized) return;
    
    try {
      _firestore = firestore ?? FirebaseFirestore.instance;
      _errorService = errorService ?? ErrorHandlingService();
      _exerciseService = exerciseService ?? serviceLocator<IExerciseService>();
      
      // 配置環境
      configureForEnvironment(environment);
      
      // 加載用戶使用習慣數據
      await _loadUserPreferences();
      
      _isInitialized = true;
      _logDebug('預加載服務初始化完成');
    } catch (e) {
      _logError('預加載服務初始化失敗: $e');
    }
  }
  
  /// 釋放資源
  static Future<void> dispose() async {
    try {
      await _progressController.close();
      _isInitialized = false;
      _logDebug('預加載服務資源已釋放');
    } catch (e) {
      _logError('釋放預加載服務資源時發生錯誤: $e');
    }
  }
  
  /// 根據環境配置服務
  static void configureForEnvironment(Environment environment) {
    _environment = environment;
    
    switch (environment) {
      case Environment.development:
        // 開發環境設置
        _preloadEnabled = true;
        _useUserHistory = true;
        _maxConcurrentPreloads = 2;
        _maxItemsPerCategory = 30;
        _retryAttempts = 3;
        _retryDelay = const Duration(seconds: 2);
        _logDebug('預加載服務配置為開發環境');
        break;
      case Environment.testing:
        // 測試環境設置
        _preloadEnabled = false; // 測試時禁用預加載，避免干擾測試結果
        _useUserHistory = false;
        _maxConcurrentPreloads = 1;
        _maxItemsPerCategory = 10;
        _retryAttempts = 1;
        _retryDelay = const Duration(milliseconds: 500);
        _logDebug('預加載服務配置為測試環境');
        break;
      case Environment.production:
        // 生產環境設置
        _preloadEnabled = true;
        _useUserHistory = true;
        _maxConcurrentPreloads = 3;
        _maxItemsPerCategory = 20;
        _retryAttempts = 2;
        _retryDelay = const Duration(seconds: 1);
        _logDebug('預加載服務配置為生產環境');
        break;
    }
  }
  
  /// 獲取預加載進度流
  static Stream<PreloadProgress> get preloadProgress => _progressController.stream;
  
  /// 預加載常用數據
  static Future<void> preloadCommonData({
    bool forcePreload = false,
    List<String>? specificCategories,
    bool showProgress = true,
  }) async {
    _ensureInitialized();
    
    if (!_preloadEnabled && !forcePreload) {
      _logDebug('預加載已被禁用，跳過操作');
      return;
    }
    
    if (_isPreloading) {
      _logDebug('預加載操作已在進行中，跳過重複調用');
      return;
    }
    
    try {
      _isPreloading = true;
      _failedTasks.clear();
      
      // 檢查上次預加載時間，避免頻繁預加載
      if (!forcePreload && _lastPreloadTime != null) {
        final now = DateTime.now();
        final hoursSinceLastPreload = now.difference(_lastPreloadTime!).inHours;
        
        if (hoursSinceLastPreload < 12) {
          _logDebug('距離上次預加載不足12小時，跳過操作');
          _isPreloading = false;
          return;
        }
      }
      
      // 初始化進度追蹤
      _totalTasks = 0;
      _completedTasks = 0;
      
      // 預加載任務列表
      final preloadTasks = <Future<void> Function()>[];
      
      // 添加預加載運動類型任務
      if (specificCategories == null || specificCategories.contains('exerciseTypes')) {
        preloadTasks.add(_preloadExerciseTypes);
      }
      
      // 添加預加載身體部位任務
      if (specificCategories == null || specificCategories.contains('bodyParts')) {
        preloadTasks.add(_preloadBodyParts);
      }
      
      // 添加預加載常用運動數據任務
      if (specificCategories == null || specificCategories.contains('exercises')) {
        preloadTasks.add(_preloadExercises);
      }
      
      // 更新總任務數
      _totalTasks = preloadTasks.length;
      
      // 報告初始進度
      if (showProgress) {
        _updateProgress('初始化預加載', 0);
      }
      
      // 執行預加載任務
      await Future.wait(preloadTasks.map((task) async {
        try {
          await task();
          _completedTasks++;
          
          if (showProgress) {
            final progress = _completedTasks / _totalTasks;
            _updateProgress('預加載進行中', progress);
          }
        } catch (e) {
          _logError('預加載任務失敗: $e');
          _failedTasks.add(task.toString());
        }
      }));
      
      // 更新上次預加載時間
      _lastPreloadTime = DateTime.now();
      await _saveUserPreferences();
      
      // 報告最終進度
      if (showProgress) {
        _updateProgress(
          _failedTasks.isEmpty ? '預加載完成' : '預加載部分完成，有${_failedTasks.length}個任務失敗',
          1.0
        );
      }
      
      _logDebug('預加載完成，成功率: ${(_totalTasks - _failedTasks.length) / _totalTasks * 100}%');
    } catch (e) {
      _logError('預加載過程中發生錯誤: $e');
      
      if (showProgress) {
        _updateProgress('預加載失敗: $e', 0);
      }
    } finally {
      _isPreloading = false;
    }
  }
  
  /// 預加載運動類型
  static Future<void> _preloadExerciseTypes() async {
    _logDebug('預加載運動類型開始');
    
    try {
      // 直接從Firestore獲取並利用內建緩存
      final typesSnapshot = await _retryOperation(
        () => _firestore.collection('exerciseTypes').get()
      );
      
      // 解析數據
      final types = typesSnapshot.docs.map((doc) => doc['name'] as String).toList();
      
      // 使用ExerciseCacheService緩存數據
      await ExerciseCacheService.cacheCategories('exerciseTypes', types);
      
      _logDebug('預加載運動類型成功: ${types.length} 個類型');
    } catch (e) {
      _logError('預加載運動類型失敗: $e');
      rethrow;
    }
  }
  
  /// 預加載身體部位
  static Future<void> _preloadBodyParts() async {
    _logDebug('預加載身體部位開始');
    
    try {
      // 直接從Firestore獲取並利用內建緩存
      final partsSnapshot = await _retryOperation(
        () => _firestore.collection('bodyParts').get()
      );
      
      // 解析數據
      final parts = partsSnapshot.docs.map((doc) => doc['name'] as String).toList();
      
      // 使用ExerciseCacheService緩存數據
      await ExerciseCacheService.cacheCategories('bodyParts', parts);
      
      _logDebug('預加載身體部位成功: ${parts.length} 個部位');
    } catch (e) {
      _logError('預加載身體部位失敗: $e');
      rethrow;
    }
  }
  
  /// 預加載常用運動數據
  static Future<void> _preloadExercises() async {
    _logDebug('預加載常用運動數據開始');
    
    try {
      // 獲取運動類型列表
      List<String> types = [];
      
      // 如果有緩存，優先使用緩存
      if (_exerciseService != null) {
        try {
          types = await _exerciseService!.getExerciseTypes();
        } catch (e) {
          _logError('從服務獲取運動類型失敗，將直接查詢: $e');
        }
      }
      
      // 如果服務調用失敗，直接查詢
      if (types.isEmpty) {
        final typesSnapshot = await _firestore.collection('exerciseTypes').get();
        types = typesSnapshot.docs.map((doc) => doc['name'] as String).toList();
      }
      
      // 根據用戶習慣排序
      if (_useUserHistory && _exerciseTypeUsageCount.isNotEmpty) {
        types.sort((a, b) {
          final countA = _exerciseTypeUsageCount[a] ?? 0;
          final countB = _exerciseTypeUsageCount[b] ?? 0;
          return countB.compareTo(countA); // 降序排列，使用頻率高的在前
        });
      }
      
      // 限制預加載的類型數量
      final typesToPreload = types.take(_maxConcurrentPreloads).toList();
      
      // 批量預加載
      await Future.wait(typesToPreload.map((type) async {
        try {
          final exerciseSnapshot = await _retryOperation(
            () => _firestore
                .collection('exercise')
                .where('type', isEqualTo: type)
                .limit(_maxItemsPerCategory)
                .get()
          );
          
          _logDebug('已預加載類型 "$type" 的 ${exerciseSnapshot.docs.length} 個運動');
        } catch (e) {
          _logError('預加載 "$type" 類型的運動數據失敗: $e');
        }
      }));
      
      _logDebug('預加載常用運動數據完成');
    } catch (e) {
      _logError('預加載常用運動數據失敗: $e');
      rethrow;
    }
  }
  
  /// 記錄運動類型使用情況
  static Future<void> trackExerciseTypeUsage(String type) async {
    if (!_preloadEnabled || !_useUserHistory) return;
    
    try {
      _exerciseTypeUsageCount[type] = (_exerciseTypeUsageCount[type] ?? 0) + 1;
      await _saveUserPreferences();
      _logDebug('已記錄運動類型使用: $type, 次數: ${_exerciseTypeUsageCount[type]}');
    } catch (e) {
      _logError('記錄運動類型使用失敗: $e');
    }
  }
  
  /// 記錄身體部位使用情況
  static Future<void> trackBodyPartUsage(String bodyPart) async {
    if (!_preloadEnabled || !_useUserHistory) return;
    
    try {
      _bodyPartUsageCount[bodyPart] = (_bodyPartUsageCount[bodyPart] ?? 0) + 1;
      await _saveUserPreferences();
      _logDebug('已記錄身體部位使用: $bodyPart, 次數: ${_bodyPartUsageCount[bodyPart]}');
    } catch (e) {
      _logError('記錄身體部位使用失敗: $e');
    }
  }
  
  /// 帶有重試機制的操作執行器
  static Future<T> _retryOperation<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (attempts > _retryAttempts) {
          _logError('操作重試 $attempts 次後仍然失敗: $e');
          rethrow;
        }
        
        _logDebug('操作失敗，正在重試 ($attempts/$_retryAttempts): $e');
        await Future.delayed(_retryDelay);
      }
    }
  }
  
  /// 更新預加載進度
  static void _updateProgress(String message, double progress) {
    _progressController.add(PreloadProgress(
      message: message,
      progress: progress,
      totalTasks: _totalTasks,
      completedTasks: _completedTasks,
      failedTasks: _failedTasks.length,
    ));
  }
  
  /// 加載用戶使用偏好
  static Future<void> _loadUserPreferences() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        _logDebug('未登入用戶，跳過加載用戶偏好');
        return;
      }
      
      final userId = currentUser.uid;
      final prefs = await SharedPreferences.getInstance();
      
      // 加載運動類型使用記錄
      final typeUsageJson = prefs.getString('exercise_type_usage_$userId');
      if (typeUsageJson != null) {
        _exerciseTypeUsageCount = Map<String, int>.from(
          Map<String, dynamic>.from(
            jsonDecode(typeUsageJson)
          ).map((key, value) => MapEntry(key, value as int))
        );
      }
      
      // 加載身體部位使用記錄
      final bodyPartUsageJson = prefs.getString('body_part_usage_$userId');
      if (bodyPartUsageJson != null) {
        _bodyPartUsageCount = Map<String, int>.from(
          Map<String, dynamic>.from(
            jsonDecode(bodyPartUsageJson)
          ).map((key, value) => MapEntry(key, value as int))
        );
      }
      
      // 加載上次預加載時間
      final lastPreloadTimeMillis = prefs.getInt('last_preload_time_$userId');
      if (lastPreloadTimeMillis != null) {
        _lastPreloadTime = DateTime.fromMillisecondsSinceEpoch(lastPreloadTimeMillis);
      }
      
      _logDebug('成功加載用戶偏好設置');
    } catch (e) {
      _logError('加載用戶偏好設置失敗: $e');
    }
  }
  
  /// 保存用戶使用偏好
  static Future<void> _saveUserPreferences() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        _logDebug('未登入用戶，跳過保存用戶偏好');
        return;
      }
      
      final userId = currentUser.uid;
      final prefs = await SharedPreferences.getInstance();
      
      // 保存運動類型使用記錄
      if (_exerciseTypeUsageCount.isNotEmpty) {
        await prefs.setString(
          'exercise_type_usage_$userId',
          jsonEncode(_exerciseTypeUsageCount)
        );
      }
      
      // 保存身體部位使用記錄
      if (_bodyPartUsageCount.isNotEmpty) {
        await prefs.setString(
          'body_part_usage_$userId',
          jsonEncode(_bodyPartUsageCount)
        );
      }
      
      // 保存上次預加載時間
      if (_lastPreloadTime != null) {
        await prefs.setInt(
          'last_preload_time_$userId',
          _lastPreloadTime!.millisecondsSinceEpoch
        );
      }
      
      _logDebug('成功保存用戶偏好設置');
    } catch (e) {
      _logError('保存用戶偏好設置失敗: $e');
    }
  }
  
  /// 確保服務已初始化
  static void _ensureInitialized() {
    if (!_isInitialized) {
      _logDebug('警告: 預加載服務在初始化前被調用');
      initialize();
    }
  }
  
  /// 記錄調試信息
  static void _logDebug(String message) {
    if (kDebugMode) {
      print('[PRELOAD] $message');
    }
  }
  
  /// 記錄錯誤信息
  static void _logError(String message) {
    if (kDebugMode) {
      print('[PRELOAD ERROR] $message');
    }
    
    try {
      _errorService.logError(message);
    } catch (e) {
      // 錯誤服務可能未初始化，忽略此錯誤
      if (kDebugMode) {
        print('[PRELOAD] 無法使用錯誤服務記錄: $e');
      }
    }
  }
}

/// 預加載進度報告類
class PreloadProgress {
  final String message;
  final double progress;
  final int totalTasks;
  final int completedTasks;
  final int failedTasks;
  
  PreloadProgress({
    required this.message,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.failedTasks,
  });
  
  bool get isComplete => progress >= 1.0;
  bool get isSuccessful => isComplete && failedTasks == 0;
} 