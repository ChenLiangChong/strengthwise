/// StrengthWise 響應式斷點定義
///
/// 基於業界標準的響應式設計斷點
/// 參考：Material Design、Bootstrap、Tailwind CSS
library;

/// 螢幕類型枚舉
enum ScreenType {
  /// 小型手機（< 360dp）
  mobileSmall,

  /// 標準手機（360-599dp）
  mobile,

  /// 大型手機/摺疊機內螢幕（600-719dp）
  mobileLarge,

  /// 小型平板（720-839dp）
  tabletSmall,

  /// 標準平板（840-1023dp）
  tablet,

  /// 大型平板/小型桌面（1024-1279dp）
  tabletLarge,

  /// 桌面（≥ 1280dp）
  desktop,
}

/// 響應式斷點常量
///
/// 符合 Material Design 3 斷點規範
/// https://m3.material.io/foundations/layout/applying-layout/window-size-classes
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  // ---------------------------------------------------------------------------
  // 1. 核心斷點（dp）
  // ---------------------------------------------------------------------------

  /// 小型手機最大寬度
  static const double mobileSmallMax = 359;

  /// 標準手機最大寬度（Compact）
  static const double mobileMax = 599;

  /// 大型手機最大寬度
  static const double mobileLargeMax = 719;

  /// 小型平板最大寬度
  static const double tabletSmallMax = 839;

  /// 標準平板最大寬度（Medium）
  static const double tabletMax = 1023;

  /// 大型平板最大寬度（Expanded）
  static const double tabletLargeMax = 1279;

  // ---------------------------------------------------------------------------
  // 2. 常用設備參考尺寸
  // ---------------------------------------------------------------------------

  /// iPhone SE（小螢幕）
  static const double iphoneSe = 375;

  /// iPhone 14 / 15（標準）
  static const double iphone14 = 390;

  /// iPhone 14 Pro Max（大螢幕）
  static const double iphone14ProMax = 430;

  /// iPad Mini
  static const double ipadMini = 744;

  /// iPad Air / Pro 11"
  static const double ipadAir = 820;

  /// iPad Pro 12.9"
  static const double ipadPro = 1024;

  // ---------------------------------------------------------------------------
  // 3. 縮放係數
  // ---------------------------------------------------------------------------

  /// 根據螢幕寬度獲取縮放係數
  ///
  /// 基準：390dp（iPhone 14）
  /// 小螢幕縮小、大螢幕維持基準（與 NavigationRail 協調）
  static double getScaleFactor(double screenWidth) {
    if (screenWidth < 320) return 0.8; // 極小螢幕
    if (screenWidth < 360) return 0.88; // 小型手機
    if (screenWidth < 390) return 0.94; // 中小手機
    if (screenWidth < 430) return 1.0; // 標準手機（基準）
    if (screenWidth < 600) return 1.05; // 大型手機
    // [修改] 平板/桌面維持基準，不放大（與 NavigationRail 76dp 協調）
    if (screenWidth < 840) return 1.0; // 小平板
    if (screenWidth < 1024) return 1.0; // 平板
    return 1.0; // 大平板/桌面
  }

  /// 根據螢幕寬度獲取螢幕類型
  static ScreenType getScreenType(double screenWidth) {
    if (screenWidth <= mobileSmallMax) return ScreenType.mobileSmall;
    if (screenWidth <= mobileMax) return ScreenType.mobile;
    if (screenWidth <= mobileLargeMax) return ScreenType.mobileLarge;
    if (screenWidth <= tabletSmallMax) return ScreenType.tabletSmall;
    if (screenWidth <= tabletMax) return ScreenType.tablet;
    if (screenWidth <= tabletLargeMax) return ScreenType.tabletLarge;
    return ScreenType.desktop;
  }

  /// 是否為手機尺寸
  static bool isMobile(double screenWidth) {
    return screenWidth <= mobileLargeMax;
  }

  /// 是否為平板尺寸
  static bool isTablet(double screenWidth) {
    return screenWidth > mobileLargeMax && screenWidth <= tabletLargeMax;
  }

  /// 是否為桌面尺寸
  static bool isDesktop(double screenWidth) {
    return screenWidth > tabletLargeMax;
  }
}
