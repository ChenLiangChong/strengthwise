import 'package:flutter/material.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/controllers/appointment_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/models/appointment_model.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/appointment_details_page.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointments_list/filter_chips_section.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointments_list/appointment_card.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/appointments_list/empty_appointments_state.dart';

/// 預約列表頁面 - Phase 2
///
/// 功能：
/// 1. 顯示學員/教練的所有預約
/// 2. 按狀態篩選（全部/待確認/已確認/已完成/已取消）
/// 3. 點擊預約卡片進入詳情頁
/// 4. 快速操作（取消預約、確認預約等）
class AppointmentsListPage extends StatefulWidget {
  final bool isCoachMode;

  const AppointmentsListPage({
    super.key,
    this.isCoachMode = false,
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
    // 導航到預約詳情頁面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailsPage(
          appointmentId: appointment.id,
          isCoachMode: widget.isCoachMode,
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

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getSuccessMessage(action))),
        );
        await _loadData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ⭐ 移除返回按鈕（TabBar 子頁面不需要）
        title: Text(widget.isCoachMode ? '預約管理' : '我的預約'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 狀態篩選器
          FilterChipsSection(
            selectedStatus: _selectedStatus,
            onStatusSelected: _onStatusSelected,
          ),

          const Divider(height: 1),

          // 預約列表
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return AppointmentCard(
            appointment: appointment,
            isCoachMode: widget.isCoachMode,
            onTap: () => _onAppointmentTapped(appointment),
            onQuickAction: (action) => _onQuickAction(appointment, action),
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

