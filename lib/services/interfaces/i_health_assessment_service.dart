import '../../models/health_assessment_models.dart';

/// 健康評估服務介面
/// 
/// 提供學員健康評估問卷的查詢、建立與更新功能
abstract class IHealthAssessmentService {
  /// 取得指定學員的當前有效評估
  /// 
  /// [userId] 學員 ID
  /// 
  /// 返回當前評估，若不存在則返回 null
  Future<HealthAssessmentModel?> getCurrentAssessment(String userId);

  /// 取得指定學員的所有評估記錄（包含歷史記錄）
  /// 
  /// [userId] 學員 ID
  /// [limit] 最多返回筆數（預設 10）
  /// 
  /// 返回評估列表，按評估日期降序排列
  Future<List<HealthAssessmentModel>> getAssessmentHistory(
    String userId, {
    int limit = 10,
  });

  /// 建立新的健康評估
  /// 
  /// [assessment] 健康評估模型
  /// [setAsCurrent] 是否設為當前有效評估（預設 true）
  /// 
  /// 注意：若 setAsCurrent = true，會將舊的評估標記為非當前
  Future<HealthAssessmentModel> createAssessment(
    HealthAssessmentModel assessment, {
    bool setAsCurrent = true,
  });

  /// 更新現有健康評估
  /// 
  /// [assessment] 健康評估模型（必須包含 id）
  Future<void> updateAssessment(HealthAssessmentModel assessment);

  /// 刪除健康評估
  /// 
  /// [assessmentId] 評估 ID
  /// 
  /// 注意：若刪除的是當前評估，需手動指定新的當前評估
  Future<void> deleteAssessment(String assessmentId);

  /// 將指定評估設為當前有效
  /// 
  /// [assessmentId] 評估 ID
  /// [userId] 學員 ID
  /// 
  /// 會將該學員的其他評估標記為非當前
  Future<void> setAsCurrentAssessment(String assessmentId, String userId);

  /// 批次查詢多位學員的當前評估
  /// 
  /// [userIds] 學員 ID 列表
  /// 
  /// 返回 Map，key 為 userId，value 為評估（可能為 null）
  Future<Map<String, HealthAssessmentModel?>> batchGetCurrentAssessments(
    List<String> userIds,
  );

  /// 取得需要警示的學員列表
  /// 
  /// [coachId] 教練 ID
  /// 
  /// 返回未通過安全篩檢或有重要警示的學員評估
  Future<List<HealthAssessmentModel>> getWarningAssessments(String coachId);
}

