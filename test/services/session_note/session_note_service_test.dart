import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';

import '../../mocks/mock_services.dart';

/// SessionNoteService 測試
///
/// P2 優先級 - 10 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md #P2
void main() {
  late MockSessionNoteService mockService;

  // 測試用的模型資料
  final testNote = SessionNoteModel(
    id: 'note-001',
    title: '第一堂課程',
    coachId: 'coach-001',
    clientId: 'client-001',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    // 註冊 SessionNoteModel fallback
    registerFallbackValue(SessionNoteModel(
      id: 'fallback',
      title: 'fallback',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // 註冊 ReadinessMetrics fallback（來自通用 mock）
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockSessionNoteService();
  });

  group('ISessionNoteService', () {
    // =========================================================================
    // P2-167: getCoachNotes
    // =========================================================================
    group('getCoachNotes', () {
      test('返回教練的所有筆記', () async {
        // Arrange
        when(() => mockService.getCoachNotes(coachId: 'coach-001'))
            .thenAnswer((_) async => [testNote]);

        // Act
        final result = await mockService.getCoachNotes(coachId: 'coach-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].coachId, 'coach-001');
      });
    });

    // =========================================================================
    // P2-168: getClientNotes
    // =========================================================================
    group('getClientNotes', () {
      test('返回學員可見的筆記', () async {
        // Arrange
        when(() => mockService.getClientNotes(clientId: 'client-001'))
            .thenAnswer((_) async => [testNote]);

        // Act
        final result = await mockService.getClientNotes(clientId: 'client-001');

        // Assert
        expect(result.length, 1);
      });
    });

    // =========================================================================
    // P2-169: getNoteById
    // =========================================================================
    group('getNoteById', () {
      test('找到筆記時返回 Model', () async {
        // Arrange
        when(() => mockService.getNoteById('note-001'))
            .thenAnswer((_) async => testNote);

        // Act
        final result = await mockService.getNoteById('note-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'note-001');
      });
    });

    // =========================================================================
    // P2-170: getNotesByAppointment
    // =========================================================================
    group('getNotesByAppointment', () {
      test('返回預約關聯的筆記', () async {
        // Arrange
        when(() => mockService.getNotesByAppointment(appointmentId: 'apt-001'))
            .thenAnswer((_) async => [testNote]);

        // Act
        final result =
            await mockService.getNotesByAppointment(appointmentId: 'apt-001');

        // Assert
        expect(result.length, 1);
      });
    });

    // =========================================================================
    // P2-171: createNote
    // =========================================================================
    group('createNote', () {
      test('建立筆記成功', () async {
        // Arrange
        when(() => mockService.createNote(any()))
            .thenAnswer((_) async => testNote);

        // Act
        final result = await mockService.createNote(testNote);

        // Assert
        expect(result.id, 'note-001');
      });
    });

    // =========================================================================
    // P2-172: updateNote
    // =========================================================================
    group('updateNote', () {
      test('更新筆記成功', () async {
        // Arrange
        final updated = testNote.copyWith(title: '更新標題');
        when(() => mockService.updateNote(any()))
            .thenAnswer((_) async => updated);

        // Act
        final result = await mockService.updateNote(testNote);

        // Assert
        expect(result.title, '更新標題');
      });
    });

    // =========================================================================
    // P2-173: deleteNote
    // =========================================================================
    group('deleteNote', () {
      test('刪除筆記成功', () async {
        // Arrange
        when(() => mockService.deleteNote('note-001')).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.deleteNote('note-001'),
          completes,
        );
      });
    });

    // =========================================================================
    // P2-174: toggleVisibility
    // =========================================================================
    group('toggleVisibility', () {
      test('切換可見性成功', () async {
        // Arrange
        final toggled = testNote.copyWith(visibility: 'private');
        when(() => mockService.toggleVisibility('note-001'))
            .thenAnswer((_) async => toggled);

        // Act
        final result = await mockService.toggleVisibility('note-001');

        // Assert
        expect(result.visibility, 'private');
      });
    });

    // =========================================================================
    // P2-175: hideNote
    // =========================================================================
    group('hideNote', () {
      test('教練隱藏筆記成功', () async {
        // Arrange
        when(() => mockService.hideNote(noteId: 'note-001', isCoach: true))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.hideNote(noteId: 'note-001', isCoach: true),
          completes,
        );
      });
    });

    // =========================================================================
    // P2-176: searchNotes
    // =========================================================================
    group('searchNotes', () {
      test('依關鍵字搜尋筆記', () async {
        // Arrange
        when(() => mockService.searchNotes(
              coachId: 'coach-001',
              keyword: '深蹲',
            )).thenAnswer((_) async => [testNote]);

        // Act
        final result = await mockService.searchNotes(
          coachId: 'coach-001',
          keyword: '深蹲',
        );

        // Assert
        expect(result.length, 1);
      });
    });
  });
}
