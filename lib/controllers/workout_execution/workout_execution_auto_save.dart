import 'package:flutter/foundation.dart';
import '../../models/workout_record_model.dart';
import '../../services/interfaces/i_workout_service.dart';

/// 訓練執行自動保存助手
/// 
/// 處理訓練記錄的自動保存邏輯
class WorkoutExecutionAutoSave {
  final IWorkoutService _workoutService;
  
  WorkoutExecutionAutoSave({
    required IWorkoutService workoutService,
  }) : _workoutService = workoutService;
  
  /// 自動保存打勾狀態（不顯示「完成訓練」提示）
  Future<bool> saveCheckboxState({
    required String workoutRecordId,
    required String userId,
    required List<ExerciseRecord> exerciseRecords,
    required String notes,
    required bool overallCompleted,
  }) async {
    try {
      if (kDebugMode) {
        print('[AutoSave] 自動保存打勾狀態，workoutRecordId: $workoutRecordId');
      }
      
      // 獲取現有記錄
      final existingRecord = await _workoutService.getRecordById(workoutRecordId);
      
      if (existingRecord != null) {
        // 更新記錄
        final updatedRecord = WorkoutRecord(
          id: workoutRecordId,
          workoutPlanId: existingRecord.workoutPlanId,
          userId: userId,
          title: existingRecord.title,
          date: existingRecord.date,
          exerciseRecords: exerciseRecords,
          notes: notes,
          completed: overallCompleted,
          createdAt: existingRecord.createdAt,
          trainingTime: existingRecord.trainingTime,
        );
        
        await _workoutService.updateRecord(updatedRecord);
        
        if (kDebugMode) {
          print('[AutoSave] 自動保存成功');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('[AutoSave] 找不到訓練記錄: $workoutRecordId');
        }
        return false;
      }
    } catch (e) {
      // 靜默失敗，不影響用戶體驗
      if (kDebugMode) {
        print('[AutoSave] 自動保存打勾狀態失敗: $e');
      }
      return false;
    }
  }
}

