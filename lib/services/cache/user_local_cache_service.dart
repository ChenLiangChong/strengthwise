import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user/user_model.dart';
import '../../utils/datetime_utils.dart';

/// 用戶本地快取服務
///
/// 使用 Hive 將用戶資料持久化存儲
/// App 啟動時可立即顯示用戶名稱、頭像，無需等待網路
class UserLocalCacheService {
  static const String _boxName = 'user_cache';
  static const String _versionKey = 'cache_version';
  static const String _userPrefix = 'user_';
  static const String _lastUpdatePrefix = 'last_update_';

  /// 快取版本（更新此版本號會觸發清除舊快取）
  static const int currentCacheVersion = 1;

  /// 快取有效期（7 天，用戶資料變化不頻繁）
  static const Duration cacheValidDuration = Duration(days: 7);

  Box? _box;
  bool _isInitializing = false;
  bool _isInitialized = false;

  /// 確保已初始化（懶加載）
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // 等待初始化完成
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
          _box = await Hive.openBox(_boxName);
          _validateVersion();
          _isInitialized = true;
          _isInitializing = false;
          if (kDebugMode) {
            debugPrint('[USER_CACHE] 本地快取初始化完成');
          }
          return;
        } catch (e) {
          retryCount++;
          if (kDebugMode) {
            debugPrint('[USER_CACHE] 初始化失敗 (第 $retryCount/$maxRetries 次): $e');
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
                debugPrint('[USER_CACHE] 清理失敗: $cleanupError');
              }
            }
          }

          if (retryCount >= maxRetries) {
            if (kDebugMode) {
              debugPrint('[USER_CACHE] ⚠️ 初始化失敗，將使用無快取模式');
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
        debugPrint('[USER_CACHE] 初始化過程發生錯誤: $e');
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
        debugPrint('[USER_CACHE] 快取版本不符，清除舊快取');
      }
      _box!.clear();
      _box!.put(_versionKey, currentCacheVersion);
    }
  }

  /// 檢查快取是否有效（同步版本）
  bool isCacheValid(String userId) {
    if (!_isInitialized || _box == null) return false;
    return _checkCacheValidity(userId);
  }

  /// 檢查快取是否有效（異步版本）
  Future<bool> isCacheValidAsync(String userId) async {
    await _ensureInitialized();
    if (_box == null) return false;
    return _checkCacheValidity(userId);
  }

  /// 內部快取有效性檢查
  bool _checkCacheValidity(String userId) {
    final userKey = '$_userPrefix$userId';
    final lastUpdateKey = '$_lastUpdatePrefix$userId';

    // 檢查是否有數據
    if (!_box!.containsKey(userKey)) return false;

    // 檢查快取時間
    final lastUpdateStr = _box!.get(lastUpdateKey) as String?;
    if (lastUpdateStr == null) return false;

    final lastUpdate = DateTimeUtils.parseIsoTimestamp(lastUpdateStr);
    final now = DateTime.now();

    final isValid = now.difference(lastUpdate) < cacheValidDuration;

    if (kDebugMode && isValid) {
      debugPrint('[USER_CACHE] ✅ 快取有效：$userId');
    }

    return isValid;
  }

  /// 獲取快取的用戶資料（同步版本，啟動時使用）
  UserModel? getCachedUser(String userId) {
    if (_box == null) return null;

    final userKey = '$_userPrefix$userId';

    try {
      final cachedData = _box!.get(userKey);
      if (cachedData == null) return null;

      // ⭐ v3.7: 使用遞迴轉換，解決 Hive 嵌套 Map 類型問題
      final json = _convertToMapStringDynamic(cachedData);
      final user = UserModel.fromMap(json);

      if (kDebugMode) {
        debugPrint('[USER_CACHE] 📦 從快取載入用戶：${user.displayName ?? user.email}');
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[USER_CACHE] ⚠️ 解析快取失敗：$e');
      }
      // 解析失敗，刪除損壞的快取
      _box!.delete(userKey);
      return null;
    }
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

  /// 獲取快取的用戶資料（異步版本，會自動初始化）
  Future<UserModel?> getCachedUserAsync(String userId) async {
    await _ensureInitialized();
    if (_box == null) return null;

    if (!_checkCacheValidity(userId)) return null;

    return getCachedUser(userId);
  }

  /// 儲存用戶資料到快取
  Future<void> cacheUser(UserModel user) async {
    await _ensureInitialized();
    if (_box == null) return;

    final userKey = '$_userPrefix${user.uid}';
    final lastUpdateKey = '$_lastUpdatePrefix${user.uid}';

    try {
      final json = user.toMap();
      await _box!.put(userKey, json);
      await _box!.put(lastUpdateKey, DateTimeUtils.formatToUtcIso(DateTime.now()));

      if (kDebugMode) {
        debugPrint('[USER_CACHE] 💾 已儲存用戶：${user.displayName ?? user.email}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[USER_CACHE] ⚠️ 儲存失敗：$e');
      }
    }
  }

  /// 清除指定用戶的快取
  Future<void> clearUserCache(String userId) async {
    await _ensureInitialized();
    if (_box == null) return;

    final userKey = '$_userPrefix$userId';
    final lastUpdateKey = '$_lastUpdatePrefix$userId';

    await _box!.delete(userKey);
    await _box!.delete(lastUpdateKey);

    if (kDebugMode) {
      debugPrint('[USER_CACHE] 🗑️ 已清除用戶快取：$userId');
    }
  }

  /// 清除所有快取（登出時使用）
  Future<void> clearAllCache() async {
    await _ensureInitialized();
    if (_box == null) return;

    await _box!.clear();
    await _box!.put(_versionKey, currentCacheVersion);

    if (kDebugMode) {
      debugPrint('[USER_CACHE] 🗑️ 已清除所有快取');
    }
  }

  /// 獲取快取資訊
  Map<String, dynamic> getCacheInfo() {
    if (_box == null) {
      return {'initialized': false};
    }

    final userKeys = _box!.keys
        .where((k) => k.toString().startsWith(_userPrefix))
        .toList();

    return {
      'initialized': true,
      'version': _box!.get(_versionKey, defaultValue: 0),
      'cachedUsers': userKeys.length,
      'keys': userKeys.map((k) => k.toString().replaceFirst(_userPrefix, '')).toList(),
    };
  }

  /// 關閉 Box
  Future<void> close() async {
    await _box?.close();
    _box = null;
    _isInitialized = false;
  }
}
