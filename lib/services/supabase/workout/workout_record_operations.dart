import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/workout_record_model.dart';
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

      _logDebug('從 workout_plans 獲取用戶已完成的訓練記錄（Cursor 分頁）, cursor: $cursor, limit: $limit');

      // ⚡ 優化：使用 Cursor-based 分頁（基於 completed_date 欄位）
      var queryBuilder = _supabase
          .from('workout_plans')
          .select(
              'id, title, scheduled_date, completed_date, completed, total_volume, total_exercises, total_sets, plan_type, trainee_id, creator_id, user_id, exercises, note, created_at, updated_at')
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

      final records = (response as List)
          .map((data) => WorkoutRecord.fromSupabase(data))
          .toList();

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
        final nextCursor = records.last.date.toIso8601String();
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
              return limit >= allPlans.length ? allPlans : allPlans.sublist(0, limit);
            }

            // ⚡ 智能過濾：從快取中過濾符合條件的記錄
            List<WorkoutRecord> filtered = allPlans;

            // 過濾 completed 狀態
            if (completed != null) {
              filtered = filtered.where((r) => r.completed == completed).toList();
            }

            // 過濾日期範圍
            if (startDate != null || endDate != null) {
              filtered = filtered.where((r) {
                final schedDate = r.date;
                if (startDate != null && schedDate.isBefore(startDate)) return false;
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

            return limit >= filtered.length ? filtered : filtered.sublist(0, limit);
          }
        }
      }

      _logDebug('從 workout_plans 獲取用戶訓練計劃（Cursor 分頁）');
      _logDebug('  - completed: $completed, startDate: $startDate, endDate: $endDate');
      _logDebug('  - cursor: $cursor, limit: $limit');

      // ⚡ 優化：使用 Cursor-based 分頁（基於 scheduled_date 欄位）
      var queryBuilder = _supabase
          .from('workout_plans')
          .select(
              'id, title, scheduled_date, completed, completed_date, total_volume, total_exercises, total_sets, plan_type, trainee_id, creator_id, user_id, note, training_time, updated_at, created_at, exercises')
          .eq('trainee_id', userId);

      // 篩選完成狀態
      if (completed != null) {
        queryBuilder = queryBuilder.eq('completed', completed);
      }

      // 篩選日期範圍
      if (startDate != null) {
        queryBuilder =
            queryBuilder.gte('scheduled_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        queryBuilder =
            queryBuilder.lt('scheduled_date', endDate.toIso8601String());
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

      final plans = (response as List)
          .map((data) => WorkoutRecord.fromSupabase(data))
          .toList();

      _logDebug('成功獲取 ${plans.length} 個訓練計劃（Cursor 分頁）');

      // ⚡ 智能快取更新
      if (_cacheRecords && cursor == null) {
        if (completed == null && startDate == null && endDate == null && plans.isNotEmpty) {
          _cacheManager.updateAllPlansCache(userId, plans);
          _logDebug('⚡ 已快取 ${plans.length} 個訓練計劃（5 分鐘有效）');
        }
      }

      // 如果有結果，打印下一頁的游標
      if (plans.isNotEmpty) {
        final nextCursor = plans.last.date.toIso8601String();
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
      final response = await _supabase
          .from('workout_plans')
          .select(
              'id, user_id, trainee_id, creator_id, title, scheduled_date, completed_date, completed, '
              'total_volume, total_exercises, total_sets, plan_type, exercises, note, training_time, '
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

      // 準備數據（存入 workout_plans 表）
      final recordData = {
        'id': newId, // 明確指定 ID
        'user_id': userId,
        'trainee_id': userId,
        'creator_id': userId,
        'title': record.title,
        'plan_type': 'self',
        'scheduled_date': record.date.toIso8601String(),
        'completed_date':
            record.completed ? DateTime.now().toIso8601String() : null,
        'training_time': record.trainingTime?.toIso8601String(),
        'exercises': record.exerciseRecords.map((e) => e.toJson()).toList(),
        'completed': record.completed,
        'note': record.notes,
      };

      final response = await _supabase
          .from('workout_plans')
          .insert(recordData)
          .select()
          .single();

      final newRecord = WorkoutRecord.fromSupabase(response);

      // ⚡ Optimistic Update：同步更新快取
      if (_cacheRecords) {
        _cacheManager.addRecord(userId, newRecord);
        _logDebug('⚡ 已同步更新記錄快取');
      }

      _logDebug('訓練記錄創建成功: ${newRecord.id}');
      return newRecord;
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

      final recordData = {
        'scheduled_date': record.date.toIso8601String(),
        'completed_date':
            record.completed ? DateTime.now().toIso8601String() : null,
        'training_time': record.trainingTime?.toIso8601String(),
        'exercises': record.exerciseRecords.map((e) => e.toJson()).toList(),
        'completed': record.completed,
        'note': record.notes,
      };

      await _supabase
          .from('workout_plans')
          .update(recordData)
          .eq('id', record.id)
          .eq('trainee_id', userId);

      // ⚡ Optimistic Update：同步更新快取
      if (_cacheRecords) {
        _cacheManager.updateRecord(userId, record);
        _logDebug('⚡ 已同步更新記錄快取');
      }

      _logDebug('訓練記錄更新成功');
      return true;
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
          .eq('id', recordId)
          .eq('trainee_id', userId);

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
      final response = await _supabase
          .from('workout_plans')
          .select(
              'id, title, scheduled_date, completed, completed_date, total_volume, total_exercises, total_sets, plan_type, trainee_id, creator_id, user_id, note, training_time, updated_at, created_at, exercises')
          .eq('trainee_id', userId)
          .order('scheduled_date', ascending: false)
          .limit(100); // 預載入最近 100 筆

      final plans = (response as List)
          .map((data) => WorkoutRecord.fromSupabase(data))
          .toList();

      if (_cacheRecords && plans.isNotEmpty) {
        _cacheManager.updateAllPlansCache(userId, plans);
        _logDebug('⚡ 背景預載入完成：已快取 ${plans.length} 個訓練計劃');
      }
    } catch (e) {
      _logError('預載入訓練計劃失敗: $e');
    }
  }
}

