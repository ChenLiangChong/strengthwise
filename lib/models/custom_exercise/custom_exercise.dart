import 'custom_exercise_mapper.dart';

/// 用戶自定義訓練動作模型
///
/// 用於表示用戶創建的自定義訓練動作。
/// 
/// 功能：
/// - 可按身體部位統計（胸/背/腿/肩/手臂/核心）
/// - 可追蹤力量進步（通過 workout_plans 記錄）
/// - 可設定器材類型
/// - 可選擇訓練類型（心肺適能訓練/活動度與伸展/阻力訓練）
/// - 支援雙語系統（中文/英文）
class CustomExercise {
  final String id;          // Firestore 相容 ID
  final String name;        // 動作名稱
  final String userId;      // 創建者 ID
  final String trainingType; // 訓練類型（中文）：心肺適能訓練/活動度與伸展/阻力訓練
  final String trainingTypeEn; // 訓練類型（英文）：Cardio/Flexibility/Resistance Training
  final String bodyPart;    // 身體部位（中文）：胸部/背部/腿部/肩部/手臂/核心
  final String bodyPartEn;  // 身體部位（英文）：Chest/Back/Legs/Shoulders/Arms/Core
  final String equipment;   // 器材（中文）：徒手/啞鈴/槓鈴/機械/Cable/其他
  final String equipmentEn; // 器材（英文）：Bodyweight/Dumbbell/Barbell/Machine/Cable/Other
  final String description; // 動作說明（選填）
  final String notes;       // 個人筆記（選填）
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 創建一個自定義訓練動作實例
  CustomExercise({
    required this.id,
    required this.name,
    required this.userId,
    this.trainingType = '阻力訓練',
    this.trainingTypeEn = 'Resistance Training',
    required this.bodyPart,
    this.bodyPartEn = '',
    this.equipment = '徒手',
    this.equipmentEn = 'Bodyweight',
    this.description = '',
    this.notes = '',
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  /// 從 Supabase 數據創建對象（snake_case 欄位）
  factory CustomExercise.fromSupabase(Map<String, dynamic> json) {
    return CustomExerciseMapper.fromSupabase(json);
  }

  /// 轉換為 Supabase Map（用於 insert/update）
  Map<String, dynamic> toSupabase() {
    return CustomExerciseMapper.toSupabase(this);
  }
  
  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
  CustomExercise copyWith({
    String? id,
    String? name,
    String? userId,
    String? trainingType,
    String? trainingTypeEn,
    String? bodyPart,
    String? bodyPartEn,
    String? equipment,
    String? equipmentEn,
    String? description,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      trainingType: trainingType ?? this.trainingType,
      trainingTypeEn: trainingTypeEn ?? this.trainingTypeEn,
      bodyPart: bodyPart ?? this.bodyPart,
      bodyPartEn: bodyPartEn ?? this.bodyPartEn,
      equipment: equipment ?? this.equipment,
      equipmentEn: equipmentEn ?? this.equipmentEn,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// 轉換為 JSON 數據格式（用於本地存儲）
  Map<String, dynamic> toJson() {
    return CustomExerciseMapper.toJson(this);
  }
  
  /// 從 JSON 數據創建對象
  factory CustomExercise.fromJson(Map<String, dynamic> json) {
    return CustomExerciseMapper.fromJson(json);
  }
  
  @override
  String toString() => 'CustomExercise(id: $id, name: $name, trainingType: $trainingType, bodyPart: $bodyPart)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomExercise &&
        other.id == id &&
        other.name == name &&
        other.userId == userId &&
        other.trainingType == trainingType &&
        other.bodyPart == bodyPart;
  }
  
  @override
  int get hashCode => Object.hash(id, name, userId, trainingType, bodyPart);
}

