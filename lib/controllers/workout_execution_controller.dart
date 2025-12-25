import 'package:flutter/material.dart';
import '../models/workout_record_model.dart';
import '../models/exercise_model.dart';
import '../services/interfaces/i_workout_service.dart';
import '../controllers/interfaces/i_auth_controller.dart';
import '../services/error_handling_service.dart';
import '../services/service_locator.dart';
import 'interfaces/i_workout_execution_controller.dart';

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
  
  // 數據
  String _workoutRecordId = '';
  String _planTitle = '';
  String _planType = '';
  List<ExerciseRecord> _exerciseRecords = [];
  final TextEditingController _notesController = TextEditingController();
  
  // 日期相關
  DateTime? _planDate;
  bool _isToday = false;
  bool _isPastDate = false;
  bool _isFutureDate = false;
  
  // 當前正在進行的運動索引
  int _currentExerciseIndex = 0;
  
  // 時間相關
  int? _trainingHour;
  bool _hasScheduledTime = false;
  
  /// 構造函數，支持依賴注入
  WorkoutExecutionController({
    IWorkoutService? workoutService,
    IAuthController? authController,
    ErrorHandlingService? errorService,
  }) : 
    _workoutService = workoutService ?? serviceLocator<IWorkoutService>(),
    _authController = authController ?? serviceLocator<IAuthController>(),
    _errorService = errorService ?? serviceLocator<ErrorHandlingService>();
  
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
    _workoutRecordId = workoutRecordId;
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
      _planTitle = '訓練記錄'; // WorkoutRecord 沒有 title 欄位，暫時使用預設值
      _planType = '一般訓練'; // WorkoutRecord 沒有 planType 欄位，暫時使用預設值
      
      if (record.notes.isNotEmpty) {
        _notesController.text = record.notes;
      }
      
      // 處理日期信息
      _processDateInfoFromDateTime(record.date);
      
      // 設置運動記錄
      _exerciseRecords = record.exerciseRecords;
      
      print('[WorkoutExecutionController] 訓練計畫載入完成，動作數量: ${_exerciseRecords.length}');
      
      _setLoading(false);
    } catch (e) {
      print('[WorkoutExecutionController] 加載訓練計劃失敗: $e');
      _handleError('加載訓練計劃失敗', e);
    }
  }
  
  /// 處理日期信息（從 DateTime）
  void _processDateInfoFromDateTime(DateTime date) {
    _planDate = date;
    
    // 對比今日日期（僅考慮年月日，不考慮時分秒）
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final planDateOnly = DateTime(_planDate!.year, _planDate!.month, _planDate!.day);
    
    _isToday = planDateOnly.isAtSameMomentAs(todayDate);
    _isPastDate = planDateOnly.isBefore(todayDate);
    _isFutureDate = planDateOnly.isAfter(todayDate);
  }
  
  /// 獲取訓練計劃標題
  @override
  String getPlanTitle() {
    return _planTitle;
  }
  
  /// 獲取訓練計劃類型
  @override
  String getPlanType() {
    return _planType;
  }
  
  /// 獲取訓練備註
  @override
  String getNotes() {
    return _notesController.text;
  }
  
  /// 設置訓練備註
  @override
  void setNotes(String notes) {
    _notesController.text = notes;
    _isDataChanged = true;
    notifyListeners();
  }
  
  /// 獲取運動記錄列表
  @override
  List<ExerciseRecord> getExerciseRecords() {
    return _exerciseRecords;
  }
  
  /// 獲取當前運動索引
  @override
  int getCurrentExerciseIndex() {
    return _currentExerciseIndex;
  }
  
  /// 設置當前運動索引
  @override
  void setCurrentExerciseIndex(int index) {
    if (index >= 0 && index < _exerciseRecords.length) {
      _currentExerciseIndex = index;
      notifyListeners();
    }
  }
  
  /// 檢查是否可以修改訓練
  @override
  bool canModify() {
    // 如果是今天的訓練，允許修改
    return _isToday && !_isPastDate && !_isFutureDate;
  }
  
  /// 檢查是否可以編輯（新增/刪除動作、調整重量組數）
  /// 過去的訓練不能編輯，今天和未來的可以編輯
  @override
  bool canEdit() {
    return !_isPastDate; // 只要不是過去的，都可以編輯
  }
  
  /// 檢查是否可以勾選完成（只有今天的訓練可以勾選完成）
  @override
  bool canToggleCompletion() {
    return _isToday; // 只有今天的訓練可以勾選完成
  }
  
  /// 檢查是否為過去的訓練
  @override
  bool isPastDate() {
    return _isPastDate;
  }
  
  /// 檢查是否為未來的訓練
  @override
  bool isFutureDate() {
    return _isFutureDate;
  }
  
  /// 檢查是否為今天的訓練
  @override
  bool isToday() {
    return _isToday;
  }
  
  /// 切換組數完成狀態
  @override
  void toggleSetCompletion(int exerciseIndex, int setIndex, {BuildContext? context}) async {
    if (!canModify()) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getPastDateMessage())),
        );
      }
      return;
    }
    
    if (exerciseIndex >= _exerciseRecords.length) return;
    
    final exercise = _exerciseRecords[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;
    
    // 更新本地狀態
    final updatedSets = List<SetRecord>.from(exercise.sets);
    updatedSets[setIndex] = exercise.sets[setIndex].copyWith(
      completed: !exercise.sets[setIndex].completed,
    );
    
    // 檢查是否所有組數都已完成
    final allSetsCompleted = updatedSets.every((set) => set.completed);
    
    _exerciseRecords[exerciseIndex] = exercise.copyWith(
      sets: updatedSets,
      completed: allSetsCompleted,
    );
    
    _isDataChanged = true;
    notifyListeners();
    
    // 自動保存打勾狀態到 Firebase
    await _autoSaveCheckboxState();
  }
  
  /// 自動保存打勾狀態（不顯示「完成訓練」提示）
  Future<void> _autoSaveCheckboxState() async {
    try {
      final userId = _authController.user?.uid;
      if (userId == null) {
        print('[WorkoutExecutionController] 自動保存失敗：用戶未登入');
        return;
      }
      
      // 計算整體完成狀態
      final overallCompleted = allExercisesCompleted();
      
      print('[WorkoutExecutionController] 自動保存打勾狀態，workoutRecordId: $_workoutRecordId');
      
      // 獲取現有記錄
      final existingRecord = await _workoutService.getRecordById(_workoutRecordId);
      
      if (existingRecord != null) {
        // 更新記錄
        final updatedRecord = WorkoutRecord(
          id: _workoutRecordId,
          workoutPlanId: existingRecord.workoutPlanId,
          userId: userId,
          date: existingRecord.date,
          exerciseRecords: _exerciseRecords,
          notes: _notesController.text,
          completed: overallCompleted,
          createdAt: existingRecord.createdAt,
          trainingTime: existingRecord.trainingTime,
        );
        
        await _workoutService.updateRecord(updatedRecord);
        print('[WorkoutExecutionController] 自動保存成功');
      } else {
        print('[WorkoutExecutionController] 找不到訓練記錄: $_workoutRecordId');
      }
      
      _isDataChanged = false;
    } catch (e) {
      // 靜默失敗，不影響用戶體驗
      print('[WorkoutExecutionController] 自動保存打勾狀態失敗: $e');
    }
  }
  
  /// 獲取無法修改訓練的提示信息
  String _getPastDateMessage() {
    if (_isPastDate) {
      return '無法修改過去的訓練記錄';
    } else if (_isFutureDate) {
      return '無法修改未來的訓練記錄，請在訓練當天進行操作';
    }
    return '無法修改訓練記錄';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getPastDateMessage())),
        );
      }
      return;
    }
    
    if (exerciseIndex >= _exerciseRecords.length) return;
    
    final exercise = _exerciseRecords[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;
    
    final currentSet = exercise.sets[setIndex];
    
    // 更新本地狀態
    final updatedSets = List<SetRecord>.from(exercise.sets);
    updatedSets[setIndex] = currentSet.copyWith(
      reps: reps,
      weight: weight,
    );
    
    _exerciseRecords[exerciseIndex] = exercise.copyWith(
      sets: updatedSets,
    );
    
    _isDataChanged = true;
    notifyListeners();
    
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已更新組數數據，完成訓練後將保存所有更改')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getPastDateMessage())),
        );
      }
      return;
    }
    
    if (exerciseIndex >= _exerciseRecords.length) return;
    
    final exercise = _exerciseRecords[exerciseIndex];
    
    // 更新本地狀態
    _exerciseRecords[exerciseIndex] = exercise.copyWith(
      notes: note,
    );
    
    _isDataChanged = true;
    notifyListeners();
    
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已更新運動備註，完成訓練後將保存所有更改')),
      );
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
    if (_isPastDate) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getPastDateMessage())),
        );
      }
      return;
    }
    
    try {
      // 創建組數記錄
      final setRecords = <SetRecord>[];
      for (int i = 0; i < sets; i++) {
        setRecords.add(SetRecord(
          setNumber: i + 1,
          reps: reps,
          weight: weight,
          restTime: restTime,
          completed: false,
        ));
      }
      
      // 創建運動記錄
      final newExercise = ExerciseRecord(
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        sets: setRecords,
        notes: '',
        completed: false,
      );
      
      // 添加新運動到列表
      _exerciseRecords.add(newExercise);
      // 新添加的運動自動成為當前運動
      _currentExerciseIndex = _exerciseRecords.length - 1;
      // 標記數據已變更
      _isDataChanged = true;
      
      notifyListeners();
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已添加新運動：${exercise.name}'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: '保存',
              onPressed: () {
                saveWorkoutRecord(context: context);
              },
            ),
          ),
        );
      }
    } catch (e) {
      _handleError('添加運動失敗', e);
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加運動失敗: $e')),
        );
      }
    }
  }
  
  /// 新增組數到指定運動
  @override
  Future<void> addSetToExercise(int exerciseIndex, {BuildContext? context}) async {
    if (!canModify()) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getPastDateMessage())),
        );
      }
      return;
    }
    
    if (exerciseIndex >= _exerciseRecords.length) return;
    
    final exercise = _exerciseRecords[exerciseIndex];
    
    // 複製最後一組的數據作為新組的預設值
    final lastSet = exercise.sets.isNotEmpty 
        ? exercise.sets.last 
        : SetRecord(
            setNumber: 1,
            reps: 10,
            weight: 0.0,
            restTime: 60,
            completed: false,
            note: '',
          );
    
    // 創建新的組數記錄
    final newSet = SetRecord(
      setNumber: exercise.sets.length + 1,
      reps: lastSet.reps,
      weight: lastSet.weight,
      restTime: lastSet.restTime,
      completed: false,
      note: '',
    );
    
    // 更新運動記錄
    final updatedSets = List<SetRecord>.from(exercise.sets)..add(newSet);
    _exerciseRecords[exerciseIndex] = exercise.copyWith(sets: updatedSets);
    
    _isDataChanged = true;
    notifyListeners();
    
    // 自動保存新增的組數
    await _autoSaveCheckboxState();
    
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已新增第 ${newSet.setNumber} 組')),
      );
    }
  }
  
  /// 刪除訓練動作
  @override
  Future<void> deleteExercise(int exerciseIndex, {BuildContext? context}) async {
    if (_isPastDate) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getPastDateMessage())),
        );
      }
      return;
    }
    
    if (exerciseIndex >= _exerciseRecords.length) return;
    
    final exerciseName = _exerciseRecords[exerciseIndex].exerciseName;
    
    // 刪除運動
    _exerciseRecords.removeAt(exerciseIndex);
    
    // 調整當前運動索引
    if (_currentExerciseIndex >= _exerciseRecords.length) {
      _currentExerciseIndex = _exerciseRecords.isEmpty ? 0 : _exerciseRecords.length - 1;
    }
    
    // 標記數據已變更
    _isDataChanged = true;
    notifyListeners();
    
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已刪除運動：$exerciseName，完成訓練後將保存所有更改')),
      );
    }
  }
  
  /// 設置訓練時間
  @override
  Future<void> setTrainingHour(int hour, {BuildContext? context}) async {
    // 是否允許修改
    final canModifyTime = !_isPastDate;
    
    if (!canModifyTime) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法修改過去訓練的時間')),
        );
      }
      return;
    }
    
    try {
      _trainingHour = hour;
      _hasScheduledTime = true;
      _isDataChanged = true;
      notifyListeners();
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('訓練時間已設定為 ${hour.toString().padLeft(2, '0')}:00，完成訓練後將保存更改')),
        );
      }
    } catch (e) {
      _handleError('設置訓練時間失敗', e);
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('設置訓練時間失敗: $e')),
        );
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
      
      print('[WorkoutExecutionController] 保存訓練記錄: $_workoutRecordId');
      
      // 計算整體完成狀態
      final overallCompleted = allExercisesCompleted();
      
      // 獲取現有記錄
      final existingRecord = await _workoutService.getRecordById(_workoutRecordId);
      
      if (existingRecord != null) {
        // 更新現有記錄
        final updatedRecord = WorkoutRecord(
          id: _workoutRecordId,
          workoutPlanId: existingRecord.workoutPlanId,
          userId: userId,
          date: existingRecord.date,
          exerciseRecords: _exerciseRecords,
          notes: _notesController.text,
          completed: overallCompleted,
          createdAt: existingRecord.createdAt,
          trainingTime: existingRecord.trainingTime ?? (_hasScheduledTime && _trainingHour != null 
              ? DateTime(existingRecord.date.year, existingRecord.date.month, existingRecord.date.day, _trainingHour!)
              : null),
        );
        
        final success = await _workoutService.updateRecord(updatedRecord);
        
        if (!success) {
          throw Exception('更新訓練記錄失敗');
        }
        
        print('[WorkoutExecutionController] 訓練記錄更新成功');
      } else {
        // 創建新記錄（理論上不應該走到這裡，因為 loadWorkoutPlan 應該已經確保記錄存在）
        print('[WorkoutExecutionController] 警告：找不到現有記錄，創建新記錄');
        
        final newRecord = WorkoutRecord(
          id: _workoutRecordId, // 使用傳入的 ID
          workoutPlanId: _workoutRecordId,
          userId: userId,
          date: _planDate ?? DateTime.now(),
          exerciseRecords: _exerciseRecords,
          notes: _notesController.text,
          completed: overallCompleted,
          createdAt: DateTime.now(),
          trainingTime: _hasScheduledTime && _trainingHour != null 
              ? DateTime((_planDate ?? DateTime.now()).year, (_planDate ?? DateTime.now()).month, (_planDate ?? DateTime.now()).day, _trainingHour!)
              : null,
        );
        
        await _workoutService.createRecord(newRecord);
        print('[WorkoutExecutionController] 新訓練記錄創建成功');
      }
      
      // 標記數據已保存
      _isDataChanged = false;
      _setSaving(false);
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('訓練記錄已保存')),
        );
      }
      
      return true;
    } catch (e, stackTrace) {
      print('[WorkoutExecutionController] 保存訓練記錄失敗: $e');
      print('[WorkoutExecutionController] Stack trace: $stackTrace');
      _handleError('保存訓練記錄失敗', e);
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存訓練記錄失敗: $e')),
        );
      }
      
      return false;
    }
  }
  
  /// 計算總組數
  @override
  int calculateTotalSets() {
    int totalSets = 0;
    for (var exercise in _exerciseRecords) {
      totalSets += exercise.sets.length;
    }
    return totalSets;
  }
  
  /// 計算總訓練量
  @override
  double calculateTotalVolume() {
    double totalVolume = 0;
    for (var exercise in _exerciseRecords) {
      for (var set in exercise.sets) {
        if (set.completed) {
          totalVolume += set.weight * set.reps;
        }
      }
    }
    return totalVolume;
  }
  
  /// 檢查所有運動是否已完成
  @override
  bool allExercisesCompleted() {
    if (_exerciseRecords.isEmpty) return false;
    return _exerciseRecords.every((exercise) => exercise.completed);
  }
} 