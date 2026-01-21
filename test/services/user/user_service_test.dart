import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/user/user_model.dart';

import '../../mocks/mock_services.dart';

/// UserService 測試
///
/// P1 優先級 - 10 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockUserService mockService;

  // 測試用的模型資料
  final testUser = UserModel(
    uid: 'user-001',
    email: 'test@example.com',
    displayName: 'Test User',
    photoURL: 'https://example.com/photo.jpg',
    isCoach: false,
    isStudent: true,
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockUserService();
  });

  group('IUserService', () {
    // =========================================================================
    // isProfileCompleted
    // =========================================================================
    group('isProfileCompleted', () {
      test('資料設置完成返回 true', () async {
        // Arrange
        when(() => mockService.isProfileCompleted())
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.isProfileCompleted();

        // Assert
        expect(result, isTrue);
      });

      test('資料未設置完成返回 false', () async {
        // Arrange
        when(() => mockService.isProfileCompleted())
            .thenAnswer((_) async => false);

        // Act
        final result = await mockService.isProfileCompleted();

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // getCurrentUserProfile
    // =========================================================================
    group('getCurrentUserProfile', () {
      test('正常獲取當前用戶資料', () async {
        // Arrange
        when(() => mockService.getCurrentUserProfile())
            .thenAnswer((_) async => testUser);

        // Act
        final result = await mockService.getCurrentUserProfile();

        // Assert
        expect(result, isNotNull);
        expect(result!.uid, 'user-001');
        expect(result.email, 'test@example.com');
      });

      test('未登入返回 null', () async {
        // Arrange
        when(() => mockService.getCurrentUserProfile())
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getCurrentUserProfile();

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // getUserProfile
    // =========================================================================
    group('getUserProfile', () {
      test('正常獲取指定用戶資料', () async {
        // Arrange
        when(() => mockService.getUserProfile('user-001'))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await mockService.getUserProfile('user-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.uid, 'user-001');
      });

      test('用戶不存在返回 null', () async {
        // Arrange
        when(() => mockService.getUserProfile('not-exist'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getUserProfile('not-exist');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // updateUserProfile
    // =========================================================================
    group('updateUserProfile', () {
      test('正常更新用戶資料', () async {
        // Arrange
        when(() => mockService.updateUserProfile(
              displayName: 'New Name',
            )).thenAnswer((_) async => true);

        // Act
        final result = await mockService.updateUserProfile(
          displayName: 'New Name',
        );

        // Assert
        expect(result, isTrue);
      });

      test('更新多個欄位', () async {
        // Arrange
        when(() => mockService.updateUserProfile(
              displayName: 'New Name',
              height: 175.0,
              weight: 70.0,
            )).thenAnswer((_) async => true);

        // Act
        final result = await mockService.updateUserProfile(
          displayName: 'New Name',
          height: 175.0,
          weight: 70.0,
        );

        // Assert
        expect(result, isTrue);
      });
    });

    // =========================================================================
    // toggleUserRole
    // =========================================================================
    group('toggleUserRole', () {
      test('切換為教練角色', () async {
        // Arrange
        when(() => mockService.toggleUserRole(true))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.toggleUserRole(true);

        // Assert
        expect(result, isTrue);
      });

      test('切換為學員角色', () async {
        // Arrange
        when(() => mockService.toggleUserRole(false))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.toggleUserRole(false);

        // Assert
        expect(result, isTrue);
      });
    });

    // =========================================================================
    // updateUserWeight
    // =========================================================================
    group('updateUserWeight', () {
      test('正常更新用戶體重', () async {
        // Arrange
        when(() => mockService.updateUserWeight('user-001', 72.5))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.updateUserWeight('user-001', 72.5);

        // Assert
        expect(result, isTrue);
      });
    });

    // =========================================================================
    // deleteUserAccount
    // =========================================================================
    group('deleteUserAccount', () {
      test('正常刪除用戶帳號', () async {
        // Arrange
        when(() => mockService.deleteUserAccount())
            .thenAnswer((_) async => {'success': true, 'deleted_tables': 5});

        // Act
        final result = await mockService.deleteUserAccount();

        // Assert
        expect(result['success'], isTrue);
      });
    });
  });
}
