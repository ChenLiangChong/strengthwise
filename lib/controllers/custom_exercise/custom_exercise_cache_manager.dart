import '../../models/custom_exercise_model.dart';

/// 自定義動作緩存管理器
class CustomExerciseCacheManager {
  // 數據緩存
  List<CustomExercise>? _userExercisesCache;
  DateTime? _lastCacheRefreshTime;

  /// 緩存的用戶自定義動作
  List<CustomExercise> get cachedExercises => _userExercisesCache ?? [];

  /// 檢查是否需要刷新緩存
  /// 
  /// 默認5分鐘後需要刷新
  bool shouldRefresh() {
    if (_lastCacheRefreshTime == null || _userExercisesCache == null) {
      return true;
    }
    
    final now = DateTime.now();
    return now.difference(_lastCacheRefreshTime!).inMinutes > 5;
  }

  /// 更新緩存
  void updateCache(List<CustomExercise> exercises) {
    _userExercisesCache = exercises;
    _lastCacheRefreshTime = DateTime.now();
  }

  /// 添加自定義動作到緩存
  void addToCache(CustomExercise exercise) {
    if (_userExercisesCache != null) {
      _userExercisesCache = [..._userExercisesCache!, exercise];
    }
  }

  /// 從緩存中移除動作
  void removeFromCache(String exerciseId) {
    if (_userExercisesCache != null) {
      _userExercisesCache = _userExercisesCache!
          .where((exercise) => exercise.id != exerciseId)
          .toList();
    }
  }

  /// 清除緩存
  void clearCache() {
    _userExercisesCache = null;
    _lastCacheRefreshTime = null;
  }
}

