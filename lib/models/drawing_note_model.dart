import 'package:flutter/material.dart';
import 'package:strengthwise/utils/datetime_utils.dart';  // ⭐ 新增

/// 繪圖筆記模型
class DrawingNoteModel {
  final String id;
  final String sessionNoteId;
  final String templateType; // 'note1', 'note2', 'note3', 'note4'
  final List<DrawingLayer> layers;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  /// 畫布尺寸（用於跨設備座標縮放）
  final double canvasWidth;
  final double canvasHeight;

  const DrawingNoteModel({
    required this.id,
    required this.sessionNoteId,
    required this.templateType,
    required this.layers,
    required this.createdAt,
    required this.updatedAt,
    this.canvasWidth = 800.0, // 預設畫布寬度
    this.canvasHeight = 600.0, // 預設畫布高度
  });

  /// 從 JSONB 解析
  factory DrawingNoteModel.fromJson(Map<String, dynamic> json) {
    return DrawingNoteModel(
      id: json['id'] as String,
      sessionNoteId: json['session_note_id'] as String,
      templateType: json['template_type'] as String,
      layers: (json['layers'] as List<dynamic>?)
              ?.map((l) => DrawingLayer.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTimeUtils.parseIsoTimestamp(json['created_at'] as String),  // ⭐ 統一工具類
      updatedAt: DateTimeUtils.parseIsoTimestamp(json['updated_at'] as String),  // ⭐ 統一工具類
      canvasWidth: (json['canvas_width'] as num?)?.toDouble() ?? 800.0,
      canvasHeight: (json['canvas_height'] as num?)?.toDouble() ?? 600.0,
    );
  }

  /// 轉換為 JSONB
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_note_id': sessionNoteId,
      'template_type': templateType,
      'layers': layers.map((l) => l.toJson()).toList(),
      'created_at': DateTimeUtils.formatToUtcIso(createdAt),
      'updated_at': DateTimeUtils.formatToUtcIso(updatedAt),
      'canvas_width': canvasWidth,
      'canvas_height': canvasHeight,
    };
  }

  DrawingNoteModel copyWith({
    String? id,
    String? sessionNoteId,
    String? templateType,
    List<DrawingLayer>? layers,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? canvasWidth,
    double? canvasHeight,
  }) {
    return DrawingNoteModel(
      id: id ?? this.id,
      sessionNoteId: sessionNoteId ?? this.sessionNoteId,
      templateType: templateType ?? this.templateType,
      layers: layers ?? this.layers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
    );
  }
}

/// 繪圖圖層（底圖層不可編輯，繪圖層可編輯）
class DrawingLayer {
  final String id;
  final String name;
  final bool isVisible;
  final bool isLocked; // 底圖層鎖定，防止擦除
  final List<DrawingStroke> strokes;

  const DrawingLayer({
    required this.id,
    required this.name,
    required this.isVisible,
    required this.isLocked,
    required this.strokes,
  });

  factory DrawingLayer.fromJson(Map<String, dynamic> json) {
    return DrawingLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      isVisible: json['is_visible'] as bool? ?? true,
      isLocked: json['is_locked'] as bool? ?? false,
      strokes: (json['strokes'] as List<dynamic>?)
              ?.map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_visible': isVisible,
      'is_locked': isLocked,
      'strokes': strokes.map((s) => s.toJson()).toList(),
    };
  }

  DrawingLayer copyWith({
    String? id,
    String? name,
    bool? isVisible,
    bool? isLocked,
    List<DrawingStroke>? strokes,
  }) {
    return DrawingLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      strokes: strokes ?? this.strokes,
    );
  }
}

/// 繪圖筆劃（單次繪製的路徑）
class DrawingStroke {
  final String id;
  final List<DrawingPoint> points;
  final Color color;
  final double strokeWidth;
  final double opacity;
  final DrawingTool tool;

  const DrawingStroke({
    required this.id,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.opacity,
    required this.tool,
  });

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      id: json['id'] as String,
      points: (json['points'] as List<dynamic>)
          .map((p) => DrawingPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      color: Color(json['color'] as int),
      strokeWidth: (json['stroke_width'] as num).toDouble(),
      opacity: (json['opacity'] as num).toDouble(),
      tool: DrawingTool.values
          .firstWhere((t) => t.toString() == json['tool'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((p) => p.toJson()).toList(),
      'color': color.value,
      'stroke_width': strokeWidth,
      'opacity': opacity,
      'tool': tool.toString(),
    };
  }
}

/// 繪圖點（路徑上的點）
class DrawingPoint {
  final double x;
  final double y;
  final double pressure; // 壓感（未來支援）

  const DrawingPoint({
    required this.x,
    required this.y,
    this.pressure = 1.0,
  });

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      pressure: (json['pressure'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'pressure': pressure,
    };
  }

  Offset toOffset() => Offset(x, y);
}

/// 繪圖工具類型
enum DrawingTool {
  pencil, // 鉛筆
  marker, // 麥克筆
  highlighter, // 螢光筆
  eraser, // 橡皮擦
}

/// 底圖模板類型
enum TemplateType {
  note1, // 三視圖
  note2, // 前視圖
  note3, // 側視圖
  note4, // 背視圖
}

extension TemplateTypeExtension on TemplateType {
  String get assetPath {
    switch (this) {
      case TemplateType.note1:
        return 'assets/templates/note1.png';
      case TemplateType.note2:
        return 'assets/templates/note2.png';
      case TemplateType.note3:
        return 'assets/templates/note3.png';
      case TemplateType.note4:
        return 'assets/templates/note4.png';
    }
  }

  String get displayName {
    switch (this) {
      case TemplateType.note1:
        return '三視圖（前/側/背）';
      case TemplateType.note2:
        return '前視圖';
      case TemplateType.note3:
        return '側視圖';
      case TemplateType.note4:
        return '背視圖';
    }
  }
}

