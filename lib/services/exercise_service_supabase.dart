import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/exercise_model.dart';
import 'interfaces/i_exercise_service.dart';
import 'supabase_service.dart';
import 'error_handling_service.dart';
import 'service_locator.dart' show Environment;

/// 運動服務的 Supabase 實作
/// 
/// 提供訓練動作查詢、分類過濾和詳情獲取等功能
/// 與緩存服務協同工作，支援環境配置和統一錯誤處理
class ExerciseServiceSupabase implements IExerciseService {
  // 依賴注入
  final SupabaseClient _client;
  final ErrorHandlingService? _errorService;
  
  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;
  
  // 服務配置
  bool _useCache = false;  // 緩存服務已移除（Supabase 遷移）
  bool _preloadCommonData = true;
  int _queryTimeout = 15; // 秒
  
  // 載入狀態追蹤
  final Map<String, DateTime> _lastLoadTimes = {};
  
  /// 建立服務實例
  /// 
  /// 允許注入自訂的 Supabase Client，便於測試
  ExerciseServiceSupabase({
    SupabaseClient? client,
    ErrorHandlingService? errorService,
  }) : 
    _client = client ?? SupabaseService.client,
    _errorService = errorService;
  
  /// 初始化服務
  /// 
  /// 設定環境配置並初始化相關服務
  Future<void> initialize({Environment environment = Environment.development}) async {
    if (_isInitialized) return;
    
    try {
      // 設定環境
      configureForEnvironment(environment);
      
      // 如果配置了預載入，載入常用資料
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
        // 開發環境設定
        _useCache = false;  // 緩存服務已移除（Supabase 遷移）
        _preloadCommonData = true;
        _queryTimeout = 20; // 更長的逾時，便於除錯
        _logDebug('運動服務配置為開發環境');
        break;
      case Environment.testing:
        // 測試環境設定
        _useCache = false;  // 緩存服務已移除（Supabase 遷移）
        _preloadCommonData = false;
        _queryTimeout = 10;
        _logDebug('運動服務配置為測試環境');
        break;
      case Environment.production:
        // 生產環境設定
        _useCache = false;  // 緩存服務已移除（Supabase 遷移）
        _preloadCommonData = true;
        _queryTimeout = 15;
        _logDebug('運動服務配置為生產環境');
        break;
    }
  }
  
  /// 預載入常用運動資料
  Future<void> _preloadCommonExerciseData() async {
    _logDebug('開始預載入常用運動資料');
    
    try {
      // 預載入運動類型
      unawaited(getExerciseTypes());
      
      // 預載入身體部位
      unawaited(getBodyParts());
      
      // 不等待完成，讓它們在背景載入
      _logDebug('常用運動資料預載入任務已啟動');
    } catch (e) {
      _logError('預載入常用運動資料失敗: $e');
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
      // 緩存功能已移除（Supabase 遷移）
      // if (_useCache) {
      //   try {
      //     final cachedTypes = await ExerciseCacheService.getCategories('exerciseTypes');
      //     if (cachedTypes.isNotEmpty) {
      //       _logDebug('成功從緩存載入 ${cachedTypes.length} 個訓練類型');
      //       return cachedTypes;
      //     }
      //   } catch (e) {
      //     _logDebug('從緩存獲取訓練類型失敗，將從伺服器獲取: $e');
      //   }
      // }
      
      // 從 Supabase 獲取
      final response = await _client
          .from('exercise_types')
          .select('name')
          .order('name')
          .timeout(Duration(seconds: _queryTimeout));
      
      List<String> types = [];
      for (var item in (response as List)) {
        types.add(item['name'] as String);
      }
      
      _logDebug('成功從伺服器載入 ${types.length} 個訓練類型');
      
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
      // 緩存功能已移除（Supabase 遷移）
      // if (_useCache) {
      //   try {
      //     final cachedParts = await ExerciseCacheService.getCategories('bodyParts');
      //     if (cachedParts.isNotEmpty) {
      //       _logDebug('成功從緩存載入 ${cachedParts.length} 個身體部位');
      //       return cachedParts;
      //     }
      //   } catch (e) {
      //     _logDebug('從緩存獲取身體部位失敗，將從伺服器獲取: $e');
      //   }
      // }
      
      // 從 Supabase 獲取
      final response = await _client
          .from('body_parts')
          .select('name')
          .order('name')
          .timeout(Duration(seconds: _queryTimeout));
      
      List<String> parts = [];
      for (var item in (response as List)) {
        parts.add(item['name'] as String);
      }
      
      _logDebug('成功從伺服器載入 ${parts.length} 個身體部位');
      
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
    
    // 建構緩存鍵
    final selectedType = filters['type'] ?? "";
    final selectedBodyPart = filters['bodyPart'] ?? "";
    final selectedLevel1 = filters['level1'] ?? "";
    final selectedLevel2 = filters['level2'] ?? "";
    final selectedLevel3 = filters['level3'] ?? "";
    final selectedLevel4 = filters['level4'] ?? "";
    
    final cacheKey = 'level${level}_${selectedType}_${selectedBodyPart}_${selectedLevel1}_${selectedLevel2}_${selectedLevel3}_$selectedLevel4';
    _logDebug('緩存鍵: $cacheKey');
    _lastLoadTimes[cacheKey] = DateTime.now();
    
    // 緩存功能已移除（Supabase 遷移）
    // if (_useCache) {
    //   await ExerciseCacheService.clearCacheForKey('cat_$cacheKey');
    // }
    
    try {
      // 緩存功能已移除（Supabase 遷移）
      // if (_useCache) {
      //   try {
      //     final cachedCategories = await ExerciseCacheService.getCategories(cacheKey);
      //     if (cachedCategories.isNotEmpty) {
      //       _logDebug('成功從緩存載入 Level$level 分類: ${cachedCategories.length} 個項目');
      //       return cachedCategories;
      //     }
      //   } catch (e) {
      //     _logDebug('從緩存獲取 Level$level 分類失敗，將從伺服器獲取: $e');
      //   }
      // }
      
      // 驗證必要條件
      if (level == 1) {
        if (selectedType.isEmpty) {
          throw ArgumentError('查詢level1時必須指定訓練類型');
        }
        if (selectedBodyPart.isEmpty) {
          throw ArgumentError('查詢level1時必須指定身體部位');
        }
      }
      
      // 建構 Supabase 查詢
      var query = _client.from('exercises').select('level$level');
      
      // 確保類型條件始終套用
      if (selectedType.isNotEmpty) {
        query = query.eq('training_type', selectedType);
        _logDebug('新增查詢條件: training_type=$selectedType');
      }
      
      // 確保身體部位條件始終套用（PostgreSQL 陣列包含查詢）
      if (selectedBodyPart.isNotEmpty) {
        query = query.contains('body_parts', [selectedBodyPart]);
        _logDebug('新增查詢條件: body_parts包含$selectedBodyPart');
      }
      
      // 新增其他層級條件
      if (level >= 2 && selectedLevel1.isNotEmpty) {
        query = query.eq('level1', selectedLevel1);
        _logDebug('新增查詢條件: level1=$selectedLevel1');
      }
      
      if (level >= 3 && selectedLevel2.isNotEmpty) {
        query = query.eq('level2', selectedLevel2);
        _logDebug('新增查詢條件: level2=$selectedLevel2');
      }
      
      if (level >= 4 && selectedLevel3.isNotEmpty) {
        query = query.eq('level3', selectedLevel3);
        _logDebug('新增查詢條件: level3=$selectedLevel3');
      }
      
      if (level >= 5 && selectedLevel4.isNotEmpty) {
        query = query.eq('level4', selectedLevel4);
        _logDebug('新增查詢條件: level4=$selectedLevel4');
      }
      
      // 輸出完整查詢條件用於除錯
      _logDebug('完整查詢條件: 查詢level$level, type=$selectedType, bodyPart=$selectedBodyPart, '
                'level1=$selectedLevel1, level2=$selectedLevel2, level3=$selectedLevel3, level4=$selectedLevel4');
      
      // 執行查詢，新增逾時處理
      final response = await query.timeout(
        Duration(seconds: _queryTimeout),
        onTimeout: () => throw TimeoutException('查詢逾時，請檢查網路連線'),
      );
          
      _logDebug('查詢到 ${(response as List).length} 個文檔');
      
      // 提取並返回分類
      Set<String> categories = {};
      for (var item in response) {
        final fieldName = 'level$level';
        final category = item[fieldName] as String? ?? '';
        if (category.isNotEmpty) {
          categories.add(category);
          _logDebug('項目: $fieldName = $category, type = ${item['training_type']}, bodyParts = ${item['body_parts']}');
        }
      }
      
      _logDebug('從 ${response.length} 個文檔中提取了 ${categories.length} 個唯一 level$level 分類');
      
      List<String> result = categories.toList()..sort();
      
      // 緩存功能已移除（Supabase 遷移）
      // if (_useCache && result.isNotEmpty) {
      //   unawaited(ExerciseCacheService.cacheCategories(cacheKey, result));
      // }
      
      _logDebug('成功從伺服器載入 Level$level 分類: ${result.length} 個項目');
      return result;
    } catch (e) {
      _logError('載入分類失敗: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<Exercise>> getExercisesByFilters(Map<String, String> filters) async {
    _ensureInitialized();
    
    // 建構緩存鍵
    final cacheKey = 'exercises_${filters.entries.map((e) => '${e.key}_${e.value}').join('_')}';
    _logDebug('最終動作緩存鍵: $cacheKey');
    _lastLoadTimes[cacheKey] = DateTime.now();
    
    // 緩存功能已移除（Supabase 遷移）
    // if (_useCache) {
    //   await ExerciseCacheService.clearCacheForKey('ex_$cacheKey');
    // }
    
    try {
      // 緩存功能已移除（Supabase 遷移）
      // if (_useCache) {
      //   try {
      //     final cachedExercises = await ExerciseCacheService.getExercises(cacheKey);
      //     if (cachedExercises.isNotEmpty) {
      //       _logDebug('成功從緩存載入 ${cachedExercises.length} 個運動');
      //       return cachedExercises;
      //     }
      //   } catch (e) {
      //     _logDebug('從緩存獲取運動失敗，將從伺服器獲取: $e');
      //   }
      // }
      
      // 建構 Supabase 查詢
      var query = _client.from('exercises').select();
      
      // 新增所有有效的過濾條件
      for (final entry in filters.entries) {
        if (entry.value.isEmpty) continue;
        
        if (entry.key == 'bodyPart') {
          query = query.contains('body_parts', [entry.value]);
          _logDebug('新增查詢條件: body_parts包含${entry.value}');
        } else if (entry.key == 'type') {
          query = query.eq('training_type', entry.value);
          _logDebug('新增查詢條件: training_type=${entry.value}');
        } else {
          // 對於 level1-level5 的條件
          query = query.eq(entry.key, entry.value);
          _logDebug('新增查詢條件: ${entry.key}=${entry.value}');
        }
      }
      
      // 執行查詢，新增逾時處理
      final response = await query.timeout(
        Duration(seconds: _queryTimeout),
        onTimeout: () => throw TimeoutException('查詢逾時，請檢查網路連線'),
      );
          
      _logDebug('查詢到 ${(response as List).length} 個最終動作');
      
      // 解析動作，新增更好的錯誤處理
      List<Exercise> exercises = [];
      for (var item in response) {
        try {
          final exercise = Exercise.fromSupabase(item);
          _logDebug('處理動作: ID=${exercise.id}, name=${exercise.name}');
          exercises.add(exercise);
        } catch (e) {
          _logError('解析動作失敗: ${item['id']} - $e');
          // 繼續處理其他文檔，而不是中斷整個流程
        }
      }
      
      // 緩存功能已移除（Supabase 遷移）
      // if (_useCache && exercises.isNotEmpty) {
      //   unawaited(ExerciseCacheService.cacheExercises(cacheKey, exercises));
      // }
      
      _logDebug('成功從伺服器載入 ${exercises.length} 個運動');
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
      // 嘗試從緩存策略獲取（如果實作了單個動作緩存）
      
      // 從 Supabase 獲取
      final response = await _client
          .from('exercises')
          .select()
          .eq('id', exerciseId)
          .maybeSingle()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取運動詳情逾時'),
          );
      
      if (response == null) {
        _logDebug('運動詳情不存在: $exerciseId');
        return null;
      }
      
      final exercise = Exercise.fromSupabase(response);
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
      _logError('錯誤: 運動服務在初始化前被呼叫');
      // 拋出錯誤，要求在 Service Locator 中正確初始化
      throw StateError('運動服務未初始化。請確保在 setupServiceLocator() 中調用了 initialize()');
    }
  }
  
  /// 記錄除錯資訊
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[EXERCISE_SUPABASE] $message');
    }
  }
  
  /// 記錄錯誤資訊
  void _logError(String message) {
    if (kDebugMode) {
      print('[EXERCISE_SUPABASE ERROR] $message');
    }
    
    // 使用錯誤處理服務（如果可用）
    _errorService?.logError(message);
  }
}

/// 查詢逾時異常
class TimeoutException implements Exception {
  final String message;
  
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}

