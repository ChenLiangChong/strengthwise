import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/user/user_timestamp_parser.dart';

/// UserTimestampParser 測試
///
/// P1 Models 層 - 10 個測試案例
void main() {
  group('UserTimestampParser', () {
    // =========================================================================
    // parse 方法
    // =========================================================================
    group('parse', () {
      test('null 輸入返回 null', () {
        expect(UserTimestampParser.parse(null), isNull);
      });

      test('DateTime 類型直接返回', () {
        final dt = DateTime(2024, 6, 15, 10, 30);
        final result = UserTimestampParser.parse(dt);
        expect(result, dt);
      });

      test('int 類型解析為毫秒時間戳', () {
        final timestamp = DateTime(2024, 1, 1).millisecondsSinceEpoch;
        final result = UserTimestampParser.parse(timestamp);
        expect(result?.year, 2024);
        expect(result?.month, 1);
        expect(result?.day, 1);
      });

      test('ISO 8601 字串解析', () {
        final result = UserTimestampParser.parse('2024-06-15T10:30:00Z');
        expect(result?.year, 2024);
        expect(result?.month, 6);
        expect(result?.day, 15);
      });

      test('帶時區的 ISO 字串解析', () {
        final result = UserTimestampParser.parse('2024-06-15T10:30:00+08:00');
        expect(result, isNotNull);
        expect(result?.year, 2024);
      });

      test('無效字串返回 null', () {
        final result = UserTimestampParser.parse('invalid-date');
        expect(result, isNull);
      });

      test('空字串返回 null', () {
        final result = UserTimestampParser.parse('');
        expect(result, isNull);
      });

      test('處理 0 時間戳', () {
        final result = UserTimestampParser.parse(0);
        expect(result, isNotNull);
        expect(result?.year, 1970);
      });

      test('處理負數時間戳', () {
        final result = UserTimestampParser.parse(-1000);
        expect(result, isNotNull);
      });

      test('未知類型返回 null', () {
        final result = UserTimestampParser.parse([1, 2, 3]);
        expect(result, isNull);
      });
    });
  });
}
