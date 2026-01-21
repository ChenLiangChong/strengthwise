import 'package:flutter/material.dart' show TimeOfDay, ChangeNotifier;
import '../../models/availability_slot_model.dart';
import '../../services/interfaces/i_availability_slot_service.dart' show AvailabilitySlotWithBooking;

/// 教練時段控制器接口
///
/// 管理教練的可用時段設定、查詢、修改等業務邏輯
abstract class IAvailabilitySlotController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 載入中狀態
  bool get isLoading;

  /// 錯誤訊息
  String? get errorMessage;

  /// 所有時段列表
  List<AvailabilitySlotModel> get slots;

  /// 週期性時段列表
  List<AvailabilitySlotModel> get recurringSlots;

  /// 單次時段列表
  List<AvailabilitySlotModel> get oneTimeSlots;

  /// 可預約時段列表（含預約狀態）
  List<AvailabilitySlotWithBooking> get availableSlots;

  /// 當前選中的時段
  AvailabilitySlotModel? get selectedSlot;

  /// 查詢開始日期
  DateTime? get queryStartDate;

  /// 查詢結束日期
  DateTime? get queryEndDate;

  // ==================== 教練端查詢 ====================

  /// 載入教練的所有時段
  Future<void> loadCoachSlots(String coachId, {DateTime? startDate, DateTime? endDate});

  /// 載入週期性時段和單次時段（分開）
  Future<void> loadSlotsByType(String coachId);

  /// 查詢特定日期的時段
  Future<void> loadSlotsByDate({required String coachId, required DateTime date});

  /// 選擇時段（用於顯示詳情）
  Future<void> selectSlot(String slotId);

  /// 清除選中的時段
  void clearSelectedSlot();

  /// 增量刪除時段（本地）
  void removeSlotById(String slotId);

  /// 檢查時段是否已被預約
  Future<bool> checkSlotBooked(String slotId);

  // ==================== 教練端創建 ====================

  /// 從 UI 數據創建單次時段
  Future<bool> createSingleSlotFromUI({
    required String coachId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? notes,
  });

  /// 從 UI 數據創建週期性時段
  Future<bool> createRecurringSlotFromUI({
    required String coachId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String recurrenceType,
    String? notes,
  });

  /// 創建單次時段（原始方法）
  Future<bool> createSlot(AvailabilitySlotModel slot);

  /// 創建週期性時段
  Future<bool> createRecurringSlot({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    required String recurrenceRule,
    String? notes,
  });

  /// 創建覆蓋時段（如休假日）
  Future<bool> createOverrideSlot({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    required String notes,
  });

  // ==================== 教練端更新與刪除 ====================

  /// 更新時段
  Future<bool> updateSlot(String slotId, AvailabilitySlotModel slot);

  /// 刪除時段
  Future<bool> deleteSlot(String slotId);

  /// 批量刪除時段
  Future<int> deleteSlotsBatch(List<String> slotIds);

  /// 刪除覆蓋時段
  Future<bool> deleteOverrideSlot(String slotId);

  /// 刪除特定週的所有時段
  Future<int> deleteWeekSlots({required String coachId, required DateTime weekStart});

  // ==================== 學員端功能 ====================

  /// 載入可預約時段（排除已被預約的）
  Future<void> loadAvailableSlots({
    required String coachId,
    required DateTime startDate,
    required DateTime endDate,
  });

  // ==================== 批量操作 ====================

  /// 批量創建時段
  Future<int> createBatchSlots(List<AvailabilitySlotModel> slots);

  /// 複製一週的時段到下一週
  Future<int> copyWeekSlots({
    required String coachId,
    required DateTime sourceWeekStart,
    required DateTime targetWeekStart,
  });

  // ==================== MVVM 查詢方法 ====================

  /// 查詢可預約時段（直接返回結果）
  Future<List<AvailabilitySlotWithBooking>> getAvailableSlots({
    required String coachId,
    required DateTime startDate,
    required DateTime endDate,
  });

  // ==================== 狀態管理 ====================

  /// 清除所有狀態
  void clearAll();
}
