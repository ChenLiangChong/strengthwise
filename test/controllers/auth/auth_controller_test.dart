import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/controllers/auth_controller.dart';
import 'package:strengthwise/services/interfaces/i_auth_service.dart';
import 'package:strengthwise/services/core/error_handling_service.dart';

// Mock Classes
class MockAuthService extends Mock implements IAuthService {}

class MockErrorHandlingService extends Mock implements ErrorHandlingService {}

/// AuthController 測試
///
/// P3 優先級 - 10 個測試案例
void main() {
  late MockAuthService mockService;
  late MockErrorHandlingService mockErrorService;
  late AuthController controller;

  setUp(() {
    mockService = MockAuthService();
    mockErrorService = MockErrorHandlingService();

    // 預設行為
    when(() => mockService.getCurrentUser())
        .thenReturn({'uid': 'user-001', 'email': 'test@example.com'});
    when(() => mockService.signInWithEmail(any(), any()))
        .thenAnswer((_) async => {'uid': 'user-001'});
    when(() => mockService.registerWithEmail(any(), any()))
        .thenAnswer((_) async => {'uid': 'new-user-001'});
    when(() => mockService.signOut()).thenAnswer((_) async {});
    when(() => mockService.signInWithGoogle())
        .thenAnswer((_) async => {'uid': 'google-user-001'});
    when(() => mockErrorService.logError(any(), type: any(named: 'type')))
        .thenReturn(null);

    controller = AuthController(
      authService: mockService,
      errorService: mockErrorService,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('AuthController', () {
    // =========================================================================
    // P3-236: signInWithEmail
    // =========================================================================
    group('signInWithEmail', () {
      test('成功登入', () async {
        // Act
        final result =
            await controller.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(result, isTrue);
        verify(() =>
                mockService.signInWithEmail('test@example.com', 'password123'))
            .called(1);
      });
    });

    // =========================================================================
    // P3-237: registerWithEmail
    // =========================================================================
    group('registerWithEmail', () {
      test('成功註冊', () async {
        // Act
        final result = await controller.registerWithEmail(
            'new@example.com', 'password123');

        // Assert
        expect(result, isTrue);
        verify(() =>
                mockService.registerWithEmail('new@example.com', 'password123'))
            .called(1);
      });
    });

    // =========================================================================
    // P3-238: signInWithGoogle
    // =========================================================================
    group('signInWithGoogle', () {
      test('成功 Google 登入', () async {
        // Act
        final result = await controller.signInWithGoogle();

        // Assert
        expect(result, isTrue);
        verify(() => mockService.signInWithGoogle()).called(1);
      });
    });

    // =========================================================================
    // P3-239: signOut
    // =========================================================================
    group('signOut', () {
      test('成功登出', () async {
        // Act
        await controller.signOut();

        // Assert
        verify(() => mockService.signOut()).called(1);
      });
    });

    // =========================================================================
    // P3-240: 狀態管理
    // =========================================================================
    group('狀態管理', () {
      test('isLoggedIn 返回登入狀態', () {
        expect(controller.isLoggedIn, isTrue);
      });

      test('clearError 清除錯誤', () {
        controller.clearError();
        expect(controller.errorMessage, isNull);
      });

      test('isEmailValid 驗證郵件格式', () {
        expect(controller.isEmailValid('valid@email.com'), isTrue);
        expect(controller.isEmailValid('invalid'), isFalse);
      });

      test('getPasswordStrength 返回密碼強度', () {
        expect(controller.getPasswordStrength('weak'), lessThan(2));
        expect(controller.getPasswordStrength('StrongP@ss123'),
            greaterThanOrEqualTo(2));
      });
    });
  });
}
