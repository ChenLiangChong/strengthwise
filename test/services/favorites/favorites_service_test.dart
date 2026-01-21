import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/favorite_exercise_model.dart';

import '../../mocks/mock_services.dart';

/// FavoritesService 測試
///
/// P3 優先級 - 8 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockFavoritesService mockService;

  // 測試用的模型資料
  final testFavorite = FavoriteExercise(
    exerciseId: 'exercise-001',
    exerciseName: '深蹲',
    bodyPart: '腿部',
    addedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockFavoritesService();
  });

  group('IFavoritesService', () {
    // =========================================================================
    // getFavoriteExerciseIds
    // =========================================================================
    group('getFavoriteExerciseIds', () {
      test('正常獲取收藏動作 ID', () async {
        // Arrange
        when(() => mockService.getFavoriteExerciseIds('user-001'))
            .thenAnswer((_) async => ['exercise-001', 'exercise-002']);

        // Act
        final result = await mockService.getFavoriteExerciseIds('user-001');

        // Assert
        expect(result.length, 2);
      });

      test('無收藏返回空列表', () async {
        // Arrange
        when(() => mockService.getFavoriteExerciseIds('new-user'))
            .thenAnswer((_) async => []);

        // Act
        final result = await mockService.getFavoriteExerciseIds('new-user');

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // getFavoriteExercises
    // =========================================================================
    group('getFavoriteExercises', () {
      test('正常獲取收藏動作詳細資訊', () async {
        // Arrange
        when(() => mockService.getFavoriteExercises('user-001'))
            .thenAnswer((_) async => [testFavorite]);

        // Act
        final result = await mockService.getFavoriteExercises('user-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].exerciseName, '深蹲');
      });
    });

    // =========================================================================
    // addFavorite
    // =========================================================================
    group('addFavorite', () {
      test('正常添加收藏', () async {
        // Arrange
        when(() => mockService.addFavorite(
              any(),
              any(),
              any(),
              any(),
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.addFavorite('user-001', 'exercise-001', '深蹲', '腿部'),
          completes,
        );
      });
    });

    // =========================================================================
    // removeFavorite
    // =========================================================================
    group('removeFavorite', () {
      test('正常移除收藏', () async {
        // Arrange
        when(() => mockService.removeFavorite('user-001', 'exercise-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.removeFavorite('user-001', 'exercise-001'),
          completes,
        );
      });
    });

    // =========================================================================
    // isFavorite
    // =========================================================================
    group('isFavorite', () {
      test('已收藏返回 true', () async {
        // Arrange
        when(() => mockService.isFavorite('user-001', 'exercise-001'))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.isFavorite('user-001', 'exercise-001');

        // Assert
        expect(result, isTrue);
      });

      test('未收藏返回 false', () async {
        // Arrange
        when(() => mockService.isFavorite('user-001', 'not-favorite'))
            .thenAnswer((_) async => false);

        // Act
        final result = await mockService.isFavorite('user-001', 'not-favorite');

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // clearFavorites
    // =========================================================================
    group('clearFavorites', () {
      test('正常清空收藏', () async {
        // Arrange
        when(() => mockService.clearFavorites('user-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.clearFavorites('user-001'),
          completes,
        );
      });
    });
  });
}
