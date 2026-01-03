import 'package:flutter/material.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/controllers/appointment_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointment_details/details_header.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointment_details/details_info_section.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointment_details/notes_section.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointment_details/actions_section.dart';

/// 預約詳情頁面 - Phase 2
///
/// 功能：
/// 1. 顯示預約完整資訊
/// 2. 狀態管理（確認/拒絕/取消/完成）
/// 3. 備註編輯（教練/學員分別）
/// 4. 關聯訓練計劃（教練端）
class AppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;
  final bool isCoachMode;

  const AppointmentDetailsPage({
    super.key,
    required this.appointmentId,
    this.isCoachMode = false,
  });

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  late final AppointmentController _appointmentController;
  late final IAuthController _authController;
  late final ErrorHandlingService _errorService;

  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadAppointmentDetails();
  }

  void _initializeControllers() {
    _appointmentController = serviceLocator<AppointmentController>();
    _authController = serviceLocator<IAuthController>();
    _errorService = serviceLocator<ErrorHandlingService>();
    _appointmentController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadAppointmentDetails() async {
    setState(() => _isLoading = true);

    try {
      await _appointmentController.selectAppointment(widget.appointmentId);

      // 載入備註內容
      final appointment = _appointmentController.selectedAppointment;
      if (appointment != null) {
        final notes = widget.isCoachMode
            ? appointment.coachNotes
            : appointment.clientNotes;
        _notesController.text = notes ?? '';
      }
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e, customMessage: '載入預約詳情失敗');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmAppointment() async {
    final success = await _appointmentController.confirmAppointment(
      widget.appointmentId,
    );

    if (mounted) {
      if (success) {
        NotificationUtils.showSuccess(context, '預約已確認');
        await _loadAppointmentDetails();
      } else {
        NotificationUtils.showError(context, '確認失敗，請稍後再試');
      }
    }
  }

  Future<void> _rejectAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => AlertDialog(
        title: const Text('拒絕預約'),
        content: const Text('確定要拒絕這個預約嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('確定拒絕'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final userId = _authController.user?.uid;
      if (userId == null) return;

      final success = await _appointmentController.rejectAppointment(
        appointmentId: widget.appointmentId,
        cancelledBy: userId,
        reason: '教練拒絕',
      );

      if (mounted) {
        if (success) {
          NotificationUtils.showSuccess(context, '預約已拒絕');
          Navigator.pop(context);
        } else {
          NotificationUtils.showError(context, '操作失敗');
        }
      }
    }
  }

  Future<void> _cancelAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => AlertDialog(
        title: const Text('取消預約'),
        content: const Text('確定要取消這個預約嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('返回'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('確定取消'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final userId = _authController.user?.uid;
      if (userId == null) return;

      final success = await _appointmentController.cancelAppointment(
        appointmentId: widget.appointmentId,
        cancelledBy: userId,
        reason: widget.isCoachMode ? '教練取消' : '學員取消',
      );

      if (mounted) {
        if (success) {
          NotificationUtils.showSuccess(context, '預約已取消');
          Navigator.pop(context);
        } else {
          NotificationUtils.showError(context, '取消失敗');
        }
      }
    }
  }

  Future<void> _completeAppointment() async {
    final success = await _appointmentController.completeAppointment(
      widget.appointmentId,
    );

    if (mounted) {
      if (success) {
        NotificationUtils.showSuccess(context, '預約已標記為完成');
        await _loadAppointmentDetails();
      } else {
        NotificationUtils.showError(context, '操作失敗');
      }
    }
  }

  Future<void> _saveNotes() async {
    final success = widget.isCoachMode
        ? await _appointmentController.updateCoachNotes(
            appointmentId: widget.appointmentId,
            notes: _notesController.text,
          )
        : await _appointmentController.updateClientNotes(
            appointmentId: widget.appointmentId,
            notes: _notesController.text,
          );

    if (mounted) {
      if (success) {
        NotificationUtils.showSuccess(context, '備註已更新');
        setState(() => _isEditing = false);
      } else {
        NotificationUtils.showError(context, '更新失敗');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = _appointmentController.selectedAppointment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('預約詳情'),
        elevation: 0,
      ),
      body: _isLoading || appointment == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 標題區域（狀態 + 日期時間）
                  DetailsHeader(appointment: appointment),

                  const Divider(height: 1),

                  // 詳細資訊區域
                  DetailsInfoSection(
                    appointment: appointment,
                    isCoachMode: widget.isCoachMode,
                  ),

                  const Divider(height: 1),

                  // 備註區域
                  NotesSection(
                    controller: _notesController,
                    isEditing: _isEditing,
                    isCoachMode: widget.isCoachMode,
                    onEditToggle: () {
                      setState(() => _isEditing = !_isEditing);
                    },
                    onSave: _saveNotes,
                  ),

                  const Divider(height: 1),

                  // 操作按鈕區域
                  ActionsSection(
                    appointment: appointment,
                    isCoachMode: widget.isCoachMode,
                    onConfirm: _confirmAppointment,
                    onReject: _rejectAppointment,
                    onCancel: _cancelAppointment,
                    onComplete: _completeAppointment,
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _appointmentController.removeListener(_onControllerUpdate);
    _appointmentController.clearSelectedAppointment();
    _notesController.dispose();
    super.dispose();
  }
}
