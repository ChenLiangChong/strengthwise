import '../../models/workout_record_model.dart';
import '../../models/exercise_model.dart';

/// 訓練執行運動構建器
///
/// 創建新的訓練動作記錄
/// v3.2+ 支援多元追蹤模式
class WorkoutExecutionExerciseBuilder {
  /// 創建新的運動記錄
  /// 
  /// [exercise] 動作資訊
  /// [sets] 組數
  /// [reps] 次數（weight_reps, reps_only 模式使用）
  /// [weight] 重量（weight_reps, weight_time 模式使用）
  /// [restTime] 休息時間（秒）
  /// [time] 時間（秒，weight_time, time_only, distance_time 模式使用）
  /// [distance] 距離（公尺，distance_time 模式使用）
  /// [calories] 卡路里（kcal，calories 模式使用）
  static ExerciseRecord createExerciseRecord(
    Exercise exercise,
    int sets,
    int reps,
    double weight,
    int restTime, {
    int? time,
    double? distance,
    double? calories,
  }) {
    // 創建組數記錄
    final setRecords = <SetRecord>[];
    for (int i = 0; i < sets; i++) {
      setRecords.add(SetRecord(
        setNumber: i + 1,
        reps: reps,
        weight: weight,
        restTime: restTime,
        completed: false,
        // v3.2+ 新增欄位
        time: time,
        distance: distance,
        calories: calories,
      ));
    }
    
    // 創建運動記錄
    return ExerciseRecord(
      exerciseId: exercise.id,
      exerciseName: exercise.displayName,
      sets: setRecords,
      notes: '',
      completed: false,
      trackingMode: exercise.trackingMode,
    );
  }
}

