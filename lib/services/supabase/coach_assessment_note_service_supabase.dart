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
      // 檢查是否已存在
      final existing = await getNote(
        coachId: coachId,
        assessmentId: assessmentId,
      );

      if (existing != null) {
        // 更新現有備註
        final response = await _supabase
            .from('coach_assessment_notes')
            .update({
              'notes': notes,
            })
            .eq('coach_id', coachId)
            .eq('assessment_id', assessmentId)
            .select()
            .single();

        return CoachAssessmentNoteModel.fromSupabase(response);
      } else {
        // 建立新備註
        final response = await _supabase
            .from('coach_assessment_notes')
            .insert({
              'id': _uuid.v4(),
              'coach_id': coachId,
              'assessment_id': assessmentId,
              'notes': notes,
            })
            .select()
            .single();

        return CoachAssessmentNoteModel.fromSupabase(response);
      }
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

