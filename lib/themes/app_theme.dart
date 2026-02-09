import 'package:flutter/material.dart';

/// StrengthWise Kinetic 設計系統 - 主題配置
///
/// 基於設計團隊最終決策的 Titanium Blue 配色方案
/// 體現「打熬」精神的專屬色票系統
///
/// 設計文檔：docs/UI_DEVELOPER_GUIDE.md
/// 設計決策：docs/COLOR_SPEC_ANALYSIS.md
class AppTheme {
  // ---------------------------------------------------------------------------
  // 1. 核心色票定義 (Core Palette Definition)
  // ---------------------------------------------------------------------------

  // Neutral / Slate Scale
  static const Color slate50 = Color(0xFFF8FAFC); // 極致乾淨、透氣的白
  static const Color slate100 = Color(0xFFF1F5F9); // Surface Variant
  static const Color slate200 =
      Color(0xFFE2E8F0); // [修正] Dark Mode 次要文字 - 更亮更易讀
  static const Color slate300 = Color(0xFFCBD5E1); // [決策] Outline - 清晰銳利
  static const Color slate400 = Color(0xFF94A3B8); // Hint Text
  static const Color slate500 = Color(0xFF64748B); // (棄用，太淡)
  static const Color slate700 =
      Color(0xFF334155); // [修正] Light Mode 次要文字 - 加深更易讀
  static const Color slate800 = Color(0xFF1E293B); // Dark Surface - 深岩灰
  static const Color slate900 = Color(0xFF0F172A); // Dark Background - 深海藍

  // Brand Colors (Light Mode)
  static const Color blue600 = Color(0xFF0EA5E9); // Primary - Sky 500 電光藍
  static const Color blue100 = Color(0xFFDBEAFE); // Primary Container
  static const Color teal600 = Color(0xFF0D9488); // [決策] Secondary - 孔雀藍綠

  // Brand Colors (Dark Mode)
  static const Color sky400 = Color(0xFF38BDF8); // [決策] Primary - 電光藍
  static const Color sky900 = Color(0xFF0C4A6E); // On Primary Container
  static const Color teal400 = Color(0xFF2DD4BF); // [決策] Secondary - 明亮青綠
  static const Color teal100 = Color(0xFFCCFBF1); // Secondary Container (Light)
  static const Color teal700 =
      Color(0xFF0F766E); // On Secondary Container (Light)
  static const Color teal800 = Color(0xFF115E59); // Secondary Container (Dark)

  // Semantic Colors
  static const Color errorRed =
      Color(0xFFEF4444); // [決策] Tailwind Red-500 - 激情警示

  // 語意色彩 (Semantic Colors) - Success / Warning
  static const Color successLight = Color(0xFF10B981); // Emerald-500
  static const Color successDark = Color(0xFF34D399); // Emerald-400
  static const Color warningLight = Color(0xFFF59E0B); // Amber-500
  static const Color warningDark = Color(0xFFFBBF24); // Amber-400

  // SOAP 筆記專用色彩
  static const Color soapSubjective = Color(0xFF3B82F6); // Blue-500
  static const Color soapObjective = Color(0xFF10B981); // Emerald-500
  static const Color soapAssessment = Color(0xFFF59E0B); // Amber-500
  static const Color soapPlan = Color(0xFF8B5CF6); // Violet-500

  // ---------------------------------------------------------------------------
  // Rose Theme Colors (UI/UX Pro Max 推薦配色)
  // ---------------------------------------------------------------------------
  // 基於 Beauty/Spa/Wellness 產品類型：Soft pastels + Cream + Gold accents

  /// Rose 主色 - 快捷按鈕背景（primaryContainer，略深於背景）
  static const Color rosePrimary = Color(0xFFFCE7F3);

  /// Rose 輔助色 - 與主色相同（按鈕、選擇日期等）
  static const Color roseSecondary = Color(0xFFF472B6);

  /// Rose 背景色 - 淡玫瑰奶油
  static const Color roseBackground = Color(0xFFFFF5F7);

  /// Rose 主要文字 - Deep Rose Brown
  static const Color roseOnSurface = Color(0xFF4A1A2A);

  /// Rose 次要文字 - Muted Rose
  static const Color roseOnSurfaceVariant = Color(0xFF9D4E6E);

  /// Rose 邊框 - Blush Pink
  static const Color roseOutline = Color(0xFFFED7E2);

  /// Rose 點綴色 - Gold/Cream accent
  static const Color roseAccent = Color(0xFFD4A574);

  /// Rose Primary Container - 柔和粉紅（Banner 背景）
  static const Color rosePrimaryDark = Color(0xFFF472B6);

  // ---------------------------------------------------------------------------
  // 2. 8 點網格間距系統 (8-Point Grid)
  // ---------------------------------------------------------------------------

  /// 微間距 - 4dp
  static const double spacingXs = 4.0;

  /// 小間距 - 8dp (基礎單位)
  static const double spacingSm = 8.0;

  /// 中間距 - 16dp (元素間距)
  static const double spacingMd = 16.0;

  /// 大間距 - 24dp (區塊間距)
  static const double spacingLg = 24.0;

  /// 超大間距 - 32dp (區段分隔)
  static const double spacingXl = 32.0;

  /// 巨大間距 - 40dp (主要分隔)
  static const double spacing2Xl = 40.0;

  /// 最小觸控目標 - 48dp (符合 Material Design 規範)
  static const double minTouchTarget = 48.0;

  /// 卡片圓角 - 16dp
  static const double cardBorderRadius = 16.0;

  /// 按鈕圓角 - 12dp
  static const double buttonBorderRadius = 12.0;

  /// 輸入框圓角 - 12dp
  static const double inputBorderRadius = 12.0;

  // ---------------------------------------------------------------------------
  // 3. 淺色主題 (Light Theme)
  // ---------------------------------------------------------------------------

  /// 淺色模式主題
  ///
  /// [決策] 使用 Slate-50 極致乾淨背景，呈現輕量、透氣的數據介面
  /// 適用於日間或明亮健身房環境
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: slate50, // [決策] 極致乾淨的背景

      colorScheme: const ColorScheme(
        brightness: Brightness.light,

        // Primary - 皇家藍
        primary: blue600,
        onPrimary: Colors.white,
        primaryContainer: blue100,
        onPrimaryContainer: slate900,

        // Secondary - 孔雀藍綠 [決策] 和諧高級的輔助色
        secondary: teal600,
        onSecondary: Colors.white,
        secondaryContainer: teal100,
        onSecondaryContainer: teal700,

        // Error - Tailwind Red [決策] 鮮豔有激情
        error: errorRed,
        onError: Colors.white,
        errorContainer: Color(0xFFFEE2E2), // Red-100
        onErrorContainer: Color(0xFF991B1B), // Red-800

        // Surface & Background
        surface: Colors.white,
        onSurface: slate900, // 主要文字 - 深藍灰

        // [修正] 清晰的視覺層次 - 加深次要文字以提升易讀性
        onSurfaceVariant: slate700, // 次要文字 - 從 slate500 加深到 slate700
        outline: slate300, // 邊框 - 剛剛好的銳利度
        outlineVariant: slate200, // 較淡的分隔線
        surfaceContainerHighest: slate100,
      ),

      // ---------------------------------------------------------------------------
      // 元件樣式覆寫 (Component Overrides)
      // ---------------------------------------------------------------------------

      // [修正] 卡片主題 - 增加呼吸感和層次
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2, // [修正] 增加微陰影以提升層次感
        shadowColor: const Color(0x0F000000), // 6% 透明度黑色陰影
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: slate200, width: 1), // [修正] 使用更淡的邊框
          borderRadius: BorderRadius.circular(20), // [修正] 從 16 增加到 20，更現代
        ),
        margin: const EdgeInsets.symmetric(
          vertical: 12, // [修正] 增加垂直間距
          horizontal: spacingMd,
        ),
      ),

      // AppBar 主題
      appBarTheme: const AppBarTheme(
        backgroundColor: slate50,
        foregroundColor: slate900,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: slate900,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: -0.5,
        ),
      ),

      // 輸入框主題
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: slate400), // [修正] 淺灰 placeholder，與輸入文字明確區分
        floatingLabelStyle:
            const TextStyle(color: blue600), // [修正] 聚焦時 label 用主色
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: slate300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: blue600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: spacingMd,
        ),
      ),

      // 按鈕主題
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
        ),
      ),

      // FloatingActionButton 主題
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // 底部導航欄主題
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: blue600,
        unselectedItemColor: slate400,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Divider 主題
      dividerTheme: const DividerThemeData(
        color: slate300,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. 深色主題 (Dark Theme)
  // ---------------------------------------------------------------------------

  /// 深色模式主題
  ///
  /// [決策] 使用 Sky-400 電光藍，模擬健身房霓虹燈效果，給予能量回饋
  /// 適用於夜間或強調專注的訓練環境
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: slate900, // 深海藍背景

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,

        // Primary - 電光藍 [決策] 帶有能量感的霓虹效果
        primary: sky400,
        onPrimary: slate900, // 深色字體，對比度更好
        primaryContainer: slate800,
        onPrimaryContainer: sky400,

        // Secondary - 明亮青綠 [決策] 和諧且高級
        secondary: teal400,
        onSecondary: slate900,
        secondaryContainer: teal800,
        onSecondaryContainer: teal100,

        // Error - Tailwind Red
        error: errorRed,
        onError: Colors.white,
        errorContainer: Color(0xFF7F1D1D), // Red-900
        onErrorContainer: Color(0xFFFEE2E2),

        // Surface & Background
        surface: slate800, // 深岩灰卡片
        onSurface: Colors.white, // [修正] 純白文字 - 從 slate50 改為純白以提升易讀性

        // [修正] 深色模式的視覺層次 - 提亮次要文字
        onSurfaceVariant: slate200, // 次要文字 - 從 slate400 提亮到 slate200
        outline: slate700, // 深色邊框
        outlineVariant: slate800, // 更深的分隔線
        surfaceContainerHighest: slate700,
      ),

      // ---------------------------------------------------------------------------
      // 元件樣式覆寫 (Component Overrides)
      // ---------------------------------------------------------------------------

      // [修正] 卡片主題 - 深色模式增加邊框以提升辨識度
      cardTheme: CardThemeData(
        color: slate800,
        elevation: 0, // 深色模式不需要陰影
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: slate700, width: 1), // [修正] 增加邊框以提升層次
          borderRadius: BorderRadius.circular(20), // [修正] 從 16 增加到 20
        ),
        margin: const EdgeInsets.symmetric(
          vertical: 12, // [修正] 增加垂直間距
          horizontal: spacingMd,
        ),
      ),

      // AppBar 主題
      appBarTheme: const AppBarTheme(
        backgroundColor: slate900,
        foregroundColor: slate50,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: slate50,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: -0.5,
        ),
      ),

      // 輸入框主題
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slate700, // 比卡片稍亮
        hintStyle: const TextStyle(color: slate400), // [修正] 中灰 placeholder，與白色輸入文字明確區分
        floatingLabelStyle:
            const TextStyle(color: sky400), // [修正] 聚焦時 label 用主色
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: slate700, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: sky400, width: 2), // 電光藍聚焦
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: spacingMd,
        ),
      ),

      // 按鈕主題
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
        ),
      ),

      // FloatingActionButton 主題
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // 底部導航欄主題
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: slate800,
        selectedItemColor: sky400, // [決策] 發光的圖標效果
        unselectedItemColor: slate500,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Divider 主題
      dividerTheme: const DividerThemeData(
        color: slate700,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. 粉色主題 (Rose Theme) 🌸
  // ---------------------------------------------------------------------------

  /// 粉色模式主題
  ///
  /// 基於 UI/UX Pro Max 推薦的 Beauty/Spa/Wellness 配色
  /// Soft pastels (Pink) + Cream + Gold accents
  /// 適合女性用戶的柔和視覺體驗
  static ThemeData get roseTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: roseBackground,

      colorScheme: const ColorScheme(
        brightness: Brightness.light,

        // Primary - Light Pink
        primary: rosePrimaryDark, // 使用較深的粉紅作為主色以確保對比度
        onPrimary: Colors.white,
        primaryContainer: rosePrimary,
        onPrimaryContainer: roseOnSurface,

        // Secondary - Warm Pink
        secondary: roseSecondary,
        onSecondary: roseOnSurface,
        secondaryContainer: Color(0xFFFCE7F3), // Pink-100
        onSecondaryContainer: roseOnSurface,

        // Tertiary - Gold accent
        tertiary: roseAccent,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFFEF3C7), // Amber-100
        onTertiaryContainer: Color(0xFF78350F), // Amber-900

        // Error - 保持紅色
        error: errorRed,
        onError: Colors.white,
        errorContainer: Color(0xFFFEE2E2),
        onErrorContainer: Color(0xFF991B1B),

        // Surface & Background
        surface: Colors.white,
        onSurface: roseOnSurface,
        onSurfaceVariant: roseOnSurfaceVariant,
        outline: roseOutline,
        outlineVariant: Color(0xFFFDF2F8), // Pink-50
        surfaceContainerHighest: Color(0xFFFDF2F8),
      ),

      // ---------------------------------------------------------------------------
      // 元件樣式覆寫 (Component Overrides)
      // ---------------------------------------------------------------------------

      // 卡片主題
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x0FEC4899), // 粉紅色陰影
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: roseOutline, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: spacingMd,
        ),
      ),

      // AppBar 主題
      appBarTheme: const AppBarTheme(
        backgroundColor: roseBackground,
        foregroundColor: roseOnSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: roseOnSurface,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: -0.5,
        ),
      ),

      // 輸入框主題
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(
            color: roseOnSurfaceVariant
                .withValues(alpha: 0.5)), // [修正] 半透明粉 placeholder
        floatingLabelStyle: const TextStyle(
            color: rosePrimaryDark), // [修正] 聚焦時 label 用主色
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: roseOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: rosePrimaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: spacingMd,
        ),
      ),

      // 按鈕主題
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size.fromHeight(minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMd,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
        ),
      ),

      // FloatingActionButton 主題
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // 底部導航欄主題
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: rosePrimaryDark,
        unselectedItemColor: roseOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Divider 主題
      dividerTheme: const DividerThemeData(
        color: roseOutline,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. 輔助方法
  // ---------------------------------------------------------------------------

  /// 根據亮度獲取對應主題
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.light ? lightTheme : darkTheme;
  }

  /// 判斷當前是否為深色模式
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// 獲取成功色彩（根據當前主題）
  static Color getSuccessColor(BuildContext context) {
    return isDarkMode(context) ? successDark : successLight;
  }

  /// 獲取警告色彩（根據當前主題）
  static Color getWarningColor(BuildContext context) {
    return isDarkMode(context) ? warningDark : warningLight;
  }

  /// 獲取紅綠燈顏色（用於 Readiness 相關組件）
  ///
  /// [level] 1-5 的數值，1=差，5=好
  static Color getTrafficLightColorByLevel(int level) {
    switch (level) {
      case 1:
        return errorRed; // 紅色
      case 2:
        return warningLight; // 警告橘色
      case 3:
        return const Color(0xFFFBBF24); // 警告黃色
      case 4:
        return successDark; // 成功淺綠
      case 5:
        return successLight; // 成功綠色
      default:
        return warningLight;
    }
  }

  // ---------------------------------------------------------------------------
  // 6. 常用顏色輔助工具
  // ---------------------------------------------------------------------------

  /// 獲取次要文字顏色（根據當前主題）
  /// [修正] 加深以提升易讀性
  static Color getSecondaryTextColor(BuildContext context) {
    return isDarkMode(context) ? slate200 : slate700;
  }

  /// 獲取邊框顏色（根據當前主題）
  static Color getOutlineColor(BuildContext context) {
    return isDarkMode(context) ? slate700 : slate300;
  }
}
