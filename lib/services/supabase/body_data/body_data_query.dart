import 'package:supabase_flutter/supabase_flutter.dart';
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
        query = query.gte('record_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('record_date', endDate.toIso8601String());
      }

      query = query.order('record_date', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      final records = (response as List)
          .map((json) => BodyDataRecord.fromSupabase(json))
          .toList();

      _logDebug('✅ 成功查詢 ${records.length} 筆身體數據記錄');
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
}

