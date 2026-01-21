import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';

/// Session Note 查詢管理器（子模組）
///
/// 職責：處理所有與筆記查詢相關的邏輯
class SessionNoteQueryManager {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;

  SessionNoteQueryManager(this._supabase, this._errorService);

  /// 取得教練的所有筆記（依學員篩選）
  Future<List<SessionNoteModel>> getCoachNotes({
    required String coachId,
    String? clientId,
    String? clientName, // ⭐ 新增：用於查詢已刪除學員的筆記
    int limit = 20,
    String? lastNoteId,
  }) async {
    try {
      var query = _supabase
          .from('session_notes')
          .select('*')
          .eq('coach_id', coachId)
          .eq('hidden_by_coach', false); // ⭐ 過濾教練已隱藏的筆記

      // 依學員篩選
      if (clientId != null) {
        // ⭐ 正常學員：使用 client_id 查詢
        query = query.eq('client_id', clientId);
      } else if (clientName != null) {
        // ⭐ 已刪除的學員：使用 client_name 查詢 + client_id IS NULL
        query = query.eq('client_name', clientName).isFilter('client_id', null);
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

      final response =
          await query.order('created_at', ascending: false).limit(limit);
      return (response as List)
          .map((json) => SessionNoteModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError(
        '查詢教練筆記失敗: $e',
        type: 'SessionNoteServiceError',
      );
      rethrow;
    }
  }

  /// 取得學員可見的筆記（僅 shared，排除已隱藏）
  Future<List<SessionNoteModel>> getClientNotes({
    required String clientId,
    String? coachId, // ⭐ 新增：用於教練篩選
    String? coachName, // ⭐ 新增：用於查詢已刪除教練的筆記
    int limit = 20,
    String? lastNoteId,
  }) async {
    try {
      var query = _supabase
          .from('session_notes')
          .select('*')
          .eq('client_id', clientId)
          .eq('visibility', 'shared')
          .eq('hidden_by_client', false); // ⭐ 過濾已隱藏的筆記

      // ⭐ 依教練篩選
      if (coachId != null) {
        // 正常教練：使用 coach_id 查詢
        query = query.eq('coach_id', coachId);
      } else if (coachName != null) {
        // 已刪除的教練：使用 coach_name 查詢 + coach_id IS NULL
        query = query.eq('coach_name', coachName).isFilter('coach_id', null);
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

      final response =
          await query.order('created_at', ascending: false).limit(limit);
      return (response as List)
          .map((json) => SessionNoteModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError(
        '查詢學員筆記失敗: $e',
        type: 'SessionNoteServiceError',
      );
      rethrow;
    }
  }

  /// 取得單筆筆記
  Future<SessionNoteModel?> getNoteById(String noteId) async {
    try {
      final response = await _supabase
          .from('session_notes')
          .select('*')
          .eq('id', noteId)
          .maybeSingle();

      if (response == null) return null;
      return SessionNoteModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '查詢筆記詳情失敗: $e',
        type: 'SessionNoteServiceError',
      );
      rethrow;
    }
  }

  /// 取得與預約關聯的筆記
  Future<List<SessionNoteModel>> getNotesByAppointment({
    required String appointmentId,
  }) async {
    try {
      final response = await _supabase
          .from('session_notes')
          .select('*')
          .eq('appointment_id', appointmentId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SessionNoteModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError(
        '查詢預約關聯筆記失敗: $e',
        type: 'SessionNoteServiceError',
      );
      rethrow;
    }
  }

  /// 取得與訓練記錄關聯的筆記
  Future<List<SessionNoteModel>> getNotesByWorkoutLog({
    required String workoutLogId,
  }) async {
    try {
      final response = await _supabase
          .from('session_notes')
          .select('*')
          .eq('workout_log_id', workoutLogId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SessionNoteModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError(
        '查詢訓練記錄關聯筆記失敗: $e',
        type: 'SessionNoteServiceError',
      );
      rethrow;
    }
  }

  /// 搜尋筆記（依標籤或關鍵字）
  Future<List<SessionNoteModel>> searchNotes({
    required String coachId,
    String? keyword,
    List<String>? tags,
    int limit = 20,
  }) async {
    try {
      var query =
          _supabase.from('session_notes').select('*').eq('coach_id', coachId);

      // 搜尋標籤（使用 JSONB 查詢）
      if (tags != null && tags.isNotEmpty) {
        // 使用 PostgreSQL JSONB 包含運算子 @>
        // content->'quick_tags' 應包含指定標籤
        for (final tag in tags) {
          query = query.contains('content', {
            'quick_tags': [tag]
          });
        }
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

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
    } catch (e) {
      _errorService.logError(
        '搜尋筆記失敗: $e',
        type: 'SessionNoteServiceError',
      );
      rethrow;
    }
  }

  /// 取得教練的筆記統計
  Future<Map<String, int>> getCoachNoteStats({
    required String coachId,
    String? clientId,
  }) async {
    try {
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
    } catch (e) {
      _errorService.logError(
        '查詢教練筆記統計失敗: $e',
        type: 'SessionNoteServiceError',
      );
      rethrow;
    }
  }

  /// 取得學員的筆記統計
  Future<Map<String, int>> getClientNoteStats({
    required String clientId,
  }) async {
    try {
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
    } catch (e) {
      _errorService.logError(
        '查詢學員筆記統計失敗: $e',
        type: 'SessionNoteServiceError',
      );
      rethrow;
    }
  }
}
