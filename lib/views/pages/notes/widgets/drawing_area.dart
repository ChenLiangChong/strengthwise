import 'package:flutter/material.dart';
import '../../../../models/note_model.dart';
import 'drawing_painter.dart';

/// 筆記繪圖區域元件
class DrawingArea extends StatelessWidget {
  final List<DrawingPoint>? drawingPoints;
  final bool isDrawing;
  final Function(Offset offset, PointerEvent event) onAddDrawingPoint;

  const DrawingArea({
    super.key,
    required this.drawingPoints,
    required this.isDrawing,
    required this.onAddDrawingPoint,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 繪圖區域
        Listener(
          onPointerDown: (event) => onAddDrawingPoint(event.localPosition, event),
          onPointerMove: (event) => onAddDrawingPoint(event.localPosition, event),
          child: CustomPaint(
            painter: DrawingPainter(drawingPoints),
            size: Size.infinite,
          ),
        ),
        
        // 顯示繪圖指示
        if (isDrawing)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '繪圖模式：使用手指在畫面上繪圖',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

