import 'dart:async';
import '../../../models/custom_exercise_model.dart';

/// 自訂動作快取管理器
class CustomExerciseCacheManager {
  List<CustomExercise>? _userExercisesCache;
  DateTime? _userExercisesCacheTime;
  final Map<String, CustomExercise> _exerciseCache = {};
  
  int _cacheDuration = 5; // 分鐘
  Timer? _cacheClearTimer;

  void configure(int duration) {
    _cacheDuration = duration;
  }

  /// 檢查列表快取是否有效
  bool isListCacheValid() {
    if (_userExercisesCache == null || _userExercisesCacheTime == null) {
      return false;
    }
    final cacheAge = DateTime.now().difference(_userExercisesCacheTime!);
    return cacheAge.inMinutes < _cacheDuration;
  }

  /// 取得列表快取
  List<CustomExercise>? getListCache() => _userExercisesCache;

  /// 更新列表快取
  void updateListCache(List<CustomExercise> exercises) {
    _userExercisesCache = exercises;
    _userExercisesCacheTime = DateTime.now();
    
    for (final exercise in exercises) {
      _exerciseCache[exercise.id] = exercise;
    }
  }

  /// 新增動作到快取
  void addExercise(CustomExercise exercise) {
    _exerciseCache[exercise.id] = exercise;
    
    if (_userExercisesCache != null) {
      _userExercisesCache = [exercise, ..._userExercisesCache!];
      _userExercisesCacheTime = DateTime.now();
    }
  }

  /// 移除動作快取
  void removeExercise(String exerciseId) {
    _exerciseCache.remove(exerciseId);
    
    if (_userExercisesCache != null) {
      _userExercisesCache = _userExercisesCache!
          .where((exercise) => exercise.id != exerciseId)
          .toList();
      _userExercisesCacheTime = DateTime.now();
    }
  }

  /// 清除快取（更新後）
  void invalidate(String? exerciseId) {
    if (exerciseId != null) {
      _exerciseCache.remove(exerciseId);
    }
    _userExercisesCache = null;
    _userExercisesCacheTime = null;
  }

  /// 清除所有快取
  void clearAll() {
    _userExercisesCache = null;
    _userExercisesCacheTime = null;
    _exerciseCache.clear();
  }

  /// 設置緩存清理計時器
  void setupCacheCleanupTimer() {
    _cacheClearTimer?.cancel();
    _cacheClearTimer = Timer.periodic(const Duration(hours: 1), (_) {
      clearAll();
    });
  }

  /// 釋放資源
  void dispose() {
    _cacheClearTimer?.cancel();
    _cacheClearTimer = null;
    clearAll();
  }
}

