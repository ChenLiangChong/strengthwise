import 'package:flutter/foundation.dart';
import 'package:strengthwise/models/injury_coach_note_model.dart';
import 'package:strengthwise/services/interfaces/i_injury_coach_note_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// 傷病教練備註服務 Supabase 實作

/// ⭐ 定義 injury_coach_notes 表的標準查詢欄位
const String _kInjuryNoteSelectFields = '''
  id, coach_id, client_id, injury_site, note, created_at, updated_at
''';

class InjuryCoachNoteServiceSupabase implements IInjuryCoachNoteService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;
  final _uuid = const Uuid();

  InjuryCoachNoteServiceSupabase({
    required SupabaseClient supabase,
    required ErrorHandlingService errorService,
  })  : _supabase = supabase,
        _errorService = errorService;

  @override
  Future<Map<String, List<InjuryCoachNoteModel>>> getNotesForClient({
    required String clientId,
  }) async {
    debugPrint('[InjuryCoachNoteService] getNotesForClient: clientId=$clientId');
    debugPrint('[InjuryCoachNoteService] 當前用戶: ${_supabase.auth.currentUser?.id}');
    
    try {
      final response = await _supabase
          .from('injury_coach_notes')
          .select(_kInjuryNoteSelectFields)
          .eq('client_id', clientId)
          .order('injury_site')
          .order('updated_at', ascending: false);

      debugPrint('[InjuryCoachNoteService] 查詢結果: ${(response as List).length} 筆');

      final notes = (response as List)
          .map((json) => InjuryCoachNoteModel.fromSupabase(json))
          .toList();

      // 按 injury_site 分組
      final grouped = <String, List<InjuryCoachNoteModel>>{};
      for (final note in notes) {
        grouped.putIfAbsent(note.injurySite, () => []).add(note);
      }

      return grouped;
    } catch (e) {
      debugPrint('[InjuryCoachNoteService] 查詢失敗: $e');
      _errorService.logError(
        '取得學員傷病備註失敗: $e',
        type: 'InjuryCoachNoteServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<List<InjuryCoachNoteModel>> getNotesForInjury({
    required String clientId,
    required String injurySite,
  }) async {
    try {
      final response = await _supabase
          .from('injury_coach_notes')
          .select(_kInjuryNoteSelectFields)
          .eq('client_id', clientId)
          .eq('injury_site', injurySite)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => InjuryCoachNoteModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError(
        '取得傷病備註失敗: $e',
        type: 'InjuryCoachNoteServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<InjuryCoachNoteModel> upsertNote({
    required String coachId,
    required String clientId,
    required String injurySite,
    required String note,
  }) async {
    try {
      // ⚡ 使用 upsert 一次查詢完成（利用 unique(coach_id, client_id, injury_site) 約束）
      final response = await _supabase
          .from('injury_coach_notes')
          .upsert(
            {
              'id': _uuid.v4(), // 新增時使用，更新時會被忽略
              'coach_id': coachId,
              'client_id': clientId,
              'injury_site': injurySite,
              'note': note,
            },
            onConflict: 'coach_id,client_id,injury_site', // 唯一約束欄位
          )
          .select(_kInjuryNoteSelectFields)
          .single();

      return InjuryCoachNoteModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '建立或更新傷病備註失敗: $e',
        type: 'InjuryCoachNoteServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteNote({
    required String coachId,
    required String clientId,
    required String injurySite,
  }) async {
    try {
      await _supabase
          .from('injury_coach_notes')
          .delete()
          .eq('coach_id', coachId)
          .eq('client_id', clientId)
          .eq('injury_site', injurySite);
    } catch (e) {
      _errorService.logError(
        '刪除傷病備註失敗: $e',
        type: 'InjuryCoachNoteServiceError',
      );
      rethrow;
    }
  }
}
