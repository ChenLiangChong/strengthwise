import 'package:flutter/foundation.dart';
import '../services/interfaces/i_client_availability_service.dart';
import '../services/core/error_handling_service.dart';
import '../services/core/app_event_bus.dart'; // ⭐ v3.5: EventBus
import '../models/client_availability_model.dart';
import 'event_bus_controller.dart'; // ⭐ v3.5: EventBus

/// ClientAvailabilityController - Phase 3 學員時間偏好控制器
///
/// 管理學員可運動時間的設定（雙向時間管理系統）
/// 學員設定可用時間，教練可查看並主動安排訓練
class ClientAvailabilityController extends ChangeNotifier {
  final IClientAvailabilityService _service;
  final ErrorHandlingService _errorService;
  final EventBusController _eventBusController; // ⭐ v3.5: EventBus

  ClientAvailabilityController(
    this._service,
    this._errorService,
    this._eventBusController, // ⭐ v3.5: EventBus
  );

  // ============================================================================
  // 狀態
  // ============================================================================

  bool _isLoading = false;
  String? _errorMessage;
  List<ClientAvailabilityModel> _availabilities = [];
  ClientAvailabilityModel? _selectedAvailability;

  // 統計資料
  int _totalCount = 0;
  int _preferredCount = 0;
  int _availableCount = 0;
  int _avoidCount = 0;

  // ============================================================================
  // Getters
  // ============================================================================

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ClientAvailabilityModel> get availabilities =>
      List.unmodifiable(_availabilities);
  ClientAvailabilityModel? get selectedAvailability => _selectedAvailability;

  // 統計資料
  int get totalCount => _totalCount;
  int get preferredCount => _preferredCount;
  int get availableCount => _availableCount;
  int get avoidCount => _avoidCount;

  // 衍生狀態
  bool get hasAvailabilities => _availabilities.isNotEmpty;
  bool get hasError => _errorMessage != null;

  /// 取得最佳時段
  List<ClientAvailabilityModel> get preferredSlots {
    return _availabilities
        .where((a) => a.priority == AvailabilityPriority.preferred)
        .toList();
  }

  /// 取得避免時段
  List<ClientAvailabilityModel> get avoidSlots {
    return _availabilities
        .where((a) => a.priority == AvailabilityPriority.avoid)
        .toList();
  }

  /// 取得週期性時段
  List<ClientAvailabilityModel> get recurringSlots {
    return _availabilities.where((a) => a.isRecurring).toList();
  }

  // ============================================================================
  // 查詢功能
  // ============================================================================

  /// 載入學員的時間偏好設定
  Future<void> loadClientAvailabilities({
    required String clientId,
    AvailabilityPriority? priority,
  }) async {
    await _executeOperation(() async {
      _availabilities = await _service.getClientAvailability(
        clientId: clientId,
        priority: priority,
      );

      // 計算統計資料
      _recalculateStats();
    }, '載入時間偏好失敗');
  }

  /// 載入指定日期範圍內的時間偏好
  Future<void> loadAvailabilitiesInRange({
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _executeOperation(() async {
      _availabilities = await _service.getAvailabilityInRange(
        clientId: clientId,
        startDate: startDate,
        endDate: endDate,
      );

      // 計算統計資料
      _recalculateStats();
    }, '載入時間偏好失敗');
  }

  /// 載入教練查看學員的時間偏好
  Future<void> loadClientAvailabilitiesForCoach({
    required String coachId,
    required String clientId,
  }) async {
    await _executeOperation(() async {
      _availabilities = await _service.getClientAvailabilityForCoach(
        coachId: coachId,
        clientId: clientId,
      );

      // 計算統計資料
      _recalculateStats();
    }, '載入時間偏好失敗');
  }

  /// 檢查時段衝突
  Future<bool> hasConflict({
    required String clientId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeId,
  }) async {
    bool conflict = false;

    await _executeOperation(() async {
      conflict = await _service.hasConflict(
        clientId: clientId,
        startTime: startTime,
        endTime: endTime,
        excludeId: excludeId,
      );
    }, '檢查衝突失敗');

    return conflict;
  }

  // ============================================================================
  // CRUD 功能
  // ============================================================================

  /// 創建時間偏好
  Future<ClientAvailabilityModel?> createAvailability(
    ClientAvailabilityModel availability,
  ) async {
    ClientAvailabilityModel? created;

    await _executeOperation(() async {
      created = await _service.createAvailability(availability);

      // 新增到列表
      _availabilities.insert(0, created!);
      _recalculateStats();

      // ⭐ v3.5: 發布可訓練時段創建事件
      _eventBusController.publish(AppEvent(
        type: AppEventType.availabilitySlotCreated,
        entityId: created!.id,
        userId: created!.clientId,
        timestamp: DateTime.now(),
      ));
    }, '創建時間偏好失敗');

    return created;
  }

  /// 更新時間偏好
  Future<ClientAvailabilityModel?> updateAvailability(
    ClientAvailabilityModel availability,
  ) async {
    ClientAvailabilityModel? updated;

    await _executeOperation(() async {
      updated = await _service.updateAvailability(availability);

      // 更新列表中的項目
      final index = _availabilities.indexWhere((a) => a.id == updated!.id);
      if (index != -1) {
        _availabilities[index] = updated!;
        _recalculateStats();
      }
    }, '更新時間偏好失敗');

    return updated;
  }

  /// 刪除時間偏好
  Future<bool> deleteAvailability(String id) async {
    bool success = false;

    await _executeOperation(() async {
      await _service.deleteAvailability(id);

      // 從列表中移除
      _availabilities.removeWhere((a) => a.id == id);
      _recalculateStats();

      // 如果是選中的項目，清除選中狀態
      if (_selectedAvailability?.id == id) {
        _selectedAvailability = null;
      }

      success = true;
    }, '刪除時間偏好失敗');

    return success;
  }

  /// 複製週時段
  /// 
  /// 將指定週的時段複製到目標週
  Future<int> copyWeekAvailabilities({
    required String clientId,
    required DateTime sourceWeekStart,
    required DateTime targetWeekStart,
  }) async {
    int copiedCount = 0;

    await _executeOperation(() async {
      // 計算週的結束日期
      final sourceWeekEnd = sourceWeekStart.add(const Duration(days: 7));

      // 載入來源週的時段
      final sourceSlots = await _service.getAvailabilityInRange(
        clientId: clientId,
        startDate: sourceWeekStart,
        endDate: sourceWeekEnd,
      );

      // 計算時間差（天數）
      final daysDiff = targetWeekStart.difference(sourceWeekStart).inDays;

      // 複製每個時段
      for (final slot in sourceSlots) {
        // 計算新的時間
        final newStartTime = slot.startTime.add(Duration(days: daysDiff));
        final newEndTime = slot.endTime.add(Duration(days: daysDiff));

        // 創建新時段
        final newSlot = ClientAvailabilityModel(
          id: '', // 會在 create 時生成
          clientId: clientId,
          startTime: newStartTime,
          endTime: newEndTime,
          priority: slot.priority,
          notes: slot.notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _service.createAvailability(newSlot);
        copiedCount++;
      }

      // 重新載入時段列表
      await loadClientAvailabilities(clientId: clientId);
    }, '複製週時段失敗');

    return copiedCount;
  }

  /// 批次創建週期性時段
  Future<List<ClientAvailabilityModel>> batchCreateRecurring({
    required ClientAvailabilityModel template,
    required List<DateTime> dates,
  }) async {
    List<ClientAvailabilityModel> created = [];

    await _executeOperation(() async {
      for (final date in dates) {
        // 計算該日期的開始和結束時間
        final duration = template.endTime.difference(template.startTime);
        final startTime = DateTime(
          date.year,
          date.month,
          date.day,
          template.startTime.hour,
          template.startTime.minute,
        );
        final endTime = startTime.add(duration);

        // 創建新時段
        final newAvailability = ClientAvailabilityModel(
          id: '', // Service 會自動生成
          clientId: template.clientId,
          startTime: startTime,
          endTime: endTime,
          recurrenceRule: template.recurrenceRule,
          priority: template.priority,
          notes: template.notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = await _service.createAvailability(newAvailability);
        created.add(result);
        _availabilities.insert(0, result);
      }

      _recalculateStats();
    }, '批次創建時段失敗');

    return created;
  }

  // ============================================================================
  // 狀態管理
  // ============================================================================

  /// 設定選中的時間偏好
  void setSelectedAvailability(ClientAvailabilityModel? availability) {
    _selectedAvailability = availability;
    notifyListeners();
  }

  /// 清除選中的時間偏好
  void clearSelectedAvailability() {
    _selectedAvailability = null;
    notifyListeners();
  }

  /// 清除錯誤訊息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 重置所有狀態
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _availabilities = [];
    _selectedAvailability = null;
    _totalCount = 0;
    _preferredCount = 0;
    _availableCount = 0;
    _avoidCount = 0;
    notifyListeners();
  }

  // ============================================================================
  // 內部輔助方法
  // ============================================================================

  /// 重新計算統計資料
  void _recalculateStats() {
    _totalCount = _availabilities.length;
    _preferredCount = _availabilities
        .where((a) => a.priority == AvailabilityPriority.preferred)
        .length;
    _availableCount = _availabilities
        .where((a) => a.priority == AvailabilityPriority.available)
        .length;
    _avoidCount = _availabilities
        .where((a) => a.priority == AvailabilityPriority.avoid)
        .length;
  }

  /// 執行操作（統一錯誤處理）
  Future<void> _executeOperation(
    Future<void> Function() operation,
    String errorMessage,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await operation();
    } catch (e) {
      final error = '$errorMessage: $e';
      _errorMessage = error;
      _errorService.logError(error, type: 'ClientAvailabilityControllerError');

      if (kDebugMode) {
        print('❌ [ClientAvailabilityController] $error');
      }

      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // ⭐ MVVM 重構：直接查詢方法（返回結果，不更新 Controller 狀態）
  // ============================================================================

  /// 查詢教練視角下學員的時間偏好（直接返回結果）
  /// ⭐ v3.6 MVVM 重構
  ///
  /// 用於行事曆頁面等需要直接獲取數據的場景
  Future<List<ClientAvailabilityModel>> getClientAvailabilityForCoach({
    required String coachId,
    required String clientId,
  }) async {
    try {
      return await _service.getClientAvailabilityForCoach(
        coachId: coachId,
        clientId: clientId,
      );
    } catch (e) {
      _errorService.logError(
        '查詢學員時間偏好失敗: $e',
        type: 'ClientAvailabilityControllerError',
      );
      return [];
    }
  }
}

