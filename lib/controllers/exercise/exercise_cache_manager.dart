/// 運動數據緩存管理器
///
/// 管理運動相關的本地緩存，包括分類、運動列表和運動詳情
class ExerciseCacheManager {
  // 數據緩存
  final Map<String, List<String>> _categoriesCache = {};
  final Map<String, List<dynamic>> _exercisesCache = {};
  List<String>? _exerciseTypes;
  List<String>? _bodyParts;
  final Map<String, dynamic> _exerciseDetailsCache = {};
  
  /// 獲取緩存的訓練類型
  List<String>? get exerciseTypes => _exerciseTypes;
  
  /// 設置訓練類型緩存
  set exerciseTypes(List<String>? value) {
    _exerciseTypes = value;
  }
  
  /// 獲取緩存的身體部位
  List<String>? get bodyParts => _bodyParts;
  
  /// 設置身體部位緩存
  set bodyParts(List<String>? value) {
    _bodyParts = value;
  }
  
  /// 獲取緩存的分類
  List<String>? getCategoriesByKey(String key) {
    return _categoriesCache[key];
  }
  
  /// 設置分類緩存
  void setCategoriesByKey(String key, List<String> categories) {
    _categoriesCache[key] = categories;
  }
  
  /// 獲取緩存的運動列表
  List<dynamic>? getExercisesByKey(String key) {
    return _exercisesCache[key];
  }
  
  /// 設置運動列表緩存
  void setExercisesByKey(String key, List<dynamic> exercises) {
    _exercisesCache[key] = exercises;
  }
  
  /// 獲取運動詳情
  dynamic getExerciseDetails(String exerciseId) {
    return _exerciseDetailsCache[exerciseId];
  }
  
  /// 設置運動詳情
  void setExerciseDetails(String exerciseId, dynamic exercise) {
    _exerciseDetailsCache[exerciseId] = exercise;
  }
  
  /// 檢查運動詳情是否已緩存
  bool hasExerciseDetails(String exerciseId) {
    return _exerciseDetailsCache.containsKey(exerciseId);
  }
  
  /// 清除特定類型的緩存
  void clearCache(String cacheType) {
    switch (cacheType) {
      case 'all':
        _categoriesCache.clear();
        _exercisesCache.clear();
        _exerciseTypes = null;
        _bodyParts = null;
        _exerciseDetailsCache.clear();
        break;
      case 'categories':
        _categoriesCache.clear();
        break;
      case 'exercises':
        _exercisesCache.clear();
        break;
      case 'details':
        _exerciseDetailsCache.clear();
        break;
    }
  }
  
  /// 清除特定層級的分類緩存
  void clearLevelCache(int level) {
    final keysToRemove = <String>[];
    
    for (var key in _categoriesCache.keys) {
      if (key.startsWith('level$level')) {
        keysToRemove.add(key);
      }
    }
    
    for (var key in keysToRemove) {
      _categoriesCache.remove(key);
    }
  }
}

