import 'package:flutter/material.dart';

/// 繪圖點模型
///
/// 表示筆記繪圖中的一個點，包含位置、顏色和筆觸寬度
class DrawingPoint {
  final Offset offset;
  final Color color;
  final double strokeWidth;

  /// 創建一個繪圖點實例
  DrawingPoint({
    required this.offset, 
    required this.color,
    required this.strokeWidth,
  });

  /// 轉換為 Map 數據
  Map<String, dynamic> toMap() {
    return {
      'offsetX': offset.dx,
      'offsetY': offset.dy,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
    };
  }

  /// 從 Map 創建對象
  factory DrawingPoint.fromMap(Map<String, dynamic> map) {
    return DrawingPoint(
      offset: Offset(map['offsetX'], map['offsetY']),
      color: Color(map['color']),
      strokeWidth: map['strokeWidth'],
    );
  }
  
  /// 獲取用於繪製的 Paint 對象
  Paint get paint => Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round;
    
  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
  DrawingPoint copyWith({
    Offset? offset,
    Color? color,
    double? strokeWidth,
  }) {
    return DrawingPoint(
      offset: offset ?? this.offset,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
  
  @override
  String toString() => 'DrawingPoint(offset: $offset, color: $color, strokeWidth: $strokeWidth)';
}

