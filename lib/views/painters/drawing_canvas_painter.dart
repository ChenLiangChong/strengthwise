import 'package:flutter/material.dart';
import '../../models/drawing_note_model.dart';

/// CustomPainter 實現（繪圖引擎）
class DrawingCanvasPainter extends CustomPainter {
  final DrawingNoteModel? drawing;
  final int currentLayerIndex;

  DrawingCanvasPainter({
    required this.drawing,
    required this.currentLayerIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (drawing == null) return;

    // 繪製所有可見圖層
    for (int i = 0; i < drawing!.layers.length; i++) {
      final layer = drawing!.layers[i];
      if (!layer.isVisible) continue;

      // 繪製圖層的所有筆劃
      for (final stroke in layer.strokes) {
        _drawStroke(canvas, stroke);
      }
    }
  }

  /// 繪製單一筆劃
  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color.withOpacity(stroke.opacity)
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 螢光筆使用混合模式
    if (stroke.tool == DrawingTool.highlighter) {
      paint.blendMode = BlendMode.multiply;
    }

    // 繪製路徑
    final path = Path();
    path.moveTo(stroke.points.first.x, stroke.points.first.y);

    for (int i = 1; i < stroke.points.length; i++) {
      final current = stroke.points[i];
      final previous = stroke.points[i - 1];

      // 使用二次貝茲曲線平滑路徑
      final controlX = (previous.x + current.x) / 2;
      final controlY = (previous.y + current.y) / 2;

      path.quadraticBezierTo(
        previous.x,
        previous.y,
        controlX,
        controlY,
      );
    }

    // 最後一個點
    if (stroke.points.length > 1) {
      final last = stroke.points.last;
      path.lineTo(last.x, last.y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DrawingCanvasPainter oldDelegate) {
    return oldDelegate.drawing != drawing ||
        oldDelegate.currentLayerIndex != currentLayerIndex;
  }
}

