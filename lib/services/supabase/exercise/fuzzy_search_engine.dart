import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../models/exercise_model.dart';

/// 模糊搜尋引擎（v5.0）
///
/// 提供離線模糊搜尋功能，支援：
/// - Jaro-Winkler 相似度計算
/// - Trigram 索引加速候選過濾
/// - 5 欄位加權評分
/// - Isolate 並行處理
class FuzzySearchEngine {
  /// 權重配置
  static const double _nameWeight = 0.30;
  static const double _nameEnWeight = 0.25;
  static const double _canonicalNameWeight = 0.20;
  static const double _canonicalNameEnWeight = 0.15;
  static const double _aliasesWeight = 0.10;

  /// 搜尋動作（支援模糊匹配）
  ///
  /// [query] 搜尋關鍵字
  /// [exercises] 候選動作列表
  /// [candidateIds] 可選的候選 ID 集合（由 Trigram 索引預過濾）
  /// [limit] 返回結果數量上限
  /// [threshold] 最低相似度閾值（0.0-1.0）
  Future<List<ScoredExercise>> search({
    required String query,
    required List<Exercise> exercises,
    Set<String>? candidateIds,
    int limit = 20,
    double threshold = 0.3,
  }) async {
    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase().trim();

    // 如果有候選 ID，先過濾
    List<Exercise> candidates = exercises;
    if (candidateIds != null && candidateIds.isNotEmpty) {
      candidates = exercises.where((e) => candidateIds.contains(e.id)).toList();
    }

    // 使用 Isolate 計算相似度
    final params = _SearchParams(
      query: lowerQuery,
      exercises: candidates,
      threshold: threshold,
    );

    final results = await compute(_searchInIsolate, params);

    // 排序並取前 N 個
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  /// Isolate 內執行的搜尋（純函數）
  static List<ScoredExercise> _searchInIsolate(_SearchParams params) {
    final results = <ScoredExercise>[];

    for (final exercise in params.exercises) {
      final score = _calculateWeightedScore(exercise, params.query);

      if (score >= params.threshold) {
        results.add(ScoredExercise(exercise: exercise, score: score));
      }
    }

    return results;
  }

  /// 計算加權相似度分數
  static double _calculateWeightedScore(Exercise exercise, String query) {
    double totalScore = 0.0;

    // 1. name（中文名）
    final nameScore = _calculateFieldScore(exercise.name.toLowerCase(), query);
    totalScore += nameScore * _nameWeight;

    // 2. nameEn（英文名）
    final nameEnScore =
        _calculateFieldScore(exercise.nameEn.toLowerCase(), query);
    totalScore += nameEnScore * _nameEnWeight;

    // 3. canonicalName（SEE 標準中文名）
    if (exercise.canonicalName != null) {
      final canonicalScore =
          _calculateFieldScore(exercise.canonicalName!.toLowerCase(), query);
      totalScore += canonicalScore * _canonicalNameWeight;
    }

    // 4. canonicalNameEn（SEE 標準英文名）
    if (exercise.canonicalNameEn != null) {
      final canonicalEnScore =
          _calculateFieldScore(exercise.canonicalNameEn!.toLowerCase(), query);
      totalScore += canonicalEnScore * _canonicalNameEnWeight;
    }

    // 5. aliases（別名）- 取最高分
    if (exercise.aliases.isNotEmpty) {
      double maxAliasScore = 0.0;
      for (final alias in exercise.aliases) {
        final aliasScore = _calculateFieldScore(alias.toLowerCase(), query);
        if (aliasScore > maxAliasScore) {
          maxAliasScore = aliasScore;
        }
      }
      totalScore += maxAliasScore * _aliasesWeight;
    }

    return totalScore;
  }

  /// 計算單欄位相似度
  static double _calculateFieldScore(String field, String query) {
    // 完全匹配
    if (field == query) return 1.0;

    // 前綴匹配
    if (field.startsWith(query)) return 0.9;

    // 包含匹配
    if (field.contains(query)) return 0.7;

    // Jaro-Winkler 相似度
    final jw = jaroWinklerSimilarity(field, query);

    // Trigram 相似度
    final trigram = trigramSimilarity(field, query);

    // 取較高者
    return max(jw, trigram);
  }

  /// Jaro-Winkler 相似度
  ///
  /// 適合處理拼寫錯誤、前綴相似的情況
  static double jaroWinklerSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    // Jaro 相似度
    final jaro = _jaroSimilarity(s1, s2);
    if (jaro == 0.0) return 0.0;

    // 計算共同前綴長度（最多 4 個字元）
    int prefixLength = 0;
    final maxPrefix = min(4, min(s1.length, s2.length));
    for (int i = 0; i < maxPrefix; i++) {
      if (s1[i] == s2[i]) {
        prefixLength++;
      } else {
        break;
      }
    }

    // Winkler 修正（前綴加權 0.1）
    return jaro + (prefixLength * 0.1 * (1 - jaro));
  }

  /// Jaro 相似度（內部函數）
  static double _jaroSimilarity(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    if (len1 == 0 && len2 == 0) return 1.0;
    if (len1 == 0 || len2 == 0) return 0.0;

    // 匹配窗口
    final matchWindow = max(0, (max(len1, len2) ~/ 2) - 1);

    final s1Matches = List<bool>.filled(len1, false);
    final s2Matches = List<bool>.filled(len2, false);

    int matches = 0;
    int transpositions = 0;

    // 計算匹配
    for (int i = 0; i < len1; i++) {
      final start = max(0, i - matchWindow);
      final end = min(i + matchWindow + 1, len2);

      for (int j = start; j < end; j++) {
        if (s2Matches[j] || s1[i] != s2[j]) continue;
        s1Matches[i] = true;
        s2Matches[j] = true;
        matches++;
        break;
      }
    }

    if (matches == 0) return 0.0;

    // 計算轉置
    int k = 0;
    for (int i = 0; i < len1; i++) {
      if (!s1Matches[i]) continue;
      while (!s2Matches[k]) {
        k++;
      }
      if (s1[i] != s2[k]) transpositions++;
      k++;
    }

    return (matches / len1 +
            matches / len2 +
            (matches - transpositions / 2) / matches) /
        3;
  }

  /// Trigram（3-gram）相似度
  ///
  /// 基於字元 n-gram 重疊度
  static double trigramSimilarity(String s1, String s2) {
    final trigrams1 = _generateTrigrams(s1);
    final trigrams2 = _generateTrigrams(s2);

    if (trigrams1.isEmpty || trigrams2.isEmpty) return 0.0;

    // 計算交集
    final intersection = trigrams1.intersection(trigrams2).length;
    final union = trigrams1.union(trigrams2).length;

    return intersection / union; // Jaccard 相似度
  }

  /// 生成 Trigram 集合
  static Set<String> _generateTrigrams(String text) {
    if (text.length < 3) return {text};

    final trigrams = <String>{};
    for (var i = 0; i <= text.length - 3; i++) {
      trigrams.add(text.substring(i, i + 3));
    }
    return trigrams;
  }
}

/// 搜尋參數（用於 Isolate 傳遞）
class _SearchParams {
  final String query;
  final List<Exercise> exercises;
  final double threshold;

  _SearchParams({
    required this.query,
    required this.exercises,
    required this.threshold,
  });
}

/// 帶分數的動作結果
class ScoredExercise {
  final Exercise exercise;
  final double score;

  ScoredExercise({
    required this.exercise,
    required this.score,
  });

  @override
  String toString() =>
      'ScoredExercise(${exercise.name}, score: ${score.toStringAsFixed(3)})';
}
