import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/controllers/coaching_relationship_controller.dart';
import 'package:strengthwise/controllers/event_bus_controller.dart';
import 'package:strengthwise/models/coaching_relationship_model.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/services/interfaces/i_coaching_relationship_service.dart';
import 'package:strengthwise/services/interfaces/i_user_service.dart';
import 'package:strengthwise/services/interfaces/i_invite_code_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';

// Mock 類別
class MockCoachingRelationshipService extends Mock
    implements ICoachingRelationshipService {}

class MockUserService extends Mock implements IUserService {}

class MockInviteCodeService extends Mock implements IInviteCodeService {}

class MockErrorHandlingService extends Mock implements ErrorHandlingService {}

class MockEventBusController extends Mock implements EventBusController {}

/// CoachingRelationshipController 測試
void main() {
  late MockCoachingRelationshipService mockRelationshipService;
  late MockUserService mockUserService;
  late MockInviteCodeService mockInviteCodeService;
  late MockErrorHandlingService mockErrorService;
  late MockEventBusController mockEventBusController;
  late CoachingRelationshipController controller;

  final testUser = UserModel(
    uid: 'user-001',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  final testClients = [
    UserModel(uid: 'client-001', email: 'client1@example.com'),
    UserModel(uid: 'client-002', email: 'client2@example.com'),
  ];

  final testRelationship = CoachingRelationshipModel(
    id: 'rel-001',
    coachId: 'coach-001',
    clientId: 'client-001',
    status: 'active',
    invitedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockRelationshipService = MockCoachingRelationshipService();
    mockUserService = MockUserService();
    mockInviteCodeService = MockInviteCodeService();
    mockErrorService = MockErrorHandlingService();
    mockEventBusController = MockEventBusController();

    // 預設 mock 行為
    when(() => mockRelationshipService.getCoachClientsWithDetails(any(),
        status: any(named: 'status'))).thenAnswer((_) async => testClients);
    when(() => mockRelationshipService.getActiveClientCount(any()))
        .thenAnswer((_) async => 2);
    when(() => mockRelationshipService.clearCache()).thenReturn(null);
    when(() => mockUserService.getCurrentUserProfile())
        .thenAnswer((_) async => testUser);
    when(() => mockErrorService.logError(any(), type: any(named: 'type')))
        .thenReturn(null);

    // v3.5: 新增 EventBusController
    controller = CoachingRelationshipController(
      mockRelationshipService,
      mockUserService,
      mockInviteCodeService,
      mockErrorService,
      mockEventBusController,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('CoachingRelationshipController 初始狀態', () {
    test('初始 isLoading 應該為 false', () {
      expect(controller.isLoading, isFalse);
    });

    test('初始 errorMessage 應該為 null', () {
      expect(controller.errorMessage, isNull);
    });

    test('初始 clients 應該為空', () {
      expect(controller.clients, isEmpty);
    });

    test('初始 activeClientCount 應該為 0', () {
      expect(controller.activeClientCount, 0);
    });
  });

  group('CoachingRelationshipController.loadCoachClients', () {
    test('應該載入學員列表', () async {
      await controller.loadCoachClients('coach-001');

      expect(controller.clients.length, 2);
      verify(() => mockRelationshipService.getCoachClientsWithDetails(
            'coach-001',
            status: 'active',
          )).called(1);
    });

    test('應該同時載入活躍學員數量', () async {
      await controller.loadCoachClients('coach-001');

      expect(controller.activeClientCount, 2);
      verify(() => mockRelationshipService.getActiveClientCount('coach-001'))
          .called(1);
    });

    test('載入失敗時應該設定錯誤訊息', () async {
      when(() => mockRelationshipService.getCoachClientsWithDetails(any(),
          status: any(named: 'status'))).thenThrow(Exception('Error'));

      await controller.loadCoachClients('coach-001');

      expect(controller.errorMessage, contains('載入學員列表失敗'));
    });
  });

  group('CoachingRelationshipController.inviteClient', () {
    test('成功邀請應該返回 true', () async {
      when(() => mockRelationshipService.inviteClient(any(), any()))
          .thenAnswer((_) async => testRelationship);

      final result =
          await controller.inviteClient('coach-001', 'client@example.com');

      expect(result, isTrue);
    });

    test('邀請失敗應該返回 false', () async {
      when(() => mockRelationshipService.inviteClient(any(), any()))
          .thenThrow(Exception('Error'));

      final result =
          await controller.inviteClient('coach-001', 'client@example.com');

      expect(result, isFalse);
      expect(controller.errorMessage, contains('邀請學員失敗'));
    });
  });

  group('CoachingRelationshipController.createRelationship', () {
    test('成功創建應該返回 true', () async {
      when(() => mockRelationshipService.createRelationship(any(), any(),
              status: any(named: 'status')))
          .thenAnswer((_) async => testRelationship);

      final result =
          await controller.createRelationship('coach-001', 'client-001');

      expect(result, isTrue);
    });
  });

  group('CoachingRelationshipController.archiveClient', () {
    test('成功歸檔應該返回 true', () async {
      when(() => mockRelationshipService.archiveRelationship(any()))
          .thenAnswer((_) async {});

      final result = await controller.archiveClient('rel-001', 'coach-001');

      expect(result, isTrue);
    });
  });

  group('CoachingRelationshipController.archiveRelationship', () {
    test('成功歸檔應該返回 true', () async {
      when(() => mockRelationshipService.archiveRelationship(any()))
          .thenAnswer((_) async {});

      final result = await controller.archiveRelationship('rel-001');

      expect(result, isTrue);
    });

    test('歸檔失敗應該返回 false', () async {
      when(() => mockRelationshipService.archiveRelationship(any()))
          .thenThrow(Exception('Error'));

      final result = await controller.archiveRelationship('rel-001');

      expect(result, isFalse);
      expect(controller.errorMessage, contains('解除綁定失敗'));
    });
  });

  group('CoachingRelationshipController.loadPendingInvitations', () {
    test('應該載入待處理邀請', () async {
      when(() => mockRelationshipService.getClientCoaches(any(),
              status: any(named: 'status')))
          .thenAnswer((_) async => [testRelationship]);

      await controller.loadPendingInvitations('client-001');

      expect(controller.pendingInvitations.length, 1);
    });
  });

  group('CoachingRelationshipController.loadClientCoaches', () {
    test('應該載入教練列表', () async {
      when(() => mockRelationshipService.getClientCoaches(any(),
              status: any(named: 'status')))
          .thenAnswer((_) async => [testRelationship]);

      await controller.loadClientCoaches('client-001');

      expect(controller.coaches.length, 1);
    });
  });

  group('CoachingRelationshipController.acceptInvitation', () {
    test('成功接受應該返回 true', () async {
      when(() => mockRelationshipService.acceptInvitation(any()))
          .thenAnswer((_) async {});
      when(() => mockRelationshipService.getClientCoaches(any(),
          status: any(named: 'status'))).thenAnswer((_) async => []);

      final result = await controller.acceptInvitation('rel-001', 'client-001');

      expect(result, isTrue);
    });
  });

  group('CoachingRelationshipController.rejectInvitation', () {
    test('成功拒絕應該返回 true', () async {
      when(() => mockRelationshipService.rejectInvitation(any()))
          .thenAnswer((_) async {});
      when(() => mockRelationshipService.getClientCoaches(any(),
          status: any(named: 'status'))).thenAnswer((_) async => []);

      final result = await controller.rejectInvitation('rel-001', 'client-001');

      expect(result, isTrue);
    });
  });

  group('CoachingRelationshipController.deleteRelationship', () {
    test('成功刪除應該返回 true', () async {
      when(() => mockRelationshipService.deleteRelationship(any()))
          .thenAnswer((_) async {});

      final result = await controller.deleteRelationship('rel-001');

      expect(result, isTrue);
    });
  });

  group('CoachingRelationshipController.validateQRCode', () {
    test('有效 QR Code 應該返回解析結果', () {
      const validQR =
          '{"app":"strengthwise","role":"coach","user_id":"u001","name":"Coach","email":"coach@test.com","timestamp":"2026-01-14"}';

      final result = controller.validateQRCode(validQR);

      expect(result, isNotNull);
      expect(result!['role'], 'coach');
      expect(result['user_id'], 'u001');
    });

    test('非 StrengthWise QR Code 應該返回 null', () {
      const invalidQR = '{"app":"other_app","data":"test"}';

      final result = controller.validateQRCode(invalidQR);

      expect(result, isNull);
    });

    test('無效 JSON 應該返回 null', () {
      const invalidQR = 'not a json';

      final result = controller.validateQRCode(invalidQR);

      expect(result, isNull);
    });
  });

  group('CoachingRelationshipController.clearCache', () {
    test('應該呼叫 Service 的 clearCache', () {
      controller.clearCache();

      verify(() => mockRelationshipService.clearCache()).called(1);
    });
  });

  group('CoachingRelationshipController.clearInviteCodeCache', () {
    test('應該清除邀請碼快取', () {
      controller.clearInviteCodeCache();
      // 驗證不會拋出異常
    });
  });
}
