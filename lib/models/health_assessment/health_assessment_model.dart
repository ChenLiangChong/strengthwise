import 'package:strengthwise/utils/datetime_utils.dart';
import 'injury_record.dart';
import 'enums.dart';
import 'training_goals.dart';

/// 健康評估模型
///
/// 記錄學員的健康評估問卷（PAR-Q+ 標準）
class HealthAssessmentModel {
  /// ID
  final String id;

  /// 學員 ID
  final String userId;

  /// 評估建立者 ID（教練或學員自己）
  final String? assessedBy;

  /// 評估日期
  final DateTime assessmentDate;

  // =========================================
  // 基礎安全篩檢（PAR-Q+ 7題）
  // =========================================

  /// 心臟疾病
  final bool heartDisease;
  final String? heartDiseaseNote;

  /// 運動時胸痛
  final bool chestPainExercise;

  /// 靜止時胸痛
  final bool chestPainRest;

  /// 頭暈或失去意識
  final bool dizziness;

  /// 骨骼或關節問題
  final bool boneJointProblem;
  final String? boneJointNote;

  /// 服用藥物
  final bool medication;
  final String? medicationNote;

  /// 其他不宜運動原因
  final bool otherReason;
  final String? otherReasonNote;

  /// 是否通過安全篩檢（自動計算）
  /// ⚠️ 此欄位僅供參考，不構成醫療診斷
  final bool isCleared;

  /// 取得風險等級標籤
  ///
  /// 返回：'low' (低風險) 或 'attention' (需注意)
  String get riskLevel => isCleared ? 'low' : 'attention';

  /// 取得風險等級中文標籤
  String get riskLevelLabel => isCleared ? '低風險' : '需注意';

  /// 取得風險等級描述
  String get riskLevelDescription =>
      isCleared ? '無特殊風險因子，可進行一般訓練' : '有風險因子需注意，建議調整訓練計畫';

  // =========================================
  // 進階評估（JSONB）
  // =========================================

  /// 心血管系統細節
  final Map<String, dynamic>? cardiovascularDetails;

  /// 傷病史
  final List<InjuryRecord> injuries;

  /// 代謝與內分泌系統
  final Map<String, dynamic>? metabolicDetails;

  /// 呼吸系統
  final Map<String, dynamic>? respiratoryDetails;

  // =========================================
  // 生活型態與訓練背景
  // =========================================

  /// 訓練經驗等級
  final TrainingLevel? trainingExperience;

  /// 訓練年資（年）
  final double? trainingYears;

  /// 職業活動度
  final ActivityLevel? occupationActivity;

  /// 可用器材
  final List<String> equipmentAccess;

  /// 每週訓練次數
  final int? weeklySessions;

  /// 平均睡眠時數（舊欄位，向後相容）
  final double? sleepHours;

  /// 平均睡眠時數 - 最少
  final double? sleepHoursMin;

  /// 平均睡眠時數 - 最多
  final double? sleepHoursMax;

  // =========================================
  // 訓練目標
  // =========================================

  /// 訓練目標
  final TrainingGoals? trainingGoals;

  // =========================================
  // 版本控制與狀態
  // =========================================

  /// 問卷版本號
  final int version;

  /// 是否為當前有效評估
  final bool isCurrent;

  /// 緊急聯絡人
  final Map<String, dynamic>? emergencyContact;

  /// 建立時間
  final DateTime createdAt;

  /// 更新時間
  final DateTime updatedAt;

  const HealthAssessmentModel({
    required this.id,
    required this.userId,
    this.assessedBy,
    required this.assessmentDate,
    required this.heartDisease,
    this.heartDiseaseNote,
    required this.chestPainExercise,
    required this.chestPainRest,
    required this.dizziness,
    required this.boneJointProblem,
    this.boneJointNote,
    required this.medication,
    this.medicationNote,
    required this.otherReason,
    this.otherReasonNote,
    required this.isCleared,
    this.cardiovascularDetails,
    required this.injuries,
    this.metabolicDetails,
    this.respiratoryDetails,
    this.trainingExperience,
    this.trainingYears,
    this.occupationActivity,
    required this.equipmentAccess,
    this.weeklySessions,
    this.sleepHours,
    this.sleepHoursMin,
    this.sleepHoursMax,
    this.trainingGoals,
    required this.version,
    required this.isCurrent,
    this.emergencyContact,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 從 Supabase 創建實例
  factory HealthAssessmentModel.fromSupabase(Map<String, dynamic> json) {
    return HealthAssessmentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      assessedBy: json['assessed_by'] as String?,
      assessmentDate:
          DateTimeUtils.parseIsoTimestamp(json['assessment_date'] as String),

      // 基礎篩檢
      heartDisease: json['heart_disease'] as bool,
      heartDiseaseNote: json['heart_disease_note'] as String?,
      chestPainExercise: json['chest_pain_exercise'] as bool,
      chestPainRest: json['chest_pain_rest'] as bool,
      dizziness: json['dizziness'] as bool,
      boneJointProblem: json['bone_joint_problem'] as bool,
      boneJointNote: json['bone_joint_note'] as String?,
      medication: json['medication'] as bool,
      medicationNote: json['medication_note'] as String?,
      otherReason: json['other_reason'] as bool,
      otherReasonNote: json['other_reason_note'] as String?,
      isCleared: json['is_cleared'] as bool,

      // 進階評估
      cardiovascularDetails:
          json['cardiovascular_details'] as Map<String, dynamic>?,
      injuries: _parseInjuries(json['musculoskeletal_details']),
      metabolicDetails: json['metabolic_details'] as Map<String, dynamic>?,
      respiratoryDetails: json['respiratory_details'] as Map<String, dynamic>?,

      // 生活型態
      trainingExperience: json['training_experience'] != null
          ? TrainingLevel.fromString(json['training_experience'] as String)
          : null,
      trainingYears: json['training_years'] != null
          ? (json['training_years'] as num).toDouble()
          : null,
      occupationActivity: json['occupation_activity'] != null
          ? ActivityLevel.fromString(json['occupation_activity'] as String)
          : null,
      equipmentAccess:
          (json['equipment_access'] as List?)?.cast<String>() ?? [],
      weeklySessions: json['weekly_sessions'] as int?,
      sleepHours: json['sleep_hours'] != null
          ? (json['sleep_hours'] as num).toDouble()
          : null,
      sleepHoursMin: json['sleep_hours_min'] != null
          ? (json['sleep_hours_min'] as num).toDouble()
          : null,
      sleepHoursMax: json['sleep_hours_max'] != null
          ? (json['sleep_hours_max'] as num).toDouble()
          : null,

      // 訓練目標
      trainingGoals: json['training_goals'] != null
          ? TrainingGoals.fromJson(
              json['training_goals'] as Map<String, dynamic>)
          : null,

      // 版本控制
      version: json['version'] as int? ?? 1,
      isCurrent: json['is_current'] as bool? ?? true,
      emergencyContact: json['emergency_contact'] as Map<String, dynamic>?,
      createdAt: DateTimeUtils.parseIsoTimestamp(json['created_at']),
      updatedAt: DateTimeUtils.parseIsoTimestamp(json['updated_at']),
    );
  }

  /// 轉換為 Supabase 格式
  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'assessed_by': assessedBy,
      'assessment_date': DateTimeUtils.formatToUtcIso(assessmentDate),

      // 基礎篩檢
      'heart_disease': heartDisease,
      'heart_disease_note': heartDiseaseNote,
      'chest_pain_exercise': chestPainExercise,
      'chest_pain_rest': chestPainRest,
      'dizziness': dizziness,
      'bone_joint_problem': boneJointProblem,
      'bone_joint_note': boneJointNote,
      'medication': medication,
      'medication_note': medicationNote,
      'other_reason': otherReason,
      'other_reason_note': otherReasonNote,

      // 進階評估
      'cardiovascular_details': cardiovascularDetails,
      'musculoskeletal_details': injuries.map((e) => e.toJson()).toList(),
      'metabolic_details': metabolicDetails,
      'respiratory_details': respiratoryDetails,

      // 生活型態
      'training_experience': trainingExperience?.value,
      'training_years': trainingYears,
      'occupation_activity': occupationActivity?.value,
      'equipment_access': equipmentAccess,
      'weekly_sessions': weeklySessions,
      'sleep_hours': sleepHours,
      'sleep_hours_min': sleepHoursMin,
      'sleep_hours_max': sleepHoursMax,

      // 訓練目標
      'training_goals': trainingGoals?.toJson(),

      // 版本控制
      'version': version,
      'is_current': isCurrent,
      if (emergencyContact != null) 'emergency_contact': emergencyContact,
      'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
    };
  }

  /// 解析傷病史陣列
  static List<InjuryRecord> _parseInjuries(dynamic json) {
    if (json == null) return [];
    if (json is! List) return [];
    return json
        .map((e) => InjuryRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 是否有需要注意的警示
  bool get hasWarnings => !isCleared || injuries.isNotEmpty || medication;

  /// 取得警示摘要（用於卡片顯示）
  List<String> getWarningSummary() {
    final warnings = <String>[];

    if (!isCleared) {
      warnings.add('安全篩檢未通過，請審查細節');
    }

    for (final injury in injuries) {
      if (injury.status == InjuryStatus.acute ||
          injury.status == InjuryStatus.chronic) {
        final limitation = injury.limitations ?? '需注意';
        warnings.add('${injury.site}：$limitation');
      }
    }

    if (medication && medicationNote != null && medicationNote!.isNotEmpty) {
      warnings.add('服用藥物：$medicationNote');
    }

    return warnings;
  }

  /// 複製並修改
  HealthAssessmentModel copyWith({
    String? id,
    String? userId,
    String? assessedBy,
    DateTime? assessmentDate,
    bool? heartDisease,
    String? heartDiseaseNote,
    bool? chestPainExercise,
    bool? chestPainRest,
    bool? dizziness,
    bool? boneJointProblem,
    String? boneJointNote,
    bool? medication,
    String? medicationNote,
    bool? otherReason,
    String? otherReasonNote,
    bool? isCleared,
    Map<String, dynamic>? cardiovascularDetails,
    List<InjuryRecord>? injuries,
    Map<String, dynamic>? metabolicDetails,
    Map<String, dynamic>? respiratoryDetails,
    TrainingLevel? trainingExperience,
    double? trainingYears,
    ActivityLevel? occupationActivity,
    List<String>? equipmentAccess,
    int? weeklySessions,
    double? sleepHours,
    double? sleepHoursMin,
    double? sleepHoursMax,
    TrainingGoals? trainingGoals,
    int? version,
    bool? isCurrent,
    Map<String, dynamic>? emergencyContact,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthAssessmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assessedBy: assessedBy ?? this.assessedBy,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      heartDisease: heartDisease ?? this.heartDisease,
      heartDiseaseNote: heartDiseaseNote ?? this.heartDiseaseNote,
      chestPainExercise: chestPainExercise ?? this.chestPainExercise,
      chestPainRest: chestPainRest ?? this.chestPainRest,
      dizziness: dizziness ?? this.dizziness,
      boneJointProblem: boneJointProblem ?? this.boneJointProblem,
      boneJointNote: boneJointNote ?? this.boneJointNote,
      medication: medication ?? this.medication,
      medicationNote: medicationNote ?? this.medicationNote,
      otherReason: otherReason ?? this.otherReason,
      otherReasonNote: otherReasonNote ?? this.otherReasonNote,
      isCleared: isCleared ?? this.isCleared,
      cardiovascularDetails:
          cardiovascularDetails ?? this.cardiovascularDetails,
      injuries: injuries ?? this.injuries,
      metabolicDetails: metabolicDetails ?? this.metabolicDetails,
      respiratoryDetails: respiratoryDetails ?? this.respiratoryDetails,
      trainingExperience: trainingExperience ?? this.trainingExperience,
      trainingYears: trainingYears ?? this.trainingYears,
      occupationActivity: occupationActivity ?? this.occupationActivity,
      equipmentAccess: equipmentAccess ?? this.equipmentAccess,
      weeklySessions: weeklySessions ?? this.weeklySessions,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepHoursMin: sleepHoursMin ?? this.sleepHoursMin,
      sleepHoursMax: sleepHoursMax ?? this.sleepHoursMax,
      trainingGoals: trainingGoals ?? this.trainingGoals,
      version: version ?? this.version,
      isCurrent: isCurrent ?? this.isCurrent,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'HealthAssessmentModel(userId: $userId, isCleared: $isCleared, '
        'injuries: ${injuries.length}, isCurrent: $isCurrent)';
  }
}
