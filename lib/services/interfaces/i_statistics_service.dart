import '../../models/statistics_model.dart';

/// 統計服務介面
///
/// 提供訓練數據統計和分析功能
abstract class IStatisticsService {
  /// 獲取完整的統計數據
  ///
  /// [userId] 用戶 ID
  /// [timeRange] 時間範圍
  Future<StatisticsData> getStatistics(String userId, TimeRange timeRange);

  /// 獲取訓練頻率統計
  ///
  /// [userId] 用戶 ID
  /// [timeRange] 時間範圍
  Future<TrainingFrequency> getTrainingFrequency(String userId, TimeRange timeRange);

  /// 獲取訓練量歷史數據
  ///
  /// [userId] 用戶 ID
  /// [timeRange] 時間範圍
  Future<List<TrainingVolumePoint>> getVolumeHistory(String userId, TimeRange timeRange);

  /// 獲取身體部位統計
  ///
  /// [userId] 用戶 ID
  /// [timeRange] 時間範圍
  Future<List<BodyPartStats>> getBodyPartStats(String userId, TimeRange timeRange);

  /// 獲取特定肌群細節
  ///
  /// [userId] 用戶 ID
  /// [bodyPart] 身體部位
  /// [timeRange] 時間範圍
  Future<List<SpecificMuscleStats>> getSpecificMuscleStats(
    String userId,
    String bodyPart,
    TimeRange timeRange,
  );

  /// 獲取訓練類型統計
  ///
  /// [userId] 用戶 ID
  /// [timeRange] 時間範圍
  Future<List<TrainingTypeStats>> getTrainingTypeStats(String userId, TimeRange timeRange);

  /// 獲取器材使用統計
  ///
  /// [userId] 用戶 ID
  /// [timeRange] 時間範圍
  Future<List<EquipmentStats>> getEquipmentStats(String userId, TimeRange timeRange);

  /// 獲取個人最佳記錄列表
  ///
  /// [userId] 用戶 ID
  /// [limit] 返回數量限制
  Future<List<PersonalRecord>> getPersonalRecords(String userId, {int limit = 20});

  /// 獲取力量進步追蹤
  ///
  /// [userId] 用戶 ID
  /// [timeRange] 時間範圍
  /// [limit] 返回動作數量限制
  Future<List<ExerciseStrengthProgress>> getStrengthProgress(
    String userId,
    TimeRange timeRange, {
    int limit = 10,
  });

  /// 獲取肌群平衡分析
  ///
  /// [userId] 用戶 ID
  /// [timeRange] 時間範圍
  Future<MuscleGroupBalance> getMuscleGroupBalance(String userId, TimeRange timeRange);

  /// 獲取訓練日曆數據
  ///
  /// [userId] 用戶 ID
  /// [timeRange] 時間範圍
  Future<TrainingCalendarData> getTrainingCalendar(String userId, TimeRange timeRange);

  /// 獲取完成率統計
  ///
  /// [userId] 用戶 ID
  /// [timeRange] 時間範圍
  Future<CompletionRateStats> getCompletionRate(String userId, TimeRange timeRange);

  /// 獲取訓練建議
  ///
  /// [statisticsData] 統計數據
  List<TrainingSuggestion> getTrainingSuggestions(StatisticsData statisticsData);

  /// 清除快取
  void clearCache();
}

