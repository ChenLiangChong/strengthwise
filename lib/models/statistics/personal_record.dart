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

