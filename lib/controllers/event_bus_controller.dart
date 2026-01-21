import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/core/app_event_bus.dart';
import 'interfaces/i_event_bus_controller.dart';

/// 事件匯流排控制器
///
/// 作為 AppEventBus（Service 層）和 View 層之間的中間層，
/// 符合 MVVM 架構的分層原則。
///
/// 使用方式：
/// ```dart
/// // 在頁面中監聽（通過 Provider）
/// final eventBusController = context.read<EventBusController>();
/// eventBusController.addListener(() {
///   if (eventBusController.lastEvent?.type == AppEventType.workoutCreated) {
///     _refreshData();
///   }
/// });
///
/// // 或者使用 Stream 訂閱特定事件
/// eventBusController.workoutEvents.listen((event) {
///   _refreshCalendar();
/// });
/// ```
class EventBusController extends ChangeNotifier implements IEventBusController {
  final AppEventBus _eventBus;

  /// 最後收到的事件（用於 UI 判斷）
  AppEvent? _lastEvent;
  @override
  AppEvent? get lastEvent => _lastEvent;

  /// 內部訂閱
  StreamSubscription<AppEvent>? _subscription;

  EventBusController({AppEventBus? eventBus})
      : _eventBus = eventBus ?? AppEventBus() {
    _subscribeToEvents();
  }

  /// 訂閱所有事件
  void _subscribeToEvents() {
    _subscription = _eventBus.stream.listen((event) {
      _lastEvent = event;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('[EVENT_BUS_CONTROLLER] 📥 收到事件: ${event.type}');
      }
    });
  }

  // ==================== 過濾後的事件流 ====================
  // 供頁面直接訂閱特定類型的事件

  /// 訓練計畫相關事件流
  @override
  Stream<AppEvent> get workoutEvents => _eventBus.where([
        AppEventType.workoutCreated,
        AppEventType.workoutUpdated,
        AppEventType.workoutDeleted,
        AppEventType.workoutCompleted,
      ]);

  /// 預約相關事件流
  @override
  Stream<AppEvent> get appointmentEvents => _eventBus.where([
        AppEventType.appointmentCreated,
        AppEventType.appointmentConfirmed,
        AppEventType.appointmentCancelled,
        AppEventType.appointmentRescheduled,
      ]);

  /// 模板相關事件流
  @override
  Stream<AppEvent> get templateEvents => _eventBus.where([
        AppEventType.templateCreated,
        AppEventType.templateUpdated,
        AppEventType.templateDeleted,
      ]);

  /// 身體數據相關事件流
  @override
  Stream<AppEvent> get bodyDataEvents => _eventBus.where([
        AppEventType.bodyDataUpdated,
      ]);

  /// 行事曆相關事件流（訓練 + 預約）
  @override
  Stream<AppEvent> get calendarEvents => _eventBus.where([
        AppEventType.workoutCreated,
        AppEventType.workoutUpdated,
        AppEventType.workoutDeleted,
        AppEventType.appointmentCreated,
        AppEventType.appointmentConfirmed,
        AppEventType.appointmentCancelled,
        AppEventType.appointmentCompleted, // ⭐ v3.5
        AppEventType.appointmentRescheduled,
      ]);

  /// ⭐ v3.9: 時段相關事件流（教練時段 + 學員偏好）
  @override
  Stream<AppEvent> get availabilityEvents => _eventBus.where([
        AppEventType.availabilitySlotCreated,
        AppEventType.availabilitySlotDeleted,
        AppEventType.clientAvailabilityCreated,
        AppEventType.clientAvailabilityUpdated,
        AppEventType.clientAvailabilityDeleted,
      ]);

  /// 首頁相關事件流（今日行程變更）
  @override
  Stream<AppEvent> get homePageEvents => _eventBus.where([
        AppEventType.workoutCreated,
        AppEventType.workoutDeleted,
        AppEventType.workoutCompleted,
        AppEventType.appointmentCreated,
        AppEventType.appointmentConfirmed,
        AppEventType.appointmentCancelled,
        AppEventType.appointmentCompleted, // ⭐ v3.5
      ]);

  /// 統計相關事件流
  ///
  /// 包含所有影響統計數據的事件：
  /// - workoutCreated: 影響日曆（顯示有計畫的日期）
  /// - workoutUpdated: 影響 PR、訓練量、肌群分布（set 完成、重量變更）
  /// - workoutDeleted: 影響所有統計
  /// - workoutCompleted: 影響完成率、連續天數
  /// - bodyDataUpdated: 影響身體數據 Tab
  @override
  Stream<AppEvent> get statisticsEvents => _eventBus.where([
        AppEventType.workoutCreated,
        AppEventType.workoutUpdated,
        AppEventType.workoutDeleted,
        AppEventType.workoutCompleted,
        AppEventType.bodyDataUpdated,
      ]);

  // ==================== 發布事件的便捷方法 ====================
  // 讓其他 Controller 可以透過這個 Controller 發布事件

  /// 發布訓練計畫創建事件
  @override
  void publishWorkoutCreated({
    required String workoutId,
    required String userId,
    Map<String, dynamic>? metadata,
  }) {
    _eventBus.publishWorkoutCreated(
      workoutId: workoutId,
      userId: userId,
      metadata: metadata,
    );
  }

  /// 發布訓練計畫更新事件
  @override
  void publishWorkoutUpdated({
    required String workoutId,
    required String userId,
  }) {
    _eventBus.publishWorkoutUpdated(
      workoutId: workoutId,
      userId: userId,
    );
  }

  /// 發布訓練計畫刪除事件
  @override
  void publishWorkoutDeleted({
    required String workoutId,
    required String userId,
  }) {
    _eventBus.publishWorkoutDeleted(
      workoutId: workoutId,
      userId: userId,
    );
  }

  /// 發布訓練完成事件
  @override
  void publishWorkoutCompleted({
    required String workoutId,
    required String userId,
  }) {
    _eventBus.publishWorkoutCompleted(
      workoutId: workoutId,
      userId: userId,
    );
  }

  /// 發布預約創建事件
  @override
  void publishAppointmentCreated({
    required String appointmentId,
    String? coachId,
    String? clientId,
    String? userId, // ⭐ v3.7: 簡化版本，自動推導 coachId/clientId
  }) {
    _eventBus.publishAppointmentCreated(
      appointmentId: appointmentId,
      coachId: coachId ?? userId ?? '',
      clientId: clientId ?? userId ?? '',
    );
  }

  /// 發布預約取消事件
  @override
  void publishAppointmentCancelled({
    required String appointmentId,
    String? coachId,
    String? clientId,
    String? userId, // ⭐ v3.7: 簡化版本
  }) {
    _eventBus.publishAppointmentCancelled(
      appointmentId: appointmentId,
      coachId: coachId ?? userId ?? '',
      clientId: clientId ?? userId ?? '',
    );
  }

  /// 發布預約確認事件
  @override
  void publishAppointmentConfirmed({
    required String appointmentId,
    String? coachId,
    String? clientId,
    String? userId, // ⭐ v3.7: 簡化版本
  }) {
    _eventBus.publishAppointmentConfirmed(
      appointmentId: appointmentId,
      coachId: coachId ?? userId ?? '',
      clientId: clientId ?? userId ?? '',
    );
  }

  /// 發布預約完成事件
  @override
  void publishAppointmentCompleted({
    required String appointmentId,
    required String coachId,
    required String clientId,
  }) {
    _eventBus.publishAppointmentCompleted(
      appointmentId: appointmentId,
      coachId: coachId,
      clientId: clientId,
    );
  }

  /// 發布身體數據更新事件
  @override
  void publishBodyDataUpdated({required String userId}) {
    _eventBus.publishBodyDataUpdated(userId: userId);
  }

  /// 發布模板創建事件
  @override
  void publishTemplateCreated({
    required String templateId,
    required String userId,
  }) {
    _eventBus.publishTemplateCreated(
      templateId: templateId,
      userId: userId,
    );
  }

  /// 發布模板更新事件
  @override
  void publishTemplateUpdated({
    required String templateId,
    required String userId,
  }) {
    _eventBus.publishTemplateUpdated(
      templateId: templateId,
      userId: userId,
    );
  }

  /// 發布模板刪除事件
  @override
  void publishTemplateDeleted({
    required String templateId,
    required String userId,
  }) {
    _eventBus.publishTemplateDeleted(
      templateId: templateId,
      userId: userId,
    );
  }

  /// 發布預約重新安排事件 ⭐ v3.9
  @override
  void publishAppointmentRescheduled({
    required String appointmentId,
    required String coachId,
    required String clientId,
  }) {
    _eventBus.publishAppointmentRescheduled(
      appointmentId: appointmentId,
      coachId: coachId,
      clientId: clientId,
    );
  }

  /// 發布關係建立事件 ⭐ v3.9
  @override
  void publishRelationshipCreated({
    required String relationshipId,
    required String coachId,
    required String clientId,
  }) {
    _eventBus.publishRelationshipCreated(
      relationshipId: relationshipId,
      coachId: coachId,
      clientId: clientId,
    );
  }

  /// 發布教練時段建立事件 ⭐ v3.9
  @override
  void publishAvailabilitySlotCreated({
    required String slotId,
    required String coachId,
  }) {
    _eventBus.publishAvailabilitySlotCreated(
      slotId: slotId,
      coachId: coachId,
    );
  }

  /// 發布教練時段刪除事件 ⭐ v3.9
  @override
  void publishAvailabilitySlotDeleted({
    required String slotId,
    required String coachId,
  }) {
    _eventBus.publishAvailabilitySlotDeleted(
      slotId: slotId,
      coachId: coachId,
    );
  }

  /// 發布課程筆記更新事件 ⭐ v3.9
  @override
  void publishSessionNoteUpdated({
    required String noteId,
    required String coachId,
    required String clientId,
  }) {
    _eventBus.publishSessionNoteUpdated(
      noteId: noteId,
      coachId: coachId,
      clientId: clientId,
    );
  }

  // ==================== 通用發布方法 ====================

  /// ⭐ v3.5: 通用事件發布方法
  ///
  /// 適用於新增的事件類型（健康評估、收藏、關係等）
  @override
  void publish(AppEvent event) {
    _eventBus.publish(event);
    _lastEvent = event;
    notifyListeners();
  }

  // ==================== 清除最後事件 ====================

  /// 清除最後事件（UI 處理完畢後調用）
  @override
  void clearLastEvent() {
    _lastEvent = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
