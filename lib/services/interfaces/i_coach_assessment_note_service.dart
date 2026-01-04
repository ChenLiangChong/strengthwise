import 'package:strengthwise/models/coach_assessment_note_model.dart';

/// 教練評估備註服務介面
/// 
/// 功能：
/// 1. 教練可以對學員的健康評估寫私有備註
/// 2. 每個教練的備註獨立，互不干擾
/// 3. 學員無法查看這些備註
abstract class ICoachAssessmentNoteService {
  /// 取得教練對特定評估的備註
  /// 
  /// [coachId] 教練 ID
  /// [assessmentId] 健康評估 ID
  /// 
  /// 返回：教練的備註，如果不存在則返回 null
  Future<CoachAssessmentNoteModel?> getNote({
    required String coachId,
    required String assessmentId,
  });

  /// 建立或更新教練備註
  /// 
  /// [coachId] 教練 ID
  /// [assessmentId] 健康評估 ID
  /// [notes] 備註內容
  /// 
  /// 返回：建立或更新後的備註
  /// 
  /// 說明：
  /// - 如果備註不存在，則建立新備註
  /// - 如果備註已存在，則更新內容
  Future<CoachAssessmentNoteModel> upsertNote({
    required String coachId,
    required String assessmentId,
    required String notes,
  });

  /// 刪除教練備註
  /// 
  /// [coachId] 教練 ID
  /// [assessmentId] 健康評估 ID
  Future<void> deleteNote({
    required String coachId,
    required String assessmentId,
  });

  /// 取得教練的所有備註
  /// 
  /// [coachId] 教練 ID
  /// [limit] 最多返回筆數
  /// 
  /// 返回：教練的所有備註列表
  Future<List<CoachAssessmentNoteModel>> getCoachNotes({
    required String coachId,
    int limit = 50,
  });
}

