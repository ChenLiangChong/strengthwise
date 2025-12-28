/// 教練-學員綁定關係模型
///
/// 表示教練與學員之間的綁定關係，包含邀請狀態和時間記錄
class CoachingRelationshipModel {
  final String id;
  final String coachId;
  final String clientId;
  final String status; // 'pending', 'active', 'archived', 'rejected'
  final String? notes;
  final DateTime invitedAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  CoachingRelationshipModel({
    required this.id,
    required this.coachId,
    required this.clientId,
    required this.status,
    this.notes,
    required this.invitedAt,
    this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 從 Supabase 數據創建模型（snake_case）
  factory CoachingRelationshipModel.fromSupabase(Map<String, dynamic> json) {
    return CoachingRelationshipModel(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      clientId: json['client_id'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      invitedAt: DateTime.parse(json['invited_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// 轉換為 Supabase 格式（snake_case）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coach_id': coachId,
      'client_id': clientId,
      'status': status,
      'notes': notes,
      'invited_at': invitedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 創建副本（用於狀態更新）
  CoachingRelationshipModel copyWith({
    String? status,
    String? notes,
    DateTime? acceptedAt,
  }) {
    return CoachingRelationshipModel(
      id: id,
      coachId: coachId,
      clientId: clientId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      invitedAt: invitedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
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

