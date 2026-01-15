import 'package:flutter/foundation.dart';
import '../../models/statistics_model.dart';
import '../../models/favorite_exercise_model.dart'; // ⭐ v3.6: MVVM 查詢方法

/// 統計控制器介面
///
/// 管理統計數據的載入和狀態
abstract class IStatisticsController extends ChangeNotifier {
  /// 是否正在載入
  bool get isLoading;

  /// 錯誤訊息
  String? get errorMessage;

  /// 當前時間範圍
  TimeRange get timeRange;

  /// 統計數據
  StatisticsData? get statisticsData;

  /// 訓練建議
  List<TrainingSuggestion> get suggestions;

  /// 是否有數據
  bool get hasData;

  /// 初始化統計數據
  ///
  /// [userId] 用戶 ID
  /// [initialTimeRange] 初始時間範圍
  Future<void> initialize(String userId, {TimeRange? initialTimeRange});

  /// ⚡ 最小化初始化（僅載入本週數據，不預載入其他時間範圍）
  ///
  /// 用於首頁快速預載入，減少主線程阻塞
  Future<void> initializeMinimal(String userId);

  /// 載入統計數據
  ///
  /// [timeRange] 時間範圍
  Future<void> loadStatistics(TimeRange timeRange);

  /// 刷新統計數據
  Future<void> refreshStatistics();

  /// 切換時間範圍
  Future<void> changeTimeRange(TimeRange newTimeRange);

  /// 清除快取
  void clearCache();

  // =============================================
  // ⭐ v3.6: MVVM 查詢方法（View 層透過 Controller 調用）
  // =============================================

  /// 獲取力量進步數據
  Future<List<ExerciseStrengthProgress>> getStrengthProgress(
    String userId,
    TimeRange timeRange, {
    int limit = 1000,
  });

  /// 獲取有訓練記錄的動作列表
  Future<List<ExerciseWithRecord>> getExercisesWithRecords(
    String userId, {
    TimeRange? timeRange,
  });

  /// 清除統計快取
  void clearStatisticsCache();

  /// 預熱統計快取（從 Hive 載入到記憶體）
  Future<void> warmupFromLocalCache(String userId);

  /// 預載入所有時間範圍的統計數據
  Future<void> preloadAllTimeRanges(String userId);

  /// 查詢統計數據（直接返回結果）
  ///
  /// 用於 Session Mode 等需要直接獲取數據的場景
  Future<StatisticsData?> getStatistics(String userId, TimeRange timeRange);
}

