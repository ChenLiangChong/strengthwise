/// 訓練計劃數據驗證器
///
/// 負責驗證訓練模板和記錄的數據有效性
class WorkoutDataValidator {
  /// 驗證模板標題
  static void validateTemplateTitle(String title) {
    if (title.trim().isEmpty) {
      throw ArgumentError('訓練模板標題不能為空');
    }
  }
  
  /// 驗證模板運動列表
  static void validateTemplateExercises(List<dynamic> exercises) {
    if (exercises.isEmpty) {
      throw ArgumentError('訓練模板必須包含至少一個運動');
    }
  }
  
  /// 驗證完整模板數據
  static void validateTemplate({
    required String title,
    required List<dynamic> exercises,
  }) {
    validateTemplateTitle(title);
    validateTemplateExercises(exercises);
  }
}

