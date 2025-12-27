import 'package:flutter/material.dart';
import '../../models/statistics_model.dart';

/// 迷你曲線圖組件
/// 
/// 用於在卡片中顯示簡化的力量進步曲線
class MiniLineChart extends StatelessWidget {
  final List<StrengthProgressPoint> dataPoints;
  final double width;
  final double height;
  final Color lineColor;
  final Color fillColor;

  const MiniLineChart({
    Key? key,
    required this.dataPoints,
    this.width = 120,
    this.height = 40,
    required this.lineColor,
    required this.fillColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    // 取最近的 10 個數據點
    final recentPoints = dataPoints.length > 10 
        ? dataPoints.sublist(dataPoints.length - 10) 
        : dataPoints;

    // 找出最大和最小值用於標準化
    double minWeight = recentPoints.first.weight;
    double maxWeight = recentPoints.first.weight;
    
    for (var point in recentPoints) {
      if (point.weight < minWeight) minWeight = point.weight;
      if (point.weight > maxWeight) maxWeight = point.weight;
    }

    // 避免除以零
    final range = maxWeight - minWeight;
    if (range == 0) {
      // 如果所有數據點相同，繪製一條直線
      return CustomPaint(
        size: Size(width, height),
        painter: _FlatLinePainter(
          color: lineColor,
        ),
      );
    }

    return CustomPaint(
      size: Size(width, height),
      painter: _MiniLineChartPainter(
        dataPoints: recentPoints,
        minWeight: minWeight,
        maxWeight: maxWeight,
        lineColor: lineColor,
        fillColor: fillColor,
      ),
    );
  }
}

/// 曲線圖繪製器
class _MiniLineChartPainter extends CustomPainter {
  final List<StrengthProgressPoint> dataPoints;
  final double minWeight;
  final double maxWeight;
  final Color lineColor;
  final Color fillColor;

  _MiniLineChartPainter({
    required this.dataPoints,
    required this.minWeight,
    required this.maxWeight,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final range = maxWeight - minWeight;
    final stepX = size.width / (dataPoints.length - 1).clamp(1, double.infinity);

    // 建立路徑
    final path = Path();
    final fillPath = Path();
    
    // 第一個點
    final firstY = size.height - ((dataPoints.first.weight - minWeight) / range * size.height);
    path.moveTo(0, firstY);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, firstY);

    // 中間點
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final y = size.height - ((dataPoints[i].weight - minWeight) / range * size.height);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    // 完成填充區域
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // 繪製填充區域
    final fillPaint = Paint()
      ..color = fillColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 繪製曲線
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // 繪製數據點
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final y = size.height - ((dataPoints[i].weight - minWeight) / range * size.height);
      canvas.drawCircle(Offset(x, y), 2.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 平線繪製器（當所有數據點相同時使用）
class _FlatLinePainter extends CustomPainter {
  final Color color;

  _FlatLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 繪製一條水平線在中間
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

