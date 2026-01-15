import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:strengthwise/views/pages/notes/photo_annotation_page.dart';

/// 標註繪製器
/// 
/// 負責在照片上繪製標註（圓圈、箭頭、文字）
class AnnotationPainter extends CustomPainter {
  final ui.Image image;
  final List<Annotation> annotations;
  final Annotation? currentAnnotation;

  AnnotationPainter({
    required this.image,
    required this.annotations,
    this.currentAnnotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 繪製照片
    _drawImage(canvas, size);
    
    // 繪製已完成的標註
    for (final annotation in annotations) {
      _drawAnnotation(canvas, size, annotation);
    }
    
    // 繪製當前正在繪製的標註
    if (currentAnnotation != null) {
      _drawAnnotation(canvas, size, currentAnnotation!);
    }
  }

  /// 繪製照片
  void _drawImage(Canvas canvas, Size size) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    
    // 計算縮放以填滿畫布
    final scale = size.width / imageSize.width;
    
    canvas.save();
    canvas.scale(scale);
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.restore();
  }

  /// 繪製標註
  void _drawAnnotation(Canvas canvas, Size size, Annotation annotation) {
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final scale = size.width / imageSize.width;
    
    canvas.save();
    canvas.scale(scale);
    
    if (annotation is CircleAnnotation) {
      _drawCircle(canvas, annotation);
    } else if (annotation is ArrowAnnotation) {
      _drawArrow(canvas, annotation);
    } else if (annotation is TextAnnotation) {
      _drawText(canvas, annotation);
    }
    
    canvas.restore();
  }

  /// 繪製圓圈
  void _drawCircle(Canvas canvas, CircleAnnotation circle) {
    final paint = Paint()
      ..color = circle.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawCircle(circle.center, circle.radius, paint);
  }

  /// 繪製箭頭
  void _drawArrow(Canvas canvas, ArrowAnnotation arrow) {
    final paint = Paint()
      ..color = arrow.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    
    // 繪製線條
    canvas.drawLine(arrow.start, arrow.end, paint);
    
    // 繪製箭頭
    const arrowSize = 20.0;
    final angle = (arrow.end - arrow.start).direction;
    
    final arrowPath = Path();
    arrowPath.moveTo(arrow.end.dx, arrow.end.dy);
    arrowPath.lineTo(
      arrow.end.dx - arrowSize * 0.866 * (angle + 0.5).cos(),
      arrow.end.dy - arrowSize * 0.866 * (angle + 0.5).sin(),
    );
    arrowPath.moveTo(arrow.end.dx, arrow.end.dy);
    arrowPath.lineTo(
      arrow.end.dx - arrowSize * 0.866 * (angle - 0.5).cos(),
      arrow.end.dy - arrowSize * 0.866 * (angle - 0.5).sin(),
    );
    
    canvas.drawPath(arrowPath, paint);
  }

  /// 繪製文字
  void _drawText(Canvas canvas, TextAnnotation textAnnotation) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: textAnnotation.text,
        style: TextStyle(
          color: textAnnotation.color,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, textAnnotation.position);
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
           oldDelegate.currentAnnotation != currentAnnotation;
  }
}

/// Offset 擴展（計算方向）
extension OffsetExtension on Offset {
  double get direction => dy.atan2(dx);
}

/// double 擴展（三角函數）
extension DoubleExtension on double {
  double cos() => this * 57.2958; // 弧度轉角度
  double sin() => this * 57.2958;
  double atan2(double x) => this / x;
}

