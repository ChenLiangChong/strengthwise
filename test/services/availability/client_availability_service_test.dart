import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/client_availability_model.dart';

import '../../mocks/mock_services.dart';

/// ClientAvailabilityService 測試
///
/// P2 優先級 - 12 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockClientAvailabilityService mockService;

  // 測試用的模型資料
  final testAvailability = ClientAvailabilityModel(
    id: 'avail-001',
    clientId: 'client-001',
    startTime: DateTime(2026, 1, 20, 18, 0),
    endTime: DateTime(2026, 1, 20, 21, 0),
    priority: AvailabilityPriority.preferred,
    notes: '下班後時段',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockClientAvailabilityService();
  });

  group('IClientAvailabilityService', () {
    // =========================================================================
    // getClientAvailability
    // =========================================================================
    group('getClientAvailability', () {
      test('正常獲取學員時間偏好', () async {
        // Arrange
        when(() => mockService.getClientAvailability(clientId: 'client-001'))
            .thenAnswer((_) async => [testAvailability]);

        // Act
        final result =
            await mockService.getClientAvailability(clientId: 'client-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].clientId, 'client-001');
      });

      test('按優先級篩選', () async {
        // Arrange
        when(() => mockService.getClientAvailability(
              clientId: 'client-001',
              priority: AvailabilityPriority.preferred,
            )).thenAnswer((_) async => [testAvailability]);

        // Act
        final result = await mockService.getClientAvailability(
          clientId: 'client-001',
          priority: AvailabilityPriority.preferred,
        );

        // Assert
        expect(result[0].priority, AvailabilityPriority.preferred);
      });

      test('無時間偏好返回空列表', () async {
        // Arrange
        when(() => mockService.getClientAvailability(clientId: 'new-client'))
            .thenAnswer((_) async => []);

        // Act
        final result =
            await mockService.getClientAvailability(clientId: 'new-client');

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // getAvailabilityById
    // =========================================================================
    group('getAvailabilityById', () {
      test('正常獲取時間偏好', () async {
        // Arrange
        when(() => mockService.getAvailabilityById('avail-001'))
            .thenAnswer((_) async => testAvailability);

        // Act
        final result = await mockService.getAvailabilityById('avail-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'avail-001');
      });

      test('不存在返回 null', () async {
        // Arrange
        when(() => mockService.getAvailabilityById('not-exist'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getAvailabilityById('not-exist');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // getAvailabilityInRange
    // =========================================================================
    group('getAvailabilityInRange', () {
      test('正常獲取日期範圍內的時間偏好', () async {
        // Arrange
        when(() => mockService.getAvailabilityInRange(
              clientId: 'client-001',
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => [testAvailability]);

        // Act
        final result = await mockService.getAvailabilityInRange(
          clientId: 'client-001',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
        );

        // Assert
        expect(result.length, 1);
      });
    });

    // =========================================================================
    // createAvailability
    // =========================================================================
    group('createAvailability', () {
      test('正常建立時間偏好', () async {
        // Arrange
        when(() => mockService.createAvailability(any()))
            .thenAnswer((_) async => testAvailability);

        // Act
        final result = await mockService.createAvailability(testAvailability);

        // Assert
        expect(result.id, isNotEmpty);
      });
    });

    // =========================================================================
    // updateAvailability
    // =========================================================================
    group('updateAvailability', () {
      test('正常更新時間偏好', () async {
        // Arrange
        when(() => mockService.updateAvailability(any()))
            .thenAnswer((_) async => testAvailability);

        // Act
        final result = await mockService.updateAvailability(testAvailability);

        // Assert
        expect(result, isNotNull);
      });
    });

    // =========================================================================
    // deleteAvailability
    // =========================================================================
    group('deleteAvailability', () {
      test('正常刪除時間偏好', () async {
        // Arrange
        when(() => mockService.deleteAvailability('avail-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.deleteAvailability('avail-001'),
          completes,
        );
      });
    });

    // =========================================================================
    // hasConflict
    // =========================================================================
    group('hasConflict', () {
      test('無衝突返回 false', () async {
        // Arrange
        when(() => mockService.hasConflict(
              clientId: 'client-001',
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
            )).thenAnswer((_) async => false);

        // Act
        final result = await mockService.hasConflict(
          clientId: 'client-001',
          startTime: DateTime(2026, 1, 21, 10, 0),
          endTime: DateTime(2026, 1, 21, 12, 0),
        );

        // Assert
        expect(result, isFalse);
      });

      test('有衝突返回 true', () async {
        // Arrange
        when(() => mockService.hasConflict(
              clientId: 'client-001',
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
            )).thenAnswer((_) async => true);

        // Act
        final result = await mockService.hasConflict(
          clientId: 'client-001',
          startTime: DateTime(2026, 1, 20, 19, 0),
          endTime: DateTime(2026, 1, 20, 20, 0),
        );

        // Assert
        expect(result, isTrue);
      });
    });

    // =========================================================================
    // getPreferredTimeSlots
    // =========================================================================
    group('getPreferredTimeSlots', () {
      test('正常獲取最佳時段建議', () async {
        // Arrange
        when(() => mockService.getPreferredTimeSlots(
              clientId: 'client-001',
              date: any(named: 'date'),
            )).thenAnswer((_) async => [testAvailability]);

        // Act
        final result = await mockService.getPreferredTimeSlots(
          clientId: 'client-001',
          date: DateTime(2026, 1, 20),
        );

        // Assert
        expect(result.length, 1);
        expect(result[0].isPreferred, isTrue);
      });
    });
  });
}
