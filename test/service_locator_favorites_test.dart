import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/services/interfaces/i_favorites_service.dart';
import 'package:strengthwise/services/favorites_service.dart';
import 'package:strengthwise/services/error_handling_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FavoritesService 註冊測試', () {
    setUp(() async {
      // 清除 SharedPreferences
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('FavoritesService 應該可以手動註冊', () async {
      // 手動註冊（不依賴 Firebase）
      if (!serviceLocator.isRegistered<IFavoritesService>()) {
        serviceLocator.registerLazySingleton<IFavoritesService>(
          () => FavoritesService(errorService: ErrorHandlingService()),
        );
      }

      // 檢查是否已註冊
      expect(serviceLocator.isRegistered<IFavoritesService>(), true);

      // 獲取服務實例
      final favoritesService = serviceLocator<IFavoritesService>();
      expect(favoritesService, isNotNull);
      expect(favoritesService, isA<IFavoritesService>());

      // 初始化服務（需要轉換為實作類）
      if (favoritesService is FavoritesService) {
        await favoritesService.initialize();
      }
    });

    test('FavoritesService 應該是單例', () async {
      // 手動註冊
      if (!serviceLocator.isRegistered<IFavoritesService>()) {
        serviceLocator.registerLazySingleton<IFavoritesService>(
          () => FavoritesService(errorService: ErrorHandlingService()),
        );
      }

      final service1 = serviceLocator<IFavoritesService>();
      final service2 = serviceLocator<IFavoritesService>();

      // 應該是同一個實例（LazySingleton）
      expect(identical(service1, service2), true);
    });

    test('FavoritesService 應該可以正常使用', () async {
      // 手動註冊
      if (!serviceLocator.isRegistered<IFavoritesService>()) {
        serviceLocator.registerLazySingleton<IFavoritesService>(
          () => FavoritesService(errorService: ErrorHandlingService()),
        );
      }

      final favoritesService = serviceLocator<IFavoritesService>();
      // 初始化服務（需要轉換為實作類）
      if (favoritesService is FavoritesService) {
        await favoritesService.initialize();
      }

      const testUserId = 'test_user';
      const testExerciseId = 'test_exercise';
      const testExerciseName = '測試動作';
      const testBodyPart = '胸';

      // 測試添加收藏
      await favoritesService.addFavorite(
        testUserId,
        testExerciseId,
        testExerciseName,
        testBodyPart,
      );

      // 測試檢查收藏
      final isFavorite = await favoritesService.isFavorite(testUserId, testExerciseId);
      expect(isFavorite, true);

      // 測試獲取收藏列表
      final favorites = await favoritesService.getFavoriteExercises(testUserId);
      expect(favorites.length, 1);
      expect(favorites[0].exerciseId, testExerciseId);
    });
  });
}

