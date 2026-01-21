import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/coaching_relationship_model.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/services/interfaces/i_coaching_relationship_service.dart';

import '../../mocks/mock_services.dart';

/// CoachingRelationshipService 測試
///
/// P1 優先級 - 15 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockCoachingRelationshipService mockService;

  // 測試用的模型資料
  final testRelationship = CoachingRelationshipModel(
    id: 'rel-001',
    coachId: 'coach-001',
    clientId: 'client-001',
    status: 'active',
    invitedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testUser = UserModel(
    uid: 'client-001',
    email: 'client@example.com',
    displayName: 'Test Client',
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockCoachingRelationshipService();
  });

  group('ICoachingRelationshipService', () {
    // =========================================================================
    // getCoachClients
    // =========================================================================
    group('getCoachClients', () {
      test('正常獲取教練的學員列表', () async {
        // Arrange
        when(() => mockService.getCoachClients('coach-001'))
            .thenAnswer((_) async => [testRelationship]);

        // Act
        final result = await mockService.getCoachClients('coach-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].coachId, 'coach-001');
      });

      test('按狀態篩選', () async {
        // Arrange
        when(() => mockService.getCoachClients('coach-001', status: 'active'))
            .thenAnswer((_) async => [testRelationship]);

        // Act
        final result =
            await mockService.getCoachClients('coach-001', status: 'active');

        // Assert
        expect(result[0].status, 'active');
      });

      test('無學員返回空列表', () async {
        // Arrange
        when(() => mockService.getCoachClients('new-coach'))
            .thenAnswer((_) async => []);

        // Act
        final result = await mockService.getCoachClients('new-coach');

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // getClientCoaches
    // =========================================================================
    group('getClientCoaches', () {
      test('正常獲取學員的教練列表', () async {
        // Arrange
        when(() => mockService.getClientCoaches('client-001'))
            .thenAnswer((_) async => [testRelationship]);

        // Act
        final result = await mockService.getClientCoaches('client-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].clientId, 'client-001');
      });
    });

    // =========================================================================
    // getCoachClientsWithDetails
    // =========================================================================
    group('getCoachClientsWithDetails', () {
      test('正常獲取學員詳細資料', () async {
        // Arrange
        when(() => mockService.getCoachClientsWithDetails('coach-001'))
            .thenAnswer((_) async => [testUser]);

        // Act
        final result =
            await mockService.getCoachClientsWithDetails('coach-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].email, 'client@example.com');
      });
    });

    // =========================================================================
    // isActiveRelationship
    // =========================================================================
    group('isActiveRelationship', () {
      test('活躍關係返回 true', () async {
        // Arrange
        when(() => mockService.isActiveRelationship('coach-001', 'client-001'))
            .thenAnswer((_) async => true);

        // Act
        final result =
            await mockService.isActiveRelationship('coach-001', 'client-001');

        // Assert
        expect(result, isTrue);
      });

      test('無關係返回 false', () async {
        // Arrange
        when(() => mockService.isActiveRelationship('coach-001', 'unknown'))
            .thenAnswer((_) async => false);

        // Act
        final result =
            await mockService.isActiveRelationship('coach-001', 'unknown');

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // getActiveClientCount
    // =========================================================================
    group('getActiveClientCount', () {
      test('正常獲取活躍學員數量', () async {
        // Arrange
        when(() => mockService.getActiveClientCount('coach-001'))
            .thenAnswer((_) async => 5);

        // Act
        final result = await mockService.getActiveClientCount('coach-001');

        // Assert
        expect(result, 5);
      });

      test('無學員返回 0', () async {
        // Arrange
        when(() => mockService.getActiveClientCount('new-coach'))
            .thenAnswer((_) async => 0);

        // Act
        final result = await mockService.getActiveClientCount('new-coach');

        // Assert
        expect(result, 0);
      });
    });

    // =========================================================================
    // bindByQrCode
    // =========================================================================
    group('bindByQrCode', () {
      test('QR Code 綁定成功', () async {
        // Arrange
        final successResult = QrCodeBindResult(
          success: true,
          relationshipId: 'rel-new',
          coachId: 'coach-001',
          clientId: 'client-002',
        );
        when(() => mockService.bindByQrCode(
              scannedUserId: 'client-002',
              myUserId: 'coach-001',
              myRole: 'coach',
            )).thenAnswer((_) async => successResult);

        // Act
        final result = await mockService.bindByQrCode(
          scannedUserId: 'client-002',
          myUserId: 'coach-001',
          myRole: 'coach',
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.relationshipId, isNotNull);
      });

      test('QR Code 綁定失敗 - 用戶不存在', () async {
        // Arrange
        final failResult = QrCodeBindResult(
          success: false,
          error: 'User not found',
        );
        when(() => mockService.bindByQrCode(
              scannedUserId: 'not-exist',
              myUserId: 'coach-001',
              myRole: 'coach',
            )).thenAnswer((_) async => failResult);

        // Act
        final result = await mockService.bindByQrCode(
          scannedUserId: 'not-exist',
          myUserId: 'coach-001',
          myRole: 'coach',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });
    });

    // =========================================================================
    // acceptInvitation / rejectInvitation
    // =========================================================================
    group('Invitation Management', () {
      test('接受邀請', () async {
        // Arrange
        when(() => mockService.acceptInvitation('rel-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.acceptInvitation('rel-001'),
          completes,
        );
      });

      test('拒絕邀請', () async {
        // Arrange
        when(() => mockService.rejectInvitation('rel-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.rejectInvitation('rel-001'),
          completes,
        );
      });
    });

    // =========================================================================
    // archiveRelationship / deleteRelationship
    // =========================================================================
    group('Relationship Lifecycle', () {
      test('歸檔關係', () async {
        // Arrange
        when(() => mockService.archiveRelationship('rel-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.archiveRelationship('rel-001'),
          completes,
        );
      });

      test('刪除關係', () async {
        // Arrange
        when(() => mockService.deleteRelationship('rel-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.deleteRelationship('rel-001'),
          completes,
        );
      });
    });

    // =========================================================================
    // Cache Management
    // =========================================================================
    group('Cache Management', () {
      test('清除快取', () {
        // Arrange
        when(() => mockService.clearCache()).thenReturn(null);

        // Act & Assert
        expect(() => mockService.clearCache(), returnsNormally);
      });
    });
  });
}
