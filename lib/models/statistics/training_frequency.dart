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

