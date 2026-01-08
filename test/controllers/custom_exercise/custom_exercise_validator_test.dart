import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/controllers/custom_exercise/custom_exercise_validator.dart';

/// CustomExerciseValidator 測試
///
/// P10 優先級 - 15 個測試案例（安全/Edge Cases）
void main() {
  group('CustomExerciseValidator', () {
    // =========================================================================
    // validateName
    // =========================================================================
    group('validateName', () {
      test('有效名稱不拋出異常', () {
        expect(
            () => CustomExerciseValidator.validateName('俯臥撐'), returnsNormally);
      });

      test('空名稱拋出 ArgumentError', () {
        expect(() => CustomExerciseValidator.validateName(''),
            throwsArgumentError);
      });

      test('只有空白的名稱拋出 ArgumentError', () {
        expect(() => CustomExerciseValidator.validateName('   '),
            throwsArgumentError);
      });

      test('超過50字符拋出 ArgumentError', () {
        final longName = 'a' * 51;
        expect(() => CustomExerciseValidator.validateName(longName),
            throwsArgumentError);
      });

      test('剛好50字符不拋出異常', () {
        final maxName = 'a' * 50;
        expect(() => CustomExerciseValidator.validateName(maxName),
            returnsNormally);
      });
    });

    // =========================================================================
    // validateBodyPart
    // =========================================================================
    group('validateBodyPart', () {
      test('有效身體部位不拋出異常', () {
        expect(() => CustomExerciseValidator.validateBodyPart('胸部'),
            returnsNormally);
      });

      test('空身體部位拋出 ArgumentError', () {
        expect(() => CustomExerciseValidator.validateBodyPart(''),
            throwsArgumentError);
      });
    });

    // =========================================================================
    // validateId
    // =========================================================================
    group('validateId', () {
      test('有效 ID 不拋出異常', () {
        expect(() => CustomExerciseValidator.validateId('exercise-001'),
            returnsNormally);
      });

      test('空 ID 拋出 ArgumentError', () {
        expect(
            () => CustomExerciseValidator.validateId(''), throwsArgumentError);
      });
    });

    // =========================================================================
    // validateCreateParams
    // =========================================================================
    group('validateCreateParams', () {
      test('有效參數不拋出異常', () {
        expect(
          () => CustomExerciseValidator.validateCreateParams(
            name: '俯臥撐',
            bodyPart: '胸部',
          ),
          returnsNormally,
        );
      });

      test('空名稱拋出 ArgumentError', () {
        expect(
          () => CustomExerciseValidator.validateCreateParams(
            name: '',
            bodyPart: '胸部',
          ),
          throwsArgumentError,
        );
      });
    });

    // =========================================================================
    // validateUpdateParams
    // =========================================================================
    group('validateUpdateParams', () {
      test('有效參數不拋出異常', () {
        expect(
          () => CustomExerciseValidator.validateUpdateParams(
            exerciseId: 'exercise-001',
            name: '新名稱',
          ),
          returnsNormally,
        );
      });

      test('空 ID 拋出 ArgumentError', () {
        expect(
          () => CustomExerciseValidator.validateUpdateParams(
            exerciseId: '',
          ),
          throwsArgumentError,
        );
      });

      test('空名稱（非 null）拋出 ArgumentError', () {
        expect(
          () => CustomExerciseValidator.validateUpdateParams(
            exerciseId: 'exercise-001',
            name: '',
          ),
          throwsArgumentError,
        );
      });

      test('null 名稱不拋出異常', () {
        expect(
          () => CustomExerciseValidator.validateUpdateParams(
            exerciseId: 'exercise-001',
            name: null,
          ),
          returnsNormally,
        );
      });
    });
  });
}
