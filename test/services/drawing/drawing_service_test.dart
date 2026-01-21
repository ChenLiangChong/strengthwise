import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/drawing_note_model.dart';

import '../../mocks/mock_services.dart';

/// DrawingService 測試
///
/// P3 優先級 - 5 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockDrawingService mockService;

  // 測試用的模型資料
  final testDrawing = DrawingNoteModel(
    id: 'drawing-001',
    sessionNoteId: 'session-note-001',
    templateType: 'note1',
    layers: const [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockDrawingService();
  });

  group('IDrawingService', () {
    // =========================================================================
    // createDrawing
    // =========================================================================
    group('createDrawing', () {
      test('正常建立繪圖筆記', () async {
        // Arrange
        when(() => mockService.createDrawing(
              sessionNoteId: 'session-note-001',
              templateType: 'note1',
            )).thenAnswer((_) async => testDrawing);

        // Act
        final result = await mockService.createDrawing(
          sessionNoteId: 'session-note-001',
          templateType: 'note1',
        );

        // Assert
        expect(result.id, isNotEmpty);
        expect(result.templateType, 'note1');
      });
    });

    // =========================================================================
    // saveDrawing
    // =========================================================================
    group('saveDrawing', () {
      test('正常保存繪圖筆記', () async {
        // Arrange
        when(() => mockService.saveDrawing(any())).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.saveDrawing(testDrawing),
          completes,
        );
      });
    });

    // =========================================================================
    // getDrawing
    // =========================================================================
    group('getDrawing', () {
      test('正常獲取繪圖筆記', () async {
        // Arrange
        when(() => mockService.getDrawing('session-note-001'))
            .thenAnswer((_) async => testDrawing);

        // Act
        final result = await mockService.getDrawing('session-note-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.sessionNoteId, 'session-note-001');
      });

      test('不存在返回 null', () async {
        // Arrange
        when(() => mockService.getDrawing('not-exist'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getDrawing('not-exist');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // deleteDrawing
    // =========================================================================
    group('deleteDrawing', () {
      test('正常刪除繪圖筆記', () async {
        // Arrange
        when(() => mockService.deleteDrawing('drawing-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.deleteDrawing('drawing-001'),
          completes,
        );
      });
    });
  });
}
