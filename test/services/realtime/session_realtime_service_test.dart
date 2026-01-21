import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/services/interfaces/i_notification_service.dart';

/// SessionRealtimeService 和通知類型測試
///
/// P6 優先級 - 5 個測試案例
///
/// 注意：SessionRealtimeService 直接依賴 Supabase Realtime，
/// 需要整合測試環境，這裡測試相關的純邏輯部分
void main() {
  group('NotificationType 解析', () {
    // =========================================================================
    // P6-304: 解析預約相關通知類型
    // =========================================================================
    test('解析 new_appointment', () {
      expect(parseNotificationType('new_appointment'),
          NotificationType.newAppointment);
    });

    test('解析 appointment_confirmed', () {
      expect(parseNotificationType('appointment_confirmed'),
          NotificationType.appointmentConfirmed);
    });

    test('解析 appointment_rejected', () {
      expect(parseNotificationType('appointment_rejected'),
          NotificationType.appointmentRejected);
    });

    test('解析 appointment_cancelled', () {
      expect(parseNotificationType('appointment_cancelled'),
          NotificationType.appointmentCancelled);
    });

    // =========================================================================
    // P6-305: 解析其他通知類型
    // =========================================================================
    test('解析 session_reminder', () {
      expect(parseNotificationType('session_reminder'),
          NotificationType.sessionReminder);
    });

    test('解析 readiness_submitted', () {
      expect(parseNotificationType('readiness_submitted'),
          NotificationType.readinessSubmitted);
    });

    // =========================================================================
    // P6-306: 未知類型處理
    // =========================================================================
    test('未知類型返回 general', () {
      expect(parseNotificationType('unknown_type'), NotificationType.general);
    });

    test('null 返回 general', () {
      expect(parseNotificationType(null), NotificationType.general);
    });

    // =========================================================================
    // P6-307: 枚舉值完整性
    // =========================================================================
    test('NotificationType 枚舉包含所有預期值', () {
      // v3.9+ 新增了 7 個通知類型
      expect(NotificationType.values.length, 14);
      // 預約相關
      expect(
          NotificationType.values, contains(NotificationType.newAppointment));
      expect(NotificationType.values,
          contains(NotificationType.appointmentConfirmed));
      expect(NotificationType.values,
          contains(NotificationType.appointmentRejected));
      expect(NotificationType.values,
          contains(NotificationType.appointmentCancelled));
      expect(
          NotificationType.values, contains(NotificationType.sessionReminder));
      expect(NotificationType.values,
          contains(NotificationType.readinessSubmitted));
      // 時段相關（v3.9 新增）
      expect(
          NotificationType.values, contains(NotificationType.coachSlotCreated));
      expect(
          NotificationType.values, contains(NotificationType.coachSlotDeleted));
      expect(NotificationType.values,
          contains(NotificationType.clientAvailabilityCreated));
      expect(NotificationType.values,
          contains(NotificationType.clientAvailabilityUpdated));
      // 關係相關（v3.9 新增）
      expect(NotificationType.values,
          contains(NotificationType.relationshipCreated));
      expect(NotificationType.values,
          contains(NotificationType.relationshipArchived));
      // 課程筆記（v3.9 新增）
      expect(NotificationType.values,
          contains(NotificationType.sessionNoteShared));
      // 一般通知
      expect(NotificationType.values, contains(NotificationType.general));
    });

    // =========================================================================
    // P6-308: 解析空字串
    // =========================================================================
    test('空字串返回 general', () {
      expect(parseNotificationType(''), NotificationType.general);
    });
  });
}
