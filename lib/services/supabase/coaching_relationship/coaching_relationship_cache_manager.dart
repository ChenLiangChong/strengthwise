import '../../../models/coaching_relationship_model.dart';
import '../../../models/user/user_model.dart';

/// 教練-學員關係快取管理
///
/// 管理關係列表和用戶詳情的記憶體快取
class CoachingRelationshipCacheManager {
  // 快取有效期（5 分鐘）
  static const Duration _cacheDuration = Duration(minutes: 5);

  // 教練的學員列表快取（按狀態分類）
  final Map<String, Map<String, _CacheEntry<List<CoachingRelationshipModel>>>>
      _coachClientsCache = {};

  // 學員的教練列表快取（按狀態分類）
  final Map<String, Map<String, _CacheEntry<List<CoachingRelationshipModel>>>>
      _clientCoachesCache = {};

  // 學員詳情快取
  final Map<String, _CacheEntry<List<UserModel>>> _clientDetailsCache = {};

  // 活躍關係檢查快取
  final Map<String, _CacheEntry<bool>> _activeCheckCache = {};

  // ============================================================================
  // 快取讀取
  // ============================================================================

  /// 獲取教練的學員列表快取
  List<CoachingRelationshipModel>? getCoachClients(
    String coachId,
    String? status,
  ) {
    final statusKey = status ?? 'all';
    return _coachClientsCache[coachId]?[statusKey]?.value;
  }

  /// 獲取學員的教練列表快取
  List<CoachingRelationshipModel>? getClientCoaches(
    String clientId,
    String? status,
  ) {
    final statusKey = status ?? 'all';
    return _clientCoachesCache[clientId]?[statusKey]?.value;
  }

  /// 獲取學員詳情快取
  List<UserModel>? getClientDetails(String coachId, String? status) {
    final cacheKey = '$coachId:${status ?? 'all'}';
    return _clientDetailsCache[cacheKey]?.value;
  }

  /// 獲取活躍關係檢查快取
  bool? getActiveCheck(String coachId, String clientId) {
    final cacheKey = '$coachId:$clientId';
    return _activeCheckCache[cacheKey]?.value;
  }

  // ============================================================================
  // 快取寫入
  // ============================================================================

  /// 設置教練的學員列表快取
  void setCoachClients(
    String coachId,
    String? status,
    List<CoachingRelationshipModel> data,
  ) {
    final statusKey = status ?? 'all';
    _coachClientsCache[coachId] ??= {};
    _coachClientsCache[coachId]![statusKey] = _CacheEntry(data);
  }

  /// 設置學員的教練列表快取
  void setClientCoaches(
    String clientId,
    String? status,
    List<CoachingRelationshipModel> data,
  ) {
    final statusKey = status ?? 'all';
    _clientCoachesCache[clientId] ??= {};
    _clientCoachesCache[clientId]![statusKey] = _CacheEntry(data);
  }

  /// 設置學員詳情快取
  void setClientDetails(
    String coachId,
    String? status,
    List<UserModel> data,
  ) {
    final cacheKey = '$coachId:${status ?? 'all'}';
    _clientDetailsCache[cacheKey] = _CacheEntry(data);
  }

  /// 設置活躍關係檢查快取
  void setActiveCheck(String coachId, String clientId, bool isActive) {
    final cacheKey = '$coachId:$clientId';
    _activeCheckCache[cacheKey] = _CacheEntry(isActive);
  }

  // ============================================================================
  // 快取清除
  // ============================================================================

  /// 清除所有快取
  void clearAll() {
    _coachClientsCache.clear();
    _clientCoachesCache.clear();
    _clientDetailsCache.clear();
    _activeCheckCache.clear();
  }

  /// 清除特定教練的快取
  void clearCoachCache(String coachId) {
    _coachClientsCache.remove(coachId);
    _clientDetailsCache
        .removeWhere((key, _) => key.startsWith('$coachId:'));
    _activeCheckCache.removeWhere((key, _) => key.startsWith('$coachId:'));
  }

  /// 清除特定學員的快取
  void clearClientCache(String clientId) {
    _clientCoachesCache.remove(clientId);
    _activeCheckCache.removeWhere((key, _) => key.endsWith(':$clientId'));
  }

  /// 清除特定關係的快取（CRUD 操作後）
  void clearRelationshipCache(String coachId, String clientId) {
    clearCoachCache(coachId);
    clearClientCache(clientId);
  }
}

/// 快取項目（含時間戳記）
class _CacheEntry<T> {
  final T value;
  final DateTime timestamp;

  _CacheEntry(this.value) : timestamp = DateTime.now();

  /// 檢查快取是否有效（5 分鐘內）
  bool get isValid {
    return DateTime.now().difference(timestamp) <
        CoachingRelationshipCacheManager._cacheDuration;
  }
}

