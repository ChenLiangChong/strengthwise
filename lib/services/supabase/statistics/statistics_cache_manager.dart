import '../../../models/statistics_model.dart';
import 'statistics_models.dart';

/// 統計快取管理器
///
/// 管理統計數據的快取（記憶體層）
class StatisticsCacheManager {
  // 訓練數據快取
  List<UnifiedWorkoutData>? _cachedWorkouts;
  String? _cachedWorkoutsUserId;
  DateTime? _cachedWorkoutsStartDate;
  DateTime? _cachedWorkoutsEndDate;

  // 動作記錄列表快取（未使用，預留給未來）
  // static const int _exerciseCacheVersion = 2;
  // List<ExerciseWithRecord>? _cachedExercisesWithRecords;
  // String? _cachedExercisesUserId;
  // Set<String>? _cachedSystemExerciseIds;
  // int? _cachedExercisesVersion;

  // 個人記錄快取
  List<PersonalRecord>? _personalRecordsCache;
  DateTime? _prCacheTime;
  String? _prCachedUserId;

  // 力量進步多時間範圍快取
  final Map<String, _StrengthProgressCache> _strengthProgressCache = {};

  // 統計數據多時間範圍快取
  final Map<String, _StatisticsCache> _statisticsDataCache = {};

  /// 檢查訓練數據快取是否有效
  bool isWorkoutsCacheValid(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _cachedWorkouts != null &&
        _cachedWorkoutsUserId == userId &&
        _cachedWorkoutsStartDate != null &&
        _cachedWorkoutsEndDate != null &&
        _isSameDay(_cachedWorkoutsStartDate!, startDate) &&
        _isSameDay(_cachedWorkoutsEndDate!, endDate);
  }

  /// 取得快取的訓練數據
  List<UnifiedWorkoutData>? getCachedWorkouts() => _cachedWorkouts;

  /// 更新訓練數據快取
  void cacheWorkouts(
    String userId,
    DateTime startDate,
    DateTime endDate,
    List<UnifiedWorkoutData> workouts,
  ) {
    _cachedWorkouts = workouts;
    _cachedWorkoutsUserId = userId;
    _cachedWorkoutsStartDate = startDate;
    _cachedWorkoutsEndDate = endDate;
  }

  /// 檢查個人記錄快取是否有效
  bool isPersonalRecordsCacheValid(String userId) {
    return _personalRecordsCache != null &&
        _prCachedUserId == userId &&
        _prCacheTime != null &&
        DateTime.now().difference(_prCacheTime!).inMinutes < 5;
  }

  /// 取得快取的個人記錄
  List<PersonalRecord>? getCachedPersonalRecords() => _personalRecordsCache;

  /// 更新個人記錄快取
  void cachePersonalRecords(String userId, List<PersonalRecord> records) {
    _personalRecordsCache = records;
    _prCacheTime = DateTime.now();
    _prCachedUserId = userId;
  }

  /// 檢查統計數據快取是否有效
  bool isStatisticsCacheValid(String userId, TimeRange timeRange) {
    final cacheKey = '${userId}_${timeRange.name}';
    final cache = _statisticsDataCache[cacheKey];
    return cache != null && cache.isValid(userId);
  }

  /// 取得快取的統計數據
  StatisticsData? getCachedStatistics(String userId, TimeRange timeRange) {
    final cacheKey = '${userId}_${timeRange.name}';
    return _statisticsDataCache[cacheKey]?.data;
  }

  /// 更新統計數據快取
  void cacheStatistics(String userId, TimeRange timeRange, StatisticsData data) {
    final cacheKey = '${userId}_${timeRange.name}';
    _statisticsDataCache[cacheKey] = _StatisticsCache(
      data: data,
      cacheTime: DateTime.now(),
      userId: userId,
    );
  }

  /// 檢查力量進步快取是否有效
  bool isStrengthProgressCacheValid(
      String userId, TimeRange timeRange, int limit) {
    final cacheKey = '${userId}_${timeRange.name}_$limit';
    final cache = _strengthProgressCache[cacheKey];
    return cache != null && cache.isValid(userId);
  }

  /// 取得快取的力量進步數據
  List<ExerciseStrengthProgress>? getCachedStrengthProgress(
      String userId, TimeRange timeRange, int limit) {
    final cacheKey = '${userId}_${timeRange.name}_$limit';
    return _strengthProgressCache[cacheKey]?.data;
  }

  /// 更新力量進步快取
  void cacheStrengthProgress(String userId, TimeRange timeRange, int limit,
      List<ExerciseStrengthProgress> data) {
    final cacheKey = '${userId}_${timeRange.name}_$limit';
    _strengthProgressCache[cacheKey] = _StrengthProgressCache(
      data: data,
      cacheTime: DateTime.now(),
      userId: userId,
    );
  }

  // 動作記錄快取相關方法已移除（暫不實作）

  /// 清除所有快取
  void clearAll() {
    _cachedWorkouts = null;
    _cachedWorkoutsUserId = null;
    _cachedWorkoutsStartDate = null;
    _cachedWorkoutsEndDate = null;

    _personalRecordsCache = null;
    _prCacheTime = null;
    _prCachedUserId = null;

    _strengthProgressCache.clear();
    _statisticsDataCache.clear();
  }

  /// 檢查兩個日期是否為同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

/// 統計數據快取項（內部）
class _StatisticsCache {
  final StatisticsData data;
  final DateTime cacheTime;
  final String userId;

  _StatisticsCache({
    required this.data,
    required this.cacheTime,
    required this.userId,
  });

  /// 快取是否有效（5 分鐘內）
  bool isValid(String currentUserId) {
    return userId == currentUserId &&
        DateTime.now().difference(cacheTime).inMinutes < 5;
  }
}

/// 力量進步快取項（內部使用）
class _StrengthProgressCache {
  final List<ExerciseStrengthProgress> data;
  final DateTime cacheTime;
  final String userId;

  _StrengthProgressCache({
    required this.data,
    required this.cacheTime,
    required this.userId,
  });

  /// 快取是否有效（5 分鐘內）
  bool isValid(String currentUserId) {
    return userId == currentUserId &&
        DateTime.now().difference(cacheTime).inMinutes < 5;
  }
}

