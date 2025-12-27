import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/body_data_record.dart';
import '../../../utils/firestore_id_generator.dart';

/// 身體數據操作模組
/// 
/// 負責執行身體數據的 CRUD 操作
class BodyDataOperations {
  final SupabaseClient _supabase;
  final void Function(String) _logDebug;
  final void Function(String, [Object?]) _logError;

  BodyDataOperations({
    required SupabaseClient supabase,
    required void Function(String) logDebug,
    required void Function(String, [Object?]) logError,
  })  : _supabase = supabase,
        _logDebug = logDebug,
        _logError = logError;

  /// 創建身體數據記錄
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

  /// 更新身體數據記錄
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

  /// 刪除身體數據記錄
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
}

