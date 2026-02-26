import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../interfaces/i_coaching_relationship_service.dart';
import '../../models/coaching_relationship_model.dart';
import '../../models/user/user_model.dart';
import '../../models/client_with_relationship.dart';
import '../../models/coach_with_relationship.dart';
import '../core/error_handling_service.dart';
import '../cache/relationship_local_cache_service.dart';
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
  final RelationshipLocalCacheService? _localCacheService;  // ⚡ Hive 持久化快取

  // 子模組
  late final CoachingRelationshipQuery _query;
  late final CoachingRelationshipOperations _operations;
  late final CoachingRelationshipCacheManager _cache;

  CoachingRelationshipServiceSupabase(
    this._supabase,
    this._errorService, {
    RelationshipLocalCacheService? localCacheService,  // ⚡ 新增參數
  }) : _localCacheService = localCacheService {
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
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        // ⚡ 1. 優先檢查記憶體快取（最快）
        final memoryCached = _cache.getCoachClients(coachId, status);
        if (memoryCached != null) {
          return memoryCached;
        }

        // ⚡ 2. 檢查 Hive 持久化快取
        if (_localCacheService != null) {
          final hiveCached = await _localCacheService!.getCachedCoachClientsAsync(coachId, status);
          if (hiveCached != null) {
            if (kDebugMode) {
              debugPrint('[RELATIONSHIP_SERVICE] ⚡ 從 Hive 快取載入 ${hiveCached.length} 個學員關係');
            }
            // 同步到記憶體快取
            _cache.setCoachClients(coachId, status, hiveCached);
            // 背景更新（不阻塞）
            _refreshCoachClientsInBackground(coachId, status);
            return hiveCached;
          }
        }
      }

      // 3. 查詢資料庫
      final relationships = await _query.queryCoachClients(
        coachId,
        status: status,
      );

      // ⚡ 更新記憶體快取
      _cache.setCoachClients(coachId, status, relationships);
      // ⚡ 更新 Hive 快取
      await _localCacheService?.cacheCoachClients(coachId, status, relationships);

      return relationships;
    } catch (e) {
      _errorService.logError(
        '獲取教練學員列表失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  /// 背景刷新教練的學員列表（不阻塞 UI）
  Future<void> _refreshCoachClientsInBackground(String coachId, String? status) async {
    try {
      final relationships = await _query.queryCoachClients(coachId, status: status);
      _cache.setCoachClients(coachId, status, relationships);
      await _localCacheService?.cacheCoachClients(coachId, status, relationships);
      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_SERVICE] ⚡ 背景刷新學員列表完成');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_SERVICE] 背景刷新學員列表失敗: $e');
      }
    }
  }

  @override
  Future<List<CoachingRelationshipModel>> getClientCoaches(
    String clientId, {
    String? status,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        // ⚡ 1. 優先檢查記憶體快取（最快）
        final memoryCached = _cache.getClientCoaches(clientId, status);
        if (memoryCached != null) {
          return memoryCached;
        }

        // ⚡ 2. 檢查 Hive 持久化快取
        if (_localCacheService != null) {
          final hiveCached = await _localCacheService!.getCachedClientCoachesAsync(clientId, status);
          if (hiveCached != null) {
            if (kDebugMode) {
              debugPrint('[RELATIONSHIP_SERVICE] ⚡ 從 Hive 快取載入 ${hiveCached.length} 個教練關係');
            }
            // 同步到記憶體快取
            _cache.setClientCoaches(clientId, status, hiveCached);
            // 背景更新（不阻塞）
            _refreshClientCoachesInBackground(clientId, status);
            return hiveCached;
          }
        }
      }

      // 3. 查詢資料庫
      final relationships = await _query.queryClientCoaches(
        clientId,
        status: status,
      );

      // ⚡ 更新記憶體快取
      _cache.setClientCoaches(clientId, status, relationships);
      // ⚡ 更新 Hive 快取
      await _localCacheService?.cacheClientCoaches(clientId, status, relationships);

      return relationships;
    } catch (e) {
      _errorService.logError(
        '獲取學員教練列表失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  /// 背景刷新學員的教練列表（不阻塞 UI）
  Future<void> _refreshClientCoachesInBackground(String clientId, String? status) async {
    try {
      final relationships = await _query.queryClientCoaches(clientId, status: status);
      _cache.setClientCoaches(clientId, status, relationships);
      await _localCacheService?.cacheClientCoaches(clientId, status, relationships);
      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_SERVICE] ⚡ 背景刷新教練列表完成');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_SERVICE] 背景刷新教練列表失敗: $e');
      }
    }
  }

  @override
  Future<List<UserModel>> getCoachClientsWithDetails(
    String coachId, {
    String? status,
    bool forceRefresh = false,
  }) async {
    try {
      // 檢查快取
      if (!forceRefresh) {
        final cached = _cache.getClientDetails(coachId, status);
        if (cached != null) {
          return cached;
        }
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
      final response = await _supabase.from('users').select('''
            id,
            email,
            display_name,
            photo_url,
            is_coach,
            is_student,
            profile_created_at
          ''').inFilter('id', clientIds);

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
  Future<List<ClientWithRelationship>> getCoachClientsWithRelationship(
    String coachId, {
    String? status,
  }) async {
    try {
      // 1. 查詢所有關係（包含已刪除的學員）
      final relationships = await _query.queryCoachClients(
        coachId,
        status: status,
      );

      // 2. 提取有效的學員 ID（過濾 null）
      final validClientIds = relationships
          .where((r) => r.clientId != null)
          .map((r) => r.clientId!)
          .toList();

      // 3. 批量查詢用戶資料
      Map<String, UserModel> usersMap = {};
      if (validClientIds.isNotEmpty) {
        final response = await _supabase.from('users').select('''
              id,
              email,
              display_name,
              photo_url,
              is_coach,
              is_student,
              profile_created_at
            ''').inFilter('id', validClientIds);

        final data = response as List<dynamic>;
        for (final json in data) {
          final user = UserModel.fromSupabase(json as Map<String, dynamic>);
          usersMap[user.uid] = user;
        }
      }

      // 4. 組合結果（關係 + 用戶資料）
      final results = <ClientWithRelationship>[];
      for (final relationship in relationships) {
        final user = relationship.clientId != null
            ? usersMap[relationship.clientId!]
            : null;

        results.add(ClientWithRelationship(
          user: user,
          relationship: relationship,
        ));
      }

      return results;
    } catch (e) {
      _errorService.logError(
        '獲取學員及關係狀態失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  /// ⭐ 新增：取得學員的教練列表（含關係狀態）
  @override
  Future<List<CoachWithRelationship>> getClientCoachesWithRelationship(
    String clientId, {
    String? status,
  }) async {
    try {
      // 1. 查詢所有關係（包含已刪除的教練）
      final relationships = await _query.queryClientCoaches(
        clientId,
        status: status,
      );

      // 2. 提取有效的教練 ID（過濾 null）
      final validCoachIds = relationships
          .where((r) => r.coachId != null)
          .map((r) => r.coachId!)
          .toList();

      // 3. 批量查詢用戶資料
      Map<String, UserModel> usersMap = {};
      if (validCoachIds.isNotEmpty) {
        final response = await _supabase.from('users').select('''
              id,
              email,
              display_name,
              photo_url,
              is_coach,
              is_student,
              profile_created_at
            ''').inFilter('id', validCoachIds);

        final data = response as List<dynamic>;
        for (final json in data) {
          final user = UserModel.fromSupabase(json as Map<String, dynamic>);
          usersMap[user.uid] = user;
        }
      }

      // 4. 組合結果（關係 + 用戶資料）
      final results = <CoachWithRelationship>[];
      for (final relationship in relationships) {
        final user = relationship.coachId != null
            ? usersMap[relationship.coachId!]
            : null;

        results.add(CoachWithRelationship(
          user: user,
          relationship: relationship,
        ));
      }

      return results;
    } catch (e) {
      _errorService.logError(
        '獲取教練及關係狀態失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<CoachingRelationshipModel?> getRelationshipByUsers(
    String coachId,
    String clientId,
  ) async {
    try {
      return await _query.queryByUsers(coachId, clientId);
    } catch (e) {
      _errorService.logError(
        '查詢綁定關係失敗: $e',
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
    String clientEmail,
  ) async {
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
      );

      // ⚡ 清除記憶體快取
      _cache.clearRelationshipCache(coachId, clientId);
      // ⚡ 清除 Hive 快取
      await _localCacheService?.clearRelationshipCache(coachId, clientId);

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
  }) async {
    try {
      final relationship = await _operations.createRelationship(
        coachId: coachId,
        clientId: clientId,
        status: status,
      );

      // ⚡ 清除記憶體快取
      _cache.clearRelationshipCache(coachId, clientId);
      // ⚡ 清除 Hive 快取
      await _localCacheService?.clearRelationshipCache(coachId, clientId);

      return relationship;
    } catch (e) {
      _errorService.logError(
        '創建綁定關係失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  /// ⭐ QR Code 綁定（RPC 版本）
  @override
  Future<QrCodeBindResult> bindByQrCode({
    required String scannedUserId,
    required String myUserId,
    required String myRole,
  }) async {
    try {
      final response = await _supabase.rpc(
        'bind_by_qr_code',
        params: {
          'p_scanned_user_id': scannedUserId,
          'p_my_user_id': myUserId,
          'p_my_role': myRole,
        },
      );

      // RPC 返回 JSON
      if (response is Map<String, dynamic>) {
        final result = QrCodeBindResult.fromJson(response);
        
        // 成功時清除快取
        if (result.success && result.coachId != null && result.clientId != null) {
          // ⚡ 清除記憶體快取
          _cache.clearRelationshipCache(result.coachId!, result.clientId!);
          // ⚡ 清除 Hive 快取
          await _localCacheService?.clearRelationshipCache(result.coachId!, result.clientId!);
        }
        
        return result;
      }

      return QrCodeBindResult(
        success: false,
        error: '綁定失敗：無效的回應格式',
      );
    } catch (e) {
      _errorService.logError(
        'QR Code 綁定失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      return QrCodeBindResult(
        success: false,
        error: '綁定失敗：$e',
      );
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

      // ⚡ 清除記憶體快取
      _cache.clearRelationshipCache(
        relationship.coachId,
        relationship.clientId,
      );
      // ⚡ 清除 Hive 快取
      await _localCacheService?.clearRelationshipCache(
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

      // ⚡ 清除記憶體快取
      _cache.clearRelationshipCache(
        relationship.coachId,
        relationship.clientId,
      );
      // ⚡ 清除 Hive 快取
      await _localCacheService?.clearRelationshipCache(
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

      // ⚡ 清除記憶體快取
      _cache.clearRelationshipCache(
        relationship.coachId,
        relationship.clientId,
      );
      // ⚡ 清除 Hive 快取
      await _localCacheService?.clearRelationshipCache(
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
  Future<void> deleteRelationship(String relationshipId) async {
    try {
      final relationship = await _query.queryById(relationshipId);
      if (relationship == null) {
        throw Exception('找不到該綁定關係');
      }

      await _operations.deleteRelationship(relationshipId);

      // ⚡ 清除記憶體快取
      _cache.clearRelationshipCache(
        relationship.coachId,
        relationship.clientId,
      );
      // ⚡ 清除 Hive 快取
      await _localCacheService?.clearRelationshipCache(
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
    // ⚡ 同步清除 Hive 快取
    _localCacheService?.clearAllCache();
  }

  @override
  void clearCoachCache(String coachId) {
    _cache.clearCoachCache(coachId);
    // ⚡ 同步清除 Hive 快取
    _localCacheService?.clearCoachCache(coachId);
  }

  @override
  void clearClientCache(String clientId) {
    _cache.clearClientCache(clientId);
    // ⚡ 同步清除 Hive 快取
    _localCacheService?.clearClientCache(clientId);
  }

  // ============================================================================
  // 學員檔案管理
  // ============================================================================

  @override
  Future<CoachingRelationshipModel?> getRelationshipByIdDetailed(
    String relationshipId,
  ) async {
    try {
      return await _query.queryByIdDetailed(relationshipId);
    } catch (e) {
      _errorService.logError(
        '獲取關係詳情失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<CoachingRelationshipModel?> getRelationshipByUsersDetailed(
    String coachId,
    String clientId,
  ) async {
    try {
      return await _query.queryByUsersDetailed(coachId, clientId);
    } catch (e) {
      _errorService.logError(
        '根據用戶獲取關係詳情失敗: $e',
        type: 'CoachingRelationshipServiceError',
      );
      rethrow;
    }
  }
}
