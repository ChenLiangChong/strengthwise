import 'package:flutter/foundation.dart';
import '../services/interfaces/i_appointment_service.dart';
import '../services/interfaces/i_readiness_service.dart'; // ⭐ v3.6: MVVM
import '../services/service_locator.dart'; // ⭐ v3.6: MVVM
import '../services/core/error_handling_service.dart';
import '../models/appointment_model.dart';
import '../models/readiness/daily_readiness_model.dart'; // ⭐ v3.6: MVVM
import 'appointment/appointment_state_manager.dart';
import 'appointment/appointment_query_manager.dart';
import 'appointment/appointment_coach_operations.dart';
import 'appointment/appointment_client_operations.dart';
import 'event_bus_controller.dart'; // ⭐ v3.5

/// AppointmentController - Phase 2 預約管理控制器
///
/// 管理教練-學員預約的創建、查詢、狀態更新等業務邏輯
/// 遵循完全解耦架構（透過 Interface 注入依賴）+ 子模組化設計
/// ⭐ v3.5: 統一發布預約事件（Controller 層負責事件發布）
class AppointmentController extends ChangeNotifier {
  final IAppointmentService _appointmentService;
  final ErrorHandlingService _errorService;
  final EventBusController _eventBusController; // ⭐ v3.5

  // 子模組
  late final AppointmentStateManager _state;
  late final AppointmentQueryManager _query;
  late final AppointmentCoachOperations _coachOps;
  late final AppointmentClientOperations _clientOps;

  AppointmentController(
    this._appointmentService,
    this._errorService,
    this._eventBusController, // ⭐ v3.5
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
  /// ⭐ v3.5: 操作成功後自動發布事件
  Future<bool> confirmAppointment(String appointmentId) async {
    // 先獲取預約資訊用於事件發布
    final appointment = _state.selectedAppointment?.id == appointmentId
        ? _state.selectedAppointment
        : await _appointmentService.getAppointmentById(appointmentId);

    final success = await _executeOperation(
      () => _coachOps.confirmAppointment(appointmentId),
      '確認預約失敗',
    );

    // ⭐ v3.5: 操作成功後發布事件
    if (success && appointment != null) {
      _eventBusController.publishAppointmentConfirmed(
        appointmentId: appointmentId,
        coachId: appointment.coachId,
        clientId: appointment.clientId,
      );
    }

    return success;
  }

  /// 拒絕預約
  /// ⭐ v3.5: 操作成功後自動發布事件（拒絕視為取消）
  Future<bool> rejectAppointment({
    required String appointmentId,
    required String cancelledBy,
    String reason = '教練拒絕',
  }) async {
    // 先獲取預約資訊用於事件發布
    final appointment = _state.selectedAppointment?.id == appointmentId
        ? _state.selectedAppointment
        : await _appointmentService.getAppointmentById(appointmentId);

    final success = await _executeOperation(
      () => _coachOps.rejectAppointment(
        appointmentId: appointmentId,
        cancelledBy: cancelledBy,
        reason: reason,
      ),
      '拒絕預約失敗',
    );

    // ⭐ v3.5: 操作成功後發布事件
    if (success && appointment != null) {
      _eventBusController.publishAppointmentCancelled(
        appointmentId: appointmentId,
        coachId: appointment.coachId,
        clientId: appointment.clientId,
      );
    }

    return success;
  }

  /// 完成預約
  /// ⭐ v3.5: 操作成功後自動發布事件
  Future<bool> completeAppointment(String appointmentId) async {
    // 先獲取預約資訊用於事件發布
    final appointment = _state.selectedAppointment?.id == appointmentId
        ? _state.selectedAppointment
        : await _appointmentService.getAppointmentById(appointmentId);

    final success = await _executeOperation(
      () => _coachOps.completeAppointment(appointmentId),
      '完成預約失敗',
    );

    // ⭐ v3.5: 操作成功後發布事件
    if (success && appointment != null) {
      _eventBusController.publishAppointmentCompleted(
        appointmentId: appointmentId,
        coachId: appointment.coachId,
        clientId: appointment.clientId,
      );
    }

    return success;
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

  /// ⭐ v3.5: 創建臨時課程（教練直接建立 confirmed 狀態的課程）
  /// MVVM 重構 - 透過 Controller 操作，事件由 Controller 自動發布
  Future<String?> createAdHocSession({
    required String coachId,
    required String clientId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    String? appointmentId;
    
    final success = await _executeOperation(
      () async {
        appointmentId = await _appointmentService.createAdHocSession(
          coachId: coachId,
          clientId: clientId,
          startTime: startTime,
          endTime: endTime,
          notes: notes,
        );
      },
      '創建臨時課程失敗',
    );

    // 操作成功後發布事件（臨時課程直接是 confirmed 狀態）
    if (success && appointmentId != null) {
      _eventBusController.publishAppointmentConfirmed(
        appointmentId: appointmentId!,
        coachId: coachId,
        clientId: clientId,
      );
    }

    return appointmentId;
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
  /// ⭐ v3.5: 操作成功後自動發布事件
  Future<bool> createAppointment(AppointmentModel appointment) async {
    final success = await _executeOperation(() async {
      await _clientOps.createAppointment(appointment);
      // 重新載入預約列表
      await loadClientAppointments(clientId: appointment.clientId);
    }, '創建預約失敗');

    // ⭐ v3.5: 操作成功後發布事件
    if (success) {
      _eventBusController.publishAppointmentCreated(
        appointmentId: appointment.id,
        coachId: appointment.coachId,
        clientId: appointment.clientId,
      );
    }

    return success;
  }

  /// 取消預約
  /// ⭐ v3.5: 操作成功後自動發布事件
  Future<bool> cancelAppointment({
    required String appointmentId,
    required String cancelledBy,
    required String reason,
  }) async {
    // 先獲取預約資訊用於事件發布
    final appointment = _state.selectedAppointment?.id == appointmentId
        ? _state.selectedAppointment
        : await _appointmentService.getAppointmentById(appointmentId);

    final success = await _executeOperation(
      () => _clientOps.cancelAppointment(
        appointmentId: appointmentId,
        cancelledBy: cancelledBy,
        reason: reason,
      ),
      '取消預約失敗',
    );

    // ⭐ v3.5: 操作成功後發布事件
    if (success && appointment != null) {
      _eventBusController.publishAppointmentCancelled(
        appointmentId: appointmentId,
        coachId: appointment.coachId,
        clientId: appointment.clientId,
      );
    }

    return success;
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
  /// ⭐ v3.9: 操作成功後自動發布事件
  Future<bool> rescheduleAppointment({
    required String appointmentId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    // 先獲取預約資訊用於事件發布
    final appointment = _state.selectedAppointment?.id == appointmentId
        ? _state.selectedAppointment
        : await _appointmentService.getAppointmentById(appointmentId);

    final success = await _executeOperation(
      () => _clientOps.rescheduleAppointment(
        appointmentId: appointmentId,
        newStartTime: newStartTime,
        newEndTime: newEndTime,
      ),
      '更新預約時間失敗',
    );

    // ⭐ v3.9: 操作成功後發布事件
    if (success && appointment != null) {
      _eventBusController.publishAppointmentRescheduled(
        appointmentId: appointmentId,
        coachId: appointment.coachId,
        clientId: appointment.clientId,
      );
    }

    return success;
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

  // ============================================================================
  // ⭐ MVVM 重構：直接查詢方法（返回結果，不更新 Controller 狀態）
  // ============================================================================

  /// 查詢學員的預約（直接返回結果）
  ///
  /// 用於首頁等需要直接獲取數據的場景
  Future<List<AppointmentModel>> getClientAppointments({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) async {
    try {
      return await _appointmentService.getClientAppointments(
        clientId: clientId,
        startDate: startDate,
        endDate: endDate,
        status: status,
      );
    } catch (e) {
      _errorService.logError(
        '查詢學員預約失敗: $e',
        type: 'AppointmentControllerError',
      );
      return [];
    }
  }

  /// 查詢教練的預約（直接返回結果）
  ///
  /// 用於首頁等需要直接獲取數據的場景
  Future<List<AppointmentModel>> getCoachAppointments({
    required String coachId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) async {
    try {
      return await _appointmentService.getCoachAppointments(
        coachId: coachId,
        startDate: startDate,
        endDate: endDate,
        status: status,
      );
    } catch (e) {
      _errorService.logError(
        '查詢教練預約失敗: $e',
        type: 'AppointmentControllerError',
      );
      return [];
    }
  }

  /// 查詢單筆預約（直接返回結果）
  Future<AppointmentModel?> getAppointmentById(String appointmentId) async {
    try {
      return await _appointmentService.getAppointmentById(appointmentId);
    } catch (e) {
      _errorService.logError(
        '查詢預約失敗: $e',
        type: 'AppointmentControllerError',
      );
      return null;
    }
  }

  /// 查詢預約的課前問卷（直接返回結果）
  /// ⭐ v3.6 MVVM 重構
  ///
  /// 用於課程紀錄頁面等需要直接獲取數據的場景
  Future<DailyReadinessModel?> getReadinessByAppointmentId(
    String appointmentId,
  ) async {
    try {
      final readinessService = serviceLocator<IReadinessService>();
      return await readinessService.getByAppointmentId(appointmentId);
    } catch (e) {
      _errorService.logError(
        '查詢課前問卷失敗: $e',
        type: 'AppointmentControllerError',
      );
      return null;
    }
  }

  @override
  void dispose() {
    _state.removeListener(notifyListeners);
    _state.dispose();
    super.dispose();
  }
}

