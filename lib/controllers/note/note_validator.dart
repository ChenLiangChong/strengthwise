import '../../models/note_model.dart';

/// 筆記驗證器
class NoteValidator {
  /// 驗證筆記標題
  static void validateTitle(String title) {
    if (title.trim().isEmpty) {
      throw ArgumentError('筆記標題不能為空');
    }
  }

  /// 驗證筆記創建參數
  static void validateCreateParams(String title) {
    validateTitle(title);
  }

  /// 驗證筆記更新參數
  static void validateUpdateParams(Note note) {
    validateTitle(note.title);
  }
}

