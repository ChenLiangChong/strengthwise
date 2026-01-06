/// 運動緩存鍵構建器
///
/// 根據過濾條件生成一致的緩存鍵
class ExerciseCacheKeyBuilder {
  /// 生成分類緩存鍵
  /// 
  /// 格式：'level{level}_{type}_{bodyPart}_{level1}_{level2}_{level3}_{level4}'
  static String buildCategoryCacheKey({
    required int level,
    String? selectedType,
    String? selectedBodyPart,
    String? selectedLevel1,
    String? selectedLevel2,
    String? selectedLevel3,
    String? selectedLevel4,
  }) {
    final typeValue = selectedType ?? '';
    final bodyPartValue = selectedBodyPart ?? '';
    final level1Value = (level >= 2 && selectedLevel1 != null) ? selectedLevel1 : '';
    final level2Value = (level >= 3 && selectedLevel2 != null) ? selectedLevel2 : '';
    final level3Value = (level >= 4 && selectedLevel3 != null) ? selectedLevel3 : '';
    final level4Value = (level >= 5 && selectedLevel4 != null) ? selectedLevel4 : '';
    
    return 'level${level}_${typeValue}_${bodyPartValue}_${level1Value}_${level2Value}_${level3Value}_$level4Value';
  }
  
  /// 生成運動列表緩存鍵
  /// 
  /// 格式：'exercises_{type}_{bodyPart}_{level1}_{level2}_{level3}_{level4}_{level5}'
  static String buildExercisesCacheKey({
    required String selectedType,
    required String selectedBodyPart,
    String? selectedLevel1,
    String? selectedLevel2,
    String? selectedLevel3,
    String? selectedLevel4,
    String? selectedLevel5,
  }) {
    final level1Value = selectedLevel1 ?? '';
    final level2Value = selectedLevel2 ?? '';
    final level3Value = selectedLevel3 ?? '';
    final level4Value = selectedLevel4 ?? '';
    final level5Value = selectedLevel5 ?? '';
    
    return 'exercises_${selectedType}_${selectedBodyPart}_${level1Value}_${level2Value}_${level3Value}_${level4Value}_$level5Value';
  }
}

