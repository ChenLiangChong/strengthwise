import 'package:strengthwise/utils/datetime_utils.dart';

/// 教練-學員綁定關係模型
///
/// 表示教練與學員之間的綁定關係，包含邀請狀態和時間記錄
class CoachingRelationshipModel {
  final String id;
  
  /// 教練 ID（可能為 null，當教練帳號被刪除後）⭐ 修改
  final String? coachId;
  
  /// 學員 ID（可能為 null，當學員帳號被刪除後）⭐ 修改
  final String? clientId;
  
  final String status; // 'pending', 'active', 'archived', 'rejected'
  final DateTime invitedAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  /// 教練名稱快照（即使帳號刪除也保留）
  final String? coachName;
  
  /// 學員名稱快照（即使帳號刪除也保留）
  final String? clientName;

  CoachingRelationshipModel({
    required this.id,
    this.coachId,  // ⭐ 改為可選
    this.clientId, // ⭐ 改為可選
    required this.status,
    required this.invitedAt,
    this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
    this.coachName,
    this.clientName,
  });

  /// 從 Supabase 數據創建模型（snake_case）
  factory CoachingRelationshipModel.fromSupabase(Map<String, dynamic> json) {
    return CoachingRelationshipModel(
      id: json['id'] as String,
      coachId: json['coach_id'] as String?,   // ⭐ 允許 null
      clientId: json['client_id'] as String?, // ⭐ 允許 null
      status: json['status'] as String,
      invitedAt: DateTimeUtils.parseIsoTimestamp(json['invited_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTimeUtils.parseIsoTimestamp(json['accepted_at'] as String)
          : null,
      createdAt: DateTimeUtils.parseIsoTimestamp(json['created_at'] as String),
      updatedAt: DateTimeUtils.parseIsoTimestamp(json['updated_at'] as String),
      coachName: json['coach_name'] as String?,
      clientName: json['client_name'] as String?,
    );
  }

  /// 轉換為 Supabase 格式（snake_case）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coach_id': coachId,
      'client_id': clientId,
      'status': status,
      'invited_at': DateTimeUtils.formatToUtcIso(invitedAt),
      'accepted_at': acceptedAt != null ? DateTimeUtils.formatToUtcIso(acceptedAt!) : null,
      'created_at': DateTimeUtils.formatToUtcIso(createdAt),
      'updated_at': DateTimeUtils.formatToUtcIso(updatedAt),
      if (coachName != null) 'coach_name': coachName,
      if (clientName != null) 'client_name': clientName,
    };
  }

  /// 創建副本（用於狀態更新）
  CoachingRelationshipModel copyWith({
    String? status,
    DateTime? acceptedAt,
    String? coachName,
    String? clientName,
  }) {
    return CoachingRelationshipModel(
      id: id,
      coachId: coachId,   // ⭐ 保持原值（可能為 null）
      clientId: clientId, // ⭐ 保持原值（可能為 null）
      status: status ?? this.status,
      invitedAt: invitedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      coachName: coachName ?? this.coachName,
      clientName: clientName ?? this.clientName,
    );
  }

  /// 判斷是否為活躍關係
  bool get isActive => status == 'active';

  /// 判斷是否為待處理邀請
  bool get isPending => status == 'pending';

  /// 判斷是否已被拒絕
  bool get isRejected => status == 'rejected';

  /// 判斷是否已歸檔
  bool get isArchived => status == 'archived';
}

