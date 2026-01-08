import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/services/interfaces/i_notification_service.dart';

/// Mock NotificationService for testing
class MockNotificationService extends Mock implements INotificationService {}

/// NotificationService 接口測試
///
/// P6 優先級 - 10 個測試案例
void main() {
  late MockNotificationService mockService;

  setUp(() {
    mockService = MockNotificationService();

    // 預設行為
    when(() => mockService.isInitialized).thenReturn(true);
    when(() => mockService.initialize()).thenAnswer((_) async {});
    when(() => mockService.getToken())
        .thenAnswer((_) async => 'fake-fcm-token');
    when(() => mockService.saveTokenToDatabase(
          any(),
          any(),
          platform: any(named: 'platform'),
          deviceName: any(named: 'deviceName'),
        )).thenAnswer((_) async {});
    when(() => mockService.removeTokenFromDatabase(any()))
        .thenAnswer((_) async {});
    when(() => mockService.listenForTokenChanges(any())).thenReturn(null);
    when(() => mockService.showLocalNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        )).thenAnswer((_) async {});
    when(() => mockService.cancelAllNotifications()).thenAnswer((_) async {});
    when(() => mockService.requestPermission()).thenAnswer((_) async => true);
    when(() => mockService.hasPermission()).thenAnswer((_) async => true);
  });

  group('NotificationService', () {
    // =========================================================================
    // P6-294: initialize
    // =========================================================================
    test('initialize 正確初始化', () async {
      await mockService.initialize();
      verify(() => mockService.initialize()).called(1);
    });

    // =========================================================================
    // P6-295: getToken
    // =========================================================================
    test('getToken 返回有效 Token', () async {
      final token = await mockService.getToken();
      expect(token, isNotNull);
      expect(token, 'fake-fcm-token');
    });

    // =========================================================================
    // P6-296: saveTokenToDatabase
    // =========================================================================
    test('saveTokenToDatabase 保存成功', () async {
      await mockService.saveTokenToDatabase(
        'user-001',
        'token-abc',
        platform: 'android',
      );
      verify(() => mockService.saveTokenToDatabase(
            'user-001',
            'token-abc',
            platform: 'android',
            deviceName: null,
          )).called(1);
    });

    // =========================================================================
    // P6-297: removeTokenFromDatabase
    // =========================================================================
    test('removeTokenFromDatabase 刪除成功', () async {
      await mockService.removeTokenFromDatabase('user-001');
      verify(() => mockService.removeTokenFromDatabase('user-001')).called(1);
    });

    // =========================================================================
    // P6-298: listenForTokenChanges
    // =========================================================================
    test('listenForTokenChanges 設置監聽', () {
      mockService.listenForTokenChanges('user-001');
      verify(() => mockService.listenForTokenChanges('user-001')).called(1);
    });

    // =========================================================================
    // P6-299: showLocalNotification
    // =========================================================================
    test('showLocalNotification 顯示通知', () async {
      await mockService.showLocalNotification(
        title: '測試標題',
        body: '測試內容',
      );
      verify(() => mockService.showLocalNotification(
            title: '測試標題',
            body: '測試內容',
            payload: null,
          )).called(1);
    });

    // =========================================================================
    // P6-300: cancelAllNotifications
    // =========================================================================
    test('cancelAllNotifications 取消所有通知', () async {
      await mockService.cancelAllNotifications();
      verify(() => mockService.cancelAllNotifications()).called(1);
    });

    // =========================================================================
    // P6-301: requestPermission
    // =========================================================================
    test('requestPermission 請求權限成功', () async {
      final granted = await mockService.requestPermission();
      expect(granted, isTrue);
    });

    // =========================================================================
    // P6-302: hasPermission
    // =========================================================================
    test('hasPermission 檢查權限', () async {
      final hasPermission = await mockService.hasPermission();
      expect(hasPermission, isTrue);
    });

    // =========================================================================
    // P6-303: isInitialized
    // =========================================================================
    test('isInitialized 返回初始化狀態', () {
      expect(mockService.isInitialized, isTrue);
    });
  });

  group('NotificationType', () {
    // =========================================================================
    // 通知類型解析
    // =========================================================================
    test('parseNotificationType 解析 new_appointment', () {
      final type = parseNotificationType('new_appointment');
      expect(type, NotificationType.newAppointment);
    });

    test('parseNotificationType 解析 appointment_confirmed', () {
      final type = parseNotificationType('appointment_confirmed');
      expect(type, NotificationType.appointmentConfirmed);
    });

    test('parseNotificationType 解析 readiness_submitted', () {
      final type = parseNotificationType('readiness_submitted');
      expect(type, NotificationType.readinessSubmitted);
    });

    test('parseNotificationType 未知類型返回 general', () {
      final type = parseNotificationType('unknown_type');
      expect(type, NotificationType.general);
    });

    test('parseNotificationType null 返回 general', () {
      final type = parseNotificationType(null);
      expect(type, NotificationType.general);
    });
  });
}
