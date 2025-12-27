import '../../models/body_data_record.dart';

/// 身體數據緩存管理器
class BodyDataCacheManager {
  List<BodyDataRecord> _records = [];
  BodyDataRecord? _latestRecord;

  /// 緩存的身體數據記錄
  List<BodyDataRecord> get records => _records;

  /// 最新記錄
  BodyDataRecord? get latestRecord => _latestRecord;

  /// 是否有記錄
  bool get hasRecords => _records.isNotEmpty;

  /// 更新記錄緩存
  void updateRecordsCache(List<BodyDataRecord> records) {
    _records = records;
    
    // 同時更新最新記錄
    if (_records.isNotEmpty) {
      _latestRecord = _records.first; // 已按日期降序排列
    }
  }

  /// 更新最新記錄
  void updateLatestRecord(BodyDataRecord? record) {
    _latestRecord = record;
  }

  /// 更新緩存中的記錄
  void updateRecordInCache(String recordId, BodyDataRecord updatedRecord) {
    final index = _records.indexWhere((r) => r.id == recordId);
    if (index != -1) {
      _records[index] = updatedRecord;
    }
  }

  /// 從緩存中移除記錄
  void removeRecordFromCache(String recordId) {
    _records.removeWhere((r) => r.id == recordId);
  }

  /// 清除緩存
  void clearCache() {
    _records = [];
    _latestRecord = null;
  }
}

