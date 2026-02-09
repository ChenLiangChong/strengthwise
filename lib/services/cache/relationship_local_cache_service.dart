import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/coaching_relationship_model.dart';
import '../../utils/datetime_utils.dart';
import '../../utils/hive_encryption_helper.dart';

/// 教練學員關係本地快取服務
///
/// 使用 Hive 將關係列表持久化存儲
/// App 啟動時首頁可立即顯示學員列表，無需等待網路
class RelationshipLocalCacheService {
  static const String _boxName = 'relationship_cache';
  static const String _versionKey = 'cache_version';
  static const String _coachClientsPrefix = 'coach_clients_';
  static const String _clientCoachesPrefix = 'client_coaches_';
  static const String _lastUpdatePrefix = 'last_update_';

  /// 快取版本（更新此版本號會觸發清除舊快取）
  static const int currentCacheVersion = 1;

  /// 快取有效期（7 天，關係變化不頻繁）
  static const Duration cacheValidDuration = Duration(days: 7);

  Box? _box;
  bool _isInitializing = false;
  bool _isInitialized = false;

  /// 確保已初始化（懶加載）
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    await initialize();
  }

  /// 初始化 Hive Box
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitializing = true;

    try {
      // ⭐ v3.7: Hive.initFlutter() 已在 main.dart 統一初始化，這裡不再重複調用

      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          _box = await HiveEncryptionHelper.openBox(_boxName);
          _validateVersion();
          _isInitialized = true;
          _isInitializing = false;
          if (kDebugMode) {
            debugPrint('[RELATIONSHIP_CACHE] 本地快取初始化完成');
          }
          return;
        } catch (e) {
          retryCount++;
          if (kDebugMode) {
            debugPrint('[RELATIONSHIP_CACHE] 初始化失敗 (第 $retryCount/$maxRetries 次): $e');
          }

          if (e.toString().contains('lock failed') ||
              e.toString().contains('already open')) {
            try {
              if (await Hive.boxExists(_boxName)) {
                await Hive.deleteBoxFromDisk(_boxName);
              }
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
            } catch (cleanupError) {
              if (kDebugMode) {
                debugPrint('[RELATIONSHIP_CACHE] 清理失敗: $cleanupError');
              }
            }
          }

          if (retryCount >= maxRetries) {
            if (kDebugMode) {
              debugPrint('[RELATIONSHIP_CACHE] ⚠️ 初始化失敗，將使用無快取模式');
            }
            _box = null;
            _isInitialized = true;
            _isInitializing = false;
            return;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_CACHE] 初始化過程發生錯誤: $e');
      }
      _box = null;
      _isInitialized = true;
      _isInitializing = false;
    }
  }

  /// 驗證快取版本
  void _validateVersion() {
    if (_box == null) return;

    final cachedVersion = _box!.get(_versionKey, defaultValue: 0);
    if (cachedVersion != currentCacheVersion) {
      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_CACHE] 快取版本不符，清除舊快取');
      }
      _box!.clear();
      _box!.put(_versionKey, currentCacheVersion);
    }
  }

  // ============================================================================
  // 教練視角：獲取學員列表
  // ============================================================================

  /// 檢查教練的學員快取是否有效
  bool isCoachClientsCacheValid(String coachId, String? status) {
    if (!_isInitialized || _box == null) return false;
    return _checkCacheValidity('$_coachClientsPrefix${coachId}_${status ?? 'all'}');
  }

  /// 獲取教練的學員列表（同步版本）
  List<CoachingRelationshipModel>? getCachedCoachClients(String coachId, String? status) {
    if (_box == null) return null;

    final cacheKey = '$_coachClientsPrefix${coachId}_${status ?? 'all'}';

    try {
      final cachedData = _box!.get(cacheKey);
      if (cachedData == null) return null;

      final list = (cachedData as List).cast<Map>();
      // ⭐ v3.7: 使用遞迴轉換，解決 Hive 嵌套 Map 類型問題
      final relationships = list
          .map((json) => CoachingRelationshipModel.fromSupabase(_convertToMapStringDynamic(json)))
          .toList();

      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_CACHE] 📦 從快取載入 ${relationships.length} 個學員關係');
      }

      return relationships;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_CACHE] ⚠️ 解析快取失敗：$e');
      }
      _box!.delete(cacheKey);
      return null;
    }
  }

  /// 獲取教練的學員列表（異步版本）
  Future<List<CoachingRelationshipModel>?> getCachedCoachClientsAsync(
    String coachId,
    String? status,
  ) async {
    await _ensureInitialized();
    if (_box == null) return null;

    final cacheKey = '$_coachClientsPrefix${coachId}_${status ?? 'all'}';
    if (!_checkCacheValidity(cacheKey)) return null;

    return getCachedCoachClients(coachId, status);
  }

  /// 儲存教練的學員列表
  Future<void> cacheCoachClients(
    String coachId,
    String? status,
    List<CoachingRelationshipModel> relationships,
  ) async {
    await _ensureInitialized();
    if (_box == null) return;

    final cacheKey = '$_coachClientsPrefix${coachId}_${status ?? 'all'}';
    final lastUpdateKey = '$_lastUpdatePrefix$cacheKey';

    try {
      final jsonList = relationships.map((r) => r.toMap()).toList();
      await _box!.put(cacheKey, jsonList);
      await _box!.put(lastUpdateKey, DateTimeUtils.formatToUtcIso(DateTime.now()));

      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_CACHE] 💾 已儲存 ${relationships.length} 個學員關係');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_CACHE] ⚠️ 儲存失敗：$e');
      }
    }
  }

  // ============================================================================
  // 學員視角：獲取教練列表
  // ============================================================================

  /// 檢查學員的教練快取是否有效
  bool isClientCoachesCacheValid(String clientId, String? status) {
    if (!_isInitialized || _box == null) return false;
    return _checkCacheValidity('$_clientCoachesPrefix${clientId}_${status ?? 'all'}');
  }

  /// 獲取學員的教練列表（同步版本）
  List<CoachingRelationshipModel>? getCachedClientCoaches(String clientId, String? status) {
    if (_box == null) return null;

    final cacheKey = '$_clientCoachesPrefix${clientId}_${status ?? 'all'}';

    try {
      final cachedData = _box!.get(cacheKey);
      if (cachedData == null) return null;

      final list = (cachedData as List).cast<Map>();
      // ⭐ v3.7: 使用遞迴轉換，解決 Hive 嵌套 Map 類型問題
      final relationships = list
          .map((json) => CoachingRelationshipModel.fromSupabase(_convertToMapStringDynamic(json)))
          .toList();

      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_CACHE] 📦 從快取載入 ${relationships.length} 個教練關係');
      }

      return relationships;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_CACHE] ⚠️ 解析快取失敗：$e');
      }
      _box!.delete(cacheKey);
      return null;
    }
  }

  /// 獲取學員的教練列表（異步版本）
  Future<List<CoachingRelationshipModel>?> getCachedClientCoachesAsync(
    String clientId,
    String? status,
  ) async {
    await _ensureInitialized();
    if (_box == null) return null;

    final cacheKey = '$_clientCoachesPrefix${clientId}_${status ?? 'all'}';
    if (!_checkCacheValidity(cacheKey)) return null;

    return getCachedClientCoaches(clientId, status);
  }

  /// 儲存學員的教練列表
  Future<void> cacheClientCoaches(
    String clientId,
    String? status,
    List<CoachingRelationshipModel> relationships,
  ) async {
    await _ensureInitialized();
    if (_box == null) return;

    final cacheKey = '$_clientCoachesPrefix${clientId}_${status ?? 'all'}';
    final lastUpdateKey = '$_lastUpdatePrefix$cacheKey';

    try {
      final jsonList = relationships.map((r) => r.toMap()).toList();
      await _box!.put(cacheKey, jsonList);
      await _box!.put(lastUpdateKey, DateTimeUtils.formatToUtcIso(DateTime.now()));

      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_CACHE] 💾 已儲存 ${relationships.length} 個教練關係');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RELATIONSHIP_CACHE] ⚠️ 儲存失敗：$e');
      }
    }
  }

  // ============================================================================
  // 快取清除
  // ============================================================================

  /// 清除教練的快取（關係變更時調用）
  Future<void> clearCoachCache(String coachId) async {
    await _ensureInitialized();
    if (_box == null) return;

    final keysToDelete = <String>[];
    for (var key in _box!.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('$_coachClientsPrefix$coachId') ||
          keyStr.startsWith('$_lastUpdatePrefix$_coachClientsPrefix$coachId')) {
        keysToDelete.add(keyStr);
      }
    }

    for (var key in keysToDelete) {
      await _box!.delete(key);
    }

    if (kDebugMode) {
      debugPrint('[RELATIONSHIP_CACHE] 🗑️ 已清除教練快取：$coachId');
    }
  }

  /// 清除學員的快取（關係變更時調用）
  Future<void> clearClientCache(String clientId) async {
    await _ensureInitialized();
    if (_box == null) return;

    final keysToDelete = <String>[];
    for (var key in _box!.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('$_clientCoachesPrefix$clientId') ||
          keyStr.startsWith('$_lastUpdatePrefix$_clientCoachesPrefix$clientId')) {
        keysToDelete.add(keyStr);
      }
    }

    for (var key in keysToDelete) {
      await _box!.delete(key);
    }

    if (kDebugMode) {
      debugPrint('[RELATIONSHIP_CACHE] 🗑️ 已清除學員快取：$clientId');
    }
  }

  /// 清除特定用戶的所有快取（雙向）
  Future<void> clearUserCache(String userId) async {
    await clearCoachCache(userId);
    await clearClientCache(userId);
  }

  /// 清除特定關係的快取（CRUD 操作後）
  Future<void> clearRelationshipCache(String? coachId, String? clientId) async {
    if (coachId != null) {
      await clearCoachCache(coachId);
    }
    if (clientId != null) {
      await clearClientCache(clientId);
    }
  }

  /// 清除所有快取
  Future<void> clearAllCache() async {
    await _ensureInitialized();
    if (_box == null) return;

    await _box!.clear();
    await _box!.put(_versionKey, currentCacheVersion);

    if (kDebugMode) {
      debugPrint('[RELATIONSHIP_CACHE] 🗑️ 已清除所有快取');
    }
  }

  // ============================================================================
  // 工具方法
  // ============================================================================

  /// 內部快取有效性檢查
  bool _checkCacheValidity(String cacheKey) {
    final lastUpdateKey = '$_lastUpdatePrefix$cacheKey';

    // 檢查是否有數據
    if (!_box!.containsKey(cacheKey)) return false;

    // 檢查快取時間
    final lastUpdateStr = _box!.get(lastUpdateKey) as String?;
    if (lastUpdateStr == null) return false;

    final lastUpdate = DateTimeUtils.parseIsoTimestamp(lastUpdateStr);
    final now = DateTime.now();

    return now.difference(lastUpdate) < cacheValidDuration;
  }

  /// 獲取快取資訊
  Map<String, dynamic> getCacheInfo() {
    if (_box == null) {
      return {'initialized': false};
    }

    final coachKeys = _box!.keys
        .where((k) => k.toString().startsWith(_coachClientsPrefix))
        .toList();
    final clientKeys = _box!.keys
        .where((k) => k.toString().startsWith(_clientCoachesPrefix))
        .toList();

    return {
      'initialized': true,
      'version': _box!.get(_versionKey, defaultValue: 0),
      'cachedCoachClients': coachKeys.length,
      'cachedClientCoaches': clientKeys.length,
    };
  }

  /// 關閉 Box
  Future<void> close() async {
    await _box?.close();
    _box = null;
    _isInitialized = false;
  }

  /// ⭐ v3.7: 遞迴將 Hive 的 _Map<dynamic, dynamic> 轉換為 Map<String, dynamic>
  Map<String, dynamic> _convertToMapStringDynamic(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _convertToMapStringDynamic(value));
        } else if (value is List) {
          return MapEntry(key.toString(), _convertList(value));
        } else {
          return MapEntry(key.toString(), value);
        }
      });
    }
    return {};
  }

  /// ⭐ v3.7: 遞迴轉換 List 中的嵌套 Map
  List<dynamic> _convertList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map) {
        return _convertToMapStringDynamic(item);
      } else if (item is List) {
        return _convertList(item);
      } else {
        return item;
      }
    }).toList();
  }
}
