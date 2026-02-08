import 'package:strengthwise/models/exercise/exercise.dart';

/// 運動數據緩存管理器
///
/// 管理運動相關的本地緩存：動作詳情 + 參照資料
class ExerciseCacheManager {
  // 動作詳情快取
  final Map<String, Exercise> _exerciseDetailsCache = {};

  // ⭐ v5.0: 參照資料快取（movementPatterns / muscleGroups / equipment）
  final Map<String, List<Map<String, String>>> _refDataCache = {};

  /// 獲取動作詳情
  Exercise? getExerciseDetails(String exerciseId) {
    return _exerciseDetailsCache[exerciseId];
  }

  /// 設置動作詳情
  void setExerciseDetails(String exerciseId, Exercise exercise) {
    _exerciseDetailsCache[exerciseId] = exercise;
  }

  /// 檢查動作詳情是否已緩存
  bool hasExerciseDetails(String exerciseId) {
    return _exerciseDetailsCache.containsKey(exerciseId);
  }

  /// 獲取參照資料快取
  List<Map<String, String>>? getRefData(String key) {
    return _refDataCache[key];
  }

  /// 設置參照資料快取
  void setRefData(String key, List<Map<String, String>> data) {
    _refDataCache[key] = data;
  }

  /// 清除所有快取
  void clearAll() {
    _exerciseDetailsCache.clear();
    _refDataCache.clear();
  }
}
