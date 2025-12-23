/// 時間範圍枚舉
enum TimeRange {
  week,       // 本週
  month,      // 本月
  threeMonth, // 三個月
  year,       // 本年
}

/// 時間範圍擴展方法
extension TimeRangeExtension on TimeRange {
  /// 獲取顯示名稱
  String get displayName {
    switch (this) {
      case TimeRange.week:
        return '本週';
      case TimeRange.month:
        return '本月';
      case TimeRange.threeMonth:
        return '三個月';
      case TimeRange.year:
        return '本年';
    }
  }

  /// 獲取起始日期
  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case TimeRange.week:
        return now.subtract(Duration(days: 7));
      case TimeRange.month:
        return DateTime(now.year, now.month, 1);
      case TimeRange.threeMonth:
        return DateTime(now.year, now.month - 3, 1);
      case TimeRange.year:
        return DateTime(now.year, 1, 1);
    }
  }

  /// 獲取結束日期
  DateTime get endDate => DateTime.now();
}

/// 訓練頻率統計
class TrainingFrequency {
  final int totalWorkouts;      // 總訓練次數
  final double totalHours;       // 總訓練時長（小時）
  final double averageHours;     // 平均訓練時長
  final int consecutiveDays;     // 連續訓練天數
  final int comparisonValue;     // 與上期對比值（正數表示增加）

  TrainingFrequency({
    required this.totalWorkouts,
    required this.totalHours,
    required this.averageHours,
    required this.consecutiveDays,
    required this.comparisonValue,
  });

  /// 是否有增長
  bool get hasGrowth => comparisonValue > 0;

  /// 對比百分比
  String get comparisonPercentage {
    if (comparisonValue == 0) return '0%';
    final sign = comparisonValue > 0 ? '+' : '';
    return '$sign$comparisonValue';
  }

  @override
  String toString() => 'TrainingFrequency(total: $totalWorkouts, hours: $totalHours)';
}

/// 訓練量數據點（用於圖表）
class TrainingVolumePoint {
  final DateTime date;           // 日期
  final double totalVolume;      // 總訓練量（kg）
  final int totalSets;           // 總組數
  final int workoutCount;        // 訓練次數

  TrainingVolumePoint({
    required this.date,
    required this.totalVolume,
    required this.totalSets,
    required this.workoutCount,
  });

  /// 格式化日期顯示
  String get formattedDate {
    return '${date.month}/${date.day}';
  }

  @override
  String toString() => 'VolumePoint(${formattedDate}: ${totalVolume.toStringAsFixed(0)} kg)';
}

/// 身體部位統計
class BodyPartStats {
  final String bodyPart;         // 身體部位名稱
  final double totalVolume;      // 總訓練量
  final int workoutCount;        // 訓練次數
  final int exerciseCount;       // 動作數量
  final double percentage;       // 佔比（0-1）

  BodyPartStats({
    required this.bodyPart,
    required this.totalVolume,
    required this.workoutCount,
    required this.exerciseCount,
    required this.percentage,
  });

  /// 格式化訓練量顯示
  String get formattedVolume {
    if (totalVolume >= 1000) {
      return '${(totalVolume / 1000).toStringAsFixed(1)}k kg';
    }
    return '${totalVolume.toStringAsFixed(0)} kg';
  }

  /// 格式化百分比顯示
  String get formattedPercentage {
    return '${(percentage * 100).toStringAsFixed(0)}%';
  }

  @override
  String toString() => 'BodyPartStats($bodyPart: $formattedVolume, $formattedPercentage)';
}

/// 特定肌群統計（細分）
class SpecificMuscleStats {
  final String specificMuscle;   // 特定肌群名稱
  final double totalVolume;      // 總訓練量
  final int workoutCount;        // 訓練次數
  final double percentage;       // 在該身體部位中的佔比

  SpecificMuscleStats({
    required this.specificMuscle,
    required this.totalVolume,
    required this.workoutCount,
    required this.percentage,
  });

  /// 格式化訓練量顯示
  String get formattedVolume {
    if (totalVolume >= 1000) {
      return '${(totalVolume / 1000).toStringAsFixed(1)}k kg';
    }
    return '${totalVolume.toStringAsFixed(0)} kg';
  }

  /// 格式化百分比顯示
  String get formattedPercentage {
    return '${(percentage * 100).toStringAsFixed(0)}%';
  }

  @override
  String toString() => 'SpecificMuscleStats($specificMuscle: $formattedVolume)';
}

/// 訓練類型統計
class TrainingTypeStats {
  final String trainingType;     // 訓練類型（重訓/有氧/伸展）
  final int workoutCount;        // 訓練次數
  final double percentage;       // 佔比

  TrainingTypeStats({
    required this.trainingType,
    required this.workoutCount,
    required this.percentage,
  });

  /// 格式化百分比顯示
  String get formattedPercentage {
    return '${(percentage * 100).toStringAsFixed(0)}%';
  }

  @override
  String toString() => 'TrainingTypeStats($trainingType: $formattedPercentage)';
}

/// 器材類別統計
class EquipmentStats {
  final String equipment;        // 器材名稱
  final int usageCount;          // 使用次數
  final double percentage;       // 佔比

  EquipmentStats({
    required this.equipment,
    required this.usageCount,
    required this.percentage,
  });

  /// 格式化百分比顯示
  String get formattedPercentage {
    return '${(percentage * 100).toStringAsFixed(0)}%';
  }

  @override
  String toString() => 'EquipmentStats($equipment: $usageCount 次)';
}

/// 個人最佳記錄（PR）
class PersonalRecord {
  final String exerciseId;       // 動作 ID
  final String exerciseName;     // 動作名稱
  final double maxWeight;        // 最大重量
  final int reps;                // 次數
  final DateTime achievedDate;   // 達成日期
  final String bodyPart;         // 身體部位
  final bool isNew;              // 是否為新記錄（本週內達成）

  PersonalRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.maxWeight,
    required this.reps,
    required this.achievedDate,
    required this.bodyPart,
    this.isNew = false,
  });

  /// 格式化重量顯示
  String get formattedWeight {
    return '${maxWeight.toStringAsFixed(1)} kg × $reps';
  }

  /// 格式化日期顯示
  String get formattedDate {
    return '${achievedDate.year}-${achievedDate.month.toString().padLeft(2, '0')}-${achievedDate.day.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => 'PR($exerciseName: $formattedWeight)';
}

/// 完整的統計數據
class StatisticsData {
  final TimeRange timeRange;                           // 時間範圍
  final TrainingFrequency frequency;                   // 訓練頻率
  final List<TrainingVolumePoint> volumeHistory;       // 訓練量歷史
  final List<BodyPartStats> bodyPartStats;             // 身體部位統計
  final Map<String, List<SpecificMuscleStats>> muscleDetails; // 特定肌群細節
  final List<TrainingTypeStats> trainingTypeStats;     // 訓練類型統計
  final List<EquipmentStats> equipmentStats;           // 器材統計
  final List<PersonalRecord> personalRecords;          // 個人記錄
  
  // 新增統計
  final List<ExerciseStrengthProgress> strengthProgress;  // 力量進步追蹤
  final MuscleGroupBalance? muscleGroupBalance;           // 肌群平衡分析
  final TrainingCalendarData? calendarData;               // 訓練日曆數據
  final CompletionRateStats? completionRate;              // 完成率統計

  StatisticsData({
    required this.timeRange,
    required this.frequency,
    required this.volumeHistory,
    required this.bodyPartStats,
    required this.muscleDetails,
    required this.trainingTypeStats,
    required this.equipmentStats,
    required this.personalRecords,
    this.strengthProgress = const [],
    this.muscleGroupBalance,
    this.calendarData,
    this.completionRate,
  });

  /// 創建空的統計數據
  factory StatisticsData.empty(TimeRange timeRange) {
    return StatisticsData(
      timeRange: timeRange,
      frequency: TrainingFrequency(
        totalWorkouts: 0,
        totalHours: 0,
        averageHours: 0,
        consecutiveDays: 0,
        comparisonValue: 0,
      ),
      volumeHistory: [],
      bodyPartStats: [],
      muscleDetails: {},
      trainingTypeStats: [],
      equipmentStats: [],
      personalRecords: [],
      strengthProgress: [],
      muscleGroupBalance: null,
      calendarData: null,
      completionRate: null,
    );
  }

  /// 是否有數據
  bool get hasData => frequency.totalWorkouts > 0;

  @override
  String toString() => 'StatisticsData(${timeRange.displayName}, ${frequency.totalWorkouts} workouts)';
}

/// 訓練建議
class TrainingSuggestion {
  final String title;            // 建議標題
  final String description;      // 建議描述
  final SuggestionType type;     // 建議類型

  TrainingSuggestion({
    required this.title,
    required this.description,
    required this.type,
  });

  @override
  String toString() => 'Suggestion($title)';
}

/// 建議類型
enum SuggestionType {
  warning,    // 警告（例如：某肌群訓練不足）
  info,       // 資訊（例如：訓練多樣性良好）
  success,    // 成功（例如：訓練頻率優秀）
}

/// 力量進步數據點
class StrengthProgressPoint {
  final DateTime date;           // 日期
  final double weight;           // 重量
  final int reps;                // 次數
  final double estimatedOneRM;   // 估算 1RM
  final bool isPR;               // 是否為 PR

  StrengthProgressPoint({
    required this.date,
    required this.weight,
    required this.reps,
    required this.estimatedOneRM,
    this.isPR = false,
  });

  /// 格式化日期顯示
  String get formattedDate => '${date.month}/${date.day}';

  @override
  String toString() => 'StrengthPoint(${formattedDate}: ${weight}kg × $reps)';
}

/// 動作力量進步追蹤
class ExerciseStrengthProgress {
  final String exerciseId;                        // 動作 ID
  final String exerciseName;                      // 動作名稱
  final String bodyPart;                          // 身體部位
  final List<StrengthProgressPoint> history;      // 歷史記錄
  final double currentMax;                        // 當前最大重量
  final double previousMax;                       // 上期最大重量
  final double progressPercentage;                // 進步百分比
  final int totalSets;                            // 總組數
  final double averageWeight;                     // 平均重量

  ExerciseStrengthProgress({
    required this.exerciseId,
    required this.exerciseName,
    required this.bodyPart,
    required this.history,
    required this.currentMax,
    required this.previousMax,
    required this.progressPercentage,
    required this.totalSets,
    required this.averageWeight,
  });

  /// 是否有進步
  bool get hasProgress => progressPercentage > 0;

  /// 格式化進步百分比
  String get formattedProgress {
    if (progressPercentage == 0) return '持平';
    final sign = progressPercentage > 0 ? '+' : '';
    return '$sign${progressPercentage.toStringAsFixed(1)}%';
  }

  /// 格式化當前最大重量
  String get formattedCurrentMax => '${currentMax.toStringAsFixed(1)} kg';

  @override
  String toString() => 'StrengthProgress($exerciseName: $formattedProgress)';
}

/// 肌群類別（推/拉/腿/核心）
enum MuscleGroupCategory {
  push,    // 推（胸、肩、三頭）
  pull,    // 拉（背、二頭）
  legs,    // 腿部
  core,    // 核心
  other,   // 其他
}

extension MuscleGroupCategoryExtension on MuscleGroupCategory {
  String get displayName {
    switch (this) {
      case MuscleGroupCategory.push:
        return '推（胸肩三頭）';
      case MuscleGroupCategory.pull:
        return '拉（背二頭）';
      case MuscleGroupCategory.legs:
        return '腿部';
      case MuscleGroupCategory.core:
        return '核心';
      case MuscleGroupCategory.other:
        return '其他';
    }
  }

  String get emoji {
    switch (this) {
      case MuscleGroupCategory.push:
        return '💪';
      case MuscleGroupCategory.pull:
        return '🏋️';
      case MuscleGroupCategory.legs:
        return '🦵';
      case MuscleGroupCategory.core:
        return '🎯';
      case MuscleGroupCategory.other:
        return '📝';
    }
  }
}

/// 肌群平衡統計
class MuscleGroupBalanceStats {
  final MuscleGroupCategory category;  // 肌群類別
  final double totalVolume;            // 總訓練量
  final int workoutCount;              // 訓練次數
  final int exerciseCount;             // 動作數量
  final double percentage;             // 佔比（0-1）
  final List<String> topExercises;     // 主要動作

  MuscleGroupBalanceStats({
    required this.category,
    required this.totalVolume,
    required this.workoutCount,
    required this.exerciseCount,
    required this.percentage,
    required this.topExercises,
  });

  /// 格式化訓練量
  String get formattedVolume {
    if (totalVolume >= 1000) {
      return '${(totalVolume / 1000).toStringAsFixed(1)}k kg';
    }
    return '${totalVolume.toStringAsFixed(0)} kg';
  }

  /// 格式化百分比
  String get formattedPercentage => '${(percentage * 100).toStringAsFixed(0)}%';

  @override
  String toString() => 'BalanceStats(${category.displayName}: $formattedPercentage)';
}

/// 肌群平衡分析
class MuscleGroupBalance {
  final List<MuscleGroupBalanceStats> stats;  // 各肌群統計
  final bool isPushPullBalanced;              // 推拉是否平衡
  final double pushPullRatio;                 // 推拉比例
  final String balanceStatus;                 // 平衡狀態描述
  final List<String> recommendations;         // 建議

  MuscleGroupBalance({
    required this.stats,
    required this.isPushPullBalanced,
    required this.pushPullRatio,
    required this.balanceStatus,
    required this.recommendations,
  });

  /// 獲取推動作統計
  MuscleGroupBalanceStats? get pushStats =>
      stats.where((s) => s.category == MuscleGroupCategory.push).firstOrNull;

  /// 獲取拉動作統計
  MuscleGroupBalanceStats? get pullStats =>
      stats.where((s) => s.category == MuscleGroupCategory.pull).firstOrNull;

  /// 獲取腿部統計
  MuscleGroupBalanceStats? get legStats =>
      stats.where((s) => s.category == MuscleGroupCategory.legs).firstOrNull;

  @override
  String toString() => 'MuscleBalance($balanceStatus)';
}

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
  String toString() => 'CalendarDay(${formattedDate}: ${hasWorkout ? 'Workout' : 'Rest'})';
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

/// 訓練完成率統計
class CompletionRateStats {
  final int totalPlannedSets;      // 計劃總組數
  final int completedSets;         // 完成組數
  final int failedSets;            // 失敗組數
  final double completionRate;     // 完成率（0-1）
  final Map<String, int> incompleteExercises; // 未完成的動作（動作名: 失敗組數）
  final List<String> weakPoints;   // 弱點動作

  CompletionRateStats({
    required this.totalPlannedSets,
    required this.completedSets,
    required this.failedSets,
    required this.completionRate,
    required this.incompleteExercises,
    required this.weakPoints,
  });

  /// 格式化完成率
  String get formattedCompletionRate => '${(completionRate * 100).toStringAsFixed(0)}%';

  /// 是否表現優秀（>=95%）
  bool get isExcellent => completionRate >= 0.95;

  /// 是否需要調整（<85%）
  bool get needsAdjustment => completionRate < 0.85;

  @override
  String toString() => 'CompletionRate($formattedCompletionRate)';
}

