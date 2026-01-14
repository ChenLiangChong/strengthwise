import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/statistics/time_range.dart';
import 'package:strengthwise/models/statistics/personal_record.dart';

/// Statistics 模組測試
void main() {
  group('TimeRange', () {
    group('枚舉值', () {
      test('應該有 5 種時間範圍', () {
        expect(TimeRange.values.length, 5);
      });

      test('包含所有預期的時間範圍', () {
        expect(TimeRange.values, contains(TimeRange.week));
        expect(TimeRange.values, contains(TimeRange.sevenDays));
        expect(TimeRange.values, contains(TimeRange.month));
        expect(TimeRange.values, contains(TimeRange.threeMonth));
        expect(TimeRange.values, contains(TimeRange.year));
      });
    });

    group('displayName', () {
      test('week → 本週', () {
        expect(TimeRange.week.displayName, '本週');
      });

      test('sevenDays → 最近七天', () {
        expect(TimeRange.sevenDays.displayName, '最近七天');
      });

      test('month → 本月', () {
        expect(TimeRange.month.displayName, '本月');
      });

      test('threeMonth → 三個月', () {
        expect(TimeRange.threeMonth.displayName, '三個月');
      });

      test('year → 本年', () {
        expect(TimeRange.year.displayName, '本年');
      });

      test('所有範圍都有顯示名稱', () {
        for (final range in TimeRange.values) {
          expect(range.displayName, isNotEmpty);
        }
      });
    });

    group('startDate', () {
      test('week 應該從週一開始', () {
        final startDate = TimeRange.week.startDate;
        // weekday 1 = Monday
        expect(startDate.weekday, 1);
        // 應該是當天的開始（00:00:00）
        expect(startDate.hour, 0);
        expect(startDate.minute, 0);
        expect(startDate.second, 0);
      });

      test('sevenDays 應該往前推 7 天', () {
        final now = DateTime.now();
        final startDate = TimeRange.sevenDays.startDate;
        final difference = now.difference(startDate).inDays;
        // 差距應該約為 7 天
        expect(difference, greaterThanOrEqualTo(6));
        expect(difference, lessThanOrEqualTo(7));
      });

      test('month 應該從本月 1 日開始', () {
        final now = DateTime.now();
        final startDate = TimeRange.month.startDate;
        expect(startDate.year, now.year);
        expect(startDate.month, now.month);
        expect(startDate.day, 1);
      });

      test('year 應該從 1 月 1 日開始', () {
        final now = DateTime.now();
        final startDate = TimeRange.year.startDate;
        expect(startDate.year, now.year);
        expect(startDate.month, 1);
        expect(startDate.day, 1);
      });
    });

    group('endDate', () {
      test('應該是當天的 23:59:59', () {
        final endDate = TimeRange.week.endDate;
        final now = DateTime.now();
        expect(endDate.year, now.year);
        expect(endDate.month, now.month);
        expect(endDate.day, now.day);
        expect(endDate.hour, 23);
        expect(endDate.minute, 59);
        expect(endDate.second, 59);
      });
    });
  });

  group('PersonalRecord', () {
    final testDate = DateTime(2026, 1, 14);

    PersonalRecord createTestRecord() {
      return PersonalRecord(
        exerciseId: 'ex-001',
        exerciseName: '深蹲',
        maxWeight: 100.0,
        reps: 5,
        achievedDate: testDate,
        bodyPart: '腿部',
        isNew: true,
      );
    }

    test('應該正確建立實例', () {
      final record = createTestRecord();

      expect(record.exerciseId, 'ex-001');
      expect(record.exerciseName, '深蹲');
      expect(record.maxWeight, 100.0);
      expect(record.reps, 5);
      expect(record.achievedDate, testDate);
      expect(record.bodyPart, '腿部');
      expect(record.isNew, isTrue);
    });

    test('isNew 預設為 false', () {
      final record = PersonalRecord(
        exerciseId: 'ex-001',
        exerciseName: '深蹲',
        maxWeight: 100.0,
        reps: 5,
        achievedDate: testDate,
        bodyPart: '腿部',
      );

      expect(record.isNew, isFalse);
    });

    group('formattedWeight', () {
      test('應該正確格式化整數重量', () {
        final record = PersonalRecord(
          exerciseId: 'ex-001',
          exerciseName: '深蹲',
          maxWeight: 100.0,
          reps: 5,
          achievedDate: testDate,
          bodyPart: '腿部',
        );

        expect(record.formattedWeight, '100.0 kg × 5');
      });

      test('應該正確格式化小數重量', () {
        final record = PersonalRecord(
          exerciseId: 'ex-001',
          exerciseName: '臥推',
          maxWeight: 62.5,
          reps: 8,
          achievedDate: testDate,
          bodyPart: '胸部',
        );

        expect(record.formattedWeight, '62.5 kg × 8');
      });
    });

    group('formattedDate', () {
      test('應該正確格式化日期', () {
        final record = createTestRecord();

        expect(record.formattedDate, '2026-01-14');
      });

      test('月份和日期應該補零', () {
        final record = PersonalRecord(
          exerciseId: 'ex-001',
          exerciseName: '深蹲',
          maxWeight: 100.0,
          reps: 5,
          achievedDate: DateTime(2026, 3, 5),
          bodyPart: '腿部',
        );

        expect(record.formattedDate, '2026-03-05');
      });
    });

    test('toString 應該返回可讀格式', () {
      final record = createTestRecord();
      final str = record.toString();

      expect(str, contains('深蹲'));
      expect(str, contains('100.0'));
    });
  });
}
