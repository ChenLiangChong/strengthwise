import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../services/interfaces/i_coaching_relationship_service.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/interfaces/i_invite_code_service.dart';
import '../services/core/error_handling_service.dart';
import '../models/coaching_relationship_model.dart';
import '../models/user/user_model.dart';
import '../models/invite_code_model.dart';

/// 教練-學員關係控制器
///
/// 管理教練與學員的綁定關係、邀請、查詢等業務邏輯
class CoachingRelationshipController extends ChangeNotifier {
  final ICoachingRelationshipService _relationshipService;
  final IUserService _userService;
  final IInviteCodeService _inviteCodeService;
  final ErrorHandlingService _errorService;

  CoachingRelationshipController(
    this._relationshipService,
    this._userService,
    this._inviteCodeService,
    this._errorService,
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
  Future<bool> createRelationship(
    String coachId,
    String clientId, {
    String status = 'active',
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _relationshipService.createRelationship(
        coachId,
        clientId,
        status: status,
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
  Future<bool> acceptInvitation(String relationshipId, String clientId) async {
    _setLoading(true);
    _clearError();

    try {
      await _relationshipService.acceptInvitation(relationshipId);

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

      // ✅ 驗證對方用戶是否存在於 public.users
      final scannedUser = await _userService.getUserProfile(scannedUserId);
      if (scannedUser == null) {
        _errorMessage = '對方用戶不存在或尚未完成註冊\n請確認對方已完成首次登入';
        notifyListeners();
        return false;
      }

      // 創建關係
      String coachId, traineeId;
      if (myRole == 'coach') {
        coachId = currentUser.uid;
        traineeId = scannedUserId;
      } else {
        coachId = scannedUserId;
        traineeId = currentUser.uid;
      }

      // 創建新關係（直接設為 active，QR Code 綁定無需審核）
      await _relationshipService.createRelationship(
        coachId,
        traineeId,
        status: 'active',
      );

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

  /// 生成邀請碼（教練專用）
  ///
  /// [coachId] - 教練 ID
  /// 返回邀請碼模型（包含 code 和 expiresAt）
  Future<InviteCodeModel?> generateInviteCode(String coachId) async {
    try {
      _setLoading(true);
      _clearError();

      final inviteCode = await _inviteCodeService.generateInviteCode(coachId);

      _setLoading(false);
      return inviteCode;
    } catch (e) {
      _handleError('生成邀請碼失敗', e);
      _setLoading(false);
      return null;
    }
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

      // 驗證並使用邀請碼（返回教練 ID）
      final coachId = await _inviteCodeService.validateAndUseCode(
        code: code,
        traineeId: traineeId,
      );

      // ✅ 驗證教練是否存在於 public.users
      final coachUser = await _userService.getUserProfile(coachId);
      if (coachUser == null) {
        _errorMessage = '教練用戶不存在或尚未完成註冊\n請確認教練已完成首次登入';
        notifyListeners();
        _setLoading(false);
        return false;
      }

      // 創建新關係（直接設為 active，邀請碼綁定無需審核）
      await _relationshipService.createRelationship(
        coachId,
        traineeId,
        status: 'active',
      );

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

