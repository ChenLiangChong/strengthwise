import '../../../models/availability_slot_model.dart';

/// IAvailabilitySlotService - Phase 2 時段服務接口
/// 
/// 定義教練可用時段管理的所有方法（不依賴具體實現）
/// 遵循依賴反轉原則（Dependency Inversion Principle）
abstract class IAvailabilitySlotService {
  // ============================================================
  // 查詢方法（Query）
  // ============================================================

  /// 查詢教練的所有時段
  /// 
  /// [coachId] 教練 ID
  /// [startDate] 開始日期（可選）
  /// [endDate] 結束日期（可選）
  /// [includeOverrides] 是否包含覆蓋時段（預設 true）
  Future<List<AvailabilitySlotModel>> getCoachSlots({
    required String coachId,
    DateTime? startDate,
    DateTime? endDate,
    bool includeOverrides = true,
  });

  /// 根據 ID 查詢單個時段
  /// 
  /// [slotId] 時段 ID
  /// 返回 null 表示不存在或無權限
  Future<AvailabilitySlotModel?> getSlotById(String slotId);

  /// 查詢教練在特定日期的時段
  /// 
  /// [coachId] 教練 ID
  /// [date] 日期
  Future<List<AvailabilitySlotModel>> getSlotsByDate({
    required String coachId,
    required DateTime date,
  });

  /// 查詢可預約時段（排除已被預約的時段）
  /// 
  /// [coachId] 教練 ID
  /// [startDate] 開始日期
  /// [endDate] 結束日期
  /// 返回時段列表，包含 isBooked 標記
  Future<List<AvailabilitySlotWithBooking>> getAvailableSlots({
    required String coachId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 查詢週期性時段
  /// 
  /// [coachId] 教練 ID
  Future<List<AvailabilitySlotModel>> getRecurringSlots(String coachId);

  /// 查詢單次時段
  /// 
  /// [coachId] 教練 ID
  Future<List<AvailabilitySlotModel>> getOneTimeSlots(String coachId);

  /// 檢查時段是否已被預約
  /// 
  /// [slotId] 時段 ID
  /// 返回 true 表示已被預約
  Future<bool> isSlotBooked(String slotId);

  // ============================================================
  // 操作方法（Operations）
  // ============================================================

  /// 創建單次時段
  /// 
  /// [slot] 時段資料
  /// 返回創建的時段 ID
  Future<String> createSlot(AvailabilitySlotModel slot);

  /// 創建週期性時段
  /// 
  /// [coachId] 教練 ID
  /// [startTime] 開始時間（模板）
  /// [endTime] 結束時間（模板）
  /// [recurrenceRule] 週期性規則（iCal RRULE 格式）
  /// [notes] 備註（可選）
  /// 返回創建的時段 ID 列表
  Future<List<String>> createRecurringSlots({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    required String recurrenceRule,
    String? notes,
  });

  /// 更新時段
  /// 
  /// [slotId] 時段 ID
  /// [slot] 新時段資料
  Future<void> updateSlot({
    required String slotId,
    required AvailabilitySlotModel slot,
  });

  /// 刪除時段（僅限未被預約的時段）
  /// 
  /// [slotId] 時段 ID
  Future<void> deleteSlot(String slotId);

  /// 批量刪除時段
  /// 
  /// [slotIds] 時段 ID 列表
  /// 返回成功刪除的數量
  Future<int> deleteSlots(List<String> slotIds);

  /// 創建覆蓋時段（如休假日）
  /// 
  /// [coachId] 教練 ID
  /// [startTime] 開始時間
  /// [endTime] 結束時間
  /// [notes] 備註（如：休假）
  /// 返回創建的時段 ID
  Future<String> createOverrideSlot({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    required String notes,
  });

  /// 刪除覆蓋時段
  /// 
  /// [slotId] 時段 ID
  Future<void> deleteOverrideSlot(String slotId);

  // ============================================================
  // 批量操作（Batch Operations）
  // ============================================================

  /// 批量創建時段（用於設定每週固定時段）
  /// 
  /// [slots] 時段列表
  /// 返回創建的時段 ID 列表
  Future<List<String>> createSlotsBatch(List<AvailabilitySlotModel> slots);

  /// 複製時段到另一週
  /// 
  /// [coachId] 教練 ID
  /// [sourceWeekStart] 來源週的開始日期（週一）
  /// [targetWeekStart] 目標週的開始日期（週一）
  /// 返回創建的時段 ID 列表
  Future<List<String>> copyWeekSlots({
    required String coachId,
    required DateTime sourceWeekStart,
    required DateTime targetWeekStart,
  });

  /// 刪除特定週的所有時段
  /// 
  /// [coachId] 教練 ID
  /// [weekStart] 週開始日期（週一）
  /// 返回刪除的時段數量
  Future<int> deleteWeekSlots({
    required String coachId,
    required DateTime weekStart,
  });
}

/// 時段與預約狀態（用於顯示可用時段）
class AvailabilitySlotWithBooking {
  final AvailabilitySlotModel slot;
  final bool isBooked;
  final String? appointmentId;  // 如果已預約，關聯的預約 ID
  final String? bookedByClientId;  // ⭐ 新增：預約者的 client_id

  AvailabilitySlotWithBooking({
    required this.slot,
    required this.isBooked,
    this.appointmentId,
    this.bookedByClientId,  // ⭐ 新增參數
  });
}

