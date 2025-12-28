import '../../services/interfaces/i_appointment_service.dart';
import '../../models/appointment_model.dart';
import 'appointment_state_manager.dart';

/// AppointmentQueryManager - 預約查詢管理器
///
/// 負責所有預約查詢邏輯
class AppointmentQueryManager {
  final IAppointmentService _appointmentService;
  final AppointmentStateManager _state;

  AppointmentQueryManager(
    this._appointmentService,
    this._state,
  );

  // ============================================================================
  // 教練端查詢
  // ============================================================================

  /// 載入教練的預約列表
  Future<void> loadCoachAppointments({
    required String coachId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) async {
    _state.setQueryParams(
      startDate: startDate,
      endDate: endDate,
      status: status,
    );

    final appointments = await _appointmentService.getCoachAppointments(
      coachId: coachId,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );

    _state.setAppointments(appointments);
  }

  /// 載入待確認的預約
  Future<void> loadPendingAppointments(String coachId) async {
    final appointments = await _appointmentService.getPendingAppointments(coachId);
    _state.setPendingAppointments(appointments);
  }

  /// 載入教練的統計數據
  Future<void> loadCoachStats(String coachId) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    final stats = await _appointmentService.getAppointmentStats(
      coachId: coachId,
      startDate: startDate,
      endDate: endDate,
    );

    final total = stats.values.fold(0, (sum, count) => sum + count);
    final completed = stats['completed'] ?? 0;
    final cancelled = stats['cancelled'] ?? 0;
    final attendanceRate = total > 0 ? completed / total : 0.0;

    _state.setStatistics(
      total: total,
      completed: completed,
      cancelled: cancelled,
      attendanceRate: attendanceRate,
    );
  }

  // ============================================================================
  // 學員端查詢
  // ============================================================================

  /// 載入學員的預約列表
  Future<void> loadClientAppointments({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) async {
    _state.setQueryParams(
      startDate: startDate,
      endDate: endDate,
      status: status,
    );

    final appointments = await _appointmentService.getClientAppointments(
      clientId: clientId,
      startDate: startDate,
      endDate: endDate,
      status: status,
    );

    _state.setAppointments(appointments);
  }

  /// 載入學員的統計數據
  Future<void> loadClientStats(String clientId) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    final attendanceRate = await _appointmentService.getClientAttendanceRate(
      clientId: clientId,
      startDate: startDate,
      endDate: endDate,
    );

    // 從當前列表計算統計
    final appointments = _state.appointments;
    final total = appointments.length;
    final completed = appointments
        .where((apt) => apt.status == AppointmentStatus.completed)
        .length;
    final cancelled = appointments
        .where((apt) => apt.status == AppointmentStatus.cancelled)
        .length;

    _state.setStatistics(
      total: total,
      completed: completed,
      cancelled: cancelled,
      attendanceRate: attendanceRate,
    );
  }

  // ============================================================================
  // 共用查詢
  // ============================================================================

  /// 載入即將到來的預約（未來 7 天）
  Future<void> loadUpcomingAppointments({
    required String userId,
    required bool isCoach,
  }) async {
    final appointments = await _appointmentService.getUpcomingAppointments(
      userId: userId,
      isCoach: isCoach,
    );

    _state.setUpcomingAppointments(appointments);
  }

  /// 查詢預約詳情
  Future<void> selectAppointment(String appointmentId) async {
    final appointment = await _appointmentService.getAppointmentById(appointmentId);
    _state.setSelectedAppointment(appointment);
  }

  /// 檢查時段衝突
  Future<bool> checkTimeConflict({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeAppointmentId,
  }) async {
    return await _appointmentService.checkConflict(
      coachId: coachId,
      startTime: startTime,
      endTime: endTime,
      excludeAppointmentId: excludeAppointmentId,
    );
  }
}

