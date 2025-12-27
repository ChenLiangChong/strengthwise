/// 統計服務內部使用的統一數據類型
///
/// 這些類型用於在不同統計模組之間傳遞訓練數據

/// 統一的訓練數據
class UnifiedWorkoutData {
  final String id;
  final String title;
  final DateTime completedTime;
  final List<UnifiedExerciseData> exercises;

  UnifiedWorkoutData({
    required this.id,
    required this.title,
    required this.completedTime,
    required this.exercises,
  });
}

/// 統一的動作數據
class UnifiedExerciseData {
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final int sets;
  final bool isCompleted;

  UnifiedExerciseData({
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.sets,
    required this.isCompleted,
  });
}

