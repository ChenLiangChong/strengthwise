import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/controllers/workout/workout_data_validator.dart';
import 'package:strengthwise/models/workout_template/workout_exercise.dart';

/// WorkoutDataValidator 測試
///
/// P10 優先級 - 10 個測試案例（安全/Edge Cases）
void main() {
  group('WorkoutDataValidator', () {
    // =========================================================================
    // 測試用的 Mock WorkoutExercise
    // =========================================================================
    WorkoutExercise createMockExercise(String name) {
      return WorkoutExercise(
        id: 'test-id-${name.hashCode}',
        exerciseId: 'exercise-id-${name.hashCode}',
        name: name,
        equipment: '槓鈴',
        bodyParts: ['胸'],
        sets: 4,
        reps: 10,
        weight: 60,
        restTime: 90,
      );
    }

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
        final exercises = [
          createMockExercise('臥推'),
          createMockExercise('飛鳥'),
        ];
        expect(
            () => WorkoutDataValidator.validateTemplateExercises(exercises),
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
        final exercises = [createMockExercise('臥推')];
        expect(
          () => WorkoutDataValidator.validateTemplate(
            title: '胸部訓練',
            exercises: exercises,
          ),
          returnsNormally,
        );
      });

      test('空標題拋出 ArgumentError', () {
        final exercises = [createMockExercise('臥推')];
        expect(
          () => WorkoutDataValidator.validateTemplate(
            title: '',
            exercises: exercises,
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
