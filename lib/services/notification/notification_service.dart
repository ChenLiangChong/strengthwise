import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:strengthwise/services/interfaces/i_notification_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';

/// 背景訊息處理（必須是頂層函數）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 確保 Firebase 已初始化
  await Firebase.initializeApp();
  
  if (kDebugMode) {
    print('[NotificationService] 背景訊息: ${message.messageId}');
  }
}

/// FCM 推播通知服務實作 ⭐ v3.0-C
///
/// 整合 Firebase Cloud Messaging + Flutter Local Notifications
/// 支援：
/// - 前景/背景/終止狀態的通知接收
/// - 本地通知顯示
/// - FCM Token 管理
class NotificationService implements INotificationService {
  final ErrorHandlingService _errorService;
  final SupabaseClient _supabase;

  // Firebase Messaging 實例
  late final FirebaseMessaging _messaging;

  // Local Notifications 插件
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // 狀態標記
  bool _isInitialized = false;

  // 回調函數
  void Function(Map<String, dynamic> data)? _onForegroundMessage;
  void Function(Map<String, dynamic> data)? _onNotificationTap;

  // Token 變化監聽
  StreamSubscription<String>? _tokenSubscription;

  NotificationService({
    required ErrorHandlingService errorService,
    SupabaseClient? supabase,
  })  : _errorService = errorService,
        _supabase = supabase ?? Supabase.instance.client;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. 初始化 Firebase（如果尚未初始化）
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      _messaging = FirebaseMessaging.instance;

      // 2. 請求權限
      await requestPermission();

      // 3. 設置背景訊息處理
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 4. 初始化本地通知
      await _initializeLocalNotifications();

      // 5. 設置前景訊息處理
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 6. 設置通知點擊處理
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // 7. 檢查是否從通知啟動
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('[NotificationService] ✅ 初始化完成');
      }
    } catch (e) {
      _errorService.logError('初始化通知服務失敗: $e',
          type: 'NotificationServiceError');
      rethrow;
    }
  }

  /// 初始化本地通知
  Future<void> _initializeLocalNotifications() async {
    // Android 設置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 設置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // 創建 Android 通知頻道
    const androidChannel = AndroidNotificationChannel(
      'strengthwise_channel',
      'StrengthWise 通知',
      description: '預約提醒、課程通知等',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// 處理前景訊息
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('[NotificationService] 前景訊息: ${message.notification?.title}');
    }

    // 顯示本地通知
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? '新通知',
        body: message.notification!.body ?? '',
        payload: message.data,
      );
    }

    // 調用回調
    _onForegroundMessage?.call(message.data);
  }

  /// 處理通知點擊
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('[NotificationService] 通知點擊: ${message.data}');
    }

    _onNotificationTap?.call(message.data);
  }

  /// 處理本地通知點擊
  void _onLocalNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      print('[NotificationService] 本地通知點擊: ${response.payload}');
    }

    // 解析 payload 並調用回調
    if (response.payload != null) {
      // TODO: 解析 JSON payload
      _onNotificationTap?.call({'payload': response.payload});
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (kDebugMode) {
        print('[NotificationService] FCM Token: ${token?.substring(0, 20)}...');
      }
      return token;
    } catch (e) {
      _errorService.logError('獲取 FCM Token 失敗: $e',
          type: 'NotificationServiceError');
      return null;
    }
  }

  @override
  Future<void> saveTokenToDatabase(
    String userId,
    String token, {
    String platform = 'android',
    String? deviceName,
  }) async {
    try {
      // 使用 RPC 函數來安全地添加 token（user_devices 表）
      await _supabase.rpc('upsert_device_token', params: {
        'p_user_id': userId,
        'p_token': token,
        'p_platform': platform,
        'p_device_name': deviceName,
      });

      if (kDebugMode) {
        print('[NotificationService] ✅ FCM Token 已保存到 user_devices');
      }
    } catch (e) {
      _errorService.logError('保存 FCM Token 失敗: $e',
          type: 'NotificationServiceError');
    }
  }

  @override
  Future<void> removeTokenFromDatabase(String userId) async {
    try {
      final token = await getToken();
      if (token == null) return;

      // 使用 RPC 函數移除 token（user_devices 表）
      await _supabase.rpc('remove_device_token', params: {
        'p_user_id': userId,
        'p_token': token,
      });

      if (kDebugMode) {
        print('[NotificationService] ✅ FCM Token 已從 user_devices 移除');
      }
    } catch (e) {
      _errorService.logError('移除 FCM Token 失敗: $e',
          type: 'NotificationServiceError');
    }
  }

  @override
  void listenForTokenChanges(String userId) {
    _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('[NotificationService] Token 已更新');
      }
      saveTokenToDatabase(userId, newToken);
    });
  }

  @override
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'strengthwise_channel',
      'StrengthWise 通知',
      channelDescription: '預約提醒、課程通知等',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload?.toString(),
    );
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (kDebugMode) {
        print('[NotificationService] 權限狀態: ${settings.authorizationStatus}');
      }

      return granted;
    } catch (e) {
      _errorService.logError('請求通知權限失敗: $e',
          type: 'NotificationServiceError');
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  void setOnForegroundMessage(void Function(Map<String, dynamic> data) onMessage) {
    _onForegroundMessage = onMessage;
  }

  @override
  void setOnNotificationTap(void Function(Map<String, dynamic> data) onTap) {
    _onNotificationTap = onTap;
  }

  /// 釋放資源
  void dispose() {
    _tokenSubscription?.cancel();
  }
}

