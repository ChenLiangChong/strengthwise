import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/availability_slot_model.dart';

/// AvailabilitySlotModel 及其相關類別測試
void main() {
  group('RecurrenceFrequency', () {
    test('應該有 3 種頻率', () {
      expect(RecurrenceFrequency.values.length, 3);
    });

    group('displayName', () {
      test('daily → 每日', () {
        expect(RecurrenceFrequency.daily.displayName, '每日');
      });

      test('weekly → 每週', () {
        expect(RecurrenceFrequency.weekly.displayName, '每週');
      });

      test('monthly → 每月', () {
        expect(RecurrenceFrequency.monthly.displayName, '每月');
      });
    });
  });

  group('RecurrenceRule', () {
    group('parse', () {
      test('應該解析基本 FREQ', () {
        final rule = RecurrenceRule.parse('FREQ=WEEKLY');

        expect(rule.frequency, RecurrenceFrequency.weekly);
        expect(rule.byDay, isNull);
        expect(rule.until, isNull);
      });

      test('應該解析 BYDAY', () {
        final rule = RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=MO,WE,FR');

        expect(rule.frequency, RecurrenceFrequency.weekly);
        expect(rule.byDay, [1, 3, 5]);
      });

      test('缺少 FREQ 應該拋出異常', () {
        expect(
          () => RecurrenceRule.parse('BYDAY=MO'),
          throwsA(isA<FormatException>()),
        );
      });

      test('無效星期應該拋出異常', () {
        expect(
          () => RecurrenceRule.parse('FREQ=WEEKLY;BYDAY=XX'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('toRRuleString', () {
      test('應該正確轉換基本規則', () {
        final rule = RecurrenceRule(frequency: RecurrenceFrequency.weekly);
        expect(rule.toRRuleString(), 'FREQ=WEEKLY');
      });

      test('應該正確轉換含 BYDAY 的規則', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          byDay: [1, 3, 5],
        );

        expect(rule.toRRuleString(), 'FREQ=WEEKLY;BYDAY=MO,WE,FR');
      });

      test('parse → toRRuleString 往返應該一致', () {
        const original = 'FREQ=WEEKLY;BYDAY=TU,TH';
        final parsed = RecurrenceRule.parse(original);
        final result = parsed.toRRuleString();

        expect(result, original);
      });
    });

    group('displayName', () {
      test('無 BYDAY 應該返回頻率名稱', () {
        final rule = RecurrenceRule(frequency: RecurrenceFrequency.daily);
        expect(rule.displayName, '每日');
      });

      test('有 BYDAY 應該返回星期列表', () {
        final rule = RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          byDay: [1, 3, 5],
        );

        expect(rule.displayName, '每週（週一、週三、週五）');
      });
    });
  });

  group('AvailabilitySlotModel', () {
    final testStart = DateTime(2026, 1, 14, 10, 0);
    final testEnd = DateTime(2026, 1, 14, 12, 0);
    final testCreated = DateTime(2026, 1, 1);
    final testUpdated = DateTime(2026, 1, 10);

    AvailabilitySlotModel createTestSlot({
      String? recurrenceRule,
      bool isOverride = false,
    }) {
      return AvailabilitySlotModel(
        id: 'slot-001',
        coachId: 'coach-001',
        startTime: testStart,
        endTime: testEnd,
        recurrenceRule: recurrenceRule,
        isOverride: isOverride,
        notes: '測試時段',
        createdAt: testCreated,
        updatedAt: testUpdated,
      );
    }

    test('應該正確建立實例', () {
      final slot = createTestSlot();

      expect(slot.id, 'slot-001');
      expect(slot.coachId, 'coach-001');
      expect(slot.startTime, testStart);
      expect(slot.endTime, testEnd);
    });

    group('durationMinutes', () {
      test('應該正確計算時長', () {
        final slot = createTestSlot();
        expect(slot.durationMinutes, 120);
      });
    });

    group('isRecurring / isOneTime', () {
      test('有週期規則應該是週期性', () {
        final slot = createTestSlot(recurrenceRule: 'FREQ=WEEKLY');

        expect(slot.isRecurring, isTrue);
        expect(slot.isOneTime, isFalse);
      });

      test('無週期規則應該是單次', () {
        final slot = createTestSlot();

        expect(slot.isRecurring, isFalse);
        expect(slot.isOneTime, isTrue);
      });
    });

    group('isInRange', () {
      test('時段在範圍內應該返回 true', () {
        final slot = createTestSlot();
        final rangeStart = DateTime(2026, 1, 14, 9, 0);
        final rangeEnd = DateTime(2026, 1, 14, 13, 0);

        expect(slot.isInRange(rangeStart, rangeEnd), isTrue);
      });

      test('時段在範圍外應該返回 false', () {
        final slot = createTestSlot();
        final rangeStart = DateTime(2026, 1, 15, 9, 0);
        final rangeEnd = DateTime(2026, 1, 15, 13, 0);

        expect(slot.isInRange(rangeStart, rangeEnd), isFalse);
      });
    });

    group('overlaps', () {
      test('重疊時段應該返回 true', () {
        final slot1 = createTestSlot();
        final slot2 = AvailabilitySlotModel(
          id: 'slot-002',
          coachId: 'coach-001',
          startTime: DateTime(2026, 1, 14, 11, 0), // 重疊
          endTime: DateTime(2026, 1, 14, 13, 0),
          createdAt: testCreated,
          updatedAt: testUpdated,
        );

        expect(slot1.overlaps(slot2), isTrue);
      });

      test('不重疊時段應該返回 false', () {
        final slot1 = createTestSlot();
        final slot2 = AvailabilitySlotModel(
          id: 'slot-002',
          coachId: 'coach-001',
          startTime: DateTime(2026, 1, 14, 14, 0), // 不重疊
          endTime: DateTime(2026, 1, 14, 16, 0),
          createdAt: testCreated,
          updatedAt: testUpdated,
        );

        expect(slot1.overlaps(slot2), isFalse);
      });
    });

    group('contains', () {
      test('時間點在時段內應該返回 true', () {
        final slot = createTestSlot();
        final time = DateTime(2026, 1, 14, 11, 0);

        expect(slot.contains(time), isTrue);
      });

      test('時間點在時段外應該返回 false', () {
        final slot = createTestSlot();
        final time = DateTime(2026, 1, 14, 9, 0);

        expect(slot.contains(time), isFalse);
      });
    });

    group('displayTimeRange', () {
      test('應該正確格式化時間範圍', () {
        final slot = createTestSlot();

        expect(slot.displayTimeRange, '10:00 - 12:00');
      });
    });

    group('getRecurrenceDescription', () {
      test('單次時段應該返回「單次時段」', () {
        final slot = createTestSlot();
        expect(slot.getRecurrenceDescription(), '單次時段');
      });

      test('週期性時段應該返回描述', () {
        final slot = createTestSlot(recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO');
        expect(slot.getRecurrenceDescription(), '每週（週一）');
      });
    });

    group('copyWith', () {
      test('應該複製並修改指定欄位', () {
        final original = createTestSlot();
        final copied = original.copyWith(notes: '新備註');

        expect(copied.id, original.id);
        expect(copied.notes, '新備註');
      });
    });

    group('toMap', () {
      test('includeId=true 應該包含 id', () {
        final slot = createTestSlot();
        final map = slot.toMap(includeId: true);

        expect(map.containsKey('id'), isTrue);
      });

      test('includeId=false 不應該包含 id', () {
        final slot = createTestSlot();
        final map = slot.toMap(includeId: false);

        expect(map.containsKey('id'), isFalse);
      });

      test('應該包含 time_range 格式', () {
        final slot = createTestSlot();
        final map = slot.toMap();

        expect(map['time_range'], isNotNull);
        expect(map['time_range'].toString(), contains('['));
      });
    });
  });
}
