import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/utils/translation_helper.dart';

/// TranslationHelper 測試
///
/// P0 Utils 層 - 15 個測試案例
void main() {
  group('TranslationHelper', () {
    // =========================================================================
    // getTrainingTypeEn
    // =========================================================================
    group('getTrainingTypeEn', () {
      test('阻力訓練 → Resistance Training', () {
        expect(
            TranslationHelper.getTrainingTypeEn('阻力訓練'), 'Resistance Training');
      });

      test('心肺適能訓練 → Cardio', () {
        expect(TranslationHelper.getTrainingTypeEn('心肺適能訓練'), 'Cardio');
      });

      test('活動度與伸展 → Flexibility', () {
        expect(TranslationHelper.getTrainingTypeEn('活動度與伸展'), 'Flexibility');
      });

      test('未知訓練類型返回預設值', () {
        expect(
            TranslationHelper.getTrainingTypeEn('未知類型'), 'Resistance Training');
      });
    });

    // =========================================================================
    // getBodyPartEn
    // =========================================================================
    group('getBodyPartEn', () {
      test('胸部 → Chest', () {
        expect(TranslationHelper.getBodyPartEn('胸部'), 'Chest');
      });

      test('背部 → Back', () {
        expect(TranslationHelper.getBodyPartEn('背部'), 'Back');
      });

      test('腿部 → Legs', () {
        expect(TranslationHelper.getBodyPartEn('腿部'), 'Legs');
      });

      test('肩部 → Shoulders', () {
        expect(TranslationHelper.getBodyPartEn('肩部'), 'Shoulders');
      });

      test('手臂 → Arms', () {
        expect(TranslationHelper.getBodyPartEn('手臂'), 'Arms');
      });

      test('核心 → Core', () {
        expect(TranslationHelper.getBodyPartEn('核心'), 'Core');
      });

      test('未知部位返回 Other', () {
        expect(TranslationHelper.getBodyPartEn('未知部位'), 'Other');
      });
    });

    // =========================================================================
    // getEquipmentEn
    // =========================================================================
    group('getEquipmentEn', () {
      test('徒手 → Bodyweight', () {
        expect(TranslationHelper.getEquipmentEn('徒手'), 'Bodyweight');
      });

      test('啞鈴 → Dumbbell', () {
        expect(TranslationHelper.getEquipmentEn('啞鈴'), 'Dumbbell');
      });

      test('槓鈴 → Barbell', () {
        expect(TranslationHelper.getEquipmentEn('槓鈴'), 'Barbell');
      });

      test('Cable滑輪 → Cable', () {
        expect(TranslationHelper.getEquipmentEn('Cable滑輪'), 'Cable');
      });

      test('未知器材返回 Other', () {
        expect(TranslationHelper.getEquipmentEn('未知器材'), 'Other');
      });
    });

    // =========================================================================
    // 常數驗證
    // =========================================================================
    group('常數驗證', () {
      test('trainingTypes 不為空', () {
        expect(TranslationHelper.trainingTypes, isNotEmpty);
      });

      test('bodyParts 不為空', () {
        expect(TranslationHelper.bodyParts, isNotEmpty);
      });

      test('equipment 不為空', () {
        expect(TranslationHelper.equipment, isNotEmpty);
      });
    });
  });
}
