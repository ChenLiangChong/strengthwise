import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/models/client_availability_model.dart';
import 'package:strengthwise/services/interfaces/i_client_availability_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';
import 'package:strengthwise/utils/datetime_utils.dart';

/// Client Availability Service Supabase 實現
///
/// Phase 3: 雙向時間管理系統

/// ⭐ 定義 client_availability 表的標準查詢欄位
const String _kClientAvailabilitySelectFields = '''
  id, client_id, time_range, priority, notes, created_at, updated_at
''';

class ClientAvailabilityServiceSupabase implements IClientAvailabilityService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;

  ClientAvailabilityServiceSupabase(this._supabase, this._errorService);

  // ==================== 查詢方法 ====================

  @override
  Future<List<ClientAvailabilityModel>> getClientAvailability({
    required String clientId,
    AvailabilityPriority? priority,
  }) async {
    try {
      var query = _supabase
          .from('client_availability')
          .select(_kClientAvailabilitySelectFields)
          .eq('client_id', clientId);

      if (priority != null) {
        query = query.eq('priority', priority.toJson());
      }

      final response = await query.order('time_range', ascending: true);
      return (response as List)
          .map((json) => ClientAvailabilityModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError(
        '查詢學員可用時段失敗: $e',
        type: 'ClientAvailabilityServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<ClientAvailabilityModel?> getAvailabilityById(String id) async {
    try {
      final response = await _supabase
          .from('client_availability')
          .select(_kClientAvailabilitySelectFields)
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return ClientAvailabilityModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '查詢可用時段詳情失敗: $e',
        type: 'ClientAvailabilityServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<List<ClientAvailabilityModel>> getAvailabilityInRange({
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // 使用 PostgreSQL 範圍重疊運算子
      final rangeStr = DateTimeUtils.formatToTstzRange(startDate, endDate);

      final response = await _supabase
          .from('client_availability')
          .select(_kClientAvailabilitySelectFields)
          .eq('client_id', clientId)
          .filter('time_range', 'ov', rangeStr)
          .order('time_range', ascending: true);

      return (response as List)
          .map((json) => ClientAvailabilityModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError(
        '查詢日期範圍內可用時段失敗: $e',
        type: 'ClientAvailabilityServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<List<ClientAvailabilityModel>> getClientAvailabilityForCoach({
    required String coachId,
    required String clientId,
  }) async {
    // RLS 策略會自動檢查 coaching_relationships
    // 這裡直接查詢即可
    return getClientAvailability(clientId: clientId);
  }

  // ==================== CRUD 操作 ====================

  @override
  Future<ClientAvailabilityModel> createAvailability(
    ClientAvailabilityModel availability,
  ) async {
    try {
      final data = availability.toSupabase(includeId: false);

      final response = await _supabase
          .from('client_availability')
          .insert(data)
          .select(_kClientAvailabilitySelectFields)
          .single();

      return ClientAvailabilityModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '創建可用時段失敗: $e',
        type: 'ClientAvailabilityServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<ClientAvailabilityModel> updateAvailability(
    ClientAvailabilityModel availability,
  ) async {
    try {
      final data = availability.toSupabase(includeId: false);

      final response = await _supabase
          .from('client_availability')
          .update(data)
          .eq('id', availability.id)
          .select(_kClientAvailabilitySelectFields)
          .single();

      return ClientAvailabilityModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError(
        '更新可用時段失敗: $e',
        type: 'ClientAvailabilityServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteAvailability(String id) async {
    try {
      await _supabase.from('client_availability').delete().eq('id', id);
    } catch (e) {
      _errorService.logError(
        '刪除可用時段失敗: $e',
        type: 'ClientAvailabilityServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<List<ClientAvailabilityModel>> batchCreateAvailability(
    List<ClientAvailabilityModel> availabilities,
  ) async {
    try {
      final dataList =
          availabilities.map((a) => a.toSupabase(includeId: false)).toList();

      final response = await _supabase
          .from('client_availability')
          .insert(dataList)
          .select(_kClientAvailabilitySelectFields);

      return (response as List)
          .map((json) => ClientAvailabilityModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError(
        '批量創建可用時段失敗: $e',
        type: 'ClientAvailabilityServiceError',
      );
      rethrow;
    }
  }

  // ==================== 輔助方法 ====================

  @override
  Future<bool> hasConflict({
    required String clientId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeId,
  }) async {
    try {
      final rangeStr = DateTimeUtils.formatToTstzRange(startTime, endTime);

      var query = _supabase
          .from('client_availability')
          .select('id')
          .eq('client_id', clientId)
          .filter('time_range', 'ov', rangeStr);

      // 排除自己（更新時）
      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }

      final response = await query;
      return (response as List).isNotEmpty;
    } catch (e) {
      _errorService.logError(
        '檢查時段衝突失敗: $e',
        type: 'ClientAvailabilityServiceError',
      );
      rethrow;
    }
  }

  @override
  Future<List<ClientAvailabilityModel>> getPreferredTimeSlots({
    required String clientId,
    required DateTime date,
  }) async {
    try {
      // 查詢指定日期的時段
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final slots = await getAvailabilityInRange(
        clientId: clientId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      // 依優先級排序（preferred > available > avoid）
      slots.sort((a, b) {
        final priorityOrder = {
          AvailabilityPriority.preferred: 0,
          AvailabilityPriority.available: 1,
          AvailabilityPriority.avoid: 2,
        };
        return (priorityOrder[a.priority] ?? 1)
            .compareTo(priorityOrder[b.priority] ?? 1);
      });

      return slots;
    } catch (e) {
      _errorService.logError(
        '查詢偏好時段失敗: $e',
        type: 'ClientAvailabilityServiceError',
      );
      rethrow;
    }
  }
}
