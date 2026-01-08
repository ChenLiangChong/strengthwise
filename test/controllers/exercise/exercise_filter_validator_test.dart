import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/controllers/exercise/exercise_filter_validator.dart';

/// ExerciseFilterValidator 測試
///
/// P10 優先級 - 10 個測試案例（安全/Edge Cases）
void main() {
  group('ExerciseFilterValidator', () {
    // =========================================================================
    // validateCategoryFilters
    // =========================================================================
    group('validateCategoryFilters', () {
      test('level 0 不需要參數', () {
        expect(
          () => ExerciseFilterValidator.validateCategoryFilters(level: 0),
          returnsNormally,
        );
      });

      test('level 1 需要訓練類型', () {
        expect(
          () => ExerciseFilterValidator.validateCategoryFilters(
            level: 1,
            selectedBodyPart: '胸部',
          ),
          throwsArgumentError,
        );
      });

      test('level 1 需要身體部位', () {
        expect(
          () => ExerciseFilterValidator.validateCategoryFilters(
            level: 1,
            selectedType: '肌肥大',
          ),
          throwsArgumentError,
        );
      });

      test('level 1 參數完整不拋出異常', () {
        expect(
          () => ExerciseFilterValidator.validateCategoryFilters(
            level: 1,
            selectedType: '肌肥大',
            selectedBodyPart: '胸部',
          ),
          returnsNormally,
        );
      });

      test('level 1 空訓練類型拋出異常', () {
        expect(
          () => ExerciseFilterValidator.validateCategoryFilters(
            level: 1,
            selectedType: '',
            selectedBodyPart: '胸部',
          ),
          throwsArgumentError,
        );
      });
    });

    // =========================================================================
    // validateExerciseFilters
    // =========================================================================
    group('validateExerciseFilters', () {
      test('參數完整不拋出異常', () {
        expect(
          () => ExerciseFilterValidator.validateExerciseFilters(
            selectedType: '肌肥大',
            selectedBodyPart: '胸部',
          ),
          returnsNormally,
        );
      });

      test('缺少訓練類型拋出異常', () {
        expect(
          () => ExerciseFilterValidator.validateExerciseFilters(
            selectedBodyPart: '胸部',
          ),
          throwsArgumentError,
        );
      });

      test('缺少身體部位拋出異常', () {
        expect(
          () => ExerciseFilterValidator.validateExerciseFilters(
            selectedType: '肌肥大',
          ),
          throwsArgumentError,
        );
      });

      test('空訓練類型拋出異常', () {
        expect(
          () => ExerciseFilterValidator.validateExerciseFilters(
            selectedType: '',
            selectedBodyPart: '胸部',
          ),
          throwsArgumentError,
        );
      });

      test('空身體部位拋出異常', () {
        expect(
          () => ExerciseFilterValidator.validateExerciseFilters(
            selectedType: '肌肥大',
            selectedBodyPart: '',
          ),
          throwsArgumentError,
        );
      });
    });
  });
}
