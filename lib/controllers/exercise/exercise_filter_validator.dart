/// 運動過濾條件驗證器
///
/// 驗證查詢條件的有效性
class ExerciseFilterValidator {
  /// 驗證分類查詢條件
  /// 
  /// level1 查詢必須指定訓練類型和身體部位
  static void validateCategoryFilters({
    required int level,
    String? selectedType,
    String? selectedBodyPart,
  }) {
    if (level == 1) {
      if (selectedType == null || selectedType.isEmpty) {
        throw ArgumentError('查詢level1時必須指定訓練類型');
      }
      if (selectedBodyPart == null || selectedBodyPart.isEmpty) {
        throw ArgumentError('查詢level1時必須指定身體部位');
      }
    }
  }
  
  /// 驗證運動查詢條件
  /// 
  /// 必須指定訓練類型和身體部位
  static void validateExerciseFilters({
    String? selectedType,
    String? selectedBodyPart,
  }) {
    if (selectedType == null || selectedType.isEmpty) {
      throw ArgumentError('訓練類型為必選項');
    }
    
    if (selectedBodyPart == null || selectedBodyPart.isEmpty) {
      throw ArgumentError('身體部位為必選項');
    }
  }
}

