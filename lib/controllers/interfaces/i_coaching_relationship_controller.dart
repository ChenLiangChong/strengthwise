import 'package:flutter/foundation.dart';
import '../../models/user/user_model.dart';
import '../../models/coaching_relationship_model.dart';
import '../../models/invite_code_model.dart';
import '../../models/client_with_relationship.dart';
import '../../models/coach_with_relationship.dart';

/// 教練學員關係控制器接口
///
/// 負責管理教練與學員之間的關係綁定、邀請、QR Code 等功能
abstract class ICoachingRelationshipController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 載入中狀態
  bool get isLoading;

  /// 錯誤訊息
  String? get errorMessage;

  /// 教練的學員列表
  List<UserModel> get clients;

  /// 待處理的邀請列表
  List<CoachingRelationshipModel> get pendingInvitations;

  /// 學員的教練列表
  List<CoachingRelationshipModel> get coaches;

  /// 活躍學員數量
  int get activeClientCount;

  // ==================== 教練端功能 ====================

  /// 載入教練的學員列表
  Future<void> loadCoachClients(String coachId, {String? status});

  /// 邀請學員（通過 Email）
  Future<bool> inviteClient(String coachId, String clientEmail);

  /// 創建教練學員關係
  Future<bool> createRelationship(String coachId, String clientId, {String status});

  /// 封存學員
  Future<bool> archiveClient(String relationshipId, String coachId);

  /// 封存關係
  Future<bool> archiveRelationship(String relationshipId);

  /// 通過用戶 ID 獲取關係
  Future<CoachingRelationshipModel?> getRelationshipByUsers(String coachId, String clientId);

  // ==================== 學員端功能 ====================

  /// 載入待處理的邀請
  Future<void> loadPendingInvitations(String clientId);

  /// 載入學員的教練列表
  Future<void> loadClientCoaches(String clientId, {String? status});

  /// 接受邀請
  Future<bool> acceptInvitation(String relationshipId, String clientId);

  /// 拒絕邀請
  Future<bool> rejectInvitation(String relationshipId, String clientId);

  /// 刪除關係
  Future<bool> deleteRelationship(String relationshipId);

  // ==================== QR Code 和邀請碼 ====================

  /// 生成 QR Code 數據
  Future<String> generateMyQRData(String currentRole);

  /// 掃描並綁定
  Future<bool> scanAndBind({required String qrData, required String myRole});

  /// 驗證 QR Code
  Map<String, dynamic>? validateQRCode(String qrData);

  /// 生成邀請碼
  Future<InviteCodeModel?> generateInviteCode(String coachId);

  /// 清除邀請碼緩存
  void clearInviteCodeCache();

  /// 使用邀請碼
  Future<bool> useInviteCode({required String code, required String traineeId});

  // ==================== MVVM 查詢方法 ====================

  /// 檢查學員是否有活躍的教練
  Future<bool> hasActiveCoach(String clientId);

  /// 獲取教練的學員列表（帶關係資訊）
  Future<List<ClientWithRelationship>> getCoachClientsWithRelationship(
    String coachId, {
    String? status,
  });

  /// 獲取學員的教練列表（帶關係資訊）
  Future<List<CoachWithRelationship>> getClientCoachesWithRelationship(
    String clientId, {
    String? status,
  });

  /// 獲取詳細的關係資訊
  Future<CoachingRelationshipModel?> getRelationshipByUsersDetailed(
    String coachId,
    String clientId,
  );

  /// 獲取教練的學員列表（帶用戶詳情）
  Future<List<UserModel>> getCoachClientsWithDetails(String coachId, {String? status, bool forceRefresh = false});

  /// 獲取教練的學員關係列表
  Future<List<CoachingRelationshipModel>> getCoachClients(String coachId, {String? status, bool forceRefresh = false});

  // ==================== 快取管理 ====================

  /// 清除所有快取
  void clearCache();

  /// 清除特定學員的快取
  void clearClientCache(String clientId);
}
