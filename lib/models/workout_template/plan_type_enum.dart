/// 訓練計劃類型枚舉（專業健身分類 - 簡化版）
///
/// 涵蓋常見的訓練目標和身體分化方式
enum PlanType {
  // === 按訓練目標分類 ===
  strength,        // 💪 力量訓練（1-5RM，神經適應）
  hypertrophy,     // 🏋️ 增肌訓練（6-12RM，肌肉肥大）
  fatLoss,         // 🔥 減脂訓練（循環訓練、代謝訓練）
  cardio,          // 🏃 有氧訓練（跑步、飛輪、划船）
  
  // === 按身體部位分化 ===
  fullBody,        // 🎯 全身訓練（新手、每週2-3次）
  upperBody,       // ⬆️ 上半身訓練
  lowerBody,       // ⬇️ 下半身訓練
  
  // === 輔助訓練 ===
  core,            // 🎪 核心訓練
  flexibility,     // 🧘 伸展恢復
  
  // === 其他 ===
  custom           // ⚙️ 自定義
}

/// 訓練計劃類型枚舉擴展方法
extension PlanTypeExtension on PlanType {
  /// 獲取類型的顯示名稱
  String get displayName {
    switch (this) {
      case PlanType.strength: return '力量訓練';
      case PlanType.hypertrophy: return '增肌訓練';
      case PlanType.fatLoss: return '減脂訓練';
      case PlanType.cardio: return '有氧訓練';
      case PlanType.fullBody: return '全身訓練';
      case PlanType.upperBody: return '上半身訓練';
      case PlanType.lowerBody: return '下半身訓練';
      case PlanType.core: return '核心訓練';
      case PlanType.flexibility: return '伸展恢復';
      case PlanType.custom: return '自定義';
    }
  }
  
  /// 獲取類型的圖示
  String get icon {
    switch (this) {
      case PlanType.strength: return '💪';
      case PlanType.hypertrophy: return '🏋️';
      case PlanType.fatLoss: return '🔥';
      case PlanType.cardio: return '🏃';
      case PlanType.fullBody: return '🎯';
      case PlanType.upperBody: return '⬆️';
      case PlanType.lowerBody: return '⬇️';
      case PlanType.core: return '🎪';
      case PlanType.flexibility: return '🧘';
      case PlanType.custom: return '⚙️';
    }
  }
  
  /// 獲取類型的簡短描述
  String get description {
    switch (this) {
      case PlanType.strength: return '1-5RM，提升最大力量';
      case PlanType.hypertrophy: return '6-12RM，增加肌肉量';
      case PlanType.fatLoss: return '高強度循環，燃脂塑形';
      case PlanType.cardio: return '有氧運動，提升心肺';
      case PlanType.fullBody: return '全身性訓練，適合新手';
      case PlanType.upperBody: return '上半身專項訓練';
      case PlanType.lowerBody: return '下半身專項訓練';
      case PlanType.core: return '核心穩定性訓練';
      case PlanType.flexibility: return '伸展放鬆，促進恢復';
      case PlanType.custom: return '自訂訓練計劃';
    }
  }
  
  /// 從字符串轉換為枚舉值
  static PlanType fromString(String value) {
    switch (value) {
      case '力量訓練': return PlanType.strength;
      case '增肌訓練': return PlanType.hypertrophy;
      case '減脂訓練': return PlanType.fatLoss;
      case '有氧訓練': return PlanType.cardio;
      case '全身訓練': return PlanType.fullBody;
      case '上半身訓練': return PlanType.upperBody;
      case '下半身訓練': return PlanType.lowerBody;
      case '核心訓練': return PlanType.core;
      case '伸展恢復': return PlanType.flexibility;
      case '自定義': return PlanType.custom;
      
      // 向後兼容舊值
      case '推動訓練': return PlanType.upperBody;
      case '拉動訓練': return PlanType.upperBody;
      case '腿部訓練': return PlanType.lowerBody;
      case '肌肉塑形': return PlanType.hypertrophy;
      case '耐力訓練': return PlanType.cardio;
      case '功能性訓練': return PlanType.fullBody;
      case '恢復訓練': return PlanType.flexibility;
      case '其他': return PlanType.custom;
      
      default: return PlanType.custom;
    }
  }
  
  /// 獲取所有訓練類型的列表（用於 UI 顯示）
  static List<String> get allDisplayNames {
    return PlanType.values.map((type) => type.displayName).toList();
  }
}

