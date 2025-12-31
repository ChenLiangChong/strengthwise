/// 視覺元素基類（抽象類）
/// 
/// Phase 3: 視覺化筆記系統
/// 所有視覺元素（手繪、照片、語音、文字）的基類
abstract class VisualElementModel {
  /// 元素類型
  final String type;

  const VisualElementModel({required this.type});

  /// 從 JSON 創建實例（工廠方法）
  factory VisualElementModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    switch (type) {
      case 'drawing':
        return DrawingElementModel.fromJson(json);
      case 'photo':
        return PhotoElementModel.fromJson(json);
      case 'voice_note':
        return VoiceNoteElementModel.fromJson(json);
      case 'text':
        return TextElementModel.fromJson(json);
      default:
        throw ArgumentError('Unknown visual element type: $type');
    }
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson();
}

/// 手繪元素
class DrawingElementModel extends VisualElementModel {
  /// Storage 路徑（舊版：圖片方案，可選）
  final String? storagePath;
  
  /// 繪圖數據（新版：向量方案，可選）
  final Map<String, dynamic>? drawingData;

  /// 縮圖路徑
  final String? thumbnailPath;

  /// 使用的底圖模板
  final String? templateType;

  /// 創建時間
  final DateTime? createdAt;
  
  /// 更新時間
  final DateTime? updatedAt;

  const DrawingElementModel({
    this.storagePath,
    this.drawingData,
    this.thumbnailPath,
    this.templateType,
    this.createdAt,
    this.updatedAt,
  }) : super(type: 'drawing');

  factory DrawingElementModel.fromJson(Map<String, dynamic> json) {
    return DrawingElementModel(
      storagePath: json['storage_path'] as String?,
      drawingData: json['drawing_data'] as Map<String, dynamic>?,
      thumbnailPath: json['thumbnail_path'] as String?,
      templateType: json['template_type'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (storagePath != null) 'storage_path': storagePath,
      if (drawingData != null) 'drawing_data': drawingData,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (templateType != null) 'template_type': templateType,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  DrawingElementModel copyWith({
    String? storagePath,
    Map<String, dynamic>? drawingData,
    String? thumbnailPath,
    String? templateType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DrawingElementModel(
      storagePath: storagePath ?? this.storagePath,
      drawingData: drawingData ?? this.drawingData,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      templateType: templateType ?? this.templateType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// 是否為向量繪圖
  bool get isVectorDrawing => drawingData != null;
  
  /// 是否為圖片繪圖
  bool get isImageDrawing => storagePath != null;
}

/// 照片元素
class PhotoElementModel extends VisualElementModel {
  /// Storage 路徑
  final String storagePath;

  /// 照片說明
  final String? caption;

  const PhotoElementModel({
    required this.storagePath,
    this.caption,
  }) : super(type: 'photo');

  factory PhotoElementModel.fromJson(Map<String, dynamic> json) {
    return PhotoElementModel(
      storagePath: json['storage_path'] as String,
      caption: json['caption'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'storage_path': storagePath,
      if (caption != null) 'caption': caption,
    };
  }

  PhotoElementModel copyWith({
    String? storagePath,
    String? caption,
  }) {
    return PhotoElementModel(
      storagePath: storagePath ?? this.storagePath,
      caption: caption ?? this.caption,
    );
  }
}

/// 語音筆記元素
class VoiceNoteElementModel extends VisualElementModel {
  /// Storage 路徑
  final String storagePath;

  /// 時長（秒）
  final int? durationSeconds;

  /// 轉錄文字
  final String? transcription;

  /// 轉錄信心度（0.0 - 1.0）
  final double? transcriptionConfidence;

  const VoiceNoteElementModel({
    required this.storagePath,
    this.durationSeconds,
    this.transcription,
    this.transcriptionConfidence,
  }) : super(type: 'voice_note');

  factory VoiceNoteElementModel.fromJson(Map<String, dynamic> json) {
    return VoiceNoteElementModel(
      storagePath: json['storage_path'] as String,
      durationSeconds: json['duration_seconds'] as int?,
      transcription: json['transcription'] as String?,
      transcriptionConfidence:
          (json['transcription_confidence'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'storage_path': storagePath,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (transcription != null) 'transcription': transcription,
      if (transcriptionConfidence != null)
        'transcription_confidence': transcriptionConfidence,
    };
  }

  VoiceNoteElementModel copyWith({
    String? storagePath,
    int? durationSeconds,
    String? transcription,
    double? transcriptionConfidence,
  }) {
    return VoiceNoteElementModel(
      storagePath: storagePath ?? this.storagePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      transcription: transcription ?? this.transcription,
      transcriptionConfidence:
          transcriptionConfidence ?? this.transcriptionConfidence,
    );
  }
}

/// 文字元素
class TextElementModel extends VisualElementModel {
  /// 文字內容
  final String value;

  const TextElementModel({
    required this.value,
  }) : super(type: 'text');

  factory TextElementModel.fromJson(Map<String, dynamic> json) {
    return TextElementModel(
      value: json['value'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
    };
  }

  TextElementModel copyWith({
    String? value,
  }) {
    return TextElementModel(
      value: value ?? this.value,
    );
  }
}

