import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/services/core/app_event_bus.dart';

/// Realtime 訂閱管理器 ⭐ v3.9
///
/// 統一管理所有 Supabase Realtime 訂閱
/// 支援自動訂閱/取消訂閱，避免記憶體洩漏
/// 
/// ⭐ 防抖機制：避免短時間內多次觸發刷新
class RealtimeSubscriptionManager {
  final SupabaseClient _supabase;

  /// 儲存所有訂閱的 channel
  final Map<String, RealtimeChannel> _channels = {};

  /// 事件匯流排（用於發布事件）
  final AppEventBus _eventBus = AppEventBus();

  /// ⭐ 防抖計時器（每個頻道一個）
  final Map<String, Timer?> _debounceTimers = {};

  /// 防抖延遲時間（毫秒）
  static const int _debounceMs = 500;

  RealtimeSubscriptionManager({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// ⭐ 防抖執行回調
  void _debounce(String channelId, VoidCallback callback) {
    // 取消之前的計時器
    _debounceTimers[channelId]?.cancel();
    
    // 設置新的計時器
    _debounceTimers[channelId] = Timer(
      Duration(milliseconds: _debounceMs),
      callback,
    );
  }

  // ============================================================================
  // 教練時段訂閱（學員端使用）
  // ============================================================================

  /// 訂閱教練的可預約時段變更
  ///
  /// [coachId] 要監聽的教練 ID
  /// [onUpdate] 當資料變更時的回調
  ///
  /// 返回訂閱 ID，用於取消訂閱
  String subscribeToCoachSlots({
    required String coachId,
    required VoidCallback onUpdate,
  }) {
    final channelId = 'coach_slots_$coachId';

    // 如果已經訂閱過，先取消
    if (_channels.containsKey(channelId)) {
      unsubscribe(channelId);
    }

    if (kDebugMode) {
      debugPrint('[RealtimeManager] 訂閱教練時段: $coachId');
    }

    final channel = _supabase
        .channel(channelId)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'availability_slots',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'coach_id',
            value: coachId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('[RealtimeManager] 教練新增時段: ${payload.newRecord}');
            }
            // ⭐ 防抖處理
            _debounce(channelId, () {
              _eventBus.publishAvailabilitySlotCreated(
                slotId: payload.newRecord['id'] as String? ?? '',
                coachId: coachId,
              );
              onUpdate();
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'availability_slots',
          // ⭐ v3.9: DELETE 不使用 filter（Supabase 限制：oldRecord 可能為空）
          // 只發布 EventBus 事件，讓 View 層通過訂閱 EventBus 自己刷新
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('[RealtimeManager] 教練時段刪除事件');
            }
            // ⭐ 防抖處理
            _debounce(channelId, () {
              // 只發布 EventBus，不調用 onUpdate
              // View 層訂閱 availabilityEvents 來刷新
              _eventBus.publishAvailabilitySlotDeleted(
                slotId: payload.oldRecord['id'] as String? ?? '',
                coachId: coachId, // 這裡用訂閱時的 coachId
              );
            });
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            debugPrint('[RealtimeManager] coach_slots 訂閱狀態: $status');
          }
        });

    _channels[channelId] = channel;
    return channelId;
  }

  // ============================================================================
  // 學員偏好訂閱（教練端使用）
  // ============================================================================

  /// 訂閱學員的可訓練時間變更
  ///
  /// [clientId] 要監聽的學員 ID
  /// [onUpdate] 當資料變更時的回調
  ///
  /// 返回訂閱 ID，用於取消訂閱
  String subscribeToClientAvailability({
    required String clientId,
    required VoidCallback onUpdate,
  }) {
    final channelId = 'client_availability_$clientId';

    // 如果已經訂閱過，先取消
    if (_channels.containsKey(channelId)) {
      unsubscribe(channelId);
    }

    if (kDebugMode) {
      debugPrint('[RealtimeManager] 訂閱學員偏好: $clientId');
    }

    final channel = _supabase
        .channel(channelId)
        // ⭐ v3.9: INSERT 和 UPDATE 使用 filter（能正確識別 client_id）
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'client_availability',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: clientId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('[RealtimeManager] 學員新增偏好: ${payload.newRecord}');
            }
            _debounce(channelId, () {
              _eventBus.publishClientAvailabilityCreated(
                availabilityId: payload.newRecord['id'] as String? ?? '',
                clientId: clientId,
              );
              onUpdate();
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'client_availability',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: clientId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('[RealtimeManager] 學員更新偏好: ${payload.newRecord}');
            }
            _debounce(channelId, () {
              _eventBus.publishClientAvailabilityUpdated(
                availabilityId: payload.newRecord['id'] as String? ?? '',
                clientId: clientId,
              );
              onUpdate();
            });
          },
        )
        // ⭐ v3.9: DELETE 不使用 filter（Supabase 限制），通過 EventBus 通知
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'client_availability',
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('[RealtimeManager] 學員刪除偏好事件');
            }
            _debounce(channelId, () {
              // 只發布 EventBus，讓 View 層通過訂閱刷新
              _eventBus.publishClientAvailabilityDeleted(
                availabilityId: payload.oldRecord['id'] as String? ?? '',
                clientId: clientId,
              );
            });
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            debugPrint('[RealtimeManager] client_availability 訂閱狀態: $status');
          }
        });

    _channels[channelId] = channel;
    return channelId;
  }

  // ============================================================================
  // 預約訂閱（雙方都可使用）⭐ v3.9
  // ============================================================================

  /// 訂閱用戶相關的預約變更（作為學員或教練）
  ///
  /// [userId] 當前用戶 ID
  /// [onUpdate] 當預約資料變更時的回調
  ///
  /// 返回訂閱 ID，用於取消訂閱
  String subscribeToUserAppointments({
    required String userId,
    required VoidCallback onUpdate,
  }) {
    final channelId = 'appointments_$userId';

    // 如果已經訂閱過，先取消
    if (_channels.containsKey(channelId)) {
      unsubscribe(channelId);
    }

    if (kDebugMode) {
      debugPrint('[RealtimeManager] 訂閱預約變更: $userId');
    }

    final channel = _supabase
        .channel(channelId)
        // 監聽作為學員的預約（教練確認/取消時會收到）
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'client_id',
            value: userId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('[RealtimeManager] 預約更新（作為學員）: ${payload.newRecord['status']}');
            }
            _debounce(channelId, () {
              final status = payload.newRecord['status'] as String?;
              final appointmentId = payload.newRecord['id'] as String? ?? '';
              final coachId = payload.newRecord['coach_id'] as String? ?? '';
              
              // 根據狀態發布不同事件
              if (status == 'confirmed') {
                _eventBus.publishAppointmentConfirmed(
                  appointmentId: appointmentId,
                  coachId: coachId,
                  clientId: userId,
                );
              } else if (status == 'cancelled' || status == 'rejected') {
                // cancelled 和 rejected 都觸發刷新
                _eventBus.publishAppointmentCancelled(
                  appointmentId: appointmentId,
                  coachId: coachId,
                  clientId: userId,
                );
              }
              onUpdate();
            });
          },
        )
        // 監聽作為教練的預約（學員預約/取消時會收到）
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'coach_id',
            value: userId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('[RealtimeManager] 新預約（作為教練）');
            }
            _debounce(channelId, () {
              _eventBus.publishAppointmentCreated(
                appointmentId: payload.newRecord['id'] as String? ?? '',
                coachId: userId,
                clientId: payload.newRecord['client_id'] as String? ?? '',
              );
              onUpdate();
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'coach_id',
            value: userId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('[RealtimeManager] 預約更新（作為教練）: ${payload.newRecord['status']}');
            }
            _debounce(channelId, () {
              final status = payload.newRecord['status'] as String?;
              final appointmentId = payload.newRecord['id'] as String? ?? '';
              final clientId = payload.newRecord['client_id'] as String? ?? '';
              
              if (status == 'cancelled') {
                _eventBus.publishAppointmentCancelled(
                  appointmentId: appointmentId,
                  coachId: userId,
                  clientId: clientId,
                );
              }
              onUpdate();
            });
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            debugPrint('[RealtimeManager] appointments 訂閱狀態: $status');
          }
        });

    _channels[channelId] = channel;
    return channelId;
  }

  // ============================================================================
  // 訓練計畫訂閱（學員端使用）⭐ v3.9
  // ============================================================================

  /// 訂閱用戶相關的訓練計畫變更（作為學員）
  ///
  /// [userId] 當前用戶 ID
  /// [onUpdate] 當訓練計畫變更時的回調
  ///
  /// 返回訂閱 ID，用於取消訂閱
  String subscribeToUserWorkoutPlans({
    required String userId,
    required VoidCallback onUpdate,
  }) {
    final channelId = 'workout_plans_$userId';

    // 如果已經訂閱過，先取消
    if (_channels.containsKey(channelId)) {
      unsubscribe(channelId);
    }

    if (kDebugMode) {
      debugPrint('[RealtimeManager] 訂閱訓練計畫變更: $userId');
    }

    final channel = _supabase
        .channel(channelId)
        // 監聯作為學員的訓練計畫（教練創建時會收到）
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'workout_plans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trainee_id',
            value: userId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('[RealtimeManager] 新訓練計畫（作為學員）');
            }
            _debounce(channelId, () {
              _eventBus.publishWorkoutCreated(
                workoutId: payload.newRecord['id'] as String? ?? '',
                userId: userId,
              );
              onUpdate();
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'workout_plans',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'trainee_id',
            value: userId,
          ),
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('[RealtimeManager] 訓練計畫更新（作為學員）');
            }
            _debounce(channelId, () {
              _eventBus.publishWorkoutUpdated(
                workoutId: payload.newRecord['id'] as String? ?? '',
                userId: userId,
              );
              onUpdate();
            });
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'workout_plans',
          callback: (payload) {
            if (kDebugMode) {
              debugPrint('[RealtimeManager] 訓練計畫刪除');
            }
            _debounce(channelId, () {
              _eventBus.publishWorkoutDeleted(
                workoutId: payload.oldRecord['id'] as String? ?? '',
                userId: userId,
              );
              onUpdate();
            });
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            debugPrint('[RealtimeManager] workout_plans 訂閱狀態: $status');
          }
        });

    _channels[channelId] = channel;
    return channelId;
  }

  // ============================================================================
  // 批量訂閱（根據角色）
  // ============================================================================

  /// 根據用戶角色自動訂閱相關頻道
  ///
  /// [userId] 當前用戶 ID
  /// [isCoach] 是否為教練
  /// [relatedIds] 相關 ID 列表（教練的學員 ID 或學員的教練 ID）
  /// [onUpdate] 當任何資料變更時的回調
  void autoSubscribe({
    required String userId,
    required bool isCoach,
    required List<String> relatedIds,
    required VoidCallback onUpdate,
  }) {
    if (kDebugMode) {
      debugPrint(
          '[RealtimeManager] 自動訂閱: isCoach=$isCoach, relatedIds=$relatedIds');
    }

    if (isCoach) {
      // 教練訂閱所有學員的可訓練時間
      for (final clientId in relatedIds) {
        subscribeToClientAvailability(
          clientId: clientId,
          onUpdate: onUpdate,
        );
      }
    } else {
      // 學員訂閱所有教練的可預約時段
      for (final coachId in relatedIds) {
        subscribeToCoachSlots(
          coachId: coachId,
          onUpdate: onUpdate,
        );
      }
    }
  }

  // ============================================================================
  // 訂閱管理
  // ============================================================================

  /// 取消特定訂閱
  void unsubscribe(String channelId) {
    // ⭐ 清理防抖計時器
    _debounceTimers[channelId]?.cancel();
    _debounceTimers.remove(channelId);
    
    final channel = _channels.remove(channelId);
    if (channel != null) {
      _supabase.removeChannel(channel);
      if (kDebugMode) {
        debugPrint('[RealtimeManager] 已取消訂閱: $channelId');
      }
    }
  }

  /// 取消所有訂閱
  void disposeAll() {
    if (kDebugMode) {
      debugPrint('[RealtimeManager] 清理所有訂閱: ${_channels.length} 個');
    }

    // ⭐ 清理所有防抖計時器
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();

    for (final channel in _channels.values) {
      _supabase.removeChannel(channel);
    }
    _channels.clear();
  }

  /// 獲取當前訂閱數量
  int get subscriptionCount => _channels.length;

  /// 檢查是否有特定訂閱
  bool hasSubscription(String channelId) => _channels.containsKey(channelId);
}
