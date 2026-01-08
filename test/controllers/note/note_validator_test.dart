import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/controllers/note/note_validator.dart';
import 'package:strengthwise/models/note_model.dart';

/// NoteValidator 測試
///
/// P10 優先級 - 10 個測試案例（安全/Edge Cases）
void main() {
  group('NoteValidator', () {
    // =========================================================================
    // validateTitle
    // =========================================================================
    group('validateTitle', () {
      test('有效標題不拋出異常', () {
        expect(() => NoteValidator.validateTitle('有效標題'), returnsNormally);
      });

      test('空標題拋出 ArgumentError', () {
        expect(() => NoteValidator.validateTitle(''), throwsArgumentError);
      });

      test('只有空白的標題拋出 ArgumentError', () {
        expect(() => NoteValidator.validateTitle('   '), throwsArgumentError);
      });

      test('tab 和換行符標題拋出 ArgumentError', () {
        expect(() => NoteValidator.validateTitle('\t\n'), throwsArgumentError);
      });
    });

    // =========================================================================
    // validateCreateParams
    // =========================================================================
    group('validateCreateParams', () {
      test('有效參數不拋出異常', () {
        expect(
            () => NoteValidator.validateCreateParams('測試筆記'), returnsNormally);
      });

      test('空標題拋出 ArgumentError', () {
        expect(
            () => NoteValidator.validateCreateParams(''), throwsArgumentError);
      });
    });

    // =========================================================================
    // validateUpdateParams
    // =========================================================================
    group('validateUpdateParams', () {
      test('有效筆記不拋出異常', () {
        final note = Note(
          id: 'note-001',
          title: '有效標題',
          textContent: '內容',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(() => NoteValidator.validateUpdateParams(note), returnsNormally);
      });

      test('空標題的筆記拋出 ArgumentError', () {
        final note = Note(
          id: 'note-001',
          title: '',
          textContent: '內容',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(() => NoteValidator.validateUpdateParams(note),
            throwsArgumentError);
      });
    });
  });
}
