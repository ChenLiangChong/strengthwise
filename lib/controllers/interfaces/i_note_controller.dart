import '../../models/note_model.dart';

/// 筆記控制器接口
/// 
/// 定義與筆記相關的業務邏輯操作。
abstract class INoteController {
  /// 載入用戶筆記
  Future<List<Note>> loadUserNotes();
  
  /// 獲取特定筆記
  Future<Note?> getNoteById(String noteId);
  
  /// 創建新筆記
  Future<Note> createNote(String title, String textContent, List<DrawingPoint>? drawingPoints);
  
  /// 更新筆記
  Future<bool> updateNote(Note note);
  
  /// 刪除筆記
  Future<bool> deleteNote(String noteId);
} 