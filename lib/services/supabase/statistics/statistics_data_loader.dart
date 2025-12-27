import 'package:supabase_flutter/supabase_flutter.dart';

/// 統計數據載入器
///
/// 負責從 Supabase 查詢訓練數據
class StatisticsDataLoader {
  final SupabaseClient _supabase;

  StatisticsDataLoader({required SupabaseClient supabase})
      : _supabase = supabase;

  /// 查詢已完成的訓練（指定時間範圍）
  Future<List<Map<String, dynamic>>> getCompletedWorkouts(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _supabase
        .from('workout_plans')
        .select('id, completed_date, updated_at, exercises, total_volume')
        .eq('trainee_id', userId)
        .eq('completed', true)
        .gte('completed_date', startDate.toIso8601String())
        .lte('completed_date', endDate.add(Duration(days: 1)).toIso8601String());

    return (response as List<dynamic>)
        .map((doc) => doc as Map<String, dynamic>)
        .toList();
  }

  /// 查詢所有已完成的訓練（不限時間）
  Future<List<Map<String, dynamic>>> getAllCompletedWorkouts(
      String userId) async {
    final response = await _supabase
        .from('workout_plans')
        .select()
        .eq('trainee_id', userId)
        .eq('completed', true);

    return (response as List<dynamic>)
        .map((doc) => doc as Map<String, dynamic>)
        .toList();
  }

  /// 從彙總表查詢訓練頻率
  Future<List<Map<String, dynamic>>> getDailySummary(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _supabase
        .from('daily_workout_summary')
        .select('workout_count, date')
        .eq('user_id', userId)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0])
        .order('date');

    return (response as List<dynamic>)
        .map((row) => row as Map<String, dynamic>)
        .toList();
  }

  /// 從彙總表查詢訓練量趨勢
  Future<List<Map<String, dynamic>>> getVolumeSummary(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _supabase
        .from('daily_workout_summary')
        .select('date, total_volume, total_sets, workout_count')
        .eq('user_id', userId)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0])
        .order('date');

    return (response as List<dynamic>)
        .map((row) => row as Map<String, dynamic>)
        .toList();
  }

  /// 從彙總表查詢訓練類型統計
  Future<List<Map<String, dynamic>>> getTrainingTypeSummary(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final response = await _supabase
        .from('daily_workout_summary')
        .select('resistance_training_count, cardio_count, mobility_count')
        .eq('user_id', userId)
        .gte('date', startDate.toIso8601String().split('T')[0])
        .lte('date', endDate.toIso8601String().split('T')[0]);

    return (response as List<dynamic>)
        .map((row) => row as Map<String, dynamic>)
        .toList();
  }

  /// 從彙總表查詢個人記錄
  Future<List<Map<String, dynamic>>> getPersonalRecordsFromAggregation(
    String userId, {
    int limit = 20,
  }) async {
    final response = await _supabase
        .from('personal_records')
        .select(
            'exercise_id, exercise_name, max_weight, max_reps, max_volume, '
            'achieved_date, workout_plan_id')
        .eq('user_id', userId)
        .order('max_weight', ascending: false)
        .limit(limit);

    return (response as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  /// 批量查詢動作信息（系統動作）
  Future<List<Map<String, dynamic>>> getExerciseInfo(List<String> exerciseIds) async {
    final response = await _supabase
        .from('exercises')
        .select('id, body_part')
        .inFilter('id', exerciseIds);

    return (response as List<dynamic>)
        .map((ex) => ex as Map<String, dynamic>)
        .toList();
  }

  /// 批量查詢自訂動作信息
  Future<List<Map<String, dynamic>>> getCustomExerciseInfo(
      List<String> exerciseIds) async {
    final response = await _supabase
        .from('custom_exercises')
        .select('id, body_part')
        .inFilter('id', exerciseIds);

    return (response as List<dynamic>)
        .map((ex) => ex as Map<String, dynamic>)
        .toList();
  }
}

