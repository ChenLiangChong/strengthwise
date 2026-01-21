import 'package:flutter/foundation.dart';
import '../../models/body_data_record.dart';

/// 身體數據控制器接口
///
/// 遵循 MVVM 架構，處理身體數據相關業務邏輯
abstract class IBodyDataController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 身體數據記錄列表
  List<BodyDataRecord> get records;

  /// 最新記錄
  BodyDataRecord? get latestRecord;

  /// 載入中狀態
  bool get isLoading;

  /// 錯誤訊息
  String? get error;

  /// 是否有記錄
  bool get hasRecords;

  // ==================== 資料載入 ====================

  /// 載入用戶的身體數據記錄
  Future<void> loadRecords(String userId, {DateTime? startDate, DateTime? endDate});

  /// 載入最新記錄
  Future<void> loadLatestRecord(String userId);

  // ==================== CRUD 操作 ====================

  /// 創建新記錄（或更新當日記錄）
  ///
  /// 邏輯：
  /// - 如果當日已有記錄：更新現有記錄
  /// - 如果當日無記錄：新增記錄
  Future<bool> createRecord({
    required String userId,
    required DateTime recordDate,
    required double weight,
    double? bodyFat,
    double? muscleMass,
    double? heightCm,
    String? notes,
  });

  /// 更新記錄
  Future<bool> updateRecord(BodyDataRecord record, {double? heightCm});

  /// 刪除記錄
  Future<bool> deleteRecord(String recordId);

  // ==================== 查詢方法 ====================

  /// 獲取指定期間的平均體重
  Future<double?> getAverageWeight(String userId, DateTime startDate, DateTime endDate);

  // ==================== 狀態管理 ====================

  /// 清除錯誤訊息
  void clearError();
}
