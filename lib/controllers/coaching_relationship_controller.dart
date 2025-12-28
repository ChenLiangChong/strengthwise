import 'package:flutter/foundation.dart';
import '../services/interfaces/i_coaching_relationship_service.dart';
import '../services/core/error_handling_service.dart';
import '../models/coaching_relationship_model.dart';
import '../models/user/user_model.dart';

/// 教練-學員關係控制器
///
/// 管理教練與學員的綁定關係、邀請、查詢等業務邏輯
class CoachingRelationshipController extends ChangeNotifier {
  final ICoachingRelationshipService _relationshipService;
  final ErrorHandlingService _errorService;

  CoachingRelationshipController(
    this._relationshipService,
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
    String clientEmail, {
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _relationshipService.inviteClient(
        coachId,
        clientEmail,
        notes: notes,
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
  /// [notes] 備註
  Future<bool> createRelationship(
    String coachId,
    String clientId, {
    String status = 'active',
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _relationshipService.createRelationship(
        coachId,
        clientId,
        status: status,
        notes: notes,
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

  /// 更新學員備註
  ///
  /// [relationshipId] 關係 ID
  /// [notes] 新備註內容
  Future<bool> updateClientNotes(
    String relationshipId,
    String notes,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      await _relationshipService.updateNotes(relationshipId, notes);
      return true;
    } catch (e) {
      _handleError('更新備註失敗', e);
      return false;
    } finally {
      _setLoading(false);
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

