import 'package:supabase_flutter/supabase_flutter.dart';

/// ⭐ 定義 exercises 表的標準查詢欄位（避免 SELECT *）
/// v3.2+ 新增 tracking_mode 欄位
const String _kExerciseSelectFields = '''
  id, name, name_en, body_parts, training_type, equipment, 
  level1, level2, level3, level4, level5, action_name, 
  description, image_url, video_url, body_part, 
  specific_muscle, equipment_category, equipment_subcategory, created_at,
  tracking_mode
''';

/// ⭐ 定義 custom_exercises 表的標準查詢欄位
/// v3.2+ 新增 tracking_mode 欄位
const String _kCustomExerciseSelectFields = '''
  id, name, body_part, training_type, equipment, description, 
  user_id, created_at, updated_at, tracking_mode
''';

/// 動作資料載入器
class ExerciseDataLoader {
  final SupabaseClient _client;
  final int _queryTimeout;

  ExerciseDataLoader({
    required SupabaseClient client,
    required errorService,
    required int queryTimeout,
  })  : _client = client,
        _queryTimeout = queryTimeout;

  /// 載入訓練類型
  Future<List<String>> loadExerciseTypes() async {
    final response = await _client
        .from('exercise_types')
        .select('name')
        .order('name')
        .timeout(Duration(seconds: _queryTimeout));

    List<String> types = [];
    for (var item in (response as List)) {
      types.add(item['name'] as String);
    }

    return types;
  }

  /// 載入身體部位
  Future<List<String>> loadBodyParts() async {
    final response = await _client
        .from('body_parts')
        .select('name')
        .order('name')
        .timeout(Duration(seconds: _queryTimeout));

    List<String> parts = [];
    for (var item in (response as List)) {
      parts.add(item['name'] as String);
    }

    return parts;
  }

  /// 載入分類層級
  Future<dynamic> loadCategoriesByLevel({
    required int level,
    required String selectedType,
    required String selectedBodyPart,
    required String selectedLevel1,
    required String selectedLevel2,
    required String selectedLevel3,
    required String selectedLevel4,
  }) async {
    var query = _client.from('exercises').select('level$level');

    // 確保類型條件始終套用
    if (selectedType.isNotEmpty) {
      query = query.eq('training_type', selectedType);
    }

    // 確保身體部位條件始終套用（PostgreSQL 陣列包含查詢）
    if (selectedBodyPart.isNotEmpty) {
      query = query.contains('body_parts', [selectedBodyPart]);
    }

    // 新增其他層級條件
    if (level >= 2 && selectedLevel1.isNotEmpty) {
      query = query.eq('level1', selectedLevel1);
    }

    if (level >= 3 && selectedLevel2.isNotEmpty) {
      query = query.eq('level2', selectedLevel2);
    }

    if (level >= 4 && selectedLevel3.isNotEmpty) {
      query = query.eq('level3', selectedLevel3);
    }

    if (level >= 5 && selectedLevel4.isNotEmpty) {
      query = query.eq('level4', selectedLevel4);
    }

    // 執行查詢
    final response = await query.timeout(
      Duration(seconds: _queryTimeout),
      onTimeout: () => throw TimeoutException('查詢逾時，請檢查網路連線'),
    );

    return response;
  }

  /// 根據過濾條件載入動作
  Future<dynamic> loadExercisesByFilters(Map<String, String> filters) async {
    var query = _client.from('exercises').select(_kExerciseSelectFields);

    // 新增所有有效的過濾條件
    for (final entry in filters.entries) {
      if (entry.value.isEmpty) continue;

      if (entry.key == 'bodyPart') {
        query = query.contains('body_parts', [entry.value]);
      } else if (entry.key == 'type') {
        query = query.eq('training_type', entry.value);
      } else {
        // 對於 level1-level5 的條件
        query = query.eq(entry.key, entry.value);
      }
    }

    // 執行查詢
    final response = await query.timeout(
      Duration(seconds: _queryTimeout),
      onTimeout: () => throw TimeoutException('查詢逾時，請檢查網路連線'),
    );

    return response;
  }

  /// 根據 ID 載入動作
  Future<Map<String, dynamic>?> loadExerciseById(String exerciseId) async {
    final response = await _client
        .from('exercises')
        .select(_kExerciseSelectFields)
        .eq('id', exerciseId)
        .maybeSingle()
        .timeout(
          Duration(seconds: _queryTimeout),
          onTimeout: () => throw TimeoutException('獲取運動詳情逾時'),
        );

    return response;
  }

  /// 根據 ID 列表批量載入動作
  Future<List<dynamic>> loadExercisesByIds(List<String> exerciseIds) async {
    final response = await _client
        .from('exercises')
        .select(_kExerciseSelectFields)
        .inFilter('id', exerciseIds)
        .timeout(
          Duration(seconds: _queryTimeout),
          onTimeout: () => throw TimeoutException('批量獲取運動詳情逾時'),
        );

    return response as List;
  }

  /// 載入自訂動作
  Future<Map<String, dynamic>?> loadCustomExerciseById(
      String exerciseId) async {
    final response = await _client
        .from('custom_exercises')
        .select(_kCustomExerciseSelectFields)
        .eq('id', exerciseId)
        .maybeSingle()
        .timeout(
          Duration(seconds: _queryTimeout),
          onTimeout: () => throw TimeoutException('獲取自訂動作詳情逾時'),
        );

    return response;
  }

  /// 批量載入自訂動作
  Future<List<dynamic>> loadCustomExercisesByIds(
      List<String> exerciseIds) async {
    final response = await _client
        .from('custom_exercises')
        .select(_kCustomExerciseSelectFields)
        .inFilter('id', exerciseIds)
        .timeout(
          Duration(seconds: _queryTimeout),
          onTimeout: () => throw TimeoutException('批量獲取自訂動作詳情逾時'),
        );

    return response as List;
  }

  /// 全文搜尋（使用 pgroonga）
  Future<List<dynamic>> searchExercisesWithPgroonga(
      String query, int limit) async {
    final response = await _client.rpc(
      'search_exercises_pgroonga',
      params: {
        'search_query': query,
        'max_results': limit,
      },
    ).timeout(
      Duration(seconds: _queryTimeout),
      onTimeout: () => throw TimeoutException('搜尋動作逾時'),
    );

    return response as List;
  }

  /// 回退搜尋（LIKE 查詢）
  Future<List<dynamic>> fallbackSearch(String query, int limit) async {
    final response = await _client
        .from('exercises')
        .select(_kExerciseSelectFields)
        .or('name.ilike.%$query%,name_en.ilike.%$query%')
        .limit(limit)
        .timeout(
          Duration(seconds: _queryTimeout),
          onTimeout: () => throw TimeoutException('回退搜尋逾時'),
        );

    return response as List;
  }

  /// 載入所有動作（預載入用）
  Future<List<dynamic>> loadAllExercises() async {
    final response =
        await _client.from('exercises').select(_kExerciseSelectFields).timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException('載入所有動作超時'),
            );

    return response as List;
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}
