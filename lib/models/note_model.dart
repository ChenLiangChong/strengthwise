import 'dart:convert';
import 'package:flutter/material.dart';

class Note {
  final String id;
  String title;
  String textContent;
  List<DrawingPoint>? drawingPoints;
  final DateTime createdAt;
  DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    this.textContent = '',
    this.drawingPoints,
    required this.createdAt,
    required this.updatedAt,
  });

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

  String toJson() => json.encode(toMap());
  factory Note.fromJson(String source) => Note.fromMap(json.decode(source));
}

class DrawingPoint {
  final Offset offset;
  final Color color;
  final double strokeWidth;

  DrawingPoint({
    required this.offset, 
    required this.color,
    required this.strokeWidth,
  });

  Map<String, dynamic> toMap() {
    return {
      'offsetX': offset.dx,
      'offsetY': offset.dy,
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }

  factory DrawingPoint.fromMap(Map<String, dynamic> map) {
    return DrawingPoint(
      offset: Offset(map['offsetX'], map['offsetY']),
      color: Color(map['color']),
      strokeWidth: map['strokeWidth'],
    );
  }
  
  Paint get paint => Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round;
} 