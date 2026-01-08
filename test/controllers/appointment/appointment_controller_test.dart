import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/controllers/appointment_controller.dart';
import 'package:strengthwise/models/appointment_model.dart';
import 'package:strengthwise/services/interfaces/i_appointment_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';

// Mock Classes
class MockAppointmentService extends Mock implements IAppointmentService {}

class MockErrorHandlingService extends Mock implements ErrorHandlingService {}

/// AppointmentController 測試
///
/// P3 優先級 - 10 個測試案例
void main() {
  late MockAppointmentService mockService;
  late MockErrorHandlingService mockErrorService;
  late AppointmentController controller;

  final testAppointment = AppointmentModel(
    id: 'apt-001',
    coachId: 'coach-001',
    clientId: 'client-001',
    startTime: DateTime(2025, 12, 15, 10, 0),
    endTime: DateTime(2025, 12, 15, 11, 0),
    status: AppointmentStatus.confirmed,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(AppointmentModel(
      id: 'fallback',
      coachId: 'fallback',
      clientId: 'fallback',
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 1)),
      status: AppointmentStatus.requested,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  setUp(() {
    mockService = MockAppointmentService();
    mockErrorService = MockErrorHandlingService();

    // 預設行為
    when(() => mockService.getCoachAppointments(
          coachId: any(named: 'coachId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          status: any(named: 'status'),
        )).thenAnswer((_) async => [testAppointment]);

    when(() => mockService.getPendingAppointments(any()))
        .thenAnswer((_) async => []);

    when(() => mockService.getAppointmentById(any()))
        .thenAnswer((_) async => testAppointment);

    when(() => mockService.confirmAppointment(any())).thenAnswer((_) async {});

    when(() => mockService.cancelAppointment(
          appointmentId: any(named: 'appointmentId'),
          cancelledBy: any(named: 'cancelledBy'),
          reason: any(named: 'reason'),
        )).thenAnswer((_) async {});

    when(() => mockService.checkConflict(
          coachId: any(named: 'coachId'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          excludeAppointmentId: any(named: 'excludeAppointmentId'),
        )).thenAnswer((_) async => false);

    when(() => mockErrorService.logError(any(), type: any(named: 'type')))
        .thenReturn(null);

    // 使用位置參數構造
    controller = AppointmentController(mockService, mockErrorService);
  });

  tearDown(() {
    controller.dispose();
  });

  group('AppointmentController', () {
    // =========================================================================
    // P3-231: 狀態訪問
    // =========================================================================
    group('狀態訪問', () {
      test('isLoading 初始為 false', () {
        expect(controller.isLoading, isFalse);
      });

      test('appointments 初始為空', () {
        expect(controller.appointments, isEmpty);
      });

      test('selectedAppointment 初始為 null', () {
        expect(controller.selectedAppointment, isNull);
      });
    });

    // =========================================================================
    // P3-232: confirmAppointment
    // =========================================================================
    group('確認預約', () {
      test('clearSelectedAppointment 清除選中', () {
        controller.clearSelectedAppointment();
        expect(controller.selectedAppointment, isNull);
      });
    });

    // =========================================================================
    // P3-233: cancelAppointment
    // =========================================================================
    group('取消預約', () {
      test('clearAll 清除所有狀態', () {
        controller.clearAll();
        expect(controller.appointments, isEmpty);
      });
    });

    // =========================================================================
    // P3-234: 時段衝突檢查
    // =========================================================================
    group('時段衝突', () {
      test('checkTimeConflict 無衝突返回 false', () async {
        // Act
        final result = await controller.checkTimeConflict(
          coachId: 'coach-001',
          startTime: DateTime(2025, 12, 16, 10, 0),
          endTime: DateTime(2025, 12, 16, 11, 0),
        );

        // Assert
        expect(result, isFalse);
      });

      test('checkTimeConflict 有衝突返回 true', () async {
        // Arrange
        when(() => mockService.checkConflict(
              coachId: any(named: 'coachId'),
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
              excludeAppointmentId: any(named: 'excludeAppointmentId'),
            )).thenAnswer((_) async => true);

        // Act
        final result = await controller.checkTimeConflict(
          coachId: 'coach-001',
          startTime: DateTime(2025, 12, 15, 10, 0),
          endTime: DateTime(2025, 12, 15, 11, 0),
        );

        // Assert
        expect(result, isTrue);
      });
    });

    // =========================================================================
    // P3-235: 錯誤狀態
    // =========================================================================
    group('錯誤狀態', () {
      test('errorMessage 初始為 null', () {
        expect(controller.errorMessage, isNull);
      });
    });
  });
}
