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
  String toString() => 'StrengthPoint($formattedDate: ${weight}kg × $reps)';
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

