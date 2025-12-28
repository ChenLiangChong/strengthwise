import 'package:supabase_flutter/supabase_flutter.dart';
import '../interfaces/i_coaching_relationship_service.dart';
import '../../models/coaching_relationship_model.dart';
import '../../models/user/user_model.dart';
import '../core/error_handling_service.dart';
import 'coaching_relationship/coaching_relationship_query.dart';
import 'coaching_relationship/coaching_relationship_operations.dart';
import 'coaching_relationship/coaching_relationship_cache_manager.dart';

/// 教練-學員關係服務（Supabase 實作）
///
/// 負責教練與學員的綁定、邀請、查詢等功能
class CoachingRelationshipServiceSupabase
    implements ICoachingRelationshipService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;

  // 子模組
  late final CoachingRelationshipQuery _query;
  late final CoachingRelationshipOperations _operations;
  late final CoachingRelationshipCacheManager _cache;

  CoachingRelationshipServiceSupabase(
    this._supabase,
    this._errorService,
  ) {
    _query = CoachingRelationshipQuery(_supabase);
    _operations = CoachingRelationshipOperations(_supabase);
    _cache = CoachingRelationshipCacheManager();
  }

  // ============================================================================
  // 查詢功能
  // ============================================================================

  @override
  Future<List<CoachingRelationshipModel>> getCoachClients(
    String coachId, {
    String? status,
  }) async {
    try {
      // 檢查快取
      final cached = _cache.getCoachClients(coachId, status);
      if (cached != null) {
        return cached;
      }

      // 查詢資料庫
      final relationships = await _query.queryCoachClients(
        coachId,
        status: status,
      );

      // 更新快取
      _cache.setCoachClients(coachId, status, relationships);

      return relationships;
    } catch (e) {
      _errorService.logError(
        '獲取教練學員列表失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<List<CoachingRelationshipModel>> getClientCoaches(
    String clientId, {
    String? status,
  }) async {
    try {
      // 檢查快取
      final cached = _cache.getClientCoaches(clientId, status);
      if (cached != null) {
        return cached;
      }

      // 查詢資料庫
      final relationships = await _query.queryClientCoaches(
        clientId,
        status: status,
      );

      // 更新快取
      _cache.setClientCoaches(clientId, status, relationships);

      return relationships;
    } catch (e) {
      _errorService.logError(
        '獲取學員教練列表失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<List<UserModel>> getCoachClientsWithDetails(
    String coachId, {
    String? status,
  }) async {
    try {
      // 檢查快取
      final cached = _cache.getClientDetails(coachId, status);
      if (cached != null) {
        return cached;
      }

      // 查詢學員 ID 列表
      final clientIds = await _query.queryClientIds(
        coachId,
        status: status,
      );

      if (clientIds.isEmpty) {
        return [];
      }

      // 批量查詢用戶資料（避免 N+1 問題）
      final response = await _supabase
          .from('users')
          .select('''
            id,
            email,
            display_name,
            photo_url,
            is_coach,
            is_student,
            profile_created_at
          ''')
          .inFilter('id', clientIds);

      final data = response as List<dynamic>;
      final users = data
          .map((json) => UserModel.fromSupabase(json as Map<String, dynamic>))
          .toList();

      // 更新快取
      _cache.setClientDetails(coachId, status, users);

      return users;
    } catch (e) {
      _errorService.logError(
        '獲取學員詳情失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<bool> isActiveRelationship(String coachId, String clientId) async {
    try {
      // 檢查快取
      final cached = _cache.getActiveCheck(coachId, clientId);
      if (cached != null) {
        return cached;
      }

      // 查詢資料庫
      final isActive = await _query.checkActiveRelationship(coachId, clientId);

      // 更新快取
      _cache.setActiveCheck(coachId, clientId, isActive);

      return isActive;
    } catch (e) {
      _errorService.logError(
        '檢查活躍關係失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      return false;
    }
  }

  @override
  Future<int> getActiveClientCount(String coachId) async {
    try {
      return await _query.getActiveClientCount(coachId);
    } catch (e) {
      _errorService.logError(
        '獲取學員數量失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      return 0;
    }
  }

  // ============================================================================
  // 建立與邀請功能
  // ============================================================================

  @override
  Future<CoachingRelationshipModel> inviteClient(
    String coachId,
    String clientEmail, {
    String? notes,
  }) async {
    try {
      // 查詢學員是否已註冊
      final response = await _supabase
          .from('users')
          .select('id, email')
          .eq('email', clientEmail)
          .maybeSingle();

      if (response == null) {
        throw Exception('該 Email 尚未註冊，請學員先註冊後再邀請');
      }

      final clientId = response['id'] as String;

      // 創建 pending 關係
      final relationship = await _operations.createRelationship(
        coachId: coachId,
        clientId: clientId,
        status: 'pending',
        notes: notes,
      );

      // 清除快取
      _cache.clearRelationshipCache(coachId, clientId);

      return relationship;
    } catch (e) {
      _errorService.logError(
        '邀請學員失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<CoachingRelationshipModel> createRelationship(
    String coachId,
    String clientId, {
    String status = 'pending',
    String? notes,
  }) async {
    try {
      final relationship = await _operations.createRelationship(
        coachId: coachId,
        clientId: clientId,
        status: status,
        notes: notes,
      );

      // 清除快取
      _cache.clearRelationshipCache(coachId, clientId);

      return relationship;
    } catch (e) {
      _errorService.logError(
        '創建綁定關係失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  // ============================================================================
  // 更新與管理功能
  // ============================================================================

  @override
  Future<void> acceptInvitation(String relationshipId) async {
    try {
      // 先查詢關係以獲取 coach_id 和 client_id（用於清除快取）
      final relationship = await _query.queryById(relationshipId);
      if (relationship == null) {
        throw Exception('找不到該綁定關係');
      }

      // 更新狀態
      await _operations.updateStatus(
        relationshipId: relationshipId,
        status: 'active',
        acceptedAt: DateTime.now(),
      );

      // 清除快取
      _cache.clearRelationshipCache(
        relationship.coachId,
        relationship.clientId,
      );
    } catch (e) {
      _errorService.logError(
        '接受邀請失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<void> rejectInvitation(String relationshipId) async {
    try {
      final relationship = await _query.queryById(relationshipId);
      if (relationship == null) {
        throw Exception('找不到該綁定關係');
      }

      await _operations.updateStatus(
        relationshipId: relationshipId,
        status: 'rejected',
      );

      _cache.clearRelationshipCache(
        relationship.coachId,
        relationship.clientId,
      );
    } catch (e) {
      _errorService.logError(
        '拒絕邀請失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<void> archiveRelationship(String relationshipId) async {
    try {
      final relationship = await _query.queryById(relationshipId);
      if (relationship == null) {
        throw Exception('找不到該綁定關係');
      }

      await _operations.updateStatus(
        relationshipId: relationshipId,
        status: 'archived',
      );

      _cache.clearRelationshipCache(
        relationship.coachId,
        relationship.clientId,
      );
    } catch (e) {
      _errorService.logError(
        '歸檔關係失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateNotes(String relationshipId, String notes) async {
    try {
      final relationship = await _query.queryById(relationshipId);
      if (relationship == null) {
        throw Exception('找不到該綁定關係');
      }

      await _operations.updateNotes(
        relationshipId: relationshipId,
        notes: notes,
      );

      _cache.clearCoachCache(relationship.coachId);
    } catch (e) {
      _errorService.logError(
        '更新備註失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteRelationship(String relationshipId) async {
    try {
      final relationship = await _query.queryById(relationshipId);
      if (relationship == null) {
        throw Exception('找不到該綁定關係');
      }

      await _operations.deleteRelationship(relationshipId);

      _cache.clearRelationshipCache(
        relationship.coachId,
        relationship.clientId,
      );
    } catch (e) {
      _errorService.logError(
        '刪除綁定關係失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  // ============================================================================
  // 快取管理
  // ============================================================================

  @override
  void clearCache() {
    _cache.clearAll();
  }

  @override
  void clearCoachCache(String coachId) {
    _cache.clearCoachCache(coachId);
  }

  @override
  void clearClientCache(String clientId) {
    _cache.clearClientCache(clientId);
  }
}

