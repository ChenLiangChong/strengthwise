import '../../services/interfaces/i_availability_slot_service.dart';
import '../../models/availability_slot_model.dart';

/// AvailabilitySlotBatchOperations - 時段批量操作管理器
///
/// 負責批量時段操作（批量創建、複製週時段等）
class AvailabilitySlotBatchOperations {
  final IAvailabilitySlotService _slotService;

  AvailabilitySlotBatchOperations(this._slotService);

  // ============================================================================
  // 批量操作
  // ============================================================================

  /// 批量創建時段
  Future<List<String>> createBatchSlots(List<AvailabilitySlotModel> slots) async {
    final slotIds = await _slotService.createSlotsBatch(slots);
    return slotIds;
  }

  /// 複製一週的時段到下一週
  Future<List<String>> copyWeekSlots({
    required String coachId,
    required DateTime sourceWeekStart,
    required DateTime targetWeekStart,
  }) async {
    final slotIds = await _slotService.copyWeekSlots(
      coachId: coachId,
      sourceWeekStart: sourceWeekStart,
      targetWeekStart: targetWeekStart,
    );

    return slotIds;
  }
}

