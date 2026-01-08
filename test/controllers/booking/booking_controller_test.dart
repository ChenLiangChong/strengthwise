import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/controllers/booking_controller.dart';
import 'package:strengthwise/services/interfaces/i_booking_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';

// Mock Classes
class MockBookingService extends Mock implements IBookingService {}

class MockErrorHandlingService extends Mock implements ErrorHandlingService {}

/// BookingController 測試
///
/// P3 優先級 - 10 個測試案例
void main() {
  late MockBookingService mockService;
  late MockErrorHandlingService mockErrorService;
  late BookingController controller;

  setUp(() {
    mockService = MockBookingService();
    mockErrorService = MockErrorHandlingService();

    // 預設行為
    when(() => mockService.isInitialized).thenReturn(true);
    when(() => mockService.getUserBookings()).thenAnswer((_) async => [
          {'id': 'booking-001', 'status': 'confirmed'}
        ]);
    when(() => mockService.getCoachBookings()).thenAnswer((_) async => [
          {'id': 'booking-001', 'status': 'confirmed'}
        ]);
    when(() => mockService.getBookingById(any()))
        .thenAnswer((_) async => {'id': 'booking-001', 'status': 'confirmed'});
    when(() => mockService.getAvailableSlots(any())).thenAnswer((_) async => [
          {'id': 'slot-001', 'time': '10:00'}
        ]);
    when(() => mockService.createBooking(any()))
        .thenAnswer((_) async => 'new-booking-001');
    when(() => mockService.cancelBooking(any())).thenAnswer((_) async => true);
    when(() => mockService.confirmBooking(any())).thenAnswer((_) async => true);
    when(() => mockService.updateBooking(any(), any()))
        .thenAnswer((_) async => true);
    when(() => mockService.deleteBooking(any())).thenAnswer((_) async => true);
    when(() => mockService.setSlotBooked(any())).thenAnswer((_) async => true);
    when(() => mockErrorService.logError(any(), type: any(named: 'type')))
        .thenReturn(null);

    controller = BookingController(
      bookingService: mockService,
      errorService: mockErrorService,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('BookingController', () {
    // =========================================================================
    // P3-241: loadUserBookings
    // =========================================================================
    group('loadUserBookings', () {
      test('成功載入用戶預約', () async {
        // Act
        final result = await controller.loadUserBookings();

        // Assert
        expect(result.length, 1);
        verify(() => mockService.getUserBookings()).called(1);
      });
    });

    // =========================================================================
    // P3-242: loadCoachBookings
    // =========================================================================
    group('loadCoachBookings', () {
      test('成功載入教練預約', () async {
        // Act
        final result = await controller.loadCoachBookings();

        // Assert
        expect(result.length, 1);
      });
    });

    // =========================================================================
    // P3-243: loadAvailableSlots
    // =========================================================================
    group('loadAvailableSlots', () {
      test('成功載入可用時段', () async {
        // Act
        final result = await controller.loadAvailableSlots('coach-001');

        // Assert
        verify(() => mockService.getAvailableSlots('coach-001')).called(1);
      });
    });

    // =========================================================================
    // P3-244: getBookingById
    // =========================================================================
    group('getBookingById', () {
      test('成功取得預約詳情', () async {
        // Act
        final result = await controller.getBookingById('booking-001');

        // Assert
        expect(result, isNotNull);
        expect(result!['id'], 'booking-001');
      });
    });

    // =========================================================================
    // P3-245: cancelBooking
    // =========================================================================
    group('cancelBooking', () {
      test('成功取消預約', () async {
        // Act
        final result = await controller.cancelBooking('booking-001');

        // Assert
        expect(result, isTrue);
        verify(() => mockService.cancelBooking('booking-001')).called(1);
      });
    });

    // =========================================================================
    // P3-246: confirmBooking
    // =========================================================================
    group('confirmBooking', () {
      test('成功確認預約', () async {
        // Act
        final result = await controller.confirmBooking('booking-001');

        // Assert
        expect(result, isTrue);
      });
    });

    // =========================================================================
    // 狀態管理
    // =========================================================================
    group('狀態管理', () {
      test('isLoading 初始為 false（初始化後）', () async {
        await controller.initialized;
        expect(controller.isLoading, isFalse);
      });

      test('clearError 清除錯誤', () {
        controller.clearError();
        expect(controller.errorMessage, isNull);
      });

      test('clearCache 清除緩存', () {
        controller.clearCache('all');
        // 測試不拋出異常即可
      });
    });
  });
}
