import 'package:flutter/material.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/controllers/appointment_controller.dart';
import 'package:strengthwise/controllers/availability_slot_controller.dart';
import 'package:strengthwise/controllers/coaching_relationship_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/services/interfaces/i_availability_slot_service.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/models/appointment_model.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/client_booking/coach_selector_section.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/client_booking/available_slots_calendar.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/client_booking/slot_list_view.dart';
import 'package:strengthwise/views/pages/scheduling/appointments/widgets/client_booking/booking_confirmation_dialog.dart';

/// 學員預約頁面 - Phase 2
///
/// 功能：
/// 1. 選擇教練
/// 2. 查看教練可用時段（日曆視圖 + 列表視圖）
/// 3. 創建預約
class ClientBookingPage extends StatefulWidget {
  const ClientBookingPage({super.key});

  @override
  State<ClientBookingPage> createState() => _ClientBookingPageState();
}

class _ClientBookingPageState extends State<ClientBookingPage> {
  late final AppointmentController _appointmentController;
  late final AvailabilitySlotController _slotController;
  late final CoachingRelationshipController _relationshipController;
  late final IAuthController _authController;
  late final ErrorHandlingService _errorService;

  bool _isLoading = true;
  String? _selectedCoachId;
  UserModel? _selectedCoach;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    _appointmentController = serviceLocator<AppointmentController>();
    _slotController = serviceLocator<AvailabilitySlotController>();
    _relationshipController = serviceLocator<CoachingRelationshipController>();
    _authController = serviceLocator<IAuthController>();
    _errorService = serviceLocator<ErrorHandlingService>();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authController.user?.uid;
      if (userId == null) {
        throw Exception('未登入');
      }

      // 載入學員的教練列表
      await _relationshipController.loadClientCoaches(userId);

      // 如果只有一個教練，自動選擇
      final coaches = _relationshipController.coaches;
      if (coaches.length == 1) {
        _selectedCoachId = coaches.first.coachId;
        await _loadCoachSlots();
      }
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e, customMessage: '載入教練列表失敗');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCoachSlots() async {
    if (_selectedCoachId == null) return;

    setState(() => _isLoading = true);

    try {
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      await _slotController.loadAvailableSlots(
        coachId: _selectedCoachId!,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e, customMessage: '載入時段失敗');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onCoachSelected(UserModel coach) {
    setState(() {
      _selectedCoachId = coach.uid;
      _selectedCoach = coach;
    });
    _loadCoachSlots();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
    _loadCoachSlots();
  }

  Future<void> _onSlotTapped(AvailabilitySlotWithBooking slot) async {
    if (slot.isBooked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('此時段已被預約')),
        );
      }
      return;
    }

    // 顯示確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => BookingConfirmationDialog(
        slot: slot,
        coachName: _selectedCoach?.displayName ?? '教練',
      ),
    );

    if (confirmed == true && mounted) {
      await _createBooking(slot);
    }
  }

  Future<void> _createBooking(AvailabilitySlotWithBooking slot) async {
    try {
      final userId = _authController.user?.uid;
      if (userId == null) throw Exception('未登入');
      if (_selectedCoachId == null) throw Exception('未選擇教練');

      final success = await _appointmentController.createAppointment(
        AppointmentModel(
          id: '', // 由後端生成
          coachId: _selectedCoachId!,
          clientId: userId,
          startTime: slot.slot.startTime,
          endTime: slot.slot.endTime,
          status: AppointmentStatus.requested,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('預約成功！等待教練確認')),
          );
          // 重新載入時段列表
          await _loadCoachSlots();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('預約失敗，請稍後再試')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _errorService.handleError(context, e, customMessage: '創建預約失敗');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('預約教練課程'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 教練選擇區域
                CoachSelectorSection(
                  coaches: _relationshipController.coaches,
                  selectedCoachId: _selectedCoachId,
                  onCoachSelected: _onCoachSelected,
                ),

                const Divider(height: 1),

                // 可用時段顯示區域
                Expanded(
                  child: _selectedCoachId == null
                      ? _buildEmptyState()
                      : _buildSlotsView(),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '請選擇教練以查看可預約時段',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsView() {
    return Column(
      children: [
        // 日曆視圖
        AvailableSlotsCalendar(
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          availableSlots: _slotController.availableSlots,
          onDaySelected: _onDaySelected,
          onPageChanged: _onPageChanged,
        ),

        const Divider(height: 1),

        // 時段列表視圖
        Expanded(
          child: SlotListView(
            selectedDay: _selectedDay,
            availableSlots: _slotController.availableSlots,
            onSlotTapped: _onSlotTapped,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // 清除狀態（避免記憶體洩漏）
    _slotController.clearAll();
    super.dispose();
  }
}
