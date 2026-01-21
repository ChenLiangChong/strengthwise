import 'package:flutter/foundation.dart';
import 'package:strengthwise/services/realtime/realtime_subscription_manager.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'interfaces/i_realtime_controller.dart';

/// Realtime 訂閱控制器 ⭐ v3.9
///
/// 提供 Realtime 訂閱的輔助方法
///
/// 設計原則：
/// - **頁面級訂閱**：各頁面自己管理訂閱生命週期
/// - **只訂閱「看別人資料」**：自己的操作透過 EventBus 處理
///
/// 使用範例：
/// ```dart
/// // 在 initState 中訂閱
/// _subscriptionId = _realtimeController.subscribeToCoachSlots(
///   coachId: widget.coachId,
///   onUpdate: _refreshData,
/// );
///
/// // 在 dispose 中取消
/// _realtimeController.unsubscribe(_subscriptionId);
/// ```
class RealtimeController extends ChangeNotifier implements IRealtimeController {
  final RealtimeSubscriptionManager _realtimeManager;

  RealtimeController({
    RealtimeSubscriptionManager? realtimeManager,
  }) : _realtimeManager =
            realtimeManager ?? serviceLocator<RealtimeSubscriptionManager>();

  /// 當前訂閱數量
  @override
  int get subscriptionCount => _realtimeManager.subscriptionCount;

  // ============================================================================
  // 教練時段訂閱（學員端使用）
  // ============================================================================

  /// 訂閱教練的可預約時段變更
  ///
  /// 返回訂閱 ID，用於取消訂閱
  @override
  String subscribeToCoachSlots({
    required String coachId,
    required VoidCallback onUpdate,
  }) {
    if (kDebugMode) {
      debugPrint('[RealtimeController] 訂閱教練時段: $coachId');
    }
    return _realtimeManager.subscribeToCoachSlots(
      coachId: coachId,
      onUpdate: onUpdate,
    );
  }

  // ============================================================================
  // 學員偏好訂閱（教練端使用）
  // ============================================================================

  /// 訂閱學員的可訓練時間變更
  ///
  /// 返回訂閱 ID，用於取消訂閱
  @override
  String subscribeToClientAvailability({
    required String clientId,
    required VoidCallback onUpdate,
  }) {
    if (kDebugMode) {
      debugPrint('[RealtimeController] 訂閱學員偏好: $clientId');
    }
    return _realtimeManager.subscribeToClientAvailability(
      clientId: clientId,
      onUpdate: onUpdate,
    );
  }

  // ============================================================================
  // 訓練計畫訂閱（學員端使用）⭐ v3.9
  // ============================================================================

  /// 訂閱用戶相關的訓練計畫變更（作為學員）
  ///
  /// 教練為學員創建訓練計畫時，學員會收到通知
  ///
  /// 返回訂閱 ID，用於取消訂閱
  @override
  String subscribeToUserWorkoutPlans({
    required String userId,
    required VoidCallback onUpdate,
  }) {
    if (kDebugMode) {
      debugPrint('[RealtimeController] 訂閱訓練計畫: $userId');
    }
    return _realtimeManager.subscribeToUserWorkoutPlans(
      userId: userId,
      onUpdate: onUpdate,
    );
  }

  // ============================================================================
  // 預約訂閱（雙方都可使用）⭐ v3.9
  // ============================================================================

  /// 訂閱用戶相關的預約變更
  /// 
  /// 學員：收到教練確認/拒絕/取消的通知
  /// 教練：收到學員新預約/取消的通知
  ///
  /// 返回訂閱 ID，用於取消訂閱
  @override
  String subscribeToUserAppointments({
    required String userId,
    required VoidCallback onUpdate,
  }) {
    if (kDebugMode) {
      debugPrint('[RealtimeController] 訂閱預約變更: $userId');
    }
    return _realtimeManager.subscribeToUserAppointments(
      userId: userId,
      onUpdate: onUpdate,
    );
  }

  // ============================================================================
  // 取消訂閱
  // ============================================================================

  /// 取消特定訂閱
  @override
  void unsubscribe(String subscriptionId) {
    if (kDebugMode) {
      debugPrint('[RealtimeController] 取消訂閱: $subscriptionId');
    }
    _realtimeManager.unsubscribe(subscriptionId);
  }

  /// 取消所有訂閱（通常不需要）
  @override
  void unsubscribeAll() {
    if (kDebugMode) {
      debugPrint('[RealtimeController] 取消所有訂閱');
    }
    _realtimeManager.disposeAll();
  }

  @override
  void dispose() {
    // 注意：不自動清理，因為訂閱由各頁面管理
    super.dispose();
  }
}
