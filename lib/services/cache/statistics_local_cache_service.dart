import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/statistics/statistics_data.dart';
import '../../models/statistics/statistics_serialization.dart';
import '../../models/statistics/time_range.dart';
import '../../utils/datetime_utils.dart';

/// 統計數據本地快取服務
///
/// 使用 Hive 將統計數據持久化存儲到手機
/// 支持多時間範圍快取，App 啟動時可立即顯示
class StatisticsLocalCacheService {
  static const String _boxName = 'statistics_cache';
  static const String _versionKey = 'cache_version';
  static const String _lastUpdatePrefix = 'last_update_';
  static const String _dataPrefix = 'data_';

  /// 快取版本（更新此版本號會觸發清除舊快取）
  /// v3.3: 升級至 v2，支援多元追蹤模式欄位
  /// v3.3+: 升級至 v3，修正時間過濾邏輯（加入 scheduled_date）
  static const int currentCacheVersion = 3;

  /// 快取有效期（24 小時）
  static const Duration cacheValidDuration = Duration(hours: 24);

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
      if (!kIsWeb) {
        await Hive.initFlutter();
      }

      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          _box = await Hive.openBox(_boxName);
          _validateVersion();
          _isInitialized = true;
          _isInitializing = false;
          if (kDebugMode) {
            print('[STATISTICS_CACHE] 本地快取初始化完成');
          }
          return;
        } catch (e) {
          retryCount++;
          if (kDebugMode) {
            print('[STATISTICS_CACHE] 初始化失敗 (第 $retryCount/$maxRetries 次): $e');
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
                print('[STATISTICS_CACHE] 清理失敗: $cleanupError');
              }
            }
          }

          if (retryCount >= maxRetries) {
            if (kDebugMode) {
              print('[STATISTICS_CACHE] ⚠️ 初始化失敗，將使用無快取模式');
            }
            _box = null;
            _isInitialized = true; // 標記為已嘗試初始化
            _isInitializing = false;
            return;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[STATISTICS_CACHE] 初始化過程發生錯誤: $e');
      }
      _box = null;
      _isInitialized = true; // 標記為已嘗試初始化
      _isInitializing = false;
    }
  }

  /// 驗證快取版本
  void _validateVersion() {
    if (_box == null) return;

    final cachedVersion = _box!.get(_versionKey, defaultValue: 0);
    if (cachedVersion != currentCacheVersion) {
      if (kDebugMode) {
        print('[STATISTICS_CACHE] 快取版本不符，清除舊快取');
      }
      _box!.clear();
      _box!.put(_versionKey, currentCacheVersion);
    }
  }

  /// 生成快取 key
  String _getCacheKey(String userId, TimeRange timeRange) {
    return '${userId}_${timeRange.name}';
  }

  /// 檢查指定用戶和時間範圍的快取是否有效（同步版本）
  /// 注意：需要先調用 initialize() 或等待自動初始化
  bool isCacheValid(String userId, TimeRange timeRange) {
    if (!_isInitialized || _box == null) return false;
    return _checkCacheValidity(userId, timeRange);
  }

  /// 檢查指定用戶和時間範圍的快取是否有效（異步版本）
  /// 會自動確保初始化完成
  Future<bool> isCacheValidAsync(String userId, TimeRange timeRange) async {
    await _ensureInitialized();
    if (_box == null) return false;
    return _checkCacheValidity(userId, timeRange);
  }

  /// 內部快取有效性檢查
  bool _checkCacheValidity(String userId, TimeRange timeRange) {
    final key = _getCacheKey(userId, timeRange);
    final lastUpdateKey = '$_lastUpdatePrefix$key';
    final dataKey = '$_dataPrefix$key';

    // 檢查是否有數據
    if (!_box!.containsKey(dataKey)) return false;

    // 檢查快取時間
    final lastUpdateStr = _box!.get(lastUpdateKey) as String?;
    if (lastUpdateStr == null) return false;

    final lastUpdate = DateTimeUtils.parseIsoTimestamp(lastUpdateStr);
    final now = DateTime.now();

    final isValid = now.difference(lastUpdate) < cacheValidDuration;

    if (kDebugMode && isValid) {
      print('[STATISTICS_CACHE] ✅ 快取有效：$userId - ${timeRange.displayName}');
    }

    return isValid;
  }

  /// 獲取快取的統計數據
  StatisticsData? getCachedStatistics(String userId, TimeRange timeRange) {
    if (_box == null) return null;

    final key = _getCacheKey(userId, timeRange);
    final dataKey = '$_dataPrefix$key';

    try {
      final cachedData = _box!.get(dataKey);
      if (cachedData == null) return null;

      final json = Map<String, dynamic>.from(cachedData as Map);
      final data = StatisticsDataJson.fromJson(json);

      if (kDebugMode) {
        print('[STATISTICS_CACHE] 📦 從快取載入：${timeRange.displayName}');
      }

      return data;
    } catch (e) {
      if (kDebugMode) {
        print('[STATISTICS_CACHE] ⚠️ 解析快取失敗：$e');
      }
      // 解析失敗，刪除損壞的快取
      _box!.delete(dataKey);
      return null;
    }
  }

  /// 儲存統計數據到快取
  Future<void> cacheStatistics(
    String userId,
    TimeRange timeRange,
    StatisticsData data,
  ) async {
    if (_box == null) return;

    final key = _getCacheKey(userId, timeRange);
    final lastUpdateKey = '$_lastUpdatePrefix$key';
    final dataKey = '$_dataPrefix$key';

    try {
      final json = data.toJson();
      await _box!.put(dataKey, json);
      await _box!.put(lastUpdateKey, DateTimeUtils.formatToUtcIso(DateTime.now()));

      if (kDebugMode) {
        print('[STATISTICS_CACHE] 💾 已儲存：${timeRange.displayName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[STATISTICS_CACHE] ⚠️ 儲存失敗：$e');
      }
    }
  }

  /// 清除指定用戶的所有快取
  Future<void> clearUserCache(String userId) async {
    if (_box == null) return;

    final keysToDelete = <String>[];
    for (var key in _box!.keys) {
      if (key.toString().startsWith('$_dataPrefix$userId') ||
          key.toString().startsWith('$_lastUpdatePrefix$userId')) {
        keysToDelete.add(key.toString());
      }
    }

    for (var key in keysToDelete) {
      await _box!.delete(key);
    }

    if (kDebugMode) {
      print('[STATISTICS_CACHE] 🗑️ 已清除用戶快取：$userId');
    }
  }

  /// 清除所有快取
  Future<void> clearAllCache() async {
    if (_box == null) return;

    await _box!.clear();
    await _box!.put(_versionKey, currentCacheVersion);

    if (kDebugMode) {
      print('[STATISTICS_CACHE] 🗑️ 已清除所有快取');
    }
  }

  /// 獲取快取資訊
  Map<String, dynamic> getCacheInfo() {
    if (_box == null) {
      return {'initialized': false};
    }

    final dataKeys = _box!.keys
        .where((k) => k.toString().startsWith(_dataPrefix))
        .toList();

    return {
      'initialized': true,
      'version': _box!.get(_versionKey, defaultValue: 0),
      'cachedRanges': dataKeys.length,
      'keys': dataKeys.map((k) => k.toString().replaceFirst(_dataPrefix, '')).toList(),
    };
  }

  /// ⚡ 預熱：獲取所有快取的時間範圍（用於啟動時載入到記憶體）
  Future<Map<TimeRange, StatisticsData>> getAllCachedStatistics(String userId) async {
    await _ensureInitialized();
    if (_box == null) return {};

    final result = <TimeRange, StatisticsData>{};
    
    for (final timeRange in TimeRange.values) {
      if (await isCacheValidAsync(userId, timeRange)) {
        final data = getCachedStatistics(userId, timeRange);
        if (data != null) {
          result[timeRange] = data;
        }
      }
    }

    if (kDebugMode && result.isNotEmpty) {
      print('[STATISTICS_CACHE] 🔥 預熱完成：${result.length} 個時間範圍');
    }

    return result;
  }

  /// 關閉 Box
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
