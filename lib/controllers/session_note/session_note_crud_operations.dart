import '../../services/interfaces/i_session_note_service.dart';
import '../../models/session_note/session_note_model.dart';
import 'session_note_state_manager.dart';

/// SessionNoteCrudOperations - 筆記 CRUD 操作管理器
/// 
/// 負責筆記的創建、更新、刪除等操作
class SessionNoteCrudOperations {
  final ISessionNoteService _service;
  final SessionNoteStateManager _state;
  
  SessionNoteCrudOperations(this._service, this._state);
  
  // ==================== 創建筆記 ====================
  
  /// 創建新筆記
  Future<SessionNoteModel> createNote(SessionNoteModel note) async {
    final createdNote = await _service.createNote(note);
    
    // 新增到列表頂部（最新的在前面）
    _state.addNote(createdNote);
    
    return createdNote;
  }
  
  // ==================== 更新筆記 ====================
  
  /// 更新筆記內容
  Future<SessionNoteModel> updateNote(SessionNoteModel note) async {
    final updatedNote = await _service.updateNote(note);
    
    // 更新列表中的筆記
    _state.updateNote(updatedNote);
    
    return updatedNote;
  }
  
  /// 切換筆記可見性（private <-> shared）
  Future<SessionNoteModel> toggleVisibility(String noteId) async {
    final updatedNote = await _service.toggleVisibility(noteId);
    
    // 更新列表中的筆記（會自動更新統計）
    _state.updateNote(updatedNote);
    
    return updatedNote;
  }
  
  // ==================== 刪除筆記 ====================
  
  /// 刪除筆記
  Future<void> deleteNote(String noteId) async {
    await _service.deleteNote(noteId);
    
    // 從列表中移除
    _state.removeNote(noteId);
  }
  
  // ==================== 批次操作 ====================
  
  /// 批次分享筆記
  Future<List<SessionNoteModel>> batchShare(List<String> noteIds) async {
    final updatedNotes = <SessionNoteModel>[];
    
    for (final noteId in noteIds) {
      try {
        final updatedNote = await _service.toggleVisibility(noteId);
        _state.updateNote(updatedNote);
        updatedNotes.add(updatedNote);
      } catch (e) {
        // 單筆失敗不影響其他筆記
        continue;
      }
    }
    
    return updatedNotes;
  }
  
  /// 批次刪除筆記
  Future<void> batchDelete(List<String> noteIds) async {
    for (final noteId in noteIds) {
      try {
        await _service.deleteNote(noteId);
        _state.removeNote(noteId);
      } catch (e) {
        // 單筆失敗不影響其他筆記
        continue;
      }
    }
  }
}

