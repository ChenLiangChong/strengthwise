import '../../models/workout_template_model.dart';
import '../../models/workout_record_model.dart';
import '../../models/workout_record/exercise_record.dart';

/// 訓練計畫控制器接口
/// 
/// 定義與訓練計畫相關的業務邏輯操作。
abstract class IWorkoutController {
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
} 