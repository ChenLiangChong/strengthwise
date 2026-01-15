import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/datetime_utils.dart';

/// 統計數據載入器
///
/// 負責從 Supabase 查詢訓練數據
class StatisticsDataLoader {
  final SupabaseClient _supabase;

  StatisticsDataLoader({required SupabaseClient supabase})
      : _supabase = supabase;

  /// 查詢訓練數據（指定時間範圍）
  ///
  /// ⚠️ 重要：查詢所有訓練計劃（不管 completed 狀態）
  /// 因為 Parser 會根據 set.completed 來過濾組數
  ///
  /// 邏輯：
  /// 1. 查詢 updated_at 在範圍內的所有訓練計劃
  /// 2. Parser 會過濾出 set.completed = true 的組
  /// 3. 這些組的數據用於統計
  Future<List<Map<String, dynamic>>> getCompletedWorkouts(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // 擴展查詢範圍（前後各加 1 天）以確保不遺漏數據
    final queryStartDate = startDate.subtract(const Duration(days: 1));
    final queryEndDate = endDate.add(const Duration(days: 2));

    // v3.3+ 修正：加入 scheduled_date 以統一時間判斷邏輯
    final response = await _supabase
        .from('workout_plans')
        .select(
            'id, completed_date, scheduled_date, updated_at, exercises, total_volume, completed')
        .eq('trainee_id', userId)
        .gte('updated_at', DateTimeUtils.formatToUtcIso(queryStartDate))
        .lte('updated_at', DateTimeUtils.formatToUtcIso(queryEndDate))
        .order('updated_at', ascending: false);

    final List<Map<String, dynamic>> allWorkouts = (response as List<dynamic>)
        .map((doc) => doc as Map<String, dynamic>)
        .toList();

    // v3.3+ 修正：使用 COALESCE(completed_date, scheduled_date, updated_at) 邏輯
    // 與 getExercisesWithRecords 保持一致
    final filtered = allWorkouts.where((doc) {
      final completedDateStr = doc['completed_date'] as String?;
      final scheduledDateStr = doc['scheduled_date'] as String?;
      final updatedAtStr = doc['updated_at'] as String;

      // v3.3+ 優先順序：completed_date > scheduled_date > updated_at
      DateTime trainingDate;
      try {
        if (completedDateStr != null && completedDateStr.isNotEmpty) {
          trainingDate = DateTimeUtils.parseIsoTimestamp(completedDateStr);
        } else if (scheduledDateStr != null && scheduledDateStr.isNotEmpty) {
          trainingDate = DateTimeUtils.parseIsoTimestamp(scheduledDateStr);
        } else {
          trainingDate = DateTimeUtils.parseIsoTimestamp(updatedAtStr);
        }
      } catch (e) {
        print('[STATISTICS_LOADER] ❌ 解析日期失敗：$e');
        return false;
      }

      // 檢查訓練日期是否在目標範圍內（使用日期比較，忽略時間）
      final trainingDateOnly =
          DateTime(trainingDate.year, trainingDate.month, trainingDate.day);
      final startDateOnly =
          DateTime(startDate.year, startDate.month, startDate.day);
      final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

      return !trainingDateOnly.isBefore(startDateOnly) &&
          !trainingDateOnly.isAfter(endDateOnly);
    }).toList();

    return filtered;
  }

  /// 查詢所有訓練（不限時間）
  ///
  /// ⚠️ 重要：查詢所有訓練（包括部分完成）
  /// 因為 Parser 會根據 set.completed 來過濾組數
  Future<List<Map<String, dynamic>>> getAllCompletedWorkouts(
      String userId) async {
    // ⭐ 只查詢統計需要的欄位（避免 SELECT *）
    final response = await _supabase
        .from('workout_plans')
        .select(
            'id, completed_date, updated_at, exercises, total_volume, completed')
        .eq('trainee_id', userId);
    // ✅ 移除 .eq('completed', true) 限制

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
    // ⭐ 修正：直接使用本地日期，不要轉換為 UTC（因為 date 欄位是 DATE 類型）
    final startStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    
    final response = await _supabase
        .from('daily_workout_summary')
        .select(
            'scheduled_workout_count, workout_count, completed_workout_count, partial_workout_count, date')
        .eq('user_id', userId)
        .gte('date', startStr)
        .lte('date', endStr)
        .order('date', ascending: true);

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
        .gte('date', DateTimeUtils.formatToUtcIso(startDate).split('T')[0])
        .lte('date', DateTimeUtils.formatToUtcIso(endDate).split('T')[0])
        .order('date', ascending: true); // 明確指定升序：舊日期在左邊，新日期在右邊

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
        .gte('date', DateTimeUtils.formatToUtcIso(startDate).split('T')[0])
        .lte('date', DateTimeUtils.formatToUtcIso(endDate).split('T')[0]);

    return (response as List<dynamic>)
        .map((row) => row as Map<String, dynamic>)
        .toList();
  }

  /// 從彙總表查詢個人記錄
  ///
  /// ⚠️ 重要：使用 personal_records_top_by_body_part View
  /// 這個 View 自動過濾每個部位的最大重量記錄
  Future<List<Map<String, dynamic>>> getPersonalRecordsFromAggregation(
    String userId, {
    int limit = 20,
  }) async {
    final response = await _supabase
        .from('personal_records_top_by_body_part')
        .select('exercise_id, exercise_name, max_weight, max_reps, max_volume, '
            'achieved_date, workout_plan_id, body_part')
        .eq('user_id', userId)
        .order('max_weight', ascending: false)
        .limit(limit);

    return (response as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }

  /// 批量查詢動作信息（系統動作）
  Future<List<Map<String, dynamic>>> getExerciseInfo(
      List<String> exerciseIds) async {
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
