import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/controllers/statistics_controller.dart';
import 'package:strengthwise/models/statistics_model.dart';
import 'package:strengthwise/services/interfaces/i_statistics_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';

// Mock 類別
class MockStatisticsService extends Mock implements IStatisticsService {}

class MockErrorHandlingService extends Mock implements ErrorHandlingService {}

/// StatisticsController 測試
void main() {
  late MockStatisticsService mockStatisticsService;
  late MockErrorHandlingService mockErrorHandlingService;
  late StatisticsController controller;

  // 使用 factory 建立測試資料
  StatisticsData createTestStatisticsData() {
    return StatisticsData.empty(TimeRange.week);
  }

  setUpAll(() {
    registerFallbackValue(TimeRange.week);
    registerFallbackValue(StatisticsData.empty(TimeRange.week));
  });

  setUp(() {
    mockStatisticsService = MockStatisticsService();
    mockErrorHandlingService = MockErrorHandlingService();

    final testData = createTestStatisticsData();

    // 預設 mock 行為
    when(() => mockStatisticsService.hasCachedStatistics(any(), any()))
        .thenAnswer((_) async => false);
    when(() => mockStatisticsService.getStatistics(any(), any()))
        .thenAnswer((_) async => testData);
    when(() => mockStatisticsService.getTrainingSuggestions(any()))
        .thenReturn([]);
    when(() => mockStatisticsService.preloadAllTimeRanges(any(),
            currentTimeRange: any(named: 'currentTimeRange')))
        .thenAnswer((_) async {});
    when(() => mockStatisticsService.clearCache()).thenReturn(null);

    controller = StatisticsController(
      statisticsService: mockStatisticsService,
      errorService: mockErrorHandlingService,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('StatisticsController 初始狀態', () {
    test('初始 isLoading 應該為 false', () {
      expect(controller.isLoading, isFalse);
    });

    test('初始 errorMessage 應該為 null', () {
      expect(controller.errorMessage, isNull);
    });

    test('初始 timeRange 應該為 week', () {
      expect(controller.timeRange, TimeRange.week);
    });

    test('初始 statisticsData 應該為 null', () {
      expect(controller.statisticsData, isNull);
    });

    test('初始 hasData 應該為 false', () {
      expect(controller.hasData, isFalse);
    });
  });

  group('StatisticsController.initialize', () {
    test('應該設定 userId 並載入統計數據', () async {
      await controller.initialize('user-001');

      verify(() =>
              mockStatisticsService.getStatistics('user-001', TimeRange.week))
          .called(1);
      expect(controller.statisticsData, isNotNull);
    });

    test('應該使用指定的初始時間範圍', () async {
      await controller.initialize('user-001',
          initialTimeRange: TimeRange.month);

      verify(() =>
              mockStatisticsService.getStatistics('user-001', TimeRange.month))
          .called(1);
      expect(controller.timeRange, TimeRange.month);
    });

    test('初始化後應該預載入其他時間範圍', () async {
      await controller.initialize('user-001');

      verify(() => mockStatisticsService.preloadAllTimeRanges(
            'user-001',
            currentTimeRange: TimeRange.week,
          )).called(1);
    });
  });

  group('StatisticsController.initializeMinimal', () {
    test('應該只載入本週數據', () async {
      await controller.initializeMinimal('user-001');

      verify(() =>
              mockStatisticsService.getStatistics('user-001', TimeRange.week))
          .called(1);
      expect(controller.timeRange, TimeRange.week);
    });

    test('不應該預載入其他時間範圍', () async {
      await controller.initializeMinimal('user-001');

      verifyNever(() => mockStatisticsService.preloadAllTimeRanges(
            any(),
            currentTimeRange: any(named: 'currentTimeRange'),
          ));
    });
  });

  group('StatisticsController.loadStatistics', () {
    test('userId 為 null 時應該設定錯誤訊息', () async {
      await controller.loadStatistics(TimeRange.week);

      expect(controller.errorMessage, '用戶未登入');
    });

    test('無快取時應該顯示 loading', () async {
      when(() => mockStatisticsService.hasCachedStatistics(any(), any()))
          .thenAnswer((_) async => false);

      await controller.initialize('user-001');

      // 驗證 getStatistics 被呼叫
      verify(() => mockStatisticsService.getStatistics(any(), any())).called(1);
    });

    test('載入失敗時應該設定錯誤訊息', () async {
      when(() => mockStatisticsService.getStatistics(any(), any()))
          .thenThrow(Exception('Network error'));
      when(() => mockErrorHandlingService.logError(any(),
          type: any(named: 'type'))).thenReturn(null);

      await controller.initialize('user-001');

      expect(controller.errorMessage, contains('失敗'));
      expect(controller.isLoading, isFalse);
    });
  });

  group('StatisticsController.changeTimeRange', () {
    test('切換相同時間範圍不應該重新載入', () async {
      await controller.initialize('user-001');
      clearInteractions(mockStatisticsService);

      await controller.changeTimeRange(TimeRange.week);

      verifyNever(() => mockStatisticsService.getStatistics(any(), any()));
    });

    test('切換不同時間範圍應該重新載入', () async {
      await controller.initialize('user-001');
      clearInteractions(mockStatisticsService);

      when(() => mockStatisticsService.hasCachedStatistics(any(), any()))
          .thenAnswer((_) async => false);

      await controller.changeTimeRange(TimeRange.month);

      verify(() =>
              mockStatisticsService.getStatistics('user-001', TimeRange.month))
          .called(1);
    });
  });

  group('StatisticsController.refreshStatistics', () {
    test('應該清除快取並重新載入', () async {
      await controller.initialize('user-001');
      clearInteractions(mockStatisticsService);

      when(() => mockStatisticsService.hasCachedStatistics(any(), any()))
          .thenAnswer((_) async => false);

      await controller.refreshStatistics();

      verify(() => mockStatisticsService.clearCache()).called(1);
      verify(() => mockStatisticsService.getStatistics(any(), any())).called(1);
    });
  });

  group('StatisticsController.clearCache', () {
    test('應該清除快取和數據', () async {
      await controller.initialize('user-001');

      controller.clearCache();

      verify(() => mockStatisticsService.clearCache()).called(1);
      expect(controller.statisticsData, isNull);
      expect(controller.suggestions, isEmpty);
    });
  });
}
