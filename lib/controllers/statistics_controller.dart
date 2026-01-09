import 'package:flutter/foundation.dart';
import '../models/statistics_model.dart';
import '../services/interfaces/i_statistics_service.dart';
import '../services/core/error_handling_service.dart';
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
    
    // ⚡ 首次初始化後，後台預載入其他時間範圍（只執行一次）
    _statisticsService.preloadAllTimeRanges(_userId!, currentTimeRange: _timeRange);
  }

  /// ⚡ 最小化初始化（僅載入本週數據，不預載入其他時間範圍）
  ///
  /// 用於首頁快速預載入，減少主線程阻塞
  @override
  Future<void> initializeMinimal(String userId) async {
    _userId = userId;
    _timeRange = TimeRange.week;
    
    // 只載入本週數據，不預載入其他時間範圍
    await loadStatistics(TimeRange.week);
    
    if (kDebugMode) {
      print('[StatisticsController] ⚡ 最小化初始化完成（僅本週）');
    }
  }

  @override
  Future<void> loadStatistics(TimeRange timeRange) async {
    if (_userId == null) {
      _errorMessage = '用戶未登入';
      notifyListeners();
      return;
    }

    try {
      // ⚡ v3.1.1 優化：檢查快取，有快取時不顯示 loading
      final hasCached = await _statisticsService.hasCachedStatistics(_userId!, timeRange);

      if (!hasCached) {
        // 沒有快取，顯示 loading
        _isLoading = true;
        _errorMessage = null;
        _timeRange = timeRange;
        notifyListeners();
      } else {
        // 有快取，先更新 timeRange（不顯示 loading）
        _timeRange = timeRange;
      }

      // 載入統計數據（有快取時會立即返回）
      _statisticsData = await _statisticsService.getStatistics(_userId!, timeRange);

      // 🐛 DEBUG: 輸出統計數據詳情
      if (kDebugMode) {
        print('\n========== 統計頁面 DEBUG ==========');
        print('📊 時間範圍: ${timeRange.displayName}');
        print('📊 訓練次數: ${_statisticsData?.frequency.totalWorkouts ?? 0}');
        print('📊 訓練天數: ${_statisticsData?.volumeHistory.length ?? 0}');
        print('📊 個人記錄數量: ${_statisticsData?.personalRecords.length ?? 0}');
        
        // 輸出個人記錄的 body_part 分布
        if (_statisticsData != null && _statisticsData!.personalRecords.isNotEmpty) {
          final bodyPartCount = <String, int>{};
          for (var pr in _statisticsData!.personalRecords) {
            bodyPartCount[pr.bodyPart] = (bodyPartCount[pr.bodyPart] ?? 0) + 1;
          }
          print('📊 個人記錄 body_part 分布:');
          bodyPartCount.forEach((bodyPart, count) {
            print('   - $bodyPart: $count 筆');
          });
        }
        
        // 輸出訓練量趨勢數據
        if (_statisticsData != null && _statisticsData!.volumeHistory.isNotEmpty) {
          print('📊 訓練量趨勢數據點:');
          for (var point in _statisticsData!.volumeHistory) {
            print('   - ${point.formattedDate}: 訓練 ${point.workoutCount} 次, 訓練量 ${point.totalVolume.toStringAsFixed(0)} kg');
          }
        }
        
        print('====================================\n');
      }

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

