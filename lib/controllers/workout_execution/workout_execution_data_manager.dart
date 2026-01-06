import '../../models/workout_record_model.dart';
import 'package:flutter/material.dart';

/// 訓練執行數據管理器
///
/// 管理訓練執行過程中的數據狀態
class WorkoutExecutionDataManager {
  // 數據
  String _workoutRecordId = '';
  String _planTitle = '';
  String _planType = '';
  List<ExerciseRecord> _exerciseRecords = [];
  final TextEditingController _notesController = TextEditingController();
  
  // ⭐ v2.0 Phase 4C: 教練學員系統
  String? _traineeId;  // 受訓者 ID
  String? _creatorId;  // 創建者 ID
  
  // ⭐ v3.1: Session Mode 關聯
  String? _appointmentId;  // 上課類型（有此值表示是課程訓練）
  
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
  
  // ⭐ v2.9.1: 訓練狀態追蹤
  String _trainingStatus = 'pending'; // pending | in_progress | paused | completed
  int _elapsedSeconds = 0;
  DateTime? _actualStartTime;
  DateTime? _actualEndTime;
  DateTime? _lastTickTime; // 用於計算經過時間
  
  // ⭐ v3.1: 是否已初始化（用於區分首次載入和 Realtime 重載）
  bool _isInitialized = false;
  
  // Getters
  String get workoutRecordId => _workoutRecordId;
  String get planTitle => _planTitle;
  String get planType => _planType;
  List<ExerciseRecord> get exerciseRecords => _exerciseRecords;
  TextEditingController get notesController => _notesController;
  String? get traineeId => _traineeId;  // ⭐ 新增
  String? get creatorId => _creatorId;  // ⭐ 新增
  String? get appointmentId => _appointmentId;  // ⭐ v3.1: Session Mode
  bool get isSessionPlan => _appointmentId != null && _appointmentId!.isNotEmpty;  // ⭐ v3.1
  DateTime? get planDate => _planDate;
  bool get isToday => _isToday;
  bool get isPastDate => _isPastDate;
  bool get isFutureDate => _isFutureDate;
  int get currentExerciseIndex => _currentExerciseIndex;
  int? get trainingHour => _trainingHour;
  bool get hasScheduledTime => _hasScheduledTime;
  
  // ⭐ v2.9.1: 訓練狀態追蹤 Getters
  String get trainingStatus => _trainingStatus;
  int get elapsedSeconds => _elapsedSeconds;
  DateTime? get actualStartTime => _actualStartTime;
  DateTime? get actualEndTime => _actualEndTime;
  
  bool get isPending => _trainingStatus == 'pending';
  bool get isInProgress => _trainingStatus == 'in_progress';
  bool get isPaused => _trainingStatus == 'paused';
  bool get isCompleted => _trainingStatus == 'completed';
  bool get isInitialized => _isInitialized;  // ⭐ v3.1
  
  // Setters
  set workoutRecordId(String value) => _workoutRecordId = value;
  set planTitle(String value) => _planTitle = value;
  set planType(String value) => _planType = value;
  set exerciseRecords(List<ExerciseRecord> value) => _exerciseRecords = value;
  set traineeId(String? value) => _traineeId = value;  // ⭐ 新增
  set creatorId(String? value) => _creatorId = value;  // ⭐ 新增
  set appointmentId(String? value) => _appointmentId = value;  // ⭐ v3.1
  
  // ⭐ v2.9.1: 訓練狀態追蹤 Setters
  set trainingStatus(String value) => _trainingStatus = value;
  set elapsedSeconds(int value) => _elapsedSeconds = value;
  set actualStartTime(DateTime? value) => _actualStartTime = value;
  set actualEndTime(DateTime? value) => _actualEndTime = value;
  
  /// 設置當前運動索引
  void setCurrentExerciseIndex(int index) {
    if (index >= 0 && index < _exerciseRecords.length) {
      _currentExerciseIndex = index;
    }
  }
  
  /// 設置訓練時間
  void setTrainingHour(int hour) {
    _trainingHour = hour;
    _hasScheduledTime = true;
  }
  
  // =============================================
  // ⭐ v2.9.1: 訓練狀態追蹤方法
  // =============================================
  
  /// 開始訓練（pending → in_progress）
  void startTraining() {
    if (_trainingStatus != 'pending') return;
    
    _trainingStatus = 'in_progress';
    _actualStartTime = DateTime.now();
    _lastTickTime = DateTime.now();
  }
  
  /// 暫停訓練（in_progress → paused）
  void pauseTraining() {
    if (_trainingStatus != 'in_progress') return;
    
    // 計算本次經過時間
    if (_lastTickTime != null) {
      final now = DateTime.now();
      _elapsedSeconds += now.difference(_lastTickTime!).inSeconds;
    }
    
    _trainingStatus = 'paused';
    _lastTickTime = null;
  }
  
  /// 繼續訓練（paused/completed → in_progress）
  /// ⭐ v2.9.1: 支援從 completed 狀態恢復（用戶取消勾選時）
  void resumeTraining() {
    if (_trainingStatus != 'paused' && _trainingStatus != 'completed') return;
    
    _trainingStatus = 'in_progress';
    _lastTickTime = DateTime.now();
    _actualEndTime = null; // 清除結束時間
  }
  
  /// 完成訓練（in_progress → completed）
  void completeTraining() {
    if (_trainingStatus != 'in_progress' && _trainingStatus != 'paused') return;
    
    // 如果還在進行中，先計算最後的時間
    if (_trainingStatus == 'in_progress' && _lastTickTime != null) {
      final now = DateTime.now();
      _elapsedSeconds += now.difference(_lastTickTime!).inSeconds;
    }
    
    _trainingStatus = 'completed';
    _actualEndTime = DateTime.now();
    _lastTickTime = null;
  }
  
  /// 更新經過時間（每秒呼叫，僅在 in_progress 時有效）
  /// 返回當前總秒數
  int tickElapsedTime() {
    if (_trainingStatus != 'in_progress' || _lastTickTime == null) {
      return _elapsedSeconds;
    }
    
    final now = DateTime.now();
    return _elapsedSeconds + now.difference(_lastTickTime!).inSeconds;
  }
  
  /// 從資料庫加載的資料初始化狀態
  /// ⭐ v3.1: 區分首次載入和 Realtime 重載
  void initFromRecord({
    required String trainingStatus,
    required int elapsedSeconds,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
  }) {
    _elapsedSeconds = elapsedSeconds;
    _actualStartTime = actualStartTime;
    _actualEndTime = actualEndTime;
    _trainingStatus = trainingStatus;
    
    // ⭐ v3.1: 如果是 in_progress，設置計時起點
    if (trainingStatus == 'in_progress') {
      _lastTickTime = DateTime.now();
    } else {
      _lastTickTime = null;
    }
    
    // ⭐ v3.1: 標記已初始化
    _isInitialized = true;
  }
  
  /// ⭐ v3.1: 從遠端同步時間（Realtime 更新時使用）
  /// 只更新時間和狀態，不影響其他資料
  void syncTimeFromRemote({
    required int elapsedSeconds,
    required String trainingStatus,
  }) {
    _elapsedSeconds = elapsedSeconds;
    _trainingStatus = trainingStatus;
    
    // 如果遠端是 in_progress，設置計時起點（讓顯示正確）
    if (trainingStatus == 'in_progress') {
      _lastTickTime = DateTime.now();
    } else {
      _lastTickTime = null;
    }
  }
  
  /// 處理日期信息
  void processDateInfo(DateTime date) {
    _planDate = date;
    
    // 對比今日日期（僅考慮年月日，不考慮時分秒）
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final planDateOnly = DateTime(_planDate!.year, _planDate!.month, _planDate!.day);
    
    _isToday = planDateOnly.isAtSameMomentAs(todayDate);
    _isPastDate = planDateOnly.isBefore(todayDate);
    _isFutureDate = planDateOnly.isAfter(todayDate);
  }
  
  /// 獲取無法修改訓練的提示信息
  String getPastDateMessage() {
    if (_isPastDate) {
      return '無法修改過去的訓練記錄';
    } else if (_isFutureDate) {
      return '無法修改未來的訓練記錄，請在訓練當天進行操作';
    }
    return '無法修改訓練記錄';
  }
  
  /// 檢查所有運動是否已完成
  bool allExercisesCompleted() {
    if (_exerciseRecords.isEmpty) return false;
    return _exerciseRecords.every((exercise) => exercise.completed);
  }
  
  /// 計算總組數
  int calculateTotalSets() {
    int totalSets = 0;
    for (var exercise in _exerciseRecords) {
      totalSets += exercise.sets.length;
    }
    return totalSets;
  }
  
  /// 計算總訓練量
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
  
  /// 釋放資源
  void dispose() {
    _notesController.dispose();
  }
}

