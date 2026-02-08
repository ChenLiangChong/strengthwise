import '../../../models/exercise_model.dart';
import 'fuzzy_search_engine.dart';

/// 動作搜尋引擎（客戶端）
///
/// 提供記憶體快取搜尋功能，支援：
/// - 基本文字搜尋（名稱、英文名、分類）
/// - v5.0+ 進階搜尋（別名、動作模式、PPL 標籤）
/// - v5.0+ 模糊搜尋（Jaro-Winkler + Trigram）
class ExerciseSearchEngine {
  final FuzzySearchEngine _fuzzyEngine = FuzzySearchEngine();
  /// 從快取中搜尋動作
  List<Exercise> searchFromCache({
    required List<Exercise> cache,
    required String query,
    required int limit,
  }) {
    final lowerQuery = query.toLowerCase();

    // v5.0+: 加入別名和標準名搜尋
    final results = cache.where((exercise) {
      // 基本名稱搜尋
      if (exercise.name.toLowerCase().contains(lowerQuery)) return true;
      if (exercise.nameEn.toLowerCase().contains(lowerQuery)) return true;

      // v5.0+ 標準名稱搜尋
      if (exercise.canonicalName != null &&
          exercise.canonicalName!.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      if (exercise.canonicalNameEn != null &&
          exercise.canonicalNameEn!.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // v5.0+ 別名搜尋
      for (final alias in exercise.aliases) {
        if (alias.toLowerCase().contains(lowerQuery)) return true;
      }

      // 分類搜尋
      if (exercise.level1.isNotEmpty &&
          exercise.level1.toLowerCase().contains(lowerQuery)) {
        return true;
      }
      if (exercise.level2.isNotEmpty &&
          exercise.level2.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      return false;
    }).toList();

    // 排序：名稱完全匹配 > 開頭匹配 > 部分匹配
    results.sort((a, b) {
      final aScore = _calculateRelevanceScore(a, lowerQuery);
      final bScore = _calculateRelevanceScore(b, lowerQuery);
      return bScore.compareTo(aScore);
    });

    return results.take(limit).toList();
  }

  /// 計算相關度分數
  double _calculateRelevanceScore(Exercise exercise, String query) {
    // 完全匹配
    if (exercise.name.toLowerCase() == query) return 100.0;
    if (exercise.nameEn.toLowerCase() == query) return 95.0;
    if (exercise.canonicalName?.toLowerCase() == query) return 90.0;

    // 開頭匹配
    if (exercise.name.toLowerCase().startsWith(query)) return 80.0;
    if (exercise.nameEn.toLowerCase().startsWith(query)) return 75.0;

    // 別名匹配
    for (final alias in exercise.aliases) {
      if (alias.toLowerCase() == query) return 70.0;
      if (alias.toLowerCase().startsWith(query)) return 65.0;
    }

    // 部分匹配
    if (exercise.name.toLowerCase().contains(query)) return 50.0;
    if (exercise.nameEn.toLowerCase().contains(query)) return 45.0;

    return 40.0;
  }

  /// v5.0+ 進階搜尋（支援別名、動作模式、PPL 標籤）
  List<Exercise> searchAdvancedFromCache({
    required List<Exercise> cache,
    String? query,
    List<String>? movementPatterns,
    List<String>? pplTags,
    String? primaryMuscle,
    String? equipment,
    bool? isExplosive,
    String? difficultyLevel,
    int limit = 50,
  }) {
    var results = cache.toList();

    // 文字搜尋（名稱 + 別名）
    if (query != null && query.trim().isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((e) => _matchesQuery(e, lowerQuery)).toList();
    }

    // 動作模式篩選（陣列交集）
    if (movementPatterns != null && movementPatterns.isNotEmpty) {
      results = results.where((e) {
        return e.movementPatterns.any((p) => movementPatterns.contains(p));
      }).toList();
    }

    // PPL 標籤篩選（陣列交集）
    if (pplTags != null && pplTags.isNotEmpty) {
      results = results.where((e) {
        return e.pplTags.any((t) => pplTags.contains(t));
      }).toList();
    }

    // 主動肌篩選
    if (primaryMuscle != null && primaryMuscle.isNotEmpty) {
      results = results.where((e) => e.primaryMuscle == primaryMuscle).toList();
    }

    // 器材篩選
    if (equipment != null && equipment.isNotEmpty) {
      results = results.where((e) => e.equipment == equipment).toList();
    }

    // 爆發力篩選
    if (isExplosive != null) {
      results = results.where((e) => e.isExplosive == isExplosive).toList();
    }

    // 難度篩選
    if (difficultyLevel != null && difficultyLevel.isNotEmpty) {
      results =
          results.where((e) => e.difficultyLevel == difficultyLevel).toList();
    }

    // 排序
    if (query != null && query.trim().isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results.sort((a, b) {
        final aScore = _calculateRelevanceScore(a, lowerQuery);
        final bScore = _calculateRelevanceScore(b, lowerQuery);
        return bScore.compareTo(aScore);
      });
    } else {
      // 無搜尋關鍵字時按名稱排序
      results.sort((a, b) => a.name.compareTo(b.name));
    }

    return results.take(limit).toList();
  }

  /// 檢查動作是否匹配搜尋關鍵字
  bool _matchesQuery(Exercise exercise, String lowerQuery) {
    // 名稱匹配
    if (exercise.name.toLowerCase().contains(lowerQuery)) return true;
    if (exercise.nameEn.toLowerCase().contains(lowerQuery)) return true;

    // 標準名稱匹配
    if (exercise.canonicalName != null &&
        exercise.canonicalName!.toLowerCase().contains(lowerQuery)) {
      return true;
    }
    if (exercise.canonicalNameEn != null &&
        exercise.canonicalNameEn!.toLowerCase().contains(lowerQuery)) {
      return true;
    }

    // 別名匹配
    for (final alias in exercise.aliases) {
      if (alias.toLowerCase().contains(lowerQuery)) return true;
    }

    return false;
  }

  /// 從快取中依過濾條件篩選
  List<Exercise> filterFromCache({
    required List<Exercise> cache,
    required Map<String, String> filters,
  }) {
    var exercises = cache;

    for (final entry in filters.entries) {
      if (entry.value.isEmpty) continue;

      if (entry.key == 'bodyPart') {
        exercises =
            exercises.where((e) => e.bodyPart == entry.value).toList();
      } else if (entry.key == 'type') {
        exercises =
            exercises.where((e) => e.trainingType == entry.value).toList();
      } else if (entry.key == 'level1') {
        exercises = exercises.where((e) => e.level1 == entry.value).toList();
      } else if (entry.key == 'level2') {
        exercises = exercises.where((e) => e.level2 == entry.value).toList();
      } else if (entry.key == 'level3') {
        exercises = exercises.where((e) => e.level3 == entry.value).toList();
      } else if (entry.key == 'level4') {
        exercises = exercises.where((e) => e.level4 == entry.value).toList();
      } else if (entry.key == 'level5') {
        exercises = exercises.where((e) => e.level5 == entry.value).toList();
      }
      // v5.0+ 新增篩選條件
      else if (entry.key == 'primaryMuscle') {
        exercises =
            exercises.where((e) => e.primaryMuscle == entry.value).toList();
      } else if (entry.key == 'difficultyLevel') {
        exercises =
            exercises.where((e) => e.difficultyLevel == entry.value).toList();
      } else if (entry.key == 'mechanicsType') {
        exercises =
            exercises.where((e) => e.mechanicsType == entry.value).toList();
      }
    }

    return exercises;
  }

  /// v5.0+ 依 PPL 標籤篩選
  List<Exercise> filterByPplTags({
    required List<Exercise> cache,
    required List<String> pplTags,
  }) {
    if (pplTags.isEmpty) return cache;

    return cache.where((e) {
      return e.pplTags.any((t) => pplTags.contains(t));
    }).toList();
  }

  /// v5.0+ 依動作模式篩選
  List<Exercise> filterByMovementPatterns({
    required List<Exercise> cache,
    required List<String> patterns,
  }) {
    if (patterns.isEmpty) return cache;

    return cache.where((e) {
      return e.movementPatterns.any((p) => patterns.contains(p));
    }).toList();
  }

  // ============================================================================
  // v5.0 模糊搜尋功能
  // ============================================================================

  /// 模糊搜尋動作（支援拼寫錯誤容忍）
  ///
  /// [query] 搜尋關鍵字
  /// [cache] 候選動作列表
  /// [candidateIds] 可選的候選 ID 集合（由 Trigram 索引預過濾）
  /// [limit] 返回結果數量上限
  /// [threshold] 最低相似度閾值（0.0-1.0，預設 0.3）
  ///
  /// 使用策略：
  /// 1. 先嘗試精確匹配（contains）
  /// 2. 如果精確匹配結果不足，再進行模糊匹配
  Future<List<Exercise>> fuzzySearchFromCache({
    required List<Exercise> cache,
    required String query,
    Set<String>? candidateIds,
    int limit = 20,
    double threshold = 0.3,
  }) async {
    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase().trim();

    // 1. 先嘗試精確匹配
    final exactResults = searchFromCache(
      cache: cache,
      query: query,
      limit: limit,
    );

    // 如果精確匹配結果足夠，直接返回
    if (exactResults.length >= limit) {
      return exactResults;
    }

    // 2. 進行模糊匹配補足結果
    final exactIds = exactResults.map((e) => e.id).toSet();

    // 排除已有結果的候選
    List<Exercise> candidates = cache;
    if (candidateIds != null && candidateIds.isNotEmpty) {
      candidates = cache
          .where((e) => candidateIds.contains(e.id) && !exactIds.contains(e.id))
          .toList();
    } else {
      candidates = cache.where((e) => !exactIds.contains(e.id)).toList();
    }

    // 模糊搜尋
    final fuzzyResults = await _fuzzyEngine.search(
      query: lowerQuery,
      exercises: candidates,
      limit: limit - exactResults.length,
      threshold: threshold,
    );

    // 合併結果：精確匹配在前，模糊匹配在後
    final combined = [...exactResults];
    for (final scored in fuzzyResults) {
      combined.add(scored.exercise);
    }

    return combined.take(limit).toList();
  }

  /// 獲取模糊搜尋引擎（供直接訪問）
  FuzzySearchEngine get fuzzyEngine => _fuzzyEngine;
}
