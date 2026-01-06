// ✅ P3 響應式分欄佈局
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
import 'package:strengthwise/views/pages/scheduling/appointments/session_record_page.dart';

/// 預約詳情內容 - 用於嵌入式顯示（無 AppBar）
///
/// 設計用於：
/// 1. Master-Detail 佈局的右側詳情區
/// 2. 可獨立使用或嵌入其他頁面
///
/// 與 [AppointmentDetailsPage] 的差異：
/// - 沒有 Scaffold/AppBar
/// - 使用回調通知父組件需要關閉
class AppointmentDetailsContent extends StatefulWidget {
  final String appointmentId;
  final bool isCoachMode;

  /// 當詳情需要關閉時的回調（如刪除/取消後）
  final VoidCallback? onClose;

  /// 當數據變更時的回調（用於刷新列表）
  final VoidCallback? onDataChanged;

  const AppointmentDetailsContent({
    super.key,
    required this.appointmentId,
    this.isCoachMode = false,
    this.onClose,
    this.onDataChanged,
  });

  @override
  State<AppointmentDetailsContent> createState() =>
      _AppointmentDetailsContentState();
}

class _AppointmentDetailsContentState extends State<AppointmentDetailsContent> {
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

  @override
  void didUpdateWidget(AppointmentDetailsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當 appointmentId 變更時重新載入
    if (oldWidget.appointmentId != widget.appointmentId) {
      _loadAppointmentDetails();
    }
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
        widget.onDataChanged?.call();
      } else {
        NotificationUtils.showError(context, '確認失敗，請稍後再試');
      }
    }
  }

  Future<void> _rejectAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
          widget.onDataChanged?.call();
          widget.onClose?.call();
        } else {
          NotificationUtils.showError(context, '操作失敗');
        }
      }
    }
  }

  Future<void> _cancelAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
          widget.onDataChanged?.call();
          widget.onClose?.call();
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
        widget.onDataChanged?.call();
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

  void _navigateToSessionRecord(dynamic appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionRecordPage(appointment: appointment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointment = _appointmentController.selectedAppointment;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appointment == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text('載入預約詳情失敗'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailsHeader(appointment: appointment),
          const Divider(height: 1),
          DetailsInfoSection(
            appointment: appointment,
            isCoachMode: widget.isCoachMode,
          ),
          const Divider(height: 1),
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
          ActionsSection(
            appointment: appointment,
            isCoachMode: widget.isCoachMode,
            onConfirm: _confirmAppointment,
            onReject: _rejectAppointment,
            onCancel: _cancelAppointment,
            onComplete: _completeAppointment,
            onViewRecord: !widget.isCoachMode
                ? () => _navigateToSessionRecord(appointment)
                : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _appointmentController.removeListener(_onControllerUpdate);
    _notesController.dispose();
    super.dispose();
  }
}
