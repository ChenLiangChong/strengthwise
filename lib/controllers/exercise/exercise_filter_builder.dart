/// 運動過濾條件構建器
///
/// 將用戶選擇轉換為服務層可使用的過濾器
class ExerciseFilterBuilder {
  /// 構建分類查詢過濾器
  static Map<String, String> buildCategoryFilters({
    required int level,
    String? selectedType,
    String? selectedBodyPart,
    String? selectedLevel1,
    String? selectedLevel2,
    String? selectedLevel3,
    String? selectedLevel4,
  }) {
    final filters = <String, String>{};
    
    // 添加訓練類型和身體部位過濾條件
    if (selectedType != null && selectedType.isNotEmpty) {
      filters['type'] = selectedType;
    }
    
    if (selectedBodyPart != null && selectedBodyPart.isNotEmpty) {
      filters['bodyPart'] = selectedBodyPart;
    }
    
    // 根據當前要查詢的層級，添加所有前置層級的條件
    if (level >= 2 && selectedLevel1 != null && selectedLevel1.isNotEmpty) {
      filters['level1'] = selectedLevel1;
    }
    
    if (level >= 3 && selectedLevel2 != null && selectedLevel2.isNotEmpty) {
      filters['level2'] = selectedLevel2;
    }
    
    if (level >= 4 && selectedLevel3 != null && selectedLevel3.isNotEmpty) {
      filters['level3'] = selectedLevel3;
    }
    
    if (level >= 5 && selectedLevel4 != null && selectedLevel4.isNotEmpty) {
      filters['level4'] = selectedLevel4;
    }
    
    return filters;
  }
  
  /// 構建運動列表查詢過濾器
  static Map<String, String> buildExerciseFilters({
    required String selectedType,
    required String selectedBodyPart,
    String? selectedLevel1,
    String? selectedLevel2,
    String? selectedLevel3,
    String? selectedLevel4,
    String? selectedLevel5,
  }) {
    final filters = <String, String>{
      'type': selectedType,
      'bodyPart': selectedBodyPart,
    };
    
    // 添加所有層級條件
    if (selectedLevel1 != null && selectedLevel1.isNotEmpty) {
      filters['level1'] = selectedLevel1;
    }
    
    if (selectedLevel2 != null && selectedLevel2.isNotEmpty) {
      filters['level2'] = selectedLevel2;
    }
    
    if (selectedLevel3 != null && selectedLevel3.isNotEmpty) {
      filters['level3'] = selectedLevel3;
    }
    
    if (selectedLevel4 != null && selectedLevel4.isNotEmpty) {
      filters['level4'] = selectedLevel4;
    }
    
    if (selectedLevel5 != null && selectedLevel5.isNotEmpty) {
      filters['level5'] = selectedLevel5;
    }
    
    return filters;
  }
}

