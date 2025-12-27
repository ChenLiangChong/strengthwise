import 'package:flutter/material.dart';
import '../models/workout_record_model.dart';
import '../models/exercise_model.dart';
import '../services/interfaces/i_workout_service.dart';
import '../controllers/interfaces/i_auth_controller.dart';
import '../services/core/error_handling_service.dart';
import '../services/service_locator.dart';
import '../utils/notification_utils.dart';
import 'interfaces/i_workout_execution_controller.dart';
import 'workout_execution/workout_execution_data_manager.dart';
import 'workout_execution/workout_execution_permission_checker.dart';
import 'workout_execution/workout_execution_set_operations.dart';
import 'workout_execution/workout_execution_exercise_builder.dart';
import 'workout_execution/workout_execution_auto_save.dart';
import 'workout_execution/workout_execution_record_saver.dart';

/// 訓練執行控制器實現
///
/// 管理訓練執行頁面的業務邏輯，包括數據加載、狀態管理和操作處理
class WorkoutExecutionController extends ChangeNotifier implements IWorkoutExecutionController {
  // 依賴注入
  final IWorkoutService _workoutService;
  final IAuthController _authController;
  final ErrorHandlingService _errorService;
  
  // 狀態管理
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDataChanged = false;
  String? _errorMessage;
  
  // 子模組
  late final WorkoutExecutionDataManager _dataManager;
  late final WorkoutExecutionAutoSave _autoSave;
  late final WorkoutExecutionRecordSaver _recordSaver;
  
  /// 構造函數，支持依賴注入
  WorkoutExecutionController({
    IWorkoutService? workoutService,
    IAuthController? authController,
    ErrorHandlingService? errorService,
  }) : 
    _workoutService = workoutService ?? serviceLocator<IWorkoutService>(),
    _authController = authController ?? serviceLocator<IAuthController>(),
    _errorService = errorService ?? serviceLocator<ErrorHandlingService>() {
    // 初始化子模組
    _dataManager = WorkoutExecutionDataManager();
    _autoSave = WorkoutExecutionAutoSave(workoutService: _workoutService);
    _recordSaver = WorkoutExecutionRecordSaver(workoutService: _workoutService);
  }
  
  /// 正在載入數據
  @override
  bool get isLoading => _isLoading;
  
  /// 正在保存數據
  @override
  bool get isSaving => _isSaving;
  
  /// 數據是否已變更
  @override
  bool get isDataChanged => _isDataChanged;
  
  /// 錯誤訊息
  @override
  String? get errorMessage => _errorMessage;
  
  /// 清除錯誤消息
  @override
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  /// 設置載入狀態
  void _setLoading(bool isLoading) {
    if (_isLoading != isLoading) {
      _isLoading = isLoading;
      notifyListeners();
    }
  }
  
  /// 設置保存狀態
  void _setSaving(bool isSaving) {
    if (_isSaving != isSaving) {
      _isSaving = isSaving;
      notifyListeners();
    }
  }
  
  /// 處理錯誤
  void _handleError(String message, [dynamic error]) {
    _errorMessage = message;
    _errorService.logError('$message: $error', type: 'WorkoutExecutionControllerError');
    _setLoading(false);
    _setSaving(false);
    notifyListeners();
  }
  
  /// 加載訓練計劃
  @override
  Future<void> loadWorkoutPlan(String workoutRecordId) async {
    _dataManager.workoutRecordId = workoutRecordId;
    _setLoading(true);
    
    try {
      print('[WorkoutExecutionController] 從 Supabase 獲取訓練計畫: $workoutRecordId');
      
      // 使用 IWorkoutService 獲取訓練記錄
      final record = await _workoutService.getRecordById(workoutRecordId);

      // 如果找不到，拋出錯誤
      if (record == null) {
        throw Exception('無法找到訓練計劃');
      }

      print('[WorkoutExecutionController] 成功獲取訓練計畫: ${record.workoutPlanId}');
      
      // 設置計劃標題和類型
      _dataManager.planTitle = '訓練記錄';
      _dataManager.planType = '一般訓練';
      
      if (record.notes.isNotEmpty) {
        _dataManager.notesController.text = record.notes;
      }
      
      // 處理日期信息
      _dataManager.processDateInfo(record.date);
      
      // 設置運動記錄
      _dataManager.exerciseRecords = record.exerciseRecords;
      
      print('[WorkoutExecutionController] 訓練計畫載入完成，動作數量: ${_dataManager.exerciseRecords.length}');
      
      _setLoading(false);
    } catch (e) {
      print('[WorkoutExecutionController] 加載訓練計劃失敗: $e');
      _handleError('加載訓練計劃失敗', e);
    }
  }
  
  /// 獲取訓練計劃標題
  @override
  String getPlanTitle() => _dataManager.planTitle;
  
  /// 獲取訓練計劃類型
  @override
  String getPlanType() => _dataManager.planType;
  
  /// 獲取訓練備註
  @override
  String getNotes() => _dataManager.notesController.text;
  
  /// 設置訓練備註
  @override
  void setNotes(String notes) {
    _dataManager.notesController.text = notes;
    _isDataChanged = true;
    notifyListeners();
  }
  
  /// 獲取運動記錄列表
  @override
  List<ExerciseRecord> getExerciseRecords() => _dataManager.exerciseRecords;
  
  /// 獲取當前運動索引
  @override
  int getCurrentExerciseIndex() => _dataManager.currentExerciseIndex;
  
  /// 設置當前運動索引
  @override
  void setCurrentExerciseIndex(int index) {
    _dataManager.setCurrentExerciseIndex(index);
    notifyListeners();
  }
  
  /// 檢查是否可以修改訓練
  @override
  bool canModify() {
    final checker = _getPermissionChecker();
    return checker.canModify();
  }
  
  /// 檢查是否可以編輯（新增/刪除動作、調整重量組數）
  @override
  bool canEdit() {
    final checker = _getPermissionChecker();
    return checker.canEdit();
  }
  
  /// 檢查是否可以勾選完成
  @override
  bool canToggleCompletion() {
    final checker = _getPermissionChecker();
    return checker.canToggleCompletion();
  }
  
  /// 檢查是否為過去的訓練
  @override
  bool isPastDate() => _dataManager.isPastDate;
  
  /// 檢查是否為未來的訓練
  @override
  bool isFutureDate() => _dataManager.isFutureDate;
  
  /// 檢查是否為今天的訓練
  @override
  bool isToday() => _dataManager.isToday;
  
  /// 獲取權限檢查器
  WorkoutExecutionPermissionChecker _getPermissionChecker() {
    return WorkoutExecutionPermissionChecker(
      isToday: _dataManager.isToday,
      isPastDate: _dataManager.isPastDate,
      isFutureDate: _dataManager.isFutureDate,
    );
  }
  
  /// 切換組數完成狀態
  @override
  void toggleSetCompletion(int exerciseIndex, int setIndex, {BuildContext? context}) async {
    if (!canModify()) {
      if (context != null) {
        NotificationUtils.showWarning(context, _dataManager.getPastDateMessage());
      }
      return;
    }
    
    if (exerciseIndex >= _dataManager.exerciseRecords.length) return;
    
    // 使用子模組處理組數切換
    _dataManager.exerciseRecords[exerciseIndex] = WorkoutExecutionSetOperations.toggleSetCompletion(
      _dataManager.exerciseRecords[exerciseIndex],
      setIndex,
    );
    
    _isDataChanged = true;
    notifyListeners();
    
    // 自動保存打勾狀態
    await _autoSaveCheckboxState();
  }
  
  /// 自動保存打勾狀態（不顯示「完成訓練」提示）
  Future<void> _autoSaveCheckboxState() async {
    final userId = _authController.user?.uid;
    if (userId == null) return;
    
    final success = await _autoSave.saveCheckboxState(
      workoutRecordId: _dataManager.workoutRecordId,
      userId: userId,
      exerciseRecords: _dataManager.exerciseRecords,
      notes: _dataManager.notesController.text,
      overallCompleted: allExercisesCompleted(),
    );
    
    if (success) {
      _isDataChanged = false;
    }
  }
  
  /// 更新組數數據
  @override
  Future<void> updateSetData(
    int exerciseIndex, 
    int setIndex, 
    int reps, 
    double weight,
    {BuildContext? context}
  ) async {
    if (!canModify()) {
      if (context != null) {
        NotificationUtils.showWarning(context, _dataManager.getPastDateMessage());
      }
      return;
    }
    
    if (exerciseIndex >= _dataManager.exerciseRecords.length) return;
    
    // 使用子模組更新組數數據
    _dataManager.exerciseRecords[exerciseIndex] = WorkoutExecutionSetOperations.updateSetData(
      _dataManager.exerciseRecords[exerciseIndex],
      setIndex,
      reps,
      weight,
    );
    
    _isDataChanged = true;
    notifyListeners();
    
    if (context != null) {
      NotificationUtils.showInfo(context, '已更新組數數據，完成訓練後將保存所有更改');
    }
  }
  
  /// 添加運動備註
  @override
  Future<void> addExerciseNote(
    int exerciseIndex, 
    String note,
    {BuildContext? context}
  ) async {
    if (!canModify()) {
      if (context != null) {
        NotificationUtils.showWarning(context, _dataManager.getPastDateMessage());
      }
      return;
    }
    
    if (exerciseIndex >= _dataManager.exerciseRecords.length) return;
    
    // 使用子模組添加備註
    _dataManager.exerciseRecords[exerciseIndex] = WorkoutExecutionSetOperations.addExerciseNote(
      _dataManager.exerciseRecords[exerciseIndex],
      note,
    );
    
    _isDataChanged = true;
    notifyListeners();
    
    if (context != null) {
      NotificationUtils.showInfo(context, '已更新運動備註，完成訓練後將保存所有更改');
    }
  }
  
  /// 添加新訓練動作
  @override
  Future<void> addNewExercise(
    Exercise exercise, 
    int sets, 
    int reps, 
    double weight, 
    int restTime,
    {BuildContext? context}
  ) async {
    if (_dataManager.isPastDate) {
      if (context != null) {
        NotificationUtils.showWarning(context, _dataManager.getPastDateMessage());
      }
      return;
    }
    
    try {
      // 使用子模組創建運動記錄
      final newExercise = WorkoutExecutionExerciseBuilder.createExerciseRecord(
        exercise,
        sets,
        reps,
        weight,
        restTime,
      );
      
      // 添加新運動到列表
      _dataManager.exerciseRecords.add(newExercise);
      // 新添加的運動自動成為當前運動
      _dataManager.setCurrentExerciseIndex(_dataManager.exerciseRecords.length - 1);
      // 標記數據已變更
      _isDataChanged = true;
      
      notifyListeners();
      
      if (context != null) {
        NotificationUtils.showSuccess(
          context, 
          '已添加新運動：${exercise.name}',
          onAction: () => saveWorkoutRecord(context: context),
          actionLabel: '保存',
        );
      }
    } catch (e) {
      _handleError('添加運動失敗', e);
      
      if (context != null) {
        NotificationUtils.showError(context, '添加運動失敗: $e');
      }
    }
  }
  
  /// 新增組數到指定運動
  @override
  Future<void> addSetToExercise(int exerciseIndex, {BuildContext? context}) async {
    if (!canModify()) {
      if (context != null) {
        NotificationUtils.showWarning(context, _dataManager.getPastDateMessage());
      }
      return;
    }
    
    if (exerciseIndex >= _dataManager.exerciseRecords.length) return;
    
    // 使用子模組添加組數
    _dataManager.exerciseRecords[exerciseIndex] = WorkoutExecutionSetOperations.addSetToExercise(
      _dataManager.exerciseRecords[exerciseIndex],
    );
    
    _isDataChanged = true;
    notifyListeners();
    
    // 自動保存新增的組數
    await _autoSaveCheckboxState();
    
    if (context != null) {
      final newSetNumber = _dataManager.exerciseRecords[exerciseIndex].sets.length;
      NotificationUtils.showSuccess(context, '已新增第 $newSetNumber 組');
    }
  }
  
  /// 刪除訓練動作
  @override
  Future<void> deleteExercise(int exerciseIndex, {BuildContext? context}) async {
    if (_dataManager.isPastDate) {
      if (context != null) {
        NotificationUtils.showWarning(context, _dataManager.getPastDateMessage());
      }
      return;
    }
    
    if (exerciseIndex >= _dataManager.exerciseRecords.length) return;
    
    final exerciseName = _dataManager.exerciseRecords[exerciseIndex].exerciseName;
    
    // 刪除運動
    _dataManager.exerciseRecords.removeAt(exerciseIndex);
    
    // 調整當前運動索引
    if (_dataManager.currentExerciseIndex >= _dataManager.exerciseRecords.length) {
      _dataManager.setCurrentExerciseIndex(
        _dataManager.exerciseRecords.isEmpty ? 0 : _dataManager.exerciseRecords.length - 1
      );
    }
    
    // 標記數據已變更
    _isDataChanged = true;
    notifyListeners();
    
    if (context != null) {
      NotificationUtils.showInfo(context, '已刪除運動：$exerciseName，完成訓練後將保存所有更改');
    }
  }
  
  /// 設置訓練時間
  @override
  Future<void> setTrainingHour(int hour, {BuildContext? context}) async {
    // 檢查權限
    final checker = _getPermissionChecker();
    if (!checker.canModifyTime()) {
      if (context != null) {
        NotificationUtils.showWarning(context, '無法修改過去訓練的時間');
      }
      return;
    }
    
    try {
      _dataManager.setTrainingHour(hour);
      _isDataChanged = true;
      notifyListeners();
      
      if (context != null) {
        NotificationUtils.showSuccess(context, '訓練時間已設定為 ${hour.toString().padLeft(2, '0')}:00，完成訓練後將保存更改');
      }
    } catch (e) {
      _handleError('設置訓練時間失敗', e);
      
      if (context != null) {
        NotificationUtils.showError(context, '設置訓練時間失敗: $e');
      }
    }
  }
  
  /// 保存訓練記錄
  @override
  Future<bool> saveWorkoutRecord({BuildContext? context}) async {
    _setSaving(true);
    
    try {
      // 當前用戶ID
      final userId = _authController.user?.uid;
      if (userId == null) {
        throw Exception('未登入');
      }
      
      // 計算訓練時間
      DateTime? trainingTime;
      if (_dataManager.hasScheduledTime && _dataManager.trainingHour != null) {
        final planDate = _dataManager.planDate ?? DateTime.now();
        trainingTime = DateTime(
          planDate.year,
          planDate.month,
          planDate.day,
          _dataManager.trainingHour!,
        );
      }
      
      // 使用子模組保存記錄
      final success = await _recordSaver.saveRecord(
        workoutRecordId: _dataManager.workoutRecordId,
        userId: userId,
        exerciseRecords: _dataManager.exerciseRecords,
        notes: _dataManager.notesController.text,
        overallCompleted: allExercisesCompleted(),
        planDate: _dataManager.planDate,
        trainingTime: trainingTime,
        context: context,
      );
      
      if (success) {
        _isDataChanged = false;
      }
      
      _setSaving(false);
      return success;
    } catch (e) {
      _handleError('保存訓練記錄失敗', e);
      return false;
    }
  }
  
  /// 計算總組數
  @override
  int calculateTotalSets() => _dataManager.calculateTotalSets();
  
  /// 計算總訓練量
  @override
  double calculateTotalVolume() => _dataManager.calculateTotalVolume();
  
  /// 檢查所有運動是否已完成
  @override
  bool allExercisesCompleted() => _dataManager.allExercisesCompleted();
  
  /// 釋放資源
  @override
  void dispose() {
    _dataManager.dispose();
    super.dispose();
  }
} 