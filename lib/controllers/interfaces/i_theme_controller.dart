import 'package:flutter/material.dart';
import '../../themes/app_theme_mode.dart';

/// 主題控制器接口
///
/// 負責管理應用程式的主題狀態
/// 支援四種模式：Light、Dark、Rose、System
abstract class IThemeController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 當前主題模式
  AppThemeMode get themeMode;

  /// 是否已初始化
  bool get isInitialized;

  /// 當前主題模式的顯示名稱
  String get themeModeName;

  /// 當前主題模式的圖標
  IconData get themeModeIcon;

  /// 是否為自訂主題（非 system）
  bool get isCustomTheme;

  /// 是否為粉色主題
  bool get isRoseTheme;

  // ==================== 設定方法 ====================

  /// 設定主題模式
  Future<void> setThemeMode(AppThemeMode mode);

  /// 切換到淺色模式
  Future<void> setLightMode();

  /// 切換到深色模式
  Future<void> setDarkMode();

  /// 切換到粉色模式
  Future<void> setRoseMode();

  /// 跟隨系統模式
  Future<void> setSystemMode();

  /// 切換主題（淺色 → 深色 → 粉色 → 淺色）
  Future<void> toggleTheme(BuildContext context);

  /// 重置到預設值（跟隨系統）
  Future<void> resetToDefault();

  // ==================== 獲取主題 ====================

  /// 獲取當前主題對應的 ThemeData
  ThemeData getThemeData(Brightness platformBrightness);
}
