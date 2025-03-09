import 'package:flutter/material.dart';
import '../../models/workout_record_model.dart';
import '../../models/exercise_model.dart';

/// 訓練執行控制器接口
///
/// 提供管理訓練執行頁面的業務邏輯
abstract class IWorkoutExecutionController {
  /// 正在載入數據
  bool get isLoading;
  
  /// 正在保存數據
  bool get isSaving;
  
  /// 數據是否已變更
  bool get isDataChanged;
  
  /// 錯誤訊息
  String? get errorMessage;
  
  /// 清除錯誤消息
  void clearError();
  
  /// 加載訓練計劃
  Future<void> loadWorkoutPlan(String workoutRecordId);
  
  /// 獲取訓練計劃標題
  String getPlanTitle();
  
  /// 獲取訓練計劃類型
  String getPlanType();
  
  /// 獲取訓練備註
  String getNotes();
  
  /// 設置訓練備註
  void setNotes(String notes);
  
  /// 獲取運動記錄列表
  List<ExerciseRecord> getExerciseRecords();
  
  /// 獲取當前運動索引
  int getCurrentExerciseIndex();
  
  /// 設置當前運動索引
  void setCurrentExerciseIndex(int index);
  
  /// 檢查是否可以修改訓練
  bool canModify();
  
  /// 檢查是否為過去的訓練
  bool isPastDate();
  
  /// 檢查是否為未來的訓練
  bool isFutureDate();
  
  /// 檢查是否為今天的訓練
  bool isToday();
  
  /// 切換組數完成狀態
  void toggleSetCompletion(int exerciseIndex, int setIndex, {BuildContext? context});
  
  /// 更新組數數據
  Future<void> updateSetData(
    int exerciseIndex, 
    int setIndex, 
    int reps, 
    double weight,
    {BuildContext? context}
  );
  
  /// 添加運動備註
  Future<void> addExerciseNote(
    int exerciseIndex, 
    String note,
    {BuildContext? context}
  );
  
  /// 添加新訓練動作
  Future<void> addNewExercise(Exercise exercise, int sets, int reps, double weight, int restTime, {BuildContext? context});
  
  /// 刪除訓練動作
  Future<void> deleteExercise(int exerciseIndex, {BuildContext? context});
  
  /// 設置訓練時間
  Future<void> setTrainingHour(int hour, {BuildContext? context});
  
  /// 保存訓練記錄
  Future<bool> saveWorkoutRecord({BuildContext? context});
  
  /// 計算總組數
  int calculateTotalSets();
  
  /// 計算總訓練量
  double calculateTotalVolume();
  
  /// 檢查所有運動是否已完成
  bool allExercisesCompleted();
} 