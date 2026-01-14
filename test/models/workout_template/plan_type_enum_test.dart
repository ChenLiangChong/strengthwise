import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/models/workout_template/plan_type_enum.dart';

/// PlanType 枚舉測試
///
/// P1 Models 層 - 18 個測試案例
void main() {
  group('PlanType', () {
    // =========================================================================
    // 枚舉值驗證
    // =========================================================================
    group('枚舉值', () {
      test('包含所有預期值', () {
        expect(PlanType.values, contains(PlanType.strength));
        expect(PlanType.values, contains(PlanType.hypertrophy));
        expect(PlanType.values, contains(PlanType.fatLoss));
        expect(PlanType.values, contains(PlanType.cardio));
        expect(PlanType.values, contains(PlanType.fullBody));
        expect(PlanType.values, contains(PlanType.upperBody));
        expect(PlanType.values, contains(PlanType.lowerBody));
        expect(PlanType.values, contains(PlanType.core));
        expect(PlanType.values, contains(PlanType.flexibility));
        expect(PlanType.values, contains(PlanType.mixed));
        expect(PlanType.values, contains(PlanType.custom));
      });

      test('共有 11 種類型', () {
        expect(PlanType.values.length, 11);
      });
    });

    // =========================================================================
    // displayName
    // =========================================================================
    group('displayName', () {
      test('strength → 力量訓練', () {
        expect(PlanType.strength.displayName, '力量訓練');
      });

      test('hypertrophy → 增肌訓練', () {
        expect(PlanType.hypertrophy.displayName, '增肌訓練');
      });

      test('fullBody → 全身訓練', () {
        expect(PlanType.fullBody.displayName, '全身訓練');
      });
    });

    // =========================================================================
    // icon
    // =========================================================================
    group('icon', () {
      test('strength 有圖示', () {
        expect(PlanType.strength.icon, '💪');
      });

      test('cardio 有圖示', () {
        expect(PlanType.cardio.icon, '🏃');
      });

      test('all types have icons', () {
        for (final type in PlanType.values) {
          expect(type.icon, isNotEmpty);
        }
      });
    });

    // =========================================================================
    // description
    // =========================================================================
    group('description', () {
      test('strength 有描述', () {
        expect(PlanType.strength.description, contains('力量'));
      });

      test('all types have descriptions', () {
        for (final type in PlanType.values) {
          expect(type.description, isNotEmpty);
        }
      });
    });

    // =========================================================================
    // fromString
    // =========================================================================
    group('fromString', () {
      test('力量訓練 → strength', () {
        expect(PlanTypeExtension.fromString('力量訓練'), PlanType.strength);
      });

      test('增肌訓練 → hypertrophy', () {
        expect(PlanTypeExtension.fromString('增肌訓練'), PlanType.hypertrophy);
      });

      test('向後相容 - 推動訓練 → upperBody', () {
        expect(PlanTypeExtension.fromString('推動訓練'), PlanType.upperBody);
      });

      test('向後相容 - 腿部訓練 → lowerBody', () {
        expect(PlanTypeExtension.fromString('腿部訓練'), PlanType.lowerBody);
      });

      test('未知值 → custom', () {
        expect(PlanTypeExtension.fromString('未知類型'), PlanType.custom);
      });
    });

    // =========================================================================
    // allDisplayNames
    // =========================================================================
    group('allDisplayNames', () {
      test('返回所有類型名稱', () {
        final names = PlanTypeExtension.allDisplayNames;
        expect(names, isNotEmpty);
        expect(names.length, PlanType.values.length);
      });

      test('包含力量訓練', () {
        expect(PlanTypeExtension.allDisplayNames, contains('力量訓練'));
      });
    });
  });
}
