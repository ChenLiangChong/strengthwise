import 'package:flutter/material.dart';
import '../../../../models/note_model.dart';

/// 繪圖板的自定義繪製器
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint>? points;
  
  DrawingPainter(this.points);
  
  @override
  void paint(Canvas canvas, Size size) {
    final pts = points;
    if (pts == null || pts.isEmpty) return;

    for (final point in pts) {
      canvas.drawCircle(point.offset, point.strokeWidth / 2, point.paint);

      // 如果點超過一個，則繪製線段連接它們
      for (int i = 0; i < pts.length - 1; i++) {
        if (i < pts.length - 1) {
          final p1 = pts[i];
          final p2 = pts[i + 1];
          canvas.drawLine(p1.offset, p2.offset, p1.paint);
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

