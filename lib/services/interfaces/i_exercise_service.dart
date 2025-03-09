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
  
  /// 記錄日誌信息
  /// 
  /// [message] 日誌消息
  void logDebug(String message);
} 