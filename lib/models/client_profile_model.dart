import 'package:strengthwise/utils/datetime_utils.dart';

/// 學員檔案模型
/// 
/// 記錄學員的訓練目標、健康注意事項、訓練偏好等資訊
class ClientProfile {
  /// 訓練目標（必填）
  final String goals;
  
  /// 健康注意事項（選填）
  final String? healthNotes;
  
  /// 訓練偏好（選填）
  final String? preferences;
  
  /// 建檔日期
  final DateTime assessmentDate;

  const ClientProfile({
    required this.goals,
    this.healthNotes,
    this.preferences,
    required this.assessmentDate,
  });

  /// 從 JSONB 創建實例
  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      goals: json['goals'] as String? ?? '',
      healthNotes: json['health_notes'] as String?,
      preferences: json['preferences'] as String?,
      assessmentDate: json['assessment_date'] != null
          ? DateTimeUtils.parseIsoTimestamp(json['assessment_date'] as String)
          : DateTime.now(),
    );
  }

  /// 轉換為 JSONB
  Map<String, dynamic> toJson() {
    return {
      'goals': goals,
      if (healthNotes != null && healthNotes!.isNotEmpty) 
        'health_notes': healthNotes,
      if (preferences != null && preferences!.isNotEmpty) 
        'preferences': preferences,
      'assessment_date': DateTimeUtils.formatToUtcIso(assessmentDate),
    };
  }

  /// 創建副本
  ClientProfile copyWith({
    String? goals,
    String? healthNotes,
    String? preferences,
    DateTime? assessmentDate,
  }) {
    return ClientProfile(
      goals: goals ?? this.goals,
      healthNotes: healthNotes ?? this.healthNotes,
      preferences: preferences ?? this.preferences,
      assessmentDate: assessmentDate ?? this.assessmentDate,
    );
  }

  /// 是否為空檔案（只檢查必填欄位）
  bool get isEmpty => goals.trim().isEmpty;

  /// 是否有健康注意事項
  bool get hasHealthNotes => 
      healthNotes != null && healthNotes!.trim().isNotEmpty;

  /// 是否有訓練偏好
  bool get hasPreferences => 
      preferences != null && preferences!.trim().isNotEmpty;

  @override
  String toString() {
    return 'ClientProfile(goals: $goals, healthNotes: $healthNotes, preferences: $preferences)';
  }
}

