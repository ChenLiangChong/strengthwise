/// 自定義動作驗證器
class CustomExerciseValidator {
  /// 驗證動作名稱
  static void validateName(String name) {
    if (name.trim().isEmpty) {
      throw ArgumentError('動作名稱不能為空');
    }
    
    if (name.length > 50) {
      throw ArgumentError('動作名稱不能超過50個字符');
    }
  }

  /// 驗證身體部位
  static void validateBodyPart(String bodyPart) {
    if (bodyPart.trim().isEmpty) {
      throw ArgumentError('身體部位不能為空');
    }
  }

  /// 驗證動作 ID
  static void validateId(String exerciseId) {
    if (exerciseId.trim().isEmpty) {
      throw ArgumentError('動作ID不能為空');
    }
  }

  /// 驗證創建動作的參數
  static void validateCreateParams({
    required String name,
    required String bodyPart,
  }) {
    validateName(name);
    validateBodyPart(bodyPart);
  }

  /// 驗證更新動作的參數
  static void validateUpdateParams({
    required String exerciseId,
    String? name,
  }) {
    validateId(exerciseId);
    
    if (name != null && name.trim().isEmpty) {
      throw ArgumentError('新的動作名稱不能為空');
    }
  }
}

