import 'package:strengthwise/utils/datetime_utils.dart';

/// 傷病教練備註 Model
///
/// 每個教練對每筆傷病可以寫獨立備註
/// 特性：
/// - 所有有教練關係的教練都可以「查看」該學員的所有傷病備註
/// - 每個教練只能「編輯」自己的備註
class InjuryCoachNoteModel {
  /// 備註 ID
  final String id;

  /// 教練 ID
  final String coachId;

  /// 學員 ID
  final String clientId;

  /// 傷病部位（對應 InjuryRecord.site）
  final String injurySite;

  /// 備註內容
  final String note;

  /// 建立時間
  final DateTime createdAt;

  /// 更新時間
  final DateTime updatedAt;

  const InjuryCoachNoteModel({
    required this.id,
    required this.coachId,
    required this.clientId,
    required this.injurySite,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 從 Supabase 資料轉換
  factory InjuryCoachNoteModel.fromSupabase(Map<String, dynamic> json) {
    return InjuryCoachNoteModel(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      clientId: json['client_id'] as String,
      injurySite: json['injury_site'] as String,
      note: json['note'] as String,
      createdAt: DateTimeUtils.parseIsoTimestamp(json['created_at']),
      updatedAt: DateTimeUtils.parseIsoTimestamp(json['updated_at']),
    );
  }

  /// 轉換為 Supabase 資料格式（用於 upsert）
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'coach_id': coachId,
      'client_id': clientId,
      'injury_site': injurySite,
      'note': note,
    };
  }

  /// 建立副本
  InjuryCoachNoteModel copyWith({
    String? id,
    String? coachId,
    String? clientId,
    String? injurySite,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InjuryCoachNoteModel(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      clientId: clientId ?? this.clientId,
      injurySite: injurySite ?? this.injurySite,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'InjuryCoachNoteModel(coachId: $coachId, clientId: $clientId, injurySite: $injurySite)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InjuryCoachNoteModel &&
        other.id == id &&
        other.coachId == coachId &&
        other.clientId == clientId &&
        other.injurySite == injurySite &&
        other.note == note;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        coachId.hashCode ^
        clientId.hashCode ^
        injurySite.hashCode ^
        note.hashCode;
  }
}
