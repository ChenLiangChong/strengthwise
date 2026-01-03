import 'package:flutter/material.dart';
import '../calendar_layer.dart';
import '../models/calendar_marker.dart';
import '../models/marker_style.dart';

/// 標記層：渲染事件標記點
///
/// 用途：
/// - 訓練計劃標記
/// - 預約標記
/// - 自定義事件標記
///
/// 使用範例：
/// ```dart
/// MarkerLayer(
///   markerProvider: (day) {
///     final workouts = controller.getWorkoutsForDate(day);
///     return workouts.map((w) => CalendarMarker(
///       color: Colors.blue,
///       tooltip: w.title,
///       data: w,
///     )).toList();
///   },
///   maxMarkers: 3,
/// )
/// ```
class MarkerLayer implements CalendarLayer {
  /// 標記數據提供者
  final List<CalendarMarker> Function(DateTime day) markerProvider;

  /// 最大標記數量
  final int maxMarkers;

  /// 標記樣式
  final MarkerStyle style;

  const MarkerLayer({
    required this.markerProvider,
    this.maxMarkers = 3,
    this.style = MarkerStyle.defaultStyle,
  });

  @override
  Widget? buildDay(BuildContext context, DateTime day) {
    final markers = markerProvider(day);
    if (markers.isEmpty) return null;

    // 限制標記數量
    final displayMarkers = markers.take(maxMarkers).toList();

    return Positioned(
      bottom: style.bottomOffset,
      left: 0,
      right: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: displayMarkers.map((marker) {
          return Container(
            width: style.size,
            height: style.size,
            margin: EdgeInsets.symmetric(horizontal: style.spacing),
            decoration: BoxDecoration(
              color: marker.color,
              shape: BoxShape.circle,
            ),
          );
        }).toList(),
      ),
    );
  }
}

