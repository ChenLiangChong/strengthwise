import 'package:strengthwise/utils/datetime_utils.dart';

/// 教練評估備註 Model
/// 
/// 每個教練可以對學員的健康評估寫私有備註
/// 學員無法查看這些備註
class CoachAssessmentNoteModel {
  /// 備註 ID
  final String id;
  
  /// 教練 ID
  final String coachId;
  
  /// 健康評估 ID
  final String assessmentId;
  
  /// 備註內容
  final String notes;
  
  /// 建立時間
  final DateTime createdAt;
  
  /// 更新時間
  final DateTime updatedAt;

  const CoachAssessmentNoteModel({
    required this.id,
    required this.coachId,
    required this.assessmentId,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 從 Supabase 資料轉換
  factory CoachAssessmentNoteModel.fromSupabase(Map<String, dynamic> json) {
    return CoachAssessmentNoteModel(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      assessmentId: json['assessment_id'] as String,
      notes: json['notes'] as String,
      createdAt: DateTimeUtils.parseIsoTimestamp(json['created_at']),
      updatedAt: DateTimeUtils.parseIsoTimestamp(json['updated_at']),
    );
  }

  /// 轉換為 Supabase 資料格式
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'coach_id': coachId,
      'assessment_id': assessmentId,
      'notes': notes,
      'created_at': DateTimeUtils.formatToUtcIso(createdAt),
      'updated_at': DateTimeUtils.formatToUtcIso(updatedAt),
    };
  }

  /// 建立副本（用於更新）
  CoachAssessmentNoteModel copyWith({
    String? id,
    String? coachId,
    String? assessmentId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoachAssessmentNoteModel(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      assessmentId: assessmentId ?? this.assessmentId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CoachAssessmentNoteModel(id: $id, coachId: $coachId, assessmentId: $assessmentId, notes: ${notes.length > 50 ? '${notes.substring(0, 50)}...' : notes})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is CoachAssessmentNoteModel &&
      other.id == id &&
      other.coachId == coachId &&
      other.assessmentId == assessmentId &&
      other.notes == notes &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      coachId.hashCode ^
      assessmentId.hashCode ^
      notes.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  }
}

