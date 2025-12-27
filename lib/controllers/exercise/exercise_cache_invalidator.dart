import 'exercise_cache_manager.dart';

/// 運動緩存失效管理器
///
/// 當選擇條件變化時，智能清除受影響的緩存
class ExerciseCacheInvalidator {
  final ExerciseCacheManager _cacheManager;
  
  ExerciseCacheInvalidator(this._cacheManager);
  
  /// 當選擇條件變化時清除受影響的緩存
  /// 
  /// [changedSelection] 可以是 'type', 'bodyPart', 'level1' 等
  void clearCacheOnSelectionChange(String changedSelection, {Function(String)? logDebug}) {
    switch (changedSelection) {
      case 'type':
      case 'bodyPart':
        // 訓練類型或身體部位變化時，清除所有層級緩存和運動緩存
        _cacheManager.clearCache('categories');
        _cacheManager.clearCache('exercises');
        logDebug?.call('選擇$changedSelection已變化，清除所有分類和運動緩存');
        break;
      case 'level1':
        // level1變化時，清除level2及以上層級和運動緩存
        _cacheManager.clearLevelCache(2);
        _cacheManager.clearLevelCache(3);
        _cacheManager.clearLevelCache(4);
        _cacheManager.clearLevelCache(5);
        _cacheManager.clearCache('exercises');
        logDebug?.call('選擇level1已變化，清除level2+和運動緩存');
        break;
      case 'level2':
        // level2變化時，清除level3及以上層級和運動緩存
        _cacheManager.clearLevelCache(3);
        _cacheManager.clearLevelCache(4);
        _cacheManager.clearLevelCache(5);
        _cacheManager.clearCache('exercises');
        logDebug?.call('選擇level2已變化，清除level3+和運動緩存');
        break;
      case 'level3':
        // level3變化時，清除level4及以上層級和運動緩存
        _cacheManager.clearLevelCache(4);
        _cacheManager.clearLevelCache(5);
        _cacheManager.clearCache('exercises');
        logDebug?.call('選擇level3已變化，清除level4+和運動緩存');
        break;
      case 'level4':
        // level4變化時，清除level5和運動緩存
        _cacheManager.clearLevelCache(5);
        _cacheManager.clearCache('exercises');
        logDebug?.call('選擇level4已變化，清除level5和運動緩存');
        break;
      case 'level5':
        // level5變化時，只清除運動緩存
        _cacheManager.clearCache('exercises');
        logDebug?.call('選擇level5已變化，清除運動緩存');
        break;
    }
  }
}

