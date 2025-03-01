import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseCacheService {
  // Firebase Firestore 實例
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _prefixCache = 'firestore_cache_';
  static const int _cacheExpiration = 7 * 24 * 60 * 60 * 1000; // 7天緩存過期時間（毫秒）
  
  // 初始化 - 配置 Firebase 緩存
  static void init() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED
    );
  }

  // 混合緩存策略 - 同時使用 Firestore 緩存和 SharedPreferences
  // 從緩存中獲取分類數據
  static Future<List<String>> getCategories(String key) async {
    try {
      // 1. 先嘗試從 SharedPreferences 獲取（超快）
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_prefixCache}cat_$key';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final cacheTime = prefs.getInt('${cacheKey}_time') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // 檢查緩存是否過期
        if (now - cacheTime < _cacheExpiration) {
          final data = jsonDecode(cachedData);
          return List<String>.from(data['items']);
        }
      }
      
      // 2. 如果 SharedPreferences 沒有或已過期，嘗試從 Firestore 緩存獲取
      final collection = key.startsWith('exerciseTypes') || key.startsWith('bodyParts') 
          ? key.split('_')[0] 
          : 'exercise';
      
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
            final levelNum = int.tryParse(key.split('level').last) ?? 1;
            final fieldName = 'level$levelNum';
            
            Set<String> uniqueValues = {};
            for (var doc in snapshot.docs) {
              final value = doc[fieldName] as String? ?? '';
              if (value.isNotEmpty) uniqueValues.add(value);
            }
            results = uniqueValues.toList()..sort();
          }
        }
        
        // 保存到 SharedPreferences
        await prefs.setString(cacheKey, jsonEncode({'items': results}));
        await prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
        
        return results;
      }
      
      // 3. 如果緩存都沒有，從服務器讀取
      final serverSnapshot = await _firestore.collection(collection).get();
      final results = serverSnapshot.docs.map((doc) => doc['name'] as String).toList();
      
      // 保存到 SharedPreferences
      await prefs.setString(cacheKey, jsonEncode({'items': results}));
      await prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
      
      return results;
    } catch (e) {
      print('緩存獲取錯誤: $e');
      return [];
    }
  }
  
  // 從緩存獲取運動數據
  static Future<List<Exercise>> getExercises(String key) async {
    try {
      // 1. 先嘗試從 SharedPreferences 獲取
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_prefixCache}ex_$key';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final cacheTime = prefs.getInt('${cacheKey}_time') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // 檢查緩存是否過期
        if (now - cacheTime < _cacheExpiration) {
          final List<dynamic> data = jsonDecode(cachedData);
          return data.map((json) => Exercise.fromJson(json)).toList();
        }
      }
      
      // 2. 嘗試從 Firestore 緩存獲取
      Query query = _firestore.collection('exercise');
      
      // 創建基於鍵的查詢
      final parts = key.split('_');
      if (parts.length >= 2) {
        final type = parts[0];
        if (type.isNotEmpty) {
          query = query.where('type', isEqualTo: type);
        }
        
        final bodyPart = parts.length > 1 ? parts[1] : '';
        if (bodyPart.isNotEmpty) {
          query = query.where('bodyParts', arrayContains: bodyPart);
        }
        
        // 添加層次過濾器
        if (parts.length > 2 && parts[2].isNotEmpty) {
          query = query.where('level1', isEqualTo: parts[2]);
          
          if (parts.length > 3 && parts[3].isNotEmpty) {
            query = query.where('level2', isEqualTo: parts[3]);
            
            if (parts.length > 4 && parts[4].isNotEmpty) {
              query = query.where('level3', isEqualTo: parts[4]);
              
              if (parts.length > 5 && parts[5].isNotEmpty) {
                query = query.where('level4', isEqualTo: parts[5]);
                
                if (parts.length > 6 && parts[6].isNotEmpty) {
                  query = query.where('level5', isEqualTo: parts[6]);
                }
              }
            }
          }
        }
      }
      
      query = query.limit(50);
      
      final snapshot = await query.get(const GetOptions(source: Source.cache));
      
      if (snapshot.docs.isNotEmpty) {
        List<Exercise> exercises = snapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList();
        
        // 序列化並保存到 SharedPreferences
        final jsonList = exercises.map((e) => e.toJson()).toList();
        await prefs.setString(cacheKey, jsonEncode(jsonList));
        await prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
        
        return exercises;
      }
      
      // 3. 如果緩存都沒有，從服務器讀取
      final serverSnapshot = await query.get();
      final exercises = serverSnapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList();
      
      // 序列化並保存到 SharedPreferences
      if (exercises.isNotEmpty) {
        final jsonList = exercises.map((e) => e.toJson()).toList();
        await prefs.setString(cacheKey, jsonEncode(jsonList));
        await prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
      }
      
      return exercises;
    } catch (e) {
      print('緩存獲取錯誤: $e');
      return [];
    }
  }
  
  // 緩存分類數據 - 主動緩存
  static Future<void> cacheCategories(String key, List<String> categories) async {
    if (categories.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_prefixCache}cat_$key';
      
      await prefs.setString(cacheKey, jsonEncode({'items': categories}));
      await prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('緩存分類失敗: $e');
    }
  }
  
  // 緩存運動數據 - 主動緩存
  static Future<void> cacheExercises(String key, List<Exercise> exercises) async {
    if (exercises.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_prefixCache}ex_$key';
      
      final jsonList = exercises.map((e) => e.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
      await prefs.setInt('${cacheKey}_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('緩存運動失敗: $e');
    }
  }
  
  // 清除所有緩存
  static Future<void> clearCache() async {
    try {
      // 清除 SharedPreferences 緩存
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_prefixCache));
      for (var key in keys) {
        await prefs.remove(key);
      }
      
      // 清除 Firestore 緩存
      await _firestore.clearPersistence();
    } catch (e) {
      print('清除緩存失敗: $e');
    }
  }
  
  // 清空特定缓存
  static Future<void> clearCacheForKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_prefixCache}$key';
      await prefs.remove(cacheKey);
      await prefs.remove('${cacheKey}_time');
      print('已清除緩存: $key');
    } catch (e) {
      print('清除缓存失败: $e');
    }
  }
  
  // 清空所有层级相关的缓存
  static Future<void> clearAllLevelCaches() async {
    try {
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
      print('已清除所有層級相關緩存: $count 個項目');
    } catch (e) {
      print('清除所有層級緩存失敗: $e');
    }
  }
  
  // 清空所有缓存
  static Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      int count = 0;
      
      for (final key in allKeys) {
        if (key.startsWith(_prefixCache)) {
          await prefs.remove(key);
          count++;
        }
      }
      print('已清除所有緩存: $count 個項目');
      
      // 也清除 Firestore 缓存
      try {
        await _firestore.clearPersistence();
        print('已清除 Firestore 持久化緩存');
      } catch (e) {
        print('清除 Firestore 持久化緩存失敗: $e');
      }
    } catch (e) {
      print('清除所有緩存失敗: $e');
    }
  }
  
  // 兼容舊API
  static List<String> getCachedCategories(String key) => [];
  static List<Exercise> getCachedExercises(String key) => [];
} 