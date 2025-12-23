import 'package:flutter/foundation.dart';
import '../models/statistics_model.dart';
import '../services/interfaces/i_statistics_service.dart';
import '../services/error_handling_service.dart';
import 'interfaces/i_statistics_controller.dart';

/// 統計控制器實作
///
/// 管理統計數據的載入和狀態
class StatisticsController extends ChangeNotifier implements IStatisticsController {
  final IStatisticsService _statisticsService;
  final ErrorHandlingService _errorService;

  // 狀態
  bool _isLoading = false;
  String? _errorMessage;
  TimeRange _timeRange = TimeRange.week;
  StatisticsData? _statisticsData;
  List<TrainingSuggestion> _suggestions = [];

  // 當前用戶 ID
  String? _userId;

  StatisticsController({
    required IStatisticsService statisticsService,
    required ErrorHandlingService errorService,
  })  : _statisticsService = statisticsService,
        _errorService = errorService;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  TimeRange get timeRange => _timeRange;

  @override
  StatisticsData? get statisticsData => _statisticsData;

  @override
  List<TrainingSuggestion> get suggestions => _suggestions;

  @override
  bool get hasData => _statisticsData != null && _statisticsData!.hasData;

  /// 初始化統計數據
  ///
  /// [userId] 用戶 ID
  /// [initialTimeRange] 初始時間範圍
  @override
  Future<void> initialize(String userId, {TimeRange? initialTimeRange}) async {
    _userId = userId;
    if (initialTimeRange != null) {
      _timeRange = initialTimeRange;
    }
    // 立即載入統計數據
    await loadStatistics(_timeRange);
  }

  @override
  Future<void> loadStatistics(TimeRange timeRange) async {
    if (_userId == null) {
      _errorMessage = '用戶未登入';
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      _timeRange = timeRange;
      notifyListeners();

      // 載入統計數據
      _statisticsData = await _statisticsService.getStatistics(_userId!, timeRange);

      // 生成訓練建議
      _suggestions = _statisticsService.getTrainingSuggestions(_statisticsData!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorService.logError('載入統計數據失敗: $e', type: 'StatisticsControllerError');
      _errorMessage = '載入統計數據失敗，請稍後再試';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> refreshStatistics() async {
    // 清除快取並重新載入
    _statisticsService.clearCache();
    await loadStatistics(_timeRange);
  }

  @override
  Future<void> changeTimeRange(TimeRange newTimeRange) async {
    if (newTimeRange == _timeRange) return;
    await loadStatistics(newTimeRange);
  }

  @override
  void clearCache() {
    _statisticsService.clearCache();
    _statisticsData = null;
    _suggestions = [];
    notifyListeners();
  }

  /// 獲取身體部位詳細統計
  ///
  /// [bodyPart] 身體部位名稱
  Future<List<SpecificMuscleStats>> getBodyPartDetails(String bodyPart) async {
    if (_userId == null) return [];

    try {
      return await _statisticsService.getSpecificMuscleStats(
        _userId!,
        bodyPart,
        _timeRange,
      );
    } catch (e) {
      _errorService.logError('載入肌群詳情失敗: $e', type: 'StatisticsControllerError');
      return [];
    }
  }

  @override
  void dispose() {
    _userId = null;
    super.dispose();
  }
}

