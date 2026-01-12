import '../../models/workout_record_model.dart';

/// 訓練執行組數操作
///
/// 處理組數的勾選、更新、新增等操作
class WorkoutExecutionSetOperations {
  /// 切換組數完成狀態
  /// 
  /// 返回更新後的運動記錄
  static ExerciseRecord toggleSetCompletion(
    ExerciseRecord exercise,
    int setIndex,
  ) {
    if (setIndex >= exercise.sets.length) return exercise;
    
    // 更新組數狀態
    final updatedSets = List<SetRecord>.from(exercise.sets);
    updatedSets[setIndex] = exercise.sets[setIndex].copyWith(
      completed: !exercise.sets[setIndex].completed,
    );
    
    // 檢查是否所有組數都已完成
    final allSetsCompleted = updatedSets.every((set) => set.completed);
    
    return exercise.copyWith(
      sets: updatedSets,
      completed: allSetsCompleted,
    );
  }
  
  /// 更新組數數據
  /// 
  /// v3.2+ 支援多元追蹤模式的所有欄位
  /// 返回更新後的運動記錄
  static ExerciseRecord updateSetData(
    ExerciseRecord exercise,
    int setIndex,
    int reps,
    double weight, {
    int? time,
    double? distance,
    double? calories,
  }) {
    if (setIndex >= exercise.sets.length) return exercise;
    
    final currentSet = exercise.sets[setIndex];
    
    // 更新組數數據
    final updatedSets = List<SetRecord>.from(exercise.sets);
    updatedSets[setIndex] = currentSet.copyWith(
      reps: reps,
      weight: weight,
      time: time ?? currentSet.time,
      distance: distance ?? currentSet.distance,
      calories: calories ?? currentSet.calories,
    );
    
    return exercise.copyWith(sets: updatedSets);
  }
  
  /// 新增組數到運動
  /// 
  /// v3.2+ 複製最後一組的所有欄位（包含 time, distance, calories）
  /// 返回更新後的運動記錄
  static ExerciseRecord addSetToExercise(ExerciseRecord exercise) {
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
    
    // 創建新的組數記錄（v3.2+ 包含新欄位）
    final newSet = SetRecord(
      setNumber: exercise.sets.length + 1,
      reps: lastSet.reps,
      weight: lastSet.weight,
      restTime: lastSet.restTime,
      completed: false,
      note: '',
      // v3.2+ 新增欄位
      time: lastSet.time,
      distance: lastSet.distance,
      calories: lastSet.calories,
    );
    
    // 更新運動記錄
    final updatedSets = List<SetRecord>.from(exercise.sets)..add(newSet);
    return exercise.copyWith(sets: updatedSets);
  }
  
  /// ⭐ v2.9.1 TRN-2: 減少組數
  /// 
  /// 返回更新後的運動記錄（移除最後一組）
  static ExerciseRecord removeSetFromExercise(ExerciseRecord exercise) {
    if (exercise.sets.length <= 1) return exercise; // 至少保留 1 組
    
    // 移除最後一組
    final updatedSets = List<SetRecord>.from(exercise.sets)..removeLast();
    
    // 重新計算是否全部完成
    final allSetsCompleted = updatedSets.isNotEmpty && 
                             updatedSets.every((set) => set.completed);
    
    return exercise.copyWith(
      sets: updatedSets,
      completed: allSetsCompleted,
    );
  }
  
  /// 添加運動備註
  /// 
  /// 返回更新後的運動記錄
  static ExerciseRecord addExerciseNote(
    ExerciseRecord exercise,
    String note,
  ) {
    return exercise.copyWith(notes: note);
  }
}

