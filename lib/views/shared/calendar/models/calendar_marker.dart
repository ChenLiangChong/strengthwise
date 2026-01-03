import 'package:flutter/material.dart';

/// 行事曆標記數據
///
/// 用於在日期單元格上顯示標記點
class CalendarMarker {
  /// 標記顏色
  final Color color;

  /// 提示文字（可選）
  final String? tooltip;

  /// 關聯數據（可選）
  ///
  /// 可以是 WorkoutRecord、AppointmentModel 等
  final dynamic data;

  const CalendarMarker({
    required this.color,
    this.tooltip,
    this.data,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarMarker &&
        other.color == color &&
        other.tooltip == tooltip &&
        other.data == data;
  }

  @override
  int get hashCode => Object.hash(color, tooltip, data);

  @override
  String toString() => 'CalendarMarker(color: $color, tooltip: $tooltip)';
}

