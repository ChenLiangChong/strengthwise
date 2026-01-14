import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/tracking_mode.dart';

/// TrackingMode 枚舉測試
///
/// 測試追蹤模式的所有功能
void main() {
  group('TrackingMode 枚舉值', () {
    test('應該有 8 種追蹤模式', () {
      expect(TrackingMode.values.length, 8);
    });

    test('包含所有預期的追蹤模式', () {
      expect(TrackingMode.values, contains(TrackingMode.weightReps));
      expect(TrackingMode.values, contains(TrackingMode.weightTime));
      expect(TrackingMode.values, contains(TrackingMode.repsOnly));
      expect(TrackingMode.values, contains(TrackingMode.timeOnly));
      expect(TrackingMode.values, contains(TrackingMode.repsTime));
      expect(TrackingMode.values, contains(TrackingMode.distanceTime));
      expect(TrackingMode.values, contains(TrackingMode.distanceOnly));
      expect(TrackingMode.values, contains(TrackingMode.calories));
    });
  });

  group('TrackingMode.toJson', () {
    test('weightReps → weight_reps', () {
      expect(TrackingMode.weightReps.toJson(), 'weight_reps');
    });

    test('weightTime → weight_time', () {
      expect(TrackingMode.weightTime.toJson(), 'weight_time');
    });

    test('repsOnly → reps_only', () {
      expect(TrackingMode.repsOnly.toJson(), 'reps_only');
    });

    test('timeOnly → time_only', () {
      expect(TrackingMode.timeOnly.toJson(), 'time_only');
    });

    test('distanceTime → distance_time', () {
      expect(TrackingMode.distanceTime.toJson(), 'distance_time');
    });

    test('calories → calories', () {
      expect(TrackingMode.calories.toJson(), 'calories');
    });
  });

  group('TrackingModeExtension.fromJson', () {
    test('weight_reps → weightReps', () {
      expect(TrackingModeExtension.fromJson('weight_reps'),
          TrackingMode.weightReps);
    });

    test('weight_time → weightTime', () {
      expect(TrackingModeExtension.fromJson('weight_time'),
          TrackingMode.weightTime);
    });

    test('null → weightReps (預設)', () {
      expect(TrackingModeExtension.fromJson(null), TrackingMode.weightReps);
    });

    test('未知值 → weightReps (預設)', () {
      expect(
          TrackingModeExtension.fromJson('unknown'), TrackingMode.weightReps);
    });
  });

  group('TrackingMode.displayName', () {
    test('weightReps → 重量 & 次數', () {
      expect(TrackingMode.weightReps.displayName, '重量 & 次數');
    });

    test('timeOnly → 僅時間', () {
      expect(TrackingMode.timeOnly.displayName, '僅時間');
    });

    test('calories → 卡路里', () {
      expect(TrackingMode.calories.displayName, '卡路里');
    });

    test('所有模式都有顯示名稱', () {
      for (final mode in TrackingMode.values) {
        expect(mode.displayName, isNotEmpty);
      }
    });
  });

  group('TrackingMode.description', () {
    test('weightReps 描述包含重訓', () {
      expect(TrackingMode.weightReps.description, contains('重訓'));
    });

    test('所有模式都有描述', () {
      for (final mode in TrackingMode.values) {
        expect(mode.description, isNotEmpty);
      }
    });
  });

  group('TrackingMode.needsWeight', () {
    test('weightReps 需要重量', () {
      expect(TrackingMode.weightReps.needsWeight, isTrue);
    });

    test('weightTime 需要重量', () {
      expect(TrackingMode.weightTime.needsWeight, isTrue);
    });

    test('repsOnly 不需要重量', () {
      expect(TrackingMode.repsOnly.needsWeight, isFalse);
    });

    test('calories 不需要重量', () {
      expect(TrackingMode.calories.needsWeight, isFalse);
    });
  });

  group('TrackingMode.needsReps', () {
    test('weightReps 需要次數', () {
      expect(TrackingMode.weightReps.needsReps, isTrue);
    });

    test('repsOnly 需要次數', () {
      expect(TrackingMode.repsOnly.needsReps, isTrue);
    });

    test('repsTime 需要次數', () {
      expect(TrackingMode.repsTime.needsReps, isTrue);
    });

    test('timeOnly 不需要次數', () {
      expect(TrackingMode.timeOnly.needsReps, isFalse);
    });
  });

  group('TrackingMode.needsTime', () {
    test('weightTime 需要時間', () {
      expect(TrackingMode.weightTime.needsTime, isTrue);
    });

    test('timeOnly 需要時間', () {
      expect(TrackingMode.timeOnly.needsTime, isTrue);
    });

    test('distanceTime 需要時間', () {
      expect(TrackingMode.distanceTime.needsTime, isTrue);
    });

    test('weightReps 不需要時間', () {
      expect(TrackingMode.weightReps.needsTime, isFalse);
    });
  });

  group('TrackingMode.needsDistance', () {
    test('distanceTime 需要距離', () {
      expect(TrackingMode.distanceTime.needsDistance, isTrue);
    });

    test('distanceOnly 需要距離', () {
      expect(TrackingMode.distanceOnly.needsDistance, isTrue);
    });

    test('weightReps 不需要距離', () {
      expect(TrackingMode.weightReps.needsDistance, isFalse);
    });
  });

  group('TrackingMode.needsCalories', () {
    test('calories 需要卡路里', () {
      expect(TrackingMode.calories.needsCalories, isTrue);
    });

    test('weightReps 不需要卡路里', () {
      expect(TrackingMode.weightReps.needsCalories, isFalse);
    });
  });

  group('TrackingMode.contributesToStats', () {
    test('weightReps 納入統計', () {
      expect(TrackingMode.weightReps.contributesToStats, isTrue);
    });

    test('其他模式不納入統計', () {
      expect(TrackingMode.timeOnly.contributesToStats, isFalse);
      expect(TrackingMode.calories.contributesToStats, isFalse);
      expect(TrackingMode.distanceTime.contributesToStats, isFalse);
    });
  });

  group('TrackingMode.isWeightBased', () {
    test('weightReps 是重量導向', () {
      expect(TrackingMode.weightReps.isWeightBased, isTrue);
    });

    test('weightTime 是重量導向', () {
      expect(TrackingMode.weightTime.isWeightBased, isTrue);
    });

    test('repsOnly 不是重量導向', () {
      expect(TrackingMode.repsOnly.isWeightBased, isFalse);
    });
  });

  group('TrackingMode.inputFields', () {
    test('weightReps 欄位為 [weight, reps]', () {
      expect(TrackingMode.weightReps.inputFields, ['weight', 'reps']);
    });

    test('timeOnly 欄位為 [time]', () {
      expect(TrackingMode.timeOnly.inputFields, ['time']);
    });

    test('distanceTime 欄位為 [distance, time]', () {
      expect(TrackingMode.distanceTime.inputFields, ['distance', 'time']);
    });

    test('calories 欄位為 [calories]', () {
      expect(TrackingMode.calories.inputFields, ['calories']);
    });
  });

  group('TrackingModeFormatter.formatTime', () {
    test('30秒 → 30秒', () {
      expect(TrackingModeFormatter.formatTime(30), '30秒');
    });

    test('60秒 → 1:00', () {
      expect(TrackingModeFormatter.formatTime(60), '1:00');
    });

    test('90秒 → 1:30', () {
      expect(TrackingModeFormatter.formatTime(90), '1:30');
    });

    test('125秒 → 2:05', () {
      expect(TrackingModeFormatter.formatTime(125), '2:05');
    });
  });

  group('TrackingModeFormatter.formatDistance', () {
    test('500m → 500m', () {
      expect(TrackingModeFormatter.formatDistance(500), '500m');
    });

    test('1000m → 1km', () {
      expect(TrackingModeFormatter.formatDistance(1000), '1km');
    });

    test('1500m → 1.5km', () {
      expect(TrackingModeFormatter.formatDistance(1500), '1.5km');
    });

    test('5000m → 5km', () {
      expect(TrackingModeFormatter.formatDistance(5000), '5km');
    });
  });

  group('TrackingModeFormatter.formatCalories', () {
    test('200卡 → 200卡', () {
      expect(TrackingModeFormatter.formatCalories(200), '200卡');
    });

    test('150.5卡 → 150.5卡', () {
      expect(TrackingModeFormatter.formatCalories(150.5), '150.5卡');
    });
  });

  group('TrackingModeFormatter.formatWeight', () {
    test('40kg → 40kg', () {
      expect(TrackingModeFormatter.formatWeight(40), '40kg');
    });

    test('42.5kg → 42.5kg', () {
      expect(TrackingModeFormatter.formatWeight(42.5), '42.5kg');
    });
  });

  group('TrackingModeFormatter.formatReps', () {
    test('10次 → 10次', () {
      expect(TrackingModeFormatter.formatReps(10), '10次');
    });
  });
}
