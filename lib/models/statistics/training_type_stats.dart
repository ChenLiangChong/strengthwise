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

