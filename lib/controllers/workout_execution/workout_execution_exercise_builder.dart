import '../../models/workout_record_model.dart';
import '../../models/exercise_model.dart';

/// 訓練執行運動構建器
///
/// 創建新的訓練動作記錄
class WorkoutExecutionExerciseBuilder {
  /// 創建新的運動記錄
  static ExerciseRecord createExerciseRecord(
    Exercise exercise,
    int sets,
    int reps,
    double weight,
    int restTime,
  ) {
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
    return ExerciseRecord(
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      sets: setRecords,
      notes: '',
      completed: false,
    );
  }
}

