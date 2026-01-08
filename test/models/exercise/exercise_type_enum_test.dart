import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/exercise/exercise_type_enum.dart';

/// ExerciseType 枚舉測試
///
/// P1 Models 層 - 12 個測試案例
void main() {
  group('ExerciseType', () {
    // =========================================================================
    // 枚舉值驗證
    // =========================================================================
    group('枚舉值', () {
      test('包含所有預期值', () {
        expect(ExerciseType.values, contains(ExerciseType.strength));
        expect(ExerciseType.values, contains(ExerciseType.cardio));
        expect(ExerciseType.values, contains(ExerciseType.flexibility));
        expect(ExerciseType.values, contains(ExerciseType.balance));
        expect(ExerciseType.values, contains(ExerciseType.custom));
      });

      test('共有 5 種類型', () {
        expect(ExerciseType.values.length, 5);
      });
    });

    // =========================================================================
    // displayName
    // =========================================================================
    group('displayName', () {
      test('strength → 力量訓練', () {
        expect(ExerciseType.strength.displayName, '力量訓練');
      });

      test('cardio → 有氧訓練', () {
        expect(ExerciseType.cardio.displayName, '有氧訓練');
      });

      test('flexibility → 柔韌性訓練', () {
        expect(ExerciseType.flexibility.displayName, '柔韌性訓練');
      });

      test('balance → 平衡訓練', () {
        expect(ExerciseType.balance.displayName, '平衡訓練');
      });

      test('custom → 自訂', () {
        expect(ExerciseType.custom.displayName, '自訂');
      });
    });

    // =========================================================================
    // fromString
    // =========================================================================
    group('fromString', () {
      test('力量訓練 → strength', () {
        expect(ExerciseTypeExtension.fromString('力量訓練'), ExerciseType.strength);
      });

      test('有氧訓練 → cardio', () {
        expect(ExerciseTypeExtension.fromString('有氧訓練'), ExerciseType.cardio);
      });

      test('未知值 → custom', () {
        expect(ExerciseTypeExtension.fromString('未知類型'), ExerciseType.custom);
      });

      test('空字串 → custom', () {
        expect(ExerciseTypeExtension.fromString(''), ExerciseType.custom);
      });
    });
  });
}
