import '../../models/note_model.dart';

/// 筆記服務接口
/// 
/// 定義與筆記相關的所有操作，
/// 提供標準接口以支持不同的實現方式。
abstract class INoteService {
  /// 獲取用戶的所有筆記
  Future<List<Note>> getUserNotes();
  
  /// 獲取特定筆記
  Future<Note?> getNoteById(String noteId);
  
  /// 創建新筆記
  Future<Note> createNote(String title, String textContent, List<DrawingPoint>? drawingPoints);
  
  /// 更新筆記
  Future<bool> updateNote(Note note);
  
  /// 刪除筆記
  Future<bool> deleteNote(String noteId);
} 