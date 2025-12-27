import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strengthwise/models/favorite_exercise_model.dart';
import 'package:strengthwise/services/cache/favorites_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';

void main() {
  group('FavoritesService 測試', () {
    late FavoritesService favoritesService;
    const String testUserId = 'test_user_123';
    const String testExerciseId = 'exercise_001';
    const String testExerciseName = '槓鈴臥推';
    const String testBodyPart = '胸';

    setUp(() async {
      // 清除 SharedPreferences 測試數據
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 創建服務實例
      favoritesService = FavoritesService(
        errorService: ErrorHandlingService(),
      );
      await favoritesService.initialize();
    });

    test('添加收藏應該成功', () async {
      await favoritesService.addFavorite(
        testUserId,
        testExerciseId,
        testExerciseName,
        testBodyPart,
      );

      final isFavorite = await favoritesService.isFavorite(testUserId, testExerciseId);
      expect(isFavorite, true);
    });

    test('獲取收藏列表應該返回正確的動作', () async {
      await favoritesService.addFavorite(
        testUserId,
        testExerciseId,
        testExerciseName,
        testBodyPart,
      );

      final favorites = await favoritesService.getFavoriteExercises(testUserId);
      expect(favorites.length, 1);
      expect(favorites[0].exerciseId, testExerciseId);
      expect(favorites[0].exerciseName, testExerciseName);
      expect(favorites[0].bodyPart, testBodyPart);
    });

    test('移除收藏應該成功', () async {
      await favoritesService.addFavorite(
        testUserId,
        testExerciseId,
        testExerciseName,
        testBodyPart,
      );

      await favoritesService.removeFavorite(testUserId, testExerciseId);

      final isFavorite = await favoritesService.isFavorite(testUserId, testExerciseId);
      expect(isFavorite, false);
    });

    test('重複添加收藏不應該重複', () async {
      await favoritesService.addFavorite(
        testUserId,
        testExerciseId,
        testExerciseName,
        testBodyPart,
      );

      await favoritesService.addFavorite(
        testUserId,
        testExerciseId,
        testExerciseName,
        testBodyPart,
      );

      final favorites = await favoritesService.getFavoriteExercises(testUserId);
      expect(favorites.length, 1);
    });

    test('獲取收藏 ID 列表應該正確', () async {
      await favoritesService.addFavorite(
        testUserId,
        testExerciseId,
        testExerciseName,
        testBodyPart,
      );

      final ids = await favoritesService.getFavoriteExerciseIds(testUserId);
      expect(ids.length, 1);
      expect(ids[0], testExerciseId);
    });

    test('清空收藏應該移除所有收藏', () async {
      await favoritesService.addFavorite(
        testUserId,
        testExerciseId,
        testExerciseName,
        testBodyPart,
      );

      await favoritesService.clearFavorites(testUserId);

      final favorites = await favoritesService.getFavoriteExercises(testUserId);
      expect(favorites.length, 0);
    });

    test('更新最後查看時間應該成功', () async {
      await favoritesService.addFavorite(
        testUserId,
        testExerciseId,
        testExerciseName,
        testBodyPart,
      );

      await favoritesService.updateLastViewedAt(testUserId, testExerciseId);

      final favorites = await favoritesService.getFavoriteExercises(testUserId);
      expect(favorites[0].lastViewedAt, isNotNull);
    });
  });

  group('FavoriteExercise 模型測試', () {
    test('fromMap 和 toMap 應該正確轉換', () {
      final original = FavoriteExercise(
        exerciseId: 'test_id',
        exerciseName: '測試動作',
        bodyPart: '胸',
        addedAt: DateTime(2024, 1, 1),
        lastViewedAt: DateTime(2024, 1, 2),
      );

      final map = original.toMap();
      final restored = FavoriteExercise.fromMap(map);

      expect(restored.exerciseId, original.exerciseId);
      expect(restored.exerciseName, original.exerciseName);
      expect(restored.bodyPart, original.bodyPart);
      expect(restored.addedAt, original.addedAt);
      expect(restored.lastViewedAt, original.lastViewedAt);
    });

    test('copyWith 應該正確創建副本', () {
      final original = FavoriteExercise(
        exerciseId: 'test_id',
        exerciseName: '測試動作',
        bodyPart: '胸',
        addedAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        exerciseName: '新名稱',
        lastViewedAt: DateTime(2024, 1, 2),
      );

      expect(updated.exerciseId, original.exerciseId);
      expect(updated.exerciseName, '新名稱');
      expect(updated.bodyPart, original.bodyPart);
      expect(updated.addedAt, original.addedAt);
      expect(updated.lastViewedAt, DateTime(2024, 1, 2));
    });
  });

  group('ExerciseWithRecord 模型測試', () {
    test('formattedLastTrainingDate 應該正確格式化', () {
      final now = DateTime.now();
      final today = ExerciseWithRecord(
        exerciseId: 'test_id',
        exerciseName: '測試動作',
        bodyPart: '胸',
        trainingType: '重訓',
        lastTrainingDate: now,
        maxWeight: 100,
        totalSets: 5,
      );

      expect(today.formattedLastTrainingDate, '今天');

      final yesterday = ExerciseWithRecord(
        exerciseId: 'test_id',
        exerciseName: '測試動作',
        bodyPart: '胸',
        trainingType: '重訓',
        lastTrainingDate: now.subtract(const Duration(days: 1)),
        maxWeight: 100,
        totalSets: 5,
      );

      expect(yesterday.formattedLastTrainingDate, '昨天');
    });

    test('formattedMaxWeight 應該正確格式化', () {
      final exercise = ExerciseWithRecord(
        exerciseId: 'test_id',
        exerciseName: '測試動作',
        bodyPart: '胸',
        trainingType: '重訓',
        lastTrainingDate: DateTime.now(),
        maxWeight: 100.5,
        totalSets: 5,
      );

      expect(exercise.formattedMaxWeight, '100.5 kg');
    });
  });
}

