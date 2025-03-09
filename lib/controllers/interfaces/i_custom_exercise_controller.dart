import '../../models/custom_exercise_model.dart';
import '../../models/exercise_model.dart';

/// 自定義動作控制器接口
/// 
/// 定義與自定義動作相關的業務邏輯操作。
abstract class ICustomExerciseController {
  /// 獲取用戶的所有自定義動作
  Future<List<CustomExercise>> getUserExercises();
  
  /// 添加新的自定義動作
  /// 
  /// [name] 自定義動作的名稱
  Future<CustomExercise> addExercise(String name);
  
  /// 更新現有自定義動作
  /// 
  /// [exerciseId] 要更新的動作ID
  /// [newName] 新的動作名稱
  Future<void> updateExercise(String exerciseId, String newName);
  
  /// 刪除自定義動作
  /// 
  /// [exerciseId] 要刪除的動作ID
  Future<void> deleteExercise(String exerciseId);
  
  /// 將自定義動作轉換為標準Exercise模型
  /// 
  /// [customExercise] 要轉換的自定義動作
  Exercise convertToExercise(CustomExercise customExercise);
} 