import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';

/// Session Note 查詢管理器（子模組）
/// 
/// 職責：處理所有與筆記查詢相關的邏輯
class SessionNoteQueryManager {
  final SupabaseClient _supabase;

  SessionNoteQueryManager(this._supabase);

  /// 取得教練的所有筆記（依學員篩選）
  Future<List<SessionNoteModel>> getCoachNotes({
    required String coachId,
    String? clientId,
    int limit = 20,
    String? lastNoteId,
  }) async {
    var query = _supabase
        .from('session_notes')
        .select('*')
        .eq('coach_id', coachId);

    // 依學員篩選
    if (clientId != null) {
      query = query.eq('client_id', clientId);
    }

    // Cursor-based 分頁
    if (lastNoteId != null) {
      final lastNote = await _supabase
          .from('session_notes')
          .select('created_at')
          .eq('id', lastNoteId)
          .single();

      query = query.lt('created_at', lastNote['created_at']);
    }

    final response = await query.order('created_at', ascending: false).limit(limit);
    return (response as List)
        .map((json) => SessionNoteModel.fromSupabase(json))
        .toList();
  }

  /// 取得學員可見的筆記（僅 shared）
  Future<List<SessionNoteModel>> getClientNotes({
    required String clientId,
    int limit = 20,
    String? lastNoteId,
  }) async {
    var query = _supabase
        .from('session_notes')
        .select('*')
        .eq('client_id', clientId)
        .eq('visibility', 'shared');

    // Cursor-based 分頁
    if (lastNoteId != null) {
      final lastNote = await _supabase
          .from('session_notes')
          .select('created_at')
          .eq('id', lastNoteId)
          .single();

      query = query.lt('created_at', lastNote['created_at']);
    }

    final response = await query.order('created_at', ascending: false).limit(limit);
    return (response as List)
        .map((json) => SessionNoteModel.fromSupabase(json))
        .toList();
  }

  /// 取得單筆筆記
  Future<SessionNoteModel?> getNoteById(String noteId) async {
    final response = await _supabase
        .from('session_notes')
        .select('*')
        .eq('id', noteId)
        .maybeSingle();

    if (response == null) return null;
    return SessionNoteModel.fromSupabase(response);
  }

  /// 取得與預約關聯的筆記
  Future<List<SessionNoteModel>> getNotesByAppointment({
    required String appointmentId,
  }) async {
    final response = await _supabase
        .from('session_notes')
        .select('*')
        .eq('appointment_id', appointmentId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => SessionNoteModel.fromSupabase(json))
        .toList();
  }

  /// 取得與訓練記錄關聯的筆記
  Future<List<SessionNoteModel>> getNotesByWorkoutLog({
    required String workoutLogId,
  }) async {
    final response = await _supabase
        .from('session_notes')
        .select('*')
        .eq('workout_log_id', workoutLogId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => SessionNoteModel.fromSupabase(json))
        .toList();
  }

  /// 搜尋筆記（依標籤或關鍵字）
  Future<List<SessionNoteModel>> searchNotes({
    required String coachId,
    String? keyword,
    List<String>? tags,
    int limit = 20,
  }) async {
    var query = _supabase
        .from('session_notes')
        .select('*')
        .eq('coach_id', coachId);

    // 搜尋標籤（使用 JSONB 查詢）
    if (tags != null && tags.isNotEmpty) {
      // 使用 PostgreSQL JSONB 包含運算子 @>
      // content->'quick_tags' 應包含指定標籤
      for (final tag in tags) {
        query = query.contains('content', {'quick_tags': [tag]});
      }
    }

    final response = await query.order('created_at', ascending: false).limit(limit);

    var notes = (response as List)
        .map((json) => SessionNoteModel.fromSupabase(json))
        .toList();

    // 關鍵字篩選（在應用層過濾）
    if (keyword != null && keyword.isNotEmpty) {
      notes = notes.where((note) {
        // 搜尋 SOAP 內容
        final soap = note.soap;
        if (soap != null) {
          final subjective = soap.subjective?.toLowerCase() ?? '';
          final objective = soap.objective?.toLowerCase() ?? '';
          final assessment = soap.assessment?.toLowerCase() ?? '';
          final plan = soap.plan?.toLowerCase() ?? '';

          final keywordLower = keyword.toLowerCase();
          return subjective.contains(keywordLower) ||
              objective.contains(keywordLower) ||
              assessment.contains(keywordLower) ||
              plan.contains(keywordLower);
        }
        return false;
      }).toList();
    }

    return notes;
  }

  /// 取得教練的筆記統計
  Future<Map<String, int>> getCoachNoteStats({
    required String coachId,
    String? clientId,
  }) async {
    var query = _supabase
        .from('session_notes')
        .select('id, visibility')
        .eq('coach_id', coachId);

    if (clientId != null) {
      query = query.eq('client_id', clientId);
    }

    final response = await query;
    final notes = response as List;

    final total = notes.length;
    final shared = notes.where((n) => n['visibility'] == 'shared').length;
    final private = total - shared;

    return {
      'total': total,
      'shared': shared,
      'private': private,
    };
  }

  /// 取得學員的筆記統計
  Future<Map<String, int>> getClientNoteStats({
    required String clientId,
  }) async {
    // 學員可見的筆記（shared）
    final sharedResponse = await _supabase
        .from('session_notes')
        .select('id')
        .eq('client_id', clientId)
        .eq('visibility', 'shared');

    final shared = (sharedResponse as List).length;

    // 總筆記數（包含 private，但學員看不到內容）
    final totalResponse = await _supabase
        .from('session_notes')
        .select('id')
        .eq('client_id', clientId);

    final total = (totalResponse as List).length;

    return {
      'total': total,
      'shared': shared,
    };
  }
}

