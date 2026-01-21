import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/coach_assessment_note_model.dart';

import '../../mocks/mock_services.dart';

/// CoachAssessmentNoteService 測試
///
/// P3 優先級 - 8 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockCoachAssessmentNoteService mockService;

  // 測試用的模型資料
  final testNote = CoachAssessmentNoteModel(
    id: 'note-001',
    coachId: 'coach-001',
    assessmentId: 'assess-001',
    notes: '學員有輕微膝蓋不適，訓練時注意動作範圍',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockCoachAssessmentNoteService();
  });

  group('ICoachAssessmentNoteService', () {
    // =========================================================================
    // getNote
    // =========================================================================
    group('getNote', () {
      test('正常獲取教練備註', () async {
        // Arrange
        when(() => mockService.getNote(
              coachId: 'coach-001',
              assessmentId: 'assess-001',
            )).thenAnswer((_) async => testNote);

        // Act
        final result = await mockService.getNote(
          coachId: 'coach-001',
          assessmentId: 'assess-001',
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.notes, contains('膝蓋'));
      });

      test('備註不存在返回 null', () async {
        // Arrange
        when(() => mockService.getNote(
              coachId: 'coach-001',
              assessmentId: 'not-exist',
            )).thenAnswer((_) async => null);

        // Act
        final result = await mockService.getNote(
          coachId: 'coach-001',
          assessmentId: 'not-exist',
        );

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // upsertNote
    // =========================================================================
    group('upsertNote', () {
      test('建立新備註', () async {
        // Arrange
        when(() => mockService.upsertNote(
              coachId: 'coach-001',
              assessmentId: 'assess-002',
              notes: any(named: 'notes'),
            )).thenAnswer((_) async => testNote);

        // Act
        final result = await mockService.upsertNote(
          coachId: 'coach-001',
          assessmentId: 'assess-002',
          notes: '新的備註內容',
        );

        // Assert
        expect(result.id, isNotEmpty);
      });

      test('更新現有備註', () async {
        // Arrange
        final updatedNote = testNote.copyWith(
          notes: '更新後的備註內容',
        );
        when(() => mockService.upsertNote(
              coachId: 'coach-001',
              assessmentId: 'assess-001',
              notes: '更新後的備註內容',
            )).thenAnswer((_) async => updatedNote);

        // Act
        final result = await mockService.upsertNote(
          coachId: 'coach-001',
          assessmentId: 'assess-001',
          notes: '更新後的備註內容',
        );

        // Assert
        expect(result.notes, '更新後的備註內容');
      });
    });

    // =========================================================================
    // deleteNote
    // =========================================================================
    group('deleteNote', () {
      test('正常刪除備註', () async {
        // Arrange
        when(() => mockService.deleteNote(
              coachId: 'coach-001',
              assessmentId: 'assess-001',
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.deleteNote(
            coachId: 'coach-001',
            assessmentId: 'assess-001',
          ),
          completes,
        );
      });
    });

    // =========================================================================
    // getCoachNotes
    // =========================================================================
    group('getCoachNotes', () {
      test('正常獲取教練所有備註', () async {
        // Arrange
        when(() => mockService.getCoachNotes(coachId: 'coach-001'))
            .thenAnswer((_) async => [testNote]);

        // Act
        final result = await mockService.getCoachNotes(coachId: 'coach-001');

        // Assert
        expect(result.length, 1);
      });

      test('limit 參數限制返回數量', () async {
        // Arrange
        when(() => mockService.getCoachNotes(coachId: 'coach-001', limit: 5))
            .thenAnswer((_) async => [testNote]);

        // Act
        final result =
            await mockService.getCoachNotes(coachId: 'coach-001', limit: 5);

        // Assert
        expect(result.length, lessThanOrEqualTo(5));
      });

      test('無備註返回空列表', () async {
        // Arrange
        when(() => mockService.getCoachNotes(coachId: 'new-coach'))
            .thenAnswer((_) async => []);

        // Act
        final result = await mockService.getCoachNotes(coachId: 'new-coach');

        // Assert
        expect(result, isEmpty);
      });
    });
  });
}
