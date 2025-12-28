import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import '../services/interfaces/i_availability_slot_service.dart';
import '../services/core/error_handling_service.dart';
import '../models/availability_slot_model.dart';
import 'availability_slot/availability_slot_state_manager.dart';
import 'availability_slot/availability_slot_query_manager.dart';
import 'availability_slot/availability_slot_operations.dart';
import 'availability_slot/availability_slot_batch_operations.dart';

/// AvailabilitySlotController - Phase 2 時段管理控制器
///
/// 管理教練的可用時段設定、查詢、修改等業務邏輯
/// 遵循完全解耦架構（透過 Interface 注入依賴）+ 子模組化設計
class AvailabilitySlotController extends ChangeNotifier {
  final IAvailabilitySlotService _slotService;
  final ErrorHandlingService _errorService;

  // 子模組
  late final AvailabilitySlotStateManager _state;
  late final AvailabilitySlotQueryManager _query;
  late final AvailabilitySlotOperations _operations;
  late final AvailabilitySlotBatchOperations _batchOps;

  AvailabilitySlotController(
    this._slotService,
    this._errorService,
  ) {
    _state = AvailabilitySlotStateManager();
    _query = AvailabilitySlotQueryManager(_slotService, _state);
    _operations = AvailabilitySlotOperations(_slotService, _state);
    _batchOps = AvailabilitySlotBatchOperations(_slotService);

    // 監聽狀態變化並通知 UI
    _state.addListener(notifyListeners);
  }

  // ============================================================================
  // 狀態訪問（委託給 StateManager）
  // ============================================================================

  bool get isLoading => _state.isLoading;
  String? get errorMessage => _state.errorMessage;
  List<AvailabilitySlotModel> get slots => _state.slots;
  List<AvailabilitySlotModel> get recurringSlots => _state.recurringSlots;
  List<AvailabilitySlotModel> get oneTimeSlots => _state.oneTimeSlots;
  List<AvailabilitySlotWithBooking> get availableSlots => _state.availableSlots;
  AvailabilitySlotModel? get selectedSlot => _state.selectedSlot;
  DateTime? get queryStartDate => _state.queryStartDate;
  DateTime? get queryEndDate => _state.queryEndDate;

  // ============================================================================
  // 教練端功能 - 查詢（委託給子模組）
  // ============================================================================

  /// 載入教練的所有時段
  Future<void> loadCoachSlots(
    String coachId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _executeOperation(
      () => _query.loadCoachSlots(
        coachId: coachId,
        startDate: startDate,
        endDate: endDate,
      ),
      '載入時段列表失敗',
    );
  }

  /// 載入週期性時段和單次時段（分開）
  Future<void> loadSlotsByType(String coachId) async {
    await _executeOperation(
      () => _query.loadSlotsByType(coachId),
      '載入時段失敗',
    );
  }

  /// 查詢特定日期的時段
  Future<void> loadSlotsByDate({
    required String coachId,
    required DateTime date,
  }) async {
    await _executeOperation(
      () => _query.loadSlotsByDate(coachId: coachId, date: date),
      '載入當日時段失敗',
    );
  }

  /// 選擇時段（用於顯示詳情）
  Future<void> selectSlot(String slotId) async {
    _state.clearError();
    try {
      await _query.selectSlot(slotId);
    } catch (e) {
      _handleError('載入時段詳情失敗', e);
    }
  }

  /// 清除選中的時段
  void clearSelectedSlot() {
    _state.setSelectedSlot(null);
  }

  /// 檢查時段是否已被預約
  Future<bool> checkSlotBooked(String slotId) async {
    try {
      return await _query.checkSlotBooked(slotId);
    } catch (e) {
      _errorService.logError(
        '檢查時段預約狀態失敗: $e',
        type: 'AvailabilitySlotControllerError',
      );
      return false;
    }
  }

  // ============================================================================
  // 教練端功能 - 創建（委託給子模組）
  // ============================================================================

  /// 從 UI 數據創建單次時段
  /// 
  /// 此方法接收 UI 層的原始數據，封裝業務邏輯
  Future<bool> createSingleSlotFromUI({
    required String coachId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? notes,
  }) async {
    _state.clearError();
    try {
      return await _operations.createSingleSlotFromUI(
        coachId: coachId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        notes: notes,
      );
    } catch (e) {
      _handleError('創建時段失敗', e);
      return false;
    }
  }

  /// 從 UI 數據創建週期性時段
  /// 
  /// 此方法接收 UI 層的原始數據，封裝 RRULE 生成邏輯
  Future<bool> createRecurringSlotFromUI({
    required String coachId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String recurrenceType, // 'weekly' or 'daily'
    String? notes,
  }) async {
    _state.clearError();
    try {
      return await _operations.createRecurringSlotFromUI(
        coachId: coachId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        recurrenceType: recurrenceType,
        notes: notes,
      );
    } catch (e) {
      _handleError('創建週期性時段失敗', e);
      return false;
    }
  }

  /// 創建單次時段（原始方法）
  Future<bool> createSlot(AvailabilitySlotModel slot) async {
    return await _executeOperation(() async {
      await _operations.createSlot(slot);
      // 重新載入時段列表
      await _query.loadCoachSlots(coachId: slot.coachId);
    }, '創建時段失敗');
  }

  /// 創建週期性時段
  Future<bool> createRecurringSlot({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    required String recurrenceRule,
    String? notes,
  }) async {
    return await _executeOperation(() async {
      await _operations.createRecurringSlots(
        coachId: coachId,
        startTime: startTime,
        endTime: endTime,
        recurrenceRule: recurrenceRule,
        notes: notes,
      );
      // 重新載入時段列表
      await _query.loadCoachSlots(coachId: coachId);
    }, '創建週期性時段失敗');
  }

  /// 創建覆蓋時段（如休假日）
  Future<bool> createOverrideSlot({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    required String notes,
  }) async {
    return await _executeOperation(() async {
      await _operations.createOverrideSlot(
        coachId: coachId,
        startTime: startTime,
        endTime: endTime,
        notes: notes,
      );
      // 重新載入時段列表
      await _query.loadCoachSlots(coachId: coachId);
    }, '創建覆蓋時段失敗');
  }

  // ============================================================================
  // 教練端功能 - 更新與刪除（委託給子模組）
  // ============================================================================

  /// 更新時段
  Future<bool> updateSlot(
    String slotId,
    AvailabilitySlotModel slot,
  ) async {
    return await _executeOperation(() async {
      await _operations.updateSlot(slotId: slotId, slot: slot);
      // 重新載入該教練的時段
      await _query.loadCoachSlots(coachId: slot.coachId);
    }, '更新時段失敗');
  }

  /// 刪除時段
  Future<bool> deleteSlot(String slotId) async {
    return await _executeOperation(() async {
      // 先獲取時段資訊（用於重新載入）
      final slot = _state.slots.firstWhere((s) => s.id == slotId);
      await _operations.deleteSlot(slotId);
      // 重新載入時段列表
      await _query.loadCoachSlots(coachId: slot.coachId);
    }, '刪除時段失敗');
  }

  /// 批量刪除時段
  Future<int> deleteSlotsBatch(List<String> slotIds) async {
    _state.setLoading(true);
    _state.clearError();

    try {
      final count = await _operations.deleteSlots(slotIds);
      return count;
    } catch (e) {
      _handleError('批量刪除時段失敗', e);
      return 0;
    } finally {
      _state.setLoading(false);
    }
  }

  /// 刪除覆蓋時段
  Future<bool> deleteOverrideSlot(String slotId) async {
    return await _executeOperation(
      () => _operations.deleteOverrideSlot(slotId),
      '刪除覆蓋時段失敗',
    );
  }

  /// 刪除特定週的所有時段
  Future<int> deleteWeekSlots({
    required String coachId,
    required DateTime weekStart,
  }) async {
    _state.setLoading(true);
    _state.clearError();

    try {
      final count = await _operations.deleteWeekSlots(
        coachId: coachId,
        weekStart: weekStart,
      );
      // 重新載入時段列表
      await _query.loadCoachSlots(coachId: coachId);
      return count;
    } catch (e) {
      _handleError('刪除週時段失敗', e);
      return 0;
    } finally {
      _state.setLoading(false);
    }
  }

  // ============================================================================
  // 學員端功能 - 查看可預約時段（委託給子模組）
  // ============================================================================

  /// 載入可預約時段（排除已被預約的）
  Future<void> loadAvailableSlots({
    required String coachId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _executeOperation(
      () => _query.loadAvailableSlots(
        coachId: coachId,
        startDate: startDate,
        endDate: endDate,
      ),
      '載入可預約時段失敗',
    );
  }

  // ============================================================================
  // 批量操作（委託給子模組）
  // ============================================================================

  /// 批量創建時段
  Future<int> createBatchSlots(List<AvailabilitySlotModel> slots) async {
    _state.setLoading(true);
    _state.clearError();

    try {
      final slotIds = await _batchOps.createBatchSlots(slots);
      // 重新載入時段列表
      if (slots.isNotEmpty) {
        await _query.loadCoachSlots(coachId: slots.first.coachId);
      }
      return slotIds.length;
    } catch (e) {
      _handleError('批量創建時段失敗', e);
      return 0;
    } finally {
      _state.setLoading(false);
    }
  }

  /// 複製一週的時段到下一週
  Future<int> copyWeekSlots({
    required String coachId,
    required DateTime sourceWeekStart,
    required DateTime targetWeekStart,
  }) async {
    _state.setLoading(true);
    _state.clearError();

    try {
      final slotIds = await _batchOps.copyWeekSlots(
        coachId: coachId,
        sourceWeekStart: sourceWeekStart,
        targetWeekStart: targetWeekStart,
      );
      // 重新載入時段列表
      await _query.loadCoachSlots(coachId: coachId);
      return slotIds.length;
    } catch (e) {
      _handleError('複製週時段失敗', e);
      return 0;
    } finally {
      _state.setLoading(false);
    }
  }

  // ============================================================================
  // 輔助方法
  // ============================================================================

  /// 統一的操作執行包裝器
  Future<bool> _executeOperation(
    Future<void> Function() operation,
    String errorMessage,
  ) async {
    _state.setLoading(true);
    _state.clearError();

    try {
      await operation();
      return true;
    } catch (e) {
      _handleError(errorMessage, e);
      return false;
    } finally {
      _state.setLoading(false);
    }
  }

  /// 錯誤處理
  void _handleError(String message, dynamic error) {
    _state.setError(message);
    _errorService.logError(
      '$message: $error',
      type: 'AvailabilitySlotControllerError',
    );

    if (kDebugMode) {
      print('❌ AvailabilitySlotController Error: $message - $error');
    }
  }

  /// 清除所有狀態
  void clearAll() {
    _state.clearAll();
  }

  @override
  void dispose() {
    _state.removeListener(notifyListeners);
    _state.dispose();
    super.dispose();
  }
}

