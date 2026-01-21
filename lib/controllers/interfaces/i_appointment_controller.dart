import 'package:flutter/foundation.dart';
import '../../models/appointment_model.dart';
import '../../models/readiness/daily_readiness_model.dart';

/// Appointment 控制器接口
///
/// 定義與預約管理相關的業務邏輯操作。
/// ⭐ v4.0: 架構優化 - 補充 Interface 以支援 Mock 測試
abstract class IAppointmentController extends ChangeNotifier {
  // ==================== 狀態 Getters ====================

  /// 載入中狀態
  bool get isLoading;

  /// 錯誤訊息
  String? get errorMessage;

  /// 預約列表
  List<AppointmentModel> get appointments;

  /// 待確認預約列表
  List<AppointmentModel> get pendingAppointments;

  /// 即將到來的預約列表
  List<AppointmentModel> get upcomingAppointments;

  /// 選中的預約
  AppointmentModel? get selectedAppointment;

  /// 預約統計
  int get totalAppointments;
  int get completedCount;
  int get cancelledCount;
  double get attendanceRate;

  /// 查詢參數
  DateTime? get queryStartDate;
  DateTime? get queryEndDate;
  AppointmentStatus? get queryStatus;

  // ==================== 教練端功能 ====================

  /// 載入教練的預約列表
  Future<void> loadCoachAppointments({
    required String coachId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  });

  /// 載入待確認的預約
  Future<void> loadPendingAppointments(String coachId);

  /// 確認預約
  Future<bool> confirmAppointment(String appointmentId);

  /// 拒絕預約
  Future<bool> rejectAppointment({
    required String appointmentId,
    required String cancelledBy,
    String reason = '教練拒絕',
  });

  /// 完成預約
  Future<bool> completeAppointment(String appointmentId);

  /// 更新教練備註
  Future<bool> updateCoachNotes({
    required String appointmentId,
    required String notes,
  });

  /// 關聯訓練計劃
  Future<bool> linkWorkoutPlan({
    required String appointmentId,
    required String workoutPlanId,
  });

  /// 創建臨時課程
  Future<String?> createAdHocSession({
    required String coachId,
    required String clientId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  });

  // ==================== 學員端功能 ====================

  /// 載入學員的預約列表
  Future<void> loadClientAppointments({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  });

  /// 創建預約
  Future<bool> createAppointment(AppointmentModel appointment);

  /// 取消預約
  Future<bool> cancelAppointment({
    required String appointmentId,
    required String cancelledBy,
    required String reason,
  });

  /// 更新學員備註
  Future<bool> updateClientNotes({
    required String appointmentId,
    required String notes,
  });

  /// 更新預約時間
  Future<bool> rescheduleAppointment({
    required String appointmentId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  });

  // ==================== 共用功能 ====================

  /// 載入即將到來的預約
  Future<void> loadUpcomingAppointments({
    required String userId,
    required bool isCoach,
  });

  /// 查詢預約詳情
  Future<void> selectAppointment(String appointmentId);

  /// 清除選中的預約
  void clearSelectedAppointment();

  /// 檢查時段衝突
  Future<bool> checkTimeConflict({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeAppointmentId,
  });

  /// 清除所有狀態
  void clearAll();

  // ==================== MVVM 直接查詢方法 ====================

  /// 查詢學員的預約（直接返回結果）
  Future<List<AppointmentModel>> getClientAppointments({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  });

  /// 查詢教練的預約（直接返回結果）
  Future<List<AppointmentModel>> getCoachAppointments({
    required String coachId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  });

  /// 查詢單筆預約（直接返回結果）
  Future<AppointmentModel?> getAppointmentById(String appointmentId);

  /// 查詢預約的課前問卷
  Future<DailyReadinessModel?> getReadinessByAppointmentId(
      String appointmentId);
}
