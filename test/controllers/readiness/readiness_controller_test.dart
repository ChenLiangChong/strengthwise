import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/controllers/readiness_controller.dart';
import 'package:strengthwise/models/readiness/daily_readiness_model.dart';
import 'package:strengthwise/services/interfaces/i_readiness_service.dart';
import 'package:strengthwise/services/interfaces/i_auth_service.dart';

// Mock Classes
class MockReadinessService extends Mock implements IReadinessService {}

class MockAuthService extends Mock implements IAuthService {}

/// ReadinessController 測試
///
/// P3 優先級 - 10 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md #P3
void main() {
  late MockReadinessService mockReadinessService;
  late MockAuthService mockAuthService;
  ReadinessController? controller;

  final testMetrics = ReadinessMetrics(
    sleepQuality: 4,
    sleepHours: 7.5,
    soreness: 3,
    stress: 4,
    energyLevel: 5,
  );

  final testReadiness = DailyReadinessModel(
    id: 'readiness-001',
    userId: 'user-001',
    logDate: DateTime.now(),
    metrics: testMetrics,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    // 註冊所有 fallback values
    registerFallbackValue(DailyReadinessModel(
      id: 'fallback',
      userId: 'fallback',
      logDate: DateTime.now(),
      metrics: const ReadinessMetrics(
        sleepQuality: 3,
        sleepHours: 7.0,
        soreness: 3,
        stress: 3,
        energyLevel: 3,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    registerFallbackValue(const ReadinessMetrics(
      sleepQuality: 3,
      sleepHours: 7.0,
      soreness: 3,
      stress: 3,
      energyLevel: 3,
    ));
  });

  setUp(() {
    mockReadinessService = MockReadinessService();
    mockAuthService = MockAuthService();

    // 預設行為
    when(() => mockReadinessService.getByAppointmentId(any()))
        .thenAnswer((_) async => null);
    when(() => mockReadinessService.calculateReadinessScore(any()))
        .thenReturn({'score': 75, 'trafficLight': TrafficLight.green});
  });

  tearDown(() {
    controller?.dispose();
    controller = null;
  });

  group('ReadinessController', () {
    // =========================================================================
    // P3-226: loadReadiness
    // =========================================================================
    group('初始化與載入', () {
      test('初始化時載入現有問卷', () async {
        // Arrange
        when(() => mockReadinessService.getByAppointmentId('apt-001'))
            .thenAnswer((_) async => testReadiness);

        // Act
        controller = ReadinessController(
          appointmentId: 'apt-001',
          readinessService: mockReadinessService,
          authService: mockAuthService,
        );

        // 等待異步載入完成
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(controller!.metrics.sleepQuality, 4);
        verify(() => mockReadinessService.getByAppointmentId('apt-001'))
            .called(1);
      });

      test('無 appointmentId 時不載入', () async {
        // Act
        controller = ReadinessController(
          readinessService: mockReadinessService,
          authService: mockAuthService,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verifyNever(() => mockReadinessService.getByAppointmentId(any()));
      });
    });

    // =========================================================================
    // P3-227: updateMetrics
    // =========================================================================
    group('更新指標', () {
      test('setSleepQuality 更新睡眠品質', () {
        // Arrange
        controller = ReadinessController(
          readinessService: mockReadinessService,
          authService: mockAuthService,
        );

        // Act
        controller!.setSleepQuality(5);

        // Assert
        expect(controller!.metrics.sleepQuality, 5);
      });

      test('setSleepHours 更新睡眠時數', () {
        // Arrange
        controller = ReadinessController(
          readinessService: mockReadinessService,
          authService: mockAuthService,
        );

        // Act
        controller!.setSleepHours(8.5);

        // Assert
        expect(controller!.metrics.sleepHours, 8.5);
      });

      test('值超出範圍時 clamp 到邊界', () {
        // Arrange
        controller = ReadinessController(
          readinessService: mockReadinessService,
          authService: mockAuthService,
        );

        // Act
        controller!.setSleepQuality(10); // 超過 5
        controller!.setSleepHours(15); // 超過 12

        // Assert
        expect(controller!.metrics.sleepQuality, 5);
        expect(controller!.metrics.sleepHours, 12.0);
      });

      test('setSoreness 更新肌肉痠痛', () {
        controller = ReadinessController(
          readinessService: mockReadinessService,
          authService: mockAuthService,
        );
        controller!.setSoreness(2);
        expect(controller!.metrics.soreness, 2);
      });

      test('setStress 更新壓力程度', () {
        controller = ReadinessController(
          readinessService: mockReadinessService,
          authService: mockAuthService,
        );
        controller!.setStress(1);
        expect(controller!.metrics.stress, 1);
      });

      test('setEnergyLevel 更新能量水平', () {
        controller = ReadinessController(
          readinessService: mockReadinessService,
          authService: mockAuthService,
        );
        controller!.setEnergyLevel(4);
        expect(controller!.metrics.energyLevel, 4);
      });
    });

    // =========================================================================
    // P3-228: submitReadiness
    // =========================================================================
    group('提交問卷', () {
      test('提交成功', () async {
        // Arrange
        when(() => mockAuthService.getCurrentUser())
            .thenReturn({'uid': 'user-001'});
        when(() => mockReadinessService.createReadiness(any()))
            .thenAnswer((_) async => testReadiness);

        controller = ReadinessController(
          readinessService: mockReadinessService,
          authService: mockAuthService,
        );

        // Act
        await controller!.submitReadiness();

        // Assert
        verify(() => mockReadinessService.createReadiness(any())).called(1);
      });

      test('未登入時拋出異常', () async {
        // Arrange
        when(() => mockAuthService.getCurrentUser()).thenReturn(null);

        controller = ReadinessController(
          readinessService: mockReadinessService,
          authService: mockAuthService,
        );

        // Act & Assert
        expect(
          () => controller!.submitReadiness(),
          throwsException,
        );
      });
    });

    // =========================================================================
    // P3-230: 即時計算
    // =========================================================================
    group('即時計算', () {
      test('calculatePreviewScore 返回分數和紅綠燈', () {
        // Arrange
        controller = ReadinessController(
          readinessService: mockReadinessService,
          authService: mockAuthService,
        );

        // Act
        final result = controller!.calculatePreviewScore();

        // Assert
        expect(result['score'], 75);
        expect(result['trafficLight'], TrafficLight.green);
      });
    });
  });
}
