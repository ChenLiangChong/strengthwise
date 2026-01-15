import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Canvas 向量繪圖工具類
/// 
/// 職責：
/// 1. 向量路徑 → Canvas 渲染
/// 2. Canvas → PNG Bytes
/// 3. 向量資料結構定義
class CanvasUtils {
  /// 將向量路徑渲染為 PNG 圖片
  /// 
  /// [annotations] JSONB 向量資料
  /// [backgroundImage] 底圖（可選）
  /// [width] 圖片寬度
  /// [height] 圖片高度
  /// 
  /// 返回 PNG Bytes
  static Future<Uint8List> renderToPng({
    required Map<String, dynamic> annotations,
    ui.Image? backgroundImage,
    double width = 800,
    double height = 1000,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 1. 繪製底圖
    if (backgroundImage != null) {
      canvas.drawImage(backgroundImage, Offset.zero, Paint());
    }

    // 2. 繪製向量元素
    _drawAnnotations(canvas, annotations);

    // 3. 轉為 PNG
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// 在 Canvas 上繪製向量標註
  static void _drawAnnotations(Canvas canvas, Map<String, dynamic> annotations) {
    // 繪製筆觸（Strokes）
    final strokes = annotations['strokes'] as List<dynamic>?;
    if (strokes != null) {
      for (final stroke in strokes) {
        _drawStroke(canvas, stroke as Map<String, dynamic>);
      }
    }

    // 繪製箭頭（Arrows）
    final arrows = annotations['arrows'] as List<dynamic>?;
    if (arrows != null) {
      for (final arrow in arrows) {
        _drawArrow(canvas, arrow as Map<String, dynamic>);
      }
    }

    // 繪製圓圈（Circles）
    final circles = annotations['circles'] as List<dynamic>?;
    if (circles != null) {
      for (final circle in circles) {
        _drawCircle(canvas, circle as Map<String, dynamic>);
      }
    }

    // 繪製文字（Texts）
    final texts = annotations['texts'] as List<dynamic>?;
    if (texts != null) {
      for (final text in texts) {
        _drawText(canvas, text as Map<String, dynamic>);
      }
    }
  }

  /// 繪製筆觸
  static void _drawStroke(Canvas canvas, Map<String, dynamic> stroke) {
    final points = stroke['points'] as List<dynamic>;
    final color = Color(int.parse(stroke['color'].toString().replaceFirst('#', '0xFF')));
    final width = (stroke['width'] as num).toDouble();

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final point = points[i] as Map<String, dynamic>;
      final x = (point['x'] as num).toDouble();
      final y = (point['y'] as num).toDouble();

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  /// 繪製箭頭
  static void _drawArrow(Canvas canvas, Map<String, dynamic> arrow) {
    final start = arrow['start'] as Map<String, dynamic>;
    final end = arrow['end'] as Map<String, dynamic>;
    final color = Color(int.parse(
      arrow['color']?.toString().replaceFirst('#', '0xFF') ?? '0xFFFF0000',
    ));
    final width = (arrow['width'] as num?)?.toDouble() ?? 3.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final startOffset = Offset(
      (start['x'] as num).toDouble(),
      (start['y'] as num).toDouble(),
    );
    final endOffset = Offset(
      (end['x'] as num).toDouble(),
      (end['y'] as num).toDouble(),
    );

    // 繪製箭頭線
    canvas.drawLine(startOffset, endOffset, paint);

    // 繪製箭頭頭部
    const arrowSize = 20.0;
    final angle = (endOffset - startOffset).direction;
    const arrowAngle = 30 * (3.14159 / 180); // 30 度轉弧度

    final arrowPoint1 = Offset(
      endOffset.dx - arrowSize * cos(angle - arrowAngle),
      endOffset.dy - arrowSize * sin(angle - arrowAngle),
    );
    final arrowPoint2 = Offset(
      endOffset.dx - arrowSize * cos(angle + arrowAngle),
      endOffset.dy - arrowSize * sin(angle + arrowAngle),
    );

    final arrowPath = Path()
      ..moveTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(endOffset.dx, endOffset.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy);

    canvas.drawPath(arrowPath, paint);
  }

  /// 繪製圓圈
  static void _drawCircle(Canvas canvas, Map<String, dynamic> circle) {
    final center = circle['center'] as Map<String, dynamic>;
    final radius = (circle['radius'] as num).toDouble();
    final color = Color(int.parse(
      circle['color']?.toString().replaceFirst('#', '0xFF') ?? '0xFFFF0000',
    ));
    final width = (circle['width'] as num?)?.toDouble() ?? 3.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    final centerOffset = Offset(
      (center['x'] as num).toDouble(),
      (center['y'] as num).toDouble(),
    );

    canvas.drawCircle(centerOffset, radius, paint);
  }

  /// 繪製文字
  static void _drawText(Canvas canvas, Map<String, dynamic> text) {
    final position = text['position'] as Map<String, dynamic>;
    final textContent = text['text'] as String;
    final color = Color(int.parse(
      text['color']?.toString().replaceFirst('#', '0xFF') ?? '0xFFFF0000',
    ));
    final fontSize = (text['fontSize'] as num?)?.toDouble() ?? 16.0;

    final textSpan = TextSpan(
      text: textContent,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.white.withOpacity(0.7),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(
      (position['x'] as num).toDouble(),
      (position['y'] as num).toDouble(),
    );

    textPainter.paint(canvas, offset);
  }

  /// 數學輔助函數
  static double cos(double radians) => math.cos(radians);
  static double sin(double radians) => math.sin(radians);
}

/// 向量資料結構範例
/// 
/// ```json
/// {
///   "strokes": [
///     {
///       "points": [{"x": 100, "y": 200}, {"x": 150, "y": 250}],
///       "color": "#FF0000",
///       "width": 5
///     }
///   ],
///   "arrows": [
///     {
///       "start": {"x": 50, "y": 50},
///       "end": {"x": 150, "y": 150},
///       "color": "#00FF00",
///       "width": 3
///     }
///   ],
///   "circles": [
///     {
///       "center": {"x": 200, "y": 100},
///       "radius": 30,
///       "color": "#0000FF",
///       "width": 3
///     }
///   ],
///   "texts": [
///     {
///       "position": {"x": 100, "y": 50},
///       "text": "膝蓋內夾",
///       "color": "#FF0000",
///       "fontSize": 16
///     }
///   ]
/// }
/// ```

