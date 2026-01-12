import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/workout_record_model.dart';
import '../../../utils/datetime_utils.dart'; // ⭐ 使用時間工具
import '../../../utils/isolate_utils.dart';
import '_workout_cache_manager.dart';

/// 訓練記錄操作類別
///
/// 負責訓練記錄的 CRUD 操作
class WorkoutRecordOperations {
  final SupabaseClient _supabase;
  final WorkoutCacheManager _cacheManager;
  final Function(String) _logDebug;
  final Function(String) _logError;
  final bool _cacheRecords;

  WorkoutRecordOperations({
    required SupabaseClient supabase,
    required WorkoutCacheManager cacheManager,
    required Function(String) logDebug,
    required Function(String) logError,
    required bool cacheRecords,
  })  : _supabase = supabase,
        _cacheManager = cacheManager,
        _logDebug = logDebug,
        _logError = logError,
        _cacheRecords = cacheRecords;

  /// 獲取用戶已完成的訓練記錄（Cursor 分頁）
  Future<List<WorkoutRecord>> getUserRecords({
    required String userId,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      // 優化：檢查已完成記錄快取（5 分鐘內）
      if (cursor == null && _cacheRecords) {
        if (_cacheManager.isCompletedRecordsCacheValid(userId)) {
          final cached = _cacheManager.completedRecordsCache;
          if (cached != null) {
            _logDebug('⚡ 從快取返回 ${cached.length} 個已完成記錄');
            return limit >= cached.length ? cached : cached.sublist(0, limit);
          }
        }
      }

      _logDebug(
          '從 workout_plans 獲取用戶已完成的訓練記錄（Cursor 分頁）, cursor: $cursor, limit: $limit');

      // ⚡ 優化：使用 Cursor-based 分頁（基於 completed_date 欄位）
      // ⭐ v3.1: 新增 appointment_id 欄位（上課類型）
      var queryBuilder = _supabase
          .from('workout_plans')
          .select(
              'id, title, scheduled_date, completed_date, completed, total_volume, total_exercises, total_sets, plan_type, ui_plan_type, trainee_id, creator_id, user_id, exercises, note, created_at, updated_at, appointment_id')
          .eq('trainee_id', userId)
          .eq('completed', true);

      // 如果提供了游標，查詢比游標更舊的記錄
      if (cursor != null && cursor.isNotEmpty) {
        queryBuilder = queryBuilder.lt('completed_date', cursor);
        _logDebug('使用游標: $cursor（查詢更早的記錄）');
      }

      // 排序並限制返回數量
      final response = await queryBuilder
          .order('completed_date', ascending: false)
          .limit(limit);

      // ⚡ 使用 Isolate 解析大型列表（避免阻塞主執行緒）
      final records = await _parseWorkoutRecordsAsync(response as List);

      // 更新緩存
      if (_cacheRecords) {
        for (final record in records) {
          _cacheManager.setRecord(record.id, record);
        }

        if (cursor == null && records.isNotEmpty) {
          _cacheManager.updateCompletedRecordsCache(userId, records);
          _logDebug('⚡ 已快取 ${records.length} 個已完成記錄（5 分鐘有效）');
        }
      }

      _logDebug('成功獲取 ${records.length} 個訓練記錄（Cursor 分頁）');

      // 如果有結果，打印下一頁的游標（使用 date 欄位）
      if (records.isNotEmpty) {
        final nextCursor = DateTimeUtils.formatToUtcIso(records.last.date);
        _logDebug('下一頁游標: $nextCursor');
      }

      return records;
    } catch (e) {
      _logError('獲取訓練記錄失敗: $e');
      return [];
    }
  }

  /// 獲取用戶訓練計劃（含過濾條件，Cursor 分頁）
  Future<List<WorkoutRecord>> getUserPlans({
    required String userId,
    bool? completed,
    DateTime? startDate,
    DateTime? endDate,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      // ⚡ 優化：智能快取策略（從全部快取中過濾）
      if (cursor == null && _cacheRecords) {
        if (_cacheManager.isAllPlansCacheValid(userId)) {
          final allPlans = _cacheManager.allPlansCache;
          if (allPlans != null) {
            // 如果沒有過濾條件，直接返回全部快取
            if (completed == null && startDate == null && endDate == null) {
              _logDebug('⚡ 從快取返回 ${allPlans.length} 個訓練計劃');
              return limit >= allPlans.length
                  ? allPlans
                  : allPlans.sublist(0, limit);
            }

            // ⚡ 智能過濾：從快取中過濾符合條件的記錄
            List<WorkoutRecord> filtered = allPlans;

            // 過濾 completed 狀態
            if (completed != null) {
              filtered =
                  filtered.where((r) => r.completed == completed).toList();
            }

            // 過濾日期範圍
            if (startDate != null || endDate != null) {
              filtered = filtered.where((r) {
                final schedDate = r.date;
                if (startDate != null && schedDate.isBefore(startDate))
                  return false;
                if (endDate != null && schedDate.isAfter(endDate)) return false;
                return true;
              }).toList();
            }

            // 排序（與資料庫查詢保持一致）
            filtered.sort((a, b) {
              final aDate = a.date;
              final bDate = b.date;
              return completed == false
                  ? aDate.compareTo(bDate) // 未完成：升序
                  : bDate.compareTo(aDate); // 已完成：降序
            });

            _logDebug('⚡ 從快取中過濾出 ${filtered.length} 個訓練計劃');

            return limit >= filtered.length
                ? filtered
                : filtered.sublist(0, limit);
          }
        }
      }

      _logDebug('從 workout_plans 獲取用戶訓練計劃（Cursor 分頁）');
      _logDebug(
          '  - completed: $completed, startDate: $startDate, endDate: $endDate');
      _logDebug('  - cursor: $cursor, limit: $limit');

      // ⚡ 優化：使用 Cursor-based 分頁（基於 scheduled_date 欄位）
      // ⭐ v3.1: 新增 appointment_id 欄位（上課類型）
      var queryBuilder = _supabase
          .from('workout_plans')
          .select(
              'id, title, scheduled_date, completed, completed_date, total_volume, total_exercises, total_sets, plan_type, ui_plan_type, trainee_id, creator_id, user_id, note, training_time, updated_at, created_at, exercises, appointment_id')
          .eq('trainee_id', userId);

      // 篩選完成狀態
      if (completed != null) {
        queryBuilder = queryBuilder.eq('completed', completed);
      }

      // 篩選日期範圍（⭐ 使用 DateTimeUtils 統一處理）
      if (startDate != null) {
        queryBuilder = queryBuilder.gte('scheduled_date',
            DateTimeUtils.formatToUtcIso(startDate)); // ⭐ 統一工具類
      }
      if (endDate != null) {
        queryBuilder = queryBuilder.lt(
            'scheduled_date', DateTimeUtils.formatToUtcIso(endDate)); // ⭐ 統一工具類
      }

      // 如果提供了游標，查詢比游標更舊/更新的記錄
      if (cursor != null && cursor.isNotEmpty) {
        if (completed == false) {
          // 未完成：查詢比游標更晚的記錄
          queryBuilder = queryBuilder.gt('scheduled_date', cursor);
          _logDebug('使用游標: $cursor（查詢更晚的未完成計劃）');
        } else {
          // 已完成或全部：查詢比游標更早的記錄
          queryBuilder = queryBuilder.lt('scheduled_date', cursor);
          _logDebug('使用游標: $cursor（查詢更早的記錄）');
        }
      }

      // 排序並限制數量，然後執行查詢
      final response = await queryBuilder
          .order('scheduled_date', ascending: completed == false)
          .limit(limit);

      // ⚡ 使用 Isolate 解析大型列表（避免阻塞主執行緒）
      final plans = await _parseWorkoutRecordsAsync(response as List);

      _logDebug('成功獲取 ${plans.length} 個訓練計劃（Cursor 分頁）');

      // ⚡ 智能快取更新
      if (_cacheRecords && cursor == null) {
        if (completed == null &&
            startDate == null &&
            endDate == null &&
            plans.isNotEmpty) {
          _cacheManager.updateAllPlansCache(userId, plans);
          _logDebug('⚡ 已快取 ${plans.length} 個訓練計劃（5 分鐘有效）');
        }
      }

      // 如果有結果，打印下一頁的游標
      if (plans.isNotEmpty) {
        final nextCursor = DateTimeUtils.formatToUtcIso(plans.last.date);
        _logDebug('下一頁游標: $nextCursor');
      }

      return plans;
    } catch (e) {
      _logError('獲取訓練計劃失敗: $e');
      return [];
    }
  }

  /// 獲取單個訓練記錄詳情
  Future<WorkoutRecord?> getRecordById(String recordId) async {
    try {
      // ⚡ 總是從資料庫查詢完整數據（包含 exercises）
      _logDebug('從 workout_plans 獲取記錄: $recordId');

      // ⚡ 優化：明確指定所有需要的欄位（避免 SELECT *）
      // ⭐ v2.9.1: 新增 actual_start_time, actual_end_time, elapsed_seconds, training_status
      // ⭐ v3.1: 新增 appointment_id（上課類型）
      final response = await _supabase
          .from('workout_plans')
          .select(
              'id, user_id, trainee_id, creator_id, title, scheduled_date, completed_date, completed, '
              'total_volume, total_exercises, total_sets, plan_type, ui_plan_type, exercises, note, training_time, '
              'actual_start_time, actual_end_time, elapsed_seconds, training_status, appointment_id, '
              'created_at, updated_at')
          .eq('id', recordId)
          .single();

      final record = WorkoutRecord.fromSupabase(response);

      // 更新緩存（完整數據）
      if (_cacheRecords) {
        _cacheManager.setRecord(recordId, record);
      }

      return record;
    } catch (e) {
      _logError('獲取訓練記錄詳情失敗: $e');
      return null;
    }
  }

  /// 獲取指定預約的訓練記錄 ⭐ v3.1 Session Mode
  Future<WorkoutRecord?> getRecordByAppointmentId(String appointmentId) async {
    try {
      _logDebug('從 workout_plans 獲取預約關聯記錄: $appointmentId');

      final response = await _supabase
          .from('workout_plans')
          .select(
              'id, user_id, trainee_id, creator_id, title, scheduled_date, completed_date, completed, '
              'total_volume, total_exercises, total_sets, plan_type, ui_plan_type, exercises, note, training_time, '
              'actual_start_time, actual_end_time, elapsed_seconds, training_status, appointment_id, '
              'created_at, updated_at')
          .eq('appointment_id', appointmentId)
          .maybeSingle();

      if (response == null) {
        _logDebug('未找到預約關聯的訓練計畫: $appointmentId');
        return null;
      }

      final record = WorkoutRecord.fromSupabase(response);
      _logDebug('找到預約關聯的訓練計畫: ${record.id}');
      return record;
    } catch (e) {
      _logError('獲取預約關聯訓練記錄失敗: $e');
      return null;
    }
  }

  /// 創建訓練記錄
  Future<WorkoutRecord> createRecord({
    required String userId,
    required WorkoutRecord record,
    required String Function() generateId,
  }) async {
    try {
      _logDebug('創建新的訓練記錄: ${record.title}');

      // 生成新的 ID（使用 Firestore 兼容格式）
      final newId = generateId();

      // ⭐ v2.1: 準備數據（使用 DateTimeUtils 統一處理時區）
      final recordData = {
        'id': newId, // 明確指定 ID
        'user_id': userId,
        'trainee_id': record.traineeId ?? userId,
        'creator_id': record.creatorId ?? userId,
        'title': record.title,
        'plan_type': 'self',
        'ui_plan_type': record.planType, // ⭐ v3.4: 訓練計畫類型（UI 顯示用）
        'scheduled_date': DateTimeUtils.formatToUtcIso(record.date), // ⭐ 統一工具類
        'completed_date': record.completed
            ? DateTimeUtils.formatToUtcIso(DateTime.now()) // ⭐ 統一工具類
            : null,
        'exercises': record.exerciseRecords.map((e) => e.toJson()).toList(),
        'completed': record.completed,
        'note': record.notes,
      };

      // ⭐ v2.1: 處理訓練時間範圍（統一使用 record.date 作為開始時間）
      if (record.trainingEndTime != null) {
        // 有結束時間，使用 TSTZRANGE
        final rangeStr = DateTimeUtils.formatToTstzRange(
          record.date, // ⭐ 統一：scheduled_date = training_time_range 開始時間
          record.trainingEndTime!,
        );
        recordData['training_time_range'] = rangeStr;

        // ⭐ Debug
        print('[WORKOUT_OPERATIONS] ⏰ 時間範圍:');
        print('  開始: ${record.date}');
        print('  結束: ${record.trainingEndTime}');
        print('  範圍: $rangeStr');
      } else {
        // 沒有結束時間，假設 1 小時
        recordData['training_time_range'] = DateTimeUtils.formatToTstzRange(
          record.date,
          record.date.add(const Duration(hours: 1)),
        );
      }

      // ⭐ v2.1: 向後兼容：保留舊的 training_time 欄位（等於 scheduled_date）
      recordData['training_time'] =
          DateTimeUtils.formatToUtcIso(record.date); // ⭐ 統一工具類

      // ⭐ v2.9.1: 訓練狀態追蹤欄位
      if (record.actualStartTime != null) {
        recordData['actual_start_time'] =
            DateTimeUtils.formatToUtcIso(record.actualStartTime!);
      }
      if (record.actualEndTime != null) {
        recordData['actual_end_time'] =
            DateTimeUtils.formatToUtcIso(record.actualEndTime!);
      }
      recordData['elapsed_seconds'] = record.elapsedSeconds;
      recordData['training_status'] = record.trainingStatus;

      // ⭐ v3.1: Session Mode 關聯預約 ID
      if (record.appointmentId != null) {
        recordData['appointment_id'] = record.appointmentId;
        _logDebug('關聯預約 ID: ${record.appointmentId}');
      }

      final response = await _supabase
          .from('workout_plans')
          .insert(recordData)
          .select(
              'id, user_id, trainee_id, creator_id, title, scheduled_date, completed_date, completed, '
              'total_volume, total_exercises, total_sets, plan_type, ui_plan_type, exercises, note, training_time, '
              'actual_start_time, actual_end_time, elapsed_seconds, training_status, appointment_id, '
              'created_at, updated_at')
          .single();

      final newRecord = WorkoutRecord.fromSupabase(response);

      // ⚡ Optimistic Update：同步更新快取
      // ⭐ 使用 traineeId 作為快取 key（因為查詢時用 traineeId）
      if (_cacheRecords) {
        final cacheKey = newRecord.traineeId ?? userId;
        _cacheManager.addRecord(cacheKey, newRecord);
        _logDebug('⚡ 已同步更新記錄快取（key: $cacheKey）');
      }

      _logDebug('訓練記錄創建成功: ${newRecord.id}');
      return newRecord;
    } on PostgrestException catch (e) {
      // ⭐ 捕獲 PostgreSQL 錯誤
      if (e.message.contains('workout_plans_no_overlap_trainee') ||
          e.message.contains(
              'conflicting key value violates exclusion constraint')) {
        _logError('訓練時間重疊：該學員在此時段已有訓練計畫');
        throw Exception('訓練時間重疊：該學員在此時段已有訓練計畫，請選擇其他時間');
      }
      _logError('創建訓練記錄失敗 (PostgrestException): ${e.message}');
      rethrow;
    } catch (e) {
      _logError('創建訓練記錄失敗: $e');
      rethrow;
    }
  }

  /// 更新訓練記錄
  Future<bool> updateRecord({
    required String userId,
    required WorkoutRecord record,
  }) async {
    try {
      _logDebug('更新訓練記錄: ${record.id}');

      // ⭐ v2.1: 準備更新數據，使用 DateTimeUtils 統一處理時區
      final recordData = {
        'trainee_id': record.traineeId ?? userId,
        'creator_id': record.creatorId ?? userId,
        'scheduled_date': DateTimeUtils.formatToUtcIso(record.date), // ⭐ 統一工具類
        'completed_date': record.completed
            ? DateTimeUtils.formatToUtcIso(DateTime.now()) // ⭐ 統一工具類
            : null,
        'exercises': record.exerciseRecords.map((e) => e.toJson()).toList(),
        'completed': record.completed,
        'note': record.notes,
      };

      // ⭐ v2.1: 處理訓練時間範圍
      // ⚠️ 注意：必須使用 trainingTime（原始開始時間），而非 date（可能是 completed_date）
      final rangeStart = record.trainingTime ?? record.date;
      if (record.trainingEndTime != null) {
        // 有結束時間，使用 TSTZRANGE
        recordData['training_time_range'] = DateTimeUtils.formatToTstzRange(
          rangeStart,
          record.trainingEndTime!,
        );
      } else {
        // 沒有結束時間，假設 1 小時
        recordData['training_time_range'] = DateTimeUtils.formatToTstzRange(
          rangeStart,
          rangeStart.add(const Duration(hours: 1)),
        );
      }

      // ⭐ 向後兼容：保留舊的 training_time 欄位（等於 scheduled_date）
      recordData['training_time'] = DateTimeUtils.formatToUtcIso(record.date);

      // ⭐ v2.9.1: 訓練狀態追蹤欄位
      if (record.actualStartTime != null) {
        recordData['actual_start_time'] =
            DateTimeUtils.formatToUtcIso(record.actualStartTime!);
      }
      if (record.actualEndTime != null) {
        recordData['actual_end_time'] =
            DateTimeUtils.formatToUtcIso(record.actualEndTime!);
      }
      recordData['elapsed_seconds'] = record.elapsedSeconds;
      recordData['training_status'] = record.trainingStatus;

      await _supabase
          .from('workout_plans')
          .update(recordData)
          .eq('id', record.id); // ⚡ 只用 ID 查詢，不限制 trainee_id（教練也能更新）

      // ⚡ Optimistic Update：同步更新快取
      // ⭐ 使用 traineeId 作為快取 key
      if (_cacheRecords) {
        final cacheKey = record.traineeId ?? userId;
        _cacheManager.updateRecord(cacheKey, record);
        _logDebug('⚡ 已同步更新記錄快取（key: $cacheKey）');
      }

      _logDebug('訓練記錄更新成功');
      return true;
    } on PostgrestException catch (e) {
      // ⭐ 捕獲 PostgreSQL 錯誤（更新時也可能違反排除約束）
      if (e.message.contains('workout_plans_no_overlap_trainee') ||
          e.message.contains(
              'conflicting key value violates exclusion constraint')) {
        _logError('訓練時間重疊：該學員在此時段已有訓練計畫');
        throw Exception('訓練時間重疊：該學員在此時段已有訓練計畫，請選擇其他時間');
      }
      _logError('更新訓練記錄失敗 (PostgrestException): ${e.message}');
      rethrow;
    } catch (e) {
      _logError('更新訓練記錄失敗: $e');
      return false;
    }
  }

  /// 刪除訓練記錄
  Future<bool> deleteRecord({
    required String userId,
    required String recordId,
  }) async {
    try {
      _logDebug('刪除訓練記錄: $recordId');

      await _supabase
          .from('workout_plans')
          .delete()
          .eq('id', recordId); // ⚡ 只用 ID 查詢，不限制 trainee_id（教練也能刪除）

      // ⚡ Optimistic Update：同步更新快取
      if (_cacheRecords) {
        _cacheManager.removeRecord(userId, recordId);
        _logDebug('⚡ 已同步更新記錄快取');
      }

      _logDebug('訓練記錄刪除成功');
      return true;
    } catch (e) {
      _logError('刪除訓練記錄失敗: $e');
      return false;
    }
  }

  /// ⚡ 預載入全部訓練計劃（異步，不阻塞當前查詢）
  Future<void> preloadAllPlans(String userId) async {
    try {
      // ⭐ v3.1: 新增 appointment_id 欄位（上課類型）
      final response = await _supabase
          .from('workout_plans')
          .select(
              'id, title, scheduled_date, completed, completed_date, total_volume, total_exercises, total_sets, plan_type, ui_plan_type, trainee_id, creator_id, user_id, note, training_time, updated_at, created_at, exercises, appointment_id')
          .eq('trainee_id', userId)
          .order('scheduled_date', ascending: false)
          .limit(100); // 預載入最近 100 筆

      // ⚡ 使用 Isolate 解析大型列表
      final plans = await _parseWorkoutRecordsAsync(response as List);

      if (_cacheRecords && plans.isNotEmpty) {
        _cacheManager.updateAllPlansCache(userId, plans);
        _logDebug('⚡ 背景預載入完成：已快取 ${plans.length} 個訓練計劃');
      }
    } catch (e) {
      _logError('預載入訓練計劃失敗: $e');
    }
  }

  // ============================================================================
  // Isolate 解析輔助方法
  // ============================================================================

  /// ⚡ 使用 Isolate 解析訓練記錄列表（避免阻塞主執行緒）
  Future<List<WorkoutRecord>> _parseWorkoutRecordsAsync(List<dynamic> rawData) async {
    // 小型列表直接在主執行緒解析
    if (rawData.length < IsolateUtils.listThreshold) {
      return rawData
          .map((data) => WorkoutRecord.fromSupabase(data as Map<String, dynamic>))
          .toList();
    }

    // 大型列表使用 Isolate
    try {
      final result = await compute(
        _parseWorkoutRecordsIsolate,
        rawData.cast<Map<String, dynamic>>(),
      );

      if (kDebugMode) {
        _logDebug('⚡ Isolate 解析完成：${result.length} 筆訓練');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        _logDebug('⚠️ Isolate 解析失敗，降級到主執行緒: $e');
      }
      // 降級：在主執行緒解析
      return rawData
          .map((data) => WorkoutRecord.fromSupabase(data as Map<String, dynamic>))
          .toList();
    }
  }

  /// 清除特定用戶的快取（用於刷新）⭐
  void clearUserCache(String userId) {
    if (_cacheRecords) {
      _cacheManager.clearUserPlans(userId);
      _logDebug('🔄 已清除用戶快取: $userId');
    }
  }
}

/// Isolate 內執行的解析函數（必須是頂層函數）
List<WorkoutRecord> _parseWorkoutRecordsIsolate(List<Map<String, dynamic>> rawData) {
  return rawData
      .map((data) => WorkoutRecord.fromSupabase(data))
      .toList();
}
