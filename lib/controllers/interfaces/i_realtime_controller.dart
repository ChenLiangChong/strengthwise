import 'package:flutter/foundation.dart';

/// Realtime 訂閱控制器接口
///
/// 提供 Realtime 訂閱的輔助方法
abstract class IRealtimeController {
  // ==================== 狀態 Getters ====================

  /// 當前訂閱數量
  int get subscriptionCount;

  // ==================== 教練時段訂閱（學員端使用） ====================

  /// 訂閱教練的可預約時段變更
  ///
  /// 返回訂閱 ID，用於取消訂閱
  String subscribeToCoachSlots({
    required String coachId,
    required VoidCallback onUpdate,
  });

  // ==================== 學員偏好訂閱（教練端使用） ====================

  /// 訂閱學員的可訓練時間變更
  ///
  /// 返回訂閱 ID，用於取消訂閱
  String subscribeToClientAvailability({
    required String clientId,
    required VoidCallback onUpdate,
  });

  // ==================== 訓練計畫訂閱（學員端使用） ====================

  /// 訂閱用戶相關的訓練計畫變更（作為學員）
  ///
  /// 返回訂閱 ID，用於取消訂閱
  String subscribeToUserWorkoutPlans({
    required String userId,
    required VoidCallback onUpdate,
  });

  // ==================== 預約訂閱（雙方都可使用） ====================

  /// 訂閱用戶相關的預約變更
  ///
  /// 返回訂閱 ID，用於取消訂閱
  String subscribeToUserAppointments({
    required String userId,
    required VoidCallback onUpdate,
  });

  // ==================== 取消訂閱 ====================

  /// 取消特定訂閱
  void unsubscribe(String subscriptionId);

  /// 取消所有訂閱
  void unsubscribeAll();
}
