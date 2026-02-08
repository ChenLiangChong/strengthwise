import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:strengthwise/utils/datetime_utils.dart';
import '../../models/exercise_model.dart';
import '../../models/tracking_mode.dart'; // v3 新增

/// 動作本地快取服務
///
/// 使用 Hive 將所有預設動作持久化存儲到手機
/// 只在第一次安裝或版本更新時從 Supabase 下載
class ExerciseLocalCacheService {
  /// ⚡ Isolate 解析函數（減少數據傳輸）
  static Future<List<Exercise>> _parseInIsolate(
      List<Map<dynamic, dynamic>> maps) async {
    return compute(_parseExerciseListIsolate, maps);
  }

  /// Isolate 內執行的解析（純函數）
  /// ⭐ v3.7: 使用遞迴轉換，解決 Hive 嵌套 Map 類型問題
  static List<Exercise> _parseExerciseListIsolate(
      List<Map<dynamic, dynamic>> maps) {
    return maps
        .map((map) => Exercise.fromSupabase(_convertMapRecursive(map)))
        .toList();
  }

  /// ⭐ v3.7: 靜態遞迴轉換函數（供 Isolate 使用）
  static Map<String, dynamic> _convertMapRecursive(dynamic data) {
    if (data is Map) {
      return data.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _convertMapRecursive(value));
        } else if (value is List) {
          return MapEntry(key.toString(), _convertListRecursive(value));
        } else {
          return MapEntry(key.toString(), value);
        }
      });
    }
    return {};
  }

  /// ⭐ v3.7: 靜態遞迴轉換 List（供 Isolate 使用）
  static List<dynamic> _convertListRecursive(List<dynamic> list) {
    return list.map((item) {
      if (item is Map) {
        return _convertMapRecursive(item);
      } else if (item is List) {
        return _convertListRecursive(item);
      } else {
        return item;
      }
    }).toList();
  }

  static const String _boxName = 'exercises_cache';
  static const String _searchIndexBoxName = 'exercises_search_index';
  static const String _versionKey = 'cache_version';
  static const String _exercisesKey = 'all_exercises';
  static const String _lastUpdateKey = 'last_update';

  // 搜尋索引 Keys（v5.0 新增）
  static const String _trigramIndexKey = 'trigram_index';
  static const String _pinyinFullIndexKey = 'pinyin_full_index';
  static const String _pinyinInitialsIndexKey = 'pinyin_initials_index';
  static const String _indexVersionKey = 'index_version';

  /// 當前快取版本（更新此版本號會觸發重新下載）
  /// v2: 修復 body_part 欄位序列化問題 (2024-12-27)
  /// v3: 新增 tracking_mode 欄位支援 (2026-01-12)
  /// v4: 強制重新下載確保 tracking_mode 正確 (2026-01-17)
  /// v5: 新增 v2 分類欄位 + 搜尋索引支援 (2026-02-07)
  static const int currentCacheVersion = 5;

  Box? _box;
  Box? _searchIndexBox;

  /// 初始化 Hive Box
  Future<void> initialize() async {
    try {
      // ⭐ v3.7: Hive.initFlutter() 已在 main.dart 統一初始化，這裡不再重複調用

      // ⚡ 嘗試打開 Box，如果失敗則重試
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        try {
          _box = await Hive.openBox(_boxName);
          // v5.0: 同時打開搜尋索引 Box
          _searchIndexBox = await Hive.openBox(_searchIndexBoxName);
          debugPrint('[EXERCISE_CACHE] 本地快取初始化完成（含搜尋索引）');
          return;
        } catch (e) {
          retryCount++;
          debugPrint('[EXERCISE_CACHE] 初始化失敗 (第 $retryCount/$maxRetries 次): $e');

          // 如果是鎖文件問題，嘗試刪除並重試
          if (e.toString().contains('lock failed') ||
              e.toString().contains('already open')) {
            debugPrint('[EXERCISE_CACHE] 檢測到鎖文件問題，嘗試清理...');

            try {
              // 嘗試刪除舊的 Box（如果存在）
              if (await Hive.boxExists(_boxName)) {
                await Hive.deleteBoxFromDisk(_boxName);
                debugPrint('[EXERCISE_CACHE] 已刪除舊的快取檔案');
              }
              if (await Hive.boxExists(_searchIndexBoxName)) {
                await Hive.deleteBoxFromDisk(_searchIndexBoxName);
                debugPrint('[EXERCISE_CACHE] 已刪除舊的搜尋索引檔案');
              }

              // 等待一小段時間後重試
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
            } catch (cleanupError) {
              debugPrint('[EXERCISE_CACHE] 清理失敗: $cleanupError');
            }
          }

          if (retryCount >= maxRetries) {
            debugPrint('[EXERCISE_CACHE] ⚠️ 初始化失敗，將使用無快取模式');
            // 不拋出錯誤，讓服務在無快取模式下運行
            _box = null;
            _searchIndexBox = null;
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[EXERCISE_CACHE] 初始化過程發生錯誤: $e');
      // 不拋出錯誤，讓服務在無快取模式下運行
      _box = null;
      _searchIndexBox = null;
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
      debugPrint('[EXERCISE_CACHE] 快取有效（版本 $cachedVersion，上次更新: $lastUpdate）');
    } else {
      debugPrint('[EXERCISE_CACHE] 快取無效或已過期（版本 $cachedVersion）');
    }

    return isValid;
  }

  /// 保存所有動作到本地
  Future<void> saveExercises(List<Exercise> exercises) async {
    if (_box == null) throw Exception('Hive Box 未初始化');

    try {
      debugPrint('[EXERCISE_CACHE] 開始保存 ${exercises.length} 個動作到本地...');

      // 將 Exercise 物件轉換為 JSON Map（使用 Supabase 格式）
      final exercisesMaps = exercises.map((e) {
        return {
          'id': e.id,
          'name': e.name,
          'name_en': e.nameEn,
          'training_type': e.trainingType,
          'body_part': e.bodyPart, // ✅ 使用 body_part（單數）
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
          'tracking_mode': e.trackingMode.toJson(), // v3 新增
          // v5.0 新增：動作分類系統 v2 欄位
          'canonical_name': e.canonicalName,
          'canonical_name_en': e.canonicalNameEn,
          'movement_patterns': e.movementPatterns,
          'ppl_tags': e.pplTags,
          'primary_muscle': e.primaryMuscle,
          'synergist_muscles': e.synergistMuscles,
          'mechanics_type': e.mechanicsType,
          'is_unilateral': e.isUnilateral,
          'difficulty_level': e.difficultyLevel,
          'is_explosive': e.isExplosive,
          'aliases': e.aliases,
        };
      }).toList();

      await _box!.put(_exercisesKey, exercisesMaps);
      await _box!.put(_versionKey, currentCacheVersion);
      await _box!
          .put(_lastUpdateKey, DateTimeUtils.formatToUtcIso(DateTime.now()));

      debugPrint('[EXERCISE_CACHE] ✅ 成功保存到本地（${_getDataSize(exercisesMaps)}）');

      // v5.0: 在背景建構搜尋索引
      _buildSearchIndexInBackground(exercises);
    } catch (e) {
      debugPrint('[EXERCISE_CACHE] 保存失敗: $e');
      rethrow;
    }
  }

  /// 從本地載入所有動作
  Future<List<Exercise>> loadExercises() async {
    if (_box == null) throw Exception('Hive Box 未初始化');

    try {
      debugPrint('[EXERCISE_CACHE] 從本地載入動作...');

      final exercisesMaps = _box!.get(_exercisesKey) as List?;
      if (exercisesMaps == null || exercisesMaps.isEmpty) {
        debugPrint('[EXERCISE_CACHE] 本地無資料');
        return [];
      }

      // ⚡ 使用 Isolate 但優化數據傳輸（只傳必要數據）
      final startTime = DateTime.now();
      final maps = exercisesMaps.cast<Map<dynamic, dynamic>>();

      // 使用 Isolate 解析（完全不阻塞主線程）
      final exercises = await _parseInIsolate(maps);

      final duration = DateTime.now().difference(startTime);
      debugPrint(
          '[EXERCISE_CACHE] ✅ 成功從本地載入 ${exercises.length} 個動作（Isolate 解析耗時 ${duration.inMilliseconds}ms）');
      return exercises;
    } catch (e) {
      debugPrint('[EXERCISE_CACHE] 載入失敗: $e');
      return [];
    }
  }

  /// 清除快取（強制重新下載）
  Future<void> clearCache() async {
    if (_box == null) return;

    await _box!.clear();
    debugPrint('[EXERCISE_CACHE] 快取已清除');
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
    await _searchIndexBox?.close();
    _box = null;
    _searchIndexBox = null;
  }

  // ============================================================================
  // v5.0 搜尋索引功能
  // ============================================================================

  /// 在背景建構搜尋索引（使用 Isolate 避免 UI 卡頓）
  void _buildSearchIndexInBackground(List<Exercise> exercises) {
    // 使用 compute 在 Isolate 中建構索引
    compute(_buildSearchIndexIsolate, exercises).then((indexData) {
      _saveSearchIndex(indexData);
    }).catchError((e) {
      debugPrint('[EXERCISE_CACHE] 搜尋索引建構失敗: $e');
    });
  }

  /// Isolate 內執行的索引建構（純函數）
  static Map<String, dynamic> _buildSearchIndexIsolate(List<Exercise> exercises) {
    final trigramIndex = <String, List<String>>{};

    for (final exercise in exercises) {
      final id = exercise.id;

      // 收集所有需要索引的文字
      final textsToIndex = <String>[
        exercise.name,
        exercise.nameEn,
        if (exercise.canonicalName != null) exercise.canonicalName!,
        if (exercise.canonicalNameEn != null) exercise.canonicalNameEn!,
        ...exercise.aliases,
      ];

      // 為每個文字建構 Trigram
      for (final text in textsToIndex) {
        final trigrams = _generateTrigrams(text.toLowerCase());
        for (final trigram in trigrams) {
          trigramIndex.putIfAbsent(trigram, () => []);
          if (!trigramIndex[trigram]!.contains(id)) {
            trigramIndex[trigram]!.add(id);
          }
        }
      }
    }

    return {
      'trigram_index': trigramIndex,
      'version': currentCacheVersion,
    };
  }

  /// 生成 Trigram（3-gram）
  static List<String> _generateTrigrams(String text) {
    if (text.length < 3) {
      return [text]; // 短字串直接返回
    }

    final trigrams = <String>[];
    for (var i = 0; i <= text.length - 3; i++) {
      trigrams.add(text.substring(i, i + 3));
    }
    return trigrams;
  }

  /// 保存搜尋索引到 Hive
  Future<void> _saveSearchIndex(Map<String, dynamic> indexData) async {
    if (_searchIndexBox == null) {
      debugPrint('[EXERCISE_CACHE] 搜尋索引 Box 未初始化，跳過保存');
      return;
    }

    try {
      await _searchIndexBox!.put(_trigramIndexKey, indexData['trigram_index']);
      await _searchIndexBox!.put(_indexVersionKey, indexData['version']);

      final trigramCount = (indexData['trigram_index'] as Map).length;
      debugPrint('[EXERCISE_CACHE] ✅ 搜尋索引建構完成（$trigramCount 個 trigram）');
    } catch (e) {
      debugPrint('[EXERCISE_CACHE] 搜尋索引保存失敗: $e');
    }
  }

  /// 獲取 Trigram 索引（供 FuzzySearchEngine 使用）
  Map<String, List<String>>? getTrigramIndex() {
    if (_searchIndexBox == null) return null;

    final index = _searchIndexBox!.get(_trigramIndexKey);
    if (index == null) return null;

    // 轉換類型
    return (index as Map).map((key, value) {
      return MapEntry(
        key.toString(),
        (value as List).cast<String>(),
      );
    });
  }

  /// 檢查搜尋索引是否有效
  bool isSearchIndexValid() {
    if (_searchIndexBox == null) return false;

    final indexVersion = _searchIndexBox!.get(_indexVersionKey, defaultValue: 0);
    final hasIndex = _searchIndexBox!.containsKey(_trigramIndexKey);

    return indexVersion == currentCacheVersion && hasIndex;
  }

  /// 使用 Trigram 索引快速過濾候選動作
  ///
  /// [query] 搜尋關鍵字
  /// [exercises] 完整動作列表
  /// 返回可能匹配的候選動作 ID 集合
  Set<String> filterCandidatesByTrigram(String query, {int minMatchCount = 1}) {
    final trigramIndex = getTrigramIndex();
    if (trigramIndex == null || query.length < 2) {
      return {}; // 索引不存在或查詢太短，返回空集合
    }

    final queryTrigrams = _generateTrigrams(query.toLowerCase());
    final candidateCounts = <String, int>{};

    // 計算每個候選 ID 匹配的 trigram 數量
    for (final trigram in queryTrigrams) {
      final matchingIds = trigramIndex[trigram];
      if (matchingIds != null) {
        for (final id in matchingIds) {
          candidateCounts[id] = (candidateCounts[id] ?? 0) + 1;
        }
      }
    }

    // 過濾出匹配數量達到閾值的候選
    return candidateCounts.entries
        .where((e) => e.value >= minMatchCount)
        .map((e) => e.key)
        .toSet();
  }

  /// 獲取搜尋索引資訊
  Map<String, dynamic> getSearchIndexInfo() {
    if (_searchIndexBox == null) {
      return {'initialized': false};
    }

    final trigramIndex = _searchIndexBox!.get(_trigramIndexKey) as Map?;
    final trigramCount = trigramIndex?.length ?? 0;
    final version = _searchIndexBox!.get(_indexVersionKey, defaultValue: 0);

    return {
      'initialized': true,
      'isValid': isSearchIndexValid(),
      'trigramCount': trigramCount,
      'version': version,
    };
  }
}
