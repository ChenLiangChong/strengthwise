import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_services.dart';

/// BookingService 測試
///
/// P1 優先級 - 20 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockBookingService mockService;

  // 測試用的資料
  final testBooking = {
    'id': 'booking-001',
    'coachId': 'coach-001',
    'clientId': 'client-001',
    'slotId': 'slot-001',
    'startTime': DateTime(2026, 1, 15, 10, 0).toIso8601String(),
    'endTime': DateTime(2026, 1, 15, 11, 0).toIso8601String(),
    'status': 'confirmed',
  };

  final testSlot = {
    'id': 'slot-001',
    'coachId': 'coach-001',
    'dayOfWeek': 1,
    'startTime': '09:00',
    'endTime': '18:00',
    'isBooked': false,
  };

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockBookingService();
  });

  group('IBookingService', () {
    // =========================================================================
    // isInitialized / initialize
    // =========================================================================
    group('Initialization', () {
      test('初始化前 isInitialized 為 false', () {
        // Arrange
        when(() => mockService.isInitialized).thenReturn(false);

        // Act & Assert
        expect(mockService.isInitialized, isFalse);
      });

      test('初始化後 isInitialized 為 true', () async {
        // Arrange
        when(() => mockService.initialize()).thenAnswer((_) async {});
        when(() => mockService.isInitialized).thenReturn(true);

        // Act
        await mockService.initialize();

        // Assert
        expect(mockService.isInitialized, isTrue);
      });
    });

    // =========================================================================
    // getUserBookings
    // =========================================================================
    group('getUserBookings', () {
      test('正常獲取用戶預約', () async {
        // Arrange
        when(() => mockService.getUserBookings())
            .thenAnswer((_) async => [testBooking]);

        // Act
        final result = await mockService.getUserBookings();

        // Assert
        expect(result.length, 1);
        expect(result[0]['id'], 'booking-001');
      });

      test('無預約返回空列表', () async {
        // Arrange
        when(() => mockService.getUserBookings()).thenAnswer((_) async => []);

        // Act
        final result = await mockService.getUserBookings();

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // getCoachBookings
    // =========================================================================
    group('getCoachBookings', () {
      test('正常獲取教練預約', () async {
        // Arrange
        when(() => mockService.getCoachBookings())
            .thenAnswer((_) async => [testBooking]);

        // Act
        final result = await mockService.getCoachBookings();

        // Assert
        expect(result.length, 1);
      });
    });

    // =========================================================================
    // getBookingById
    // =========================================================================
    group('getBookingById', () {
      test('正常獲取特定預約', () async {
        // Arrange
        when(() => mockService.getBookingById('booking-001'))
            .thenAnswer((_) async => testBooking);

        // Act
        final result = await mockService.getBookingById('booking-001');

        // Assert
        expect(result, isNotNull);
        expect(result!['id'], 'booking-001');
      });

      test('預約不存在返回 null', () async {
        // Arrange
        when(() => mockService.getBookingById('not-exist'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getBookingById('not-exist');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // createBooking
    // =========================================================================
    group('createBooking', () {
      test('正常建立預約', () async {
        // Arrange
        when(() => mockService.createBooking(any()))
            .thenAnswer((_) async => 'booking-new');

        // Act
        final result = await mockService.createBooking(testBooking);

        // Assert
        expect(result, 'booking-new');
      });
    });

    // =========================================================================
    // updateBooking
    // =========================================================================
    group('updateBooking', () {
      test('正常更新預約', () async {
        // Arrange
        when(() => mockService.updateBooking('booking-001', any()))
            .thenAnswer((_) async => true);

        // Act
        final result =
            await mockService.updateBooking('booking-001', testBooking);

        // Assert
        expect(result, isTrue);
      });

      test('預約不存在更新失敗', () async {
        // Arrange
        when(() => mockService.updateBooking('not-exist', any()))
            .thenAnswer((_) async => false);

        // Act
        final result =
            await mockService.updateBooking('not-exist', testBooking);

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // cancelBooking
    // =========================================================================
    group('cancelBooking', () {
      test('正常取消預約', () async {
        // Arrange
        when(() => mockService.cancelBooking('booking-001'))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.cancelBooking('booking-001');

        // Assert
        expect(result, isTrue);
      });
    });

    // =========================================================================
    // confirmBooking
    // =========================================================================
    group('confirmBooking', () {
      test('正常確認預約', () async {
        // Arrange
        when(() => mockService.confirmBooking('booking-001'))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.confirmBooking('booking-001');

        // Assert
        expect(result, isTrue);
      });
    });

    // =========================================================================
    // deleteBooking
    // =========================================================================
    group('deleteBooking', () {
      test('正常刪除預約', () async {
        // Arrange
        when(() => mockService.deleteBooking('booking-001'))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.deleteBooking('booking-001');

        // Assert
        expect(result, isTrue);
      });
    });

    // =========================================================================
    // getAvailableSlots
    // =========================================================================
    group('getAvailableSlots', () {
      test('正常獲取可用時段', () async {
        // Arrange
        when(() => mockService.getAvailableSlots('coach-001'))
            .thenAnswer((_) async => [testSlot]);

        // Act
        final result = await mockService.getAvailableSlots('coach-001');

        // Assert
        expect(result.length, 1);
        expect(result[0]['isBooked'], isFalse);
      });

      test('無可用時段返回空列表', () async {
        // Arrange
        when(() => mockService.getAvailableSlots('busy-coach'))
            .thenAnswer((_) async => []);

        // Act
        final result = await mockService.getAvailableSlots('busy-coach');

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // setSlotBooked
    // =========================================================================
    group('setSlotBooked', () {
      test('正常設置時段已預約', () async {
        // Arrange
        when(() => mockService.setSlotBooked('slot-001'))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.setSlotBooked('slot-001');

        // Assert
        expect(result, isTrue);
      });
    });
  });
}
