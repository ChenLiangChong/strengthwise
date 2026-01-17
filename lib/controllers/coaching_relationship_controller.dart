import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../services/interfaces/i_coaching_relationship_service.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/interfaces/i_invite_code_service.dart';
import '../services/core/error_handling_service.dart';
import '../services/core/app_event_bus.dart'; // ⭐ v3.5: EventBus
import '../models/coaching_relationship_model.dart';
import '../models/user/user_model.dart';
import '../models/invite_code_model.dart';
import '../models/client_with_relationship.dart'; // ⭐ v3.6: MVVM
import '../models/coach_with_relationship.dart'; // ⭐ v3.6: MVVM
import 'event_bus_controller.dart'; // ⭐ v3.5: EventBus

/// 教練-學員關係控制器
///
/// 管理教練與學員的綁定關係、邀請、查詢等業務邏輯
class CoachingRelationshipController extends ChangeNotifier {
  final ICoachingRelationshipService _relationshipService;
  final IUserService _userService;
  final IInviteCodeService _inviteCodeService;
  final ErrorHandlingService _errorService;
  final EventBusController _eventBusController; // ⭐ v3.5: EventBus

  CoachingRelationshipController(
    this._relationshipService,
    this._userService,
    this._inviteCodeService,
    this._errorService,
    this._eventBusController, // ⭐ v3.5: EventBus
  );

  // ============================================================================
  // 狀態管理
  // ============================================================================

  bool _isLoading = false;
  String? _errorMessage;

  // 教練的學員列表
  List<UserModel> _clients = [];

  // 待處理的邀請列表（學員端）
  List<CoachingRelationshipModel> _pendingInvitations = [];

  // 學員的教練列表
  List<CoachingRelationshipModel> _coaches = [];

  // 活躍學員數量
  int _activeClientCount = 0;

  // ============================================================================
  // Getters
  // ============================================================================

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get clients => _clients;
  List<CoachingRelationshipModel> get pendingInvitations => _pendingInvitations;
  List<CoachingRelationshipModel> get coaches => _coaches;
  int get activeClientCount => _activeClientCount;

  // ============================================================================
  // 教練端功能
  // ============================================================================

  /// 載入教練的學員列表（含詳情）
  ///
  /// [coachId] 教練 ID
  /// [status] 過濾狀態（可選，預設 'active'）
  Future<void> loadCoachClients(
    String coachId, {
    String? status = 'active',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _clients = await _relationshipService.getCoachClientsWithDetails(
        coachId,
        status: status,
      );

      // 同時載入活躍學員數量
      _activeClientCount =
          await _relationshipService.getActiveClientCount(coachId);

      notifyListeners();
    } catch (e) {
      _handleError('載入學員列表失敗', e);
    } finally {
      _setLoading(false);
    }
  }

  /// 教練邀請學員
  ///
  /// [coachId] 教練 ID
  /// [clientEmail] 學員 Email
  /// [notes] 備註（可選）
  Future<bool> inviteClient(
    String coachId,
    String clientEmail,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      await _relationshipService.inviteClient(
        coachId,
        clientEmail,
      );

      // 重新載入列表
      await loadCoachClients(coachId);

      return true;
    } catch (e) {
      _handleError('邀請學員失敗', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 手動創建綁定關係（開發測試用）
  ///
  /// [coachId] 教練 ID
  /// [clientId] 學員 ID
  /// [status] 初始狀態（預設 'active'）
  /// ⭐ v3.9: 操作成功後自動發布事件
  Future<bool> createRelationship(
    String coachId,
    String clientId, {
    String status = 'active',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final relationship = await _relationshipService.createRelationship(
        coachId,
        clientId,
        status: status,
      );

      // ⭐ v3.9: 發布關係建立事件
      _eventBusController.publishRelationshipCreated(
        relationshipId: relationship.id,
        coachId: coachId,
        clientId: clientId,
      );

      // 重新載入列表
      await loadCoachClients(coachId);

      return true;
    } catch (e) {
      _handleError('創建綁定關係失敗', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 歸檔學員關係
  ///
  /// [relationshipId] 關係 ID
  /// [coachId] 教練 ID（用於重新載入）
  Future<bool> archiveClient(String relationshipId, String coachId) async {
    _setLoading(true);
    _clearError();

    try {
      await _relationshipService.archiveRelationship(relationshipId);

      // 重新載入列表
      await loadCoachClients(coachId);

      return true;
    } catch (e) {
      _handleError('歸檔學員失敗', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 歸檔關係（通用方法）⭐ 新增
  ///
  /// 適用於學員端解除綁定，不重新載入列表
  ///
  /// [relationshipId] 綁定關係 ID
  Future<bool> archiveRelationship(String relationshipId) async {
    _setLoading(true);
    _clearError();

    try {
      await _relationshipService.archiveRelationship(relationshipId);
      return true;
    } catch (e) {
      _handleError('解除綁定失敗', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 根據教練和學員 ID 查詢綁定關係
  ///
  /// [coachId] 教練 ID
  /// [clientId] 學員 ID
  Future<CoachingRelationshipModel?> getRelationshipByUsers(
    String coachId,
    String clientId,
  ) async {
    try {
      return await _relationshipService.getRelationshipByUsers(coachId, clientId);
    } catch (e) {
      _errorService.logError(
        '查詢綁定關係失敗: $e',
        type: 'CoachingRelationshipControllerError',
      );
      return null;
    }
  }

  // ============================================================================
  // 學員端功能
  // ============================================================================

  /// 載入學員的待處理邀請
  ///
  /// [clientId] 學員 ID
  Future<void> loadPendingInvitations(String clientId) async {
    _setLoading(true);
    _clearError();

    try {
      _pendingInvitations = await _relationshipService.getClientCoaches(
        clientId,
        status: 'pending',
      );
      notifyListeners();
    } catch (e) {
      _handleError('載入邀請列表失敗', e);
    } finally {
      _setLoading(false);
    }
  }

  /// 載入學員的教練列表
  ///
  /// [clientId] 學員 ID
  /// [status] 過濾狀態（可選，預設 'active'）
  Future<void> loadClientCoaches(
    String clientId, {
    String? status = 'active',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _coaches = await _relationshipService.getClientCoaches(
        clientId,
        status: status,
      );
      notifyListeners();
    } catch (e) {
      _handleError('載入教練列表失敗', e);
    } finally {
      _setLoading(false);
    }
  }

  /// 學員接受邀請
  ///
  /// [relationshipId] 關係 ID
  /// [clientId] 學員 ID（用於重新載入）
  /// ⭐ v3.9: 操作成功後自動發布事件
  Future<bool> acceptInvitation(String relationshipId, String clientId) async {
    _setLoading(true);
    _clearError();

    // 先從待處理邀請中獲取關係資訊
    CoachingRelationshipModel? relationship;
    try {
      relationship = _pendingInvitations.firstWhere((r) => r.id == relationshipId);
    } catch (_) {
      // 如果找不到，relationship 保持 null
    }

    try {
      await _relationshipService.acceptInvitation(relationshipId);

      // ⭐ v3.9: 發布關係建立事件（接受邀請 = 關係正式建立）
      final coachId = relationship?.coachId;
      if (coachId != null && coachId.isNotEmpty) {
        _eventBusController.publishRelationshipCreated(
          relationshipId: relationshipId,
          coachId: coachId,
          clientId: clientId,
        );
      }

      // 重新載入列表
      await loadPendingInvitations(clientId);
      await loadClientCoaches(clientId);

      return true;
    } catch (e) {
      _handleError('接受邀請失敗', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 學員拒絕邀請
  ///
  /// [relationshipId] 關係 ID
  /// [clientId] 學員 ID（用於重新載入）
  Future<bool> rejectInvitation(String relationshipId, String clientId) async {
    _setLoading(true);
    _clearError();

    try {
      await _relationshipService.rejectInvitation(relationshipId);

      // 重新載入列表
      await loadPendingInvitations(clientId);

      return true;
    } catch (e) {
      _handleError('拒絕邀請失敗', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================================
  // 刪除關係
  // ============================================================================

  /// 刪除綁定關係（雙方都可刪除）
  ///
  /// [relationshipId] 關係 ID
  Future<bool> deleteRelationship(String relationshipId) async {
    _setLoading(true);
    _clearError();

    try {
      await _relationshipService.deleteRelationship(relationshipId);

      // ⭐ v3.5: 發布關係刪除事件
      _eventBusController.publish(AppEvent(
        type: AppEventType.relationshipDeleted,
        entityId: relationshipId,
        timestamp: DateTime.now(),
      ));

      return true;
    } catch (e) {
      _handleError('刪除綁定關係失敗', e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================================
  // 快取管理
  // ============================================================================

  /// 清除所有快取
  void clearCache() {
    _relationshipService.clearCache();
  }

  // ============================================================================
  // QR Code 綁定功能
  // ============================================================================

  /// 生成當前用戶的 QR Code 數據
  /// 
  /// [currentRole] - 'coach' 或 'client'
  /// 返回 JSON 字串，包含用戶資訊
  Future<String> generateMyQRData(String currentRole) async {
    try {
      final currentUser = await _userService.getCurrentUserProfile();
      if (currentUser == null) {
        throw Exception('無法獲取當前用戶資訊');
      }

      final qrData = {
        'type': currentRole == 'coach' ? 'coach_invite' : 'client_request',
        'role': currentRole,
        'user_id': currentUser.uid,
        'name': currentUser.displayName ?? currentUser.email,
        'email': currentUser.email,
        'timestamp': DateTime.now().toIso8601String(),
        'app': 'strengthwise',
        'version': '1.0',
      };

      return jsonEncode(qrData);
    } catch (e) {
      _handleError('生成 QR Code 失敗', e);
      rethrow;
    }
  }

  /// 掃描並綁定 QR Code
  /// 
  /// [qrData] - 掃描到的 QR Code 內容（JSON 字串）
  /// [myRole] - 我的角色 ('coach' 或 'client')
  /// 返回：true = 成功，false = 失敗
  Future<bool> scanAndBind({
    required String qrData,
    required String myRole,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // 解析 QR Code
      final Map<String, dynamic> data = jsonDecode(qrData);

      // 驗證 QR Code 格式
      if (data['app'] != 'strengthwise') {
        _errorMessage = '無效的 QR Code（不是 StrengthWise 應用）';
        notifyListeners();
        return false;
      }

      final scannedRole = data['role'] as String?;
      final scannedUserId = data['user_id'] as String?;
      // final scannedName = data['name'] as String?; // 暫不使用

      if (scannedRole == null || scannedUserId == null) {
        _errorMessage = 'QR Code 格式錯誤';
        notifyListeners();
        return false;
      }

      // 驗證角色匹配
      if (myRole == 'coach' && scannedRole != 'client') {
        _errorMessage = '請掃描學員的 QR Code';
        notifyListeners();
        return false;
      }

      if (myRole == 'client' && scannedRole != 'coach') {
        _errorMessage = '請掃描教練的 QR Code';
        notifyListeners();
        return false;
      }

      // 獲取當前用戶
      final currentUser = await _userService.getCurrentUserProfile();
      if (currentUser == null) {
        _errorMessage = '無法獲取當前用戶資訊';
        notifyListeners();
        return false;
      }

      // 檢查是否掃描自己
      if (scannedUserId == currentUser.uid) {
        _errorMessage = '不能綁定自己';
        notifyListeners();
        return false;
      }

      // ⭐ 使用 RPC 函數：在資料庫層面完成驗證和綁定
      final result = await _relationshipService.bindByQrCode(
        scannedUserId: scannedUserId,
        myUserId: currentUser.uid,
        myRole: myRole,
      );

      if (!result.success) {
        _errorMessage = result.error ?? '綁定失敗';
        notifyListeners();
        _setLoading(false);
        return false;
      }

      _clearError();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _handleError('綁定失敗', e);
      _setLoading(false);
      return false;
    }
  }

  /// 驗證 QR Code 格式（不創建關係，僅返回資訊）
  /// 
  /// 用於掃描後顯示確認對話框
  Map<String, dynamic>? validateQRCode(String qrData) {
    try {
      final Map<String, dynamic> data = jsonDecode(qrData);

      if (data['app'] != 'strengthwise') {
        return null;
      }

      return {
        'role': data['role'],
        'user_id': data['user_id'],
        'name': data['name'],
        'email': data['email'],
        'timestamp': data['timestamp'],
      };
    } catch (e) {
      debugPrint('[COACHING] QR Code 解析失敗: $e');
      return null;
    }
  }

  // ============================================================================
  // 邀請碼功能（遠端綁定）
  // ============================================================================

  /// 邀請碼快取（記憶體中暫存，避免重複生成）
  InviteCodeModel? _cachedInviteCode;

  /// 生成或獲取邀請碼（教練專用）
  ///
  /// - 如果快取中有未過期的邀請碼，直接返回
  /// - 否則生成新的邀請碼並快取
  ///
  /// [coachId] - 教練 ID
  /// 返回邀請碼模型（包含 code 和 expiresAt）
  Future<InviteCodeModel?> generateInviteCode(String coachId) async {
    // ⭐ 檢查快取：如果有未過期的邀請碼，直接返回
    if (_cachedInviteCode != null &&
        _cachedInviteCode!.coachId == coachId &&
        _cachedInviteCode!.isValid) {
      return _cachedInviteCode;
    }

    try {
      _setLoading(true);
      _clearError();

      final inviteCode = await _inviteCodeService.generateInviteCode(coachId);

      // ⭐ 快取新生成的邀請碼
      _cachedInviteCode = inviteCode;

      _setLoading(false);
      return inviteCode;
    } catch (e) {
      _handleError('生成邀請碼失敗', e);
      _setLoading(false);
      return null;
    }
  }

  /// 清除邀請碼快取（強制下次生成新的）
  void clearInviteCodeCache() {
    _cachedInviteCode = null;
  }

  /// 使用邀請碼綁定教練（學員專用）
  ///
  /// [code] - 邀請碼
  /// [traineeId] - 學員 ID
  /// 返回：true = 成功，false = 失敗
  Future<bool> useInviteCode({
    required String code,
    required String traineeId,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // ⭐ 使用 RPC 函數：在資料庫層面完成所有驗證和綁定
      final result = await _inviteCodeService.bindCoachByInviteCode(
        code: code,
        traineeId: traineeId,
      );

      if (!result.success) {
        _errorMessage = result.error ?? '綁定失敗';
        notifyListeners();
        _setLoading(false);
        return false;
      }

      _clearError();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _handleError('使用邀請碼失敗', e);
      _setLoading(false);
      return false;
    }
  }

  // ============================================================================
  // ⭐ MVVM 重構：查詢方法（直接返回結果，不更新 Controller 狀態）
  // ============================================================================

  /// 檢查學員是否有活躍的教練
  ///
  /// 用於首頁判斷是否顯示「我的教練」相關功能
  ///
  /// [clientId] 學員 ID
  /// 返回 true 表示有至少一個活躍教練
  Future<bool> hasActiveCoach(String clientId) async {
    try {
      final coaches = await _relationshipService.getClientCoaches(
        clientId,
        status: 'active',
      );
      return coaches.isNotEmpty;
    } catch (e) {
      _errorService.logError(
        '檢查教練綁定失敗: $e',
        type: 'CoachingRelationshipControllerError',
      );
      return false;
    }
  }

  /// 取得教練的學員列表（含關係狀態）
  /// ⭐ v3.6: MVVM 重構 - 直接返回結果
  ///
  /// [coachId] 教練 ID
  /// [status] 過濾狀態（可選，null = 全部）
  Future<List<ClientWithRelationship>> getCoachClientsWithRelationship(
    String coachId, {
    String? status,
  }) async {
    try {
      return await _relationshipService.getCoachClientsWithRelationship(
        coachId,
        status: status,
      );
    } catch (e) {
      _errorService.logError(
        '查詢學員列表失敗: $e',
        type: 'CoachingRelationshipControllerError',
      );
      return [];
    }
  }

  /// 取得學員的教練列表（含關係狀態）
  /// ⭐ v3.6: MVVM 重構 - 直接返回結果
  ///
  /// [clientId] 學員 ID
  /// [status] 過濾狀態（可選，null = 全部）
  Future<List<CoachWithRelationship>> getClientCoachesWithRelationship(
    String clientId, {
    String? status,
  }) async {
    try {
      return await _relationshipService.getClientCoachesWithRelationship(
        clientId,
        status: status,
      );
    } catch (e) {
      _errorService.logError(
        '查詢教練列表失敗: $e',
        type: 'CoachingRelationshipControllerError',
      );
      return [];
    }
  }

  /// 根據教練和學員 ID 查詢詳細綁定關係
  /// ⭐ v3.6 MVVM 重構
  Future<CoachingRelationshipModel?> getRelationshipByUsersDetailed(
    String coachId,
    String clientId,
  ) async {
    try {
      return await _relationshipService.getRelationshipByUsersDetailed(
        coachId,
        clientId,
      );
    } catch (e) {
      _errorService.logError(
        '查詢關係詳情失敗: $e',
        type: 'CoachingRelationshipControllerError',
      );
      return null;
    }
  }

  /// 取得教練的學員列表（UserModel）
  /// ⭐ v3.6 MVVM 重構
  Future<List<UserModel>> getCoachClientsWithDetails(
    String coachId, {
    String? status,
  }) async {
    try {
      return await _relationshipService.getCoachClientsWithDetails(
        coachId,
        status: status,
      );
    } catch (e) {
      _errorService.logError(
        '查詢學員詳情列表失敗: $e',
        type: 'CoachingRelationshipControllerError',
      );
      return [];
    }
  }

  /// 取得教練的學員關係列表
  /// ⭐ v3.6 MVVM 重構
  Future<List<CoachingRelationshipModel>> getCoachClients(
    String coachId, {
    String? status,
  }) async {
    try {
      return await _relationshipService.getCoachClients(
        coachId,
        status: status,
      );
    } catch (e) {
      _errorService.logError(
        '查詢學員關係列表失敗: $e',
        type: 'CoachingRelationshipControllerError',
      );
      return [];
    }
  }

  /// 清除學員快取（用於強制刷新）
  /// ⭐ v3.6 MVVM 重構
  void clearClientCache(String clientId) {
    _relationshipService.clearClientCache(clientId);
  }

  // ============================================================================
  // 私有方法
  // ============================================================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _handleError(String message, Object error) {
    _errorMessage = message;
    _errorService.logError(
      '$message: $error',
      type: 'CoachingRelationshipControllerError',
    );
    notifyListeners();
  }
}

