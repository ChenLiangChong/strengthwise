/// 中英文對照工具類
class TranslationHelper {
  /// 訓練類型對照
  static const Map<String, String> trainingTypes = {
    '阻力訓練': 'Resistance Training',
    '心肺適能訓練': 'Cardio',
    '活動度與伸展': 'Flexibility',
  };

  /// 身體部位對照
  static const Map<String, String> bodyParts = {
    '胸部': 'Chest',
    '背部': 'Back',
    '腿部': 'Legs',
    '肩部': 'Shoulders',
    '手臂': 'Arms',
    '核心': 'Core',
    '其他': 'Other',
  };

  /// 器材對照
  static const Map<String, String> equipment = {
    '徒手': 'Bodyweight',
    '啞鈴': 'Dumbbell',
    '槓鈴': 'Barbell',
    '固定式機械': 'Machine',
    'Cable滑輪': 'Cable',
    '壺鈴': 'Kettlebell',
    '彈力帶': 'Resistance Band',
    '其他': 'Other',
  };

  /// 獲取訓練類型英文
  static String getTrainingTypeEn(String trainingType) {
    return trainingTypes[trainingType] ?? 'Resistance Training';
  }

  /// 獲取身體部位英文
  static String getBodyPartEn(String bodyPart) {
    return bodyParts[bodyPart] ?? 'Other';
  }

  /// 獲取器材英文
  static String getEquipmentEn(String equipmentName) {
    return equipment[equipmentName] ?? 'Other';
  }
}

