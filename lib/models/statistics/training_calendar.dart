/// 訓練日曆數據點
class TrainingCalendarDay {
  final DateTime date;           // 日期
  final bool hasWorkout;         // 是否有訓練
  final int workoutCount;        // 訓練次數
  final double totalVolume;      // 總訓練量
  final int intensity;           // 強度等級（0-4）
  final List<String> bodyParts;  // 訓練的身體部位

  TrainingCalendarDay({
    required this.date,
    required this.hasWorkout,
    required this.workoutCount,
    required this.totalVolume,
    required this.intensity,
    required this.bodyParts,
  });

  /// 是否為今天
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// 格式化日期
  String get formattedDate => '${date.month}/${date.day}';

  @override
  String toString() => 'CalendarDay($formattedDate: ${hasWorkout ? 'Workout' : 'Rest'})';
}

/// 訓練日曆熱力圖數據
class TrainingCalendarData {
  final List<TrainingCalendarDay> days;  // 日曆數據
  final int maxStreak;                   // 最長連續訓練天數
  final int currentStreak;               // 當前連續訓練天數
  final double averageVolume;            // 平均訓練量
  final int totalRestDays;               // 總休息天數

  TrainingCalendarData({
    required this.days,
    required this.maxStreak,
    required this.currentStreak,
    required this.averageVolume,
    required this.totalRestDays,
  });

  /// 獲取訓練天數
  int get trainingDays => days.where((d) => d.hasWorkout).length;

  /// 獲取訓練頻率（每週）
  double get weeklyFrequency {
    if (days.isEmpty) return 0;
    final weeks = days.length / 7;
    return trainingDays / weeks;
  }

  @override
  String toString() => 'CalendarData($trainingDays 天, 最長連續 $maxStreak 天)';
}

