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
  
  // Getters
  String get workoutRecordId => _workoutRecordId;
  String get planTitle => _planTitle;
  String get planType => _planType;
  List<ExerciseRecord> get exerciseRecords => _exerciseRecords;
  TextEditingController get notesController => _notesController;
  DateTime? get planDate => _planDate;
  bool get isToday => _isToday;
  bool get isPastDate => _isPastDate;
  bool get isFutureDate => _isFutureDate;
  int get currentExerciseIndex => _currentExerciseIndex;
  int? get trainingHour => _trainingHour;
  bool get hasScheduledTime => _hasScheduledTime;
  
  // Setters
  set workoutRecordId(String value) => _workoutRecordId = value;
  set planTitle(String value) => _planTitle = value;
  set planType(String value) => _planType = value;
  set exerciseRecords(List<ExerciseRecord> value) => _exerciseRecords = value;
  
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

