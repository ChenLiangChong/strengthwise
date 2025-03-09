import '../../models/custom_exercise_model.dart';

/// 自定義動作服務接口
/// 
/// 定義與自定義動作相關的所有操作，
/// 這種接口抽象允許不同的實現，
/// 便於單元測試和功能擴展。
abstract class ICustomExerciseService {
  /// 獲取當前用戶的所有自定義動作
  Future<List<CustomExercise>> getUserCustomExercises();
  
  /// 添加新的自定義動作
  /// 
  /// [name] 自定義動作的名稱
  /// 返回新創建的自定義動作
  Future<CustomExercise> addCustomExercise(String name);
  
  /// 更新現有自定義動作
  /// 
  /// [exerciseId] 要更新的動作ID
  /// [newName] 新的動作名稱
  Future<void> updateCustomExercise(String exerciseId, String newName);
  
  /// 刪除自定義動作
  /// 
  /// [exerciseId] 要刪除的動作ID
  Future<void> deleteCustomExercise(String exerciseId);
} 