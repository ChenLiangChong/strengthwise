import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/themes/app_theme.dart';

/// AppTheme 測試
///
/// 測試主題配置的正確性
void main() {
  group('AppTheme 色票定義', () {
    test('Rose Theme 色票應該正確定義', () {
      // 驗證 Rose 主題色票存在且正確
      expect(AppTheme.rosePrimary, isA<Color>());
      expect(AppTheme.roseSecondary, isA<Color>());
      expect(AppTheme.roseBackground, isA<Color>());
      expect(AppTheme.roseOnSurface, isA<Color>());
      expect(AppTheme.roseOnSurfaceVariant, isA<Color>());
      expect(AppTheme.roseOutline, isA<Color>());
      expect(AppTheme.roseAccent, isA<Color>());
      expect(AppTheme.rosePrimaryDark, isA<Color>());
    });

    test('Rose 背景色應該是淡粉紅', () {
      // #FFF5F7
      expect(AppTheme.roseBackground.toARGB32(), 0xFFFFF5F7);
    });

    test('Rose 主色（primaryContainer）應該略深於背景', () {
      // rosePrimary (#FCE7F3) 應該比 roseBackground (#FFF5F7) 深
      final primaryLuminance = AppTheme.rosePrimary.computeLuminance();
      final backgroundLuminance = AppTheme.roseBackground.computeLuminance();

      expect(
        primaryLuminance,
        lessThan(backgroundLuminance),
        reason: 'rosePrimary 應該比 roseBackground 深（亮度較低）',
      );
    });
  });

  group('AppTheme.lightTheme', () {
    test('應該返回有效的 ThemeData', () {
      final theme = AppTheme.lightTheme;

      expect(theme, isA<ThemeData>());
      expect(theme.brightness, Brightness.light);
    });

    test('應該使用 Material 3', () {
      final theme = AppTheme.lightTheme;

      expect(theme.useMaterial3, isTrue);
    });

    test('scaffold 背景色應該是 slate50', () {
      final theme = AppTheme.lightTheme;

      expect(theme.scaffoldBackgroundColor, AppTheme.slate50);
    });
  });

  group('AppTheme.darkTheme', () {
    test('應該返回有效的 ThemeData', () {
      final theme = AppTheme.darkTheme;

      expect(theme, isA<ThemeData>());
      expect(theme.brightness, Brightness.dark);
    });

    test('scaffold 背景色應該是 slate900', () {
      final theme = AppTheme.darkTheme;

      expect(theme.scaffoldBackgroundColor, AppTheme.slate900);
    });
  });

  group('AppTheme.roseTheme', () {
    test('應該返回有效的 ThemeData', () {
      final theme = AppTheme.roseTheme;

      expect(theme, isA<ThemeData>());
      expect(theme.brightness, Brightness.light);
    });

    test('scaffold 背景色應該是 roseBackground', () {
      final theme = AppTheme.roseTheme;

      expect(theme.scaffoldBackgroundColor, AppTheme.roseBackground);
    });

    test('colorScheme.primary 應該是 rosePrimaryDark', () {
      final theme = AppTheme.roseTheme;

      expect(theme.colorScheme.primary, AppTheme.rosePrimaryDark);
    });

    test('colorScheme.secondary 應該是 roseSecondary', () {
      final theme = AppTheme.roseTheme;

      expect(theme.colorScheme.secondary, AppTheme.roseSecondary);
    });

    test('colorScheme.primaryContainer 應該是 rosePrimary', () {
      final theme = AppTheme.roseTheme;

      expect(theme.colorScheme.primaryContainer, AppTheme.rosePrimary);
    });
  });

  group('AppTheme 輔助方法', () {
    test('getTheme(light) 應該返回 lightTheme', () {
      final theme = AppTheme.getTheme(Brightness.light);

      expect(theme.brightness, Brightness.light);
    });

    test('getTheme(dark) 應該返回 darkTheme', () {
      final theme = AppTheme.getTheme(Brightness.dark);

      expect(theme.brightness, Brightness.dark);
    });
  });

  group('AppTheme 間距常數', () {
    test('間距應該符合 8 點網格', () {
      expect(AppTheme.spacingXs, 4.0);
      expect(AppTheme.spacingSm, 8.0);
      expect(AppTheme.spacingMd, 16.0);
      expect(AppTheme.spacingLg, 24.0);
      expect(AppTheme.spacingXl, 32.0);
      expect(AppTheme.spacing2Xl, 40.0);
    });

    test('最小觸控目標應該是 48dp', () {
      expect(AppTheme.minTouchTarget, 48.0);
    });

    test('圓角應該正確定義', () {
      expect(AppTheme.cardBorderRadius, 16.0);
      expect(AppTheme.buttonBorderRadius, 12.0);
      expect(AppTheme.inputBorderRadius, 12.0);
    });
  });
}
