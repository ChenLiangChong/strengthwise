import 'package:flutter/material.dart';
import 'package:strengthwise/themes/app_theme.dart';
import 'package:strengthwise/utils/responsive/responsive_breakpoints.dart';
import 'package:strengthwise/utils/responsive/responsive_text_styles.dart';

/// BuildContext 響應式擴展
///
/// 提供便捷的響應式工具訪問
///
/// 使用範例：
/// ```dart
/// // 獲取螢幕類型
/// if (context.screenType == ScreenType.tablet) { ... }
///
/// // 獲取響應式文字樣式
/// style: context.responsive.headlineMedium,
///
/// // 獲取響應式間距
/// padding: EdgeInsets.all(context.spacing.md),
///
/// // 快速判斷
/// if (context.isMobile) { ... }
/// ```
extension ResponsiveContextExtension on BuildContext {
  // ---------------------------------------------------------------------------
  // 1. 螢幕資訊
  // ---------------------------------------------------------------------------

  /// 螢幕寬度（dp）
  double get screenWidth => MediaQuery.of(this).size.width;

  /// 螢幕高度（dp）
  double get screenHeight => MediaQuery.of(this).size.height;

  /// 螢幕類型
  ScreenType get screenType =>
      ResponsiveBreakpoints.getScreenType(screenWidth);

  /// 縮放係數
  double get scaleFactor => ResponsiveBreakpoints.getScaleFactor(screenWidth);

  // ---------------------------------------------------------------------------
  // 2. 快速判斷
  // ---------------------------------------------------------------------------

  /// 是否為小型手機（< 360dp）
  bool get isMobileSmall => screenType == ScreenType.mobileSmall;

  /// 是否為手機尺寸（含小型手機）
  bool get isMobile => ResponsiveBreakpoints.isMobile(screenWidth);

  /// 是否為平板尺寸
  bool get isTablet => ResponsiveBreakpoints.isTablet(screenWidth);

  /// 是否為桌面尺寸
  bool get isDesktop => ResponsiveBreakpoints.isDesktop(screenWidth);

  /// 是否為橫向
  bool get isLandscape =>
      MediaQuery.of(this).orientation == Orientation.landscape;

  /// 是否為縱向
  bool get isPortrait =>
      MediaQuery.of(this).orientation == Orientation.portrait;

  // ---------------------------------------------------------------------------
  // 3. 響應式文字樣式
  // ---------------------------------------------------------------------------

  /// 響應式文字樣式
  ResponsiveTextStyles get responsive => ResponsiveTextStyles(this);

  // ---------------------------------------------------------------------------
  // 4. 響應式間距
  // ---------------------------------------------------------------------------

  /// 響應式間距系統
  _ResponsiveSpacing get spacing => _ResponsiveSpacing(this);

  // ---------------------------------------------------------------------------
  // 5. 響應式內邊距
  // ---------------------------------------------------------------------------

  /// 頁面標準內邊距
  EdgeInsets get pagePadding {
    if (isDesktop) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
    if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
    if (isMobileSmall) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  /// 卡片標準內邊距
  EdgeInsets get cardPadding {
    if (isDesktop) return const EdgeInsets.all(24);
    if (isTablet) return const EdgeInsets.all(20);
    if (isMobileSmall) return const EdgeInsets.all(12);
    return const EdgeInsets.all(16);
  }

  /// 區塊間距（垂直）
  double get sectionSpacing {
    if (isDesktop) return 32;
    if (isTablet) return 28;
    if (isMobileSmall) return 16;
    return 24;
  }

  // ---------------------------------------------------------------------------
  // 6. 響應式欄數
  // ---------------------------------------------------------------------------

  /// Grid 佈局建議欄數
  int get gridColumns {
    if (isDesktop) return 4;
    if (isTablet) return 3;
    if (screenWidth > 500) return 2;
    return 1;
  }

  /// 列表項目建議欄數
  int get listColumns {
    if (isDesktop) return 3;
    if (isTablet) return 2;
    return 1;
  }
}

/// 響應式間距類
///
/// 根據螢幕尺寸自動調整間距，並對齊到 4dp 網格
/// 符合 StrengthWise 8 點網格規範
class _ResponsiveSpacing {
  final BuildContext context;
  final double _scale;

  _ResponsiveSpacing(this.context)
      : _scale = ResponsiveBreakpoints.getScaleFactor(
          MediaQuery.of(context).size.width,
        );

  /// 對齊到 4dp 網格（8 點網格的一半）
  double _alignToGrid(double value) {
    return (value / 4).round() * 4.0;
  }

  /// 微間距（4dp 基準）→ 2-8dp
  double get xs => _alignToGrid((AppTheme.spacingXs * _scale).clamp(2.0, 8.0));

  /// 小間距（8dp 基準）→ 4-12dp
  double get sm => _alignToGrid((AppTheme.spacingSm * _scale).clamp(4.0, 12.0));

  /// 中間距（16dp 基準）→ 12-24dp
  double get md =>
      _alignToGrid((AppTheme.spacingMd * _scale).clamp(12.0, 24.0));

  /// 大間距（24dp 基準）→ 16-32dp
  double get lg =>
      _alignToGrid((AppTheme.spacingLg * _scale).clamp(16.0, 32.0));

  /// 超大間距（32dp 基準）→ 24-48dp
  double get xl =>
      _alignToGrid((AppTheme.spacingXl * _scale).clamp(24.0, 48.0));

  /// 巨大間距（40dp 基準）→ 32-56dp
  double get xxl =>
      _alignToGrid((AppTheme.spacing2Xl * _scale).clamp(32.0, 56.0));
}

/// 數值響應式擴展
extension ResponsiveDoubleExtension on double {
  /// 根據螢幕縮放
  ///
  /// 使用範例：
  /// ```dart
  /// fontSize: 16.0.scaled(context),
  /// ```
  double scaled(BuildContext context) {
    final scale = context.scaleFactor;
    return this * scale;
  }

  /// 根據螢幕縮放並限制範圍
  double scaledClamped(BuildContext context, {double? min, double? max}) {
    final scaled = this.scaled(context);
    return scaled.clamp(min ?? 0, max ?? double.infinity);
  }
}

/// 整數響應式擴展
extension ResponsiveIntExtension on int {
  /// 根據螢幕縮放
  double scaled(BuildContext context) => toDouble().scaled(context);
}

