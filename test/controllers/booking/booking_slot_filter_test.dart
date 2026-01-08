import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/controllers/booking/booking_slot_filter.dart';

/// BookingSlotFilter 測試
///
/// P10 優先級 - 8 個測試案例（Edge Cases）
void main() {
  group('BookingSlotFilter', () {
    // =========================================================================
    // filterExpiredSlots
    // =========================================================================
    group('filterExpiredSlots', () {
      test('空列表返回空列表', () {
        final result = BookingSlotFilter.filterExpiredSlots([]);
        expect(result, isEmpty);
      });

      test('過濾掉過期時段', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final tomorrow = DateTime.now().add(const Duration(days: 1));

        final slots = [
          {'id': '1', 'dateTime': yesterday},
          {'id': '2', 'dateTime': tomorrow},
        ];

        final result = BookingSlotFilter.filterExpiredSlots(slots);
        expect(result.length, 1);
        expect(result[0]['id'], '2');
      });

      test('保留未來時段', () {
        final future1 = DateTime.now().add(const Duration(hours: 1));
        final future2 = DateTime.now().add(const Duration(hours: 2));

        final slots = [
          {'id': '1', 'dateTime': future1},
          {'id': '2', 'dateTime': future2},
        ];

        final result = BookingSlotFilter.filterExpiredSlots(slots);
        expect(result.length, 2);
      });

      test('過濾掉 dateTime 為 null 的時段', () {
        final future = DateTime.now().add(const Duration(hours: 1));

        final slots = [
          {'id': '1', 'dateTime': null},
          {'id': '2', 'dateTime': future},
        ];

        final result = BookingSlotFilter.filterExpiredSlots(slots);
        expect(result.length, 1);
        expect(result[0]['id'], '2');
      });

      test('過濾掉缺少 dateTime 的時段', () {
        final future = DateTime.now().add(const Duration(hours: 1));

        final slots = [
          {'id': '1'},
          {'id': '2', 'dateTime': future},
        ];

        final result = BookingSlotFilter.filterExpiredSlots(slots);
        expect(result.length, 1);
        expect(result[0]['id'], '2');
      });

      test('剛剛過期的時段被過濾', () {
        // 1 秒前
        final justPassed = DateTime.now().subtract(const Duration(seconds: 1));
        final future = DateTime.now().add(const Duration(hours: 1));

        final slots = [
          {'id': '1', 'dateTime': justPassed},
          {'id': '2', 'dateTime': future},
        ];

        final result = BookingSlotFilter.filterExpiredSlots(slots);
        expect(result.length, 1);
        expect(result[0]['id'], '2');
      });

      test('所有時段都過期返回空列表', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final lastWeek = DateTime.now().subtract(const Duration(days: 7));

        final slots = [
          {'id': '1', 'dateTime': yesterday},
          {'id': '2', 'dateTime': lastWeek},
        ];

        final result = BookingSlotFilter.filterExpiredSlots(slots);
        expect(result, isEmpty);
      });

      test('保留其他欄位', () {
        final future = DateTime.now().add(const Duration(hours: 1));

        final slots = [
          {
            'id': '1',
            'dateTime': future,
            'coachName': '教練A',
            'duration': 60,
          },
        ];

        final result = BookingSlotFilter.filterExpiredSlots(slots);
        expect(result.length, 1);
        expect(result[0]['coachName'], '教練A');
        expect(result[0]['duration'], 60);
      });
    });
  });
}
