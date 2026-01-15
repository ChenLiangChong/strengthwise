import '../../models/workout_template_model.dart';
import '../../models/workout_record_model.dart';
import '../../models/workout_record/workout_record.dart'; // ⭐ v3.6: MVVM
import '../../models/exercise_history_record.dart'; // ⭐ v3.6: MVVM

/// 訓練計畫控制器接口
/// 
/// 定義與訓練計畫相關的業務邏輯操作。
abstract class IWorkoutController {
  /// ⭐ v3.5: 錯誤訊息（MVVM 重構）
  String? get errorMessage;
  /// 載入用戶訓練模板（可能使用緩存）
  Future<List<WorkoutTemplate>> loadUserTemplates();
  
  /// 強制重新載入訓練模板（忽略緩存）
  Future<List<WorkoutTemplate>> reloadTemplates();
  
  /// 獲取特定訓練模板
  Future<WorkoutTemplate?> getTemplateById(String templateId);
  
  /// 創建訓練模板
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template);
  
  /// 更新訓練模板
  Future<bool> updateTemplate(WorkoutTemplate template);
  
  /// 刪除訓練模板
  Future<bool> deleteTemplate(String templateId);
  
  /// 載入用戶訓練記錄
  Future<List<WorkoutRecord>> loadUserRecords();
  
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

  /// 將訓練記錄儲存為模板
  ///
  /// [exerciseRecords] 訓練記錄中的動作列表
  /// [templateName] 模板名稱
  /// [planType] 訓練類型
  /// [description] 描述（選填）
  ///
  /// 返回創建的模板
  Future<WorkoutTemplate> saveRecordAsTemplate({
    required List<ExerciseRecord> exerciseRecords,
    required String templateName,
    required String planType,
    String description = '',
  });

  // ============================================================================
  // ⭐ MVVM 重構：查詢方法（直接返回結果，不更新 Controller 狀態）
  // ============================================================================

  /// 查詢用戶的訓練計劃（日期範圍）
  ///
  /// [startDate] 起始日期
  /// [endDate] 結束日期
  /// [userId] 用戶 ID（可選，預設當前用戶）
  ///
  /// 返回指定日期範圍內的訓練計劃列表
  Future<List<WorkoutRecord>> getUserPlans({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  });

  /// 清除用戶的訓練計劃快取
  ///
  /// [userId] 用戶 ID
  void clearUserPlansCache(String userId);

  /// 清除用戶快取
  /// ⭐ v3.6 MVVM 重構
  void clearUserCache({String? userId});

  /// 檢查時間重疊
  /// ⭐ v3.6 MVVM 重構
  Future<List<WorkoutRecord>> checkTimeOverlap({
    required String traineeId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeRecordId,
  });

  /// 查詢教練創建的訓練計畫
  /// ⭐ v3.6 MVVM 重構
  ///
  /// [coachId] 教練 ID（creator_id）
  /// [clientIds] 學員 ID 列表（trainee_id）
  Future<List<WorkoutRecord>> getCoachCreatedPlans({
    required String coachId,
    required List<String> clientIds,
    int limit = 100,
  });

  /// 查詢動作歷史記錄
  /// ⭐ v3.6 MVVM 重構
  ///
  /// 用於 Session Mode 顯示 PREV 幽靈數據
  Future<List<ExerciseHistoryRecord>> getExerciseHistory({
    required String userId,
    required String exerciseId,
    int limit = 10,
  });
} 