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

    // 計算座標縮放比例（支持跨設備）
    final scaleX = size.width / drawing!.canvasWidth;
    final scaleY = size.height / drawing!.canvasHeight;
    
    debugPrint('[DRAWING_PAINTER] 🎨 畫布尺寸: ${size.width} x ${size.height}');
    debugPrint('[DRAWING_PAINTER] 📐 原始尺寸: ${drawing!.canvasWidth} x ${drawing!.canvasHeight}');
    debugPrint('[DRAWING_PAINTER] 📏 縮放比例: $scaleX x $scaleY');

    // 繪製所有可見圖層
    for (int i = 0; i < drawing!.layers.length; i++) {
      final layer = drawing!.layers[i];
      if (!layer.isVisible) continue;

      // 繪製圖層的所有筆劃
      for (final stroke in layer.strokes) {
        _drawStroke(canvas, stroke, scaleX, scaleY);
      }
    }
  }

  /// 繪製單一筆劃（支持座標縮放）
  void _drawStroke(Canvas canvas, DrawingStroke stroke, double scaleX, double scaleY) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color.withOpacity(stroke.opacity)
      ..strokeWidth = stroke.strokeWidth * ((scaleX + scaleY) / 2) // 筆劃寬度也要縮放
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 螢光筆使用混合模式
    if (stroke.tool == DrawingTool.highlighter) {
      paint.blendMode = BlendMode.multiply;
    }

    // 繪製路徑（縮放座標）
    final path = Path();
    final firstPoint = stroke.points.first;
    path.moveTo(firstPoint.x * scaleX, firstPoint.y * scaleY);

    for (int i = 1; i < stroke.points.length; i++) {
      final current = stroke.points[i];
      final previous = stroke.points[i - 1];

      // 使用二次貝茲曲線平滑路徑（縮放座標）
      final controlX = (previous.x * scaleX + current.x * scaleX) / 2;
      final controlY = (previous.y * scaleY + current.y * scaleY) / 2;

      path.quadraticBezierTo(
        previous.x * scaleX,
        previous.y * scaleY,
        controlX,
        controlY,
      );
    }

    // 最後一個點（縮放座標）
    if (stroke.points.length > 1) {
      final last = stroke.points.last;
      path.lineTo(last.x * scaleX, last.y * scaleY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DrawingCanvasPainter oldDelegate) {
    return oldDelegate.drawing != drawing ||
        oldDelegate.currentLayerIndex != currentLayerIndex;
  }
}

