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

  /// 根據ID獲取動作詳情
  Future<Exercise?> getExerciseById(String exerciseId);

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

  // =========================================================================
  // ⭐ v5.0: 進階搜尋與篩選
  // =========================================================================

  /// v5.0 進階搜尋（支援多維度篩選）
  ///
  /// [query] 搜尋關鍵字（支援別名搜尋）
  /// [movementPatterns] 動作模式篩選（如 ['horizontal_push', 'squat']）
  /// [pplTags] PPL 標籤篩選（如 ['push', 'legs']）
  /// [primaryMuscle] 主動肌篩選（如 'pec_major_sternal'）
  /// [equipment] 器材篩選（如 'barbell'）
  /// [isExplosive] 爆發力動作篩選
  /// [difficultyLevel] 難度等級篩選（beginner/intermediate/advanced）
  /// [limit] 返回結果數量上限（預設 50）
  Future<List<Exercise>> searchExercisesAdvanced({
    String? query,
    List<String>? movementPatterns,
    List<String>? pplTags,
    List<String>? excludePplTags,
    String? primaryMuscle,
    String? equipment,
    Set<String>? equipmentSet,
    bool? isExplosive,
    String? difficultyLevel,
    String? mechanicsType,
    int limit = 50,
  });

  /// 獲取動作模式參照資料
  Future<List<Map<String, String>>> getMovementPatterns();

  /// 獲取肌肉群參照資料
  Future<List<Map<String, String>>> getMuscleGroups();

  /// 獲取器材參照資料
  Future<List<Map<String, String>>> getEquipmentList();

  // =========================================================================
  // ⭐ v5.0: 偏好設定
  // =========================================================================

  /// 偏好的瀏覽模式（'anatomy' 或 'pattern'）
  String get preferredBrowseMode;

  /// 使用者的健身房器材 IDs
  Set<String> get myEquipment;

  /// 設定偏好的瀏覽模式
  Future<void> setPreferredBrowseMode(String mode);

  /// 設定使用者的健身房器材
  Future<void> setMyEquipment(Set<String> equipment);
}