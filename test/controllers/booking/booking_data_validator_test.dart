import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/controllers/booking/booking_data_validator.dart';

/// BookingDataValidator 測試
///
/// P10 優先級 - 8 個測試案例（安全/Edge Cases）
void main() {
  group('BookingDataValidator', () {
    // =========================================================================
    // validateCreateBooking
    // =========================================================================
    group('validateCreateBooking', () {
      test('有效數據不拋出異常', () {
        expect(
          () => BookingDataValidator.validateCreateBooking({
            'coachId': 'coach-001',
            'dateTime': DateTime.now(),
          }),
          returnsNormally,
        );
      });

      test('缺少 coachId 拋出 ArgumentError', () {
        expect(
          () => BookingDataValidator.validateCreateBooking({
            'dateTime': DateTime.now(),
          }),
          throwsArgumentError,
        );
      });

      test('coachId 為空字串拋出 ArgumentError', () {
        expect(
          () => BookingDataValidator.validateCreateBooking({
            'coachId': '',
            'dateTime': DateTime.now(),
          }),
          throwsArgumentError,
        );
      });

      test('coachId 為 null 拋出 ArgumentError', () {
        expect(
          () => BookingDataValidator.validateCreateBooking({
            'coachId': null,
            'dateTime': DateTime.now(),
          }),
          throwsArgumentError,
        );
      });

      test('缺少 dateTime 拋出 ArgumentError', () {
        expect(
          () => BookingDataValidator.validateCreateBooking({
            'coachId': 'coach-001',
          }),
          throwsArgumentError,
        );
      });

      test('dateTime 為 null 拋出 ArgumentError', () {
        expect(
          () => BookingDataValidator.validateCreateBooking({
            'coachId': 'coach-001',
            'dateTime': null,
          }),
          throwsArgumentError,
        );
      });

      test('空 Map 拋出 ArgumentError', () {
        expect(
          () => BookingDataValidator.validateCreateBooking({}),
          throwsArgumentError,
        );
      });
    });
  });
}
