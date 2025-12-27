import 'package:flutter/material.dart';
import '../services/core/theme_service.dart';

/// 主題控制器
/// 
/// 負責管理應用程式的主題狀態，並通知 UI 更新
/// 繼承 ChangeNotifier 實現響應式狀態管理
class ThemeController extends ChangeNotifier {
  final ThemeService _themeService;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;
  
  /// 建構函式
  /// 
  /// 參數：
  /// - themeService: 主題服務實例（用於持久化）
  ThemeController(this._themeService) {
    _loadTheme();
  }
  
  /// 當前主題模式
  ThemeMode get themeMode => _themeMode;
  
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
      _themeMode = ThemeMode.system;
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
  Future<void> setThemeMode(ThemeMode mode) async {
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
    await setThemeMode(ThemeMode.light);
  }
  
  /// 切換到深色模式
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }
  
  /// 跟隨系統模式
  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }
  
  /// 切換主題（淺色 ↔ 深色）
  /// 
  /// 注意：如果當前是 System 模式，會切換到 Light 模式
  Future<void> toggleTheme(BuildContext context) async {
    final currentBrightness = Theme.of(context).brightness;
    
    if (_themeMode == ThemeMode.system) {
      // 從 System 模式切換到 Light
      await setLightMode();
    } else if (currentBrightness == Brightness.light) {
      // 從 Light 切換到 Dark
      await setDarkMode();
    } else {
      // 從 Dark 切換到 Light
      await setLightMode();
    }
  }
  
  /// 重置到預設值（跟隨系統）
  Future<void> resetToDefault() async {
    await _themeService.clearThemeMode();
    _themeMode = ThemeMode.system;
    notifyListeners();
    debugPrint('ThemeController: 主題已重置為 System');
  }
  
  /// 獲取當前主題模式的顯示名稱
  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return '淺色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟隨系統';
    }
  }
  
  /// 獲取當前主題模式的圖標
  IconData get themeModeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.wb_sunny;
      case ThemeMode.dark:
        return Icons.nightlight_round;
      case ThemeMode.system:
        return Icons.phone_android;
    }
  }
}

