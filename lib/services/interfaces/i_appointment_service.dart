import '../../../models/appointment_model.dart';

/// IAppointmentService - Phase 2 預約服務接口
/// 
/// 定義預約管理的所有方法（不依賴具體實現）
/// 遵循依賴反轉原則（Dependency Inversion Principle）
abstract class IAppointmentService {
  // ============================================================
  // 查詢方法（Query）
  // ============================================================

  /// 查詢教練的所有預約
  /// 
  /// [coachId] 教練 ID
  /// [startDate] 開始日期（可選，預設本月第一天）
  /// [endDate] 結束日期（可選，預設本月最後一天）
  /// [status] 狀態篩選（可選，null 表示所有狀態）
  Future<List<AppointmentModel>> getCoachAppointments({
    required String coachId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  });

  /// 查詢學員的所有預約
  /// 
  /// [clientId] 學員 ID
  /// [startDate] 開始日期（可選）
  /// [endDate] 結束日期（可選）
  /// [status] 狀態篩選（可選）
  Future<List<AppointmentModel>> getClientAppointments({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  });

  /// 根據 ID 查詢單個預約
  /// 
  /// [appointmentId] 預約 ID
  /// 返回 null 表示不存在或無權限
  Future<AppointmentModel?> getAppointmentById(String appointmentId);

  /// 查詢待確認的預約（教練端）
  /// 
  /// [coachId] 教練 ID
  Future<List<AppointmentModel>> getPendingAppointments(String coachId);

  /// 查詢即將到來的預約（未來 7 天）
  /// 
  /// [userId] 用戶 ID（教練或學員）
  /// [isCoach] 是否為教練視角
  Future<List<AppointmentModel>> getUpcomingAppointments({
    required String userId,
    required bool isCoach,
  });

  /// 檢查時段衝突
  /// 
  /// [coachId] 教練 ID
  /// [startTime] 開始時間
  /// [endTime] 結束時間
  /// [excludeAppointmentId] 排除的預約 ID（用於更新時檢查）
  /// 返回 true 表示有衝突
  Future<bool> checkConflict({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeAppointmentId,
  });

  // ============================================================
  // 操作方法（Operations）
  // ============================================================

  /// 獲取學員最近一次已完成的預約（用於一鍵續約推薦）⭐ v3.0
  /// 
  /// [clientId] 學員 ID
  /// 返回最近一次已完成的預約（若沒有則返回 null）
  Future<AppointmentModel?> getLastCompletedAppointment(String clientId);

  // ============================================================
  // 操作方法（Operations）
  // ============================================================

  /// 創建預約（學員發起）
  /// 
  /// [appointment] 預約資料
  /// 返回創建的預約 ID
  /// 
  /// 注意：狀態自動設為 'requested'
  Future<String> createAppointment(AppointmentModel appointment);

  /// 確認預約（教練操作）
  /// 
  /// [appointmentId] 預約 ID
  /// [coachNotes] 教練備註（可選）
  Future<void> confirmAppointment(String appointmentId, {String? coachNotes});

  /// 完成預約（教練操作）
  /// 
  /// [appointmentId] 預約 ID
  /// [coachNotes] 教練備註（可選）
  Future<void> completeAppointment(String appointmentId, {String? coachNotes});

  /// 取消預約（教練或學員）
  /// 
  /// [appointmentId] 預約 ID
  /// [cancelledBy] 取消者 ID
  /// [reason] 取消原因
  Future<void> cancelAppointment({
    required String appointmentId,
    required String cancelledBy,
    required String reason,
  });

  /// 更新預約時間（僅限未確認的預約）
  /// 
  /// [appointmentId] 預約 ID
  /// [newStartTime] 新開始時間
  /// [newEndTime] 新結束時間
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  });

  /// 更新學員備註
  /// 
  /// [appointmentId] 預約 ID
  /// [clientNotes] 學員備註
  Future<void> updateClientNotes({
    required String appointmentId,
    required String clientNotes,
  });

  /// 更新教練備註
  /// 
  /// [appointmentId] 預約 ID
  /// [coachNotes] 教練備註
  Future<void> updateCoachNotes({
    required String appointmentId,
    required String coachNotes,
  });

  /// 關聯訓練計劃
  /// 
  /// [appointmentId] 預約 ID
  /// [workoutPlanId] 訓練計劃 ID
  Future<void> linkWorkoutPlan({
    required String appointmentId,
    required String workoutPlanId,
  });

  /// 刪除預約（僅限待確認的預約）
  /// 
  /// [appointmentId] 預約 ID
  Future<void> deleteAppointment(String appointmentId);

  // ============================================================
  // 統計方法（Statistics）
  // ============================================================

  /// 統計教練的預約數量
  /// 
  /// [coachId] 教練 ID
  /// [startDate] 開始日期
  /// [endDate] 結束日期
  /// 返回 Map，key 為狀態字串，value 為數量
  Future<Map<String, int>> getAppointmentStats({
    required String coachId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// 計算學員的出席率
  /// 
  /// [clientId] 學員 ID
  /// [startDate] 開始日期
  /// [endDate] 結束日期
  /// 返回 0.0 - 1.0 之間的值
  Future<double> getClientAttendanceRate({
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  });

  // ============================================================
  // 臨時課程（Ad-Hoc Session）⭐ v3.0
  // ============================================================

  /// 教練手動建立臨時課程
  /// 
  /// 不經過正式預約流程，直接建立 confirmed 狀態的預約
  /// 會自動觸發 session_notes 和 daily_readiness 的創建（DB Trigger）
  /// 
  /// [coachId] 教練 ID
  /// [clientId] 學員 ID
  /// [startTime] 開始時間
  /// [endTime] 結束時間
  /// [notes] 備註（可選）
  /// 
  /// 返回創建的預約 ID
  Future<String> createAdHocSession({
    required String coachId,
    required String clientId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  });
}

