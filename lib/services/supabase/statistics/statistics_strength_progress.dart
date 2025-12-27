import '../../../models/statistics_model.dart';
import '../../../models/exercise_model.dart';
import 'statistics_models.dart';

/// 力量進步計算器
///
/// 計算每個動作的力量進步趨勢
class StrengthProgressCalculator {
  final Map<String, Exercise> _exerciseCache;

  StrengthProgressCalculator({required Map<String, Exercise> exerciseCache})
      : _exerciseCache = exerciseCache;

  /// 計算力量進步
  List<ExerciseStrengthProgress> calculateProgress(
    List<UnifiedWorkoutData> workouts,
    DateTime startDate,
    TimeRange timeRange, {
    int limit = 10,
  }) {
    // 按動作ID分組
    final Map<String, List<_ExercisePerformance>> exercisePerformances = {};

    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        if (!exercise.isCompleted) continue;

        final key = exercise.exerciseId;
        exercisePerformances.putIfAbsent(key, () => []);

        exercisePerformances[key]!.add(_ExercisePerformance(
          date: workout.completedTime,
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          weight: exercise.weight,
          reps: exercise.reps,
          sets: exercise.sets,
        ));
      }
    }

    // 計算每個動作的力量進步
    final List<ExerciseStrengthProgress> progressList = [];

    for (var entry in exercisePerformances.entries) {
      final performances = entry.value;
      if (performances.isEmpty) continue;

      // 排序（按日期）
      performances.sort((a, b) => a.date.compareTo(b.date));

      // 計算力量曲線
      final history = <StrengthProgressPoint>[];
      double maxWeight = 0;

      for (var perf in performances) {
        final oneRM = _calculateOneRM(perf.weight, perf.reps);
        final isPR = perf.weight > maxWeight;
        if (isPR) maxWeight = perf.weight;

        history.add(StrengthProgressPoint(
          date: perf.date,
          weight: perf.weight,
          reps: perf.reps,
          estimatedOneRM: oneRM,
          isPR: isPR,
        ));
      }

      // 計算進步百分比（與上一期對比）
      final previousStart = _getPreviousPeriodStart(startDate, timeRange);
      final previousPerformances = performances
          .where((p) =>
              p.date.isAfter(previousStart) && p.date.isBefore(startDate))
          .toList();

      final previousMax = previousPerformances.isEmpty
          ? 0.0
          : previousPerformances
              .map((p) => p.weight)
              .reduce((a, b) => a > b ? a : b);

      final progressPercentage = previousMax > 0
          ? ((maxWeight - previousMax) / previousMax * 100)
          : 0.0;

      // 載入動作資訊
      final exercise = _exerciseCache[performances.first.exerciseId];
      final bodyPart =
          exercise?.bodyPart.isNotEmpty == true ? exercise!.bodyPart : '未分類';

      // 計算平均重量和總組數
      final totalWeight =
          performances.fold<double>(0.0, (sum, p) => sum + p.weight * p.sets);
      final totalSets = performances.fold<int>(0, (sum, p) => sum + p.sets);
      final averageWeight =
          totalSets > 0 ? totalWeight.toDouble() / totalSets.toDouble() : 0.0;

      progressList.add(ExerciseStrengthProgress(
        exerciseId: entry.key,
        exerciseName: performances.first.exerciseName,
        bodyPart: bodyPart,
        history: history,
        currentMax: maxWeight,
        previousMax: previousMax,
        progressPercentage: progressPercentage,
        totalSets: totalSets,
        averageWeight: averageWeight,
      ));
    }

    // 按進步百分比排序，取前 N 個
    progressList
        .sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
    return progressList.take(limit).toList();
  }

  /// 計算 1RM（使用 Epley 公式）
  double _calculateOneRM(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

  /// 獲取上一個時間範圍的起始日期
  DateTime _getPreviousPeriodStart(DateTime startDate, TimeRange timeRange) {
    final endDate = timeRange.endDate;
    final duration = endDate.difference(startDate);
    return startDate.subtract(duration);
  }
}

/// 動作表現記錄（內部使用）
class _ExercisePerformance {
  final DateTime date;
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final int sets;

  _ExercisePerformance({
    required this.date,
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.sets,
  });
}

