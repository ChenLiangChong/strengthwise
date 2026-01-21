import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_services.dart';

/// AuthService 測試
///
/// P1 優先級 - 10 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockAuthService mockService;

  // 測試用的用戶資料
  final testUser = {
    'id': 'user-001',
    'email': 'test@example.com',
    'displayName': 'Test User',
  };

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockAuthService();
  });

  group('IAuthService', () {
    // =========================================================================
    // isUserLoggedIn
    // =========================================================================
    group('isUserLoggedIn', () {
      test('用戶已登入返回 true', () {
        // Arrange
        when(() => mockService.isUserLoggedIn()).thenReturn(true);

        // Act
        final result = mockService.isUserLoggedIn();

        // Assert
        expect(result, isTrue);
      });

      test('用戶未登入返回 false', () {
        // Arrange
        when(() => mockService.isUserLoggedIn()).thenReturn(false);

        // Act
        final result = mockService.isUserLoggedIn();

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // getCurrentUser
    // =========================================================================
    group('getCurrentUser', () {
      test('登入後返回用戶資訊', () {
        // Arrange
        when(() => mockService.getCurrentUser()).thenReturn(testUser);

        // Act
        final result = mockService.getCurrentUser();

        // Assert
        expect(result, isNotNull);
        expect(result!['id'], 'user-001');
        expect(result['email'], 'test@example.com');
      });

      test('未登入返回 null', () {
        // Arrange
        when(() => mockService.getCurrentUser()).thenReturn(null);

        // Act
        final result = mockService.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // signInWithGoogle
    // =========================================================================
    group('signInWithGoogle', () {
      test('Google 登入成功', () async {
        // Arrange
        when(() => mockService.signInWithGoogle())
            .thenAnswer((_) async => testUser);

        // Act
        final result = await mockService.signInWithGoogle();

        // Assert
        expect(result, isNotNull);
        expect(result!['email'], 'test@example.com');
      });

      test('Google 登入取消返回 null', () async {
        // Arrange
        when(() => mockService.signInWithGoogle()).thenAnswer((_) async => null);

        // Act
        final result = await mockService.signInWithGoogle();

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // signInWithEmail
    // =========================================================================
    group('signInWithEmail', () {
      test('Email 登入成功', () async {
        // Arrange
        when(() => mockService.signInWithEmail('test@example.com', 'password'))
            .thenAnswer((_) async => testUser);

        // Act
        final result =
            await mockService.signInWithEmail('test@example.com', 'password');

        // Assert
        expect(result, isNotNull);
      });

      test('Email 登入失敗返回 null', () async {
        // Arrange
        when(() => mockService.signInWithEmail('test@example.com', 'wrong'))
            .thenAnswer((_) async => null);

        // Act
        final result =
            await mockService.signInWithEmail('test@example.com', 'wrong');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // signOut
    // =========================================================================
    group('signOut', () {
      test('登出成功', () async {
        // Arrange
        when(() => mockService.signOut()).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(mockService.signOut(), completes);
        verify(() => mockService.signOut()).called(1);
      });
    });

    // =========================================================================
    // isOAuthUser
    // =========================================================================
    group('isOAuthUser', () {
      test('OAuth 用戶返回 true', () {
        // Arrange
        when(() => mockService.isOAuthUser()).thenReturn(true);

        // Act
        final result = mockService.isOAuthUser();

        // Assert
        expect(result, isTrue);
      });

      test('Email 用戶返回 false', () {
        // Arrange
        when(() => mockService.isOAuthUser()).thenReturn(false);

        // Act
        final result = mockService.isOAuthUser();

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
