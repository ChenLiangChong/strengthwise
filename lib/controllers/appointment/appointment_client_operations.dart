import '../../services/interfaces/i_appointment_service.dart';
import '../../models/appointment_model.dart';
import 'appointment_state_manager.dart';

/// AppointmentClientOperations - 學員端預約操作
///
/// 負責學員端的所有預約操作（創建、取消、更新備註）
class AppointmentClientOperations {
  final IAppointmentService _appointmentService;
  final AppointmentStateManager _state;

  AppointmentClientOperations(
    this._appointmentService,
    this._state,
  );

  // ============================================================================
  // 學員端操作
  // ============================================================================

  /// 創建預約
  Future<void> createAppointment(AppointmentModel appointment) async {
    // 先檢查時段衝突
    final hasConflict = await _appointmentService.checkConflict(
      coachId: appointment.coachId,
      startTime: appointment.startTime,
      endTime: appointment.endTime,
    );

    if (hasConflict) {
      throw Exception('該時段已被預約，請選擇其他時段');
    }

    await _appointmentService.createAppointment(appointment);
  }

  /// 取消預約
  Future<void> cancelAppointment({
    required String appointmentId,
    required String cancelledBy,
    required String reason,
  }) async {
    await _appointmentService.cancelAppointment(
      appointmentId: appointmentId,
      cancelledBy: cancelledBy,
      reason: reason,
    );
    _state.updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
  }

  /// 更新學員備註
  Future<void> updateClientNotes({
    required String appointmentId,
    required String notes,
  }) async {
    await _appointmentService.updateClientNotes(
      appointmentId: appointmentId,
      clientNotes: notes,
    );
  }

  /// 更新預約時間
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    await _appointmentService.rescheduleAppointment(
      appointmentId: appointmentId,
      newStartTime: newStartTime,
      newEndTime: newEndTime,
    );
  }
}

