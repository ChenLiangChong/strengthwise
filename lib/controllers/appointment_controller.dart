import 'package:flutter/foundation.dart';
import '../services/interfaces/i_appointment_service.dart';
import '../services/core/error_handling_service.dart';
import '../models/appointment_model.dart';
import 'appointment/appointment_state_manager.dart';
import 'appointment/appointment_query_manager.dart';
import 'appointment/appointment_coach_operations.dart';
import 'appointment/appointment_client_operations.dart';

/// AppointmentController - Phase 2 預約管理控制器
///
/// 管理教練-學員預約的創建、查詢、狀態更新等業務邏輯
/// 遵循完全解耦架構（透過 Interface 注入依賴）+ 子模組化設計
class AppointmentController extends ChangeNotifier {
  final IAppointmentService _appointmentService;
  final ErrorHandlingService _errorService;

  // 子模組
  late final AppointmentStateManager _state;
  late final AppointmentQueryManager _query;
  late final AppointmentCoachOperations _coachOps;
  late final AppointmentClientOperations _clientOps;

  AppointmentController(
    this._appointmentService,
    this._errorService,
  ) {
    _state = AppointmentStateManager();
    _query = AppointmentQueryManager(_appointmentService, _state);
    _coachOps = AppointmentCoachOperations(_appointmentService, _state);
    _clientOps = AppointmentClientOperations(_appointmentService, _state);

    // 監聽狀態變化並通知 UI
    _state.addListener(notifyListeners);
  }

  // ============================================================================
  // 狀態訪問（委託給 StateManager）
  // ============================================================================

  bool get isLoading => _state.isLoading;
  String? get errorMessage => _state.errorMessage;
  List<AppointmentModel> get appointments => _state.appointments;
  List<AppointmentModel> get pendingAppointments => _state.pendingAppointments;
  List<AppointmentModel> get upcomingAppointments => _state.upcomingAppointments;
  AppointmentModel? get selectedAppointment => _state.selectedAppointment;
  int get totalAppointments => _state.totalAppointments;
  int get completedCount => _state.completedCount;
  int get cancelledCount => _state.cancelledCount;
  double get attendanceRate => _state.attendanceRate;
  DateTime? get queryStartDate => _state.queryStartDate;
  DateTime? get queryEndDate => _state.queryEndDate;
  AppointmentStatus? get queryStatus => _state.queryStatus;

  // ============================================================================
  // 教練端功能（委託給子模組）
  // ============================================================================

  /// 載入教練的預約列表
  Future<void> loadCoachAppointments({
    required String coachId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) async {
    await _executeOperation(() async {
      await _query.loadCoachAppointments(
        coachId: coachId,
        startDate: startDate,
        endDate: endDate,
        status: status,
      );
      await _query.loadCoachStats(coachId);
    }, '載入預約列表失敗');
  }

  /// 載入待確認的預約
  Future<void> loadPendingAppointments(String coachId) async {
    await _executeOperation(
      () => _query.loadPendingAppointments(coachId),
      '載入待確認預約失敗',
    );
  }

  /// 確認預約
  Future<bool> confirmAppointment(String appointmentId) async {
    return await _executeOperation(
      () => _coachOps.confirmAppointment(appointmentId),
      '確認預約失敗',
    );
  }

  /// 拒絕預約
  Future<bool> rejectAppointment({
    required String appointmentId,
    required String cancelledBy,
    String reason = '教練拒絕',
  }) async {
    return await _executeOperation(
      () => _coachOps.rejectAppointment(
        appointmentId: appointmentId,
        cancelledBy: cancelledBy,
        reason: reason,
      ),
      '拒絕預約失敗',
    );
  }

  /// 完成預約
  Future<bool> completeAppointment(String appointmentId) async {
    return await _executeOperation(
      () => _coachOps.completeAppointment(appointmentId),
      '完成預約失敗',
    );
  }

  /// 更新教練備註
  Future<bool> updateCoachNotes({
    required String appointmentId,
    required String notes,
  }) async {
    return await _executeOperation(
      () async {
        await _coachOps.updateCoachNotes(
          appointmentId: appointmentId,
          notes: notes,
        );
        // 重新載入預約詳情
        if (_state.selectedAppointment?.id == appointmentId) {
          await _query.selectAppointment(appointmentId);
        }
      },
      '更新備註失敗',
    );
  }

  /// 關聯訓練計劃
  Future<bool> linkWorkoutPlan({
    required String appointmentId,
    required String workoutPlanId,
  }) async {
    return await _executeOperation(
      () async {
        await _coachOps.linkWorkoutPlan(
          appointmentId: appointmentId,
          workoutPlanId: workoutPlanId,
        );
        // 重新載入預約詳情
        if (_state.selectedAppointment?.id == appointmentId) {
          await _query.selectAppointment(appointmentId);
        }
      },
      '關聯訓練計劃失敗',
    );
  }

  // ============================================================================
  // 學員端功能（委託給子模組）
  // ============================================================================

  /// 載入學員的預約列表
  Future<void> loadClientAppointments({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) async {
    await _executeOperation(() async {
      await _query.loadClientAppointments(
        clientId: clientId,
        startDate: startDate,
        endDate: endDate,
        status: status,
      );
      await _query.loadClientStats(clientId);
    }, '載入預約列表失敗');
  }

  /// 創建預約
  Future<bool> createAppointment(AppointmentModel appointment) async {
    return await _executeOperation(() async {
      await _clientOps.createAppointment(appointment);
      // 重新載入預約列表
      await loadClientAppointments(clientId: appointment.clientId);
    }, '創建預約失敗');
  }

  /// 取消預約
  Future<bool> cancelAppointment({
    required String appointmentId,
    required String cancelledBy,
    required String reason,
  }) async {
    return await _executeOperation(
      () => _clientOps.cancelAppointment(
        appointmentId: appointmentId,
        cancelledBy: cancelledBy,
        reason: reason,
      ),
      '取消預約失敗',
    );
  }

  /// 更新學員備註
  Future<bool> updateClientNotes({
    required String appointmentId,
    required String notes,
  }) async {
    return await _executeOperation(
      () async {
        await _clientOps.updateClientNotes(
          appointmentId: appointmentId,
          notes: notes,
        );
        // 重新載入預約詳情
        if (_state.selectedAppointment?.id == appointmentId) {
          await _query.selectAppointment(appointmentId);
        }
      },
      '更新備註失敗',
    );
  }

  /// 更新預約時間
  Future<bool> rescheduleAppointment({
    required String appointmentId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    return await _executeOperation(
      () => _clientOps.rescheduleAppointment(
        appointmentId: appointmentId,
        newStartTime: newStartTime,
        newEndTime: newEndTime,
      ),
      '更新預約時間失敗',
    );
  }

  // ============================================================================
  // 共用功能（委託給子模組）
  // ============================================================================

  /// 載入即將到來的預約
  Future<void> loadUpcomingAppointments({
    required String userId,
    required bool isCoach,
  }) async {
    await _executeOperation(
      () => _query.loadUpcomingAppointments(userId: userId, isCoach: isCoach),
      '載入即將到來的預約失敗',
    );
  }

  /// 查詢預約詳情
  Future<void> selectAppointment(String appointmentId) async {
    _state.clearError();
    try {
      await _query.selectAppointment(appointmentId);
    } catch (e) {
      _handleError('載入預約詳情失敗', e);
    }
  }

  /// 清除選中的預約
  void clearSelectedAppointment() {
    _state.setSelectedAppointment(null);
  }

  /// 檢查時段衝突
  Future<bool> checkTimeConflict({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeAppointmentId,
  }) async {
    try {
      return await _query.checkTimeConflict(
        coachId: coachId,
        startTime: startTime,
        endTime: endTime,
        excludeAppointmentId: excludeAppointmentId,
      );
    } catch (e) {
      _errorService.logError(
        '檢查時段衝突失敗: $e',
        type: 'AppointmentControllerError',
      );
      return false;
    }
  }

  // ============================================================================
  // 輔助方法
  // ============================================================================

  /// 統一的操作執行包裝器
  Future<bool> _executeOperation(
    Future<void> Function() operation,
    String errorMessage,
  ) async {
    _state.setLoading(true);
    _state.clearError();

    try {
      await operation();
      return true;
    } catch (e) {
      _handleError(errorMessage, e);
      return false;
    } finally {
      _state.setLoading(false);
    }
  }

  /// 錯誤處理
  void _handleError(String message, dynamic error) {
    _state.setError(message);
    _errorService.logError(
      '$message: $error',
      type: 'AppointmentControllerError',
    );

    if (kDebugMode) {
      print('❌ AppointmentController Error: $message - $error');
    }
  }

  /// 清除所有狀態
  void clearAll() {
    _state.clearAll();
  }

  @override
  void dispose() {
    _state.removeListener(notifyListeners);
    _state.dispose();
    super.dispose();
  }
}

