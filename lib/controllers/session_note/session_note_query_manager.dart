import '../../services/interfaces/i_session_note_service.dart';
import '../../models/session_note/session_note_model.dart';
import 'session_note_state_manager.dart';

/// SessionNoteQueryManager - 筆記查詢管理器
/// 
/// 負責所有查詢相關的操作（教練筆記、學員筆記、搜尋等）
class SessionNoteQueryManager {
  final ISessionNoteService _service;
  final SessionNoteStateManager _state;
  
  SessionNoteQueryManager(this._service, this._state);
  
  // ==================== 教練端查詢 ====================
  
  /// 載入教練的所有筆記
  Future<void> loadCoachNotes({
    required String coachId,
    String? clientId,
    int limit = 20,
    String? lastNoteId,
    bool append = false,
  }) async {
    final notes = await _service.getCoachNotes(
      coachId: coachId,
      clientId: clientId,
      limit: limit,
      lastNoteId: lastNoteId,
    );
    
    if (append) {
      final existingNotes = List<SessionNoteModel>.from(_state.notes);
      existingNotes.addAll(notes);
      _state.setNotes(existingNotes);
    } else {
      _state.setNotes(notes);
    }
  }
  
  /// 載入教練的筆記統計
  Future<void> loadCoachStats({
    required String coachId,
    String? clientId,
  }) async {
    final stats = await _service.getCoachNoteStats(
      coachId: coachId,
      clientId: clientId,
    );
    
    _state.updateStats(
      total: stats['total'] ?? 0,
      shared: stats['shared'] ?? 0,
      private: stats['private'] ?? 0,
    );
  }
  
  // ==================== 學員端查詢 ====================
  
  /// 載入學員可見的筆記（僅 shared）
  Future<void> loadClientNotes({
    required String clientId,
    int limit = 20,
    String? lastNoteId,
    bool append = false,
  }) async {
    final notes = await _service.getClientNotes(
      clientId: clientId,
      limit: limit,
      lastNoteId: lastNoteId,
    );
    
    if (append) {
      final existingNotes = List<SessionNoteModel>.from(_state.notes);
      existingNotes.addAll(notes);
      _state.setNotes(existingNotes);
    } else {
      _state.setNotes(notes);
    }
  }
  
  /// 載入學員的筆記統計
  Future<void> loadClientStats({
    required String clientId,
  }) async {
    final stats = await _service.getClientNoteStats(
      clientId: clientId,
    );
    
    _state.updateStats(
      total: stats['total'] ?? 0,
      shared: stats['shared'] ?? 0,
      private: 0, // 學員只能看到 shared
    );
  }
  
  // ==================== 單筆查詢 ====================
  
  /// 載入單筆筆記詳情
  Future<SessionNoteModel?> loadNoteById(String noteId) async {
    final note = await _service.getNoteById(noteId);
    
    if (note != null) {
      _state.setSelectedNote(note);
    }
    
    return note;
  }
  
  // ==================== 關聯查詢 ====================
  
  /// 載入與預約關聯的筆記
  Future<void> loadNotesByAppointment({
    required String appointmentId,
  }) async {
    final notes = await _service.getNotesByAppointment(
      appointmentId: appointmentId,
    );
    
    _state.setNotes(notes);
  }
  
  /// 載入與訓練記錄關聯的筆記
  Future<void> loadNotesByWorkoutLog({
    required String workoutLogId,
  }) async {
    final notes = await _service.getNotesByWorkoutLog(
      workoutLogId: workoutLogId,
    );
    
    _state.setNotes(notes);
  }
  
  // ==================== 搜尋功能 ====================
  
  /// 搜尋筆記（依標籤或關鍵字）
  Future<void> searchNotes({
    required String coachId,
    String? keyword,
    List<String>? tags,
    int limit = 20,
  }) async {
    final notes = await _service.searchNotes(
      coachId: coachId,
      keyword: keyword,
      tags: tags,
      limit: limit,
    );
    
    _state.setNotes(notes);
  }
}

