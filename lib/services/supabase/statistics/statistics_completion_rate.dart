import '../../../models/statistics_model.dart';
import 'statistics_models.dart';

/// 完成率統計計算器
///
/// 計算訓練完成率相關數據
class CompletionRateCalculator {
  /// 計算完成率
  CompletionRateStats calculateCompletionRate(
    List<UnifiedWorkoutData> workouts,
  ) {
    double totalPlannedSets = 0;
    double completedSets = 0;
    Map<String, int> incompleteExercises = {};

    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        totalPlannedSets += exercise.sets.toDouble();

        if (exercise.isCompleted) {
          completedSets += exercise.sets.toDouble();
        } else {
          final failedSets = exercise.sets;
          incompleteExercises.update(
            exercise.exerciseName,
            (value) => value + failedSets,
            ifAbsent: () => failedSets,
          );
        }
      }
    }

    final failedSets = totalPlannedSets - completedSets;
    final completionRate =
        totalPlannedSets > 0 ? completedSets / totalPlannedSets : 1.0;

    // 找出弱點動作（失敗次數最多的）
    final weakPoints = incompleteExercises.entries
        .where((e) => e.value > 2)
        .map((e) => e.key)
        .toList();

    return CompletionRateStats(
      totalPlannedSets: totalPlannedSets.toInt(),
      completedSets: completedSets.toInt(),
      failedSets: failedSets.toInt(),
      completionRate: completionRate,
      incompleteExercises: incompleteExercises,
      weakPoints: weakPoints,
    );
  }
}

