import 'dart:convert';
import 'package:flutter/material.dart';

/// 筆記模型
///
/// 表示用戶的筆記，可以包含文本內容和繪圖
class Note {
  final String id;
  final String title;
  final String textContent;
  final List<DrawingPoint>? drawingPoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 創建一個筆記實例
  Note({
    required this.id,
    required this.title,
    this.textContent = '',
    this.drawingPoints,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 轉換為 Map 數據
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'textContent': textContent,
      'drawingPoints': drawingPoints?.map((point) => point.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 從 Map 創建對象
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      textContent: map['textContent'] ?? '',
      drawingPoints: map['drawingPoints'] != null
          ? List<DrawingPoint>.from(
              map['drawingPoints']?.map((x) => DrawingPoint.fromMap(x)))
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  /// 轉換為 JSON 字符串
  String toJson() => json.encode(toMap());
  
  /// 從 JSON 字符串創建對象
  factory Note.fromJson(String source) => Note.fromMap(json.decode(source));
  
  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
  Note copyWith({
    String? id,
    String? title,
    String? textContent,
    List<DrawingPoint>? drawingPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      textContent: textContent ?? this.textContent,
      drawingPoints: drawingPoints ?? this.drawingPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// 更新筆記內容，返回一個新對象
  Note updateContent({
    String? title,
    String? textContent,
    List<DrawingPoint>? drawingPoints,
  }) {
    return copyWith(
      title: title,
      textContent: textContent,
      drawingPoints: drawingPoints,
      updatedAt: DateTime.now(),
    );
  }
  
  @override
  String toString() => 'Note(id: $id, title: $title)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

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
      'color': color.value,
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