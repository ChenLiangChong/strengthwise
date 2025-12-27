import 'custom_exercise.dart';

/// 自訂動作數據映射器
///
/// 負責在不同數據格式（JSON、Supabase）之間轉換 CustomExercise
class CustomExerciseMapper {
  /// 從 Supabase 數據創建對象（snake_case 欄位）
  static CustomExercise fromSupabase(Map<String, dynamic> json) {
    return CustomExercise(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      trainingType: json['training_type'] as String? ?? '阻力訓練',
      trainingTypeEn: json['training_type_en'] as String? ?? 'Resistance Training',
      bodyPart: json['body_part'] as String? ?? '其他',
      bodyPartEn: json['body_part_en'] as String? ?? 'Other',
      equipment: json['equipment'] as String? ?? '徒手',
      equipmentEn: json['equipment_en'] as String? ?? 'Bodyweight',
      description: json['description'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// 從 JSON 數據創建對象（客戶端格式）
  static CustomExercise fromJson(Map<String, dynamic> json) {
    return CustomExercise(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      trainingType: json['trainingType'] as String? ?? '阻力訓練',
      trainingTypeEn: json['trainingTypeEn'] as String? ?? 'Resistance Training',
      bodyPart: json['bodyPart'] as String? ?? '其他',
      bodyPartEn: json['bodyPartEn'] as String? ?? 'Other',
      equipment: json['equipment'] as String? ?? '徒手',
      equipmentEn: json['equipmentEn'] as String? ?? 'Bodyweight',
      description: json['description'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
    );
  }

  /// 轉換為 Supabase Map（用於 insert/update）
  static Map<String, dynamic> toSupabase(CustomExercise exercise) {
    return {
      'id': exercise.id,
      'name': exercise.name,
      'user_id': exercise.userId,
      'training_type': exercise.trainingType,
      'training_type_en': exercise.trainingTypeEn,
      'body_part': exercise.bodyPart,
      'body_part_en': exercise.bodyPartEn,
      'equipment': exercise.equipment,
      'equipment_en': exercise.equipmentEn,
      'description': exercise.description,
      'notes': exercise.notes,
      'created_at': exercise.createdAt.toIso8601String(),
      'updated_at': exercise.updatedAt.toIso8601String(),
    };
  }

  /// 轉換為 JSON 數據格式（用於本地存儲）
  static Map<String, dynamic> toJson(CustomExercise exercise) {
    return {
      'id': exercise.id,
      'name': exercise.name,
      'userId': exercise.userId,
      'trainingType': exercise.trainingType,
      'trainingTypeEn': exercise.trainingTypeEn,
      'bodyPart': exercise.bodyPart,
      'bodyPartEn': exercise.bodyPartEn,
      'equipment': exercise.equipment,
      'equipmentEn': exercise.equipmentEn,
      'description': exercise.description,
      'notes': exercise.notes,
      'createdAt': exercise.createdAt.millisecondsSinceEpoch,
      'updatedAt': exercise.updatedAt.millisecondsSinceEpoch,
    };
  }
}

