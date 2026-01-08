import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/appointment_model.dart';
import 'package:strengthwise/services/interfaces/i_appointment_service.dart';

import '../../mocks/mock_services.dart';

/// AppointmentService 測試
///
/// P2 優先級 - 10 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md #P2
void main() {
  late MockAppointmentService mockService;

  // 測試用的模型資料
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
    // 註冊 AppointmentModel fallback
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
  });

  group('IAppointmentService', () {
    // =========================================================================
    // P2-149: getCoachAppointments
    // =========================================================================
    group('getCoachAppointments', () {
      test('返回教練的所有預約', () async {
        // Arrange
        when(() => mockService.getCoachAppointments(
              coachId: 'coach-001',
            )).thenAnswer((_) async => [testAppointment]);

        // Act
        final result =
            await mockService.getCoachAppointments(coachId: 'coach-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].coachId, 'coach-001');
      });

      test('可按狀態篩選', () async {
        // Arrange
        when(() => mockService.getCoachAppointments(
              coachId: 'coach-001',
              status: AppointmentStatus.confirmed,
            )).thenAnswer((_) async => [testAppointment]);

        // Act
        final result = await mockService.getCoachAppointments(
          coachId: 'coach-001',
          status: AppointmentStatus.confirmed,
        );

        // Assert
        expect(result.length, 1);
        expect(result[0].status, AppointmentStatus.confirmed);
      });
    });

    // =========================================================================
    // P2-150: getClientAppointments
    // =========================================================================
    group('getClientAppointments', () {
      test('返回學員的所有預約', () async {
        // Arrange
        when(() => mockService.getClientAppointments(
              clientId: 'client-001',
            )).thenAnswer((_) async => [testAppointment]);

        // Act
        final result =
            await mockService.getClientAppointments(clientId: 'client-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].clientId, 'client-001');
      });
    });

    // =========================================================================
    // P2-151: getAppointmentById
    // =========================================================================
    group('getAppointmentById', () {
      test('找到預約時返回 Model', () async {
        // Arrange
        when(() => mockService.getAppointmentById('apt-001'))
            .thenAnswer((_) async => testAppointment);

        // Act
        final result = await mockService.getAppointmentById('apt-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'apt-001');
      });

      test('找不到預約時返回 null', () async {
        // Arrange
        when(() => mockService.getAppointmentById('not-exist'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getAppointmentById('not-exist');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // P2-152: getPendingAppointments
    // =========================================================================
    group('getPendingAppointments', () {
      test('返回待確認的預約', () async {
        // Arrange
        final pending =
            testAppointment.copyWith(status: AppointmentStatus.requested);
        when(() => mockService.getPendingAppointments('coach-001'))
            .thenAnswer((_) async => [pending]);

        // Act
        final result = await mockService.getPendingAppointments('coach-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].status, AppointmentStatus.requested);
      });
    });

    // =========================================================================
    // P2-153: checkConflict
    // =========================================================================
    group('checkConflict', () {
      test('時段有衝突返回 true', () async {
        // Arrange
        when(() => mockService.checkConflict(
              coachId: 'coach-001',
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
            )).thenAnswer((_) async => true);

        // Act
        final result = await mockService.checkConflict(
          coachId: 'coach-001',
          startTime: DateTime(2025, 12, 15, 10, 0),
          endTime: DateTime(2025, 12, 15, 11, 0),
        );

        // Assert
        expect(result, isTrue);
      });
    });

    // =========================================================================
    // P2-154: createAppointment
    // =========================================================================
    group('createAppointment', () {
      test('建立預約並返回 ID', () async {
        // Arrange
        when(() => mockService.createAppointment(any()))
            .thenAnswer((_) async => 'new-apt-001');

        // Act
        final result = await mockService.createAppointment(testAppointment);

        // Assert
        expect(result, 'new-apt-001');
      });
    });

    // =========================================================================
    // P2-155: confirmAppointment
    // =========================================================================
    group('confirmAppointment', () {
      test('確認預約成功', () async {
        // Arrange
        when(() => mockService.confirmAppointment('apt-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.confirmAppointment('apt-001'),
          completes,
        );
        verify(() => mockService.confirmAppointment('apt-001')).called(1);
      });
    });

    // =========================================================================
    // P2-156: cancelAppointment
    // =========================================================================
    group('cancelAppointment', () {
      test('取消預約成功', () async {
        // Arrange
        when(() => mockService.cancelAppointment(
              appointmentId: 'apt-001',
              cancelledBy: 'user-001',
              reason: '臨時有事',
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.cancelAppointment(
            appointmentId: 'apt-001',
            cancelledBy: 'user-001',
            reason: '臨時有事',
          ),
          completes,
        );
      });
    });

    // =========================================================================
    // P2-157: createAdHocSession
    // =========================================================================
    group('createAdHocSession', () {
      test('建立臨時課程成功', () async {
        // Arrange
        when(() => mockService.createAdHocSession(
              coachId: 'coach-001',
              clientId: 'client-001',
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
            )).thenAnswer((_) async => 'adhoc-001');

        // Act
        final result = await mockService.createAdHocSession(
          coachId: 'coach-001',
          clientId: 'client-001',
          startTime: DateTime(2025, 12, 15, 14, 0),
          endTime: DateTime(2025, 12, 15, 15, 0),
        );

        // Assert
        expect(result, 'adhoc-001');
      });
    });

    // =========================================================================
    // P2-158: getLastCompletedAppointment
    // =========================================================================
    group('getLastCompletedAppointment', () {
      test('返回學員最近完成的預約', () async {
        // Arrange
        final completed =
            testAppointment.copyWith(status: AppointmentStatus.completed);
        when(() => mockService.getLastCompletedAppointment('client-001'))
            .thenAnswer((_) async => completed);

        // Act
        final result =
            await mockService.getLastCompletedAppointment('client-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.status, AppointmentStatus.completed);
      });
    });
  });
}
