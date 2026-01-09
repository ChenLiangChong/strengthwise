// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/controllers/appointment_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/utils/notification_utils.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointment_details/details_header.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointment_details/details_info_section.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointment_details/notes_section.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointment_details/actions_section.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/session_record_page.dart';
import 'package:strengthwise/views/pages/session/session_mode_page.dart';
import 'package:strengthwise/services/interfaces/i_user_service.dart';

/// 預約詳情頁面 - Phase 2
///
/// 功能：
/// 1. 顯示預約完整資訊
/// 2. 狀態管理（確認/拒絕/取消/完成）
/// 3. 備註編輯（區分學員別）
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
      barrierDismissible: false, // 修復：禁止點擊旁邊關閉
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
    // ⭐ v3.1.1: 必須填寫取消原因
    final reasonController = TextEditingController();
    
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('取消預約'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('請說明取消原因：'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: '例如：時間無法配合、臨時有事...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    autofocus: true,
                    onChanged: (_) => setState(() {}), // 更新按鈕狀態
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('返回'),
                ),
                FilledButton(
                  onPressed: reasonController.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(context, reasonController.text.trim()),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('確定取消'),
                ),
              ],
            );
          },
        );
      },
    );

    reasonController.dispose();

    if (reason != null && reason.isNotEmpty && mounted) {
      final userId = _authController.user?.uid;
      if (userId == null) return;

      // ⭐ v3.1.1: 加上角色前綴
      final rolePrefix = widget.isCoachMode ? '教練取消' : '學員取消';
      final fullReason = '$rolePrefix：$reason';

      final success = await _appointmentController.cancelAppointment(
        appointmentId: widget.appointmentId,
        cancelledBy: userId,
        reason: fullReason,
      );

      if (mounted) {
        if (success) {
          NotificationUtils.showSuccess(context, '預約已取消');
          Navigator.pop(context);
        } else {
          NotificationUtils.showError(context, '操作失敗');
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
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: context.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 標題區塊（狀態 + 時間範圍）
                      DetailsHeader(appointment: appointment),

                      const Divider(height: 1),

                      // 詳細資訊區塊
                      DetailsInfoSection(
                        appointment: appointment,
                        isCoachMode: widget.isCoachMode,
                      ),

                      const Divider(height: 1),

                      // 備註區塊
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

                      // 操作按鈕區塊
                      ActionsSection(
                        appointment: appointment,
                        isCoachMode: widget.isCoachMode,
                        onConfirm: _confirmAppointment,
                        onReject: _rejectAppointment,
                        onCancel: _cancelAppointment,
                        onComplete: _completeAppointment,
                        // ⭐ v3.0: 學員查看課程紀錄
                        onViewRecord: !widget.isCoachMode
                            ? () => _navigateToSessionRecord(appointment)
                            : null,
                        // ⭐ v3.1.1: 教練和學員都可查看課程詳情（進入 Session Mode）
                        onViewSession: () => _navigateToSessionMode(appointment),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// 導航到課程紀錄頁 ⭐ v3.0
  void _navigateToSessionRecord(dynamic appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionRecordPage(appointment: appointment),
      ),
    );
  }

  /// 導航到 Session Mode ⭐ v3.1.1
  /// 修復：異步獲取正確的名稱
  Future<void> _navigateToSessionMode(dynamic appointment) async {
    String displayName = '';

    try {
      final userService = serviceLocator<IUserService>();
      if (widget.isCoachMode) {
        // 教練視角：獲取學員名稱
        final profile = await userService.getUserProfile(appointment.clientId);
        displayName = profile?.displayName ?? profile?.email ?? '學員';
      } else {
        // 學員視角：獲取教練名稱
        final profile = await userService.getUserProfile(appointment.coachId);
        displayName = profile?.displayName ?? profile?.email ?? '教練';
      }
    } catch (e) {
      displayName = widget.isCoachMode ? '學員' : '教練';
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionModePage(
          appointmentId: appointment.id,
          clientId: appointment.clientId,
          clientName: displayName,
          sessionStartTime: appointment.startTime,
          sessionEndTime: appointment.endTime,
          workoutPlanId: appointment.workoutPlanId,
          isCoachMode: widget.isCoachMode,
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
