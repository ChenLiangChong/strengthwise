import '../../../models/statistics_model.dart';
import '../../../models/exercise_model.dart';
import '../../../models/tracking_mode.dart';
import 'statistics_models.dart';

/// 訓練進度計算器
/// v3.3+ 支援多元追蹤模式
///
/// 計算每個動作的訓練進度趨勢
class StrengthProgressCalculator {
  final Map<String, Exercise> _exerciseCache;

  StrengthProgressCalculator({required Map<String, Exercise> exerciseCache})
      : _exerciseCache = exerciseCache;

  /// 計算訓練進度
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
          // v3.3+ 新增
          time: exercise.time,
          distance: exercise.distance,
          calories: exercise.calories,
        ));
      }
    }

    // 計算每個動作的訓練進度
    final List<ExerciseStrengthProgress> progressList = [];

    for (var entry in exercisePerformances.entries) {
      final performances = entry.value;
      if (performances.isEmpty) continue;

      // 排序（按日期）
      performances.sort((a, b) => a.date.compareTo(b.date));

      // v3.3+ 從 exerciseCache 獲取 trackingMode
      final exercise = _exerciseCache[performances.first.exerciseId];
      final trackingMode = exercise?.trackingMode ?? TrackingMode.weightReps;
      final bodyPart =
          exercise?.bodyPart.isNotEmpty == true ? exercise!.bodyPart : '未分類';

      // 計算進度曲線
      final history = <StrengthProgressPoint>[];
      double maxWeight = 0;

      for (var perf in performances) {
        final oneRM = _calculateOneRM(perf.weight, perf.reps);
        final isPR = perf.weight > maxWeight && trackingMode.isWeightBased;
        if (isPR) maxWeight = perf.weight;

        history.add(StrengthProgressPoint(
          date: perf.date,
          weight: perf.weight,
          reps: perf.reps,
          estimatedOneRM: oneRM,
          isPR: isPR,
          // v3.3+ 新增
          time: perf.time,
          distance: perf.distance,
          calories: perf.calories,
          trackingMode: trackingMode,
        ));
      }

      // 計算進步百分比（與上一期對比）- 只對重訓模式計算
      double progressPercentage = 0.0;
      double previousMax = 0.0;
      
      if (trackingMode.isWeightBased) {
        final previousStart = _getPreviousPeriodStart(startDate, timeRange);
        final previousPerformances = performances
            .where((p) =>
                p.date.isAfter(previousStart) && p.date.isBefore(startDate))
            .toList();

        previousMax = previousPerformances.isEmpty
            ? 0.0
            : previousPerformances
                .map((p) => p.weight)
                .reduce((a, b) => a > b ? a : b);

        progressPercentage = previousMax > 0
            ? ((maxWeight - previousMax) / previousMax * 100)
            : 0.0;
      }

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
        // v3.3+ 新增
        trackingMode: trackingMode,
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
/// v3.3+ 支援多元追蹤模式
class _ExercisePerformance {
  final DateTime date;
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final int sets;
  // v3.3+ 新增
  final int? time;
  final double? distance;
  final double? calories;

  _ExercisePerformance({
    required this.date,
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.sets,
    this.time,
    this.distance,
    this.calories,
  });
}

