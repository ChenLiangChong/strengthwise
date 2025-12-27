import 'exercise.dart';

/// 訓練動作數據映射器
///
/// 負責在不同數據格式（JSON、Supabase）之間轉換 Exercise
class ExerciseMapper {
  /// 從 Supabase 資料創建對象
  /// 
  /// Supabase PostgreSQL 使用 snake_case 欄位名稱
  static Exercise fromSupabase(Map<String, dynamic> data) {
    return Exercise(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      nameEn: data['name_en'] ?? '',
      bodyParts: List<String>.from(data['body_parts'] ?? []),
      type: data['training_type'] ?? '',
      equipment: data['equipment'] ?? '',
      jointType: data['joint_type'] ?? '',
      level1: data['level1'] ?? '',
      level2: data['level2'] ?? '',
      level3: data['level3'] ?? '',
      level4: data['level4'] ?? '',
      level5: data['level5'] ?? '',
      // 新的專業分類欄位（中文）
      trainingType: data['training_type'] ?? '',
      bodyPart: data['body_part'] ?? '',
      specificMuscle: data['specific_muscle'] ?? '',
      equipmentCategory: data['equipment_category'] ?? '',
      equipmentSubcategory: data['equipment_subcategory'] ?? '',
      // 新的專業分類欄位（英文）
      trainingTypeEn: data['training_type_en'] ?? '',
      bodyPartEn: data['body_part_en'] ?? '',
      specificMuscleEn: data['specific_muscle_en'] ?? '',
      equipmentCategoryEn: data['equipment_category_en'] ?? '',
      equipmentSubcategoryEn: data['equipment_subcategory_en'] ?? '',
      actionName: data['action_name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image_url'] ?? '',
      videoUrl: data['video_url'] ?? '',
      apps: [], // Supabase 資料庫中無此欄位
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now(),
    );
  }

  /// 從 JSON 創建對象（客戶端格式）
  static Exercise fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      actionName: json['actionName'],
      nameEn: json['nameEn'] ?? '',
      bodyParts: List<String>.from(json['bodyParts'] ?? []),
      jointType: json['jointType'] ?? '',
      equipment: json['equipment'] ?? '',
      type: json['type'] ?? '',
      level1: json['level1'] ?? '',
      level2: json['level2'] ?? '',
      level3: json['level3'] ?? '',
      level4: json['level4'] ?? '',
      level5: json['level5'] ?? '',
      // 新的專業分類欄位
      trainingType: json['trainingType'] ?? '',
      bodyPart: json['bodyPart'] ?? '',
      specificMuscle: json['specificMuscle'] ?? '',
      equipmentCategory: json['equipmentCategory'] ?? '',
      equipmentSubcategory: json['equipmentSubcategory'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      apps: List<String>.from(json['apps'] ?? []),
      createdAt: json['createdAt'] != null ? 
                 DateTime.fromMillisecondsSinceEpoch(json['createdAt']) : 
                 DateTime.now(),
    );
  }

  /// 轉換為 JSON 數據格式
  static Map<String, dynamic> toJson(Exercise exercise) {
    return {
      'id': exercise.id,
      'name': exercise.name,
      'actionName': exercise.actionName,
      'nameEn': exercise.nameEn,
      'bodyParts': exercise.bodyParts,
      'jointType': exercise.jointType,
      'equipment': exercise.equipment,
      'type': exercise.type,
      'level1': exercise.level1,
      'level2': exercise.level2,
      'level3': exercise.level3,
      'level4': exercise.level4,
      'level5': exercise.level5,
      // 新的專業分類欄位
      'trainingType': exercise.trainingType,
      'bodyPart': exercise.bodyPart,
      'specificMuscle': exercise.specificMuscle,
      'equipmentCategory': exercise.equipmentCategory,
      'equipmentSubcategory': exercise.equipmentSubcategory,
      'description': exercise.description,
      'imageUrl': exercise.imageUrl,
      'videoUrl': exercise.videoUrl,
      'apps': exercise.apps,
      'createdAt': exercise.createdAt.millisecondsSinceEpoch,
    };
  }
}

