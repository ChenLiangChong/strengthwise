import '../../services/interfaces/i_appointment_service.dart';
import '../../models/appointment_model.dart';
import 'appointment_state_manager.dart';

/// AppointmentCoachOperations - 教練端預約操作
///
/// 負責教練端的所有預約操作（確認、拒絕、完成）
class AppointmentCoachOperations {
  final IAppointmentService _appointmentService;
  final AppointmentStateManager _state;

  AppointmentCoachOperations(
    this._appointmentService,
    this._state,
  );

  // ============================================================================
  // 教練端操作
  // ============================================================================

  /// 確認預約
  Future<void> confirmAppointment(String appointmentId) async {
    await _appointmentService.confirmAppointment(appointmentId);
    _state.updateAppointmentStatus(appointmentId, AppointmentStatus.confirmed);
  }

  /// 拒絕預約（使用取消功能）
  Future<void> rejectAppointment({
    required String appointmentId,
    required String cancelledBy,
    String reason = '教練拒絕',
  }) async {
    await _appointmentService.cancelAppointment(
      appointmentId: appointmentId,
      cancelledBy: cancelledBy,
      reason: reason,
    );
    _state.updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
  }

  /// 完成預約
  Future<void> completeAppointment(String appointmentId) async {
    await _appointmentService.completeAppointment(appointmentId);
    _state.updateAppointmentStatus(appointmentId, AppointmentStatus.completed);
  }

  /// 更新教練備註
  Future<void> updateCoachNotes({
    required String appointmentId,
    required String notes,
  }) async {
    await _appointmentService.updateCoachNotes(
      appointmentId: appointmentId,
      coachNotes: notes,
    );
  }

  /// 關聯訓練計劃
  Future<void> linkWorkoutPlan({
    required String appointmentId,
    required String workoutPlanId,
  }) async {
    await _appointmentService.linkWorkoutPlan(
      appointmentId: appointmentId,
      workoutPlanId: workoutPlanId,
    );
  }
}

