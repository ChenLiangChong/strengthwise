import 'package:flutter/foundation.dart';
import '../../models/statistics_model.dart';

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
}

