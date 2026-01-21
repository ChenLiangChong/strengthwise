import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/injury_coach_note_model.dart';

import '../../mocks/mock_services.dart';

/// InjuryCoachNoteService 測試
///
/// P3 優先級 - 8 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockInjuryCoachNoteService mockService;

  // 測試用的模型資料
  final testNote = InjuryCoachNoteModel(
    id: 'injury-note-001',
    coachId: 'coach-001',
    clientId: 'client-001',
    injurySite: '右膝',
    note: '避免深蹲過深，建議使用箱式深蹲',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockInjuryCoachNoteService();
  });

  group('IInjuryCoachNoteService', () {
    // =========================================================================
    // getNotesForClient
    // =========================================================================
    group('getNotesForClient', () {
      test('正常獲取學員所有傷病備註', () async {
        // Arrange
        when(() => mockService.getNotesForClient(clientId: 'client-001'))
            .thenAnswer((_) async => {
                  '右膝': [testNote],
                });

        // Act
        final result =
            await mockService.getNotesForClient(clientId: 'client-001');

        // Assert
        expect(result.length, 1);
        expect(result['右膝']!.length, 1);
      });

      test('無傷病備註返回空 Map', () async {
        // Arrange
        when(() => mockService.getNotesForClient(clientId: 'new-client'))
            .thenAnswer((_) async => {});

        // Act
        final result =
            await mockService.getNotesForClient(clientId: 'new-client');

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // getNotesForInjury
    // =========================================================================
    group('getNotesForInjury', () {
      test('正常獲取特定傷病備註', () async {
        // Arrange
        when(() => mockService.getNotesForInjury(
              clientId: 'client-001',
              injurySite: '右膝',
            )).thenAnswer((_) async => [testNote]);

        // Act
        final result = await mockService.getNotesForInjury(
          clientId: 'client-001',
          injurySite: '右膝',
        );

        // Assert
        expect(result.length, 1);
        expect(result[0].injurySite, '右膝');
      });

      test('無備註返回空列表', () async {
        // Arrange
        when(() => mockService.getNotesForInjury(
              clientId: 'client-001',
              injurySite: '左肩',
            )).thenAnswer((_) async => []);

        // Act
        final result = await mockService.getNotesForInjury(
          clientId: 'client-001',
          injurySite: '左肩',
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // upsertNote
    // =========================================================================
    group('upsertNote', () {
      test('建立新傷病備註', () async {
        // Arrange
        when(() => mockService.upsertNote(
              coachId: 'coach-001',
              clientId: 'client-001',
              injurySite: '左肩',
              note: any(named: 'note'),
            )).thenAnswer((_) async => testNote.copyWith(injurySite: '左肩'));

        // Act
        final result = await mockService.upsertNote(
          coachId: 'coach-001',
          clientId: 'client-001',
          injurySite: '左肩',
          note: '新的備註內容',
        );

        // Assert
        expect(result.id, isNotEmpty);
      });

      test('更新現有傷病備註', () async {
        // Arrange
        final updatedNote = testNote.copyWith(note: '更新後的備註');
        when(() => mockService.upsertNote(
              coachId: 'coach-001',
              clientId: 'client-001',
              injurySite: '右膝',
              note: '更新後的備註',
            )).thenAnswer((_) async => updatedNote);

        // Act
        final result = await mockService.upsertNote(
          coachId: 'coach-001',
          clientId: 'client-001',
          injurySite: '右膝',
          note: '更新後的備註',
        );

        // Assert
        expect(result.note, '更新後的備註');
      });
    });

    // =========================================================================
    // deleteNote
    // =========================================================================
    group('deleteNote', () {
      test('正常刪除傷病備註', () async {
        // Arrange
        when(() => mockService.deleteNote(
              coachId: 'coach-001',
              clientId: 'client-001',
              injurySite: '右膝',
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.deleteNote(
            coachId: 'coach-001',
            clientId: 'client-001',
            injurySite: '右膝',
          ),
          completes,
        );
      });
    });
  });
}
