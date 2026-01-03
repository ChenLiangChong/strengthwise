import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/utils/datetime_utils.dart';
import '../../../models/body_data_record.dart';

/// 身體數據查詢模組
/// 
/// 負責執行身體數據的查詢操作
class BodyDataQuery {
  final SupabaseClient _supabase;
  final void Function(String) _logDebug;
  final void Function(String, [Object?]) _logError;

  BodyDataQuery({
    required SupabaseClient supabase,
    required void Function(String) logDebug,
    required void Function(String, [Object?]) logError,
  })  : _supabase = supabase,
        _logDebug = logDebug,
        _logError = logError;

  /// 查詢用戶的身體數據記錄
  /// 
  /// 🆕 自動去重：如果同一天有多筆記錄，只保留最新一筆（向後兼容舊數據）
  Future<List<BodyDataRecord>> getUserRecords({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      _logDebug('查詢身體數據記錄，userId: $userId');

      dynamic query = _supabase
          .from('body_data')
          .select()
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('record_date', DateTimeUtils.formatToUtcIso(startDate));
      }

      if (endDate != null) {
        query = query.lte('record_date', DateTimeUtils.formatToUtcIso(endDate));
      }

      query = query.order('record_date', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      final allRecords = (response as List)
          .map((json) => BodyDataRecord.fromSupabase(json))
          .toList();

      // 🆕 去重：同一天只保留最新一筆（created_at 最晚）
      final Map<String, BodyDataRecord> uniqueRecordsByDate = {};
      for (var record in allRecords) {
        final dateKey = '${record.recordDate.year}-${record.recordDate.month.toString().padLeft(2, '0')}-${record.recordDate.day.toString().padLeft(2, '0')}';
        
        if (!uniqueRecordsByDate.containsKey(dateKey)) {
          uniqueRecordsByDate[dateKey] = record;
        } else {
          // 如果同一天有多筆，保留 created_at 較晚的那筆
          final existing = uniqueRecordsByDate[dateKey]!;
          if (record.createdAt.isAfter(existing.createdAt)) {
            uniqueRecordsByDate[dateKey] = record;
          }
        }
      }

      final records = uniqueRecordsByDate.values.toList()
        ..sort((a, b) => b.recordDate.compareTo(a.recordDate)); // 按日期降序排列

      _logDebug('✅ 成功查詢 ${records.length} 筆身體數據記錄（已去重，原始 ${allRecords.length} 筆）');
      return records;
    } catch (e) {
      _logError('查詢身體數據記錄失敗', e);
      return [];
    }
  }

  /// 查詢最新的身體數據記錄
  Future<BodyDataRecord?> getLatestRecord(String userId) async {
    try {
      _logDebug('查詢最新身體數據記錄，userId: $userId');

      final response = await _supabase
          .from('body_data')
          .select()
          .eq('user_id', userId)
          .order('record_date', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        _logDebug('未找到身體數據記錄');
        return null;
      }

      final record = BodyDataRecord.fromSupabase(response[0]);
      _logDebug('✅ 成功查詢最新身體數據記錄');
      return record;
    } catch (e) {
      _logError('查詢最新身體數據記錄失敗', e);
      return null;
    }
  }

  /// 🆕 查詢指定日期的身體數據記錄
  /// 
  /// 用於實現"每日一筆數據"邏輯
  Future<BodyDataRecord?> getRecordByDate(String userId, DateTime date) async {
    try {
      // 將日期轉換為當天的起始和結束時間
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      _logDebug('查詢 ${startOfDay.toString().split(' ')[0]} 的身體數據');

      final response = await _supabase
          .from('body_data')
          .select()
          .eq('user_id', userId)
          .gte('record_date', DateTimeUtils.formatToUtcIso(startOfDay))
          .lte('record_date', DateTimeUtils.formatToUtcIso(endOfDay))
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        _logDebug('當日無身體數據記錄');
        return null;
      }

      final record = BodyDataRecord.fromSupabase(response[0]);
      _logDebug('✅ 找到當日身體數據記錄: ${record.id}');
      return record;
    } catch (e) {
      _logError('查詢指定日期身體數據失敗', e);
      return null;
    }
  }
}

