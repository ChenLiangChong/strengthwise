import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../models/exercise_model.dart';
import '../interfaces/i_exercise_service.dart';
import '../core/supabase_service.dart';
import '../core/error_handling_service.dart';
import '../service_locator.dart' show Environment;
import '../cache/exercise_local_cache_service.dart';
import 'exercise/exercise_data_loader.dart';
import 'exercise/exercise_data_parser.dart';
import 'exercise/exercise_search_engine.dart';
import 'exercise/exercise_preload_manager.dart';

/// 運動服務的 Supabase 實作
///
/// 提供訓練動作查詢、分類過濾和詳情獲取等功能
/// 與緩存服務協同工作，支援環境配置和統一錯誤處理
class ExerciseServiceSupabase implements IExerciseService {
  // 依賴注入
  final SupabaseClient _client;
  final ErrorHandlingService? _errorService;
  final ExerciseLocalCacheService _localCache = ExerciseLocalCacheService();

  // 服務狀態
  bool _isInitialized = false;

  // 服務配置
  bool _preloadCommonData = true;
  int _queryTimeout = 15; // 秒

  // 載入狀態追蹤
  final Map<String, DateTime> _lastLoadTimes = {};

  // 子模組
  late final ExerciseDataLoader _dataLoader;
  late final ExerciseDataParser _dataParser;
  late final ExerciseSearchEngine _searchEngine;
  late final ExercisePreloadManager _preloadManager;

  /// 建立服務實例
  ///
  /// 允許注入自訂的 Supabase Client，便於測試
  ExerciseServiceSupabase({
    SupabaseClient? client,
    ErrorHandlingService? errorService,
  })  : _client = client ?? SupabaseService.client,
        _errorService = errorService {
    _dataLoader = ExerciseDataLoader(
      client: _client,
      errorService: _errorService,
      queryTimeout: _queryTimeout,
    );
    _dataParser = ExerciseDataParser(errorService: _errorService);
    _searchEngine = ExerciseSearchEngine();
    _preloadManager = ExercisePreloadManager(
      localCache: _localCache,
      dataLoader: _dataLoader,
      dataParser: _dataParser,
    );
  }

  /// 初始化服務
  ///
  /// 設定環境配置並初始化相關服務
  Future<void> initialize(
      {Environment environment = Environment.development}) async {
    if (_isInitialized) return;

    try {
      // 設定環境
      configureForEnvironment(environment);

      // ⚡ 初始化本地快取
      await _localCache.initialize();

      // 標記為已初始化（必須在預載入前設置，否則預載入會失敗）
      _isInitialized = true;

      // 如果配置了預載入，載入常用資料
      if (_preloadCommonData) {
        _preloadCommonExerciseData();
      }

      _logDebug('運動服務初始化完成');
    } catch (e) {
      _logError('運動服務初始化失敗: $e');
      _isInitialized = false; // 初始化失敗時重置狀態
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
    switch (environment) {
      case Environment.development:
        // 開發環境設定
        _preloadCommonData = true;
        _queryTimeout = 20; // 更長的逾時，便於除錯
        _logDebug('運動服務配置為開發環境');
        break;
      case Environment.testing:
        // 測試環境設定
        _preloadCommonData = false;
        _queryTimeout = 10;
        _logDebug('運動服務配置為測試環境');
        break;
      case Environment.production:
        // 生產環境設定
        _preloadCommonData = true;
        _queryTimeout = 15;
        _logDebug('運動服務配置為生產環境');
        break;
    }
  }

  /// 預載入常用運動資料（背景執行）⚡ 優化版
  Future<void> _preloadCommonExerciseData() async {
    if (_preloadManager.isPreloading) {
      _logDebug('預載入已在進行中，跳過');
      return;
    }

    _logDebug('🚀 開始背景預載入所有動作資料...');

    try {
      // ⚡ 預載入所有動作（不等待，背景執行）
      unawaited(_preloadManager.preloadAllExercises());

      // 預載入訓練類型
      unawaited(getExerciseTypes());

      // 預載入身體部位
      unawaited(getBodyParts());

      _logDebug('✅ 預載入任務已啟動（背景執行）');
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
      final types = await _dataLoader.loadExerciseTypes();
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
      final parts = await _dataLoader.loadBodyParts();
      _logDebug('成功從伺服器載入 ${parts.length} 個身體部位');
      return parts;
    } catch (e) {
      _logError('載入身體部位失敗: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getCategoriesByLevel(
      int level, Map<String, String> filters) async {
    _ensureInitialized();

    _logDebug('開始載入Level$level分類');

    // 建構緩存鍵
    final selectedType = filters['type'] ?? "";
    final selectedBodyPart = filters['bodyPart'] ?? "";
    final selectedLevel1 = filters['level1'] ?? "";
    final selectedLevel2 = filters['level2'] ?? "";
    final selectedLevel3 = filters['level3'] ?? "";
    final selectedLevel4 = filters['level4'] ?? "";

    final cacheKey =
        'level${level}_${selectedType}_${selectedBodyPart}_${selectedLevel1}_${selectedLevel2}_${selectedLevel3}_$selectedLevel4';
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

      // 執行查詢
      final response = await _dataLoader.loadCategoriesByLevel(
        level: level,
        selectedType: selectedType,
        selectedBodyPart: selectedBodyPart,
        selectedLevel1: selectedLevel1,
        selectedLevel2: selectedLevel2,
        selectedLevel3: selectedLevel3,
        selectedLevel4: selectedLevel4,
      );

      _logDebug('查詢到 ${(response as List).length} 個文檔');

      // 提取並返回分類
      final result = _dataParser.extractCategoriesFromLevel(response, level);
      _logDebug('成功從伺服器載入 Level$level 分類: ${result.length} 個項目');
      return result;
    } catch (e) {
      _logError('載入分類失敗: $e');
      rethrow;
    }
  }

  @override
  Future<List<Exercise>> getExercisesByFilters(
      Map<String, String> filters) async {
    _ensureInitialized();

    // 建構緩存鍵
    final cacheKey =
        'exercises_${filters.entries.map((e) => '${e.key}_${e.value}').join('_')}';
    _logDebug('最終動作緩存鍵: $cacheKey');
    _lastLoadTimes[cacheKey] = DateTime.now();

    try {
      // ⚡ 優先使用記憶體快取（如果已預載入）
      final allExercisesCache = _preloadManager.allExercisesCache;
      if (allExercisesCache != null && allExercisesCache.isNotEmpty) {
        _logDebug('✨ 使用記憶體快取（${allExercisesCache.length} 個動作），客戶端過濾...');

        // 客戶端過濾
        var exercises = allExercisesCache;

        for (final entry in filters.entries) {
          if (entry.value.isEmpty) continue;

          if (entry.key == 'bodyPart') {
            exercises =
                exercises.where((e) => e.bodyPart == entry.value).toList();
            _logDebug('過濾條件: bodyPart=${entry.value}，剩餘 ${exercises.length} 個');
          } else if (entry.key == 'type') {
            exercises =
                exercises.where((e) => e.trainingType == entry.value).toList();
            _logDebug('過濾條件: type=${entry.value}，剩餘 ${exercises.length} 個');
          } else if (entry.key == 'level1') {
            exercises =
                exercises.where((e) => e.level1 == entry.value).toList();
            _logDebug('過濾條件: level1=${entry.value}，剩餘 ${exercises.length} 個');
          } else if (entry.key == 'level2') {
            exercises =
                exercises.where((e) => e.level2 == entry.value).toList();
            _logDebug('過濾條件: level2=${entry.value}，剩餘 ${exercises.length} 個');
          } else if (entry.key == 'level3') {
            exercises =
                exercises.where((e) => e.level3 == entry.value).toList();
            _logDebug('過濾條件: level3=${entry.value}，剩餘 ${exercises.length} 個');
          } else if (entry.key == 'level4') {
            exercises =
                exercises.where((e) => e.level4 == entry.value).toList();
            _logDebug('過濾條件: level4=${entry.value}，剩餘 ${exercises.length} 個');
          } else if (entry.key == 'level5') {
            exercises =
                exercises.where((e) => e.level5 == entry.value).toList();
            _logDebug('過濾條件: level5=${entry.value}，剩餘 ${exercises.length} 個');
          }
        }

        _logDebug('✅ 從快取過濾出 ${exercises.length} 個動作（零網路請求！）');
        return exercises;
      }

      // ⚠️ 快取未準備好，回退到資料庫查詢
      _logDebug('⚠️ 快取未準備好，從資料庫查詢...');

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
          exercises.add(exercise);
        } catch (e) {
          _logError('解析動作失敗: ${item['id']} - $e');
          // 繼續處理其他文檔，而不是中斷整個流程
        }
      }

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
      // 先嘗試從 exercises 表格獲取（系統動作）
      final response = await _client
          .from('exercises')
          .select()
          .eq('id', exerciseId)
          .maybeSingle()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取運動詳情逾時'),
          );

      if (response != null) {
        final exercise = Exercise.fromSupabase(response);
        _logDebug('成功獲取系統運動詳情: ${exercise.name}');
        return exercise;
      }

      // 如果在 exercises 找不到，嘗試從 custom_exercises 獲取（自訂動作）
      _logDebug('在系統動作中未找到，嘗試查詢自訂動作: $exerciseId');

      final customResponse = await _client
          .from('custom_exercises')
          .select()
          .eq('id', exerciseId)
          .maybeSingle()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取自訂動作詳情逾時'),
          );

      if (customResponse != null) {
        // 將 custom_exercises 的資料轉換為 Exercise 格式
        // ⚠️ 自訂動作使用實際的 training_type（而非固定的「自訂」）
        final customExercise = {
          'id': customResponse['id'],
          'name': customResponse['name'],
          'name_en': '',
          'body_parts': [customResponse['body_part']],
          'type': customResponse['training_type'] ?? '阻力訓練', // 使用實際訓練類型
          'equipment': customResponse['equipment'] ?? '徒手',
          'joint_type': '',
          'level1': '',
          'level2': '',
          'level3': '',
          'level4': '',
          'level5': '',
          'action_name': customResponse['name'],
          'description': customResponse['description'] ?? '用戶自訂動作',
          'image_url': '',
          'video_url': '',
          'apps': [],
          'created_at': customResponse['created_at'],
          'training_type':
              customResponse['training_type'] ?? '阻力訓練', // 使用實際訓練類型
          'body_part': customResponse['body_part'],
          'specific_muscle': '',
          'equipment_category': customResponse['equipment'] ?? '徒手',
          'equipment_subcategory': '',
        };

        final exercise = Exercise.fromSupabase(customExercise);
        _logDebug('成功獲取自訂運動詳情: ${exercise.name}');
        return exercise;
      }

      _logDebug('運動詳情不存在（系統動作和自訂動作都未找到）: $exerciseId');
      return null;
    } catch (e) {
      _logError('獲取運動詳情失敗: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, Exercise>> getExercisesByIds(
      List<String> exerciseIds) async {
    _ensureInitialized();

    if (exerciseIds.isEmpty) return {};

    _logDebug('批量獲取 ${exerciseIds.length} 個運動詳情');

    try {
      final Map<String, Exercise> result = {};

      // 批量查詢系統動作（一次查詢）
      final systemResponse = await _client
          .from('exercises')
          .select()
          .inFilter('id', exerciseIds)
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('批量獲取運動詳情逾時'),
          );

      // 解析系統動作
      for (var item in systemResponse as List) {
        try {
          final exercise = Exercise.fromSupabase(item);
          result[exercise.id] = exercise;
        } catch (e) {
          _logError('解析系統動作失敗: ${item['id']} - $e');
        }
      }

      // 找出未在系統動作中找到的 ID
      final notFoundIds =
          exerciseIds.where((id) => !result.containsKey(id)).toList();

      if (notFoundIds.isNotEmpty) {
        _logDebug('在系統動作中未找到 ${notFoundIds.length} 個，查詢自訂動作');

        // 批量查詢自訂動作
        final customResponse = await _client
            .from('custom_exercises')
            .select()
            .inFilter('id', notFoundIds)
            .timeout(
              Duration(seconds: _queryTimeout),
              onTimeout: () => throw TimeoutException('批量獲取自訂動作詳情逾時'),
            );

        // 解析自訂動作
        for (var item in customResponse as List) {
          try {
            // ⚠️ 自訂動作使用實際的 training_type（而非固定的「自訂」）
            final customExercise = {
              'id': item['id'],
              'name': item['name'],
              'name_en': '',
              'body_parts': [item['body_part']],
              'type': item['training_type'] ?? '阻力訓練', // 使用實際訓練類型
              'equipment': item['equipment'] ?? '徒手',
              'joint_type': '',
              'level1': '',
              'level2': '',
              'level3': '',
              'level4': '',
              'level5': '',
              'action_name': item['name'],
              'description': item['description'] ?? '用戶自訂動作',
              'image_url': '',
              'video_url': '',
              'apps': [],
              'created_at': item['created_at'],
              'training_type': item['training_type'] ?? '阻力訓練', // 使用實際訓練類型
              'body_part': item['body_part'],
              'specific_muscle': '',
              'equipment_category': item['equipment'] ?? '徒手',
              'equipment_subcategory': '',
            };

            final exercise = Exercise.fromSupabase(customExercise);
            result[exercise.id] = exercise;
          } catch (e) {
            _logError('解析自訂動作失敗: ${item['id']} - $e');
          }
        }
      }

      _logDebug('成功批量獲取 ${result.length}/${exerciseIds.length} 個運動詳情');
      return result;
    } catch (e) {
      _logError('批量獲取運動詳情失敗: $e');
      return {};
    }
  }

  @override
  Future<List<Exercise>> searchExercises(String query, {int limit = 20}) async {
    _ensureInitialized();

    if (query.trim().isEmpty) {
      _logDebug('搜尋關鍵字為空，返回空列表');
      return [];
    }

    _logDebug('🔍 使用 pgroonga 搜尋動作: "$query" (limit: $limit)');

    try {
      // ⚡ 優化：優先從記憶體快取搜尋（如果已預載入）
      final allExercisesCache = _preloadManager.allExercisesCache;
      if (allExercisesCache != null && allExercisesCache.isNotEmpty) {
        _logDebug('✨ 使用記憶體快取進行客戶端搜尋...');

        final results = _searchEngine.searchFromCache(
          cache: allExercisesCache,
          query: query,
          limit: limit,
        );

        _logDebug('✅ 從快取搜尋到 ${results.length} 個結果');
        return results;
      }

      // ⚠️ 快取未準備好，使用 pgroonga RPC 函式
      _logDebug('☁️  使用 pgroonga RPC 函式搜尋...');

      final response = await _client.rpc(
        'search_exercises_pgroonga',
        params: {
          'search_query': query,
          'max_results': limit,
        },
      ).timeout(
        Duration(seconds: _queryTimeout),
        onTimeout: () => throw TimeoutException('搜尋動作逾時'),
      );

      _logDebug('pgroonga 回應: ${(response as List).length} 個結果');

      // 解析搜尋結果
      final List<Exercise> exercises = [];
      for (var item in response) {
        try {
          final exercise = Exercise.fromSupabase(item);
          exercises.add(exercise);
        } catch (e) {
          _logError('解析搜尋結果失敗: ${item['id']} - $e');
        }
      }

      _logDebug('✅ 成功搜尋到 ${exercises.length} 個動作');
      return exercises;
    } catch (e) {
      _logError('搜尋動作失敗: $e');
      // 如果 RPC 失敗，回退到簡單的 LIKE 查詢
      _logDebug('⚠️ pgroonga 搜尋失敗，回退到 LIKE 查詢');
      return _fallbackSearch(query, limit);
    }
  }

  /// 回退搜尋方法（當 pgroonga 不可用時）
  Future<List<Exercise>> _fallbackSearch(String query, int limit) async {
    try {
      final response = await _client
          .from('exercises')
          .select()
          .or('name.ilike.%$query%,name_en.ilike.%$query%')
          .limit(limit)
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('回退搜尋逾時'),
          );

      final List<Exercise> exercises = [];
      for (var item in response as List) {
        try {
          final exercise = Exercise.fromSupabase(item);
          exercises.add(exercise);
        } catch (e) {
          _logError('解析回退搜尋結果失敗: ${item['id']} - $e');
        }
      }

      _logDebug('回退搜尋到 ${exercises.length} 個結果');
      return exercises;
    } catch (e) {
      _logError('回退搜尋失敗: $e');
      return [];
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
