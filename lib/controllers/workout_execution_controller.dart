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
class WorkoutExecutionController extends ChangeNotifier
    implements IWorkoutExecutionController {
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
  })  : _workoutService = workoutService ?? serviceLocator<IWorkoutService>(),
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
    _errorService.logError('$message: $error',
        type: 'WorkoutExecutionControllerError');
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

      // ⭐ v2.0 Phase 4C: 保存教練學員信息
      _dataManager.traineeId = record.traineeId;
      _dataManager.creatorId = record.creatorId;

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

      // ⭐ v2.9.1: 根據實際勾選狀態決定訓練狀態
      // 這是唯一的真相來源，不依賴資料庫的舊 training_status
      String effectiveStatus;
      final actuallyCompleted = allExercisesCompleted(); // 實際是否全部完成

      if (actuallyCompleted) {
        // 全部勾選 → completed
        effectiveStatus = 'completed';
      } else if (record.trainingStatus == 'pending' &&
          record.exerciseRecords
              .every((e) => e.sets.every((s) => !s.completed))) {
        // 完全沒有任何勾選 → pending
        effectiveStatus = 'pending';
      } else {
        // 有部分勾選但沒全部完成 → paused（讓用戶確認繼續）
        effectiveStatus = 'paused';
      }

      print(
          '[WorkoutExecutionController] 實際完成狀態: $actuallyCompleted, 決定狀態: $effectiveStatus');

      _dataManager.initFromRecord(
        trainingStatus: effectiveStatus,
        elapsedSeconds: record.elapsedSeconds,
        actualStartTime: record.actualStartTime,
        actualEndTime: record.actualEndTime,
      );

      print(
          '[WorkoutExecutionController] 訓練計畫載入完成，動作數量: ${_dataManager.exerciseRecords.length}');
      print(
          '[WorkoutExecutionController] 訓練狀態: $effectiveStatus, 累計秒數: ${record.elapsedSeconds}');

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

  /// 檢查是否可以編輯（修改重量/次數/新增動作/新增組數）
  @override
  bool canEdit() {
    final checker = _getPermissionChecker();
    return checker.canEdit();
  }

  /// ⭐ v2.9: 檢查是否可以刪除（刪除動作/刪除計畫）
  ///
  /// 只有創建者可以刪除，學員不能刪除教練創建的
  @override
  bool canDelete() {
    final checker = _getPermissionChecker();
    return checker.canDelete();
  }

  /// 檢查是否可以勾選完成
  /// ⭐ v2.9.1:
  /// - 教練查看學員訓練時：永遠不能打勾
  /// - 過去的訓練：不能打勾
  /// - 未來的訓練：不能打勾
  /// - 今天的訓練（traineeId 是自己）：需在 in_progress 狀態
  @override
  bool canToggleCompletion() {
    // ⭐ 教練永遠不能幫學員打勾
    if (isCoachViewingTrainee()) {
      return false;
    }

    // ⭐ 過去的訓練不能修改
    if (isPastDate()) {
      return false;
    }

    // ⭐ 未來的訓練不能打勾（只能規劃）
    if (isFutureDate()) {
      return false;
    }

    // ⭐ 今天的訓練：需要先「開始訓練」才能打勾
    if (shouldShowTimerUI()) {
      if (_dataManager.isPaused || _dataManager.isPending) {
        return false;
      }
    }

    return true;
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

  /// 檢查是否為教練查看學員訓練
  ///
  /// 當前用戶不是訓練對象（traineeId）時，表示是教練在查看學員訓練
  @override
  bool isCoachViewingTrainee() {
    final currentUserId = _authController.user?.uid;
    // ⭐ v2.9 修正：只要當前用戶不是 traineeId，就是教練查看學員
    return _dataManager.traineeId != null &&
        currentUserId != _dataManager.traineeId;
  }

  /// ⭐ v2.9: 檢查是否正在查看別人創建的計畫
  ///
  /// 當前用戶不是創建者時，不能刪除動作或計畫
  @override
  bool isViewingOthersCreatedPlan() {
    final currentUserId = _authController.user?.uid;
    return _dataManager.creatorId != null &&
        currentUserId != _dataManager.creatorId;
  }

  /// ⭐ v2.9.1: 是否應該顯示計時器 UI
  ///
  /// 只有「今天」且「不是教練查看學員」的情況才顯示計時功能
  @override
  bool shouldShowTimerUI() {
    // 只有今天的訓練才顯示計時功能
    if (!isToday()) return false;

    // 教練查看學員訓練時不顯示
    if (isCoachViewingTrainee()) return false;

    return true;
  }

  /// 獲取權限檢查器
  WorkoutExecutionPermissionChecker _getPermissionChecker() {
    final currentUserId = _authController.user?.uid;

    // ⭐ v2.9: 教練查看學員訓練（當前用戶不是 traineeId）
    final isCoachViewingTrainee = _dataManager.traineeId != null &&
        currentUserId != _dataManager.traineeId;

    // ⭐ v2.9: 查看別人創建的計畫（當前用戶不是 creatorId）
    final isViewingOthersCreatedPlan = _dataManager.creatorId != null &&
        currentUserId != _dataManager.creatorId;

    return WorkoutExecutionPermissionChecker(
      isToday: _dataManager.isToday,
      isPastDate: _dataManager.isPastDate,
      isFutureDate: _dataManager.isFutureDate,
      isCoachViewingTrainee: isCoachViewingTrainee,
      isViewingOthersCreatedPlan: isViewingOthersCreatedPlan,
    );
  }

  /// 切換組數完成狀態
  /// ⭐ v2.9.1: 自動完成/取消時轉 paused
  @override
  void toggleSetCompletion(int exerciseIndex, int setIndex,
      {BuildContext? context}) async {
    if (!canModify()) {
      if (context != null) {
        NotificationUtils.showWarning(
            context, _dataManager.getPastDateMessage());
      }
      return;
    }

    if (exerciseIndex >= _dataManager.exerciseRecords.length) return;

    final wasCompleted = _dataManager.isCompleted;
    final currentSet =
        _dataManager.exerciseRecords[exerciseIndex].sets[setIndex];
    final isUnchecking = currentSet.completed; // 即將取消勾選

    // 使用子模組處理組數切換
    _dataManager.exerciseRecords[exerciseIndex] =
        WorkoutExecutionSetOperations.toggleSetCompletion(
      _dataManager.exerciseRecords[exerciseIndex],
      setIndex,
    );

    // ⭐ v2.9.1: 根據勾選狀態自動轉換訓練狀態
    if (allExercisesCompleted()) {
      // 全部完成 → completed
      if (!_dataManager.isCompleted) {
        _dataManager.completeTraining();
        if (context != null && context.mounted) {
          NotificationUtils.showSuccess(context, '🎉 訓練完成！做得好！');
        }
      }
    } else if (wasCompleted && isUnchecking) {
      // 從完成狀態取消勾選 → paused（等待用戶確認繼續）
      _dataManager.trainingStatus = 'paused';
      if (context != null && context.mounted) {
        NotificationUtils.showInfo(context, '已取消完成，點擊「繼續訓練」恢復計時');
      }
    }

    _isDataChanged = true;
    notifyListeners();

    // 自動保存打勾狀態
    await _autoSaveCheckboxState();
  }

  /// 自動保存打勾狀態（不顯示「完成訓練」提示）
  Future<void> _autoSaveCheckboxState() async {
    final userId = _authController.user?.uid;
    if (userId == null) return;

    // ⭐ v2.9.1: 包含訓練狀態追蹤欄位
    final success = await _autoSave.saveCheckboxState(
      workoutRecordId: _dataManager.workoutRecordId,
      userId: userId,
      exerciseRecords: _dataManager.exerciseRecords,
      notes: _dataManager.notesController.text,
      overallCompleted: allExercisesCompleted(),
      // ⭐ v2.9.1: 訓練狀態追蹤
      trainingStatus: _dataManager.trainingStatus,
      elapsedSeconds: _dataManager.elapsedSeconds,
      actualStartTime: _dataManager.actualStartTime,
      actualEndTime: _dataManager.actualEndTime,
    );

    if (success) {
      _isDataChanged = false;
    }
  }

  /// 更新組數數據
  @override
  Future<void> updateSetData(
      int exerciseIndex, int setIndex, int reps, double weight,
      {BuildContext? context}) async {
    if (!canModify()) {
      if (context != null) {
        NotificationUtils.showWarning(
            context, _dataManager.getPastDateMessage());
      }
      return;
    }

    if (exerciseIndex >= _dataManager.exerciseRecords.length) return;

    // 使用子模組更新組數數據
    _dataManager.exerciseRecords[exerciseIndex] =
        WorkoutExecutionSetOperations.updateSetData(
      _dataManager.exerciseRecords[exerciseIndex],
      setIndex,
      reps,
      weight,
    );

    _isDataChanged = true;
    notifyListeners();

    // 🐛 修復：移除「已更新數據組」通知（避免干擾用戶）
  }

  /// 添加運動備註
  @override
  Future<void> addExerciseNote(int exerciseIndex, String note,
      {BuildContext? context}) async {
    if (!canModify()) {
      if (context != null) {
        NotificationUtils.showWarning(
            context, _dataManager.getPastDateMessage());
      }
      return;
    }

    if (exerciseIndex >= _dataManager.exerciseRecords.length) return;

    // 使用子模組添加備註
    _dataManager.exerciseRecords[exerciseIndex] =
        WorkoutExecutionSetOperations.addExerciseNote(
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
      Exercise exercise, int sets, int reps, double weight, int restTime,
      {BuildContext? context}) async {
    // ⚡ 使用統一的權限檢查（支援教練編輯學員訓練）
    if (!canEdit()) {
      if (context != null) {
        NotificationUtils.showWarning(context, '無法編輯過去的訓練記錄');
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
      _dataManager
          .setCurrentExerciseIndex(_dataManager.exerciseRecords.length - 1);
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
  Future<void> addSetToExercise(int exerciseIndex,
      {BuildContext? context}) async {
    // ⚡ 使用統一的權限檢查（今天和未來都可以編輯，教練也可以）
    if (!canEdit()) {
      if (context != null) {
        NotificationUtils.showWarning(context, '無法編輯過去的訓練記錄');
      }
      return;
    }

    if (exerciseIndex >= _dataManager.exerciseRecords.length) return;

    // 使用子模組添加組數
    _dataManager.exerciseRecords[exerciseIndex] =
        WorkoutExecutionSetOperations.addSetToExercise(
      _dataManager.exerciseRecords[exerciseIndex],
    );

    _isDataChanged = true;
    notifyListeners();

    // 自動保存新增的組數
    await _autoSaveCheckboxState();

    if (context != null) {
      final newSetNumber =
          _dataManager.exerciseRecords[exerciseIndex].sets.length;
      NotificationUtils.showSuccess(context, '已新增第 $newSetNumber 組');
    }
  }

  /// ⭐ v2.9.1 TRN-2: 減少組數（只有創建者可以）
  @override
  Future<void> removeSetFromExercise(int exerciseIndex,
      {BuildContext? context}) async {
    // 權限檢查：只有創建者可以減少組數
    if (!canDelete()) {
      if (context != null) {
        NotificationUtils.showWarning(context, '無法減少教練安排的組數，如需調整請聯繫教練');
      }
      return;
    }

    if (exerciseIndex >= _dataManager.exerciseRecords.length) return;

    final currentSets = _dataManager.exerciseRecords[exerciseIndex].sets.length;
    if (currentSets <= 1) {
      if (context != null) {
        NotificationUtils.showWarning(context, '至少需要保留 1 組');
      }
      return;
    }

    // 使用子模組減少組數
    _dataManager.exerciseRecords[exerciseIndex] =
        WorkoutExecutionSetOperations.removeSetFromExercise(
      _dataManager.exerciseRecords[exerciseIndex],
    );

    _isDataChanged = true;
    notifyListeners();

    // 自動保存
    await _autoSaveCheckboxState();

    if (context != null) {
      final newSetNumber =
          _dataManager.exerciseRecords[exerciseIndex].sets.length;
      NotificationUtils.showInfo(context, '已減少為 $newSetNumber 組');
    }
  }

  /// 刪除訓練動作
  @override
  Future<void> deleteExercise(int exerciseIndex,
      {BuildContext? context}) async {
    // ⚡ 使用統一的權限檢查（支援教練編輯學員訓練）
    if (!canEdit()) {
      if (context != null) {
        NotificationUtils.showWarning(context, '無法編輯過去的訓練記錄');
      }
      return;
    }

    if (exerciseIndex >= _dataManager.exerciseRecords.length) return;

    final exerciseName =
        _dataManager.exerciseRecords[exerciseIndex].exerciseName;

    // 刪除運動
    _dataManager.exerciseRecords.removeAt(exerciseIndex);

    // 調整當前運動索引
    if (_dataManager.currentExerciseIndex >=
        _dataManager.exerciseRecords.length) {
      _dataManager.setCurrentExerciseIndex(_dataManager.exerciseRecords.isEmpty
          ? 0
          : _dataManager.exerciseRecords.length - 1);
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
        NotificationUtils.showSuccess(context,
            '訓練時間已設定為 ${hour.toString().padLeft(2, '0')}:00，完成訓練後將保存更改');
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
      // ⭐ v2.9.1: 包含訓練狀態追蹤欄位
      final success = await _recordSaver.saveRecord(
        workoutRecordId: _dataManager.workoutRecordId,
        userId: userId,
        exerciseRecords: _dataManager.exerciseRecords,
        notes: _dataManager.notesController.text,
        overallCompleted: allExercisesCompleted(),
        planDate: _dataManager.planDate,
        trainingTime: trainingTime,
        // ⭐ v2.9.1: 訓練狀態追蹤
        trainingStatus: _dataManager.trainingStatus,
        elapsedSeconds: _dataManager.elapsedSeconds,
        actualStartTime: _dataManager.actualStartTime,
        actualEndTime: _dataManager.actualEndTime,
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

  // =============================================
  // ⭐ v2.9.1: 訓練狀態追蹤實作
  // =============================================

  /// 獲取訓練狀態
  @override
  String get trainingStatus => _dataManager.trainingStatus;

  /// 獲取累計訓練秒數
  @override
  int get elapsedSeconds => _dataManager.tickElapsedTime();

  /// 獲取實際開始時間
  @override
  DateTime? get actualStartTime => _dataManager.actualStartTime;

  /// 是否處於準備模式
  @override
  bool get isPending => _dataManager.isPending;

  /// 是否正在進行中
  @override
  bool get isInProgress => _dataManager.isInProgress;

  /// 是否已暫停
  @override
  bool get isPaused => _dataManager.isPaused;

  /// 是否已完成
  @override
  bool get isCompleted => _dataManager.isCompleted;

  /// 開始訓練（pending → in_progress）
  @override
  Future<void> startTraining() async {
    if (!_dataManager.isPending) return;

    _dataManager.startTraining();
    notifyListeners();

    // 保存狀態到資料庫
    await _saveTrainingStatus();
  }

  /// 暫停訓練（in_progress → paused）
  @override
  Future<void> pauseTraining() async {
    if (!_dataManager.isInProgress) return;

    _dataManager.pauseTraining();
    notifyListeners();

    // 保存狀態到資料庫
    await _saveTrainingStatus();
  }

  /// 繼續訓練（paused → in_progress）
  @override
  Future<void> resumeTraining() async {
    if (!_dataManager.isPaused) return;

    _dataManager.resumeTraining();
    notifyListeners();

    // 保存狀態到資料庫
    await _saveTrainingStatus();
  }

  /// 保存並離開（全部完成 → completed，否則 → paused）
  /// ⭐ v2.9.1: 修改邏輯 - 右上角按鈕 = 保存並離開
  @override
  Future<bool> completeTraining({BuildContext? context}) async {
    // ⭐ v2.9.1: 只有需要顯示計時 UI 時才檢查 pending 狀態
    // 教練編輯學員訓練、過去/未來的訓練都不需要檢查 pending
    if (shouldShowTimerUI() && _dataManager.isPending) {
      return false;
    }

    // 根據勾選狀態決定最終狀態（只有顯示計時 UI 時才處理）
    if (shouldShowTimerUI()) {
      if (allExercisesCompleted()) {
        if (!_dataManager.isCompleted) {
          _dataManager.completeTraining();
        }
        if (context != null && context.mounted) {
          NotificationUtils.showSuccess(context, '🎉 訓練完成！做得好！');
        }
      } else {
        if (!_dataManager.isPaused) {
          _dataManager.pauseTraining();
        }
        if (context != null && context.mounted) {
          NotificationUtils.showInfo(context, '訓練已保存，可隨時返回繼續');
        }
      }
    } else {
      // ⭐ 不顯示計時 UI 時，只提示保存成功
      if (context != null && context.mounted) {
        NotificationUtils.showSuccess(context, '訓練計畫已保存');
      }
    }
    notifyListeners();

    return await saveWorkoutRecord(context: context);
  }

  /// 更新經過時間（每秒呼叫）
  @override
  void tickElapsedTime() {
    if (_dataManager.isInProgress) {
      notifyListeners();
    }
  }

  /// 保存訓練狀態到資料庫
  Future<void> _saveTrainingStatus() async {
    final userId = _authController.user?.uid;
    if (userId == null) return;

    try {
      final existingRecord =
          await _workoutService.getRecordById(_dataManager.workoutRecordId);
      if (existingRecord == null) return;

      final updatedRecord = existingRecord.copyWith(
        trainingStatus: _dataManager.trainingStatus,
        elapsedSeconds: _dataManager.elapsedSeconds,
        actualStartTime: _dataManager.actualStartTime,
        actualEndTime: _dataManager.actualEndTime,
      );

      await _workoutService.updateRecord(updatedRecord);
      print(
          '[WorkoutExecutionController] 訓練狀態已保存: ${_dataManager.trainingStatus}');
    } catch (e) {
      _errorService.logError('保存訓練狀態失敗: $e',
          type: 'WorkoutExecutionControllerError');
    }
  }

  /// 釋放資源
  @override
  void dispose() {
    _dataManager.dispose();
    super.dispose();
  }
}
