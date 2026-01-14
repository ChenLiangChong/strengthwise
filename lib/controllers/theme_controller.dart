import 'package:flutter/material.dart';
import '../services/core/theme_service.dart';
import '../themes/app_theme_mode.dart';
import '../themes/app_theme.dart';

/// 主題控制器
///
/// 負責管理應用程式的主題狀態，並通知 UI 更新
/// 繼承 ChangeNotifier 實現響應式狀態管理
/// 支援四種模式：Light、Dark、Rose、System
class ThemeController extends ChangeNotifier {
  final ThemeService _themeService;
  AppThemeMode _themeMode = AppThemeMode.system;
  bool _isInitialized = false;

  /// 建構函式
  ///
  /// 參數：
  /// - themeService: 主題服務實例（用於持久化）
  ThemeController(this._themeService) {
    _loadTheme();
  }

  /// 當前主題模式
  AppThemeMode get themeMode => _themeMode;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 從本地存儲加載主題設定
  Future<void> _loadTheme() async {
    try {
      _themeMode = await _themeService.getThemeMode();
      _isInitialized = true;
      notifyListeners();
      debugPrint('ThemeController: 主題已載入 - $_themeMode');
    } catch (e) {
      debugPrint('ThemeController: 載入主題失敗 - $e');
      _themeMode = AppThemeMode.system;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// 設定主題模式
  ///
  /// 參數：
  /// - mode: 要設定的主題模式
  ///
  /// 會同時更新記憶體狀態和持久化存儲
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) {
      return; // 相同模式，不需要更新
    }

    _themeMode = mode;
    notifyListeners(); // 立即通知 UI 更新

    try {
      await _themeService.setThemeMode(mode);
      debugPrint('ThemeController: 主題已切換 - $mode');
    } catch (e) {
      debugPrint('ThemeController: 保存主題失敗 - $e');
      // 不影響 UI 更新，僅記錄錯誤
    }
  }

  /// 切換到淺色模式
  Future<void> setLightMode() async {
    await setThemeMode(AppThemeMode.light);
  }

  /// 切換到深色模式
  Future<void> setDarkMode() async {
    await setThemeMode(AppThemeMode.dark);
  }

  /// 切換到粉色模式 🌸
  Future<void> setRoseMode() async {
    await setThemeMode(AppThemeMode.rose);
  }

  /// 跟隨系統模式
  Future<void> setSystemMode() async {
    await setThemeMode(AppThemeMode.system);
  }

  /// 切換主題（淺色 → 深色 → 粉色 → 淺色）
  ///
  /// 如果當前是 System 模式，會切換到 Light 模式
  Future<void> toggleTheme(BuildContext context) async {
    switch (_themeMode) {
      case AppThemeMode.system:
        await setLightMode();
        break;
      case AppThemeMode.light:
        await setDarkMode();
        break;
      case AppThemeMode.dark:
        await setRoseMode();
        break;
      case AppThemeMode.rose:
        await setLightMode();
        break;
    }
  }

  /// 重置到預設值（跟隨系統）
  Future<void> resetToDefault() async {
    await _themeService.clearThemeMode();
    _themeMode = AppThemeMode.system;
    notifyListeners();
    debugPrint('ThemeController: 主題已重置為 System');
  }

  /// 獲取當前主題模式的顯示名稱
  String get themeModeName {
    switch (_themeMode) {
      case AppThemeMode.light:
        return '淺色模式';
      case AppThemeMode.dark:
        return '深色模式';
      case AppThemeMode.rose:
        return '粉色模式';
      case AppThemeMode.system:
        return '跟隨系統';
    }
  }

  /// 獲取當前主題模式的圖標
  IconData get themeModeIcon {
    switch (_themeMode) {
      case AppThemeMode.light:
        return Icons.wb_sunny;
      case AppThemeMode.dark:
        return Icons.nightlight_round;
      case AppThemeMode.rose:
        return Icons.local_florist;
      case AppThemeMode.system:
        return Icons.phone_android;
    }
  }

  /// 獲取當前主題對應的 ThemeData
  ///
  /// 用於 MaterialApp.theme 屬性
  ThemeData getThemeData(Brightness platformBrightness) {
    switch (_themeMode) {
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
      case AppThemeMode.rose:
        return AppTheme.roseTheme;
      case AppThemeMode.system:
        return platformBrightness == Brightness.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme;
    }
  }

  /// 獲取當前是否為自訂主題（非 system）
  bool get isCustomTheme => _themeMode != AppThemeMode.system;

  /// 獲取當前是否為粉色主題
  bool get isRoseTheme => _themeMode == AppThemeMode.rose;
}
