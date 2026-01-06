/// 推播通知服務接口 ⭐ v3.0-C
///
/// 定義推播通知的所有方法（不依賴具體實現）
/// 支援 FCM（Android/iOS）+ 本地通知
abstract class INotificationService {
  // ============================================================
  // 初始化
  // ============================================================

  /// 初始化通知服務
  ///
  /// 1. 初始化 Firebase Messaging
  /// 2. 請求通知權限
  /// 3. 獲取 FCM Token
  /// 4. 設置前景/背景通知處理
  Future<void> initialize();

  /// 是否已初始化
  bool get isInitialized;

  // ============================================================
  // FCM Token 管理
  // ============================================================

  /// 獲取當前設備的 FCM Token
  Future<String?> getToken();

  /// 保存 FCM Token 到資料庫（user_devices 表）
  ///
  /// [userId] 用戶 ID
  /// [token] FCM Token
  /// [platform] 平台（android/ios/web）
  /// [deviceName] 設備名稱（可選）
  Future<void> saveTokenToDatabase(
    String userId,
    String token, {
    String platform = 'android',
    String? deviceName,
  });

  /// 刪除當前設備的 FCM Token（登出時調用）
  ///
  /// [userId] 用戶 ID
  Future<void> removeTokenFromDatabase(String userId);

  /// 監聽 Token 變化並自動更新
  ///
  /// [userId] 用戶 ID
  void listenForTokenChanges(String userId);

  // ============================================================
  // 本地通知
  // ============================================================

  /// 顯示本地通知
  ///
  /// [title] 標題
  /// [body] 內容
  /// [payload] 附加資料（點擊通知時使用）
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  });

  /// 取消所有通知
  Future<void> cancelAllNotifications();

  // ============================================================
  // 權限管理
  // ============================================================

  /// 請求通知權限
  ///
  /// 返回是否獲得權限
  Future<bool> requestPermission();

  /// 檢查是否有通知權限
  Future<bool> hasPermission();

  // ============================================================
  // 通知處理回調
  // ============================================================

  /// 設置前景通知處理回調
  ///
  /// [onMessage] 收到通知時的回調
  void setOnForegroundMessage(void Function(Map<String, dynamic> data) onMessage);

  /// 設置通知點擊回調
  ///
  /// [onTap] 點擊通知時的回調
  void setOnNotificationTap(void Function(Map<String, dynamic> data) onTap);
}

/// 通知類型枚舉
enum NotificationType {
  /// 新預約請求
  newAppointment,

  /// 預約已確認
  appointmentConfirmed,

  /// 預約被拒絕
  appointmentRejected,

  /// 預約已取消
  appointmentCancelled,

  /// 課前提醒（1 小時前）
  sessionReminder,

  /// 學員已填寫課前問卷
  readinessSubmitted,

  /// 一般通知
  general,
}

/// 從字串解析通知類型
NotificationType parseNotificationType(String? type) {
  switch (type) {
    case 'new_appointment':
      return NotificationType.newAppointment;
    case 'appointment_confirmed':
      return NotificationType.appointmentConfirmed;
    case 'appointment_rejected':
      return NotificationType.appointmentRejected;
    case 'appointment_cancelled':
      return NotificationType.appointmentCancelled;
    case 'session_reminder':
      return NotificationType.sessionReminder;
    case 'readiness_submitted':
      return NotificationType.readinessSubmitted;
    default:
      return NotificationType.general;
  }
}

