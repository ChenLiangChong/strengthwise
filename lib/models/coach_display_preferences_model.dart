import 'package:strengthwise/utils/datetime_utils.dart';

/// 教練顯示偏好模型
///
/// 用於儲存教練在學員詳情頁的顯示偏好設定
class CoachDisplayPreferencesModel {
  /// 教練 ID
  final String coachId;

  /// 健康評估顯示欄位
  ///
  /// 可選值：
  /// - 'safety_screening': 安全篩檢（PAR-Q+）
  /// - 'injuries': 傷病史
  /// - 'medications': 用藥記錄
  /// - 'cardiovascular': 心血管系統
  /// - 'metabolic': 代謝系統
  /// - 'respiratory': 呼吸系統
  /// - 'training_experience': 訓練經驗
  /// - 'occupation_activity': 職業活動度
  /// - 'equipment_access': 可用器材
  /// - 'training_goals': 訓練目標
  /// - 'emergency_contact': 緊急聯絡人
  final List<String> healthAssessmentFields;

  /// 更新時間
  final DateTime updatedAt;

  const CoachDisplayPreferencesModel({
    required this.coachId,
    required this.healthAssessmentFields,
    required this.updatedAt,
  });

  /// 預設顯示欄位
  static const List<String> defaultFields = [
    'safety_screening',
    'injuries',
    'medications',
    'training_experience',
    'training_goals',
  ];

  /// 所有可用欄位（⭐ v3.3: 對應 PAR-Q+ 問題）
  static const Map<String, String> availableFields = {
    'safety_screening': '安全篩檢（風險評估）',
    'injuries': '傷病史',
    'cardiovascular': '心血管系統（心臟/胸痛/頭暈）',
    'bone_joint': '骨骼關節問題', // ⭐ v3.3: 新增
    'medications': '用藥記錄',
    'other_health_issues': '其他健康問題', // ⭐ v3.3: 新增
    'training_experience': '訓練經驗',
    'occupation_activity': '職業活動度',
    'equipment_access': '可用器材',
    'training_goals': '訓練目標',
    'emergency_contact': '緊急聯絡人',
  };

  /// 從 Supabase 創建實例
  factory CoachDisplayPreferencesModel.fromSupabase(Map<String, dynamic> json) {
    return CoachDisplayPreferencesModel(
      coachId: json['coach_id'] as String,
      healthAssessmentFields:
          (json['health_assessment_fields'] as List?)?.cast<String>() ??
              defaultFields,
      updatedAt: DateTimeUtils.parseIsoTimestamp(json['updated_at'] as String),
    );
  }

  /// 轉換為 Supabase 格式
  Map<String, dynamic> toSupabase() {
    return {
      'coach_id': coachId,
      'health_assessment_fields': healthAssessmentFields,
      'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
    };
  }

  /// 創建預設偏好
  factory CoachDisplayPreferencesModel.createDefault(String coachId) {
    return CoachDisplayPreferencesModel(
      coachId: coachId,
      healthAssessmentFields: List.from(defaultFields),
      updatedAt: DateTime.now(),
    );
  }

  /// 檢查欄位是否啟用
  bool isFieldEnabled(String fieldKey) {
    return healthAssessmentFields.contains(fieldKey);
  }

  /// 複製並修改
  CoachDisplayPreferencesModel copyWith({
    String? coachId,
    List<String>? healthAssessmentFields,
    DateTime? updatedAt,
  }) {
    return CoachDisplayPreferencesModel(
      coachId: coachId ?? this.coachId,
      healthAssessmentFields:
          healthAssessmentFields ?? this.healthAssessmentFields,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CoachDisplayPreferencesModel(coachId: $coachId, fields: ${healthAssessmentFields.length})';
  }
}
