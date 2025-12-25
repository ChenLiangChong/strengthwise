/// 身體數據記錄模型
/// 記錄體重、體脂、BMI 等身體指標的歷史數據
class BodyDataRecord {
  final String id;
  final String userId;
  final DateTime recordDate;  // 記錄日期
  final double weight;         // 體重（kg）
  final double? bodyFat;       // 體脂率（%）
  final double? muscleMass;    // 肌肉量（kg）
  final double? bmi;           // BMI
  final String? notes;         // 備註
  final DateTime createdAt;
  final DateTime? updatedAt;

  BodyDataRecord({
    required this.id,
    required this.userId,
    required this.recordDate,
    required this.weight,
    this.bodyFat,
    this.muscleMass,
    this.bmi,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// 從 Supabase 數據創建（snake_case）
  factory BodyDataRecord.fromSupabase(Map<String, dynamic> json) {
    return BodyDataRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      recordDate: DateTime.parse(json['record_date'] as String),
      weight: (json['weight'] as num).toDouble(),
      bodyFat: json['body_fat'] != null ? (json['body_fat'] as num).toDouble() : null,
      muscleMass: json['muscle_mass'] != null ? (json['muscle_mass'] as num).toDouble() : null,
      bmi: json['bmi'] != null ? (json['bmi'] as num).toDouble() : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  /// 轉換為 Map（用於 Supabase 插入/更新）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'record_date': recordDate.toIso8601String(),
      'weight': weight,
      'body_fat': bodyFat,
      'muscle_mass': muscleMass,
      'bmi': bmi,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// 創建副本
  BodyDataRecord copyWith({
    double? weight,
    double? bodyFat,
    double? muscleMass,
    double? bmi,
    String? notes,
    DateTime? recordDate,
  }) {
    return BodyDataRecord(
      id: id,
      userId: userId,
      recordDate: recordDate ?? this.recordDate,
      weight: weight ?? this.weight,
      bodyFat: bodyFat ?? this.bodyFat,
      muscleMass: muscleMass ?? this.muscleMass,
      bmi: bmi ?? this.bmi,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// 計算 BMI（如果身高已知）
  static double calculateBMI(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// 獲取 BMI 分類（中文）
  String getBMICategory() {
    if (bmi == null) return '未知';
    if (bmi! < 18.5) return '過輕';
    if (bmi! < 24) return '正常';
    if (bmi! < 27) return '過重';
    if (bmi! < 30) return '輕度肥胖';
    if (bmi! < 35) return '中度肥胖';
    return '重度肥胖';
  }
}

