import '../../../models/statistics_model.dart';
import '../../../models/exercise_model.dart';
import '../../../models/exercise/exercise_labels.dart';
import '../../../utils/datetime_utils.dart';
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
    // ⭐ 新增：全部排定的訓練計劃數
    final scheduledWorkouts = currentStats.fold<int>(
        0, (sum, row) => sum + (row['scheduled_workout_count'] as int? ?? 0));
    final totalWorkouts = currentStats.fold<int>(
        0, (sum, row) => sum + (row['workout_count'] as int? ?? 0));
    final completedWorkouts = currentStats.fold<int>(
        0, (sum, row) => sum + (row['completed_workout_count'] as int? ?? 0));
    final partialWorkouts = currentStats.fold<int>(
        0, (sum, row) => sum + (row['partial_workout_count'] as int? ?? 0));
    final previousScheduled = previousStats.fold<int>(
        0, (sum, row) => sum + (row['scheduled_workout_count'] as int? ?? 0));
    final trainingDays = currentStats.length;

    final consecutiveDays =
        _calculateConsecutiveDaysFromSummary(currentStats);

    return TrainingFrequency(
      scheduledWorkouts: scheduledWorkouts,
      totalWorkouts: totalWorkouts,
      completedWorkouts: completedWorkouts,
      partialWorkouts: partialWorkouts,
      trainingDays: trainingDays,
      totalHours: totalWorkouts.toDouble(),
      averageHours: trainingDays > 0 ? totalWorkouts / trainingDays : 0.0,
      consecutiveDays: consecutiveDays,
      comparisonValue: scheduledWorkouts - previousScheduled,
    );
  }

  /// 計算訓練量趨勢
  List<TrainingVolumePoint> calculateVolumeHistory(
      List<Map<String, dynamic>> summaryData) {
    final points = <TrainingVolumePoint>[];

    for (var row in summaryData) {
      final date = DateTimeUtils.parseIsoTimestamp(row['date'] as String);
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
  ///
  /// ⭐ v5.0: 使用 primaryMuscle → parentGroup 取代 v4 bodyPart 中文字串
  List<BodyPartStats> calculateBodyPartStats(
      List<UnifiedWorkoutData> workouts) {
    final Map<String, _BodyPartAccumulator> stats = {};

    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        if (!exercise.isCompleted) continue;

        final exerciseInfo = _exerciseCache[exercise.exerciseId];
        if (exerciseInfo == null) continue;

        // v5.0: primaryMuscle → parentGroup（6 個分區）
        final primaryMuscle = exerciseInfo.primaryMuscle ?? '';
        final parentGroup =
            ExerciseLabels.muscleToGroup[primaryMuscle] ?? '';
        if (parentGroup.isEmpty) continue;

        final volume = exercise.weight * exercise.reps * exercise.sets;
        final displayName = ExerciseLabels.resolve(
            ExerciseLabels.muscleGroups, parentGroup);

        stats.putIfAbsent(
          parentGroup,
          () => _BodyPartAccumulator(
              bodyPart: displayName, parentGroupId: parentGroup),
        );
        stats[parentGroup]!.addExercise(volume);
      }
    }

    final totalVolume = stats.values.fold<double>(
      0,
      (sum, stat) => sum + stat.totalVolume,
    );

    final result = stats.values.map((accumulator) {
      return BodyPartStats(
        bodyPart: accumulator.bodyPart,
        parentGroupId: accumulator.parentGroupId,
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

  /// 計算特定肌群統計（在某個 parentGroup 內按 primaryMuscle 分組）
  ///
  /// ⭐ v5.0: 參數改為 parentGroup ID（如 'chest'），
  /// 取代 v4 的中文 bodyPart 字串。
  List<SpecificMuscleStats> calculateSpecificMuscleStats(
    List<UnifiedWorkoutData> workouts,
    String parentGroup,
  ) {
    final Map<String, _MuscleAccumulator> stats = {};
    double totalVolumeForGroup = 0;

    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        if (!exercise.isCompleted) continue;

        final exerciseInfo = _exerciseCache[exercise.exerciseId];
        if (exerciseInfo == null) continue;

        // v5.0: 用 muscleToGroup 判斷歸屬
        final primaryMuscle = exerciseInfo.primaryMuscle ?? '';
        final group = ExerciseLabels.muscleToGroup[primaryMuscle] ?? '';
        if (group != parentGroup) continue;

        final volume = exercise.weight * exercise.reps * exercise.sets;
        totalVolumeForGroup += volume;

        final displayName = ExerciseLabels.resolve(
            ExerciseLabels.muscles, primaryMuscle);

        stats.putIfAbsent(
          primaryMuscle,
          () => _MuscleAccumulator(muscleGroup: displayName),
        );
        stats[primaryMuscle]!.addExercise(volume);
      }
    }

    if (stats.isEmpty) return [];

    final result = stats.values.map((accumulator) {
      return SpecificMuscleStats(
        specificMuscle: accumulator.muscleGroup,
        totalVolume: accumulator.totalVolume,
        workoutCount: accumulator.exerciseCount,
        percentage: totalVolumeForGroup > 0
            ? accumulator.totalVolume / totalVolumeForGroup
            : 0,
      );
    }).toList();

    result.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));
    return result;
  }

  /// 計算訓練類型統計
  ///
  /// ⭐ v5.0: 改為從 workouts + exerciseCache 計算（使用 pplTags），
  /// 取代 v4 從 daily_workout_summary 讀取永遠為 0 的計數。
  List<TrainingTypeStats> calculateTrainingTypeStats(
      List<UnifiedWorkoutData> workouts) {
    int resistanceCount = 0;
    int cardioCount = 0;
    int mobilityCount = 0;

    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        if (!exercise.isCompleted) continue;

        final exerciseInfo = _exerciseCache[exercise.exerciseId];
        if (exerciseInfo == null) continue;

        final pplTags = exerciseInfo.pplTags;
        if (pplTags.contains('cardio')) {
          cardioCount++;
        } else if (pplTags.contains('mobility')) {
          mobilityCount++;
        } else {
          // push/pull/legs/core 都算阻力訓練
          resistanceCount++;
        }
      }
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
        .map((row) => DateTimeUtils.parseIsoTimestamp(row['date'] as String))
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
  final String bodyPart;        // 顯示名稱
  final String parentGroupId;   // parent_group ID
  double totalVolume = 0;
  int exerciseCount = 0;

  _BodyPartAccumulator({required this.bodyPart, required this.parentGroupId});

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

