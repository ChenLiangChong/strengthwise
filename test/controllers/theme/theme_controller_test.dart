import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/controllers/theme_controller.dart';
import 'package:strengthwise/services/core/theme_service.dart';
import 'package:strengthwise/themes/app_theme_mode.dart';
import 'package:strengthwise/themes/app_theme.dart';

/// Mock ThemeService
class MockThemeService extends Mock implements ThemeService {}

/// ThemeController 測試
///
/// 測試主題控制器的狀態管理和持久化邏輯
void main() {
  late MockThemeService mockThemeService;
  late ThemeController controller;

  setUpAll(() {
    // 註冊 AppThemeMode 的 fallback value（mocktail 需要）
    registerFallbackValue(AppThemeMode.system);
  });

  setUp(() {
    mockThemeService = MockThemeService();

    // 預設 mock 行為
    when(() => mockThemeService.getThemeMode())
        .thenAnswer((_) async => AppThemeMode.system);
    when(() => mockThemeService.setThemeMode(any())).thenAnswer((_) async {});
    when(() => mockThemeService.clearThemeMode()).thenAnswer((_) async {});
  });

  tearDown(() {
    controller.dispose();
  });

  group('ThemeController 初始化', () {
    test('初始化時應該從 ThemeService 載入主題', () async {
      // Arrange
      when(() => mockThemeService.getThemeMode())
          .thenAnswer((_) async => AppThemeMode.dark);

      // Act
      controller = ThemeController(mockThemeService);
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(controller.themeMode, AppThemeMode.dark);
      expect(controller.isInitialized, isTrue);
      verify(() => mockThemeService.getThemeMode()).called(1);
    });

    test('載入失敗時應該使用 system 模式', () async {
      // Arrange
      when(() => mockThemeService.getThemeMode()).thenThrow(Exception('Error'));

      // Act
      controller = ThemeController(mockThemeService);
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(controller.themeMode, AppThemeMode.system);
      expect(controller.isInitialized, isTrue);
    });
  });

  group('ThemeController.setThemeMode', () {
    test('設定相同模式不應該觸發更新', () async {
      // Arrange
      when(() => mockThemeService.getThemeMode())
          .thenAnswer((_) async => AppThemeMode.light);
      controller = ThemeController(mockThemeService);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      await controller.setThemeMode(AppThemeMode.light);

      // Assert - setThemeMode 不應該被呼叫（因為相同模式）
      verifyNever(() => mockThemeService.setThemeMode(any()));
    });

    test('設定不同模式應該更新並持久化', () async {
      // Arrange
      when(() => mockThemeService.getThemeMode())
          .thenAnswer((_) async => AppThemeMode.light);
      controller = ThemeController(mockThemeService);
      await Future.delayed(const Duration(milliseconds: 100));

      // Act
      await controller.setThemeMode(AppThemeMode.dark);

      // Assert
      expect(controller.themeMode, AppThemeMode.dark);
      verify(() => mockThemeService.setThemeMode(AppThemeMode.dark)).called(1);
    });
  });

  group('ThemeController 快捷方法', () {
    setUp(() async {
      controller = ThemeController(mockThemeService);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('setLightMode 應該設定為 light', () async {
      await controller.setLightMode();
      expect(controller.themeMode, AppThemeMode.light);
    });

    test('setDarkMode 應該設定為 dark', () async {
      await controller.setDarkMode();
      expect(controller.themeMode, AppThemeMode.dark);
    });

    test('setRoseMode 應該設定為 rose', () async {
      await controller.setRoseMode();
      expect(controller.themeMode, AppThemeMode.rose);
    });

    test('setSystemMode 應該設定為 system', () async {
      // 先設定為其他模式
      await controller.setLightMode();
      // 再設定回 system
      await controller.setSystemMode();
      expect(controller.themeMode, AppThemeMode.system);
    });
  });

  group('ThemeController.themeModeName', () {
    setUp(() async {
      controller = ThemeController(mockThemeService);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('light 模式應該返回「淺色模式」', () async {
      await controller.setLightMode();
      expect(controller.themeModeName, '淺色模式');
    });

    test('dark 模式應該返回「深色模式」', () async {
      await controller.setDarkMode();
      expect(controller.themeModeName, '深色模式');
    });

    test('rose 模式應該返回「粉色模式」', () async {
      await controller.setRoseMode();
      expect(controller.themeModeName, '粉色模式');
    });

    test('system 模式應該返回「跟隨系統」', () {
      expect(controller.themeModeName, '跟隨系統');
    });
  });

  group('ThemeController.themeModeIcon', () {
    setUp(() async {
      controller = ThemeController(mockThemeService);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('light 模式應該返回太陽圖標', () async {
      await controller.setLightMode();
      expect(controller.themeModeIcon, Icons.wb_sunny);
    });

    test('dark 模式應該返回月亮圖標', () async {
      await controller.setDarkMode();
      expect(controller.themeModeIcon, Icons.nightlight_round);
    });

    test('rose 模式應該返回花朵圖標', () async {
      await controller.setRoseMode();
      expect(controller.themeModeIcon, Icons.local_florist);
    });

    test('system 模式應該返回手機圖標', () {
      expect(controller.themeModeIcon, Icons.phone_android);
    });
  });

  group('ThemeController.getThemeData', () {
    setUp(() async {
      controller = ThemeController(mockThemeService);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('light 模式應該返回 lightTheme', () async {
      await controller.setLightMode();
      final themeData = controller.getThemeData(Brightness.dark);
      expect(themeData.brightness, Brightness.light);
    });

    test('dark 模式應該返回 darkTheme', () async {
      await controller.setDarkMode();
      final themeData = controller.getThemeData(Brightness.light);
      expect(themeData.brightness, Brightness.dark);
    });

    test('rose 模式應該返回 roseTheme', () async {
      await controller.setRoseMode();
      final themeData = controller.getThemeData(Brightness.dark);
      expect(themeData.scaffoldBackgroundColor, AppTheme.roseBackground);
    });

    test('system 模式 + 平台 dark 應該返回 darkTheme', () {
      final themeData = controller.getThemeData(Brightness.dark);
      expect(themeData.brightness, Brightness.dark);
    });

    test('system 模式 + 平台 light 應該返回 lightTheme', () {
      final themeData = controller.getThemeData(Brightness.light);
      expect(themeData.brightness, Brightness.light);
    });
  });

  group('ThemeController.resetToDefault', () {
    test('重置應該清除設定並設為 system', () async {
      // Arrange
      controller = ThemeController(mockThemeService);
      await Future.delayed(const Duration(milliseconds: 100));
      await controller.setDarkMode();

      // Act
      await controller.resetToDefault();

      // Assert
      expect(controller.themeMode, AppThemeMode.system);
      verify(() => mockThemeService.clearThemeMode()).called(1);
    });
  });

  group('ThemeController 輔助屬性', () {
    setUp(() async {
      controller = ThemeController(mockThemeService);
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('isCustomTheme 在 system 模式應該為 false', () {
      expect(controller.isCustomTheme, isFalse);
    });

    test('isCustomTheme 在非 system 模式應該為 true', () async {
      await controller.setLightMode();
      expect(controller.isCustomTheme, isTrue);
    });

    test('isRoseTheme 在 rose 模式應該為 true', () async {
      await controller.setRoseMode();
      expect(controller.isRoseTheme, isTrue);
    });

    test('isRoseTheme 在非 rose 模式應該為 false', () async {
      await controller.setLightMode();
      expect(controller.isRoseTheme, isFalse);
    });
  });
}
