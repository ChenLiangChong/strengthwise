import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Session Mode 即時同步服務
///
/// 使用 Supabase Realtime 監聽 workout_plans 表的變更，
/// 當教練修改訓練計畫時，學員端可以即時看到更新。
class SessionRealtimeService {
  final SupabaseClient _supabase;

  /// 儲存所有訂閱的 channel，用於清理
  final Map<String, RealtimeChannel> _channels = {};

  SessionRealtimeService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// 訂閱特定 workout_plan 的變更
  ///
  /// [workoutPlanId] 要監聽的訓練計畫 ID
  /// [onUpdate] 當資料更新時的回調
  /// [onDelete] 當資料刪除時的回調（可選）
  ///
  /// 返回一個唯一的訂閱 ID，用於取消訂閱
  String subscribeToWorkoutPlan({
    required String workoutPlanId,
    required VoidCallback onUpdate,
    VoidCallback? onDelete,
  }) {
    final channelId = 'workout_plan_$workoutPlanId';

    // 如果已經訂閱過，先取消
    if (_channels.containsKey(channelId)) {
      unsubscribe(channelId);
    }

    debugPrint('[SESSION_REALTIME] 訂閱 workout_plan: $workoutPlanId');

    final channel = _supabase
        .channel(channelId)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'workout_plans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: workoutPlanId,
          ),
          callback: (payload) {
            debugPrint('[SESSION_REALTIME] 收到更新: ${payload.newRecord}');
            onUpdate();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'workout_plans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: workoutPlanId,
          ),
          callback: (payload) {
            debugPrint('[SESSION_REALTIME] 收到刪除事件');
            onDelete?.call();
          },
        )
        .subscribe((status, error) {
          debugPrint('[SESSION_REALTIME] 訂閱狀態: $status, 錯誤: $error');
        });

    _channels[channelId] = channel;
    return channelId;
  }

  /// 訂閱特定 session_note 的變更
  ///
  /// [sessionNoteId] 要監聯的課程筆記 ID
  /// [onUpdate] 當資料更新時的回調
  ///
  /// 返回一個唯一的訂閱 ID，用於取消訂閱
  String subscribeToSessionNote({
    required String sessionNoteId,
    required VoidCallback onUpdate,
  }) {
    final channelId = 'session_note_$sessionNoteId';

    // 如果已經訂閱過，先取消
    if (_channels.containsKey(channelId)) {
      unsubscribe(channelId);
    }

    debugPrint('[SESSION_REALTIME] 訂閱 session_note: $sessionNoteId');

    final channel = _supabase
        .channel(channelId)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'session_notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sessionNoteId,
          ),
          callback: (payload) {
            debugPrint('[SESSION_REALTIME] session_note 更新: ${payload.newRecord}');
            onUpdate();
          },
        )
        .subscribe((status, error) {
          debugPrint('[SESSION_REALTIME] session_note 訂閱狀態: $status, 錯誤: $error');
        });

    _channels[channelId] = channel;
    return channelId;
  }

  /// 取消特定訂閱
  void unsubscribe(String channelId) {
    final channel = _channels.remove(channelId);
    if (channel != null) {
      debugPrint('[SESSION_REALTIME] 取消訂閱: $channelId');
      _supabase.removeChannel(channel);
    }
  }

  /// 取消所有訂閱
  void unsubscribeAll() {
    debugPrint('[SESSION_REALTIME] 取消所有訂閱 (${_channels.length} 個)');
    for (final channel in _channels.values) {
      _supabase.removeChannel(channel);
    }
    _channels.clear();
  }

  /// 清理資源
  void dispose() {
    unsubscribeAll();
  }
}

