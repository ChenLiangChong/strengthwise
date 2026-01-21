import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/workout_record_model.dart';
import '../../utils/datetime_utils.dart';

/// 訓練計劃本地快取服務
///
/// 使用 Hive 將進行中的訓練計劃持久化存儲
/// 支持離線訓練和方案 C 啟動時驗證
class WorkoutPlanLocalCacheService {
  static const String _boxName = 'workout_plans_cache';
  static const String _versionKey = 'cache_version';
  static const String _plansPrefix = 'plans_';
  static const String _timestampsPrefix = 'timestamps_';

  /// 快取版本
  static const int currentCacheVersion = 1;

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
          _box = await Hive.openBox(_boxName);
          _validateVersion();
          _isInitialized = true;
          _isInitializing = false;
          if (kDebugMode) {
            debugPrint('[WORKOUT_CACHE] 本地快取初始化完成');
          }
          return;
        } catch (e) {
          retryCount++;
          if (kDebugMode) {
            debugPrint('[WORKOUT_CACHE] 初始化失敗 (第 $retryCount/$maxRetries 次): $e');
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
                debugPrint('[WORKOUT_CACHE] 清理失敗: $cleanupError');
              }
            }
          }

          if (retryCount >= maxRetries) {
            if (kDebugMode) {
              debugPrint('[WORKOUT_CACHE] ⚠️ 初始化失敗，將使用無快取模式');
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
        debugPrint('[WORKOUT_CACHE] 初始化過程發生錯誤: $e');
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
        debugPrint('[WORKOUT_CACHE] 快取版本不符，清除舊快取');
      }
      _box!.clear();
      _box!.put(_versionKey, currentCacheVersion);
    }
  }

  /// 儲存用戶的進行中訓練計劃
  Future<void> cacheActivePlans(
    String userId,
    List<WorkoutRecord> plans,
  ) async {
    await _ensureInitialized();
    if (_box == null) return;

    final plansKey = '$_plansPrefix$userId';
    final timestampsKey = '$_timestampsPrefix$userId';

    try {
      // 只快取非 Session Mode 的計劃（appointment_id == null）
      final plansToCache = plans.where((p) => p.appointmentId == null).toList();

      // 轉換為 JSON
      final plansJson = plansToCache.map((p) => p.toJson()).toList();

      // 記錄每個計劃的 updated_at（用於驗證）
      final timestamps = <String, String>{};
      for (var plan in plansToCache) {
        // 使用 createdAt 作為基準時間戳
        timestamps[plan.id] = DateTimeUtils.formatToUtcIso(plan.createdAt);
      }

      await _box!.put(plansKey, plansJson);
      await _box!.put(timestampsKey, timestamps);

      if (kDebugMode) {
        debugPrint('[WORKOUT_CACHE] 💾 已快取 ${plansToCache.length} 個訓練計劃');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WORKOUT_CACHE] ⚠️ 儲存失敗：$e');
      }
    }
  }

  /// 獲取快取的訓練計劃
  Future<List<WorkoutRecord>?> getCachedPlans(String userId) async {
    await _ensureInitialized();
    if (_box == null) return null;

    final plansKey = '$_plansPrefix$userId';

    try {
      final cachedData = _box!.get(plansKey);
      if (cachedData == null) return null;

      final plansList = (cachedData as List).cast<Map>();
      // ⭐ v3.7: 使用遞迴轉換，解決 Hive 嵌套 Map 類型問題
      final plans = plansList
          .map((json) => WorkoutRecord.fromJson(_convertToMapStringDynamic(json)))
          .toList();

      if (kDebugMode) {
        debugPrint('[WORKOUT_CACHE] 📦 從快取載入 ${plans.length} 個訓練計劃');
      }

      return plans;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WORKOUT_CACHE] ⚠️ 解析快取失敗：$e');
      }
      return null;
    }
  }

  /// 獲取快取的時間戳（用於驗證）
  Future<Map<String, DateTime>?> getCachedTimestamps(String userId) async {
    await _ensureInitialized();
    if (_box == null) return null;

    final timestampsKey = '$_timestampsPrefix$userId';

    try {
      final cachedData = _box!.get(timestampsKey);
      if (cachedData == null) return null;

      final timestamps = <String, DateTime>{};
      // ⭐ v3.7: 使用遞迴轉換，解決 Hive 類型問題
      final map = _convertToMapStringDynamic(cachedData);
      for (var entry in map.entries) {
        timestamps[entry.key] = DateTimeUtils.parseIsoTimestamp(entry.value as String);
      }

      return timestamps;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WORKOUT_CACHE] ⚠️ 解析時間戳失敗：$e');
      }
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

  /// 更新單個計劃的快取
  Future<void> updateCachedPlan(String userId, WorkoutRecord plan) async {
    await _ensureInitialized();
    if (_box == null) return;

    // 不快取 Session Mode 計劃
    if (plan.appointmentId != null) return;

    try {
      final existingPlans = await getCachedPlans(userId) ?? [];

      // 更新或添加
      final index = existingPlans.indexWhere((p) => p.id == plan.id);
      if (index >= 0) {
        existingPlans[index] = plan;
      } else {
        existingPlans.add(plan);
      }

      await cacheActivePlans(userId, existingPlans);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WORKOUT_CACHE] ⚠️ 更新單個計劃失敗：$e');
      }
    }
  }

  /// 從快取移除計劃
  Future<void> removeCachedPlan(String userId, String planId) async {
    await _ensureInitialized();
    if (_box == null) return;

    try {
      final existingPlans = await getCachedPlans(userId) ?? [];
      existingPlans.removeWhere((p) => p.id == planId);
      await cacheActivePlans(userId, existingPlans);

      if (kDebugMode) {
        debugPrint('[WORKOUT_CACHE] 🗑️ 已移除計劃：$planId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WORKOUT_CACHE] ⚠️ 移除計劃失敗：$e');
      }
    }
  }

  /// 清除用戶的所有快取
  Future<void> clearUserCache(String userId) async {
    await _ensureInitialized();
    if (_box == null) return;

    final plansKey = '$_plansPrefix$userId';
    final timestampsKey = '$_timestampsPrefix$userId';

    await _box!.delete(plansKey);
    await _box!.delete(timestampsKey);

    if (kDebugMode) {
      debugPrint('[WORKOUT_CACHE] 🗑️ 已清除用戶快取：$userId');
    }
  }

  /// 檢查是否有快取
  Future<bool> hasCachedPlans(String userId) async {
    await _ensureInitialized();
    if (_box == null) return false;

    final plansKey = '$_plansPrefix$userId';
    return _box!.containsKey(plansKey);
  }

  /// 關閉 Box
  Future<void> close() async {
    await _box?.close();
    _box = null;
    _isInitialized = false;
  }
}
