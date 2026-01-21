import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/note_model.dart';

import '../../mocks/mock_services.dart';

/// NoteService 測試
///
/// P2 優先級 - 12 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockNoteService mockService;

  // 測試用的模型資料
  final testNote = Note(
    id: 'note-001',
    title: '訓練筆記',
    textContent: '今天做了深蹲和硬舉',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockNoteService();
  });

  group('INoteService', () {
    // =========================================================================
    // getUserNotes
    // =========================================================================
    group('getUserNotes', () {
      test('正常獲取用戶筆記', () async {
        // Arrange
        when(() => mockService.getUserNotes())
            .thenAnswer((_) async => [testNote]);

        // Act
        final result = await mockService.getUserNotes();

        // Assert
        expect(result.length, 1);
        expect(result[0].title, '訓練筆記');
      });

      test('無筆記返回空列表', () async {
        // Arrange
        when(() => mockService.getUserNotes()).thenAnswer((_) async => []);

        // Act
        final result = await mockService.getUserNotes();

        // Assert
        expect(result, isEmpty);
      });

      test('多筆記按時間排序', () async {
        // Arrange
        final note1 = testNote.copyWith(
          id: 'note-001',
          createdAt: DateTime(2026, 1, 15),
        );
        final note2 = testNote.copyWith(
          id: 'note-002',
          createdAt: DateTime(2026, 1, 20),
        );
        when(() => mockService.getUserNotes())
            .thenAnswer((_) async => [note2, note1]);

        // Act
        final result = await mockService.getUserNotes();

        // Assert
        expect(result.length, 2);
        expect(result[0].id, 'note-002'); // 較新的在前
      });
    });

    // =========================================================================
    // getNoteById
    // =========================================================================
    group('getNoteById', () {
      test('正常獲取特定筆記', () async {
        // Arrange
        when(() => mockService.getNoteById('note-001'))
            .thenAnswer((_) async => testNote);

        // Act
        final result = await mockService.getNoteById('note-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'note-001');
      });

      test('筆記不存在返回 null', () async {
        // Arrange
        when(() => mockService.getNoteById('not-exist'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getNoteById('not-exist');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // createNote
    // =========================================================================
    group('createNote', () {
      test('正常建立筆記（純文字）', () async {
        // Arrange
        when(() => mockService.createNote('新筆記', '筆記內容', null))
            .thenAnswer((_) async => testNote);

        // Act
        final result = await mockService.createNote('新筆記', '筆記內容', null);

        // Assert
        expect(result.id, isNotEmpty);
        expect(result.title, isNotEmpty);
      });

      test('建立帶有繪圖的筆記', () async {
        // Arrange
        final noteWithDrawing = testNote.copyWith(
          drawingPoints: [],
        );
        when(() => mockService.createNote('繪圖筆記', '', any()))
            .thenAnswer((_) async => noteWithDrawing);

        // Act
        final result = await mockService.createNote('繪圖筆記', '', []);

        // Assert
        expect(result, isNotNull);
      });
    });

    // =========================================================================
    // updateNote
    // =========================================================================
    group('updateNote', () {
      test('正常更新筆記', () async {
        // Arrange
        when(() => mockService.updateNote(any())).thenAnswer((_) async => true);

        // Act
        final result = await mockService.updateNote(testNote);

        // Assert
        expect(result, isTrue);
      });

      test('更新不存在筆記返回 false', () async {
        // Arrange
        final nonExistNote = testNote.copyWith(id: 'not-exist');
        when(() => mockService.updateNote(any())).thenAnswer((_) async => false);

        // Act
        final result = await mockService.updateNote(nonExistNote);

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // deleteNote
    // =========================================================================
    group('deleteNote', () {
      test('正常刪除筆記', () async {
        // Arrange
        when(() => mockService.deleteNote('note-001'))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.deleteNote('note-001');

        // Assert
        expect(result, isTrue);
      });

      test('刪除不存在筆記返回 false', () async {
        // Arrange
        when(() => mockService.deleteNote('not-exist'))
            .thenAnswer((_) async => false);

        // Act
        final result = await mockService.deleteNote('not-exist');

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
