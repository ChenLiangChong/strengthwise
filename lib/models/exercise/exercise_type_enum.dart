/// 訓練類型枚舉
enum ExerciseType {
  strength,     // 力量訓練
  cardio,       // 有氧訓練
  flexibility,  // 柔韌性訓練
  balance,      // 平衡訓練
  custom        // 自定義
}

/// 訓練類型枚舉擴展方法
extension ExerciseTypeExtension on ExerciseType {
  /// 獲取類型的顯示名稱
  String get displayName {
    switch (this) {
      case ExerciseType.strength: return '力量訓練';
      case ExerciseType.cardio: return '有氧訓練';
      case ExerciseType.flexibility: return '柔韌性訓練';
      case ExerciseType.balance: return '平衡訓練';
      case ExerciseType.custom: return '自訂';
    }
  }
  
  /// 從字符串轉換為枚舉值
  static ExerciseType fromString(String value) {
    switch (value) {
      case '力量訓練': return ExerciseType.strength;
      case '有氧訓練': return ExerciseType.cardio;
      case '柔韌性訓練': return ExerciseType.flexibility;
      case '平衡訓練': return ExerciseType.balance;
      case '自訂': return ExerciseType.custom;
      default: return ExerciseType.custom;
    }
  }
}

