import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/custom_exercise_model.dart';
import '../interfaces/i_custom_exercise_service.dart';
import '../core/error_handling_service.dart';
import '../service_locator.dart' show Environment;
import 'custom_exercise/custom_exercise_cache_manager.dart';
import 'custom_exercise/custom_exercise_operations.dart';

/// 自定義動作服務的 Supabase 實現
///
/// 提供用戶自定義動作的創建、讀取、更新、刪除等功能
class CustomExerciseServiceSupabase implements ICustomExerciseService {
  // 依賴注入
  final SupabaseClient _supabase;
  final ErrorHandlingService? _errorService;

  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;

  // 服務配置
  bool _useCache = true;
  int _queryTimeout = 8; // 秒

  // 子模組
  late final CustomExerciseCacheManager _cacheManager;
  late final CustomExerciseOperations _operations;

  /// 創建服務實例
  CustomExerciseServiceSupabase({
    SupabaseClient? supabase,
    ErrorHandlingService? errorService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _errorService = errorService {
    _cacheManager = CustomExerciseCacheManager();
    _operations = CustomExerciseOperations(
      supabase: _supabase,
      logDebug: _logDebug,
      queryTimeout: _queryTimeout,
    );
  }

  /// 初始化服務
  Future<void> initialize({Environment environment = Environment.development}) async {
    if (_isInitialized) return;

    try {
      configureForEnvironment(environment);

      // 配置快取管理器
      _cacheManager.configure(_queryTimeout > 10 ? 10 : _queryTimeout ~/ 2);

      if (_useCache) {
        _cacheManager.setupCacheCleanupTimer();
      }

      _isInitialized = true;
      _logDebug('自定義動作服務初始化完成');
    } catch (e) {
      _logError('自定義動作服務初始化失敗: $e');
      rethrow;
    }
  }

  /// 釋放資源
  Future<void> dispose() async {
    try {
      _cacheManager.dispose();
      _isInitialized = false;
      _logDebug('自定義動作服務資源已釋放');
    } catch (e) {
      _logError('釋放自定義動作服務資源時發生錯誤: $e');
    }
  }

  /// 根據環境配置服務
  void configureForEnvironment(Environment environment) {
    _environment = environment;

    switch (environment) {
      case Environment.development:
        _useCache = true;
        _queryTimeout = 12;
        _logDebug('自定義動作服務配置為開發環境');
        break;
      case Environment.testing:
        _useCache = false;
        _queryTimeout = 6;
        _logDebug('自定義動作服務配置為測試環境');
        break;
      case Environment.production:
        _useCache = true;
        _queryTimeout = 8;
        _logDebug('自定義動作服務配置為生產環境');
        break;
    }
  }

  // 獲取當前用戶ID
  String? get currentUserId {
    _ensureInitialized();
    return _supabase.auth.currentUser?.id;
  }

  @override
  Future<CustomExercise> addCustomExercise({
    required String name,
    required String trainingType,
    required String bodyPart,
    String equipment = '徒手',
    String description = '',
    String notes = '',
    String trackingMode = 'weight_reps', // v3.2+
  }) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('添加自定義動作失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }

    try {
      final newExercise = await _operations.createCustomExercise(
        userId: currentUserId!,
        name: name,
        trainingType: trainingType,
        bodyPart: bodyPart,
        equipment: equipment,
        description: description,
        notes: notes,
        trackingMode: trackingMode, // v3.2+
      );

      // 更新緩存
      if (_useCache) {
        _cacheManager.addExercise(newExercise);
      }

      return newExercise;
    } catch (e) {
      _logError('添加自定義動作失敗: $e');
      rethrow;
    }
  }

  @override
  Future<List<CustomExercise>> getUserCustomExercises() async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logDebug('獲取自定義動作：沒有登入用戶');
      return [];
    }

    // 檢查緩存
    if (_useCache && _cacheManager.isListCacheValid()) {
      final cached = _cacheManager.getListCache();
      if (cached != null) {
        _logDebug('從緩存獲取自定義動作列表 (${cached.length} 個動作)');
        return List.unmodifiable(cached);
      }
    }

    try {
      final exercises = await _operations.getUserCustomExercises(currentUserId!);

      // 更新緩存
      if (_useCache) {
        _cacheManager.updateListCache(exercises);
      }

      return exercises;
    } catch (e) {
      _logError('獲取自定義動作失敗: $e');

      if (_useCache) {
        final cached = _cacheManager.getListCache();
        if (cached != null) {
          _logDebug('服務器獲取失敗，返回可能過期的緩存數據');
          return List.unmodifiable(cached);
        }
      }

      rethrow;
    }
  }

  @override
  Future<void> deleteCustomExercise(String exerciseId) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('刪除自定義動作失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }

    try {
      await _operations.deleteCustomExercise(currentUserId!, exerciseId);

      // 更新緩存
      if (_useCache) {
        _cacheManager.removeExercise(exerciseId);
      }
    } catch (e) {
      _logError('刪除自定義動作失敗: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCustomExercise({
    required String exerciseId,
    String? name,
    String? trainingType,
    String? bodyPart,
    String? equipment,
    String? description,
    String? notes,
    String? trackingMode, // v3.2+
  }) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('更新自定義動作失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }

    try {
      await _operations.updateCustomExercise(
        userId: currentUserId!,
        exerciseId: exerciseId,
        name: name,
        trainingType: trainingType,
        bodyPart: bodyPart,
        equipment: equipment,
        description: description,
        notes: notes,
        trackingMode: trackingMode, // v3.2+
      );

      // 清除緩存
      if (_useCache) {
        _cacheManager.invalidate(exerciseId);
      }
    } catch (e) {
      _logError('更新自定義動作失敗: $e');
      rethrow;
    }
  }

  // ========================================
  // v3.4+ 教練自訂動作複製功能
  // ========================================

  @override
  Future<bool> isCoachCustomExercise(String exerciseId) async {
    _ensureInitialized();

    if (currentUserId == null) {
      return false;
    }

    try {
      // 1. 檢查是否在系統動作庫
      final systemExercise = await _supabase
          .from('exercises')
          .select('id')
          .eq('id', exerciseId)
          .maybeSingle()
          .timeout(Duration(seconds: _queryTimeout));

      if (systemExercise != null) {
        // 是系統動作，不是教練自訂
        return false;
      }

      // 2. 檢查是否在當前用戶的自訂動作中
      final myCustomExercise = await _supabase
          .from('custom_exercises')
          .select('id')
          .eq('id', exerciseId)
          .eq('user_id', currentUserId!)
          .maybeSingle()
          .timeout(Duration(seconds: _queryTimeout));

      if (myCustomExercise != null) {
        // 是我的自訂動作，不需要複製
        return false;
      }

      // 不在系統庫，也不在我的自訂動作中 = 是教練的自訂動作
      _logDebug('動作 $exerciseId 識別為教練自訂動作');
      return true;
    } catch (e) {
      _logError('檢查是否為教練自訂動作失敗: $e');
      return false;
    }
  }

  @override
  Future<CustomExercise> copyToMyExercises({
    required String name,
    required String trainingType,
    required String bodyPart,
    String equipment = '徒手',
    String trackingMode = 'weight_reps',
    String description = '',
    String notes = '',
  }) async {
    _ensureInitialized();

    if (currentUserId == null) {
      throw Exception('用戶未登入');
    }

    _logDebug('複製動作到我的動作庫: $name');

    // 直接調用 addCustomExercise，因為邏輯相同
    return await addCustomExercise(
      name: name,
      trainingType: trainingType,
      bodyPart: bodyPart,
      equipment: equipment,
      trackingMode: trackingMode,
      description: description,
      notes: notes,
    );
  }

  @override
  Future<int> getTrainingRecordCount(String exerciseId) async {
    _ensureInitialized();

    if (currentUserId == null) {
      return 0;
    }

    try {
      // 使用 JSONB 包含查詢，檢查 exercises 陣列中是否有 exerciseId
      // PostgreSQL: exercises @> '[{"exerciseId": "xxx"}]'::jsonb
      final response = await _supabase
          .from('workout_plans')
          .select('id')
          .contains('exercises', [{'exerciseId': exerciseId}])
          .eq('completed', true)
          .or('trainee_id.eq.${currentUserId!},creator_id.eq.${currentUserId!}')
          .timeout(Duration(seconds: _queryTimeout));

      final count = (response as List).length;
      _logDebug('動作 $exerciseId 有 $count 筆訓練記錄');
      return count;
    } catch (e) {
      _logError('查詢訓練記錄數量失敗: $e');
      return 0;
    }
  }

  /// 確保服務已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      _logDebug('警告: 自定義動作服務在初始化前被調用');
      if (_environment == Environment.development) {
        initialize();
      } else {
        throw StateError('自定義動作服務未初始化');
      }
    }
  }

  /// 記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint('[CUSTOM_EXERCISE_SUPABASE] $message');
    }
  }

  /// 記錄錯誤信息
  void _logError(String message) {
    if (kDebugMode) {
      debugPrint('[CUSTOM_EXERCISE_SUPABASE ERROR] $message');
    }
    _errorService?.logError(message);
  }
}
