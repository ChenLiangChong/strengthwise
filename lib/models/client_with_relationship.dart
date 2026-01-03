import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/models/coaching_relationship_model.dart';

/// 學員及其關係狀態（用於筆記篩選器）
/// 
/// 包含學員的用戶資料和與教練的關係狀態
class ClientWithRelationship {
  /// 學員用戶資料（可能為 null，當學員被刪除後）
  final UserModel? user;
  
  /// 關係資料（包含 status, clientName 等）
  final CoachingRelationshipModel relationship;

  ClientWithRelationship({
    this.user,
    required this.relationship,
  });

  /// 顯示名稱（優先使用 user，否則使用名稱快照）
  String get displayName {
    if (user != null) {
      return user!.displayName ?? user!.email;
    }
    // 學員被刪除，使用名稱快照
    return relationship.clientName ?? '未知學員';
  }

  /// 是否為活躍關係
  bool get isActive => relationship.isActive;

  /// 是否為已歸檔關係
  bool get isArchived => relationship.isArchived;

  /// 學員是否已被刪除
  bool get isDeleted => relationship.clientId == null;

  /// 用於篩選器的顯示文字（帶狀態標記）
  String get filterDisplayText {
    if (isDeleted) {
      return '$displayName 👻 (已刪除)';
    } else if (isArchived) {
      return '$displayName 🔗 (已解除)';
    } else {
      return displayName;
    }
  }
}

