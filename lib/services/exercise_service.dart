import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/exercise_model.dart';
import 'interfaces/i_exercise_service.dart';
import 'exercise_cache_service.dart';
import 'error_handling_service.dart';
import 'service_locator.dart' show Environment;

/// 運動服務的Firebase實現
/// 
/// 提供訓練動作查詢、分類過濾和詳情獲取等功能
/// 與緩存服務協同工作，支持環境配置和統一錯誤處理
class ExerciseService implements IExerciseService {
  // 依賴注入
  final FirebaseFirestore _firestore;
  final ErrorHandlingService? _errorService;
  
  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;
  
  // 服務配置
  bool _useCache = true;
  bool _preloadCommonData = true;
  int _queryTimeout = 15; // 秒
  
  // 載入狀態追蹤
  final Map<String, DateTime> _lastLoadTimes = {};
  
  /// 創建服務實例
  /// 
  /// 允許注入自定義的Firestore實例，便於測試
  ExerciseService({
    FirebaseFirestore? firestore,
    ErrorHandlingService? errorService,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _errorService = errorService;
  
  /// 初始化服務
  /// 
  /// 設置環境配置並初始化相關服務
  Future<void> initialize({Environment environment = Environment.development}) async {
    if (_isInitialized) return;
    
    try {
      // 設置環境
      configureForEnvironment(environment);
      
      // 確保緩存服務已初始化
      await ExerciseCacheService.init(
        environment: environment,
        errorService: _errorService,
      );
      
      // 如果配置了預加載，加載常用數據
      if (_preloadCommonData) {
        _preloadCommonExerciseData();
      }
      
      _isInitialized = true;
      _logDebug('運動服務初始化完成');
    } catch (e) {
      _logError('運動服務初始化失敗: $e');
      rethrow;
    }
  }
  
  /// 釋放資源
  Future<void> dispose() async {
    try {
      // 清理載入狀態追蹤
      _lastLoadTimes.clear();
      
      _isInitialized = false;
      _logDebug('運動服務資源已釋放');
    } catch (e) {
      _logError('釋放運動服務資源時發生錯誤: $e');
    }
  }
  
  /// 根據環境配置服務
  void configureForEnvironment(Environment environment) {
    _environment = environment;
    
    switch (environment) {
      case Environment.development:
        // 開發環境設置
        _useCache = true;
        _preloadCommonData = true;
        _queryTimeout = 20; // 更長的超時，便於調試
        _logDebug('運動服務配置為開發環境');
        break;
      case Environment.testing:
        // 測試環境設置
        _useCache = false;
        _preloadCommonData = false;
        _queryTimeout = 10;
        _logDebug('運動服務配置為測試環境');
        break;
      case Environment.production:
        // 生產環境設置
        _useCache = true;
        _preloadCommonData = true;
        _queryTimeout = 15;
        _logDebug('運動服務配置為生產環境');
        break;
    }
  }
  
  /// 預加載常用運動數據
  Future<void> _preloadCommonExerciseData() async {
    _logDebug('開始預加載常用運動數據');
    
    try {
      // 預加載運動類型
      unawaited(getExerciseTypes());
      
      // 預加載身體部位
      unawaited(getBodyParts());
      
      // 不等待完成，讓它們在後台加載
      _logDebug('常用運動數據預加載任務已啟動');
    } catch (e) {
      _logError('預加載常用運動數據失敗: $e');
    }
  }
  
  @override
  void logDebug(String message) {
    _logDebug(message);
  }
  
  @override
  Future<List<String>> getExerciseTypes() async {
    _ensureInitialized();
    
    _logDebug('開始載入訓練類型...');
    _lastLoadTimes['exerciseTypes'] = DateTime.now();
    
    try {
      // 首先嘗試從緩存獲取（如果啟用）
      if (_useCache) {
        try {
          final cachedTypes = await ExerciseCacheService.getCategories('exerciseTypes');
          if (cachedTypes.isNotEmpty) {
            _logDebug('成功從緩存載入 ${cachedTypes.length} 個訓練類型');
            return cachedTypes;
          }
        } catch (e) {
          _logDebug('從緩存獲取訓練類型失敗，將從服務器獲取: $e');
        }
      }
      
      // 從服務器獲取
      final querySnapshot = await _firestore
          .collection('exerciseTypes')
          .orderBy('name')
          .get(const GetOptions(source: Source.server))
          .timeout(Duration(seconds: _queryTimeout), 
                  onTimeout: () => throw TimeoutException('查詢訓練類型超時'));
      
      List<String> types = [];
      for (var doc in querySnapshot.docs) {
        types.add(doc['name'] as String);
      }
      
      _logDebug('成功從服務器載入 ${types.length} 個訓練類型');
      
      // 存入緩存（如果啟用）
      if (_useCache && types.isNotEmpty) {
        unawaited(ExerciseCacheService.cacheCategories('exerciseTypes', types));
      }
      
      return types;
    } catch (e) {
      _logError('載入訓練類型失敗: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<String>> getBodyParts() async {
    _ensureInitialized();
    
    _logDebug('開始載入身體部位');
    _lastLoadTimes['bodyParts'] = DateTime.now();
    
    try {
      // 首先嘗試從緩存獲取（如果啟用）
      if (_useCache) {
        try {
          final cachedParts = await ExerciseCacheService.getCategories('bodyParts');
          if (cachedParts.isNotEmpty) {
            _logDebug('成功從緩存載入 ${cachedParts.length} 個身體部位');
            return cachedParts;
          }
        } catch (e) {
          _logDebug('從緩存獲取身體部位失敗，將從服務器獲取: $e');
        }
      }
      
      // 從服務器獲取
      final querySnapshot = await _firestore
          .collection('bodyParts')
          .orderBy('name')
          .get(const GetOptions(source: Source.server))
          .timeout(Duration(seconds: _queryTimeout), 
                  onTimeout: () => throw TimeoutException('查詢身體部位超時'));
      
      List<String> parts = [];
      for (var doc in querySnapshot.docs) {
        parts.add(doc['name'] as String);
      }
      
      _logDebug('成功從服務器載入 ${parts.length} 個身體部位');
      
      // 存入緩存（如果啟用）
      if (_useCache && parts.isNotEmpty) {
        unawaited(ExerciseCacheService.cacheCategories('bodyParts', parts));
      }
      
      return parts;
    } catch (e) {
      _logError('載入身體部位失敗: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<String>> getCategoriesByLevel(int level, Map<String, String> filters) async {
    _ensureInitialized();
    
    _logDebug('開始載入Level$level分類');
    
    // 構建緩存鍵
    final selectedType = filters['type'] ?? "";
    final selectedBodyPart = filters['bodyPart'] ?? "";
    final selectedLevel1 = filters['level1'] ?? "";
    final selectedLevel2 = filters['level2'] ?? "";
    final selectedLevel3 = filters['level3'] ?? "";
    final selectedLevel4 = filters['level4'] ?? "";
    
    final cacheKey = 'level${level}_${selectedType}_${selectedBodyPart}_${selectedLevel1}_${selectedLevel2}_${selectedLevel3}_$selectedLevel4';
    _logDebug('緩存鍵: $cacheKey');
    _lastLoadTimes[cacheKey] = DateTime.now();
    
    // 清除該緩存鍵的舊資料（如果啟用緩存）
    if (_useCache) {
      await ExerciseCacheService.clearCacheForKey('cat_$cacheKey');
    }
    
    try {
      // 首先嘗試從緩存獲取（如果啟用）
      if (_useCache) {
        try {
          final cachedCategories = await ExerciseCacheService.getCategories(cacheKey);
          if (cachedCategories.isNotEmpty) {
            _logDebug('成功從緩存載入 Level$level 分類: ${cachedCategories.length} 個項目');
            return cachedCategories;
          }
        } catch (e) {
          _logDebug('從緩存獲取 Level$level 分類失敗，將從服務器獲取: $e');
        }
      }
      
      // 構建查詢
      Query query = _firestore.collection('exercise');
      
      // 驗證必要條件
      if (level == 1) {
        if (selectedType.isEmpty) {
          throw ArgumentError('查詢level1時必須指定訓練類型');
        }
        if (selectedBodyPart.isEmpty) {
          throw ArgumentError('查詢level1時必須指定身體部位');
        }
      }
      
      // 確保類型條件始終應用
      if (selectedType.isNotEmpty) {
        query = query.where('type', isEqualTo: selectedType);
        _logDebug('添加查詢條件: type=$selectedType');
      }
      
      // 確保身體部位條件始終應用
      if (selectedBodyPart.isNotEmpty) {
        query = query.where('bodyParts', arrayContains: selectedBodyPart);
        _logDebug('添加查詢條件: bodyParts包含$selectedBodyPart');
      }
      
      // 添加其他層級條件
      if (level >= 2 && selectedLevel1.isNotEmpty) {
        query = query.where('level1', isEqualTo: selectedLevel1);
        _logDebug('添加查詢條件: level1=$selectedLevel1');
      }
      
      if (level >= 3 && selectedLevel2.isNotEmpty) {
        query = query.where('level2', isEqualTo: selectedLevel2);
        _logDebug('添加查詢條件: level2=$selectedLevel2');
      }
      
      if (level >= 4 && selectedLevel3.isNotEmpty) {
        query = query.where('level3', isEqualTo: selectedLevel3);
        _logDebug('添加查詢條件: level3=$selectedLevel3');
      }
      
      if (level >= 5 && selectedLevel4.isNotEmpty) {
        query = query.where('level4', isEqualTo: selectedLevel4);
        _logDebug('添加查詢條件: level4=$selectedLevel4');
      }
      
      // 輸出完整查詢條件用於調試
      _logDebug('完整查詢條件: 查詢level$level, type=$selectedType, bodyPart=$selectedBodyPart, ' 'level1=$selectedLevel1, level2=$selectedLevel2, level3=$selectedLevel3, level4=$selectedLevel4');
      
      // 執行查詢，添加超時處理
      final querySnapshot = await query
          .get(const GetOptions(source: Source.server))
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('查詢超時，請檢查網絡連接'),
          );
          
      _logDebug('查詢到 ${querySnapshot.docs.length} 個文檔');
      
      // 提取並返回分類
      Set<String> categories = {};
      for (var doc in querySnapshot.docs) {
        final fieldName = 'level$level';
        final category = doc[fieldName] as String? ?? '';
        if (category.isNotEmpty) {
          categories.add(category);
          _logDebug('文檔 ${doc.id}: $fieldName = $category, type = ${doc['type']}, bodyParts = ${doc['bodyParts']}');
        }
      }
      
      _logDebug('從 ${querySnapshot.docs.length} 個文檔中提取了 ${categories.length} 個唯一 level$level 分類');
      
      List<String> result = categories.toList()..sort();
      
      // 存入緩存（如果啟用）
      if (_useCache && result.isNotEmpty) {
        unawaited(ExerciseCacheService.cacheCategories(cacheKey, result));
      }
      
      _logDebug('成功從服務器載入 Level$level 分類: ${result.length} 個項目');
      return result;
    } catch (e) {
      _logError('載入分類失敗: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<Exercise>> getExercisesByFilters(Map<String, String> filters) async {
    _ensureInitialized();
    
    // 構建緩存鍵
    final cacheKey = 'exercises_${filters.entries.map((e) => '${e.key}_${e.value}').join('_')}';
    _logDebug('最終動作緩存鍵: $cacheKey');
    _lastLoadTimes[cacheKey] = DateTime.now();
    
    // 清除該緩存鍵的舊資料（如果啟用緩存）
    if (_useCache) {
      await ExerciseCacheService.clearCacheForKey('ex_$cacheKey');
    }
    
    try {
      // 首先嘗試從緩存獲取（如果啟用）
      if (_useCache) {
        try {
          final cachedExercises = await ExerciseCacheService.getExercises(cacheKey);
          if (cachedExercises.isNotEmpty) {
            _logDebug('成功從緩存載入 ${cachedExercises.length} 個運動');
            return cachedExercises;
          }
        } catch (e) {
          _logDebug('從緩存獲取運動失敗，將從服務器獲取: $e');
        }
      }
      
      // 構建查詢
      Query query = _firestore.collection('exercise');
      
      // 添加所有有效的過濾條件
      for (final entry in filters.entries) {
        if (entry.value.isEmpty) continue;
        
        if (entry.key == 'bodyPart') {
          query = query.where('bodyParts', arrayContains: entry.value);
          _logDebug('添加查詢條件: bodyParts包含${entry.value}');
        } else {
          // 對於type和level1-level5的條件
          query = query.where(entry.key, isEqualTo: entry.value);
          _logDebug('添加查詢條件: ${entry.key}=${entry.value}');
        }
      }
      
      // 執行查詢，添加超時處理
      final querySnapshot = await query
          .get(const GetOptions(source: Source.server))
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('查詢超時，請檢查網絡連接'),
          );
          
      _logDebug('查詢到 ${querySnapshot.docs.length} 個最終動作');
      
      // 解析動作，添加更好的錯誤處理
      List<Exercise> exercises = [];
      for (var doc in querySnapshot.docs) {
        try {
          final exercise = Exercise.fromFirestore(doc);
          _logDebug('處理動作: ID=${exercise.id}, name=${exercise.name}');
          exercises.add(exercise);
        } catch (e) {
          _logError('解析動作失敗: ${doc.id} - $e');
          // 繼續處理其他文檔，而不是中斷整個流程
        }
      }
      
      // 存入緩存（如果啟用）
      if (_useCache && exercises.isNotEmpty) {
        unawaited(ExerciseCacheService.cacheExercises(cacheKey, exercises));
      }
      
      _logDebug('成功從服務器載入 ${exercises.length} 個運動');
      return exercises;
    } catch (e) {
      _logError('載入最終動作失敗: $e');
      rethrow;
    }
  }
  
  @override
  Future<Exercise?> getExerciseById(String exerciseId) async {
    _ensureInitialized();
    
    _logDebug('獲取運動詳情: $exerciseId');
    
    try {
      // 嘗試從緩存策略獲取（如果實現了單個動作緩存）
      
      // 從Firestore獲取
      final docSnapshot = await _firestore
          .collection('exercise')
          .doc(exerciseId)
          .get()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取運動詳情超時'),
          );
      
      if (!docSnapshot.exists) {
        _logDebug('運動詳情不存在: $exerciseId');
        return null;
      }
      
      final exercise = Exercise.fromFirestore(docSnapshot);
      _logDebug('成功獲取運動詳情: ${exercise.name}');
      return exercise;
    } catch (e) {
      _logError('獲取運動詳情失敗: $e');
      rethrow;
    }
  }
  
  /// 確保服務已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      _logDebug('警告: 運動服務在初始化前被調用');
      // 在開發環境中自動初始化，但在其他環境拋出錯誤
      if (_environment == Environment.development) {
        initialize();
      } else {
        throw StateError('運動服務未初始化');
      }
    }
  }
  
  /// 記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[EXERCISE] $message');
    }
  }
  
  /// 記錄錯誤信息
  void _logError(String message) {
    if (kDebugMode) {
      print('[EXERCISE ERROR] $message');
    }
    
    // 使用錯誤處理服務（如果可用）
    _errorService?.logError(message);
  }
}

/// 查詢超時異常
class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => message;
} 