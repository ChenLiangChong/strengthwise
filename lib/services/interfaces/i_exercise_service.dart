import '../../models/exercise_model.dart';

/// 運動服務接口
/// 
/// 定義與運動相關的所有操作，
/// 提供標準接口以支持不同的實現方式。
abstract class IExerciseService {
  /// 獲取所有訓練類型
  Future<List<String>> getExerciseTypes();
  
  /// 獲取所有身體部位
  Future<List<String>> getBodyParts();
  
  /// 根據條件獲取特定級別的分類
  /// 
  /// [level] 分類級別
  /// [filters] 篩選條件
  Future<List<String>> getCategoriesByLevel(
    int level, 
    Map<String, String> filters
  );
  
  /// 根據條件獲取最終的運動列表
  /// 
  /// [filters] 篩選條件
  Future<List<Exercise>> getExercisesByFilters(Map<String, String> filters);
  
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
  
  /// 記錄日誌信息
  /// 
  /// [message] 日誌消息
  void logDebug(String message);
} 