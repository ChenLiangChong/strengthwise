import 'package:cloud_firestore/cloud_firestore.dart';

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
    // 新的專業分類欄位
    this.trainingType = '',
    this.bodyPart = '',
    this.specificMuscle = '',
    this.equipmentCategory = '',
    this.equipmentSubcategory = '',
    this.actionName,
    required this.description,
    this.imageUrl = '',
    required this.videoUrl,
    required this.apps,
    required this.createdAt,
  });

  /// 從 Firestore 文檔創建對象
  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Exercise(
      id: doc.id,
      name: data['name'] ?? '',
      nameEn: data['nameEn'] ?? '',
      bodyParts: List<String>.from(data['bodyParts'] ?? []),
      type: data['type'] ?? '',
      equipment: data['equipment'] ?? '',
      jointType: data['jointType'] ?? '',
      level1: data['level1'] ?? '',
      level2: data['level2'] ?? '',
      level3: data['level3'] ?? '',
      level4: data['level4'] ?? '',
      level5: data['level5'] ?? '',
      // 新的專業分類欄位
      trainingType: data['trainingType'] ?? '',
      bodyPart: data['bodyPart'] ?? '',
      specificMuscle: data['specificMuscle'] ?? '',
      equipmentCategory: data['equipmentCategory'] ?? '',
      equipmentSubcategory: data['equipmentSubcategory'] ?? '',
      actionName: data['actionName'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      apps: List<String>.from(data['apps'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// 從 Supabase 資料創建對象
  /// 
  /// Supabase PostgreSQL 使用 snake_case 欄位名稱
  factory Exercise.fromSupabase(Map<String, dynamic> data) {
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
      // 新的專業分類欄位
      trainingType: data['training_type'] ?? '',
      bodyPart: data['body_part'] ?? '',
      specificMuscle: data['specific_muscle'] ?? '',
      equipmentCategory: data['equipment_category'] ?? '',
      equipmentSubcategory: data['equipment_subcategory'] ?? '',
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

  /// 轉換為 Firestore 可用的數據格式
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'nameEn': nameEn,
      'bodyParts': bodyParts,
      'type': type,
      'equipment': equipment,
      'jointType': jointType,
      'level1': level1,
      'level2': level2,
      'level3': level3,
      'level4': level4,
      'level5': level5,
      // 新的專業分類欄位
      'trainingType': trainingType,
      'bodyPart': bodyPart,
      'specificMuscle': specificMuscle,
      'equipmentCategory': equipmentCategory,
      'equipmentSubcategory': equipmentSubcategory,
      'actionName': actionName,
      'description': description,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'apps': apps,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 轉換為 JSON 數據格式
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'actionName': actionName,
      'nameEn': nameEn,
      'bodyParts': bodyParts,
      'jointType': jointType,
      'equipment': equipment,
      'type': type,
      'level1': level1,
      'level2': level2,
      'level3': level3,
      'level4': level4,
      'level5': level5,
      // 新的專業分類欄位
      'trainingType': trainingType,
      'bodyPart': bodyPart,
      'specificMuscle': specificMuscle,
      'equipmentCategory': equipmentCategory,
      'equipmentSubcategory': equipmentSubcategory,
      'description': description,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'apps': apps,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// 從 JSON 創建對象
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