import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment_model.dart';
import '../utils/datetime_utils.dart';
import 'interfaces/i_appointment_service.dart';
import 'core/error_handling_service.dart';

/// AppointmentServiceSupabase - Phase 2 預約服務實現
/// 
/// 實作 IAppointmentService 接口
/// 處理所有與 Supabase appointments 表的互動
class AppointmentServiceSupabase implements IAppointmentService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;

  AppointmentServiceSupabase({
    SupabaseClient? supabase,
    ErrorHandlingService? errorService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _errorService = errorService ?? ErrorHandlingService();

  // ============================================================
  // 查詢方法（Query）
  // ============================================================

  @override
  Future<List<AppointmentModel>> getCoachAppointments({
    required String coachId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) async {
    try {
      var query = _supabase
          .from('appointments')
          .select(
              'id, coach_id, client_id, time_range, status, workout_plan_id, '
              'notes, client_notes, coach_notes, cancellation_reason, '
              'cancelled_by, cancelled_at, created_at, updated_at')
          .eq('coach_id', coachId);

      // 時間範圍篩選（使用 TSTZRANGE 查詢）
      if (startDate != null) {
        query = query.gte('time_range',
            DateTimeUtils.formatToTstzRange(startDate, startDate));
      }
      if (endDate != null) {
        query = query.lte('time_range',
            DateTimeUtils.formatToTstzRange(endDate, endDate));
      }

      // 狀態篩選
      if (status != null) {
        query = query.eq('status', status.toSupabaseString());
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => AppointmentModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError('查詢教練預約失敗: $e',
          type: 'AppointmentServiceError');
      rethrow;
    }
  }

  @override
  Future<List<AppointmentModel>> getClientAppointments({
    required String clientId,
    DateTime? startDate,
    DateTime? endDate,
    AppointmentStatus? status,
  }) async {
    try {
      var query = _supabase
          .from('appointments')
          .select(
              'id, coach_id, client_id, time_range, status, workout_plan_id, '
              'notes, client_notes, coach_notes, cancellation_reason, '
              'cancelled_by, cancelled_at, created_at, updated_at')
          .eq('client_id', clientId);

      if (startDate != null) {
        query = query.gte('time_range',
            DateTimeUtils.formatToTstzRange(startDate, startDate));
      }
      if (endDate != null) {
        query = query.lte('time_range',
            DateTimeUtils.formatToTstzRange(endDate, endDate));
      }

      if (status != null) {
        query = query.eq('status', status.toSupabaseString());
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => AppointmentModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError('查詢學員預約失敗: $e',
          type: 'AppointmentServiceError');
      rethrow;
    }
  }

  @override
  Future<AppointmentModel?> getAppointmentById(String appointmentId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select(
              'id, coach_id, client_id, time_range, status, workout_plan_id, '
              'notes, client_notes, coach_notes, cancellation_reason, '
              'cancelled_by, cancelled_at, created_at, updated_at')
          .eq('id', appointmentId)
          .maybeSingle();

      if (response == null) return null;

      return AppointmentModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError('查詢預約詳情失敗: $e',
          type: 'AppointmentServiceError');
      return null;
    }
  }

  @override
  Future<List<AppointmentModel>> getPendingAppointments(String coachId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select(
              'id, coach_id, client_id, time_range, status, workout_plan_id, '
              'notes, client_notes, coach_notes, cancellation_reason, '
              'cancelled_by, cancelled_at, created_at, updated_at')
          .eq('coach_id', coachId)
          .eq('status', 'requested')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AppointmentModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError('查詢待確認預約失敗: $e',
          type: 'AppointmentServiceError');
      rethrow;
    }
  }

  @override
  Future<List<AppointmentModel>> getUpcomingAppointments({
    required String userId,
    required bool isCoach,
  }) async {
    try {
      final now = DateTime.now();
      final weekLater = now.add(const Duration(days: 7));

      var query = _supabase
          .from('appointments')
          .select(
              'id, coach_id, client_id, time_range, status, workout_plan_id, '
              'notes, client_notes, coach_notes, cancellation_reason, '
              'cancelled_by, cancelled_at, created_at, updated_at')
          .gte('time_range',
              DateTimeUtils.formatToTstzRange(now, now))
          .lte('time_range',
              DateTimeUtils.formatToTstzRange(weekLater, weekLater));

      // 根據角色篩選
      if (isCoach) {
        query = query.eq('coach_id', userId);
      } else {
        query = query.eq('client_id', userId);
      }

      // 只查詢已確認的預約
      query = query.inFilter('status', ['confirmed', 'completed']);

      final response = await query.order('time_range', ascending: true);

      return (response as List)
          .map((json) => AppointmentModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError('查詢即將到來的預約失敗: $e',
          type: 'AppointmentServiceError');
      rethrow;
    }
  }

  @override
  Future<bool> checkConflict({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeAppointmentId,
  }) async {
    try {
      // 調用資料庫函數檢查衝突
      final response = await _supabase.rpc('check_appointment_conflict', params: {
        'p_coach_id': coachId,
        'p_time_range': DateTimeUtils.formatToTstzRange(startTime, endTime),
        'p_exclude_appointment_id': excludeAppointmentId,
      });

      return response as bool;
    } catch (e) {
      _errorService.logError('檢查時段衝突失敗: $e',
          type: 'AppointmentServiceError');
      // 如果函數不存在，使用客戶端查詢
      return _checkConflictFallback(
        coachId: coachId,
        startTime: startTime,
        endTime: endTime,
        excludeAppointmentId: excludeAppointmentId,
      );
    }
  }

  /// 備用衝突檢查（客戶端實現）
  Future<bool> _checkConflictFallback({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeAppointmentId,
  }) async {
    try {
      var query = _supabase
          .from('appointments')
          .select('id')
          .eq('coach_id', coachId)
          .inFilter('status', ['requested', 'confirmed']);

      if (excludeAppointmentId != null) {
        query = query.neq('id', excludeAppointmentId);
      }

      final response = await query;
      final appointments = (response as List)
          .map((json) => AppointmentModel.fromSupabase(json))
          .toList();

      // 檢查時間重疊
      for (final apt in appointments) {
        if (startTime.isBefore(apt.endTime) && endTime.isAfter(apt.startTime)) {
          return true; // 有衝突
        }
      }

      return false; // 無衝突
    } catch (e) {
      _errorService.logError('備用衝突檢查失敗: $e',
          type: 'AppointmentServiceError');
      return false;
    }
  }

  // ============================================================
  // 操作方法（Operations）
  // ============================================================

  @override
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      // 確保狀態為 requested
      final appointmentData = appointment
          .copyWith(status: AppointmentStatus.requested)
          .toMap(includeId: false); // 創建時不包含 id

      final response = await _supabase
          .from('appointments')
          .insert(appointmentData)
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      _errorService.logError('創建預約失敗: $e',
          type: 'AppointmentServiceError');
      rethrow;
    }
  }

  @override
  Future<void> confirmAppointment(String appointmentId,
      {String? coachNotes}) async {
    try {
      final updateData = {
        'status': 'confirmed',
        'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
      };

      if (coachNotes != null) {
        updateData['coach_notes'] = coachNotes;
      }

      await _supabase
          .from('appointments')
          .update(updateData)
          .eq('id', appointmentId);
    } catch (e) {
      _errorService.logError('確認預約失敗: $e',
          type: 'AppointmentServiceError');
      rethrow;
    }
  }

  @override
  Future<void> completeAppointment(String appointmentId,
      {String? coachNotes}) async {
    try {
      final updateData = {
        'status': 'completed',
        'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
      };

      if (coachNotes != null) {
        updateData['coach_notes'] = coachNotes;
      }

      await _supabase
          .from('appointments')
          .update(updateData)
          .eq('id', appointmentId);
    } catch (e) {
      _errorService.logError('完成預約失敗: $e',
          type: 'AppointmentServiceError');
      rethrow;
    }
  }

  @override
  Future<void> cancelAppointment({
    required String appointmentId,
    required String cancelledBy,
    required String reason,
  }) async {
    try {
      await _supabase.from('appointments').update({
        'status': 'cancelled',
        'cancellation_reason': reason,
        'cancelled_by': cancelledBy,
        'cancelled_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
        'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
      }).eq('id', appointmentId);
    } catch (e) {
      _errorService.logError('取消預約失敗: $e',
          type: 'AppointmentServiceError');
      rethrow;
    }
  }

  @override
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    try {
      await _supabase.from('appointments').update({
        'time_range':
            DateTimeUtils.formatToTstzRange(newStartTime, newEndTime),
        'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
      }).eq('id', appointmentId).eq('status', 'requested'); // 只允許待確認的預約
    } catch (e) {
      _errorService.logError('重新安排預約失敗: $e',
          type: 'AppointmentServiceError');
      rethrow;
    }
  }

  @override
  Future<void> updateClientNotes({
    required String appointmentId,
    required String clientNotes,
  }) async {
    try {
      await _supabase.from('appointments').update({
        'client_notes': clientNotes,
        'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
      }).eq('id', appointmentId);
    } catch (e) {
      _errorService.logError('更新學員備註失敗: $e',
          type: 'AppointmentServiceError');
      rethrow;
    }
  }

  @override
  Future<void> updateCoachNotes({
    required String appointmentId,
    required String coachNotes,
  }) async {
    try {
      await _supabase.from('appointments').update({
        'coach_notes': coachNotes,
        'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
      }).eq('id', appointmentId);
    } catch (e) {
      _errorService.logError('更新教練備註失敗: $e',
          type: 'AppointmentServiceError');
      rethrow;
    }
  }

  @override
  Future<void> linkWorkoutPlan({
    required String appointmentId,
    required String workoutPlanId,
  }) async {
    try {
      await _supabase.from('appointments').update({
        'workout_plan_id': workoutPlanId,
        'updated_at': DateTimeUtils.formatToUtcIso(DateTime.now()),
      }).eq('id', appointmentId);
    } catch (e) {
      _errorService.logError('關聯訓練計劃失敗: $e',
          type: 'AppointmentServiceError');
      rethrow;
    }
  }

  @override
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _supabase
          .from('appointments')
          .delete()
          .eq('id', appointmentId)
          .eq('status', 'requested'); // 只允許刪除待確認的預約
    } catch (e) {
      _errorService.logError('刪除預約失敗: $e',
          type: 'AppointmentServiceError');
      rethrow;
    }
  }

  // ============================================================
  // 統計方法（Statistics）
  // ============================================================

  @override
  Future<Map<String, int>> getAppointmentStats({
    required String coachId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('status')
          .eq('coach_id', coachId)
          .gte('time_range',
              DateTimeUtils.formatToTstzRange(startDate, startDate))
          .lte('time_range',
              DateTimeUtils.formatToTstzRange(endDate, endDate));

      final appointments = response as List;

      // 統計各狀態數量
      final stats = <String, int>{
        'requested': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (final apt in appointments) {
        final status = apt['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      _errorService.logError('查詢預約統計失敗: $e',
          type: 'AppointmentServiceError');
      return {'requested': 0, 'confirmed': 0, 'completed': 0, 'cancelled': 0};
    }
  }

  @override
  Future<double> getClientAttendanceRate({
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('status')
          .eq('client_id', clientId)
          .gte('time_range',
              DateTimeUtils.formatToTstzRange(startDate, startDate))
          .lte('time_range',
              DateTimeUtils.formatToTstzRange(endDate, endDate));

      final appointments = response as List;

      if (appointments.isEmpty) return 0.0;

      // 計算出席率（completed / (confirmed + completed)）
      final completed =
          appointments.where((apt) => apt['status'] == 'completed').length;
      final confirmed =
          appointments.where((apt) => apt['status'] == 'confirmed').length;

      final total = confirmed + completed;
      if (total == 0) return 0.0;

      return completed / total;
    } catch (e) {
      _errorService.logError('計算出席率失敗: $e',
          type: 'AppointmentServiceError');
      return 0.0;
    }
  }
}

