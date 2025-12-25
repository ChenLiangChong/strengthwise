import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/custom_exercise_model.dart';
import 'interfaces/i_custom_exercise_service.dart';
import 'error_handling_service.dart';
import 'service_locator.dart' show Environment;

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
  int _cacheDuration = 5; // 分鐘

  // 緩存
  List<CustomExercise>? _userExercisesCache;
  DateTime? _userExercisesCacheTime;
  final Map<String, CustomExercise> _exerciseCache = {};
  Timer? _cacheClearTimer;

  /// 創建服務實例
  CustomExerciseServiceSupabase({
    SupabaseClient? supabase,
    ErrorHandlingService? errorService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _errorService = errorService;

  /// 初始化服務
  Future<void> initialize({Environment environment = Environment.development}) async {
    if (_isInitialized) return;

    try {
      configureForEnvironment(environment);

      if (_useCache) {
        _setupCacheCleanupTimer();
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
      _cacheClearTimer?.cancel();
      _cacheClearTimer = null;

      _userExercisesCache = null;
      _userExercisesCacheTime = null;
      _exerciseCache.clear();

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
        _cacheDuration = 10;
        _logDebug('自定義動作服務配置為開發環境');
        break;
      case Environment.testing:
        _useCache = false;
        _queryTimeout = 6;
        _cacheDuration = 2;
        _logDebug('自定義動作服務配置為測試環境');
        break;
      case Environment.production:
        _useCache = true;
        _queryTimeout = 8;
        _cacheDuration = 5;
        _logDebug('自定義動作服務配置為生產環境');
        break;
    }
  }

  /// 設置緩存清理計時器
  void _setupCacheCleanupTimer() {
    _cacheClearTimer?.cancel();
    _cacheClearTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _clearCache();
    });
  }

  /// 清除緩存
  void _clearCache() {
    _logDebug('清理自定義動作緩存');
    _userExercisesCache = null;
    _userExercisesCacheTime = null;
    _exerciseCache.clear();
  }

  // 獲取當前用戶ID
  String? get currentUserId {
    _ensureInitialized();
    return _supabase.auth.currentUser?.id;
  }

  @override
  Future<CustomExercise> addCustomExercise(String name) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('添加自定義動作失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }

    try {
      _logDebug('創建新的自定義動作: $name');

      // 插入到 Supabase
      final response = await _supabase
          .from('custom_exercises')
          .insert({
            'user_id': currentUserId,
            'name': name,
          })
          .select()
          .single()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('添加自定義動作超時'),
          );

      final newExercise = CustomExercise.fromSupabase(response);

      // 更新緩存
      if (_useCache) {
        _exerciseCache[newExercise.id] = newExercise;

        if (_userExercisesCache != null) {
          _userExercisesCache = [newExercise, ..._userExercisesCache!];
          _userExercisesCacheTime = DateTime.now();
        }
      }

      _logDebug('自定義動作創建成功: ${newExercise.id}');
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
    if (_useCache && _userExercisesCache != null && _userExercisesCacheTime != null) {
      final cacheAge = DateTime.now().difference(_userExercisesCacheTime!);
      if (cacheAge.inMinutes < _cacheDuration) {
        _logDebug('從緩存獲取自定義動作列表 (${_userExercisesCache!.length} 個動作)');
        return List.unmodifiable(_userExercisesCache!);
      }
    }

    try {
      _logDebug('從 Supabase 獲取自定義動作');

      final response = await _supabase
          .from('custom_exercises')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false)
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取自定義動作列表超時'),
          );

      final exercises = (response as List)
          .map((data) => CustomExercise.fromSupabase(data))
          .toList();

      // 更新緩存
      if (_useCache) {
        _userExercisesCache = exercises;
        _userExercisesCacheTime = DateTime.now();

        for (final exercise in exercises) {
          _exerciseCache[exercise.id] = exercise;
        }
      }

      _logDebug('成功獲取 ${exercises.length} 個自定義動作');
      return exercises;
    } catch (e) {
      _logError('獲取自定義動作失敗: $e');

      if (_useCache && _userExercisesCache != null) {
        _logDebug('服務器獲取失敗，返回可能過期的緩存數據');
        return List.unmodifiable(_userExercisesCache!);
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
      _logDebug('刪除自定義動作: $exerciseId');

      // Supabase RLS 會自動檢查權限
      await _supabase
          .from('custom_exercises')
          .delete()
          .eq('id', exerciseId)
          .eq('user_id', currentUserId!)
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('刪除自定義動作超時'),
          );

      // 更新緩存
      if (_useCache) {
        _exerciseCache.remove(exerciseId);

        if (_userExercisesCache != null) {
          _userExercisesCache = _userExercisesCache!
              .where((exercise) => exercise.id != exerciseId)
              .toList();
          _userExercisesCacheTime = DateTime.now();
        }
      }

      _logDebug('自定義動作刪除成功');
    } catch (e) {
      _logError('刪除自定義動作失敗: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCustomExercise(String exerciseId, String newName) async {
    _ensureInitialized();

    if (currentUserId == null) {
      _logError('更新自定義動作失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }

    try {
      _logDebug('更新自定義動作: $exerciseId, 新名稱: $newName');

      // Supabase RLS 會自動檢查權限
      await _supabase
          .from('custom_exercises')
          .update({'name': newName})
          .eq('id', exerciseId)
          .eq('user_id', currentUserId!)
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('更新自定義動作超時'),
          );

      // 更新緩存
      if (_useCache) {
        CustomExercise? oldExercise = _exerciseCache[exerciseId];

        if (oldExercise != null) {
          final updatedExercise = CustomExercise(
            id: oldExercise.id,
            name: newName,
            userId: oldExercise.userId,
            createdAt: oldExercise.createdAt,
          );

          _exerciseCache[exerciseId] = updatedExercise;

          if (_userExercisesCache != null) {
            _userExercisesCache = _userExercisesCache!
                .map((e) => e.id == exerciseId ? updatedExercise : e)
                .toList();
            _userExercisesCacheTime = DateTime.now();
          }
        }
      }

      _logDebug('自定義動作更新成功');
    } catch (e) {
      _logError('更新自定義動作失敗: $e');
      rethrow;
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
      print('[CUSTOM_EXERCISE_SUPABASE] $message');
    }
  }

  /// 記錄錯誤信息
  void _logError(String message) {
    if (kDebugMode) {
      print('[CUSTOM_EXERCISE_SUPABASE ERROR] $message');
    }
    _errorService?.logError(message);
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

