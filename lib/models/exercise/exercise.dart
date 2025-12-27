import 'exercise_type_enum.dart';
import 'exercise_mapper.dart';

/// 訓練動作模型
///
/// 表示應用中的標準訓練動作，包含詳細的分類和描述信息
class Exercise {
  final String id;            // 唯一標識符
  final String name;          // 動作名稱
  final String nameEn;        // 英文名稱
  final List<String> bodyParts; // 鍛鍊部位（舊欄位，向後相容）
  final String type;          // 訓練類型（舊欄位，向後相容）
  final String equipment;     // 所需器材（舊欄位，向後相容）
  final String jointType;     // 關節類型
  final String level1;        // 一級分類（舊欄位，向後相容）
  final String level2;        // 二級分類（舊欄位，向後相容）
  final String level3;        // 三級分類（舊欄位，向後相容）
  final String level4;        // 四級分類（舊欄位，向後相容）
  final String level5;        // 五級分類（舊欄位，向後相容）
  
  // 新的專業 5 層分類欄位（2024-12-23 新增）
  final String trainingType;          // 訓練類型（重訓/有氧/伸展/功能性訓練）
  final String bodyPart;              // 身體部位（主要肌群）
  final String specificMuscle;        // 特定肌群（例如：上胸、闊背肌、股四頭）
  final String equipmentCategory;     // 器材類別（自由重量/機械式/徒手/功能性訓練）
  final String equipmentSubcategory;  // 器材子類別（啞鈴/槓鈴/Cable滑輪等）
  
  // 英文欄位（2024-12-26 新增 - 雙語系統支援）
  final String trainingTypeEn;        // 訓練類型英文
  final String bodyPartEn;            // 身體部位英文
  final String specificMuscleEn;      // 特定肌群英文
  final String equipmentCategoryEn;   // 器材類別英文
  final String equipmentSubcategoryEn; // 器材子類別英文
  
  final String? actionName;   // 動作名稱別名
  final String description;   // 動作描述
  final String imageUrl;      // 圖片URL
  final String videoUrl;      // 視頻URL
  final List<String> apps;    // 適用的應用列表
  final DateTime createdAt;   // 創建時間

  /// 創建一個訓練動作實例
  Exercise({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.bodyParts,
    required this.type,
    required this.equipment,
    required this.jointType,
    required this.level1,
    required this.level2,
    required this.level3,
    required this.level4,
    required this.level5,
    // 新的專業分類欄位（中文）
    this.trainingType = '',
    this.bodyPart = '',
    this.specificMuscle = '',
    this.equipmentCategory = '',
    this.equipmentSubcategory = '',
    // 新的專業分類欄位（英文）
    this.trainingTypeEn = '',
    this.bodyPartEn = '',
    this.specificMuscleEn = '',
    this.equipmentCategoryEn = '',
    this.equipmentSubcategoryEn = '',
    this.actionName,
    required this.description,
    this.imageUrl = '',
    required this.videoUrl,
    required this.apps,
    required this.createdAt,
  });

  /// 從 Supabase 資料創建對象
  /// 
  /// Supabase PostgreSQL 使用 snake_case 欄位名稱
  factory Exercise.fromSupabase(Map<String, dynamic> data) {
    return ExerciseMapper.fromSupabase(data);
  }

  /// 轉換為 JSON 數據格式
  Map<String, dynamic> toJson() {
    return ExerciseMapper.toJson(this);
  }

  /// 從 JSON 創建對象
  static Exercise fromJson(Map<String, dynamic> json) {
    return ExerciseMapper.fromJson(json);
  }
  
  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
  Exercise copyWith({
    String? id,
    String? name,
    String? nameEn,
    List<String>? bodyParts,
    String? type,
    String? equipment,
    String? jointType,
    String? level1,
    String? level2,
    String? level3,
    String? level4,
    String? level5,
    String? trainingType,
    String? bodyPart,
    String? specificMuscle,
    String? equipmentCategory,
    String? equipmentSubcategory,
    String? trainingTypeEn,
    String? bodyPartEn,
    String? specificMuscleEn,
    String? equipmentCategoryEn,
    String? equipmentSubcategoryEn,
    String? actionName,
    String? description,
    String? imageUrl,
    String? videoUrl,
    List<String>? apps,
    DateTime? createdAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      bodyParts: bodyParts ?? this.bodyParts,
      type: type ?? this.type,
      equipment: equipment ?? this.equipment,
      jointType: jointType ?? this.jointType,
      level1: level1 ?? this.level1,
      level2: level2 ?? this.level2,
      level3: level3 ?? this.level3,
      level4: level4 ?? this.level4,
      level5: level5 ?? this.level5,
      trainingType: trainingType ?? this.trainingType,
      bodyPart: bodyPart ?? this.bodyPart,
      specificMuscle: specificMuscle ?? this.specificMuscle,
      equipmentCategory: equipmentCategory ?? this.equipmentCategory,
      equipmentSubcategory: equipmentSubcategory ?? this.equipmentSubcategory,
      trainingTypeEn: trainingTypeEn ?? this.trainingTypeEn,
      bodyPartEn: bodyPartEn ?? this.bodyPartEn,
      specificMuscleEn: specificMuscleEn ?? this.specificMuscleEn,
      equipmentCategoryEn: equipmentCategoryEn ?? this.equipmentCategoryEn,
      equipmentSubcategoryEn: equipmentSubcategoryEn ?? this.equipmentSubcategoryEn,
      actionName: actionName ?? this.actionName,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      apps: apps ?? this.apps,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// 獲取訓練類型的枚舉值
  ExerciseType get exerciseType => ExerciseTypeExtension.fromString(type);
  
  @override
  String toString() => 'Exercise(id: $id, name: $name, type: $type)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

