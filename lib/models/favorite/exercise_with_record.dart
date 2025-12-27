/// 有訓練記錄的動作（用於分類導航）
class ExerciseWithRecord {
  final String exerciseId; // 動作 ID
  final String exerciseName; // 動作名稱
  final String bodyPart; // 身體部位
  final String trainingType; // 訓練類型（心肺適能訓練、活動度與伸展、阻力訓練）
  final DateTime lastTrainingDate; // 最後訓練日期
  final double maxWeight; // 最大重量
  final int totalSets; // 總組數
  final bool isFavorite; // 是否已收藏
  final bool isCustom; // 是否為自訂動作

  ExerciseWithRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.bodyPart,
    required this.trainingType,
    required this.lastTrainingDate,
    required this.maxWeight,
    required this.totalSets,
    this.isFavorite = false,
    this.isCustom = false, // 預設為系統動作
  });

  /// 格式化最後訓練日期
  String get formattedLastTrainingDate {
    final now = DateTime.now();
    final difference = now.difference(lastTrainingDate).inDays;

    if (difference == 0) {
      return '今天';
    } else if (difference == 1) {
      return '昨天';
    } else if (difference < 7) {
      return '$difference 天前';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks 週前';
    } else {
      final months = (difference / 30).floor();
      return '$months 個月前';
    }
  }

  /// 格式化最大重量
  String get formattedMaxWeight {
    return '${maxWeight.toStringAsFixed(1)} kg';
  }

  @override
  String toString() => 'ExerciseWithRecord($exerciseName: $formattedMaxWeight)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseWithRecord && other.exerciseId == exerciseId;
  }

  @override
  int get hashCode => exerciseId.hashCode;
}

