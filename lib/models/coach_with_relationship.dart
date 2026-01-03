import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/models/coaching_relationship_model.dart';

/// 教練與關係組合模型（用於學員端篩選器）
/// 
/// 用途：
/// - 學員端課程筆記的教練篩選器
/// - 顯示歷史教練（active, archived, deleted）
class CoachWithRelationship {
  final UserModel? user; // 可為 null（教練已刪除）
  final CoachingRelationshipModel relationship;

  CoachWithRelationship({
    this.user,
    required this.relationship,
  });

  /// 顯示名稱（優先用 user，否則用名稱快照）
  String get displayName {
    return user?.displayName ?? relationship.coachName ?? '未知教練';
  }

  /// 是否為 active 關係
  bool get isActive => relationship.isActive;

  /// 是否為 archived 關係
  bool get isArchived => relationship.isArchived;

  /// 教練是否已刪除帳號
  bool get isDeleted => user == null;

  /// 篩選器顯示文字（含圖標和狀態）
  String get filterDisplayText {
    if (isDeleted) return '$displayName 👻 (已刪除)';
    if (isArchived) return '$displayName 🔗 (已解除)';
    return displayName;
  }
}

