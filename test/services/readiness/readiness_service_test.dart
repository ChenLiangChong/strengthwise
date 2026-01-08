import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/readiness/daily_readiness_model.dart';
import 'package:strengthwise/services/interfaces/i_readiness_service.dart';

import '../../mocks/mock_services.dart';

/// ReadinessService 測試
///
/// P2 優先級 - 8 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md #P2
void main() {
  late MockReadinessService mockService;

  // 測試用的模型資料
  final testReadiness = DailyReadinessModel(
    id: 'readiness-001',
    userId: 'user-001',
    appointmentId: 'apt-001',
    logDate: DateTime(2025, 12, 15),
    readinessScore: 75,
    trafficLight: TrafficLight.green,
    metrics: const ReadinessMetrics(
      sleepQuality: 4,
      sleepHours: 7.5,
      soreness: 3,
      stress: 4,
      energyLevel: 5,
    ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockReadinessService();
  });

  group('IReadinessService', () {
    // =========================================================================
    // P2-141: getByAppointmentId
    // =========================================================================
    group('getByAppointmentId', () {
      test('找到問卷時返回 DailyReadinessModel', () async {
        // Arrange
        when(() => mockService.getByAppointmentId('apt-001'))
            .thenAnswer((_) async => testReadiness);

        // Act
        final result = await mockService.getByAppointmentId('apt-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'readiness-001');
        verify(() => mockService.getByAppointmentId('apt-001')).called(1);
      });

      test('找不到問卷時返回 null', () async {
        // Arrange
        when(() => mockService.getByAppointmentId('not-exist'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getByAppointmentId('not-exist');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // P2-142: getByUserAndDate
    // =========================================================================
    group('getByUserAndDate', () {
      test('找到指定日期的問卷', () async {
        // Arrange
        final date = DateTime(2025, 12, 15);
        when(() => mockService.getByUserAndDate('user-001', date))
            .thenAnswer((_) async => testReadiness);

        // Act
        final result = await mockService.getByUserAndDate('user-001', date);

        // Assert
        expect(result, isNotNull);
        expect(result!.logDate.day, 15);
      });
    });

    // =========================================================================
    // P2-143: getRecentByUser
    // =========================================================================
    group('getRecentByUser', () {
      test('返回用戶最近的問卷列表', () async {
        // Arrange
        when(() => mockService.getRecentByUser('user-001', limit: 5))
            .thenAnswer((_) async => [testReadiness]);

        // Act
        final result = await mockService.getRecentByUser('user-001', limit: 5);

        // Assert
        expect(result.length, 1);
        expect(result[0].userId, 'user-001');
      });

      test('無問卷時返回空列表', () async {
        // Arrange
        when(() => mockService.getRecentByUser('no-data', limit: 10))
            .thenAnswer((_) async => []);

        // Act
        final result = await mockService.getRecentByUser('no-data', limit: 10);

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // P2-144: createReadiness
    // =========================================================================
    group('createReadiness', () {
      test('建立新問卷並返回計算後結果', () async {
        // Arrange
        final newReadiness = testReadiness.copyWith(
          id: '',
          readinessScore: null,
          trafficLight: null,
        );
        final createdReadiness = testReadiness.copyWith(
          id: 'new-001',
          readinessScore: 75,
          trafficLight: TrafficLight.green,
        );
        when(() => mockService.createReadiness(any()))
            .thenAnswer((_) async => createdReadiness);

        // Act
        final result = await mockService.createReadiness(newReadiness);

        // Assert
        expect(result.id, 'new-001');
        expect(result.readinessScore, isNotNull);
        expect(result.trafficLight, isNotNull);
      });
    });

    // =========================================================================
    // P2-145: updateReadiness
    // =========================================================================
    group('updateReadiness', () {
      test('更新問卷並返回結果', () async {
        // Arrange
        final updated = testReadiness.copyWith(readinessScore: 80);
        when(() => mockService.updateReadiness(any()))
            .thenAnswer((_) async => updated);

        // Act
        final result = await mockService.updateReadiness(testReadiness);

        // Assert
        expect(result.readinessScore, 80);
      });
    });

    // =========================================================================
    // P2-146: getClientReadiness
    // =========================================================================
    group('getClientReadiness', () {
      test('教練取得學員問卷', () async {
        // Arrange
        when(() => mockService.getClientReadiness(
              coachId: 'coach-001',
              clientId: 'user-001',
              appointmentId: 'apt-001',
            )).thenAnswer((_) async => testReadiness);

        // Act
        final result = await mockService.getClientReadiness(
          coachId: 'coach-001',
          clientId: 'user-001',
          appointmentId: 'apt-001',
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.userId, 'user-001');
      });
    });

    // =========================================================================
    // P2-147: batchGetLatestReadiness
    // =========================================================================
    group('batchGetLatestReadiness', () {
      test('批次取得多位學員問卷', () async {
        // Arrange
        when(() =>
                mockService.batchGetLatestReadiness(['user-001', 'user-002']))
            .thenAnswer((_) async => {
                  'user-001': testReadiness,
                  'user-002': null,
                });

        // Act
        final result =
            await mockService.batchGetLatestReadiness(['user-001', 'user-002']);

        // Assert
        expect(result.length, 2);
        expect(result['user-001'], isNotNull);
        expect(result['user-002'], isNull);
      });
    });

    // =========================================================================
    // P2-148: calculateReadinessScore
    // =========================================================================
    group('calculateReadinessScore', () {
      test('計算準備度分數和紅綠燈', () {
        // Arrange
        const metrics = ReadinessMetrics(
          sleepQuality: 4,
          sleepHours: 7.5,
          soreness: 3,
          stress: 4,
          energyLevel: 5,
        );
        when(() => mockService.calculateReadinessScore(metrics))
            .thenReturn({'score': 75, 'trafficLight': TrafficLight.green});

        // Act
        final result = mockService.calculateReadinessScore(metrics);

        // Assert
        expect(result['score'], 75);
        expect(result['trafficLight'], TrafficLight.green);
      });

      test('低分返回紅燈', () {
        // Arrange
        const metrics = ReadinessMetrics(
          sleepQuality: 1,
          sleepHours: 4.0,
          soreness: 1,
          stress: 1,
          energyLevel: 1,
        );
        when(() => mockService.calculateReadinessScore(metrics))
            .thenReturn({'score': 30, 'trafficLight': TrafficLight.red});

        // Act
        final result = mockService.calculateReadinessScore(metrics);

        // Assert
        expect(result['score'], 30);
        expect(result['trafficLight'], TrafficLight.red);
      });
    });
  });
}
