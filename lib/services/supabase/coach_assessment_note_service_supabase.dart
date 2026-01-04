import 'package:strengthwise/models/coach_assessment_note_model.dart';
import 'package:strengthwise/services/interfaces/i_coach_assessment_note_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// 教練評估備註服務 Supabase 實作
class CoachAssessmentNoteServiceSupabase implements ICoachAssessmentNoteService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;
  final _uuid = const Uuid();

  CoachAssessmentNoteServiceSupabase({
    required SupabaseClient supabase,
    required ErrorHandlingService errorService,
  })  : _supabase = supabase,
        _errorService = errorService;

  @override
  Future<CoachAssessmentNoteModel?> getNote({
    required String coachId,
    required String assessmentId,
  }) async {
    try {
      final response = await _supabase
          .from('coach_assessment_notes')
          .select()
          .eq('coach_id', coachId)
          .eq('assessment_id', assessmentId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return CoachAssessmentNoteModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '取得教練備註失敗: $e',
        type: 'CoachAssessmentNoteServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<CoachAssessmentNoteModel> upsertNote({
    required String coachId,
    required String assessmentId,
    required String notes,
  }) async {
    try {
      // ⚡ 使用 upsert 一次查詢完成（利用 unique_coach_assessment_note 約束）
      final response = await _supabase
          .from('coach_assessment_notes')
          .upsert(
            {
              'id': _uuid.v4(), // 新增時使用，更新時會被忽略
              'coach_id': coachId,
              'assessment_id': assessmentId,
              'notes': notes,
            },
            onConflict: 'coach_id,assessment_id', // 唯一約束欄位
          )
          .select()
          .single();

      return CoachAssessmentNoteModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '建立或更新教練備註失敗: $e',
        type: 'CoachAssessmentNoteServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteNote({
    required String coachId,
    required String assessmentId,
  }) async {
    try {
      await _supabase
          .from('coach_assessment_notes')
          .delete()
          .eq('coach_id', coachId)
          .eq('assessment_id', assessmentId);
    } catch (e) {
      _errorService.logError(
        '刪除教練備註失敗: $e',
        type: 'CoachAssessmentNoteServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<List<CoachAssessmentNoteModel>> getCoachNotes({
    required String coachId,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('coach_assessment_notes')
          .select()
          .eq('coach_id', coachId)
          .order('updated_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => CoachAssessmentNoteModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError(
        '取得教練備註列表失敗: $e',
        type: 'CoachAssessmentNoteServiceError',
      );
      rethrow;
    }
  }
}

