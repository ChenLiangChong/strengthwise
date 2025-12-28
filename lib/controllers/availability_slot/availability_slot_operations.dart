import 'package:flutter/material.dart';
import '../../services/interfaces/i_availability_slot_service.dart';
import '../../models/availability_slot_model.dart';
import 'availability_slot_state_manager.dart';

/// AvailabilitySlotOperations - 時段操作管理器
///
/// 負責時段的創建、更新、刪除操作
class AvailabilitySlotOperations {
  final IAvailabilitySlotService _slotService;
  final AvailabilitySlotStateManager _state;

  AvailabilitySlotOperations(
    this._slotService,
    this._state,
  );

  // ============================================================================
  // 創建操作（從 UI 數據）
  // ============================================================================

  /// 從 UI 數據創建單次時段
  /// 
  /// 此方法封裝了 UI 層的原始數據（date, TimeOfDay）到 Model 的轉換邏輯
  Future<bool> createSingleSlotFromUI({
    required String coachId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? notes,
  }) async {
    // 1. 組合日期和時間
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    // 2. 驗證時間合法性
    if (endDateTime.isBefore(startDateTime) || 
        endDateTime.isAtSameMomentAs(startDateTime)) {
      _state.setError('結束時間必須晚於開始時間');
      return false;
    }

    // 3. 創建 Model
    final slot = AvailabilitySlotModel(
      id: '', // 由資料庫生成
      coachId: coachId,
      startTime: startDateTime,
      endTime: endDateTime,
      recurrenceRule: null,
      isOverride: false,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 4. 調用 Service 層
    try {
      _state.setLoading(true);
      final slotId = await createSlot(slot);
      _state.setLoading(false);
      return slotId.isNotEmpty;
    } catch (e) {
      _state.setError('創建時段失敗: $e');
      _state.setLoading(false);
      return false;
    }
  }

  /// 從 UI 數據創建週期性時段
  /// 
  /// 此方法封裝了 RRULE 生成邏輯
  Future<bool> createRecurringSlotFromUI({
    required String coachId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String recurrenceType, // 'weekly' or 'daily'
    String? notes,
  }) async {
    // 1. 組合日期和時間
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    // 2. 驗證時間合法性
    if (endDateTime.isBefore(startDateTime) || 
        endDateTime.isAtSameMomentAs(startDateTime)) {
      _state.setError('結束時間必須晚於開始時間');
      return false;
    }

    // 3. 生成 RRULE
    final recurrenceRule = recurrenceType == 'daily'
        ? 'FREQ=DAILY'
        : 'FREQ=WEEKLY;BYDAY=${_getDayOfWeek(startDateTime)}';

    // 4. 調用 Service 層
    try {
      _state.setLoading(true);
      final slotIds = await createRecurringSlots(
        coachId: coachId,
        startTime: startDateTime,
        endTime: endDateTime,
        recurrenceRule: recurrenceRule,
        notes: notes,
      );
      _state.setLoading(false);
      return slotIds.isNotEmpty;
    } catch (e) {
      _state.setError('創建週期性時段失敗: $e');
      _state.setLoading(false);
      return false;
    }
  }

  /// 獲取星期幾的縮寫（iCal RRULE 格式）
  /// 
  /// MO=Monday, TU=Tuesday, WE=Wednesday, TH=Thursday, 
  /// FR=Friday, SA=Saturday, SU=Sunday
  String _getDayOfWeek(DateTime date) {
    const days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return days[date.weekday - 1];
  }

  // ============================================================================
  // 創建操作（原始方法，供內部使用）
  // ============================================================================

  /// 創建單次時段
  Future<String> createSlot(AvailabilitySlotModel slot) async {
    final slotId = await _slotService.createSlot(slot);
    return slotId;
  }

  /// 創建週期性時段
  Future<List<String>> createRecurringSlots({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    required String recurrenceRule,
    String? notes,
  }) async {
    final slotIds = await _slotService.createRecurringSlots(
      coachId: coachId,
      startTime: startTime,
      endTime: endTime,
      recurrenceRule: recurrenceRule,
      notes: notes,
    );

    return slotIds;
  }

  /// 創建覆蓋時段（如休假日）
  Future<String> createOverrideSlot({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    required String notes,
  }) async {
    final slotId = await _slotService.createOverrideSlot(
      coachId: coachId,
      startTime: startTime,
      endTime: endTime,
      notes: notes,
    );

    return slotId;
  }

  // ============================================================================
  // 更新操作
  // ============================================================================

  /// 更新時段
  Future<void> updateSlot({
    required String slotId,
    required AvailabilitySlotModel slot,
  }) async {
    await _slotService.updateSlot(
      slotId: slotId,
      slot: slot,
    );
  }

  // ============================================================================
  // 刪除操作
  // ============================================================================

  /// 刪除時段
  Future<void> deleteSlot(String slotId) async {
    await _slotService.deleteSlot(slotId);
    _state.removeSlot(slotId);
  }

  /// 批量刪除時段
  Future<int> deleteSlots(List<String> slotIds) async {
    final count = await _slotService.deleteSlots(slotIds);
    _state.removeSlots(slotIds);
    return count;
  }

  /// 刪除覆蓋時段
  Future<void> deleteOverrideSlot(String slotId) async {
    await _slotService.deleteOverrideSlot(slotId);
    _state.removeSlot(slotId);
  }

  /// 刪除特定週的所有時段
  Future<int> deleteWeekSlots({
    required String coachId,
    required DateTime weekStart,
  }) async {
    final count = await _slotService.deleteWeekSlots(
      coachId: coachId,
      weekStart: weekStart,
    );

    return count;
  }
}

