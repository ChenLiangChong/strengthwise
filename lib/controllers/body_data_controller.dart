import 'package:flutter/foundation.dart';
import '../models/body_data_record.dart';
import '../services/interfaces/i_body_data_service.dart';
import '../services/interfaces/i_user_service.dart';
import '../services/error_handling_service.dart';

/// 身體數據控制器
/// 遵循 MVVM 架構，處理身體數據相關業務邏輯
class BodyDataController extends ChangeNotifier {
  final IBodyDataService _bodyDataService;
  final IUserService _userService;
  final ErrorHandlingService? _errorService;

  List<BodyDataRecord> _records = [];
  BodyDataRecord? _latestRecord;
  bool _isLoading = false;
  String? _error;

  BodyDataController({
    required IBodyDataService bodyDataService,
    required IUserService userService,
    ErrorHandlingService? errorService,
  })  : _bodyDataService = bodyDataService,
        _userService = userService,
        _errorService = errorService;

  // Getters
  List<BodyDataRecord> get records => _records;
  BodyDataRecord? get latestRecord => _latestRecord;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasRecords => _records.isNotEmpty;

  /// 載入用戶的身體數據記錄
  Future<void> loadRecords(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _records = await _bodyDataService.getUserRecords(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      // 同時更新最新記錄
      if (_records.isNotEmpty) {
        _latestRecord = _records.first; // 已按日期降序排列
      }

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
  Future<void> loadLatestRecord(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _latestRecord = await _bodyDataService.getLatestRecord(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '載入最新記錄失敗';
      _errorService?.logError('載入最新記錄失敗: $e', type: 'BodyDataControllerError');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 創建新記錄
  Future<bool> createRecord({
    required String userId,
    required DateTime recordDate,
    required double weight,
    double? bodyFat,
    double? muscleMass,
    double? heightCm, // 用於計算 BMI
    String? notes,
  }) async {
    try {
      // 計算 BMI（如果提供了身高）
      double? bmi;
      if (heightCm != null) {
        bmi = BodyDataRecord.calculateBMI(weight, heightCm);
      }

      final record = BodyDataRecord(
        id: '', // Service 層會生成
        userId: userId,
        recordDate: recordDate,
        weight: weight,
        bodyFat: bodyFat,
        muscleMass: muscleMass,
        bmi: bmi,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await _bodyDataService.createRecord(record);

      // 🆕 同步更新 users 表的體重（最新體重）
      try {
        await _userService.updateUserWeight(userId, weight);
      } catch (e) {
        _errorService?.logError('同步用戶體重失敗: $e', type: 'BodyDataControllerError');
        // 不影響主流程，繼續執行
      }

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
  Future<bool> updateRecord(BodyDataRecord record, {double? heightCm}) async {
    try {
      // 重新計算 BMI（如果提供了身高）
      BodyDataRecord updatedRecord = record;
      if (heightCm != null) {
        final bmi = BodyDataRecord.calculateBMI(record.weight, heightCm);
        updatedRecord = record.copyWith(bmi: bmi);
      }

      final success = await _bodyDataService.updateRecord(updatedRecord);
      if (success) {
        // 更新本地列表
        final index = _records.indexWhere((r) => r.id == record.id);
        if (index != -1) {
          _records[index] = updatedRecord;
          notifyListeners();
        }
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
  Future<bool> deleteRecord(String recordId) async {
    try {
      final success = await _bodyDataService.deleteRecord(recordId);
      if (success) {
        _records.removeWhere((r) => r.id == recordId);
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
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

