import '../../models/exercise_model.dart';
import '../../models/favorite/favorite_exercise.dart';

/// 訓練動作控制器接口
/// 
/// 定義與訓練動作相關的業務邏輯操作。
/// ⭐ v3.7: 擴展介面以支援收藏功能和查詢方法
abstract class IExerciseController {
  /// 正在載入數據
  bool get isLoading;
  
  /// 錯誤訊息
  String? get errorMessage;
  
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
  Future<Exercise?> getExerciseById(String exerciseId);

  // =========================================================================
  // ⭐ v3.7: 查詢方法（供 View 層使用）
  // =========================================================================

  /// 獲取訓練類型列表
  Future<List<String>> getExerciseTypes();

  /// 根據篩選條件獲取動作列表
  Future<List<Exercise>> getExercisesByFilters(Map<String, String> filters);

  // =========================================================================
  // ⭐ v3.7: 收藏功能
  // =========================================================================

  /// 添加動作到收藏
  Future<bool> addFavorite({
    required String userId,
    required String exerciseId,
    required String exerciseName,
    required String bodyPart,
  });

  /// 移除收藏動作
  Future<bool> removeFavorite({
    required String userId,
    required String exerciseId,
  });

  /// 檢查動作是否已收藏
  Future<bool> isFavorite(String userId, String exerciseId);

  /// 獲取用戶收藏的動作 ID 列表
  Future<List<String>> getFavoriteExerciseIds(String userId);

  /// 獲取用戶收藏的動作列表（含詳細資訊）
  Future<List<FavoriteExercise>> getFavoriteExercises(String userId);
} 