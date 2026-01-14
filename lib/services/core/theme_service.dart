import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../themes/app_theme_mode.dart';

/// 主題服務
///
/// 負責主題模式的持久化存儲與讀取
/// 支援四種模式：Light、Dark、Rose、System
class ThemeService {
  static const String _themeKey = 'theme_mode';

  /// 從本地存儲讀取主題模式
  ///
  /// 返回值：
  /// - AppThemeMode.light: 淺色模式
  /// - AppThemeMode.dark: 深色模式
  /// - AppThemeMode.rose: 粉色模式 🌸
  /// - AppThemeMode.system: 跟隨系統（預設）
  Future<AppThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeKey);

      if (themeModeString == null) {
        return AppThemeMode.system; // 預設跟隨系統
      }

      switch (themeModeString) {
        case 'light':
          return AppThemeMode.light;
        case 'dark':
          return AppThemeMode.dark;
        case 'rose':
          return AppThemeMode.rose;
        case 'system':
        default:
          return AppThemeMode.system;
      }
    } catch (e) {
      // 如果讀取失敗，返回預設值
      debugPrint('ThemeService: 讀取主題模式失敗 - $e');
      return AppThemeMode.system;
    }
  }

  /// 保存主題模式到本地存儲
  ///
  /// 參數：
  /// - mode: 要保存的主題模式
  Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeModeString;

      switch (mode) {
        case AppThemeMode.light:
          themeModeString = 'light';
          break;
        case AppThemeMode.dark:
          themeModeString = 'dark';
          break;
        case AppThemeMode.rose:
          themeModeString = 'rose';
          break;
        case AppThemeMode.system:
          themeModeString = 'system';
          break;
      }

      await prefs.setString(_themeKey, themeModeString);
      debugPrint('ThemeService: 主題模式已保存 - $themeModeString');
    } catch (e) {
      debugPrint('ThemeService: 保存主題模式失敗 - $e');
      // 不拋出異常，避免影響用戶體驗
    }
  }

  /// 清除已保存的主題設定
  ///
  /// 用於重置到預設狀態（跟隨系統）
  Future<void> clearThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
      debugPrint('ThemeService: 主題設定已清除');
    } catch (e) {
      debugPrint('ThemeService: 清除主題設定失敗 - $e');
    }
  }
}
