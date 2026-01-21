import 'package:flutter/material.dart';
import '../calendar_layer.dart';

/// 背景層：渲染日期背景色
///
/// 用途：
/// - 時間偏好視覺化（綠/黃/紅）
/// - 熱力圖（訓練頻率）
/// - 自定義背景標記
///
/// 使用範例：
/// ```dart
/// BackgroundLayer(
///   colorProvider: (day) {
///     final prefs = controller.getAvailabilityForDate(day);
///     if (prefs.isEmpty) return null;
///     
///     if (prefs.any((p) => p.priority == 'preferred')) {
///       return Colors.green;
///     } else if (prefs.any((p) => p.priority == 'available')) {
///       return Colors.orange;
///     } else {
///       return Colors.red;
///     }
///   },
///   opacity: 0.15,
/// )
/// ```
class BackgroundLayer implements CalendarLayer {
  /// 背景顏色提供者
  ///
  /// 返回 null 表示不渲染背景
  final Color? Function(DateTime day) colorProvider;

  /// 邊框顏色提供者（可選）
  final Color? Function(DateTime day)? borderColorProvider;

  /// 圓角半徑
  final double borderRadius;

  /// 透明度（0.0 - 1.0）
  final double opacity;

  /// 內邊距
  final EdgeInsets margin;

  const BackgroundLayer({
    required this.colorProvider,
    this.borderColorProvider,
    this.borderRadius = 8.0,
    this.opacity = 0.15,
    this.margin = const EdgeInsets.all(4),
  });

  @override
  Widget? buildDay(BuildContext context, DateTime day) {
    final bgColor = colorProvider(day);
    if (bgColor == null) return null;

    final borderColor = borderColorProvider?.call(day);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: opacity),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.0)
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

