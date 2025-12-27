import '../../../models/note_model.dart';

/// 筆記資料解析器
class NoteDataParser {
  /// 從 Supabase 資料解析 Note 物件
  static Note parseFromSupabase(Map<String, dynamic> data) {
    List<DrawingPoint>? drawingPoints;
    if (data['drawing_points'] != null) {
      final pointsList = data['drawing_points'] as List<dynamic>;
      drawingPoints = pointsList
          .map((point) => DrawingPoint.fromMap(point as Map<String, dynamic>))
          .toList();
    }
    
    return Note(
      id: data['id'] as String,
      title: data['title'] as String,
      textContent: data['text_content'] as String? ?? '',
      drawingPoints: drawingPoints,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }
}

