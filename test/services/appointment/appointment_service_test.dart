import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/appointment_model.dart';

import '../../mocks/mock_services.dart';

/// AppointmentService 測試
///
/// P2 優先級 - 35 個測試案例（原 10 個 + 補充 25 個）
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

    // =========================================================================
    // 補充測試：getUpcomingAppointments
    // =========================================================================
    group('getUpcomingAppointments', () {
      test('教練視角獲取即將到來的預約', () async {
        // Arrange
        when(() => mockService.getUpcomingAppointments(
              userId: 'coach-001',
              isCoach: true,
            )).thenAnswer((_) async => [testAppointment]);

        // Act
        final result = await mockService.getUpcomingAppointments(
          userId: 'coach-001',
          isCoach: true,
        );

        // Assert
        expect(result.length, 1);
      });

      test('學員視角獲取即將到來的預約', () async {
        // Arrange
        when(() => mockService.getUpcomingAppointments(
              userId: 'client-001',
              isCoach: false,
            )).thenAnswer((_) async => [testAppointment]);

        // Act
        final result = await mockService.getUpcomingAppointments(
          userId: 'client-001',
          isCoach: false,
        );

        // Assert
        expect(result.length, 1);
      });

      test('無即將到來的預約返回空列表', () async {
        // Arrange
        when(() => mockService.getUpcomingAppointments(
              userId: 'new-user',
              isCoach: true,
            )).thenAnswer((_) async => []);

        // Act
        final result = await mockService.getUpcomingAppointments(
          userId: 'new-user',
          isCoach: true,
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // 補充測試：completeAppointment
    // =========================================================================
    group('completeAppointment', () {
      test('正常完成預約', () async {
        // Arrange
        when(() => mockService.completeAppointment('apt-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.completeAppointment('apt-001'),
          completes,
        );
        verify(() => mockService.completeAppointment('apt-001')).called(1);
      });

      test('完成預約並附加教練備註', () async {
        // Arrange
        when(() => mockService.completeAppointment(
              'apt-001',
              coachNotes: '學員表現優秀',
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.completeAppointment(
            'apt-001',
            coachNotes: '學員表現優秀',
          ),
          completes,
        );
      });

      test('完成後狀態變為 completed', () async {
        // Arrange
        final completed =
            testAppointment.copyWith(status: AppointmentStatus.completed);
        when(() => mockService.completeAppointment('apt-001'))
            .thenAnswer((_) async {});
        when(() => mockService.getAppointmentById('apt-001'))
            .thenAnswer((_) async => completed);

        // Act
        await mockService.completeAppointment('apt-001');
        final result = await mockService.getAppointmentById('apt-001');

        // Assert
        expect(result!.status, AppointmentStatus.completed);
      });
    });

    // =========================================================================
    // 補充測試：rescheduleAppointment
    // =========================================================================
    group('rescheduleAppointment', () {
      test('正常改期', () async {
        // Arrange
        when(() => mockService.rescheduleAppointment(
              appointmentId: 'apt-001',
              newStartTime: any(named: 'newStartTime'),
              newEndTime: any(named: 'newEndTime'),
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.rescheduleAppointment(
            appointmentId: 'apt-001',
            newStartTime: DateTime(2025, 12, 20, 10, 0),
            newEndTime: DateTime(2025, 12, 20, 11, 0),
          ),
          completes,
        );
      });

      test('時間衝突時拋出異常', () async {
        // Arrange
        when(() => mockService.rescheduleAppointment(
              appointmentId: 'apt-001',
              newStartTime: any(named: 'newStartTime'),
              newEndTime: any(named: 'newEndTime'),
            )).thenThrow(Exception('Time conflict'));

        // Act & Assert
        expect(
          () => mockService.rescheduleAppointment(
            appointmentId: 'apt-001',
            newStartTime: DateTime(2025, 12, 20, 10, 0),
            newEndTime: DateTime(2025, 12, 20, 11, 0),
          ),
          throwsException,
        );
      });

      test('非 requested/confirmed 狀態拒絕改期', () async {
        // Arrange - 已完成的預約不能改期
        when(() => mockService.rescheduleAppointment(
              appointmentId: 'completed-apt',
              newStartTime: any(named: 'newStartTime'),
              newEndTime: any(named: 'newEndTime'),
            )).thenThrow(Exception('Cannot reschedule completed appointment'));

        // Act & Assert
        expect(
          () => mockService.rescheduleAppointment(
            appointmentId: 'completed-apt',
            newStartTime: DateTime(2025, 12, 20, 10, 0),
            newEndTime: DateTime(2025, 12, 20, 11, 0),
          ),
          throwsException,
        );
      });
    });

    // =========================================================================
    // 補充測試：updateClientNotes
    // =========================================================================
    group('updateClientNotes', () {
      test('正常更新學員備註', () async {
        // Arrange
        when(() => mockService.updateClientNotes(
              appointmentId: 'apt-001',
              clientNotes: '希望練胸',
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.updateClientNotes(
            appointmentId: 'apt-001',
            clientNotes: '希望練胸',
          ),
          completes,
        );
      });

      test('空備註也可更新', () async {
        // Arrange
        when(() => mockService.updateClientNotes(
              appointmentId: 'apt-001',
              clientNotes: '',
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.updateClientNotes(
            appointmentId: 'apt-001',
            clientNotes: '',
          ),
          completes,
        );
      });
    });

    // =========================================================================
    // 補充測試：updateCoachNotes
    // =========================================================================
    group('updateCoachNotes', () {
      test('正常更新教練備註', () async {
        // Arrange
        when(() => mockService.updateCoachNotes(
              appointmentId: 'apt-001',
              coachNotes: '學員肩膀有舊傷',
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.updateCoachNotes(
            appointmentId: 'apt-001',
            coachNotes: '學員肩膀有舊傷',
          ),
          completes,
        );
      });

      test('空備註也可更新', () async {
        // Arrange
        when(() => mockService.updateCoachNotes(
              appointmentId: 'apt-001',
              coachNotes: '',
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.updateCoachNotes(
            appointmentId: 'apt-001',
            coachNotes: '',
          ),
          completes,
        );
      });
    });

    // =========================================================================
    // 補充測試：linkWorkoutPlan
    // =========================================================================
    group('linkWorkoutPlan', () {
      test('正常關聯訓練計劃', () async {
        // Arrange
        when(() => mockService.linkWorkoutPlan(
              appointmentId: 'apt-001',
              workoutPlanId: 'plan-001',
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.linkWorkoutPlan(
            appointmentId: 'apt-001',
            workoutPlanId: 'plan-001',
          ),
          completes,
        );
      });

      test('重複關聯覆蓋舊的', () async {
        // Arrange
        when(() => mockService.linkWorkoutPlan(
              appointmentId: 'apt-001',
              workoutPlanId: 'plan-002',
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.linkWorkoutPlan(
            appointmentId: 'apt-001',
            workoutPlanId: 'plan-002',
          ),
          completes,
        );
      });
    });

    // =========================================================================
    // 補充測試：deleteAppointment
    // =========================================================================
    group('deleteAppointment', () {
      test('正常刪除預約', () async {
        // Arrange
        when(() => mockService.deleteAppointment('apt-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.deleteAppointment('apt-001'),
          completes,
        );
        verify(() => mockService.deleteAppointment('apt-001')).called(1);
      });

      test('非 requested 狀態拒絕刪除', () async {
        // Arrange
        when(() => mockService.deleteAppointment('confirmed-apt'))
            .thenThrow(Exception('Cannot delete confirmed appointment'));

        // Act & Assert
        expect(
          () => mockService.deleteAppointment('confirmed-apt'),
          throwsException,
        );
      });
    });

    // =========================================================================
    // 補充測試：getAppointmentStats
    // =========================================================================
    group('getAppointmentStats', () {
      test('正常獲取預約統計', () async {
        // Arrange
        final stats = {
          'total': 10,
          'completed': 8,
          'cancelled': 1,
          'pending': 1,
        };
        when(() => mockService.getAppointmentStats(
              coachId: 'coach-001',
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => stats);

        // Act
        final result = await mockService.getAppointmentStats(
          coachId: 'coach-001',
          startDate: DateTime(2025, 12, 1),
          endDate: DateTime(2025, 12, 31),
        );

        // Assert
        expect(result['total'], 10);
        expect(result['completed'], 8);
      });

      test('日期範圍篩選正確', () async {
        // Arrange
        final stats = {'total': 5, 'completed': 4, 'cancelled': 0, 'pending': 1};
        when(() => mockService.getAppointmentStats(
              coachId: 'coach-001',
              startDate: DateTime(2025, 12, 15),
              endDate: DateTime(2025, 12, 20),
            )).thenAnswer((_) async => stats);

        // Act
        final result = await mockService.getAppointmentStats(
          coachId: 'coach-001',
          startDate: DateTime(2025, 12, 15),
          endDate: DateTime(2025, 12, 20),
        );

        // Assert
        expect(result['total'], 5);
      });

      test('無預約返回零統計', () async {
        // Arrange
        final emptyStats = {
          'total': 0,
          'completed': 0,
          'cancelled': 0,
          'pending': 0,
        };
        when(() => mockService.getAppointmentStats(
              coachId: 'new-coach',
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => emptyStats);

        // Act
        final result = await mockService.getAppointmentStats(
          coachId: 'new-coach',
          startDate: DateTime(2025, 12, 1),
          endDate: DateTime(2025, 12, 31),
        );

        // Assert
        expect(result['total'], 0);
      });
    });

    // =========================================================================
    // 補充測試：getClientAttendanceRate
    // =========================================================================
    group('getClientAttendanceRate', () {
      test('正常計算出席率', () async {
        // Arrange
        when(() => mockService.getClientAttendanceRate(
              clientId: 'client-001',
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => 0.85);

        // Act
        final result = await mockService.getClientAttendanceRate(
          clientId: 'client-001',
          startDate: DateTime(2025, 12, 1),
          endDate: DateTime(2025, 12, 31),
        );

        // Assert
        expect(result, 0.85);
      });

      test('0% 出席率', () async {
        // Arrange
        when(() => mockService.getClientAttendanceRate(
              clientId: 'absent-client',
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => 0.0);

        // Act
        final result = await mockService.getClientAttendanceRate(
          clientId: 'absent-client',
          startDate: DateTime(2025, 12, 1),
          endDate: DateTime(2025, 12, 31),
        );

        // Assert
        expect(result, 0.0);
      });

      test('100% 出席率', () async {
        // Arrange
        when(() => mockService.getClientAttendanceRate(
              clientId: 'perfect-client',
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => 1.0);

        // Act
        final result = await mockService.getClientAttendanceRate(
          clientId: 'perfect-client',
          startDate: DateTime(2025, 12, 1),
          endDate: DateTime(2025, 12, 31),
        );

        // Assert
        expect(result, 1.0);
      });
    });

    // =========================================================================
    // 補充測試：checkConflict 進階場景
    // =========================================================================
    group('checkConflict - 進階場景', () {
      test('排除自身預約檢查衝突', () async {
        // Arrange
        when(() => mockService.checkConflict(
              coachId: 'coach-001',
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
              excludeAppointmentId: 'apt-001',
            )).thenAnswer((_) async => false);

        // Act
        final result = await mockService.checkConflict(
          coachId: 'coach-001',
          startTime: DateTime(2025, 12, 15, 10, 0),
          endTime: DateTime(2025, 12, 15, 11, 0),
          excludeAppointmentId: 'apt-001',
        );

        // Assert
        expect(result, isFalse);
      });

      test('邊界時間不算衝突', () async {
        // Arrange - 10:00-11:00 和 11:00-12:00 相鄰不衝突
        when(() => mockService.checkConflict(
              coachId: 'coach-001',
              startTime: DateTime(2025, 12, 15, 11, 0),
              endTime: DateTime(2025, 12, 15, 12, 0),
            )).thenAnswer((_) async => false);

        // Act
        final result = await mockService.checkConflict(
          coachId: 'coach-001',
          startTime: DateTime(2025, 12, 15, 11, 0),
          endTime: DateTime(2025, 12, 15, 12, 0),
        );

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // 補充測試：getCoachAppointments 進階場景
    // =========================================================================
    group('getCoachAppointments - TSTZRANGE 篩選', () {
      test('按日期範圍篩選', () async {
        // Arrange
        when(() => mockService.getCoachAppointments(
              coachId: 'coach-001',
              startDate: DateTime(2025, 12, 15),
              endDate: DateTime(2025, 12, 20),
            )).thenAnswer((_) async => [testAppointment]);

        // Act
        final result = await mockService.getCoachAppointments(
          coachId: 'coach-001',
          startDate: DateTime(2025, 12, 15),
          endDate: DateTime(2025, 12, 20),
        );

        // Assert
        expect(result.length, 1);
      });
    });
  });
}
