import 'dart:convert';
import 'note.dart';
import 'drawing_point.dart';

/// 筆記數據映射器
///
/// 負責在不同數據格式（Map、JSON）之間轉換 Note
class NoteMapper {
  /// 從 Map 創建對象
  static Note fromMap(Map<String, dynamic> map) {
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

  /// 從 JSON 字符串創建對象
  static Note fromJson(String source) {
    return fromMap(json.decode(source));
  }

  /// 轉換為 Map 數據
  static Map<String, dynamic> toMap(Note note) {
    return {
      'id': note.id,
      'title': note.title,
      'textContent': note.textContent,
      'drawingPoints': note.drawingPoints?.map((point) => point.toMap()).toList(),
      'createdAt': note.createdAt.millisecondsSinceEpoch,
      'updatedAt': note.updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 轉換為 JSON 字符串
  static String toJson(Note note) {
    return json.encode(toMap(note));
  }
}

