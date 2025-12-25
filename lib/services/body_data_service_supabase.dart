import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/body_data_record.dart';
import 'interfaces/i_body_data_service.dart';
import 'error_handling_service.dart';
import '../utils/firestore_id_generator.dart';

/// 身體數據服務 Supabase 實作
class BodyDataServiceSupabase implements IBodyDataService {
  final SupabaseClient _supabase;
  final ErrorHandlingService? _errorService;

  BodyDataServiceSupabase({
    SupabaseClient? supabase,
    ErrorHandlingService? errorService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _errorService = errorService;

  void _logDebug(String message) {
    print('[BODY_DATA_SERVICE] $message');
  }

  void _logError(String message, [Object? error]) {
    print('[BODY_DATA_SERVICE ERROR] $message${error != null ? ": $error" : ""}');
    _errorService?.logError(message, type: 'BodyDataServiceError');
  }

  @override
  Future<BodyDataRecord> createRecord(BodyDataRecord record) async {
    try {
      _logDebug('創建身體數據記錄');

      // 生成 Firestore 相容 ID（20 字符）
      final id = generateFirestoreId();

      final data = {
        'id': id,
        'user_id': record.userId,
        'record_date': record.recordDate.toIso8601String(),
        'weight': record.weight,
        'body_fat': record.bodyFat,
        'muscle_mass': record.muscleMass,
        'bmi': record.bmi,
        'notes': record.notes,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('body_data').insert(data);

      _logDebug('✅ 成功創建身體數據記錄');
      return record.copyWith();
    } catch (e) {
      _logError('創建身體數據記錄失敗', e);
      rethrow;
    }
  }

  @override
  Future<bool> updateRecord(BodyDataRecord record) async {
    try {
      _logDebug('更新身體數據記錄: ${record.id}');

      final data = {
        'weight': record.weight,
        'body_fat': record.bodyFat,
        'muscle_mass': record.muscleMass,
        'bmi': record.bmi,
        'notes': record.notes,
        'record_date': record.recordDate.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('body_data')
          .update(data)
          .eq('id', record.id);

      _logDebug('✅ 成功更新身體數據記錄');
      return true;
    } catch (e) {
      _logError('更新身體數據記錄失敗', e);
      return false;
    }
  }

  @override
  Future<bool> deleteRecord(String recordId) async {
    try {
      _logDebug('刪除身體數據記錄: $recordId');

      await _supabase
          .from('body_data')
          .delete()
          .eq('id', recordId);

      _logDebug('✅ 成功刪除身體數據記錄');
      return true;
    } catch (e) {
      _logError('刪除身體數據記錄失敗', e);
      return false;
    }
  }

  @override
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

  @override
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

  @override
  Future<double?> getAverageWeight({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _logDebug('計算平均體重，userId: $userId');

      final records = await getUserRecords(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (records.isEmpty) {
        return null;
      }

      final totalWeight = records.fold<double>(
        0,
        (sum, record) => sum + record.weight,
      );

      final average = totalWeight / records.length;
      _logDebug('✅ 平均體重: ${average.toStringAsFixed(1)} kg');
      return average;
    } catch (e) {
      _logError('計算平均體重失敗', e);
      return null;
    }
  }
}

