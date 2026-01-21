import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../models/exercise_model.dart';
import '../../../services/cache/exercise_local_cache_service.dart';
import 'exercise_data_loader.dart';
import 'exercise_data_parser.dart';

/// 動作預載入管理器
class ExercisePreloadManager {
  final ExerciseLocalCacheService _localCache;
  final ExerciseDataLoader _dataLoader;
  final ExerciseDataParser _dataParser;
  
  List<Exercise>? _allExercisesCache;
  bool _isPreloading = false;

  ExercisePreloadManager({
    required ExerciseLocalCacheService localCache,
    required ExerciseDataLoader dataLoader,
    required ExerciseDataParser dataParser,
  })  : _localCache = localCache,
        _dataLoader = dataLoader,
        _dataParser = dataParser;

  /// 取得快取
  List<Exercise>? get allExercisesCache => _allExercisesCache;

  /// 是否正在預載入
  bool get isPreloading => _isPreloading;

  /// 預載入所有動作到快取
  Future<void> preloadAllExercises() async {
    if (_isPreloading) {
      _logDebug('預載入已在進行中，跳過');
      return;
    }

    _isPreloading = true;
    _logDebug('🚀 開始背景預載入所有動作資料...');

    try {
      final startTime = DateTime.now();

      // 優先從本地載入
      if (_localCache.isCacheValid()) {
        _logDebug('📱 從本地快取載入動作...');
        final exercises = await _localCache.loadExercises();

        if (exercises.isNotEmpty) {
          _allExercisesCache = exercises;
          final duration = DateTime.now().difference(startTime);
          _logDebug(
              '✅ 從本地快取載入 ${exercises.length} 個動作（耗時 ${duration.inMilliseconds}ms）');
          _isPreloading = false;
          return;
        }
      }

      // 本地無資料，從 Supabase 下載
      _logDebug('☁️  本地無資料，從 Supabase 下載...');

      final response = await _dataLoader.loadAllExercises();
      final exercises = _dataParser.parseExerciseList(response);

      // 快取到記憶體
      _allExercisesCache = exercises;

      // 保存到本地存儲
      unawaited(_localCache.saveExercises(exercises));

      final duration = DateTime.now().difference(startTime);
      _logDebug(
          '✅ 從 Supabase 下載並快取 ${exercises.length} 個動作（耗時 ${duration.inMilliseconds}ms）');
      _isPreloading = false;
    } catch (e) {
      _logDebug('預載入所有動作失敗: $e');
      _isPreloading = false;
    }
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      debugPrint('[EXERCISE_PRELOAD] $message');
    }
  }
}

