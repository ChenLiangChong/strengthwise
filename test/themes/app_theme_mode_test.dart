import 'package:flutter_test/flutter_test.dart';
import 'package:strengthwise/themes/app_theme_mode.dart';

/// AppThemeMode 枚舉測試
///
/// 測試自訂主題模式枚舉的正確性
void main() {
  group('AppThemeMode', () {
    test('應該有四個主題模式', () {
      expect(AppThemeMode.values.length, 4);
    });

    test('應該包含 light 模式', () {
      expect(AppThemeMode.values.contains(AppThemeMode.light), isTrue);
    });

    test('應該包含 dark 模式', () {
      expect(AppThemeMode.values.contains(AppThemeMode.dark), isTrue);
    });

    test('應該包含 rose 模式', () {
      expect(AppThemeMode.values.contains(AppThemeMode.rose), isTrue);
    });

    test('應該包含 system 模式', () {
      expect(AppThemeMode.values.contains(AppThemeMode.system), isTrue);
    });

    test('枚舉索引應該正確', () {
      expect(AppThemeMode.light.index, 0);
      expect(AppThemeMode.dark.index, 1);
      expect(AppThemeMode.rose.index, 2);
      expect(AppThemeMode.system.index, 3);
    });

    test('枚舉名稱應該正確', () {
      expect(AppThemeMode.light.name, 'light');
      expect(AppThemeMode.dark.name, 'dark');
      expect(AppThemeMode.rose.name, 'rose');
      expect(AppThemeMode.system.name, 'system');
    });
  });
}
