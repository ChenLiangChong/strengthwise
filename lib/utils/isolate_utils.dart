import 'package:flutter/foundation.dart';

/// Isolate 工具類
///
/// 提供通用的背景解析功能，避免大型 JSON 解析阻塞主執行緒
/// 保持 UI 60fps 流暢度
class IsolateUtils {
  /// 列表解析閾值（超過此數量使用 Isolate）
  static const int listThreshold = 50;

  /// 在背景 Isolate 中解析列表
  ///
  /// [rawData] 原始 JSON 資料列表
  /// [fromJson] 轉換函數（必須是頂層函數或靜態方法）
  ///
  /// 使用範例：
  /// ```dart
  /// final users = await IsolateUtils.parseListInBackground(
  ///   jsonList,
  ///   UserModel.fromSupabase,
  /// );
  /// ```
  static Future<List<T>> parseListInBackground<T>(
    List<dynamic> rawData,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    if (rawData.isEmpty) return [];

    // 小型列表直接在主執行緒解析
    if (rawData.length < listThreshold) {
      return rawData
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // 大型列表使用 Isolate
    try {
      final result = await compute(
        _parseListIsolate<T>,
        _ParseListParams<T>(
          rawData: rawData.cast<Map<dynamic, dynamic>>(),
          fromJson: fromJson,
        ),
      );

      if (kDebugMode) {
        print('[ISOLATE_UTILS] ⚡ 背景解析完成：${result.length} 筆資料');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('[ISOLATE_UTILS] ⚠️ Isolate 解析失敗，降級到主執行緒: $e');
      }
      // 降級：在主執行緒解析
      return rawData
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    }
  }

  /// 在背景 Isolate 中解析單筆資料
  ///
  /// [rawData] 原始 JSON 資料
  /// [fromJson] 轉換函數
  static Future<T> parseInBackground<T>(
    Map<String, dynamic> rawData,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    // 單筆資料通常不需要 Isolate，直接解析
    return fromJson(rawData);
  }

  /// 在背景 Isolate 中執行任意計算
  ///
  /// [callback] 計算函數（必須是頂層函數或靜態方法）
  /// [message] 傳遞給計算函數的參數
  static Future<R> runInBackground<Q, R>(
    R Function(Q) callback,
    Q message,
  ) async {
    try {
      return await compute(callback, message);
    } catch (e) {
      if (kDebugMode) {
        print('[ISOLATE_UTILS] ⚠️ 背景計算失敗: $e');
      }
      rethrow;
    }
  }

  /// 批量解析多個列表（並行）
  ///
  /// 適用於同時解析多個不同類型的資料
  static Future<List<List<T>>> parseMultipleListsInBackground<T>(
    List<List<dynamic>> rawDataLists,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final futures = rawDataLists.map((rawData) {
      return parseListInBackground(rawData, fromJson);
    }).toList();

    return await Future.wait(futures);
  }
}

/// Isolate 參數封裝（用於 compute）
class _ParseListParams<T> {
  final List<Map<dynamic, dynamic>> rawData;
  final T Function(Map<String, dynamic>) fromJson;

  _ParseListParams({
    required this.rawData,
    required this.fromJson,
  });
}

/// Isolate 內執行的解析函數（必須是頂層函數）
List<T> _parseListIsolate<T>(_ParseListParams<T> params) {
  return params.rawData
      .map((item) => params.fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

// ============================================================================
// 常用的靜態解析函數（供 Isolate 使用）
// ============================================================================

/// 通用 Map 轉換（用於複雜的巢狀資料）
List<Map<String, dynamic>> parseJsonListIsolate(List<Map<dynamic, dynamic>> rawData) {
  return rawData
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}
