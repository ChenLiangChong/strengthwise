import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/utils/date_format_utils.dart';

/// DateFormatUtils 測試
///
/// P0 Utils 層 - 12 個測試案例
void main() {
  group('DateFormatUtils', () {
    // =========================================================================
    // formatRelativeDate
    // =========================================================================
    group('formatRelativeDate', () {
      test('今天返回「今天」', () {
        final today = DateTime.now();
        expect(DateFormatUtils.formatRelativeDate(today), '今天');
      });

      test('昨天返回「昨天」', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(DateFormatUtils.formatRelativeDate(yesterday), '昨天');
      });

      test('2 天前返回「2 天前」', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        expect(DateFormatUtils.formatRelativeDate(twoDaysAgo), '2 天前');
      });

      test('6 天前返回「6 天前」', () {
        final sixDaysAgo = DateTime.now().subtract(const Duration(days: 6));
        expect(DateFormatUtils.formatRelativeDate(sixDaysAgo), '6 天前');
      });

      test('7 天前返回「1 週前」', () {
        final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
        expect(DateFormatUtils.formatRelativeDate(oneWeekAgo), '1 週前');
      });

      test('14 天前返回「2 週前」', () {
        final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));
        expect(DateFormatUtils.formatRelativeDate(twoWeeksAgo), '2 週前');
      });

      test('30 天前返回日期格式', () {
        final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
        final expected = '${oneMonthAgo.month}/${oneMonthAgo.day}';
        expect(DateFormatUtils.formatRelativeDate(oneMonthAgo), expected);
      });
    });

    // =========================================================================
    // formatDate
    // =========================================================================
    group('formatDate', () {
      test('今天返回「今天」', () {
        final today = DateTime.now();
        expect(DateFormatUtils.formatDate(today), '今天');
      });

      test('同年返回「M月D日」', () {
        final now = DateTime.now();
        // 使用明天或其他日期
        final otherDay = DateTime(now.year, now.month, now.day + 1);
        if (otherDay.year == now.year) {
          final expected = '${otherDay.month}月${otherDay.day}日';
          expect(DateFormatUtils.formatDate(otherDay), expected);
        }
      });

      test('跨年返回「YYYY/M/D」', () {
        final lastYear = DateTime(DateTime.now().year - 1, 6, 15);
        final expected = '${lastYear.year}/${lastYear.month}/${lastYear.day}';
        expect(DateFormatUtils.formatDate(lastYear), expected);
      });

      test('處理年初日期', () {
        final jan1 = DateTime(DateTime.now().year, 1, 1);
        if (DateTime.now().day == 1 && DateTime.now().month == 1) {
          expect(DateFormatUtils.formatDate(jan1), '今天');
        } else {
          expect(DateFormatUtils.formatDate(jan1), '1月1日');
        }
      });

      test('處理年末日期', () {
        final dec31 = DateTime(DateTime.now().year, 12, 31);
        if (DateTime.now().day == 31 && DateTime.now().month == 12) {
          expect(DateFormatUtils.formatDate(dec31), '今天');
        } else {
          expect(DateFormatUtils.formatDate(dec31), '12月31日');
        }
      });
    });
  });
}
