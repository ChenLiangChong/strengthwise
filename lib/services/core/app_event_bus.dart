import 'dart:async';
import 'package:flutter/foundation.dart';

/// 應用事件類型
///
/// 定義所有可能觸發 UI 刷新的事件類型
enum AppEventType {
  // ==================== 訓練計畫 ====================
  /// 創建訓練計畫（從模板、手動創建）
  workoutCreated,

  /// 更新訓練計畫（編輯內容）
  workoutUpdated,

  /// 刪除訓練計畫
  workoutDeleted,

  /// 完成訓練（影響統計、PR）
  workoutCompleted,

  // ==================== 預約 ====================
  /// 創建預約（學員發起）
  appointmentCreated,

  /// 確認預約（教練確認）
  appointmentConfirmed,

  /// 取消預約（任一方取消）
  appointmentCancelled,

  /// 完成預約（課程結束）
  appointmentCompleted,

  /// 重新安排預約時間
  appointmentRescheduled,

  // ==================== 模板 ====================
  /// 創建模板
  templateCreated,

  /// 更新模板
  templateUpdated,

  /// 刪除模板
  templateDeleted,

  // ==================== 身體數據 ====================
  /// 身體數據更新（體重、體脂等）
  bodyDataUpdated,

  // ==================== 教練時段（未來擴展）====================
  /// 教練新增可預約時段
  availabilitySlotCreated,

  /// 教練刪除可預約時段
  availabilitySlotDeleted,

  // ==================== 關係（未來擴展）====================
  /// 建立教練學員關係
  relationshipCreated,

  /// 解除教練學員關係
  relationshipDeleted,

  // ==================== 課程筆記（未來擴展）====================
  /// 課程筆記更新
  sessionNoteUpdated,

  // ==================== 健康評估（未來擴展）====================
  /// 健康評估更新
  healthAssessmentUpdated,

  // ==================== 收藏（v3.5）====================
  /// 收藏動作新增
  favoriteAdded,

  /// 收藏動作移除
  favoriteRemoved,
}

/// 應用事件
///
/// 攜帶事件類型和相關數據，用於通知訂閱者進行 UI 刷新
class AppEvent {
  /// 事件類型
  final AppEventType type;

  /// 實體 ID（訓練計畫 ID、預約 ID 等）
  final String? entityId;

  /// 受影響的用戶 ID（用於判斷是否需要刷新）
  final String? userId;

  /// 事件發生時間
  final DateTime timestamp;

  /// 額外元數據（可選）
  final Map<String, dynamic>? metadata;

  /// 事件來源（本地操作 or 遠端推送）
  final AppEventSource source;

  const AppEvent({
    required this.type,
    this.entityId,
    this.userId,
    required this.timestamp,
    this.metadata,
    this.source = AppEventSource.local,
  });

  @override
  String toString() {
    return 'AppEvent(type: $type, entityId: $entityId, userId: $userId, source: $source)';
  }
}

/// 事件來源
enum AppEventSource {
  /// 本地用戶操作
  local,

  /// 遠端推送（Realtime）
  remote,
}

/// 應用事件匯流排（Singleton）
///
/// 統一管理應用內所有數據變更事件，實現跨頁面自動刷新
///
/// 使用方式：
/// ```dart
/// // 發布事件
/// AppEventBus().publish(AppEvent(
///   type: AppEventType.workoutCreated,
///   entityId: workoutId,
///   userId: userId,
///   timestamp: DateTime.now(),
/// ));
///
/// // 訂閱事件
/// final subscription = AppEventBus().on<AppEvent>().listen((event) {
///   if (event.type == AppEventType.workoutCreated) {
///     _refreshData();
///   }
/// });
///
/// // 取消訂閱
/// subscription.cancel();
/// ```
class AppEventBus {
  // 單例模式
  static final AppEventBus _instance = AppEventBus._internal();
  factory AppEventBus() => _instance;
  AppEventBus._internal();

  /// 事件流控制器（broadcast 允許多個監聽者）
  final StreamController<AppEvent> _eventController =
      StreamController<AppEvent>.broadcast();

  /// 獲取事件流
  Stream<AppEvent> get stream => _eventController.stream;

  /// 發布事件
  ///
  /// [event] 要發布的事件
  void publish(AppEvent event) {
    if (kDebugMode) {
      debugPrint('[APP_EVENT_BUS] 📤 發布事件: $event');
    }
    _eventController.add(event);
  }

  /// 訂閱特定類型的事件
  ///
  /// [types] 要訂閱的事件類型列表
  /// 返回過濾後的事件流
  Stream<AppEvent> where(List<AppEventType> types) {
    return stream.where((event) => types.contains(event.type));
  }

  /// 訂閱影響特定用戶的事件
  ///
  /// [userId] 用戶 ID
  /// [types] 可選，限定事件類型
  Stream<AppEvent> forUser(String userId, {List<AppEventType>? types}) {
    return stream.where((event) {
      final matchesUser = event.userId == null || event.userId == userId;
      final matchesType = types == null || types.contains(event.type);
      return matchesUser && matchesType;
    });
  }

  /// 便捷方法：發布訓練計畫創建事件
  void publishWorkoutCreated({
    required String workoutId,
    required String userId,
    Map<String, dynamic>? metadata,
  }) {
    publish(AppEvent(
      type: AppEventType.workoutCreated,
      entityId: workoutId,
      userId: userId,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
  }

  /// 便捷方法：發布訓練計畫更新事件
  void publishWorkoutUpdated({
    required String workoutId,
    required String userId,
  }) {
    publish(AppEvent(
      type: AppEventType.workoutUpdated,
      entityId: workoutId,
      userId: userId,
      timestamp: DateTime.now(),
    ));
  }

  /// 便捷方法：發布訓練計畫刪除事件
  void publishWorkoutDeleted({
    required String workoutId,
    required String userId,
  }) {
    publish(AppEvent(
      type: AppEventType.workoutDeleted,
      entityId: workoutId,
      userId: userId,
      timestamp: DateTime.now(),
    ));
  }

  /// 便捷方法：發布訓練完成事件
  void publishWorkoutCompleted({
    required String workoutId,
    required String userId,
  }) {
    publish(AppEvent(
      type: AppEventType.workoutCompleted,
      entityId: workoutId,
      userId: userId,
      timestamp: DateTime.now(),
    ));
  }

  /// 便捷方法：發布預約創建事件
  void publishAppointmentCreated({
    required String appointmentId,
    required String coachId,
    required String clientId,
  }) {
    publish(AppEvent(
      type: AppEventType.appointmentCreated,
      entityId: appointmentId,
      timestamp: DateTime.now(),
      metadata: {
        'coachId': coachId,
        'clientId': clientId,
      },
    ));
  }

  /// 便捷方法：發布預約取消事件
  void publishAppointmentCancelled({
    required String appointmentId,
    required String coachId,
    required String clientId,
  }) {
    publish(AppEvent(
      type: AppEventType.appointmentCancelled,
      entityId: appointmentId,
      timestamp: DateTime.now(),
      metadata: {
        'coachId': coachId,
        'clientId': clientId,
      },
    ));
  }

  /// 便捷方法：發布預約確認事件
  void publishAppointmentConfirmed({
    required String appointmentId,
    required String coachId,
    required String clientId,
  }) {
    publish(AppEvent(
      type: AppEventType.appointmentConfirmed,
      entityId: appointmentId,
      timestamp: DateTime.now(),
      metadata: {
        'coachId': coachId,
        'clientId': clientId,
      },
    ));
  }

  /// 便捷方法：發布預約完成事件
  void publishAppointmentCompleted({
    required String appointmentId,
    required String coachId,
    required String clientId,
  }) {
    publish(AppEvent(
      type: AppEventType.appointmentCompleted,
      entityId: appointmentId,
      timestamp: DateTime.now(),
      metadata: {
        'coachId': coachId,
        'clientId': clientId,
      },
    ));
  }

  /// 便捷方法：發布身體數據更新事件
  void publishBodyDataUpdated({required String userId}) {
    publish(AppEvent(
      type: AppEventType.bodyDataUpdated,
      userId: userId,
      timestamp: DateTime.now(),
    ));
  }

  /// 便捷方法：發布模板創建事件
  void publishTemplateCreated({
    required String templateId,
    required String userId,
  }) {
    publish(AppEvent(
      type: AppEventType.templateCreated,
      entityId: templateId,
      userId: userId,
      timestamp: DateTime.now(),
    ));
  }

  /// 便捷方法：發布模板更新事件
  void publishTemplateUpdated({
    required String templateId,
    required String userId,
  }) {
    publish(AppEvent(
      type: AppEventType.templateUpdated,
      entityId: templateId,
      userId: userId,
      timestamp: DateTime.now(),
    ));
  }

  /// 便捷方法：發布模板刪除事件
  void publishTemplateDeleted({
    required String templateId,
    required String userId,
  }) {
    publish(AppEvent(
      type: AppEventType.templateDeleted,
      entityId: templateId,
      userId: userId,
      timestamp: DateTime.now(),
    ));
  }

  /// 清理資源（通常在應用退出時調用）
  void dispose() {
    _eventController.close();
  }
}
