import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/exercise_model.dart';

/// 動作本地快取服務
/// 
/// 使用 Hive 將所有預設動作持久化存儲到手機
/// 只在第一次安裝或版本更新時從 Supabase 下載
class ExerciseLocalCacheService {
  /// ⚡ Isolate 解析函數（減少數據傳輸）
  static Future<List<Exercise>> _parseInIsolate(List<Map<dynamic, dynamic>> maps) async {
    return compute(_parseExerciseListIsolate, maps);
  }
  
  /// Isolate 內執行的解析（純函數）
  static List<Exercise> _parseExerciseListIsolate(List<Map<dynamic, dynamic>> maps) {
    return maps
        .map((map) => Exercise.fromSupabase(Map<String, dynamic>.from(map)))
        .toList();
  }
  static const String _boxName = 'exercises_cache';
  static const String _versionKey = 'cache_version';
  static const String _exercisesKey = 'all_exercises';
  static const String _lastUpdateKey = 'last_update';
  
  /// 當前快取版本（更新此版本號會觸發重新下載）
  /// v2: 修復 body_part 欄位序列化問題 (2024-12-27)
  static const int currentCacheVersion = 2;
  
  Box? _box;
  
  /// 初始化 Hive Box
  Future<void> initialize() async {
    try {
      if (!kIsWeb) {
        await Hive.initFlutter();
      }
      _box = await Hive.openBox(_boxName);
      print('[EXERCISE_CACHE] 本地快取初始化完成');
    } catch (e) {
      print('[EXERCISE_CACHE] 初始化失敗: $e');
      rethrow;
    }
  }
  
  /// 檢查快取是否有效
  bool isCacheValid() {
    if (_box == null) return false;
    
    final cachedVersion = _box!.get(_versionKey, defaultValue: 0);
    final hasData = _box!.containsKey(_exercisesKey);
    
    final isValid = cachedVersion == currentCacheVersion && hasData;
    
    if (isValid) {
      final lastUpdate = _box!.get(_lastUpdateKey);
      print('[EXERCISE_CACHE] 快取有效（版本 $cachedVersion，上次更新: $lastUpdate）');
    } else {
      print('[EXERCISE_CACHE] 快取無效或已過期（版本 $cachedVersion）');
    }
    
    return isValid;
  }
  
  /// 保存所有動作到本地
  Future<void> saveExercises(List<Exercise> exercises) async {
    if (_box == null) throw Exception('Hive Box 未初始化');
    
    try {
      print('[EXERCISE_CACHE] 開始保存 ${exercises.length} 個動作到本地...');
      
      // 將 Exercise 物件轉換為 JSON Map（使用 Supabase 格式）
      final exercisesMaps = exercises.map((e) {
        return {
          'id': e.id,
          'name': e.name,
          'name_en': e.nameEn,
          'training_type': e.trainingType,
          'body_part': e.bodyPart,  // ✅ 使用 body_part（單數）
          'body_parts': e.bodyParts, // ✅ 保留舊的 body_parts 陣列
          'specific_muscle': e.specificMuscle,
          'equipment_category': e.equipmentCategory,
          'equipment_subcategory': e.equipmentSubcategory,
          'training_type_en': e.trainingTypeEn,
          'body_part_en': e.bodyPartEn,
          'specific_muscle_en': e.specificMuscleEn,
          'equipment_category_en': e.equipmentCategoryEn,
          'equipment_subcategory_en': e.equipmentSubcategoryEn,
          'level1': e.level1,
          'level2': e.level2,
          'level3': e.level3,
          'level4': e.level4,
          'level5': e.level5,
          'equipment': e.equipment,
          'joint_type': e.jointType,
          'action_name': e.actionName,
          'description': e.description,
        };
      }).toList();
      
      await _box!.put(_exercisesKey, exercisesMaps);
      await _box!.put(_versionKey, currentCacheVersion);
      await _box!.put(_lastUpdateKey, DateTime.now().toIso8601String());
      
      print('[EXERCISE_CACHE] ✅ 成功保存到本地（${_getDataSize(exercisesMaps)}）');
    } catch (e) {
      print('[EXERCISE_CACHE] 保存失敗: $e');
      rethrow;
    }
  }
  
  /// 從本地載入所有動作
  Future<List<Exercise>> loadExercises() async {
    if (_box == null) throw Exception('Hive Box 未初始化');
    
    try {
      print('[EXERCISE_CACHE] 從本地載入動作...');
      
      final exercisesMaps = _box!.get(_exercisesKey) as List?;
      if (exercisesMaps == null || exercisesMaps.isEmpty) {
        print('[EXERCISE_CACHE] 本地無資料');
        return [];
      }
      
      // ⚡ 使用 Isolate 但優化數據傳輸（只傳必要數據）
      final startTime = DateTime.now();
      final maps = exercisesMaps.cast<Map<dynamic, dynamic>>();
      
      // 使用 Isolate 解析（完全不阻塞主線程）
      final exercises = await _parseInIsolate(maps);
      
      final duration = DateTime.now().difference(startTime);
      print('[EXERCISE_CACHE] ✅ 成功從本地載入 ${exercises.length} 個動作（Isolate 解析耗時 ${duration.inMilliseconds}ms）');
      return exercises;
    } catch (e) {
      print('[EXERCISE_CACHE] 載入失敗: $e');
      return [];
    }
  }
  
  /// 清除快取（強制重新下載）
  Future<void> clearCache() async {
    if (_box == null) return;
    
    await _box!.clear();
    print('[EXERCISE_CACHE] 快取已清除');
  }
  
  /// 獲取快取資訊
  Map<String, dynamic> getCacheInfo() {
    if (_box == null) {
      return {'initialized': false};
    }
    
    final exercisesMaps = _box!.get(_exercisesKey) as List?;
    final exerciseCount = exercisesMaps?.length ?? 0;
    final version = _box!.get(_versionKey, defaultValue: 0);
    final lastUpdate = _box!.get(_lastUpdateKey);
    
    return {
      'initialized': true,
      'isValid': isCacheValid(),
      'exerciseCount': exerciseCount,
      'version': version,
      'lastUpdate': lastUpdate,
      'size': exercisesMaps != null ? _getDataSize(exercisesMaps) : '0 KB',
    };
  }
  
  /// 估算資料大小
  String _getDataSize(dynamic data) {
    try {
      final jsonString = data.toString();
      final bytes = jsonString.length;
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'unknown';
    }
  }
  
  /// 關閉 Box
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}

