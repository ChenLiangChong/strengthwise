import 'package:flutter/material.dart';
import 'package:strengthwise/themes/app_theme.dart';
import 'package:strengthwise/utils/responsive/responsive_breakpoints.dart';

/// 響應式文字樣式
///
/// 基於 Theme.of(context).textTheme 進行響應式縮放
/// 遵循 Material Design 3 的 Typography 規範
/// 符合 StrengthWise UI 開發規範
///
/// 使用範例：
/// ```dart
/// // ✅ 推薦
/// Text(
///   '標題',
///   style: context.responsive.headlineMedium,
/// )
///
/// // ✅ 也可以直接使用 Theme（不縮放）
/// Text(
///   '標題',
///   style: Theme.of(context).textTheme.headlineMedium,
/// )
/// ```
class ResponsiveTextStyles {
  final BuildContext context;

  // 快取計算結果
  double? _scaleFactor;
  TextTheme? _baseTheme;
  ColorScheme? _colorScheme;

  ResponsiveTextStyles(this.context);

  /// 獲取縮放係數
  double get scaleFactor {
    _scaleFactor ??= ResponsiveBreakpoints.getScaleFactor(
      MediaQuery.of(context).size.width,
    );
    return _scaleFactor!;
  }

  /// 獲取基礎 TextTheme（來自 Theme.of(context)）
  TextTheme get baseTheme {
    _baseTheme ??= Theme.of(context).textTheme;
    return _baseTheme!;
  }

  /// 獲取 ColorScheme
  ColorScheme get colorScheme {
    _colorScheme ??= Theme.of(context).colorScheme;
    return _colorScheme!;
  }

  // ---------------------------------------------------------------------------
  // Display 系列（超大標題）
  // ---------------------------------------------------------------------------

  /// Display Large (57sp 基準)
  TextStyle get displayLarge => _scale(baseTheme.displayLarge, 57);

  /// Display Medium (45sp 基準)
  TextStyle get displayMedium => _scale(baseTheme.displayMedium, 45);

  /// Display Small (36sp 基準)
  TextStyle get displaySmall => _scale(baseTheme.displaySmall, 36);

  // ---------------------------------------------------------------------------
  // Headline 系列（頁面標題）
  // ---------------------------------------------------------------------------

  /// Headline Large (32sp 基準)
  TextStyle get headlineLarge => _scale(baseTheme.headlineLarge, 32);

  /// Headline Medium (28sp 基準)
  TextStyle get headlineMedium => _scale(baseTheme.headlineMedium, 28);

  /// Headline Small (24sp 基準)
  TextStyle get headlineSmall => _scale(baseTheme.headlineSmall, 24);

  // ---------------------------------------------------------------------------
  // Title 系列（區塊標題）
  // ---------------------------------------------------------------------------

  /// Title Large (22sp 基準)
  TextStyle get titleLarge => _scale(baseTheme.titleLarge, 22);

  /// Title Medium (16sp 基準)
  TextStyle get titleMedium => _scale(baseTheme.titleMedium, 16);

  /// Title Small (14sp 基準)
  TextStyle get titleSmall => _scale(baseTheme.titleSmall, 14);

  // ---------------------------------------------------------------------------
  // Label 系列（按鈕、標籤）
  // ---------------------------------------------------------------------------

  /// Label Large (14sp 基準)
  TextStyle get labelLarge => _scale(baseTheme.labelLarge, 14);

  /// Label Medium (12sp 基準)
  TextStyle get labelMedium => _scale(baseTheme.labelMedium, 12);

  /// Label Small (11sp 基準)
  TextStyle get labelSmall => _scale(baseTheme.labelSmall, 11);

  // ---------------------------------------------------------------------------
  // Body 系列（正文）
  // ---------------------------------------------------------------------------

  /// Body Large (16sp 基準)
  TextStyle get bodyLarge => _scale(baseTheme.bodyLarge, 16);

  /// Body Medium (14sp 基準)
  TextStyle get bodyMedium => _scale(baseTheme.bodyMedium, 14);

  /// Body Small (12sp 基準)
  TextStyle get bodySmall => _scale(baseTheme.bodySmall, 12);

  // ---------------------------------------------------------------------------
  // StrengthWise 專用樣式
  // ---------------------------------------------------------------------------

  /// 數據顯示（大）- 用於重量、次數等核心數據
  TextStyle get dataLarge => TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: _clampedSize(32),
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  /// 數據顯示（中）
  TextStyle get dataMedium => TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: _clampedSize(24),
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );

  /// 數據顯示（小）
  TextStyle get dataSmall => TextStyle(
        fontFamily: 'JetBrains Mono',
        fontSize: _clampedSize(16),
        fontWeight: FontWeight.w500,
      );

  /// 問候語樣式（首頁 Hero）
  TextStyle get greeting => TextStyle(
        fontSize: _clampedSize(24),
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );

  /// 日期顯示樣式
  TextStyle get date => TextStyle(
        fontSize: _clampedSize(14),
        color: Colors.white.withOpacity(0.9),
      );

  /// 卡片標題
  TextStyle get cardTitle => TextStyle(
        fontSize: _clampedSize(18),
        fontWeight: FontWeight.w600,
      );

  /// 卡片副標題
  TextStyle get cardSubtitle => TextStyle(
        fontSize: _clampedSize(14),
        color: AppTheme.getSecondaryTextColor(context),
      );

  /// 區塊標題（帶圖標的標題）
  TextStyle get sectionTitle => TextStyle(
        fontSize: _clampedSize(20),
        fontWeight: FontWeight.bold,
      );

  // ---------------------------------------------------------------------------
  // 私有輔助方法
  // ---------------------------------------------------------------------------

  /// 縮放並限制字體大小
  TextStyle _scale(TextStyle? base, double defaultSize) {
    final size = (base?.fontSize ?? defaultSize) * scaleFactor;
    return (base ?? const TextStyle()).copyWith(
      fontSize: size.clamp(10.0, 60.0),
    );
  }

  /// 計算限制範圍內的字體大小
  double _clampedSize(double baseSize) {
    final scaled = baseSize * scaleFactor;
    // 最小 10sp，最大為基準的 1.5 倍
    return scaled.clamp(10.0, baseSize * 1.5);
  }
}

