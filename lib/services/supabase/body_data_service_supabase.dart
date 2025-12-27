import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/body_data_record.dart';
import '../interfaces/i_body_data_service.dart';
import '../core/error_handling_service.dart';
import 'body_data/body_data_operations.dart';
import 'body_data/body_data_query.dart';
import 'body_data/body_data_calculator.dart';

/// 身體數據服務 Supabase 實作
/// 
/// 提供身體數據的 CRUD 操作和統計計算功能
class BodyDataServiceSupabase implements IBodyDataService {
  final SupabaseClient _supabase;
  final ErrorHandlingService? _errorService;

  // 子模組（各司其職）
  late final BodyDataOperations _operations;
  late final BodyDataQuery _query;
  late final BodyDataCalculator _calculator;

  BodyDataServiceSupabase({
    SupabaseClient? supabase,
    ErrorHandlingService? errorService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _errorService = errorService {
    // 初始化子模組
    _operations = BodyDataOperations(
      supabase: _supabase,
      logDebug: _logDebug,
      logError: _logError,
    );
    _query = BodyDataQuery(
      supabase: _supabase,
      logDebug: _logDebug,
      logError: _logError,
    );
    _calculator = BodyDataCalculator(
      logDebug: _logDebug,
      logError: _logError,
    );
  }

  @override
  Future<BodyDataRecord> createRecord(BodyDataRecord record) async {
    return await _operations.createRecord(record);
  }

  @override
  Future<bool> updateRecord(BodyDataRecord record) async {
    return await _operations.updateRecord(record);
  }

  @override
  Future<bool> deleteRecord(String recordId) async {
    return await _operations.deleteRecord(recordId);
  }

  @override
  Future<List<BodyDataRecord>> getUserRecords({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    return await _query.getUserRecords(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  @override
  Future<BodyDataRecord?> getLatestRecord(String userId) async {
    return await _query.getLatestRecord(userId);
  }

  @override
  Future<double?> getAverageWeight({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _logDebug('計算平均體重，userId: $userId');

    final records = await _query.getUserRecords(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    return await _calculator.calculateAverageWeight(records);
  }

  /// 記錄調試信息
  void _logDebug(String message) {
    print('[BODY_DATA_SERVICE] $message');
  }

  /// 記錄錯誤信息
  void _logError(String message, [Object? error]) {
    print('[BODY_DATA_SERVICE ERROR] $message${error != null ? ": $error" : ""}');
    _errorService?.logError(message, type: 'BodyDataServiceError');
  }
}

