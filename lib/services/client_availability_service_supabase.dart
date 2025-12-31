import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/models/client_availability_model.dart';
import 'package:strengthwise/services/interfaces/i_client_availability_service.dart';
import 'package:strengthwise/utils/datetime_utils.dart';

/// Client Availability Service Supabase 實現
/// 
/// Phase 3: 雙向時間管理系統
class ClientAvailabilityServiceSupabase
    implements IClientAvailabilityService {
  final SupabaseClient _supabase;

  ClientAvailabilityServiceSupabase(this._supabase);

  // ==================== 查詢方法 ====================

  @override
  Future<List<ClientAvailabilityModel>> getClientAvailability({
    required String clientId,
    AvailabilityPriority? priority,
  }) async {
    var query = _supabase
        .from('client_availability')
        .select('*')
        .eq('client_id', clientId);

    if (priority != null) {
      query = query.eq('priority', priority.toJson());
    }

    final response = await query.order('time_range', ascending: true);
    return (response as List)
        .map((json) => ClientAvailabilityModel.fromSupabase(json))
        .toList();
  }

  @override
  Future<ClientAvailabilityModel?> getAvailabilityById(String id) async {
    final response = await _supabase
        .from('client_availability')
        .select('*')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ClientAvailabilityModel.fromSupabase(response);
  }

  @override
  Future<List<ClientAvailabilityModel>> getAvailabilityInRange({
    required String clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // 使用 PostgreSQL 範圍重疊運算子
    final rangeStr = DateTimeUtils.formatToTstzRange(startDate, endDate);

    final response = await _supabase
        .from('client_availability')
        .select('*')
        .eq('client_id', clientId)
        .filter('time_range', 'ov', rangeStr)
        .order('time_range', ascending: true);

    return (response as List)
        .map((json) => ClientAvailabilityModel.fromSupabase(json))
        .toList();
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
    final data = availability.toSupabase(includeId: false);

    final response = await _supabase
        .from('client_availability')
        .insert(data)
        .select()
        .single();

    return ClientAvailabilityModel.fromSupabase(response);
  }

  @override
  Future<ClientAvailabilityModel> updateAvailability(
    ClientAvailabilityModel availability,
  ) async {
    final data = availability.toSupabase(includeId: false);

    final response = await _supabase
        .from('client_availability')
        .update(data)
        .eq('id', availability.id)
        .select()
        .single();

    return ClientAvailabilityModel.fromSupabase(response);
  }

  @override
  Future<void> deleteAvailability(String id) async {
    await _supabase.from('client_availability').delete().eq('id', id);
  }

  @override
  Future<List<ClientAvailabilityModel>> batchCreateAvailability(
    List<ClientAvailabilityModel> availabilities,
  ) async {
    final dataList =
        availabilities.map((a) => a.toSupabase(includeId: false)).toList();

    final response =
        await _supabase.from('client_availability').insert(dataList).select();

    return (response as List)
        .map((json) => ClientAvailabilityModel.fromSupabase(json))
        .toList();
  }

  // ==================== 輔助方法 ====================

  @override
  Future<bool> hasConflict({
    required String clientId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeId,
  }) async {
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
  }

  @override
  Future<List<ClientAvailabilityModel>> getPreferredTimeSlots({
    required String clientId,
    required DateTime date,
  }) async {
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
  }
}

