import '../../models/custom_exercise_model.dart';
import '../../models/exercise_model.dart';

/// 自定義動作轉換器
class CustomExerciseConverter {
  /// 將自定義動作轉換為標準 Exercise 對象
  static Exercise toExercise(CustomExercise customExercise) {
    return Exercise(
      id: customExercise.id,
      name: customExercise.name,
      nameEn: '',
      bodyParts: [customExercise.bodyPart],
      type: '自訂',
      equipment: customExercise.equipment,
      jointType: '',
      level1: '',
      level2: '',
      level3: '',
      level4: '',
      level5: '',
      actionName: customExercise.name,
      description: customExercise.description.isEmpty 
          ? '用戶自訂動作' 
          : customExercise.description,
      videoUrl: '',
      apps: [],
      createdAt: customExercise.createdAt,
      bodyPart: customExercise.bodyPart,
      equipmentCategory: customExercise.equipment,
    );
  }
}

