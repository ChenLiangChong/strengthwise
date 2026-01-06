import 'package:flutter/material.dart';
import 'package:strengthwise/utils/responsive/responsive_breakpoints.dart';

/// 響應式數值類
///
/// 根據螢幕尺寸返回不同的數值
/// 支援手機、平板、桌面三種主要尺寸
///
/// 使用範例：
/// ```dart
/// final padding = ResponsiveValue<double>(
///   context,
///   mobile: 16,
///   tablet: 24,
///   desktop: 32,
/// ).value;
/// ```
class ResponsiveValue<T> {
  final BuildContext context;

  /// 小型手機數值（可選，預設使用 mobile）
  final T? mobileSmall;

  /// 手機數值（必填，作為預設值）
  final T mobile;

  /// 大型手機數值（可選）
  final T? mobileLarge;

  /// 平板數值（可選，預設使用 mobile）
  final T? tablet;

  /// 大型平板數值（可選）
  final T? tabletLarge;

  /// 桌面數值（可選，預設使用 tablet）
  final T? desktop;

  ResponsiveValue(
    this.context, {
    this.mobileSmall,
    required this.mobile,
    this.mobileLarge,
    this.tablet,
    this.tabletLarge,
    this.desktop,
  });

  /// 獲取當前螢幕對應的數值
  T get value {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenType = ResponsiveBreakpoints.getScreenType(screenWidth);

    switch (screenType) {
      case ScreenType.mobileSmall:
        return mobileSmall ?? mobile;
      case ScreenType.mobile:
        return mobile;
      case ScreenType.mobileLarge:
        return mobileLarge ?? mobile;
      case ScreenType.tabletSmall:
        return tablet ?? mobileLarge ?? mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.tabletLarge:
        return tabletLarge ?? tablet ?? mobile;
      case ScreenType.desktop:
        return desktop ?? tabletLarge ?? tablet ?? mobile;
    }
  }
}

/// 快速創建響應式 EdgeInsets
///
/// 使用範例：
/// ```dart
/// padding: ResponsivePadding(
///   context,
///   mobile: EdgeInsets.all(16),
///   tablet: EdgeInsets.all(24),
/// ).value,
/// ```
class ResponsivePadding extends ResponsiveValue<EdgeInsets> {
  ResponsivePadding(
    super.context, {
    super.mobileSmall,
    required super.mobile,
    super.mobileLarge,
    super.tablet,
    super.tabletLarge,
    super.desktop,
  });
}

/// 快速創建響應式字體大小
///
/// 自動根據螢幕縮放係數調整字體
///
/// 使用範例：
/// ```dart
/// fontSize: ResponsiveFontSize(context, base: 16).value,
/// ```
class ResponsiveFontSize {
  final BuildContext context;

  /// 基準字體大小（以 iPhone 14 為基準）
  final double base;

  /// 最小字體大小（防止過小無法閱讀）
  final double minSize;

  /// 最大字體大小（防止過大破壞佈局）
  final double maxSize;

  /// 是否尊重系統字體縮放設定
  final bool respectTextScaleFactor;

  ResponsiveFontSize(
    this.context, {
    required this.base,
    this.minSize = 10,
    this.maxSize = 40,
    this.respectTextScaleFactor = true,
  });

  /// 獲取縮放後的字體大小
  double get value {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveBreakpoints.getScaleFactor(screenWidth);

    // 計算縮放後的字體
    double scaledSize = base * scaleFactor;

    // 限制範圍
    scaledSize = scaledSize.clamp(minSize, maxSize);

    return scaledSize;
  }

  /// 獲取不受系統縮放影響的字體大小
  ///
  /// 用於必須保持固定比例的 UI 元素（如圖標內數字）
  double get fixedValue {
    final textScaler = MediaQuery.of(context).textScaler;
    return value / textScaler.scale(1);
  }
}

/// 響應式間距
///
/// 根據螢幕尺寸自動調整間距
class ResponsiveSpacing {
  final BuildContext context;
  final double base;

  ResponsiveSpacing(this.context, {required this.base});

  double get value {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = ResponsiveBreakpoints.getScaleFactor(screenWidth);
    return base * scaleFactor;
  }

  /// 獲取圓整到 8 點網格的間距
  double get gridAligned {
    final raw = value;
    return (raw / 4).round() * 4.0; // 對齊到 4dp（8 點網格的一半）
  }
}

