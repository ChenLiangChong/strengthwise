import 'drawing_point.dart';
import 'note_mapper.dart';

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
    return NoteMapper.toMap(this);
  }

  /// 從 Map 創建對象
  factory Note.fromMap(Map<String, dynamic> map) {
    return NoteMapper.fromMap(map);
  }

  /// 轉換為 JSON 字符串
  String toJson() => NoteMapper.toJson(this);
  
  /// 從 JSON 字符串創建對象
  factory Note.fromJson(String source) => NoteMapper.fromJson(source);
  
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

