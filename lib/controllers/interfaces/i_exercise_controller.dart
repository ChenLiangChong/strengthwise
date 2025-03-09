import '../../models/exercise_model.dart';

/// 訓練動作控制器接口
/// 
/// 定義與訓練動作相關的業務邏輯操作。
abstract class IExerciseController {
  /// 記錄調試信息
  void logDebug(String message);
  
  /// 載入訓練類型
  Future<List<String>> loadExerciseTypes();
  
  /// 載入身體部位
  Future<List<String>> loadBodyParts();
  
  /// 載入特定級別的分類
  /// 
  /// [level] 分類級別 (1-5)
  /// [selectedType] 選擇的訓練類型
  /// [selectedBodyPart] 選擇的身體部位
  /// [selectedLevel1] 選擇的一級分類
  /// [selectedLevel2] 選擇的二級分類
  /// [selectedLevel3] 選擇的三級分類
  /// [selectedLevel4] 選擇的四級分類
  Future<List<String>> loadCategories({
    required int level,
    String? selectedType,
    String? selectedBodyPart,
    String? selectedLevel1,
    String? selectedLevel2,
    String? selectedLevel3,
    String? selectedLevel4,
  });
  
  /// 載入最終動作列表
  /// 
  /// [selectedType] 選擇的訓練類型
  /// [selectedBodyPart] 選擇的身體部位
  /// [selectedLevel1] 選擇的一級分類
  /// [selectedLevel2] 選擇的二級分類
  /// [selectedLevel3] 選擇的三級分類
  /// [selectedLevel4] 選擇的四級分類
  /// [selectedLevel5] 選擇的五級分類
  Future<List<Exercise>> loadFinalExercises({
    String? selectedType,
    String? selectedBodyPart,
    String? selectedLevel1,
    String? selectedLevel2,
    String? selectedLevel3,
    String? selectedLevel4,
    String? selectedLevel5,
  });
  
  /// 根據ID獲取動作詳情
  /// 
  /// [exerciseId] 動作ID
  Future<Exercise?> getExerciseById(String exerciseId);
} 