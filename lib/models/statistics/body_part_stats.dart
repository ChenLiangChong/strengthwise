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

