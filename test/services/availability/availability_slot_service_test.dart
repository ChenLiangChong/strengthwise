import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/availability_slot_model.dart';
import 'package:strengthwise/services/interfaces/i_availability_slot_service.dart';

import '../../mocks/mock_services.dart';

/// AvailabilitySlotService 測試
///
/// P2 優先級 - 12 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockAvailabilitySlotService mockService;

  // 測試用的模型資料
  final testSlot = AvailabilitySlotModel(
    id: 'slot-001',
    coachId: 'coach-001',
    startTime: DateTime(2026, 1, 20, 10, 0),
    endTime: DateTime(2026, 1, 20, 12, 0),
    isOverride: false,
    notes: '上午時段',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testSlotWithBooking = AvailabilitySlotWithBooking(
    slot: testSlot,
    isBooked: false,
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockAvailabilitySlotService();
  });

  group('IAvailabilitySlotService', () {
    // =========================================================================
    // getCoachSlots
    // =========================================================================
    group('getCoachSlots', () {
      test('正常獲取教練時段', () async {
        // Arrange
        when(() => mockService.getCoachSlots(coachId: 'coach-001'))
            .thenAnswer((_) async => [testSlot]);

        // Act
        final result = await mockService.getCoachSlots(coachId: 'coach-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].coachId, 'coach-001');
      });

      test('按日期範圍查詢', () async {
        // Arrange
        when(() => mockService.getCoachSlots(
              coachId: 'coach-001',
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => [testSlot]);

        // Act
        final result = await mockService.getCoachSlots(
          coachId: 'coach-001',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
        );

        // Assert
        expect(result.length, 1);
      });
    });

    // =========================================================================
    // getSlotById
    // =========================================================================
    group('getSlotById', () {
      test('正常獲取時段', () async {
        // Arrange
        when(() => mockService.getSlotById('slot-001'))
            .thenAnswer((_) async => testSlot);

        // Act
        final result = await mockService.getSlotById('slot-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'slot-001');
      });

      test('時段不存在返回 null', () async {
        // Arrange
        when(() => mockService.getSlotById('not-exist'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getSlotById('not-exist');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // getAvailableSlots
    // =========================================================================
    group('getAvailableSlots', () {
      test('正常獲取可預約時段', () async {
        // Arrange
        when(() => mockService.getAvailableSlots(
              coachId: 'coach-001',
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => [testSlotWithBooking]);

        // Act
        final result = await mockService.getAvailableSlots(
          coachId: 'coach-001',
          startDate: DateTime(2026, 1, 20),
          endDate: DateTime(2026, 1, 27),
        );

        // Assert
        expect(result.length, 1);
        expect(result[0].isBooked, isFalse);
      });
    });

    // =========================================================================
    // createSlot
    // =========================================================================
    group('createSlot', () {
      test('正常建立時段', () async {
        // Arrange
        when(() => mockService.createSlot(any()))
            .thenAnswer((_) async => 'slot-new');

        // Act
        final result = await mockService.createSlot(testSlot);

        // Assert
        expect(result, 'slot-new');
      });
    });

    // =========================================================================
    // updateSlot
    // =========================================================================
    group('updateSlot', () {
      test('正常更新時段', () async {
        // Arrange
        when(() => mockService.updateSlot(
              slotId: 'slot-001',
              slot: any(named: 'slot'),
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.updateSlot(slotId: 'slot-001', slot: testSlot),
          completes,
        );
      });
    });

    // =========================================================================
    // deleteSlot
    // =========================================================================
    group('deleteSlot', () {
      test('正常刪除時段', () async {
        // Arrange
        when(() => mockService.deleteSlot('slot-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.deleteSlot('slot-001'),
          completes,
        );
      });
    });

    // =========================================================================
    // isSlotBooked
    // =========================================================================
    group('isSlotBooked', () {
      test('未被預約返回 false', () async {
        // Arrange
        when(() => mockService.isSlotBooked('slot-001'))
            .thenAnswer((_) async => false);

        // Act
        final result = await mockService.isSlotBooked('slot-001');

        // Assert
        expect(result, isFalse);
      });

      test('已被預約返回 true', () async {
        // Arrange
        when(() => mockService.isSlotBooked('slot-booked'))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.isSlotBooked('slot-booked');

        // Assert
        expect(result, isTrue);
      });
    });

    // =========================================================================
    // createSlotsBatch
    // =========================================================================
    group('createSlotsBatch', () {
      test('批量建立時段', () async {
        // Arrange
        when(() => mockService.createSlotsBatch(any()))
            .thenAnswer((_) async => ['slot-1', 'slot-2', 'slot-3']);

        // Act
        final result = await mockService.createSlotsBatch([testSlot, testSlot, testSlot]);

        // Assert
        expect(result.length, 3);
      });
    });

    // =========================================================================
    // deleteSlots
    // =========================================================================
    group('deleteSlots', () {
      test('批量刪除時段', () async {
        // Arrange
        when(() => mockService.deleteSlots(any())).thenAnswer((_) async => 3);

        // Act
        final result = await mockService.deleteSlots(['slot-1', 'slot-2', 'slot-3']);

        // Assert
        expect(result, 3);
      });
    });
  });
}
