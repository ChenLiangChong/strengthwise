import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/availability_slot_model.dart';
import 'interfaces/i_availability_slot_service.dart';
import 'core/error_handling_service.dart';

/// AvailabilitySlotServiceSupabase - Phase 2 時段服務實現
/// 
/// 實作 IAvailabilitySlotService 接口
/// 處理所有與 Supabase availability_slots 表的互動
class AvailabilitySlotServiceSupabase implements IAvailabilitySlotService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;

  AvailabilitySlotServiceSupabase({
    SupabaseClient? supabase,
    ErrorHandlingService? errorService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _errorService = errorService ?? ErrorHandlingService();

  // ============================================================
  // 查詢方法（Query）
  // ============================================================

  @override
  Future<List<AvailabilitySlotModel>> getCoachSlots({
    required String coachId,
    DateTime? startDate,
    DateTime? endDate,
    bool includeOverrides = true,
  }) async {
    try {
      var query = _supabase
          .from('availability_slots')
          .select(
              'id, coach_id, time_range, recurrence_rule, is_override, notes, '
              'created_at, updated_at')
          .eq('coach_id', coachId);

      // 時間範圍篩選（使用 PostgreSQL 範圍重疊運算符 &&）
      if (startDate != null && endDate != null) {
        final rangeStr = '[${startDate.toIso8601String()},${endDate.toIso8601String()})';
        query = query.filter('time_range', 'ov', rangeStr);
      }

      // 覆蓋時段篩選
      if (!includeOverrides) {
        query = query.eq('is_override', false);
      }

      final response = await query.order('time_range', ascending: true);

      return (response as List)
          .map((json) => AvailabilitySlotModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError('查詢教練時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      rethrow;
    }
  }

  @override
  Future<AvailabilitySlotModel?> getSlotById(String slotId) async {
    try {
      final response = await _supabase
          .from('availability_slots')
          .select(
              'id, coach_id, time_range, recurrence_rule, is_override, notes, '
              'created_at, updated_at')
          .eq('id', slotId)
          .maybeSingle();

      if (response == null) return null;

      return AvailabilitySlotModel.fromSupabase(response);
    } catch (e) {
      _errorService.logError('查詢時段詳情失敗: $e',
          type: 'AvailabilitySlotServiceError');
      return null;
    }
  }

  @override
  Future<List<AvailabilitySlotModel>> getSlotsByDate({
    required String coachId,
    required DateTime date,
  }) async {
    try {
      // 查詢當天 00:00 到 23:59 的時段
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      return getCoachSlots(
        coachId: coachId,
        startDate: startOfDay,
        endDate: endOfDay,
      );
    } catch (e) {
      _errorService.logError('查詢特定日期時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      rethrow;
    }
  }

  @override
  Future<List<AvailabilitySlotWithBooking>> getAvailableSlots({
    required String coachId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // 調用資料庫函數獲取可用時段
      final response = await _supabase.rpc('get_available_slots', params: {
        'p_coach_id': coachId,
        'p_start_time': startDate.toIso8601String(),
        'p_end_time': endDate.toIso8601String(),
      });

      final results = response as List;
      return results.map((json) {
        // ⚠️ 注意：資料庫函數只返回 slot_id, time_range, is_booked
        // 缺少的欄位使用預設值（未來可優化資料庫函數）
        final slot = AvailabilitySlotModel.fromSupabase({
          'id': json['slot_id'] as String,
          'coach_id': coachId,
          'time_range': json['time_range'] as String,
          'recurrence_rule': json['recurrence_rule'] as String?,  // 可能為 null
          'is_override': json['is_override'] as bool? ?? false,
          'notes': json['notes'] as String?,  // 可能為 null
          'created_at': json['created_at'] as String? ?? DateTime.now().toIso8601String(),
          'updated_at': json['updated_at'] as String? ?? DateTime.now().toIso8601String(),
        });

        return AvailabilitySlotWithBooking(
          slot: slot,
          isBooked: json['is_booked'] as bool,
        );
      }).toList();
    } catch (e) {
      _errorService.logError('查詢可用時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      // 備用方案：客戶端實現
      return _getAvailableSlotsFallback(
        coachId: coachId,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  /// 備用方案：客戶端實現可用時段查詢
  Future<List<AvailabilitySlotWithBooking>> _getAvailableSlotsFallback({
    required String coachId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // 1. 查詢所有時段
      final slots = await getCoachSlots(
        coachId: coachId,
        startDate: startDate,
        endDate: endDate,
      );

      // 2. 查詢所有預約
      final appointments = await _supabase
          .from('appointments')
          .select('id, time_range')
          .eq('coach_id', coachId)
          .inFilter('status', ['requested', 'confirmed'])
          .gte('time_range',
              '[${startDate.toIso8601String()},${startDate.toIso8601String()})')
          .lte('time_range',
              '[${endDate.toIso8601String()},${endDate.toIso8601String()})');

      // 3. 標記已預約時段
      return slots.map((slot) {
        final isBooked = (appointments as List).any((apt) {
          // 簡化的重疊檢查（實際應解析 TSTZRANGE）
          return true; // TODO: 實作 TSTZRANGE 重疊檢查
        });

        return AvailabilitySlotWithBooking(
          slot: slot,
          isBooked: isBooked,
        );
      }).toList();
    } catch (e) {
      _errorService.logError('備用可用時段查詢失敗: $e',
          type: 'AvailabilitySlotServiceError');
      rethrow;
    }
  }

  @override
  Future<List<AvailabilitySlotModel>> getRecurringSlots(String coachId) async {
    try {
      final response = await _supabase
          .from('availability_slots')
          .select(
              'id, coach_id, time_range, recurrence_rule, is_override, notes, '
              'created_at, updated_at')
          .eq('coach_id', coachId)
          .not('recurrence_rule', 'is', null)
          .order('time_range', ascending: true);

      return (response as List)
          .map((json) => AvailabilitySlotModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError('查詢週期性時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      rethrow;
    }
  }

  @override
  Future<List<AvailabilitySlotModel>> getOneTimeSlots(String coachId) async {
    try {
      final response = await _supabase
          .from('availability_slots')
          .select(
              'id, coach_id, time_range, recurrence_rule, is_override, notes, '
              'created_at, updated_at')
          .eq('coach_id', coachId)
          .isFilter('recurrence_rule', null)
          .eq('is_override', false)
          .order('time_range', ascending: true);

      return (response as List)
          .map((json) => AvailabilitySlotModel.fromSupabase(json))
          .toList();
    } catch (e) {
      _errorService.logError('查詢單次時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      rethrow;
    }
  }

  @override
  Future<bool> isSlotBooked(String slotId) async {
    try {
      // 查詢該時段是否有預約
      final slot = await getSlotById(slotId);
      if (slot == null) return false;

      final appointments = await _supabase
          .from('appointments')
          .select('id')
          .eq('coach_id', slot.coachId)
          .inFilter('status', ['requested', 'confirmed'])
          .gte('time_range',
              '[${slot.startTime.toIso8601String()},${slot.startTime.toIso8601String()})')
          .lte('time_range',
              '[${slot.endTime.toIso8601String()},${slot.endTime.toIso8601String()})');

      return (appointments as List).isNotEmpty;
    } catch (e) {
      _errorService.logError('檢查時段是否已預約失敗: $e',
          type: 'AvailabilitySlotServiceError');
      return false;
    }
  }

  // ============================================================
  // 操作方法（Operations）
  // ============================================================

  @override
  Future<String> createSlot(AvailabilitySlotModel slot) async {
    try {
      final response = await _supabase
          .from('availability_slots')
          .insert(slot.toMap(includeId: false)) // 創建時不包含 id，讓 Supabase 生成
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      _errorService.logError('創建時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      rethrow;
    }
  }

  @override
  Future<List<String>> createRecurringSlots({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    required String recurrenceRule,
    String? notes,
  }) async {
    try {
      // 解析週期性規則並生成多個時段
      // TODO: 根據 RRULE 生成時段實例
      // 這裡簡化實現：只創建一個帶 recurrence_rule 的時段
      final slot = AvailabilitySlotModel(
        id: '', // 將由 Supabase 生成
        coachId: coachId,
        startTime: startTime,
        endTime: endTime,
        recurrenceRule: recurrenceRule,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slotId = await createSlot(slot);
      return [slotId];
    } catch (e) {
      _errorService.logError('創建週期性時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      rethrow;
    }
  }

  @override
  Future<void> updateSlot({
    required String slotId,
    required AvailabilitySlotModel slot,
  }) async {
    try {
      await _supabase
          .from('availability_slots')
          .update(slot.toMap())
          .eq('id', slotId);
    } catch (e) {
      _errorService.logError('更新時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      rethrow;
    }
  }

  @override
  Future<void> deleteSlot(String slotId) async {
    try {
      // 檢查是否已被預約
      final isBooked = await isSlotBooked(slotId);
      if (isBooked) {
        throw Exception('無法刪除已被預約的時段');
      }

      await _supabase.from('availability_slots').delete().eq('id', slotId);
    } catch (e) {
      _errorService.logError('刪除時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      rethrow;
    }
  }

  @override
  Future<int> deleteSlots(List<String> slotIds) async {
    try {
      int deletedCount = 0;

      for (final slotId in slotIds) {
        try {
          await deleteSlot(slotId);
          deletedCount++;
        } catch (e) {
          // 繼續刪除其他時段
          _errorService.logError('刪除時段 $slotId 失敗: $e',
              type: 'AvailabilitySlotServiceError');
        }
      }

      return deletedCount;
    } catch (e) {
      _errorService.logError('批量刪除時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      return 0;
    }
  }

  @override
  Future<String> createOverrideSlot({
    required String coachId,
    required DateTime startTime,
    required DateTime endTime,
    required String notes,
  }) async {
    try {
      final slot = AvailabilitySlotModel(
        id: '', // 將由 Supabase 生成
        coachId: coachId,
        startTime: startTime,
        endTime: endTime,
        isOverride: true,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await createSlot(slot);
    } catch (e) {
      _errorService.logError('創建覆蓋時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      rethrow;
    }
  }

  @override
  Future<void> deleteOverrideSlot(String slotId) async {
    try {
      await _supabase
          .from('availability_slots')
          .delete()
          .eq('id', slotId)
          .eq('is_override', true);
    } catch (e) {
      _errorService.logError('刪除覆蓋時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      rethrow;
    }
  }

  // ============================================================
  // 批量操作（Batch Operations）
  // ============================================================

  @override
  Future<List<String>> createSlotsBatch(
      List<AvailabilitySlotModel> slots) async {
    try {
      final slotsData = slots.map((slot) => slot.toMap(includeId: false)).toList();

      final response = await _supabase
          .from('availability_slots')
          .insert(slotsData)
          .select('id');

      return (response as List).map((r) => r['id'] as String).toList();
    } catch (e) {
      _errorService.logError('批量創建時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      rethrow;
    }
  }

  @override
  Future<List<String>> copyWeekSlots({
    required String coachId,
    required DateTime sourceWeekStart,
    required DateTime targetWeekStart,
  }) async {
    try {
      // 1. 查詢來源週的時段
      final sourceWeekEnd = sourceWeekStart.add(const Duration(days: 7));
      final sourceSlots = await getCoachSlots(
        coachId: coachId,
        startDate: sourceWeekStart,
        endDate: sourceWeekEnd,
        includeOverrides: false,
      );

      // 2. 計算時間差
      final daysDifference = targetWeekStart.difference(sourceWeekStart).inDays;

      // 3. 創建新時段（調整時間）
      final newSlots = sourceSlots.map((slot) {
        final newStartTime = slot.startTime.add(Duration(days: daysDifference));
        final newEndTime = slot.endTime.add(Duration(days: daysDifference));

        return AvailabilitySlotModel(
          id: '', // 新 ID
          coachId: coachId,
          startTime: newStartTime,
          endTime: newEndTime,
          recurrenceRule: slot.recurrenceRule,
          notes: slot.notes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();

      return await createSlotsBatch(newSlots);
    } catch (e) {
      _errorService.logError('複製週時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      rethrow;
    }
  }

  @override
  Future<int> deleteWeekSlots({
    required String coachId,
    required DateTime weekStart,
  }) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 7));
      final slots = await getCoachSlots(
        coachId: coachId,
        startDate: weekStart,
        endDate: weekEnd,
        includeOverrides: false,
      );

      final slotIds = slots.map((slot) => slot.id).toList();
      return await deleteSlots(slotIds);
    } catch (e) {
      _errorService.logError('刪除週時段失敗: $e',
          type: 'AvailabilitySlotServiceError');
      return 0;
    }
  }
}

