import 'package:flutter/foundation.dart';
import '../models/body_data_record.dart';
import '../services/interfaces/i_body_data_service.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/core/error_handling_service.dart';
import 'body_data/body_data_cache_manager.dart';
import 'body_data/body_data_operation_helper.dart';
import 'interfaces/i_event_bus_controller.dart'; // ⭐ v3.5
import 'interfaces/i_body_data_controller.dart';

/// 身體數據控制器
/// 遵循 MVVM 架構，處理身體數據相關業務邏輯
/// ⭐ v3.5: 統一發布身體數據事件（Controller 層負責事件發布）
class BodyDataController extends ChangeNotifier implements IBodyDataController {
  final IBodyDataService _bodyDataService;
  final IUserService _userService;
  final ErrorHandlingService? _errorService;
  final IEventBusController _eventBusController; // ⭐ v3.5

  // 子模組
  late final BodyDataCacheManager _cacheManager;

  bool _isLoading = false;
  String? _error;

  BodyDataController({
    required IBodyDataService bodyDataService,
    required IUserService userService,
    ErrorHandlingService? errorService,
    required IEventBusController eventBusController, // ⭐ v3.5
  })  : _bodyDataService = bodyDataService,
        _userService = userService,
        _errorService = errorService,
        _eventBusController = eventBusController {
    // 初始化子模組
    _cacheManager = BodyDataCacheManager();
  }

  // Getters
  @override
  List<BodyDataRecord> get records => _cacheManager.records;
  @override
  BodyDataRecord? get latestRecord => _cacheManager.latestRecord;
  @override
  bool get isLoading => _isLoading;
  @override
  String? get error => _error;
  @override
  bool get hasRecords => _cacheManager.hasRecords;

  /// 載入用戶的身體數據記錄
  @override
  Future<void> loadRecords(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final records = await _bodyDataService.getUserRecords(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      // 使用緩存管理器更新緩存
      _cacheManager.updateRecordsCache(records);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '載入身體數據失敗';
      _errorService?.logError('載入身體數據失敗: $e', type: 'BodyDataControllerError');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 載入最新記錄
  @override
  Future<void> loadLatestRecord(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final latestRecord = await _bodyDataService.getLatestRecord(userId);
      
      // 使用緩存管理器更新最新記錄
      _cacheManager.updateLatestRecord(latestRecord);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '載入最新記錄失敗';
      _errorService?.logError('載入最新記錄失敗: $e', type: 'BodyDataControllerError');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 創建新記錄（或更新當日記錄）
  /// 
  /// 🆕 邏輯：
  /// - 如果當日已有記錄：更新現有記錄
  /// - 如果當日無記錄：新增記錄
  @override
  Future<bool> createRecord({
    required String userId,
    required DateTime recordDate,
    required double weight,
    double? bodyFat,
    double? muscleMass,
    double? heightCm,
    String? notes,
  }) async {
    try {
      // 🆕 檢查當日是否已有記錄
      final existingRecord = await _bodyDataService.getRecordByDate(userId, recordDate);

      if (existingRecord != null) {
        // 當日已有記錄：更新
        _errorService?.logError('當日已有記錄，將更新現有記錄: ${existingRecord.id}', type: 'BodyDataControllerInfo');
        
        final updatedRecord = existingRecord.copyWith(
          weight: weight,
          bodyFat: bodyFat,
          muscleMass: muscleMass,
          bmi: heightCm != null ? BodyDataRecord.calculateBMI(weight, heightCm) : existingRecord.bmi,
          notes: notes,
          recordDate: recordDate, // 更新時間
        );

        final success = await _bodyDataService.updateRecord(updatedRecord);
        
        if (success) {
          // 同步更新 users 表的體重
          try {
            await _userService.updateUserWeight(userId, weight);
          } catch (e) {
            _errorService?.logError('同步用戶體重失敗: $e', type: 'BodyDataControllerError');
          }

          // ⭐ v3.5: 發布身體數據更新事件
          _eventBusController.publishBodyDataUpdated(userId: userId);

          // 重新載入數據
          await loadRecords(userId);
        }
        
        return success;
      }

      // 當日無記錄：新增
      final record = BodyDataOperationHelper.createRecord(
        userId: userId,
        recordDate: recordDate,
        weight: weight,
        bodyFat: bodyFat,
        muscleMass: muscleMass,
        heightCm: heightCm,
        notes: notes,
      );

      await _bodyDataService.createRecord(record);

      // 同步更新 users 表的體重（最新體重）
      try {
        await _userService.updateUserWeight(userId, weight);
      } catch (e) {
        _errorService?.logError('同步用戶體重失敗: $e', type: 'BodyDataControllerError');
        // 不影響主流程，繼續執行
      }

      // ⭐ v3.5: 發布身體數據更新事件
      _eventBusController.publishBodyDataUpdated(userId: userId);

      // 重新載入數據
      await loadRecords(userId);

      return true;
    } catch (e) {
      _error = '創建記錄失敗';
      _errorService?.logError('創建記錄失敗: $e', type: 'BodyDataControllerError');
      notifyListeners();
      return false;
    }
  }

  /// 更新記錄
  /// ⭐ v3.5: 操作成功後自動發布事件
  @override
  Future<bool> updateRecord(BodyDataRecord record, {double? heightCm}) async {
    try {
      // 使用助手類重新計算 BMI
      final updatedRecord = BodyDataOperationHelper.updateRecord(record, heightCm: heightCm);

      final success = await _bodyDataService.updateRecord(updatedRecord);
      if (success) {
        // 使用緩存管理器更新本地列表
        _cacheManager.updateRecordInCache(record.id, updatedRecord);

        // ⭐ v3.5: 發布身體數據更新事件
        _eventBusController.publishBodyDataUpdated(userId: record.userId);

        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = '更新記錄失敗';
      _errorService?.logError('更新記錄失敗: $e', type: 'BodyDataControllerError');
      notifyListeners();
      return false;
    }
  }

  /// 刪除記錄
  /// ⭐ v3.5: 操作成功後自動發布事件
  @override
  Future<bool> deleteRecord(String recordId) async {
    try {
      // ⭐ v3.5: 先取得 userId 用於發布事件
      final recordToDelete = _cacheManager.records.firstWhere(
        (r) => r.id == recordId,
        orElse: () => throw Exception('記錄不存在'),
      );
      final userId = recordToDelete.userId;

      final success = await _bodyDataService.deleteRecord(recordId);
      if (success) {
        // 使用緩存管理器從本地列表中移除
        _cacheManager.removeRecordFromCache(recordId);

        // ⭐ v3.5: 發布身體數據更新事件
        _eventBusController.publishBodyDataUpdated(userId: userId);

        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = '刪除記錄失敗';
      _errorService?.logError('刪除記錄失敗: $e', type: 'BodyDataControllerError');
      notifyListeners();
      return false;
    }
  }

  /// 獲取指定期間的平均體重
  @override
  Future<double?> getAverageWeight(String userId, DateTime startDate, DateTime endDate) async {
    try {
      return await _bodyDataService.getAverageWeight(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorService?.logError('計算平均體重失敗: $e', type: 'BodyDataControllerError');
      return null;
    }
  }

  /// 清除錯誤訊息
  @override
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

