import 'dart:async';
import '../../services/core/app_event_bus.dart';

/// 事件匯流排控制器接口
///
/// 作為 AppEventBus（Service 層）和 View 層之間的中間層，
/// 符合 MVVM 架構的分層原則。
abstract class IEventBusController {
  // ==================== 狀態 Getters ====================

  /// 最後收到的事件（用於 UI 判斷）
  AppEvent? get lastEvent;

  // ==================== 過濾後的事件流 ====================

  /// 訓練計畫相關事件流
  Stream<AppEvent> get workoutEvents;

  /// 預約相關事件流
  Stream<AppEvent> get appointmentEvents;

  /// 模板相關事件流
  Stream<AppEvent> get templateEvents;

  /// 身體數據相關事件流
  Stream<AppEvent> get bodyDataEvents;

  /// 行事曆相關事件流（訓練 + 預約）
  Stream<AppEvent> get calendarEvents;

  /// 時段相關事件流（教練時段 + 學員偏好）
  Stream<AppEvent> get availabilityEvents;

  /// 首頁相關事件流（今日行程變更）
  Stream<AppEvent> get homePageEvents;

  /// 統計相關事件流
  Stream<AppEvent> get statisticsEvents;

  // ==================== 訓練事件發布 ====================

  /// 發布訓練計畫創建事件
  void publishWorkoutCreated({
    required String workoutId,
    required String userId,
    Map<String, dynamic>? metadata,
  });

  /// 發布訓練計畫更新事件
  void publishWorkoutUpdated({
    required String workoutId,
    required String userId,
  });

  /// 發布訓練計畫刪除事件
  void publishWorkoutDeleted({
    required String workoutId,
    required String userId,
  });

  /// 發布訓練完成事件
  void publishWorkoutCompleted({
    required String workoutId,
    required String userId,
  });

  // ==================== 預約事件發布 ====================

  /// 發布預約創建事件
  void publishAppointmentCreated({
    required String appointmentId,
    String? coachId,
    String? clientId,
    String? userId,
  });

  /// 發布預約取消事件
  void publishAppointmentCancelled({
    required String appointmentId,
    String? coachId,
    String? clientId,
    String? userId,
  });

  /// 發布預約確認事件
  void publishAppointmentConfirmed({
    required String appointmentId,
    String? coachId,
    String? clientId,
    String? userId,
  });

  /// 發布預約完成事件
  void publishAppointmentCompleted({
    required String appointmentId,
    required String coachId,
    required String clientId,
  });

  /// 發布預約重新安排事件
  void publishAppointmentRescheduled({
    required String appointmentId,
    required String coachId,
    required String clientId,
  });

  // ==================== 其他事件發布 ====================

  /// 發布身體數據更新事件
  void publishBodyDataUpdated({required String userId});

  /// 發布模板創建事件
  void publishTemplateCreated({
    required String templateId,
    required String userId,
  });

  /// 發布模板更新事件
  void publishTemplateUpdated({
    required String templateId,
    required String userId,
  });

  /// 發布模板刪除事件
  void publishTemplateDeleted({
    required String templateId,
    required String userId,
  });

  /// 發布關係建立事件
  void publishRelationshipCreated({
    required String relationshipId,
    required String coachId,
    required String clientId,
  });

  /// 發布教練時段建立事件
  void publishAvailabilitySlotCreated({
    required String slotId,
    required String coachId,
  });

  /// 發布教練時段刪除事件
  void publishAvailabilitySlotDeleted({
    required String slotId,
    required String coachId,
  });

  /// 發布課程筆記更新事件
  void publishSessionNoteUpdated({
    required String noteId,
    required String coachId,
    required String clientId,
  });

  // ==================== 通用方法 ====================

  /// 通用事件發布方法
  void publish(AppEvent event);

  /// 清除最後事件（UI 處理完畢後調用）
  void clearLastEvent();
}
