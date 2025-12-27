import '../../../models/statistics_model.dart';
import '../../../models/exercise_model.dart';
import 'statistics_models.dart';

/// 訓練日曆生成器
///
/// 生成訓練日曆數據
class TrainingCalendarGenerator {
  final Map<String, Exercise> _exerciseCache;

  TrainingCalendarGenerator({required Map<String, Exercise> exerciseCache})
      : _exerciseCache = exerciseCache;

  /// 生成訓練日曆
  TrainingCalendarData generateCalendar(
    List<UnifiedWorkoutData> workouts,
    DateTime startDate,
    DateTime endDate,
  ) {
    // 按日期分組
    final Map<String, List<UnifiedWorkoutData>> workoutsByDate = {};
    for (var workout in workouts) {
      final dateKey = _getDateKey(workout.completedTime);
      workoutsByDate.putIfAbsent(dateKey, () => []);
      workoutsByDate[dateKey]!.add(workout);
    }

    // 生成日曆數據
    final List<TrainingCalendarDay> days = [];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final dateKey = _getDateKey(currentDate);
      final dayWorkouts = workoutsByDate[dateKey] ?? [];
      final hasWorkout = dayWorkouts.isNotEmpty;

      double totalVolume = 0;
      Set<String> bodyParts = {};

      for (var workout in dayWorkouts) {
        for (var exercise in workout.exercises) {
          if (!exercise.isCompleted) continue;

          totalVolume += exercise.weight * exercise.reps * exercise.sets;

          // 載入身體部位
          final exerciseData = _exerciseCache[exercise.exerciseId];
          if (exerciseData?.bodyPart.isNotEmpty == true) {
            bodyParts.add(exerciseData!.bodyPart);
          }
        }
      }

      // 計算強度等級（0-4）
      int intensity = 0;
      if (totalVolume > 0) {
        if (totalVolume > 10000)
          intensity = 4;
        else if (totalVolume > 7000)
          intensity = 3;
        else if (totalVolume > 4000)
          intensity = 2;
        else
          intensity = 1;
      }

      days.add(TrainingCalendarDay(
        date: currentDate,
        hasWorkout: hasWorkout,
        workoutCount: dayWorkouts.length,
        totalVolume: totalVolume,
        intensity: intensity,
        bodyParts: bodyParts.toList(),
      ));

      currentDate = currentDate.add(const Duration(days: 1));
    }

    // 計算連續訓練天數
    int currentStreak = 0;
    int maxStreak = 0;
    int tempStreak = 0;

    for (var i = days.length - 1; i >= 0; i--) {
      if (days[i].hasWorkout) {
        tempStreak++;
        if (i == days.length - 1) {
          currentStreak = tempStreak;
        }
        if (tempStreak > maxStreak) {
          maxStreak = tempStreak;
        }
      } else {
        if (i == days.length - 1) {
          currentStreak = 0;
        }
        tempStreak = 0;
      }
    }

    // 計算統計
    final trainingDays = days.where((d) => d.hasWorkout).toList();
    final totalRestDays = days.length - trainingDays.length;
    final averageVolume = trainingDays.isEmpty
        ? 0.0
        : trainingDays.fold<double>(0, (sum, d) => sum + d.totalVolume) /
            trainingDays.length;

    return TrainingCalendarData(
      days: days,
      maxStreak: maxStreak,
      currentStreak: currentStreak,
      averageVolume: averageVolume,
      totalRestDays: totalRestDays,
    );
  }

  /// 獲取日期鍵（YYYY-MM-DD）
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

