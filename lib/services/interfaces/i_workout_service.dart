import '../../models/workout_template_model.dart';
import '../../models/workout_record_model.dart';

/// 訓練計畫服務接口
/// 
/// 定義與訓練計畫相關的所有操作，
/// 提供標準接口以支持不同的實現方式。
abstract class IWorkoutService {
  /// 獲取用戶的所有訓練模板
  Future<List<WorkoutTemplate>> getUserTemplates();
  
  /// 獲取特定訓練模板
  Future<WorkoutTemplate?> getTemplateById(String templateId);
  
  /// 創建訓練模板
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template);
  
  /// 更新訓練模板
  Future<bool> updateTemplate(WorkoutTemplate template);
  
  /// 刪除訓練模板
  Future<bool> deleteTemplate(String templateId);
  
  /// 獲取用戶的所有訓練記錄
  Future<List<WorkoutRecord>> getUserRecords();
  
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
} 