// ✅ 已響應式改造 (Phase 0 + P3 Master-Detail)
// ✅ v3.6: MVVM 重構 - 移除 Service 直接調用
import 'package:flutter/material.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/controllers/interfaces/i_profile_controller.dart'; // ⭐ v3.6: MVVM
import 'package:strengthwise/controllers/interfaces/i_appointment_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
// ⭐ v3.5: 事件由 Controller 統一發布，View 不需要直接使用 EventBusController
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/models/appointment_model.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/appointment_details_page.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointments_list/filter_chips_section.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointments_list/appointment_card.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointments_list/empty_appointments_state.dart';
import 'package:strengthwise/views/pages/session/session_mode_page.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/adhoc_session_dialog.dart';
import 'package:strengthwise/common_widgets/loading/skeleton_loader.dart';
// ⭐ P3: Master-Detail 支援
import 'package:strengthwise/views/shared/layouts/master_detail_layout.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointment_details_content.dart';
import 'package:strengthwise/common_widgets/dialogs/reason_input_dialog.dart'; // ⭐ v3.9

/// 預約列表頁面 - Phase 2
///
/// 功能：
/// 1. 顯示學員/教練的所有預約
/// 2. 按狀態篩選（全部/待確認/已確認/已完成/已取消）
/// 3. 點擊預約卡片進入詳情頁
/// 4. 快速操作（取消預約、確認預約等）
class AppointmentsListPage extends StatefulWidget {
  final bool isCoachMode;

  /// ⭐ P3：選中預約回調（用於 True Dual-Pane 佈局）
  final void Function(String? appointmentId)? onAppointmentSelected;

  const AppointmentsListPage({
    super.key,
    this.isCoachMode = false,
    this.onAppointmentSelected,
  });

  @override
  State<AppointmentsListPage> createState() => _AppointmentsListPageState();
}

class _AppointmentsListPageState extends State<AppointmentsListPage> {
  late final IAppointmentController _appointmentController;
  late final IAuthController _authController;
  late final IProfileController _profileController; // ⭐ v3.6: MVVM
  late final ErrorHandlingService _errorService;

  AppointmentStatus? _selectedStatus;
  bool _isLoading = true;
  UserModel? _currentUser;
  // ⭐ P3: Master-Detail 選中的預約 ID
  String? _selectedAppointmentId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    _appointmentController = serviceLocator<IAppointmentController>();
    _authController = serviceLocator<IAuthController>();
    _profileController = serviceLocator<IProfileController>(); // ⭐ v3.6: MVVM
    _errorService = serviceLocator<ErrorHandlingService>();
    _appointmentController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = _authController.user;
      if (user == null) {
        throw Exception('未登入');
      }
      _currentUser = user;

      if (widget.isCoachMode) {
        await _appointmentController.loadCoachAppointments(
          coachId: user.uid,
          status: _selectedStatus,
        );
      } else {
        await _appointmentController.loadClientAppointments(
          clientId: user.uid,
          status: _selectedStatus,
        );
      }
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e, customMessage: '載入預約列表失敗');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onStatusSelected(AppointmentStatus? status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadData();
  }

  void _onAppointmentTapped(AppointmentModel appointment) {
    // ⭐ P3: 如果有回調，通知父層；否則使用內部 MasterDetailLayout
    if (widget.onAppointmentSelected != null) {
      widget.onAppointmentSelected!(appointment.id);
    } else if (context.isMobile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppointmentDetailsPage(
            appointmentId: appointment.id,
            isCoachMode: widget.isCoachMode,
          ),
        ),
      );
    } else {
      // 平板/桌面：更新右側詳情
      setState(() {
        _selectedAppointmentId = appointment.id;
      });
    }
  }

  /// 開始課程（進入 Session Mode - 教練）⭐ v3.0
  /// ⭐ v3.1.1: 異步獲取學員名稱
  Future<void> _onStartSession(AppointmentModel appointment) async {
    // 獲取學員名稱
    // ⭐ v3.6: 透過 ProfileController 查詢
    String clientName = '學員';
    try {
      final profile = await _profileController.getUserProfileById(appointment.clientId);
      clientName = profile?.displayName ?? profile?.email ?? '學員';
    } catch (e) {
      debugPrint('[APPOINTMENTS_LIST] 獲取學員名稱失敗: $e');
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionModePage(
          appointmentId: appointment.id,
          clientId: appointment.clientId,
          clientName: clientName,
          sessionStartTime: appointment.startTime,
          sessionEndTime: appointment.endTime,
          workoutPlanId: appointment.workoutPlanId,
          isCoachMode: true,
        ),
      ),
    );
  }

  /// 查看課程（進入 Session Mode - 學員）⭐ v3.1
  /// ⭐ v3.1.1: 異步獲取教練名稱
  Future<void> _onViewSession(AppointmentModel appointment) async {
    // 獲取教練名稱
    // ⭐ v3.6: 透過 ProfileController 查詢
    String coachName = '教練';
    try {
      final profile = await _profileController.getUserProfileById(appointment.coachId);
      coachName = profile?.displayName ?? profile?.email ?? '教練';
    } catch (e) {
      debugPrint('[APPOINTMENTS_LIST] 獲取教練名稱失敗: $e');
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionModePage(
          appointmentId: appointment.id,
          clientId: appointment.clientId,
          clientName: coachName, // ⭐ v3.1.1: 學員視角顯示教練名稱
          sessionStartTime: appointment.startTime,
          sessionEndTime: appointment.endTime,
          workoutPlanId: appointment.workoutPlanId,
          isCoachMode: false,
        ),
      ),
    );
  }

  Future<void> _onQuickAction(
    AppointmentModel appointment,
    String action,
  ) async {
    final user = _currentUser;
    if (user == null) return;

    try {
      bool success = false;

      switch (action) {
        case 'cancel':
          // ⭐ v3.1.1: 必須填寫取消原因
          final cancelReason = await _showReasonDialog(
            title: '取消預約',
            hintText: '例如：時間無法配合、臨時有事...',
          );
          if (cancelReason == null) return;
          
          // 加上角色前綴
          final cancelPrefix = widget.isCoachMode ? '教練取消' : '學員取消';
          final fullCancelReason = '$cancelPrefix：$cancelReason';
          
          success = await _appointmentController.cancelAppointment(
            appointmentId: appointment.id,
            cancelledBy: user.uid,
            reason: fullCancelReason,
          );
          break;

        case 'confirm':
          success = await _appointmentController.confirmAppointment(
            appointment.id,
          );
          break;

        case 'complete':
          success = await _appointmentController.completeAppointment(
            appointment.id,
          );
          break;

        case 'reject':
          // ⭐ v3.1.1: 必須填寫拒絕原因
          final rejectReason = await _showReasonDialog(
            title: '拒絕預約',
            hintText: '例如：該時段已滿、時間無法配合...',
          );
          if (rejectReason == null) return;
          
          // 加上角色前綴
          final fullRejectReason = '教練拒絕：$rejectReason';
          
          success = await _appointmentController.rejectAppointment(
            appointmentId: appointment.id,
            cancelledBy: user.uid,
            reason: fullRejectReason,
          );
          break;
      }

      if (mounted) {
        if (success) {
          // ⭐ v3.5: 事件由 Controller 統一發布，View 只處理 UI 回饋
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_getSuccessMessage(action))),
          );
          await _loadData();
        } else {
          // ⭐ 修復：操作失敗時顯示錯誤訊息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getActionName(action)}失敗，請稍後再試'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e, customMessage: '操作失敗');
      }
    }
  }

  String _getSuccessMessage(String action) {
    switch (action) {
      case 'cancel':
        return '預約已取消';
      case 'confirm':
        return '預約已確認';
      case 'complete':
        return '預約已完成';
      case 'reject':
        return '預約已拒絕';
      default:
        return '操作成功';
    }
  }

  /// ⭐ 獲取操作名稱（用於錯誤訊息）
  String _getActionName(String action) {
    switch (action) {
      case 'cancel':
        return '取消預約';
      case 'confirm':
        return '確認預約';
      case 'complete':
        return '完成預約';
      case 'reject':
        return '拒絕預約';
      default:
        return '操作';
    }
  }

  /// ⭐ v3.1.1: 顯示原因輸入對話框
  Future<String?> _showReasonDialog({
    required String title,
    required String hintText,
  }) async {
    // ⭐ v3.9: 使用共用 ReasonInputDialog 避免 Controller dispose 問題
    return ReasonInputDialog.show(
      context,
      title: title,
      hintText: hintText,
      cancelText: '返回',
      confirmText: '確定',
    );
  }

  /// 建立臨時課程（教練專用）⭐ v3.0
  /// ⭐ v3.1.1: 創建後自動跳轉到 Session Mode
  Future<void> _onCreateAdHocSession() async {
    final user = _currentUser;
    if (user == null) return;

    final result = await AdHocSessionDialog.show(context, user.uid);
    if (result != null && mounted) {
      // ⭐ v3.1.1: 跳轉到 Session Mode
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionModePage(
            appointmentId: result.appointmentId,
            clientId: result.clientId,
            clientName: result.clientName,
            sessionStartTime: result.startTime,
            sessionEndTime: result.endTime,
            isCoachMode: true,
          ),
        ),
      );
      // 返回後刷新列表
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ P3: 使用 MasterDetailLayout 包裝
    final masterContent = Scaffold(
      body: Column(
        children: [
          FilterChipsSection(
            selectedStatus: _selectedStatus,
            onStatusSelected: _onStatusSelected,
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: widget.isCoachMode
          ? FloatingActionButton.extended(
              heroTag: 'appointments_fab', // ⭐ 防止 Hero tag 衝突
              onPressed: _onCreateAdHocSession,
              icon: const Icon(Icons.flash_on),
              label: const Text('臨時課程'),
              tooltip: '直接建立已確認的課程',
            )
          : null,
    );

    // ⭐ P3: 如果父層處理 Detail（有 onAppointmentSelected），直接返回 masterContent
    if (widget.onAppointmentSelected != null) {
      return masterContent;
    }

    // 否則使用內部 MasterDetailLayout
    return MasterDetailLayout(
      master: masterContent,
      detail: _selectedAppointmentId != null
          ? AppointmentDetailsContent(
              key: ValueKey(_selectedAppointmentId),
              appointmentId: _selectedAppointmentId!,
              isCoachMode: widget.isCoachMode,
              onClose: () {
                setState(() => _selectedAppointmentId = null);
              },
              onDataChanged: _loadData,
            )
          : null,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      // ⭐ v3.0: 使用骨架屏替代 Loading
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SkeletonList(
          itemCount: 4,
          spacing: 12,
          itemBuilder: (context, index) => const SkeletonAppointmentCard(),
        ),
      );
    }

    final appointments = _appointmentController.appointments;

    if (appointments.isEmpty) {
      // 空狀態也支援下拉刷新
      return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: EmptyAppointmentsState(
              isCoachMode: widget.isCoachMode,
              selectedStatus: _selectedStatus,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: context.pagePadding, // ⭐ 響應式邊距
        itemCount: appointments.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: context.spacing.md),
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return AppointmentCard(
            appointment: appointment,
            isCoachMode: widget.isCoachMode,
            onTap: () => _onAppointmentTapped(appointment),
            onQuickAction: (action) => _onQuickAction(appointment, action),
            onStartSession:
                widget.isCoachMode ? () => _onStartSession(appointment) : null,
            // ⭐ v3.1: 學員查看課程入口
            onViewSession:
                !widget.isCoachMode ? () => _onViewSession(appointment) : null,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _appointmentController.removeListener(_onControllerUpdate);
    super.dispose();
  }
}
