import '../../../models/statistics_model.dart';
import '../../../models/exercise_model.dart';
import 'statistics_models.dart';

/// 統計計算器
///
/// 負責各項統計數據的計算邏輯
class StatisticsCalculator {
  final Map<String, Exercise> _exerciseCache;

  StatisticsCalculator({required Map<String, Exercise> exerciseCache})
      : _exerciseCache = exerciseCache;

  /// 計算訓練頻率
  TrainingFrequency calculateTrainingFrequency({
    required List<Map<String, dynamic>> currentStats,
    required List<Map<String, dynamic>> previousStats,
  }) {
    final totalWorkouts = currentStats.fold<int>(
        0, (sum, row) => sum + (row['workout_count'] as int? ?? 0));
    final previousWorkouts = previousStats.fold<int>(
        0, (sum, row) => sum + (row['workout_count'] as int? ?? 0));
    final trainingDays = currentStats.length;

    final consecutiveDays =
        _calculateConsecutiveDaysFromSummary(currentStats);

    return TrainingFrequency(
      totalWorkouts: totalWorkouts,
      totalHours: totalWorkouts.toDouble(),
      averageHours: trainingDays > 0 ? totalWorkouts / trainingDays : 0.0,
      consecutiveDays: consecutiveDays,
      comparisonValue: totalWorkouts - previousWorkouts,
    );
  }

  /// 計算訓練量趨勢
  List<TrainingVolumePoint> calculateVolumeHistory(
      List<Map<String, dynamic>> summaryData) {
    final points = <TrainingVolumePoint>[];

    for (var row in summaryData) {
      final date = DateTime.parse(row['date'] as String);
      final totalVolume = (row['total_volume'] as num?)?.toDouble() ?? 0.0;
      final totalSets = (row['total_sets'] as int?) ?? 0;
      final workoutCount = (row['workout_count'] as int?) ?? 0;

      points.add(TrainingVolumePoint(
        date: date,
        totalVolume: totalVolume,
        totalSets: totalSets,
        workoutCount: workoutCount,
      ));
    }

    return points;
  }

  /// 計算身體部位統計
  List<BodyPartStats> calculateBodyPartStats(
      List<UnifiedWorkoutData> workouts) {
    final Map<String, _BodyPartAccumulator> stats = {};

    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        if (!exercise.isCompleted) continue;

        final exerciseInfo = _exerciseCache[exercise.exerciseId];
        if (exerciseInfo == null) continue;

        final bodyPart = exerciseInfo.bodyPart;
        if (bodyPart.isEmpty) continue;

        final volume = exercise.weight * exercise.reps * exercise.sets;

        stats.putIfAbsent(
          bodyPart,
          () => _BodyPartAccumulator(bodyPart: bodyPart),
        );
        stats[bodyPart]!.addExercise(volume);
      }
    }

    final totalVolume = stats.values.fold<double>(
      0,
      (sum, stat) => sum + stat.totalVolume,
    );

    final result = stats.values.map((accumulator) {
      return BodyPartStats(
        bodyPart: accumulator.bodyPart,
        totalVolume: accumulator.totalVolume,
        workoutCount: accumulator.exerciseCount,
        exerciseCount: accumulator.exerciseCount,
        percentage:
            totalVolume > 0 ? accumulator.totalVolume / totalVolume : 0,
      );
    }).toList();

    result.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));
    return result;
  }

  /// 計算特定肌群統計
  List<SpecificMuscleStats> calculateSpecificMuscleStats(
    List<UnifiedWorkoutData> workouts,
    String bodyPart,
  ) {
    final Map<String, _MuscleAccumulator> stats = {};
    double totalVolumeForBodyPart = 0;

    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        if (!exercise.isCompleted) continue;

        final exerciseInfo = _exerciseCache[exercise.exerciseId];
        if (exerciseInfo == null || exerciseInfo.bodyPart != bodyPart) continue;

        final specificMuscle = exerciseInfo.specificMuscle;
        if (specificMuscle.isEmpty) continue;

        final volume = exercise.weight * exercise.reps * exercise.sets;
        totalVolumeForBodyPart += volume;

        stats.putIfAbsent(
          specificMuscle,
          () => _MuscleAccumulator(muscleGroup: specificMuscle),
        );
        stats[specificMuscle]!.addExercise(volume);
      }
    }

    if (stats.isEmpty) return [];

    final result = stats.values.map((accumulator) {
      return SpecificMuscleStats(
        specificMuscle: accumulator.muscleGroup,
        totalVolume: accumulator.totalVolume,
        workoutCount: accumulator.exerciseCount,
        percentage: totalVolumeForBodyPart > 0
            ? accumulator.totalVolume / totalVolumeForBodyPart
            : 0,
      );
    }).toList();

    result.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));
    return result;
  }

  /// 計算訓練類型統計
  List<TrainingTypeStats> calculateTrainingTypeStats(
      List<Map<String, dynamic>> summaryData) {
    int resistanceCount = 0;
    int cardioCount = 0;
    int mobilityCount = 0;

    for (var row in summaryData) {
      resistanceCount += (row['resistance_training_count'] as int?) ?? 0;
      cardioCount += (row['cardio_count'] as int?) ?? 0;
      mobilityCount += (row['mobility_count'] as int?) ?? 0;
    }

    final totalExercises = resistanceCount + cardioCount + mobilityCount;
    if (totalExercises == 0) return [];

    final result = <TrainingTypeStats>[];

    if (resistanceCount > 0) {
      result.add(TrainingTypeStats(
        trainingType: '阻力訓練',
        workoutCount: resistanceCount,
        percentage: resistanceCount / totalExercises,
      ));
    }

    if (cardioCount > 0) {
      result.add(TrainingTypeStats(
        trainingType: '心肺適能訓練',
        workoutCount: cardioCount,
        percentage: cardioCount / totalExercises,
      ));
    }

    if (mobilityCount > 0) {
      result.add(TrainingTypeStats(
        trainingType: '活動度與伸展',
        workoutCount: mobilityCount,
        percentage: mobilityCount / totalExercises,
      ));
    }

    result.sort((a, b) => b.workoutCount.compareTo(a.workoutCount));
    return result;
  }

  /// 計算器材統計
  List<EquipmentStats> calculateEquipmentStats(
      List<UnifiedWorkoutData> workouts) {
    final Map<String, int> stats = {};
    int totalExercises = 0;

    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        if (!exercise.isCompleted) continue;

        final exerciseInfo = _exerciseCache[exercise.exerciseId];
        if (exerciseInfo == null) continue;

        final equipmentCategory = exerciseInfo.equipmentCategory;
        if (equipmentCategory.isEmpty) continue;

        stats[equipmentCategory] = (stats[equipmentCategory] ?? 0) + 1;
        totalExercises++;
      }
    }

    if (stats.isEmpty) return [];

    final result = stats.entries.map((entry) {
      return EquipmentStats(
        equipment: entry.key,
        usageCount: entry.value,
        percentage: totalExercises > 0 ? entry.value / totalExercises : 0,
      );
    }).toList();

    result.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return result;
  }

  /// 計算連續訓練天數（從彙總表數據）
  int _calculateConsecutiveDaysFromSummary(
      List<Map<String, dynamic>> summaryData) {
    if (summaryData.isEmpty) return 0;

    final dates = summaryData
        .map((row) => DateTime.parse(row['date'] as String))
        .toList();

    dates.sort((a, b) => b.compareTo(a)); // 降序排列

    int consecutive = 0;
    DateTime? previousDate;

    for (var date in dates) {
      if (previousDate == null) {
        consecutive = 1;
      } else {
        final diff = previousDate.difference(date).inDays;
        if (diff == 1) {
          consecutive++;
        } else {
          break;
        }
      }
      previousDate = date;
    }

    return consecutive;
  }

  /// 計算 1RM（使用 Epley 公式）
  double calculateOneRM(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }
}

/// 身體部位累加器（內部使用）
class _BodyPartAccumulator {
  final String bodyPart;
  double totalVolume = 0;
  int exerciseCount = 0;

  _BodyPartAccumulator({required this.bodyPart});

  void addExercise(double volume) {
    totalVolume += volume;
    exerciseCount++;
  }
}

/// 肌群累加器（內部使用）
class _MuscleAccumulator {
  final String muscleGroup;
  double totalVolume = 0;
  int exerciseCount = 0;

  _MuscleAccumulator({required this.muscleGroup});

  void addExercise(double volume) {
    totalVolume += volume;
    exerciseCount++;
  }
}

