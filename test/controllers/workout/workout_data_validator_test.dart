import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/controllers/workout/workout_data_validator.dart';

/// WorkoutDataValidator 測試
///
/// P10 優先級 - 10 個測試案例（安全/Edge Cases）
void main() {
  group('WorkoutDataValidator', () {
    // =========================================================================
    // validateTemplateTitle
    // =========================================================================
    group('validateTemplateTitle', () {
      test('有效標題不拋出異常', () {
        expect(() => WorkoutDataValidator.validateTemplateTitle('胸部訓練'),
            returnsNormally);
      });

      test('空標題拋出 ArgumentError', () {
        expect(() => WorkoutDataValidator.validateTemplateTitle(''),
            throwsArgumentError);
      });

      test('只有空白的標題拋出 ArgumentError', () {
        expect(() => WorkoutDataValidator.validateTemplateTitle('   '),
            throwsArgumentError);
      });
    });

    // =========================================================================
    // validateTemplateExercises
    // =========================================================================
    group('validateTemplateExercises', () {
      test('有運動列表不拋出異常', () {
        expect(
            () => WorkoutDataValidator.validateTemplateExercises(['臥推', '飛鳥']),
            returnsNormally);
      });

      test('空列表拋出 ArgumentError', () {
        expect(() => WorkoutDataValidator.validateTemplateExercises([]),
            throwsArgumentError);
      });
    });

    // =========================================================================
    // validateTemplate
    // =========================================================================
    group('validateTemplate', () {
      test('有效模板不拋出異常', () {
        expect(
          () => WorkoutDataValidator.validateTemplate(
            title: '胸部訓練',
            exercises: ['臥推'],
          ),
          returnsNormally,
        );
      });

      test('空標題拋出 ArgumentError', () {
        expect(
          () => WorkoutDataValidator.validateTemplate(
            title: '',
            exercises: ['臥推'],
          ),
          throwsArgumentError,
        );
      });

      test('空運動列表拋出 ArgumentError', () {
        expect(
          () => WorkoutDataValidator.validateTemplate(
            title: '胸部訓練',
            exercises: [],
          ),
          throwsArgumentError,
        );
      });
    });
  });
}
