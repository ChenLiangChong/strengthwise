import '../../services/interfaces/i_availability_slot_service.dart';
import 'availability_slot_state_manager.dart';

/// AvailabilitySlotQueryManager - 時段查詢管理器
///
/// 負責所有時段查詢邏輯
class AvailabilitySlotQueryManager {
  final IAvailabilitySlotService _slotService;
  final AvailabilitySlotStateManager _state;

  AvailabilitySlotQueryManager(
    this._slotService,
    this._state,
  );

  // ============================================================================
  // 查詢功能
  // ============================================================================

  /// 載入教練的所有時段
  Future<void> loadCoachSlots({
    required String coachId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _state.setQueryParams(
      startDate: startDate,
      endDate: endDate,
    );

    final slots = await _slotService.getCoachSlots(
      coachId: coachId,
      startDate: startDate,
      endDate: endDate,
    );

    _state.setSlots(slots);
  }

  /// 載入週期性時段和單次時段（分開）
  Future<void> loadSlotsByType(String coachId) async {
    final results = await Future.wait([
      _slotService.getRecurringSlots(coachId),
      _slotService.getOneTimeSlots(coachId),
    ]);

    _state.setRecurringSlots(results[0]);
    _state.setOneTimeSlots(results[1]);
  }

  /// 載入可預約時段（排除已被預約的）
  Future<void> loadAvailableSlots({
    required String coachId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _state.setQueryParams(
      startDate: startDate,
      endDate: endDate,
    );

    final availableSlots = await _slotService.getAvailableSlots(
      coachId: coachId,
      startDate: startDate,
      endDate: endDate,
    );

    _state.setAvailableSlots(availableSlots);
  }

  /// 查詢特定日期的時段
  Future<void> loadSlotsByDate({
    required String coachId,
    required DateTime date,
  }) async {
    final slots = await _slotService.getSlotsByDate(
      coachId: coachId,
      date: date,
    );

    _state.setSlots(slots);
  }

  /// 選擇時段（用於顯示詳情）
  Future<void> selectSlot(String slotId) async {
    final slot = await _slotService.getSlotById(slotId);
    _state.setSelectedSlot(slot);
  }

  /// 檢查時段是否已被預約
  Future<bool> checkSlotBooked(String slotId) async {
    return await _slotService.isSlotBooked(slotId);
  }
}

