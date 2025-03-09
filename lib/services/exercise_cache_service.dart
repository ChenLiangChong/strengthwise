import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_model.dart';
import 'error_handling_service.dart';
import 'service_locator.dart' show Environment;

/// 運動數據緩存服務，提供多層緩存策略
/// 
/// 結合 Firebase Firestore 緩存和 SharedPreferences 本地存儲，
/// 實現高效的數據緩存和預加載
class ExerciseCacheService {
  // Firebase Firestore 實例
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 緩存前綴和過期時間
  static const String _prefixCache = 'firestore_cache_';
  static int _cacheExpiration = 7 * 24 * 60 * 60 * 1000; // 7天緩存過期時間（毫秒）
  
  // 服務狀態
  static bool _isInitialized = false;
  static Environment _environment = Environment.development;
  
  // 服務配置
  static bool _useFirestoreCache = true;
  static bool _useSharedPrefsCache = true;
  static int _maxCacheEntries = 100;
  
  // 緩存統計
  static int _cacheHits = 0;
  static int _cacheMisses = 0;
  
  // 緩存清理計時器
  static Timer? _cacheClearTimer;
  
  // 錯誤處理服務
  static ErrorHandlingService? _errorService;
  
  /// 初始化緩存服務
  /// 
  /// 配置 Firebase 和 SharedPreferences 緩存，設置環境參數
  static Future<void> init({
    Environment environment = Environment.development,
    ErrorHandlingService? errorService,
  }) async {
    if (_isInitialized) return;
    
    try {
      _errorService = errorService;
      
      // 配置 Firestore 緩存
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED
      );
      
      // 配置環境
      configureForEnvironment(environment);
      
      // 設置緩存清理計時器（每12小時）
      _setupCacheCleanupTimer();
      
      _isInitialized = true;
      _logDebug('運動緩存服務初始化完成');
      
      // 在應用啟動時進行一次緩存清理
      await _removeExpiredCache();
    } catch (e) {
      _logError('初始化緩存服務失敗: $e');
      rethrow;
    }
  }
  
  /// 釋放資源
  static Future<void> dispose() async {
    try {
      // 取消緩存清理計時器
      _cacheClearTimer?.cancel();
      _cacheClearTimer = null;
      
      // 重置緩存統計
      _cacheHits = 0;
      _cacheMisses = 0;
      
      _isInitialized = false;
      _logDebug('運動緩存服務資源已釋放');
    } catch (e) {
      _logError('釋放緩存服務資源時發生錯誤: $e');
    }
  }
  
  /// 根據環境配置服務
  static void configureForEnvironment(Environment environment) {
    _environment = environment;
    
    switch (environment) {
      case Environment.development:
        // 開發環境設置
        _useFirestoreCache = true;
        _useSharedPrefsCache = true;
        _cacheExpiration = 14 * 24 * 60 * 60 * 1000; // 14天（開發環境更長的緩存）
        _maxCacheEntries = 200;
        _logDebug('運動緩存服務配置為開發環境');
        break;
      case Environment.testing:
        // 測試環境設置
        _useFirestoreCache = true;
        _useSharedPrefsCache = false; // 避免測試數據污染正式緩存
        _cacheExpiration = 1 * 24 * 60 * 60 * 1000; // 1天
        _maxCacheEntries = 50;
        _logDebug('運動緩存服務配置為測試環境');
        break;
      case Environment.production:
        // 生產環境設置
        _useFirestoreCache = true;
        _useSharedPrefsCache = true;
        _cacheExpiration = 7 * 24 * 60 * 60 * 1000; // 7天
        _maxCacheEntries = 100;
        _logDebug('運動緩存服務配置為生產環境');
        break;
    }
  }
  
  /// 設置緩存清理計時器
  static void _setupCacheCleanupTimer() {
    _cacheClearTimer?.cancel();
    // 每12小時清理一次過期緩存
    _cacheClearTimer = Timer.periodic(const Duration(hours: 12), (_) async {
      await _removeExpiredCache();
    });
  }
  
  /// 移除已過期的緩存
  static Future<void> _removeExpiredCache() async {
    try {
      _logDebug('開始清理過期緩存');
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_prefixCache));
      final now = DateTime.now().millisecondsSinceEpoch;
      int removedCount = 0;
      
      for (final key in keys) {
        final timeKey = '${key}_time';
        final cacheTime = prefs.getInt(timeKey) ?? 0;
        
        if (now - cacheTime > _cacheExpiration) {
          await prefs.remove(key);
          await prefs.remove(timeKey);
          removedCount++;
        }
      }
      
      _logDebug('過期緩存清理完成，已移除 $removedCount 項');
    } catch (e) {
      _logError('清理過期緩存失敗: $e');
    }
  }
  
  /// 從緩存中獲取分類數據
  static Future<List<String>> getCategories(String key) async {
    _ensureInitialized();
    
    try {
      // 1. 首先嘗試從 SharedPreferences 獲取（如果啟用）
      if (_useSharedPrefsCache) {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = '${_prefixCache}cat_$key';
        final cachedData = prefs.getString(cacheKey);
        
        if (cachedData != null) {
          final cacheTime = prefs.getInt('${cacheKey}_time') ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch;
          
          if (now - cacheTime < _cacheExpiration) {
            _logDebug('從 SharedPreferences 獲取分類: $key (緩存命中)');
            _cacheHits++;
            final data = jsonDecode(cachedData);
            return List<String>.from(data['items']);
          }
        }
      }
      
      // 2. 如果 SharedPreferences 緩存不可用或已過期，嘗試從 Firestore 緩存獲取
      if (_useFirestoreCache) {
        _logDebug('從 Firestore 緩存獲取分類: $key');
        final collection = key.startsWith('exerciseTypes') || key.startsWith('bodyParts') 
            ? key.split('_')[0] 
            : 'exercise';
        
        try {
          final snapshot = await _firestore.collection(collection)
              .get(const GetOptions(source: Source.cache));
              
          if (snapshot.docs.isNotEmpty) {
            List<String> results = [];
            
            // 根據查詢類型處理結果
            if (collection == 'exerciseTypes' || collection == 'bodyParts') {
              results = snapshot.docs.map((doc) => doc['name'] as String).toList();
            } else {
              // 從練習數據中提取類別
              if (key.contains('level')) {
                final levelNum = int.tryParse(key.split('level').last.split('_').first) ?? 1;
                final fieldName = 'level$levelNum';
                
                Set<String> uniqueValues = {};
                for (var doc in snapshot.docs) {
                  final value = doc[fieldName] as String? ?? '';
                  if (value.isNotEmpty) uniqueValues.add(value);
                }
                results = uniqueValues.toList()..sort();
              }
            }
            
            // 緩存成功，保存到 SharedPreferences（如果啟用）
            if (_useSharedPrefsCache && results.isNotEmpty) {
              await _cacheCategoriesToPrefs(key, results);
            }
            
            _logDebug('從 Firestore 緩存獲取了 ${results.length} 個分類');
            return results;
          }
        } catch (e) {
          _logDebug('Firestore 緩存讀取失敗，嘗試從服務器獲取: $e');
        }
      }
      
      // 3. 如果緩存都沒有，從服務器讀取
      _cacheMisses++;
      _logDebug('從服務器獲取分類: $key (緩存未命中)');
      
      final collection = key.startsWith('exerciseTypes') || key.startsWith('bodyParts') 
          ? key.split('_')[0] 
          : 'exercise';
          
      final serverSnapshot = await _firestore.collection(collection).get();
      
      List<String> results = [];
      if (collection == 'exerciseTypes' || collection == 'bodyParts') {
        results = serverSnapshot.docs.map((doc) => doc['name'] as String).toList();
      } else if (key.contains('level')) {
        final levelNum = int.tryParse(key.split('level').last.split('_').first) ?? 1;
        final fieldName = 'level$levelNum';
        
        Set<String> uniqueValues = {};
        for (var doc in serverSnapshot.docs) {
          final value = doc[fieldName] as String? ?? '';
          if (value.isNotEmpty) uniqueValues.add(value);
        }
        results = uniqueValues.toList()..sort();
      }
      
      // 保存到 SharedPreferences 緩存（如果啟用）
      if (_useSharedPrefsCache && results.isNotEmpty) {
        await _cacheCategoriesToPrefs(key, results);
      }
      
      _logDebug('從服務器獲取了 ${results.length} 個分類');
      return results;
    } catch (e) {
      _logError('獲取分類數據失敗: $e');
      return [];
    }
  }
  
  /// 將分類數據保存到 SharedPreferences
  static Future<void> _cacheCategoriesToPrefs(String key, List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_prefixCache}cat_$key';
      
      await prefs.setString(cacheKey, jsonEncode({'items': categories}));
      await prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
      
      _logDebug('分類保存到 SharedPreferences 緩存: $key (${categories.length} 個項目)');
    } catch (e) {
      _logError('保存分類到 SharedPreferences 失敗: $e');
    }
  }
  
  /// 從緩存獲取運動數據
  static Future<List<Exercise>> getExercises(String key) async {
    _ensureInitialized();
    
    try {
      // 1. 首先嘗試從 SharedPreferences 獲取（如果啟用）
      if (_useSharedPrefsCache) {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = '${_prefixCache}ex_$key';
        final cachedData = prefs.getString(cacheKey);
        
        if (cachedData != null) {
          final cacheTime = prefs.getInt('${cacheKey}_time') ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch;
          
          if (now - cacheTime < _cacheExpiration) {
            _logDebug('從 SharedPreferences 獲取運動數據: $key (緩存命中)');
            _cacheHits++;
            final List<dynamic> data = jsonDecode(cachedData);
            return data.map((json) => Exercise.fromJson(json)).toList();
          }
        }
      }
      
      // 2. 嘗試從 Firestore 緩存獲取（如果啟用）
      if (_useFirestoreCache) {
        _logDebug('從 Firestore 緩存獲取運動數據: $key');
        Query query = _firestore.collection('exercise');
        
        // 創建基於鍵的查詢
        final filterParams = _parseExerciseKey(key);
        query = _applyFiltersToQuery(query, filterParams);
        
        try {
          final snapshot = await query.get(const GetOptions(source: Source.cache));
          
          if (snapshot.docs.isNotEmpty) {
            List<Exercise> exercises = snapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList();
            
            // 保存到 SharedPreferences（如果啟用）
            if (_useSharedPrefsCache && exercises.isNotEmpty) {
              await _cacheExercisesToPrefs(key, exercises);
            }
            
            _logDebug('從 Firestore 緩存獲取了 ${exercises.length} 個運動數據');
            return exercises;
          }
        } catch (e) {
          _logDebug('Firestore 緩存讀取失敗，嘗試從服務器獲取: $e');
        }
      }
      
      // 3. 如果緩存都沒有，從服務器讀取
      _cacheMisses++;
      _logDebug('從服務器獲取運動數據: $key (緩存未命中)');
      
      Query query = _firestore.collection('exercise');
      final filterParams = _parseExerciseKey(key);
      query = _applyFiltersToQuery(query, filterParams);
      
      final serverSnapshot = await query.get();
      final exercises = serverSnapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList();
      
      // 保存到 SharedPreferences（如果啟用）
      if (_useSharedPrefsCache && exercises.isNotEmpty) {
        await _cacheExercisesToPrefs(key, exercises);
      }
      
      _logDebug('從服務器獲取了 ${exercises.length} 個運動數據');
      return exercises;
    } catch (e) {
      _logError('獲取運動數據失敗: $e');
      return [];
    }
  }
  
  /// 解析運動數據緩存鍵
  static Map<String, String> _parseExerciseKey(String key) {
    final filterParams = <String, String>{};
    final parts = key.split('_');
    
    if (parts.isNotEmpty) {
      if (parts.length > 0 && parts[0].isNotEmpty) {
        filterParams['type'] = parts[0];
      }
      
      if (parts.length > 1 && parts[1].isNotEmpty) {
        filterParams['bodyPart'] = parts[1];
      }
      
      // 處理層級過濾器
      final levelPrefixes = ['level1', 'level2', 'level3', 'level4', 'level5'];
      for (int i = 0; i < levelPrefixes.length && i + 2 < parts.length; i++) {
        if (parts[i + 2].isNotEmpty) {
          filterParams[levelPrefixes[i]] = parts[i + 2];
        }
      }
    }
    
    return filterParams;
  }
  
  /// 將過濾器應用到查詢
  static Query _applyFiltersToQuery(Query query, Map<String, String> filterParams) {
    Query updatedQuery = query;
    
    if (filterParams.containsKey('type') && filterParams['type']!.isNotEmpty) {
      updatedQuery = updatedQuery.where('type', isEqualTo: filterParams['type']);
    }
    
    if (filterParams.containsKey('bodyPart') && filterParams['bodyPart']!.isNotEmpty) {
      updatedQuery = updatedQuery.where('bodyParts', arrayContains: filterParams['bodyPart']);
    }
    
    // 添加層級過濾器
    for (final levelField in ['level1', 'level2', 'level3', 'level4', 'level5']) {
      if (filterParams.containsKey(levelField) && filterParams[levelField]!.isNotEmpty) {
        updatedQuery = updatedQuery.where(levelField, isEqualTo: filterParams[levelField]);
      }
    }
    
    // 限制結果數量，避免獲取過多
    return updatedQuery.limit(50);
  }
  
  /// 將運動數據保存到 SharedPreferences
  static Future<void> _cacheExercisesToPrefs(String key, List<Exercise> exercises) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_prefixCache}ex_$key';
      
      final jsonList = exercises.map((e) => e.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
      await prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
      
      _logDebug('運動數據保存到 SharedPreferences 緩存: $key (${exercises.length} 個項目)');
      
      // 檢查緩存條目數是否超出限制
      await _manageCacheSize(prefs);
    } catch (e) {
      _logError('保存運動數據到 SharedPreferences 失敗: $e');
    }
  }
  
  /// 管理緩存大小，移除最舊的條目
  static Future<void> _manageCacheSize(SharedPreferences prefs) async {
    try {
      final allKeys = prefs.getKeys()
          .where((key) => key.startsWith(_prefixCache) && !key.endsWith('_time'))
          .toList();
      
      if (allKeys.length > _maxCacheEntries) {
        _logDebug('緩存條目數 (${allKeys.length}) 超出限制 ($_maxCacheEntries)，移除最舊條目');
        
        // 獲取所有緩存條目及其時間戳
        final cacheEntries = <String, int>{};
        for (final key in allKeys) {
          final timeKey = '${key}_time';
          final time = prefs.getInt(timeKey) ?? 0;
          cacheEntries[key] = time;
        }
        
        // 按時間排序並移除最舊的條目
        final sortedEntries = cacheEntries.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        
        final entriesToRemove = sortedEntries.take(sortedEntries.length - _maxCacheEntries);
        for (final entry in entriesToRemove) {
          await prefs.remove(entry.key);
          await prefs.remove('${entry.key}_time');
        }
        
        _logDebug('已移除 ${entriesToRemove.length} 個最舊的緩存條目');
      }
    } catch (e) {
      _logError('管理緩存大小失敗: $e');
    }
  }
  
  /// 緩存分類數據 - 主動緩存
  static Future<void> cacheCategories(String key, List<String> categories) async {
    _ensureInitialized();
    
    if (categories.isEmpty) return;
    
    try {
      if (_useSharedPrefsCache) {
        await _cacheCategoriesToPrefs(key, categories);
      }
    } catch (e) {
      _logError('主動緩存分類失敗: $e');
    }
  }
  
  /// 緩存運動數據 - 主動緩存
  static Future<void> cacheExercises(String key, List<Exercise> exercises) async {
    _ensureInitialized();
    
    if (exercises.isEmpty) return;
    
    try {
      if (_useSharedPrefsCache) {
        await _cacheExercisesToPrefs(key, exercises);
      }
    } catch (e) {
      _logError('主動緩存運動失敗: $e');
    }
  }
  
  /// 清空特定缓存
  static Future<void> clearCacheForKey(String key) async {
    _ensureInitialized();
    
    try {
      if (_useSharedPrefsCache) {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = '$_prefixCache$key';
        
        bool removed = false;
        if (prefs.containsKey(cacheKey)) {
          await prefs.remove(cacheKey);
          removed = true;
        }
        
        if (prefs.containsKey('${cacheKey}_time')) {
          await prefs.remove('${cacheKey}_time');
          removed = true;
        }
        
        if (removed) {
          _logDebug('已清除緩存: $key');
        }
      }
    } catch (e) {
      _logError('清除特定緩存失敗: $e');
    }
  }
  
  /// 清空所有层级相关的缓存
  static Future<void> clearAllLevelCaches() async {
    _ensureInitialized();
    
    try {
      if (_useSharedPrefsCache) {
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();
        int count = 0;
        
        for (final key in allKeys) {
          if ((key.startsWith('${_prefixCache}cat_') || key.startsWith('${_prefixCache}ex_')) &&
              (key.contains('level') || key.contains('_time'))) {
            await prefs.remove(key);
            count++;
          }
        }
        
        _logDebug('已清除所有層級相關緩存: $count 個項目');
      }
    } catch (e) {
      _logError('清除所有層級緩存失敗: $e');
    }
  }
  
  /// 清除所有緩存
  static Future<void> clearCache() async {
    _ensureInitialized();
    
    try {
      // 清除 SharedPreferences 緩存
      if (_useSharedPrefsCache) {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().where((key) => key.startsWith(_prefixCache));
        int count = 0;
        
        for (var key in keys) {
          await prefs.remove(key);
          count++;
        }
        
        _logDebug('已清除 SharedPreferences 緩存: $count 個項目');
      }
      
      // 清除 Firestore 緩存
      if (_useFirestoreCache) {
        await _firestore.clearPersistence();
        _logDebug('已清除 Firestore 持久化緩存');
      }
      
      // 重置緩存統計
      _cacheHits = 0;
      _cacheMisses = 0;
    } catch (e) {
      _logError('清除緩存失敗: $e');
    }
  }
  
  /// 獲取緩存統計信息
  static Map<String, dynamic> getCacheStats() {
    return {
      'hits': _cacheHits,
      'misses': _cacheMisses,
      'hitRate': _cacheHits + _cacheMisses > 0 
          ? _cacheHits / (_cacheHits + _cacheMisses) 
          : 0.0,
    };
  }
  
  /// 確保服務已初始化
  static void _ensureInitialized() {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('[EXERCISE CACHE] 警告: 緩存服務在初始化前被調用');
      }
      
      // 自動初始化
      init();
    }
  }
  
  /// 記錄調試信息
  static void _logDebug(String message) {
    if (kDebugMode) {
      print('[EXERCISE CACHE] $message');
    }
  }
  
  /// 記錄錯誤信息
  static void _logError(String message) {
    if (kDebugMode) {
      print('[EXERCISE CACHE ERROR] $message');
    }
    
    // 使用錯誤處理服務（如果可用）
    _errorService?.logError(message);
  }
  
  // 兼容舊API - 返回空列表
  @deprecated
  static List<String> getCachedCategories(String key) => [];
  
  @deprecated
  static List<Exercise> getCachedExercises(String key) => [];
} 