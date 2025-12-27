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

