import 'package:flutter/foundation.dart';
import '../../models/appointment_model.dart';

/// AppointmentStateManager - 預約狀態管理器
///
/// 管理預約相關的所有狀態數據
class AppointmentStateManager extends ChangeNotifier {
  // 預約列表（教練端或學員端）
  List<AppointmentModel> _appointments = [];

  // 待確認的預約（教練端）
  List<AppointmentModel> _pendingAppointments = [];

  // 即將到來的預約（未來 7 天）
  List<AppointmentModel> _upcomingAppointments = [];

  // 當前選中的預約
  AppointmentModel? _selectedAppointment;

  // 統計數據
  int _totalAppointments = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;
  double _attendanceRate = 0.0;

  // 當前查詢的日期範圍
  DateTime? _queryStartDate;
  DateTime? _queryEndDate;

  // 當前查詢的狀態篩選
  AppointmentStatus? _queryStatus;

  // 載入狀態
  bool _isLoading = false;
  String? _errorMessage;

  // ============================================================================
  // Getters
  // ============================================================================

  List<AppointmentModel> get appointments => _appointments;
  List<AppointmentModel> get pendingAppointments => _pendingAppointments;
  List<AppointmentModel> get upcomingAppointments => _upcomingAppointments;
  AppointmentModel? get selectedAppointment => _selectedAppointment;
  int get totalAppointments => _totalAppointments;
  int get completedCount => _completedCount;
  int get cancelledCount => _cancelledCount;
  double get attendanceRate => _attendanceRate;
  DateTime? get queryStartDate => _queryStartDate;
  DateTime? get queryEndDate => _queryEndDate;
  AppointmentStatus? get queryStatus => _queryStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ============================================================================
  // Setters
  // ============================================================================

  void setAppointments(List<AppointmentModel> appointments) {
    _appointments = appointments;
    notifyListeners();
  }

  void setPendingAppointments(List<AppointmentModel> appointments) {
    _pendingAppointments = appointments;
    notifyListeners();
  }

  void setUpcomingAppointments(List<AppointmentModel> appointments) {
    _upcomingAppointments = appointments;
    notifyListeners();
  }

  void setSelectedAppointment(AppointmentModel? appointment) {
    _selectedAppointment = appointment;
    notifyListeners();
  }

  void setStatistics({
    required int total,
    required int completed,
    required int cancelled,
    required double attendanceRate,
  }) {
    _totalAppointments = total;
    _completedCount = completed;
    _cancelledCount = cancelled;
    _attendanceRate = attendanceRate;
    notifyListeners();
  }

  void setQueryParams({
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) {
    _queryStartDate = startDate;
    _queryEndDate = endDate;
    _queryStatus = status;
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }

  // ============================================================================
  // 狀態更新輔助方法
  // ============================================================================

  /// 更新本地預約狀態（避免重新查詢）
  void updateAppointmentStatus(String appointmentId, AppointmentStatus newStatus) {
    // 更新主列表
    final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
    if (index != -1) {
      _appointments[index] = _appointments[index].copyWith(status: newStatus);
    }

    // 更新待確認列表
    _pendingAppointments.removeWhere((apt) => apt.id == appointmentId);

    // 更新即將到來列表
    final upcomingIndex = _upcomingAppointments.indexWhere((apt) => apt.id == appointmentId);
    if (upcomingIndex != -1) {
      _upcomingAppointments[upcomingIndex] =
          _upcomingAppointments[upcomingIndex].copyWith(status: newStatus);
    }

    // 更新選中的預約
    final selected = _selectedAppointment;
    if (selected?.id == appointmentId && selected != null) {
      _selectedAppointment = selected.copyWith(status: newStatus);
    }

    notifyListeners();
  }

  /// 清除所有狀態
  void clearAll() {
    _appointments.clear();
    _pendingAppointments.clear();
    _upcomingAppointments.clear();
    _selectedAppointment = null;
    _totalAppointments = 0;
    _completedCount = 0;
    _cancelledCount = 0;
    _attendanceRate = 0.0;
    _queryStartDate = null;
    _queryEndDate = null;
    _queryStatus = null;
    _errorMessage = null;
    notifyListeners();
  }
}

