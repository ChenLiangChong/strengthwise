import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/workout_record_model.dart';
import '../../services/interfaces/i_workout_service.dart';
import '../../utils/notification_utils.dart';

/// 訓練執行記錄保存助手
/// 
/// 處理訓練記錄的完整保存邏輯
class WorkoutExecutionRecordSaver {
  final IWorkoutService _workoutService;
  
  WorkoutExecutionRecordSaver({
    required IWorkoutService workoutService,
  }) : _workoutService = workoutService;
  
  /// 保存訓練記錄
  Future<bool> saveRecord({
    required String workoutRecordId,
    required String userId,
    required List<ExerciseRecord> exerciseRecords,
    required String notes,
    required bool overallCompleted,
    DateTime? planDate,
    DateTime? trainingTime,
    BuildContext? context,
  }) async {
    try {
      if (kDebugMode) {
        print('[RecordSaver] 保存訓練記錄: $workoutRecordId');
      }
      
      // 獲取現有記錄
      final existingRecord = await _workoutService.getRecordById(workoutRecordId);
      
      if (existingRecord != null) {
        // 更新現有記錄
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
          trainingTime: trainingTime ?? existingRecord.trainingTime,
        );
        
        final success = await _workoutService.updateRecord(updatedRecord);
        
        if (!success) {
          throw Exception('更新訓練記錄失敗');
        }
        
        if (kDebugMode) {
          print('[RecordSaver] 訓練記錄更新成功');
        }
      } else {
        // 創建新記錄
        if (kDebugMode) {
          print('[RecordSaver] 警告：找不到現有記錄，創建新記錄');
        }
        
        final newRecord = WorkoutRecord(
          id: workoutRecordId,
          workoutPlanId: workoutRecordId,
          userId: userId,
          title: '訓練記錄',
          date: planDate ?? DateTime.now(),
          exerciseRecords: exerciseRecords,
          notes: notes,
          completed: overallCompleted,
          createdAt: DateTime.now(),
          trainingTime: trainingTime,
        );
        
        await _workoutService.createRecord(newRecord);
        
        if (kDebugMode) {
          print('[RecordSaver] 新訓練記錄創建成功');
        }
      }
      
      if (context != null && context.mounted) {
        NotificationUtils.showSuccess(context, '訓練記錄已保存');
      }
      
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[RecordSaver] 保存訓練記錄失敗: $e');
        print('[RecordSaver] Stack trace: $stackTrace');
      }
      
      if (context != null && context.mounted) {
        NotificationUtils.showError(context, '保存訓練記錄失敗: $e');
      }
      
      return false;
    }
  }
}

