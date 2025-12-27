import '../../../models/statistics_model.dart';
import '../../../models/exercise_model.dart';
import 'statistics_models.dart';

/// 肌群平衡分析器
///
/// 分析訓練的肌群平衡狀況
class MuscleBalanceAnalyzer {
  final Map<String, Exercise> _exerciseCache;

  MuscleBalanceAnalyzer({required Map<String, Exercise> exerciseCache})
      : _exerciseCache = exerciseCache;

  /// 計算肌群平衡
  MuscleGroupBalance calculateBalance(
    List<UnifiedWorkoutData> workouts,
  ) {
    // 按肌群類別統計
    final Map<MuscleGroupCategory, _MuscleGroupAccumulator> accumulators = {
      MuscleGroupCategory.push: _MuscleGroupAccumulator(),
      MuscleGroupCategory.pull: _MuscleGroupAccumulator(),
      MuscleGroupCategory.legs: _MuscleGroupAccumulator(),
      MuscleGroupCategory.core: _MuscleGroupAccumulator(),
      MuscleGroupCategory.other: _MuscleGroupAccumulator(),
    };

    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        if (!exercise.isCompleted) continue;

        // 載入動作分類
        final exerciseData = _exerciseCache[exercise.exerciseId];
        final bodyPart = exerciseData?.bodyPart.isNotEmpty == true
            ? exerciseData!.bodyPart
            : '';

        // 判斷肌群類別
        final category = _categorizeMuscleGroup(bodyPart);
        final volume =
            (exercise.weight * exercise.reps * exercise.sets).toDouble();

        accumulators[category]!.addExercise(
          exercise.exerciseName,
          volume,
        );
      }
    }

    // 計算總訓練量
    final totalVolume = accumulators.values.fold<double>(
      0.0,
      (sum, acc) => sum + acc.totalVolume,
    );

    // 生成統計列表
    final stats = <MuscleGroupBalanceStats>[];
    for (var entry in accumulators.entries) {
      if (entry.value.totalVolume == 0) continue;

      final percentage = totalVolume > 0
          ? (entry.value.totalVolume / totalVolume).toDouble()
          : 0.0;
      stats.add(MuscleGroupBalanceStats(
        category: entry.key,
        totalVolume: entry.value.totalVolume,
        workoutCount: entry.value.workoutCount,
        exerciseCount: entry.value.exerciseCount,
        percentage: percentage,
        topExercises: entry.value.topExercises,
      ));
    }

    // 計算推拉比例
    final pushVolume = accumulators[MuscleGroupCategory.push]!.totalVolume;
    final pullVolume = accumulators[MuscleGroupCategory.pull]!.totalVolume;
    final pushPullRatio =
        pullVolume > 0 ? (pushVolume / pullVolume).toDouble() : 0.0;

    // 判斷是否平衡（推拉比例在 0.8-1.2 之間為平衡）
    final isPushPullBalanced = pushPullRatio >= 0.8 && pushPullRatio <= 1.2;

    // 生成平衡狀態描述和建議
    String balanceStatus;
    List<String> recommendations = [];

    if (isPushPullBalanced) {
      balanceStatus = '推拉平衡良好';
    } else if (pushPullRatio > 1.2) {
      balanceStatus = '推動作過多';
      recommendations.add('增加拉動作訓練（背部、二頭肌）');
    } else {
      balanceStatus = '拉動作過多';
      recommendations.add('增加推動作訓練（胸部、肩膀、三頭肌）');
    }

    // 檢查腿部訓練
    final legPercentage = totalVolume > 0
        ? accumulators[MuscleGroupCategory.legs]!.totalVolume / totalVolume
        : 0.0;
    if (legPercentage < 0.15) {
      recommendations.add('腿部訓練不足，建議增加深蹲、硬舉等動作');
    }

    return MuscleGroupBalance(
      stats: stats,
      isPushPullBalanced: isPushPullBalanced,
      pushPullRatio: pushPullRatio,
      balanceStatus: balanceStatus,
      recommendations: recommendations,
    );
  }

  /// 將身體部位分類到肌群類別
  MuscleGroupCategory _categorizeMuscleGroup(String bodyPart) {
    final part = bodyPart.toLowerCase();

    // 推動作
    if (part.contains('胸') ||
        part.contains('肩') ||
        (part.contains('手') && part.contains('三頭'))) {
      return MuscleGroupCategory.push;
    }

    // 拉動作
    if (part.contains('背') || (part.contains('手') && part.contains('二頭'))) {
      return MuscleGroupCategory.pull;
    }

    // 腿部
    if (part.contains('腿') || part.contains('臀')) {
      return MuscleGroupCategory.legs;
    }

    // 核心
    if (part.contains('核心') || part.contains('腹')) {
      return MuscleGroupCategory.core;
    }

    return MuscleGroupCategory.other;
  }
}

/// 肌群累加器（進階版，用於平衡分析）
class _MuscleGroupAccumulator {
  double totalVolume = 0;
  int workoutCount = 0;
  int exerciseCount = 0;
  final Set<String> exercises = {};

  void addExercise(String exerciseName, double volume) {
    totalVolume += volume;
    if (!exercises.contains(exerciseName)) {
      exercises.add(exerciseName);
      exerciseCount++;
    }
    workoutCount++;
  }

  List<String> get topExercises => exercises.take(5).toList();
}

