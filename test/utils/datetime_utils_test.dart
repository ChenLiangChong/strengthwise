import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/utils/datetime_utils.dart';

void main() {
  group('DateTimeUtils', () {
    group('parsePostgresTimestamp', () {
      test('解析無引號時間戳（返回本地時間）', () {
        final result = DateTimeUtils.parsePostgresTimestamp(
          '2025-12-15 09:00:00+00',
        );

        // ⭐ 現在返回本地時間（UTC+8 = 17:00）
        expect(result.year, 2025);
        expect(result.month, 12);
        expect(result.day, 15);
        // 本地時間會根據時區不同而不同，所以檢查 UTC 時間
        final utc = result.toUtc();
        expect(utc.hour, 9);
        expect(utc.minute, 0);
        expect(utc.second, 0);
      });

      test('解析有引號時間戳（返回本地時間）', () {
        final result = DateTimeUtils.parsePostgresTimestamp(
          '"2025-12-15 09:00:00+00"',
        );

        expect(result.year, 2025);
        expect(result.month, 12);
        expect(result.day, 15);
        // 檢查 UTC 時間
        expect(result.toUtc().hour, 9);
      });

      test('正確處理時區格式（+00 → +00:00）', () {
        final result = DateTimeUtils.parsePostgresTimestamp(
          '2025-12-15 09:00:00+00',
        );

        // 轉回 UTC 應該是 09:00
        expect(result.toUtc().hour, 9);
      });

      test('正確處理其他時區（+08）', () {
        final result = DateTimeUtils.parsePostgresTimestamp(
          '2025-12-15 09:00:00+08',
        );

        // 解析後轉換為 UTC 時間
        // 09:00 +08:00 = 01:00 UTC
        expect(result.toUtc().hour, 1);
        expect(result.toUtc().year, 2025);
        expect(result.toUtc().month, 12);
        expect(result.toUtc().day, 15);
      });

      test('處理負時區（-05）', () {
        final result = DateTimeUtils.parsePostgresTimestamp(
          '2025-12-15 09:00:00-05',
        );

        // 解析後轉換為 UTC 時間
        // 09:00 -05:00 = 14:00 UTC
        expect(result.toUtc().hour, 14);
        expect(result.toUtc().year, 2025);
        expect(result.toUtc().month, 12);
        expect(result.toUtc().day, 15);
      });
    });

    group('parsePostgresTimestampUtc', () {
      test('解析無引號時間戳（返回 UTC）', () {
        final result = DateTimeUtils.parsePostgresTimestampUtc(
          '2025-12-15 09:00:00+00',
        );

        expect(result.year, 2025);
        expect(result.month, 12);
        expect(result.day, 15);
        expect(result.hour, 9);
        expect(result.minute, 0);
        expect(result.second, 0);
        expect(result.isUtc, isTrue);
      });

      test('解析有引號時間戳（返回 UTC）', () {
        final result = DateTimeUtils.parsePostgresTimestampUtc(
          '"2025-12-15 09:00:00+00"',
        );

        expect(result.year, 2025);
        expect(result.month, 12);
        expect(result.day, 15);
        expect(result.hour, 9);
        expect(result.isUtc, isTrue);
      });
    });

    group('parseTstzRange', () {
      test('解析標準 TSTZRANGE（返回本地時間）', () {
        final result = DateTimeUtils.parseTstzRange(
          '[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)',
        );

        expect(result['start']!.year, 2025);
        expect(result['start']!.month, 12);
        expect(result['start']!.day, 15);
        // ⭐ 現在返回本地時間，檢查 UTC 時間
        expect(result['start']!.toUtc().hour, 9);
        expect(result['end']!.toUtc().hour, 10);
      });

      test('解析帶引號的 TSTZRANGE（返回本地時間）', () {
        final result = DateTimeUtils.parseTstzRange(
          '"[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)"',
        );

        expect(result['start'], isNotNull);
        expect(result['end'], isNotNull);
        expect(result['start']!.toUtc().hour, 9);
        expect(result['end']!.toUtc().hour, 10);
      });

      test('解析跨天 TSTZRANGE', () {
        final result = DateTimeUtils.parseTstzRange(
          '[2025-12-15 23:00:00+00,2025-12-16 01:00:00+00)',
        );

        // 檢查 UTC 日期
        expect(result['start']!.toUtc().day, 15);
        expect(result['end']!.toUtc().day, 16);
      });

      test('拋出錯誤：格式無效', () {
        expect(
          () => DateTimeUtils.parseTstzRange('invalid'),
          throwsFormatException,
        );
      });

      test('拋出錯誤：缺少逗號', () {
        expect(
          () => DateTimeUtils.parseTstzRange('[2025-12-15 09:00:00+00)'),
          throwsFormatException,
        );
      });
    });

    group('parseTstzRangeUtc', () {
      test('解析標準 TSTZRANGE（返回 UTC）', () {
        final result = DateTimeUtils.parseTstzRangeUtc(
          '[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)',
        );

        expect(result['start']!.year, 2025);
        expect(result['start']!.month, 12);
        expect(result['start']!.day, 15);
        expect(result['start']!.hour, 9);
        expect(result['end']!.hour, 10);
        expect(result['start']!.isUtc, isTrue);
        expect(result['end']!.isUtc, isTrue);
      });

      test('解析帶引號的 TSTZRANGE（返回 UTC）', () {
        final result = DateTimeUtils.parseTstzRangeUtc(
          '"[2025-12-15 09:00:00+00,2025-12-15 10:00:00+00)"',
        );

        expect(result['start'], isNotNull);
        expect(result['end'], isNotNull);
        expect(result['start']!.hour, 9);
        expect(result['end']!.hour, 10);
        expect(result['start']!.isUtc, isTrue);
      });
    });

    group('formatToTstzRange', () {
      test('格式化為 TSTZRANGE 字串', () {
        final start = DateTime.utc(2025, 12, 15, 9, 0);
        final end = DateTime.utc(2025, 12, 15, 10, 0);
        final result = DateTimeUtils.formatToTstzRange(start, end);

        expect(result, contains('['));
        expect(result, contains(','));
        expect(result, contains(')'));
        expect(result, contains('2025-12-15T09:00:00'));
        expect(result, contains('2025-12-15T10:00:00'));
      });

      test('自動轉換為 UTC', () {
        // 本地時間（假設 UTC+8）
        final start = DateTime(2025, 12, 15, 17, 0);
        final end = DateTime(2025, 12, 15, 18, 0);
        final result = DateTimeUtils.formatToTstzRange(start, end);

        // 應該轉換為 UTC 時間
        expect(result, isNotEmpty);
      });
    });

    group('getUtcDate', () {
      test('正確提取 UTC 日期（忽略時間）', () {
        final dt = DateTime.parse('2025-12-27T16:00:45Z');
        final result = DateTimeUtils.getUtcDate(dt);

        expect(result.year, 2025);
        expect(result.month, 12);
        expect(result.day, 27);
        expect(result.hour, 0);
        expect(result.minute, 0);
        expect(result.second, 0);
        expect(result.millisecond, 0);
        expect(result.microsecond, 0);
      });

      test('處理不同時區的時間', () {
        // UTC 時間：12/27 16:00
        // 本地時間（UTC+8）：12/28 00:00
        final dt = DateTime.parse('2025-12-27T16:00:00Z');
        final result = DateTimeUtils.getUtcDate(dt);

        // 應該返回 UTC 日期（12/27），而不是本地日期（12/28）
        expect(result.day, 27);
      });

      test('處理已是 UTC 的時間', () {
        final dt = DateTime.utc(2025, 12, 27, 23, 59, 59);
        final result = DateTimeUtils.getUtcDate(dt);

        expect(result.year, 2025);
        expect(result.month, 12);
        expect(result.day, 27);
        expect(result.hour, 0);
      });
    });

    group('compareUtcDates', () {
      test('相同日期返回 0', () {
        final dt1 = DateTime.parse('2025-12-27T09:00:00Z');
        final dt2 = DateTime.parse('2025-12-27T23:59:59Z');

        expect(DateTimeUtils.compareUtcDates(dt1, dt2), 0);
      });

      test('較早日期返回負數', () {
        final dt1 = DateTime.parse('2025-12-27T23:59:59Z');
        final dt2 = DateTime.parse('2025-12-28T00:00:00Z');

        expect(DateTimeUtils.compareUtcDates(dt1, dt2), lessThan(0));
      });

      test('較晚日期返回正數', () {
        final dt1 = DateTime.parse('2025-12-29T00:00:00Z');
        final dt2 = DateTime.parse('2025-12-28T23:59:59Z');

        expect(DateTimeUtils.compareUtcDates(dt1, dt2), greaterThan(0));
      });

      test('跨時區比較（時區邊界測試）', () {
        // UTC 12/27 23:59
        final dt1 = DateTime.parse('2025-12-27T23:59:59Z');
        // UTC 12/28 00:00
        final dt2 = DateTime.parse('2025-12-28T00:00:00Z');

        // 應該判斷為不同天
        expect(DateTimeUtils.compareUtcDates(dt1, dt2), lessThan(0));
      });
    });

    group('isSameUtcDate', () {
      test('相同 UTC 日期返回 true', () {
        final dt1 = DateTime.parse('2025-12-27T09:00:00Z');
        final dt2 = DateTime.parse('2025-12-27T23:59:59Z');

        expect(DateTimeUtils.isSameUtcDate(dt1, dt2), isTrue);
      });

      test('不同 UTC 日期返回 false', () {
        final dt1 = DateTime.parse('2025-12-27T23:59:59Z');
        final dt2 = DateTime.parse('2025-12-28T00:00:00Z');

        expect(DateTimeUtils.isSameUtcDate(dt1, dt2), isFalse);
      });

      test('跨時區但同一 UTC 日期', () {
        // UTC 12/27 16:00（UTC+8 是 12/28 00:00）
        final dt1 = DateTime.parse('2025-12-27T16:00:00Z');
        // UTC 12/27 08:00
        final dt2 = DateTime.parse('2025-12-27T08:00:00Z');

        // 應該判斷為同一天（UTC 日期都是 12/27）
        expect(DateTimeUtils.isSameUtcDate(dt1, dt2), isTrue);
      });
    });

    group('isWithinUtcDateRange', () {
      test('日期在範圍內', () {
        final target = DateTime.parse('2025-12-28T16:00:00Z');
        final start = DateTime.parse('2025-12-28T00:00:00Z');
        final end = DateTime.parse('2025-12-29T00:00:00Z');

        expect(
          DateTimeUtils.isWithinUtcDateRange(target, start, end),
          isTrue,
        );
      });

      test('日期在範圍外（之前）', () {
        final target = DateTime.parse('2025-12-27T23:59:59Z');
        final start = DateTime.parse('2025-12-28T00:00:00Z');
        final end = DateTime.parse('2025-12-29T00:00:00Z');

        expect(
          DateTimeUtils.isWithinUtcDateRange(target, start, end),
          isFalse,
        );
      });

      test('日期在範圍外（之後）', () {
        final target = DateTime.parse('2025-12-30T00:00:00Z');
        final start = DateTime.parse('2025-12-28T00:00:00Z');
        final end = DateTime.parse('2025-12-29T00:00:00Z');

        expect(
          DateTimeUtils.isWithinUtcDateRange(target, start, end),
          isFalse,
        );
      });

      test('邊界測試：範圍起始日', () {
        final target = DateTime.parse('2025-12-28T00:00:00Z');
        final start = DateTime.parse('2025-12-28T00:00:00Z');
        final end = DateTime.parse('2025-12-29T00:00:00Z');

        expect(
          DateTimeUtils.isWithinUtcDateRange(target, start, end),
          isTrue,
        );
      });

      test('邊界測試：範圍結束日', () {
        final target = DateTime.parse('2025-12-29T23:59:59Z');
        final start = DateTime.parse('2025-12-28T00:00:00Z');
        final end = DateTime.parse('2025-12-29T00:00:00Z');

        expect(
          DateTimeUtils.isWithinUtcDateRange(target, start, end),
          isTrue,
        );
      });

      test('時區邊界測試（核心用例）⭐', () {
        // 數據庫：12/27 16:00 UTC
        final target = DateTime.parse('2025-12-27T16:00:45Z');
        // 範圍：12/28 - 12/29（UTC 日期）
        // 注意：localDateToUtcDate 將本地日期解釋為 UTC 日期
        final start = DateTimeUtils.localDateToUtcDate(DateTime(2025, 12, 28));
        final end = DateTimeUtils.localDateToUtcDate(DateTime(2025, 12, 29));

        // 應該返回 false（12/27 UTC 不在 12/28-12/29 UTC 範圍內）
        expect(
          DateTimeUtils.isWithinUtcDateRange(target, start, end),
          isFalse,
        );
      });
    });

    group('localDateToUtcDate', () {
      test('本地日期轉 UTC 日期', () {
        // 用戶選擇：2025-12-28（本地時間）
        final localDate = DateTime(2025, 12, 28);
        final utcDate = DateTimeUtils.localDateToUtcDate(localDate);

        expect(utcDate.year, 2025);
        expect(utcDate.month, 12);
        expect(utcDate.day, 28);
        expect(utcDate.hour, 0);
        expect(utcDate.isUtc, isTrue);
      });

      test('只保留日期部分', () {
        final localDate = DateTime(2025, 12, 28, 15, 30, 45);
        final utcDate = DateTimeUtils.localDateToUtcDate(localDate);

        expect(utcDate.hour, 0);
        expect(utcDate.minute, 0);
        expect(utcDate.second, 0);
      });
    });
  });
}

