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

