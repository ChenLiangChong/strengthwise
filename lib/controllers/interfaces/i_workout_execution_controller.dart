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

  /// ⭐ v3.1: 設置權限覆蓋（Session Mode 用）
  ///
  /// 當 Session Mode 內嵌使用此 Controller 時，可以覆蓋預設的權限判斷
  void setPermissionOverride({
    bool? canEdit,
    bool? canMarkSet,
  });
  
  /// 加載訓練計劃
  Future<void> loadWorkoutPlan(String workoutRecordId);
  
  /// ⭐ v3.1: Realtime 重載（靜默更新，不閃爍）
  Future<void> reloadForRealtime(String workoutRecordId);
  
  /// ⭐ v3.1: 獲取訓練者 ID（用於判斷是否需要 Realtime）
  String? getTraineeId();
  
  /// ⭐ v3.1: 是否為上課類型訓練（有 appointmentId）
  bool isSessionPlan();
  
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
  
  /// 檢查是否可以編輯（修改重量/次數）
  bool canEdit();
  
  /// ⭐ v3.1: 檢查是否可以新增（新增動作/新增組數）
  bool canAdd();
  
  /// ⭐ v2.9: 檢查是否可以刪除（刪除動作/刪除計畫/減少組數）
  bool canDelete();
  
  /// 檢查是否可以勾選完成（只有今天的訓練可以勾選完成）
  bool canToggleCompletion();
  
  /// ⭐ v3.1: 檢查是否可以開始訓練（計時）
  bool canStartTraining();
  
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
  
  /// 新增組數到指定運動
  Future<void> addSetToExercise(int exerciseIndex, {BuildContext? context});
  
  /// ⭐ v2.9.1 TRN-2: 減少組數（只有創建者可以）
  Future<void> removeSetFromExercise(int exerciseIndex, {BuildContext? context});
  
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
  
  /// 檢查是否為教練查看學員訓練
  /// 
  /// 當教練查看學員的訓練時，可以編輯（添加動作），但不能幫學員打勾
  bool isCoachViewingTrainee();
  
  /// ⭐ v2.9: 檢查是否正在查看別人創建的計畫
  /// 
  /// 當前用戶不是創建者時，不能刪除動作或計畫
  bool isViewingOthersCreatedPlan();
  
  /// ⭐ v2.9.1: 是否應該顯示計時器 UI
  /// 
  /// 只有「今天」且「不是教練查看學員」的情況才顯示計時功能
  /// - 過去的訓練：不顯示（只能查看記錄）
  /// - 未來的訓練：不顯示（只能規劃）
  /// - 教練查看學員訓練：不顯示（只能安排計畫）
  bool shouldShowTimerUI();
  
  /// 檢查所有運動是否已完成
  bool allExercisesCompleted();
  
  // =============================================
  // ⭐ v2.9.1: 訓練狀態追蹤
  // =============================================
  
  /// 獲取訓練狀態：pending | in_progress | paused | completed
  String get trainingStatus;
  
  /// 獲取累計訓練秒數（不含暫停）
  int get elapsedSeconds;
  
  /// 獲取實際開始時間
  DateTime? get actualStartTime;
  
  /// 是否處於準備模式（pending）
  bool get isPending;
  
  /// 是否正在進行中
  bool get isInProgress;
  
  /// 是否已暫停
  bool get isPaused;
  
  /// 是否已完成
  bool get isCompleted;
  
  /// 開始訓練（pending → in_progress）
  Future<void> startTraining();
  
  /// 暫停訓練（in_progress → paused）
  /// 離開頁面時自動呼叫
  Future<void> pauseTraining();
  
  /// 繼續訓練（paused → in_progress）
  Future<void> resumeTraining();
  
  /// 完成訓練（in_progress → completed）
  Future<bool> completeTraining({BuildContext? context});
  
  /// 更新經過時間（每秒呼叫，僅在 in_progress 時有效）
  void tickElapsedTime();
} 