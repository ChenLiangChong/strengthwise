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
  /// [trainingType] 訓練類型：心肺適能訓練/活動度與伸展/阻力訓練
  /// [bodyPart] 身體部位：胸部/背部/腿部/肩部/手臂/核心
  /// [equipment] 器材（選填）：徒手/啞鈴/槓鈴/機械/Cable/其他
  /// [description] 動作說明（選填）
  /// [notes] 個人筆記（選填）
  ///
  /// 返回新創建的自定義動作
  Future<CustomExercise> addCustomExercise({
    required String name,
    required String trainingType,
    required String bodyPart,
    String equipment = '徒手',
    String description = '',
    String notes = '',
  });

  /// 更新現有自定義動作
  ///
  /// [exerciseId] 要更新的動作ID
  /// [name] 新的動作名稱（選填）
  /// [trainingType] 新的訓練類型（選填）
  /// [bodyPart] 新的身體部位（選填）
  /// [equipment] 新的器材（選填）
  /// [description] 新的動作說明（選填）
  /// [notes] 新的個人筆記（選填）
  Future<void> updateCustomExercise({
    required String exerciseId,
    String? name,
    String? trainingType,
    String? bodyPart,
    String? equipment,
    String? description,
    String? notes,
  });

  /// 刪除自定義動作
  ///
  /// [exerciseId] 要刪除的動作ID
  Future<void> deleteCustomExercise(String exerciseId);
}
