import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_record_model.dart';
import '../models/exercise_model.dart';
import '../services/interfaces/i_workout_service.dart';
import '../services/error_handling_service.dart';
import '../services/service_locator.dart';
import 'interfaces/i_workout_execution_controller.dart';

/// 訓練執行控制器實現
///
/// 管理訓練執行頁面的業務邏輯，包括數據加載、狀態管理和操作處理
class WorkoutExecutionController extends ChangeNotifier implements IWorkoutExecutionController {
  // 依賴注入
  final IWorkoutService _workoutService;
  final ErrorHandlingService _errorService;
  
  // 狀態管理
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDataChanged = false;
  String? _errorMessage;
  
  // 數據
  String _workoutRecordId = '';
  Map<String, dynamic>? _workoutPlan;
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
    ErrorHandlingService? errorService,
  }) : 
    _workoutService = workoutService ?? serviceLocator<IWorkoutService>(),
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
      // 從 workoutPlans 集合獲取數據
      final planDoc = await FirebaseFirestore.instance
          .collection('workoutPlans')
          .doc(workoutRecordId)
          .get();

      // 如果找不到，拋出錯誤
      if (!planDoc.exists) {
        throw Exception('無法找到訓練計劃');
      }

      final planData = planDoc.data() as Map<String, dynamic>;
      
      // 設置計劃標題和類型
      _workoutPlan = planData;
      _planTitle = planData['title'] ?? '未命名訓練';
      
      // 從 uiPlanType 或 planType 獲取訓練類型
      _planType = planData['uiPlanType'] ?? planData['planType'] ?? '一般訓練';
      
      if (planData['note'] != null) {
        _notesController.text = planData['note'];
      }
      
      // 處理日期信息
      if (planData['scheduledDate'] != null && planData['scheduledDate'] is Timestamp) {
        _processDateInfo(planData['scheduledDate'] as Timestamp);
      } else if (planData['date'] != null && planData['date'] is Timestamp) {
        _processDateInfo(planData['date'] as Timestamp);
      } else {
        // 如果沒有日期，預設為今天
        _isToday = true;
        _isPastDate = false;
        _isFutureDate = false;
      }
      
      // 直接從文檔創建運動記錄
      final exercises = planData['exercises'] as List<dynamic>? ?? [];
      _exerciseRecords = _processExercises(exercises);
      
      _setLoading(false);
    } catch (e) {
      _handleError('加載訓練計劃失敗', e);
    }
  }
  
  /// 處理日期信息
  void _processDateInfo(Timestamp timestamp) {
    _planDate = timestamp.toDate();
    
    // 對比今日日期（僅考慮年月日，不考慮時分秒）
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final planDateOnly = DateTime(_planDate!.year, _planDate!.month, _planDate!.day);
    
    _isToday = planDateOnly.isAtSameMomentAs(todayDate);
    _isPastDate = planDateOnly.isBefore(todayDate);
    _isFutureDate = planDateOnly.isAfter(todayDate);
  }
  
  /// 處理運動記錄數據
  List<ExerciseRecord> _processExercises(List<dynamic> exercises) {
    final exerciseRecords = <ExerciseRecord>[];
    
    for (final exercise in exercises) {
      try {
        if (exercise is Map<String, dynamic>) {
          // 處理sets數據
          final setsRecords = <SetRecord>[];
          
          // 優先檢查是否有 setTargets（每組單獨設定）
          if (exercise['setTargets'] != null && exercise['setTargets'] is List) {
            final setTargetsList = exercise['setTargets'] as List<dynamic>;
            final restTime = (exercise['restTime'] as num?)?.toInt() ?? 60;
            
            // 檢查是否有保存的組數狀態（只處理 List 類型）
            final savedSets = exercise['sets'] is List ? exercise['sets'] as List<dynamic>? : null;
            
            for (int i = 0; i < setTargetsList.length; i++) {
              final target = setTargetsList[i] as Map<String, dynamic>;
              final targetReps = (target['reps'] as num?)?.toInt() ?? 10;
              final targetWeight = (target['weight'] as num?)?.toDouble() ?? 0.0;
              
              // 如果有保存的狀態，使用保存的 completed 值
              bool completed = false;
              if (savedSets != null && i < savedSets.length && savedSets[i] is Map<String, dynamic>) {
                completed = (savedSets[i] as Map<String, dynamic>)['completed'] ?? false;
              }
              
              setsRecords.add(SetRecord(
                setNumber: i + 1,
                reps: targetReps,
                weight: targetWeight,
                restTime: restTime,
                completed: completed,
                note: '',
              ));
            }
          } else if (exercise['targetSets'] != null) {
            // 新結構: 使用 targetSets, targetReps, targetWeight 字段
            final targetSets = (exercise['targetSets'] as num).toInt();
            final targetReps = (exercise['targetReps'] as num?)?.toInt() ?? 10;
            final targetWeight = (exercise['targetWeight'] as num?)?.toDouble() ?? 0.0;
            final restTime = (exercise['restTime'] as num?)?.toInt() ?? 60;
            
            // 檢查是否有保存的組數狀態（只處理 List 類型）
            final savedSets = exercise['sets'] is List ? exercise['sets'] as List<dynamic>? : null;
            
            for (int i = 0; i < targetSets; i++) {
              // 如果有保存的狀態，使用保存的 completed 值
              bool completed = false;
              if (savedSets != null && i < savedSets.length && savedSets[i] is Map<String, dynamic>) {
                completed = (savedSets[i] as Map<String, dynamic>)['completed'] ?? false;
              }
              
              setsRecords.add(SetRecord(
                setNumber: i + 1,
                reps: targetReps,
                weight: targetWeight,
                restTime: restTime,
                completed: completed,
                note: '',
              ));
            }
          } else if (exercise['sets'] is List) {
            // 舊結構: 如果已經是 List 形式的 sets
            final setsList = exercise['sets'] as List<dynamic>;
            
            if (setsList.isNotEmpty && setsList.first is Map<String, dynamic>) {
              for (final setData in setsList) {
                if (setData is Map<String, dynamic>) {
                  setsRecords.add(SetRecord(
                    setNumber: setData['setNumber'] ?? 0,
                    reps: setData['reps'] ?? 0,
                    weight: (setData['weight'] as num?)?.toDouble() ?? 0.0,
                    restTime: setData['restTime'] ?? 60,
                    completed: setData['completed'] ?? false,
                    note: setData['note'] ?? '',
                  ));
                }
              }
            }
          } else if (exercise['sets'] is int) {
            // 舊結構: 如果sets是整數，表示組數
            final totalSets = exercise['sets'] as int;
            for (int i = 0; i < totalSets; i++) {
              setsRecords.add(SetRecord(
                setNumber: i + 1,
                reps: exercise['reps'] as int? ?? 10,
                weight: (exercise['weight'] as num?)?.toDouble() ?? 0.0,
                restTime: exercise['restTime'] as int? ?? 60,
                completed: false,
                note: '',
              ));
            }
          } else {
            // 默認情況，創建3組
            for (int i = 0; i < 3; i++) {
              setsRecords.add(SetRecord(
                setNumber: i + 1,
                reps: exercise['reps'] as int? ?? 10,
                weight: (exercise['weight'] as num?)?.toDouble() ?? 0.0,
                restTime: exercise['restTime'] as int? ?? 60,
                completed: false,
                note: '',
              ));
            }
          }
          
          // 優先使用exerciseName，然後是name，最後是actionName
          final name = exercise['exerciseName'] ?? 
                      exercise['name'] ?? 
                      exercise['actionName'] ?? 
                      '未命名運動';
          
          // 檢查是否所有組數都已完成（優先使用計算值）
          final exerciseCompleted = setsRecords.isNotEmpty && setsRecords.every((set) => set.completed);
          
          // 創建運動記錄
          exerciseRecords.add(ExerciseRecord(
            exerciseId: exercise['exerciseId'] ?? '',
            exerciseName: name,
            sets: setsRecords,
            notes: exercise['notes'] ?? exercise['note'] ?? '',
            completed: exerciseCompleted,  // 根據實際組數狀態計算
          ));
        }
      } catch (e) {
        _errorService.logError('處理運動記錄失敗: $e', type: 'ExerciseProcessError');
      }
    }
    
    return exerciseRecords;
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
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      // 計算整體完成狀態
      final overallCompleted = allExercisesCompleted();
      
      // 更新 workoutPlans 集合中的組數狀態
      final planDoc = await FirebaseFirestore.instance
          .collection('workoutPlans')
          .doc(_workoutRecordId)
          .get();
          
      if (planDoc.exists) {
        await FirebaseFirestore.instance
            .collection('workoutPlans')
            .doc(_workoutRecordId)
            .update({
              'completed': overallCompleted,  // 更新整體完成狀態
              'exercises': _exerciseRecords.map((exercise) => {
                'exerciseId': exercise.exerciseId,
                'exerciseName': exercise.exerciseName,
                'completed': exercise.completed,
                'sets': exercise.sets.map((set) => {
                  'setNumber': set.setNumber,
                  'reps': set.reps,
                  'weight': set.weight,
                  'restTime': set.restTime,
                  'completed': set.completed,
                  'note': set.note,
                }).toList(),
              }).toList(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
      
      _isDataChanged = false;
    } catch (e) {
      // 靜默失敗，不影響用戶體驗
      print('[自動保存] 保存打勾狀態失敗: $e');
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
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('未登入');
      }
      
      // 創建運動記錄數據
      final recordData = {
        'userId': userId,
        'planId': _workoutRecordId, // 關聯到原計劃ID
        'title': _planTitle,
        'date': Timestamp.now(),
        'exercises': _exerciseRecords.map((exercise) {
          // 將每個運動轉換為JSON格式
          final sets = exercise.sets.map((set) => {
            'setNumber': set.setNumber,
            'weight': set.weight,
            'reps': set.reps,
            'completed': set.completed,
            'note': set.note,
          }).toList();
          
          // 計算該運動的總訓練量
          double totalVolumeForExercise = 0;
          for (var set in exercise.sets) {
            if (set.completed) {
              totalVolumeForExercise += set.weight * set.reps;
            }
          }
          
          return {
            'exerciseId': exercise.exerciseId,
            'exerciseName': exercise.exerciseName,
            'sets': sets,
            'completed': exercise.completed,
            'totalVolume': totalVolumeForExercise,
            'restTime': exercise.sets.isNotEmpty ? exercise.sets.first.restTime : 60,
            'note': exercise.notes,
          };
        }).toList(),
        'completed': allExercisesCompleted(),
        'duration': 0, // 暫時設為0
        'startTime': Timestamp.now(),
        'endTime': Timestamp.now(),
        'note': _notesController.text,
        'totalExercises': _exerciseRecords.length,
        'totalSets': calculateTotalSets(),
        'totalVolume': calculateTotalVolume(),
        'updatedAt': Timestamp.now(),
        'isPublic': false,
        'feelingRating': 0, // 預設值
        'difficultyRating': 0, // 預設值
        'muscleGroups': _extractMuscleGroups(),
      };
      
      // 統一保存到 workoutPlans 集合（不再使用 workoutRecords）
      final planDoc = await FirebaseFirestore.instance
          .collection('workoutPlans')
          .doc(_workoutRecordId)
          .get();
          
      if (planDoc.exists) {
        // 計算整體完成狀態
        final overallCompleted = allExercisesCompleted();
        
        // 更新訓練計畫，包含所有訓練記錄數據
        await FirebaseFirestore.instance
            .collection('workoutPlans')
            .doc(_workoutRecordId)
            .update({
              'completed': overallCompleted,  // 根據實際狀態設置
              'completedDate': overallCompleted ? Timestamp.now() : null,  // 只有真正完成時才設置完成日期
              'exercises': _exerciseRecords.map((exercise) => {
                'exerciseId': exercise.exerciseId,
                'exerciseName': exercise.exerciseName,
                'completed': exercise.completed,
                // 保存詳細的組數狀態
                'sets': exercise.sets.map((set) => {
                  'setNumber': set.setNumber,
                  'reps': set.reps,
                  'weight': set.weight,
                  'restTime': set.restTime,
                  'completed': set.completed,
                  'note': set.note,
                }).toList(),
              }).toList(),
              // 保存訓練記錄的統計數據
              'totalExercises': _exerciseRecords.length,
              'totalSets': calculateTotalSets(),
              'totalVolume': calculateTotalVolume(),
              'note': _notesController.text,  // ✅ 添加：保存訓練備註
              'updatedAt': Timestamp.now(),
            });
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
    } catch (e) {
      _handleError('保存訓練記錄失敗', e);
      
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存訓練記錄失敗: $e')),
        );
      }
      
      return false;
    }
  }
  
  /// 提取訓練涉及的肌肉群
  List<String> _extractMuscleGroups() {
    final muscleGroups = <String>{};
    
    // 這裡可以根據實際情況從運動記錄中提取肌肉群
    // 暫時返回空列表
    
    return muscleGroups.toList();
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