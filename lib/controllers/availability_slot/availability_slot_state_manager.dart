import 'package:flutter/foundation.dart';
import '../../models/availability_slot_model.dart';
import '../../services/interfaces/i_availability_slot_service.dart';

/// AvailabilitySlotStateManager - 時段狀態管理器
///
/// 管理時段相關的所有狀態數據
class AvailabilitySlotStateManager extends ChangeNotifier {
  // 教練的所有時段
  List<AvailabilitySlotModel> _slots = [];

  // 週期性時段
  List<AvailabilitySlotModel> _recurringSlots = [];

  // 單次時段
  List<AvailabilitySlotModel> _oneTimeSlots = [];

  // 可預約時段（含預約狀態）
  List<AvailabilitySlotWithBooking> _availableSlots = [];

  // 當前選中的時段
  AvailabilitySlotModel? _selectedSlot;

  // 當前查詢的日期範圍
  DateTime? _queryStartDate;
  DateTime? _queryEndDate;

  // 載入狀態
  bool _isLoading = false;
  String? _errorMessage;

  // ============================================================================
  // Getters
  // ============================================================================

  List<AvailabilitySlotModel> get slots => _slots;
  List<AvailabilitySlotModel> get recurringSlots => _recurringSlots;
  List<AvailabilitySlotModel> get oneTimeSlots => _oneTimeSlots;
  List<AvailabilitySlotWithBooking> get availableSlots => _availableSlots;
  AvailabilitySlotModel? get selectedSlot => _selectedSlot;
  DateTime? get queryStartDate => _queryStartDate;
  DateTime? get queryEndDate => _queryEndDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ============================================================================
  // Setters
  // ============================================================================

  void setSlots(List<AvailabilitySlotModel> slots) {
    _slots = slots;
    notifyListeners();
  }

  void setRecurringSlots(List<AvailabilitySlotModel> slots) {
    _recurringSlots = slots;
    notifyListeners();
  }

  void setOneTimeSlots(List<AvailabilitySlotModel> slots) {
    _oneTimeSlots = slots;
    notifyListeners();
  }

  void setAvailableSlots(List<AvailabilitySlotWithBooking> slots) {
    _availableSlots = slots;
    notifyListeners();
  }

  void setSelectedSlot(AvailabilitySlotModel? slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  void setQueryParams({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _queryStartDate = startDate;
    _queryEndDate = endDate;
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }

  // ============================================================================
  // 輔助方法
  // ============================================================================

  /// 從列表中移除時段
  void removeSlot(String slotId) {
    _slots.removeWhere((slot) => slot.id == slotId);
    _recurringSlots.removeWhere((slot) => slot.id == slotId);
    _oneTimeSlots.removeWhere((slot) => slot.id == slotId);
    notifyListeners();
  }

  /// 批量移除時段
  void removeSlots(List<String> slotIds) {
    _slots.removeWhere((slot) => slotIds.contains(slot.id));
    _recurringSlots.removeWhere((slot) => slotIds.contains(slot.id));
    _oneTimeSlots.removeWhere((slot) => slotIds.contains(slot.id));
    notifyListeners();
  }

  /// 清除所有狀態
  void clearAll() {
    _slots.clear();
    _recurringSlots.clear();
    _oneTimeSlots.clear();
    _availableSlots.clear();
    _selectedSlot = null;
    _queryStartDate = null;
    _queryEndDate = null;
    _errorMessage = null;
    notifyListeners();
  }
}

