import 'package:strengthwise/models/injury_coach_note_model.dart';

/// 傷病教練備註服務介面
///
/// 功能：
/// 1. 每個教練對每筆傷病可以寫獨立備註
/// 2. 所有有教練關係的教練都可以「查看」該學員的所有傷病備註
/// 3. 每個教練只能「編輯」自己的備註
abstract class IInjuryCoachNoteService {
  /// 取得學員所有傷病的教練備註（所有教練的備註）
  ///
  /// [clientId] 學員 ID
  ///
  /// 返回：Map<傷病部位, List<備註>>
  Future<Map<String, List<InjuryCoachNoteModel>>> getNotesForClient({
    required String clientId,
  });

  /// 取得特定傷病的所有教練備註
  ///
  /// [clientId] 學員 ID
  /// [injurySite] 傷病部位
  ///
  /// 返回：該傷病的所有教練備註
  Future<List<InjuryCoachNoteModel>> getNotesForInjury({
    required String clientId,
    required String injurySite,
  });

  /// 建立或更新教練對特定傷病的備註
  ///
  /// [coachId] 教練 ID
  /// [clientId] 學員 ID
  /// [injurySite] 傷病部位
  /// [note] 備註內容
  ///
  /// 返回：建立或更新後的備註
  Future<InjuryCoachNoteModel> upsertNote({
    required String coachId,
    required String clientId,
    required String injurySite,
    required String note,
  });

  /// 刪除教練對特定傷病的備註
  ///
  /// [coachId] 教練 ID
  /// [clientId] 學員 ID
  /// [injurySite] 傷病部位
  Future<void> deleteNote({
    required String coachId,
    required String clientId,
    required String injurySite,
  });
}
