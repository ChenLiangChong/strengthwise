import '../../models/workout_template_model.dart';
import '../../models/workout_record_model.dart';

/// 訓練計畫服務接口
/// 
/// 定義與訓練計畫相關的所有操作，
/// 提供標準接口以支持不同的實現方式。
abstract class IWorkoutService {
  /// 獲取用戶的訓練模板（支援 Cursor-based 分頁）
  /// 
  /// [cursor] 游標（上一頁最後一筆的 updated_at）
  /// [limit] 每頁返回數量（預設 20）
  Future<List<WorkoutTemplate>> getUserTemplates({
    String? cursor,
    int limit = 20,
  });
  
  /// 獲取特定訓練模板
  Future<WorkoutTemplate?> getTemplateById(String templateId);
  
  /// 創建訓練模板
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template);
  
  /// 更新訓練模板
  Future<bool> updateTemplate(WorkoutTemplate template);
  
  /// 刪除訓練模板
  Future<bool> deleteTemplate(String templateId);
  
  /// 清除用戶的訓練計劃快取 ⭐
  /// 
  /// 用於強制刷新數據（例如下拉刷新時）
  void clearUserPlansCache(String userId);
  
  /// 獲取用戶的訓練記錄（支援 Cursor-based 分頁）
  /// 
  /// [cursor] 游標（上一頁最後一筆的 completed_date）
  /// [limit] 每頁返回數量（預設 20）
  Future<List<WorkoutRecord>> getUserRecords({
    String? cursor,
    int limit = 20,
  });
  
  /// 獲取用戶的訓練計劃（可篩選完成狀態，支援 Cursor-based 分頁）
  /// 
  /// [userId] 用戶 ID（可選）。如果為 null，查詢當前登入用戶；如果指定，查詢該用戶（教練查學員用）⭐
  /// [completed] 完成狀態篩選
  /// [startDate] 起始日期
  /// [endDate] 結束日期
  /// [cursor] 游標（上一頁最後一筆的 scheduled_date）
  /// [limit] 每頁返回數量（預設 20）
  Future<List<WorkoutRecord>> getUserPlans({
    String? userId,
    bool? completed,
    DateTime? startDate,
    DateTime? endDate,
    String? cursor,
    int limit = 20,
  });
  
  /// 獲取特定訓練記錄
  Future<WorkoutRecord?> getRecordById(String recordId);
  
  /// 創建訓練記錄
  Future<WorkoutRecord> createRecord(WorkoutRecord record);
  
  /// 更新訓練記錄
  Future<bool> updateRecord(WorkoutRecord record);
  
  /// 刪除訓練記錄
  Future<bool> deleteRecord(String recordId);
  
  /// 從模板創建記錄
  Future<WorkoutRecord> createRecordFromTemplate(String templateId);

  /// 清除特定用戶的快取（用於刷新）⭐
  /// 
  /// [userId] 用戶 ID（可選）。如果為 null，清除當前用戶快取
  void clearUserCache({String? userId});

  /// 檢查指定時間範圍是否與現有訓練計畫重疊 ⭐ v2.1
  /// 
  /// [traineeId] 受訓者 ID
  /// [startTime] 訓練開始時間
  /// [endTime] 訓練結束時間
  /// [excludeRecordId] 排除的記錄 ID（編輯現有計畫時使用）
  /// 
  /// 返回重疊的訓練計畫列表（空列表表示無重疊）
  Future<List<WorkoutRecord>> checkTimeOverlap({
    required String traineeId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeRecordId,
  });
} 