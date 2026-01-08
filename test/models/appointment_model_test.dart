import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/appointment_model.dart';

/// AppointmentModel 測試
///
/// P1 優先級 - 10 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md #P1
void main() {
  group('AppointmentModel', () {
    // 測試用的 Supabase 格式 JSON
    final validSupabaseJson = {
      'id': 'apt-001',
      'coach_id': 'coach-001',
      'client_id': 'client-001',
      'time_range': '[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)',
      'status': 'confirmed',
      'workout_plan_id': 'plan-001',
      'notes': '第三次訓練',
      'client_notes': '學員備註',
      'coach_notes': '教練筆記',
      'cancellation_reason': null,
      'cancelled_by': null,
      'cancelled_at': null,
      'created_at': '2025-12-10T08:00:00.000Z',
      'updated_at': '2025-12-10T09:00:00.000Z',
    };

    // =========================================================================
    // P1-59: fromSupabase - TSTZRANGE 解析
    // =========================================================================
    group('fromSupabase', () {
      test('正確解析 Supabase 格式（含 TSTZRANGE）', () {
        // Act
        final model = AppointmentModel.fromSupabase(validSupabaseJson);

        // Assert
        expect(model.id, 'apt-001');
        expect(model.coachId, 'coach-001');
        expect(model.clientId, 'client-001');
        expect(model.status, AppointmentStatus.confirmed);
        expect(model.workoutPlanId, 'plan-001');
        expect(model.notes, '第三次訓練');
        expect(model.clientNotes, '學員備註');
        expect(model.coachNotes, '教練筆記');
        // TSTZRANGE 解析
        expect(model.startTime.toUtc().hour, 9);
        expect(model.endTime.toUtc().hour, 10);
      });

      test('解析各種狀態', () {
        // Arrange
        final statuses = ['requested', 'confirmed', 'completed', 'cancelled'];
        final expected = [
          AppointmentStatus.requested,
          AppointmentStatus.confirmed,
          AppointmentStatus.completed,
          AppointmentStatus.cancelled,
        ];

        for (int i = 0; i < statuses.length; i++) {
          final json = Map<String, dynamic>.from(validSupabaseJson);
          json['status'] = statuses[i];

          // Act
          final model = AppointmentModel.fromSupabase(json);

          // Assert
          expect(model.status, expected[i]);
        }
      });

      test('空 notes 處理', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['notes'] = null;
        json['client_notes'] = null;
        json['coach_notes'] = null;

        // Act
        final model = AppointmentModel.fromSupabase(json);

        // Assert
        expect(model.notes, isNull);
        expect(model.clientNotes, isNull);
        expect(model.coachNotes, isNull);
      });

      test('未知狀態拋出錯誤', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['status'] = 'unknown_status';

        // Act & Assert
        expect(
          () => AppointmentModel.fromSupabase(json),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('解析跨日預約', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['time_range'] = '[2025-12-15 23:00:00+00,2025-12-16 01:00:00+00)';

        // Act
        final model = AppointmentModel.fromSupabase(json);

        // Assert
        expect(model.startTime.toUtc().day, 15);
        expect(model.endTime.toUtc().day, 16);
        expect(model.durationMinutes, 120);
      });
    });

    // =========================================================================
    // P1-60: toMap - 轉換為 Supabase 格式
    // =========================================================================
    group('toMap', () {
      test('正確轉換為 snake_case 格式', () {
        // Arrange
        final model = AppointmentModel.fromSupabase(validSupabaseJson);

        // Act
        final map = model.toMap();

        // Assert
        expect(map['coach_id'], 'coach-001');
        expect(map['client_id'], 'client-001');
        expect(map['status'], 'confirmed');
        expect(map['time_range'], isNotNull);
        expect(map['time_range'], contains('['));
        expect(map['time_range'], contains(','));
      });

      test('includeId=false 不包含 id', () {
        // Arrange
        final model = AppointmentModel.fromSupabase(validSupabaseJson);

        // Act
        final map = model.toMap(includeId: false);

        // Assert
        expect(map.containsKey('id'), isFalse);
      });

      test('includeId=true 包含 id', () {
        // Arrange
        final model = AppointmentModel.fromSupabase(validSupabaseJson);

        // Act
        final map = model.toMap(includeId: true);

        // Assert
        expect(map['id'], 'apt-001');
      });
    });

    // =========================================================================
    // P1-61: durationMinutes - 計算時長
    // =========================================================================
    group('durationMinutes', () {
      test('正確計算時長', () {
        // Arrange
        final model = AppointmentModel.fromSupabase(validSupabaseJson);

        // Act & Assert
        expect(model.durationMinutes, 60);
      });

      test('計算 2 小時時長', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['time_range'] = '[2025-12-15 09:00:00+00,2025-12-15 11:00:00+00)';
        final model = AppointmentModel.fromSupabase(json);

        // Act & Assert
        expect(model.durationMinutes, 120);
      });

      test('計算 30 分鐘時長', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['time_range'] = '[2025-12-15 09:00:00+00,2025-12-15 09:30:00+00)';
        final model = AppointmentModel.fromSupabase(json);

        // Act & Assert
        expect(model.durationMinutes, 30);
      });
    });

    // =========================================================================
    // P1-62-65: 狀態判斷 getters
    // =========================================================================
    group('status getters', () {
      test('isPending 正確判斷', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['status'] = 'requested';
        final model = AppointmentModel.fromSupabase(json);

        // Assert
        expect(model.isPending, isTrue);
        expect(model.isConfirmed, isFalse);
        expect(model.isCompleted, isFalse);
        expect(model.isCancelled, isFalse);
      });

      test('isConfirmed 正確判斷', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['status'] = 'confirmed';
        final model = AppointmentModel.fromSupabase(json);

        // Assert
        expect(model.isConfirmed, isTrue);
        expect(model.isPending, isFalse);
      });

      test('isCompleted 正確判斷', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['status'] = 'completed';
        final model = AppointmentModel.fromSupabase(json);

        // Assert
        expect(model.isCompleted, isTrue);
      });

      test('isCancelled 正確判斷', () {
        // Arrange
        final json = Map<String, dynamic>.from(validSupabaseJson);
        json['status'] = 'cancelled';
        final model = AppointmentModel.fromSupabase(json);

        // Assert
        expect(model.isCancelled, isTrue);
      });
    });

    // =========================================================================
    // P1-66: copyWith
    // =========================================================================
    group('copyWith', () {
      test('複製並修改狀態', () {
        // Arrange
        final model = AppointmentModel.fromSupabase(validSupabaseJson);

        // Act
        final updated = model.copyWith(status: AppointmentStatus.completed);

        // Assert
        expect(updated.status, AppointmentStatus.completed);
        expect(updated.id, model.id); // 其他不變
        expect(updated.coachId, model.coachId);
      });

      test('複製並修改備註', () {
        // Arrange
        final model = AppointmentModel.fromSupabase(validSupabaseJson);

        // Act
        final updated = model.copyWith(notes: '更新的備註');

        // Assert
        expect(updated.notes, '更新的備註');
        expect(updated.status, model.status);
      });

      test('複製並修改取消資訊', () {
        // Arrange
        final model = AppointmentModel.fromSupabase(validSupabaseJson);
        final cancelTime = DateTime.now();

        // Act
        final updated = model.copyWith(
          status: AppointmentStatus.cancelled,
          cancellationReason: '學員請假',
          cancelledBy: 'client-001',
          cancelledAt: cancelTime,
        );

        // Assert
        expect(updated.status, AppointmentStatus.cancelled);
        expect(updated.cancellationReason, '學員請假');
        expect(updated.cancelledBy, 'client-001');
        expect(updated.cancelledAt, cancelTime);
      });
    });
  });

  group('AppointmentStatus', () {
    // =========================================================================
    // P1-69: toSupabaseString
    // =========================================================================
    group('toSupabaseString', () {
      test('所有狀態正確轉換', () {
        expect(
          AppointmentStatus.requested.toSupabaseString(),
          'requested',
        );
        expect(
          AppointmentStatus.confirmed.toSupabaseString(),
          'confirmed',
        );
        expect(
          AppointmentStatus.completed.toSupabaseString(),
          'completed',
        );
        expect(
          AppointmentStatus.cancelled.toSupabaseString(),
          'cancelled',
        );
      });
    });

    // =========================================================================
    // P1-70: displayName
    // =========================================================================
    group('displayName', () {
      test('所有狀態有正確中文名稱', () {
        expect(AppointmentStatus.requested.displayName, '待確認');
        expect(AppointmentStatus.confirmed.displayName, '已確認');
        expect(AppointmentStatus.completed.displayName, '已完成');
        expect(AppointmentStatus.cancelled.displayName, '已取消');
      });
    });

    // =========================================================================
    // P1-71: colorHex
    // =========================================================================
    group('colorHex', () {
      test('所有狀態有對應顏色', () {
        expect(AppointmentStatus.requested.colorHex, '#FF9800');
        expect(AppointmentStatus.confirmed.colorHex, '#4CAF50');
        expect(AppointmentStatus.completed.colorHex, '#2196F3');
        expect(AppointmentStatus.cancelled.colorHex, '#F44336');
      });
    });
  });
}
