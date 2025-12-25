import '../../models/body_data_record.dart';

/// 身體數據服務介面
/// 遵循依賴反轉原則（Dependency Inversion Principle）
abstract class IBodyDataService {
  /// 創建身體數據記錄
  Future<BodyDataRecord> createRecord(BodyDataRecord record);

  /// 更新身體數據記錄
  Future<bool> updateRecord(BodyDataRecord record);

  /// 刪除身體數據記錄
  Future<bool> deleteRecord(String recordId);

  /// 獲取用戶的所有身體數據記錄（按日期排序）
  Future<List<BodyDataRecord>> getUserRecords({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  /// 獲取最新的身體數據記錄
  Future<BodyDataRecord?> getLatestRecord(String userId);

  /// 獲取指定日期範圍的平均體重
  Future<double?> getAverageWeight({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
}

