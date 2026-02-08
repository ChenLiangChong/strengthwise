import '../../models/exercise_model.dart';

/// 運動服務接口
/// 
/// 定義與運動相關的所有操作，
/// 提供標準接口以支持不同的實現方式。
abstract class IExerciseService {
  /// 獲取特定ID的運動詳情
  /// 
  /// [exerciseId] 運動ID
  Future<Exercise?> getExerciseById(String exerciseId);
  
  /// 批量獲取多個運動詳情
  /// 
  /// [exerciseIds] 運動ID列表
  /// 返回 Map<ID, Exercise>，ID 為 key，Exercise 為 value
  Future<Map<String, Exercise>> getExercisesByIds(List<String> exerciseIds);
  
  /// 搜尋運動（使用 pgroonga 全文搜尋）
  ///
  /// [query] 搜尋關鍵字（支援中英文混合）
  /// [limit] 返回結果數量上限（預設 20）
  /// 返回按相關度排序的運動列表
  Future<List<Exercise>> searchExercises(String query, {int limit = 20});

  // ============================================================================
  // v5.0+ 動作分類系統 v2
  // ============================================================================

  /// 進階搜尋運動（支援別名、動作模式、PPL 篩選）
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

  /// 獲取所有動作模式參照資料
  ///
  /// 返回動作模式 ID 和名稱的映射列表
  Future<List<Map<String, String>>> getMovementPatterns();

  /// 獲取所有肌肉群參照資料
  ///
  /// 返回肌肉群 ID、名稱和區域的映射列表
  Future<List<Map<String, String>>> getMuscleGroups();

  /// 獲取所有器材參照資料
  ///
  /// 返回器材 ID 和名稱的映射列表
  Future<List<Map<String, String>>> getEquipmentList();

  /// 記錄日誌信息
  ///
  /// [message] 日誌消息
  void logDebug(String message);
} 