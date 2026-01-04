import '../../models/coaching_relationship_model.dart';
import '../../models/user/user_model.dart';
import '../../models/client_with_relationship.dart';  // ⭐ 新增
import '../../models/coach_with_relationship.dart';  // ⭐ 新增

/// QR Code 綁定結果
class QrCodeBindResult {
  final bool success;
  final String? error;
  final String? relationshipId;
  final String? coachId;
  final String? clientId;
  final String? scannedUserName;

  QrCodeBindResult({
    required this.success,
    this.error,
    this.relationshipId,
    this.coachId,
    this.clientId,
    this.scannedUserName,
  });

  factory QrCodeBindResult.fromJson(Map<String, dynamic> json) {
    return QrCodeBindResult(
      success: json['success'] as bool? ?? false,
      error: json['error'] as String?,
      relationshipId: json['relationship_id'] as String?,
      coachId: json['coach_id'] as String?,
      clientId: json['client_id'] as String?,
      scannedUserName: json['scanned_user_name'] as String?,
    );
  }
}

/// 教練-學員關係服務介面
///
/// 定義教練與學員綁定、邀請、查詢等核心功能
abstract class ICoachingRelationshipService {
  // ============================================================================
  // 查詢功能
  // ============================================================================

  /// 獲取教練的所有學員列表
  ///
  /// [coachId] 教練 ID
  /// [status] 過濾狀態（可選）：'active', 'pending', 'archived', 'rejected'
  Future<List<CoachingRelationshipModel>> getCoachClients(
    String coachId, {
    String? status,
  });

  /// 獲取學員的所有教練列表
  ///
  /// [clientId] 學員 ID
  /// [status] 過濾狀態（可選）
  Future<List<CoachingRelationshipModel>> getClientCoaches(
    String clientId, {
    String? status,
  });

  /// 獲取學員的詳細資料（含用戶資料）
  ///
  /// [coachId] 教練 ID
  /// [status] 過濾狀態（可選）
  /// 返回：學員的 UserModel 列表
  Future<List<UserModel>> getCoachClientsWithDetails(
    String coachId, {
    String? status,
  });

  /// 獲取學員及其關係狀態（用於筆記篩選器）⭐ 新增
  ///
  /// [coachId] 教練 ID
  /// [status] 過濾狀態（可選）
  /// 返回：學員及關係狀態列表（包含已刪除的學員）
  Future<List<ClientWithRelationship>> getCoachClientsWithRelationship(
    String coachId, {
    String? status,
  });

  /// 取得學員的教練列表（含關係狀態）⭐ 新增
  Future<List<CoachWithRelationship>> getClientCoachesWithRelationship(
    String clientId, {
    String? status,
  });

  /// 根據教練和學員 ID 查詢綁定關係
  ///
  /// [coachId] 教練 ID
  /// [clientId] 學員 ID
  /// 返回：綁定關係模型（不存在則返回 null）
  Future<CoachingRelationshipModel?> getRelationshipByUsers(
    String coachId,
    String clientId,
  );

  /// 檢查是否存在活躍的教練-學員關係
  ///
  /// [coachId] 教練 ID
  /// [clientId] 學員 ID
  Future<bool> isActiveRelationship(String coachId, String clientId);

  /// 獲取教練的活躍學員數量
  ///
  /// [coachId] 教練 ID
  Future<int> getActiveClientCount(String coachId);

  // ============================================================================
  // 建立與邀請功能
  // ============================================================================

  /// 教練邀請學員（建立 pending 關係）
  ///
  /// [coachId] 教練 ID
  /// [clientEmail] 學員 Email
  /// 
  /// 流程：
  /// 1. 查詢學員是否已註冊
  /// 2. 若已註冊，直接創建 pending 關係
  /// 3. 若未註冊，返回錯誤（Phase 1 暫不支援郵件邀請）
  Future<CoachingRelationshipModel> inviteClient(
    String coachId,
    String clientEmail,
  );

  /// 手動建立綁定關係（開發測試用）
  ///
  /// [coachId] 教練 ID
  /// [clientId] 學員 ID
  /// [status] 初始狀態（預設 'pending'）
  Future<CoachingRelationshipModel> createRelationship(
    String coachId,
    String clientId, {
    String status = 'pending',
  });

  /// ⭐ QR Code 綁定（RPC 版本）
  ///
  /// 使用 SECURITY DEFINER RPC 函數，可驗證對方用戶是否存在
  /// 並在資料庫層面完成所有邏輯
  ///
  /// [scannedUserId] - 掃描到的用戶 ID
  /// [myUserId] - 我的用戶 ID
  /// [myRole] - 我的角色 ('coach' 或 'client')
  /// 返回綁定結果（包含成功/失敗、錯誤訊息）
  Future<QrCodeBindResult> bindByQrCode({
    required String scannedUserId,
    required String myUserId,
    required String myRole,
  });

  // ============================================================================
  // 更新與管理功能
  // ============================================================================

  /// 學員接受邀請（pending → active）
  ///
  /// [relationshipId] 關係 ID
  Future<void> acceptInvitation(String relationshipId);

  /// 學員拒絕邀請（pending → rejected）
  ///
  /// [relationshipId] 關係 ID
  Future<void> rejectInvitation(String relationshipId);

  /// 歸檔關係（active → archived）
  ///
  /// [relationshipId] 關係 ID
  Future<void> archiveRelationship(String relationshipId);

  /// 刪除關係（雙方都可刪除）
  ///
  /// [relationshipId] 關係 ID
  Future<void> deleteRelationship(String relationshipId);

  // ============================================================================
  // 學員檔案管理
  // ============================================================================

  /// 根據 ID 查詢詳細關係
  ///
  /// [relationshipId] 關係 ID
  /// 返回：綁定關係模型（完整資訊）
  Future<CoachingRelationshipModel?> getRelationshipByIdDetailed(
    String relationshipId,
  );

  /// 根據教練和學員 ID 查詢詳細關係
  ///
  /// [coachId] 教練 ID
  /// [clientId] 學員 ID
  /// 返回：綁定關係模型（完整資訊）
  Future<CoachingRelationshipModel?> getRelationshipByUsersDetailed(
    String coachId,
    String clientId,
  );

  // ============================================================================
  // 快取管理
  // ============================================================================

  /// 清除快取（用於資料更新後）
  void clearCache();

  /// 清除特定教練的快取
  void clearCoachCache(String coachId);

  /// 清除特定學員的快取
  void clearClientCache(String clientId);
}

