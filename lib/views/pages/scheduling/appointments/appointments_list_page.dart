// ✅ 已響應式改造 (Phase 0 + P3 Master-Detail)
import 'package:flutter/material.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/controllers/appointment_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
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
  late final AppointmentController _appointmentController;
  late final IAuthController _authController;
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _currentUser = _authController.user;
      if (_currentUser == null) {
        throw Exception('未登入');
      }

      if (widget.isCoachMode) {
        await _appointmentController.loadCoachAppointments(
          coachId: _currentUser!.uid,
          status: _selectedStatus,
        );
      } else {
        await _appointmentController.loadClientAppointments(
          clientId: _currentUser!.uid,
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
  void _onStartSession(AppointmentModel appointment) {
    // 嘗試從備註中獲取學員名稱，否則使用預設值
    // TODO: 可考慮在 AppointmentModel 中加入 clientName 快取
    final clientName = '學員';

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
          isCoachMode: true, // ⭐ v3.1: 教練模式
        ),
      ),
    );
  }

  /// 查看課程（進入 Session Mode - 學員）⭐ v3.1
  void _onViewSession(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionModePage(
          appointmentId: appointment.id,
          clientId: appointment.clientId,
          clientName: '我', // 學員查看自己的課程
          sessionStartTime: appointment.startTime,
          sessionEndTime: appointment.endTime,
          workoutPlanId: appointment.workoutPlanId,
          isCoachMode: false, // ⭐ v3.1: 學員模式（唯讀）
        ),
      ),
    );
  }

  Future<void> _onQuickAction(
    AppointmentModel appointment,
    String action,
  ) async {
    if (_currentUser == null) return;

    try {
      bool success = false;

      switch (action) {
        case 'cancel':
          // 根據角色設置不同的取消原因
          success = await _appointmentController.cancelAppointment(
            appointmentId: appointment.id,
            cancelledBy: _currentUser!.uid,
            reason: widget.isCoachMode ? '教練取消' : '學員取消',
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
          success = await _appointmentController.rejectAppointment(
            appointmentId: appointment.id,
            cancelledBy: _currentUser!.uid,
            reason: '教練拒絕',
          );
          break;
      }

      if (mounted) {
        if (success) {
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

  /// 建立臨時課程（教練專用）⭐ v3.0
  Future<void> _onCreateAdHocSession() async {
    if (_currentUser == null) return;

    final result = await AdHocSessionDialog.show(context, _currentUser!.uid);
    if (result == true) {
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
