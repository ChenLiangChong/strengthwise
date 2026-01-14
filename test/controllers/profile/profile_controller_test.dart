import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/controllers/profile_controller.dart';
import 'package:strengthwise/models/user/user_model.dart';
import 'package:strengthwise/services/interfaces/i_user_service.dart';
import 'package:strengthwise/services/interfaces/i_auth_service.dart';

// Mock 類別
class MockUserService extends Mock implements IUserService {}

class MockAuthService extends Mock implements IAuthService {}

/// ProfileController 測試
void main() {
  late MockUserService mockUserService;
  late MockAuthService mockAuthService;
  late ProfileController controller;

  // 測試資料 - 使用正確的 uid 而非 id
  final testUser = UserModel(
    uid: 'user-001',
    email: 'test@example.com',
    displayName: '測試用戶',
    nickname: 'Tester',
    gender: 'male',
    height: 175.0,
    weight: 70.0,
    birthDate: DateTime(1990, 1, 1),
  );

  setUp(() {
    mockUserService = MockUserService();
    mockAuthService = MockAuthService();

    // 預設 mock 行為
    when(() => mockUserService.getCurrentUserProfile())
        .thenAnswer((_) async => testUser);
    when(() => mockAuthService.getCurrentUser())
        .thenReturn({'email': 'test@example.com'});
    when(() => mockAuthService.isOAuthUser()).thenReturn(false);
    when(() => mockAuthService.hasPassword()).thenReturn(true);

    controller = ProfileController(
      userService: mockUserService,
      authService: mockAuthService,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('ProfileController 初始狀態', () {
    test('初始 userProfile 應該為 null', () {
      expect(controller.userProfile, isNull);
    });

    test('初始 isLoading 應該為 false', () {
      expect(controller.isLoading, isFalse);
    });

    test('初始 errorMessage 應該為 null', () {
      expect(controller.errorMessage, isNull);
    });
  });

  group('ProfileController.loadUserProfile', () {
    test('應該載入用戶資料', () async {
      await controller.loadUserProfile();

      expect(controller.userProfile, isNotNull);
      expect(controller.userProfile!.displayName, '測試用戶');
      verify(() => mockUserService.getCurrentUserProfile()).called(1);
    });

    test('載入時 isLoading 應該為 true', () async {
      // 延遲回應以便檢查 loading 狀態
      when(() => mockUserService.getCurrentUserProfile()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return testUser;
      });

      final future = controller.loadUserProfile();
      expect(controller.isLoading, isTrue);

      await future;
      expect(controller.isLoading, isFalse);
    });

    test('載入失敗時應該設定錯誤訊息', () async {
      when(() => mockUserService.getCurrentUserProfile())
          .thenThrow(Exception('Network error'));

      await controller.loadUserProfile();

      expect(controller.errorMessage, contains('載入個人資料失敗'));
      expect(controller.isLoading, isFalse);
    });
  });

  group('ProfileController.updateUserProfile', () {
    test('更新成功應該返回 true', () async {
      when(() => mockUserService.updateUserProfile(
            displayName: any(named: 'displayName'),
            nickname: any(named: 'nickname'),
            gender: any(named: 'gender'),
            genderVisible: any(named: 'genderVisible'),
            height: any(named: 'height'),
            weight: any(named: 'weight'),
            birthDate: any(named: 'birthDate'),
            bio: any(named: 'bio'),
            unitSystem: any(named: 'unitSystem'),
            isCoach: any(named: 'isCoach'),
            isStudent: any(named: 'isStudent'),
            avatarFile: any(named: 'avatarFile'),
          )).thenAnswer((_) async => true);

      final result = await controller.updateUserProfile(displayName: '新名稱');

      expect(result, isTrue);
    });

    test('更新失敗應該返回 false', () async {
      when(() => mockUserService.updateUserProfile(
            displayName: any(named: 'displayName'),
            nickname: any(named: 'nickname'),
            gender: any(named: 'gender'),
            genderVisible: any(named: 'genderVisible'),
            height: any(named: 'height'),
            weight: any(named: 'weight'),
            birthDate: any(named: 'birthDate'),
            bio: any(named: 'bio'),
            unitSystem: any(named: 'unitSystem'),
            isCoach: any(named: 'isCoach'),
            isStudent: any(named: 'isStudent'),
            avatarFile: any(named: 'avatarFile'),
          )).thenAnswer((_) async => false);

      final result = await controller.updateUserProfile(displayName: '新名稱');

      expect(result, isFalse);
      expect(controller.errorMessage, '保存失敗');
    });

    test('更新拋出異常應該返回 false', () async {
      when(() => mockUserService.updateUserProfile(
            displayName: any(named: 'displayName'),
            nickname: any(named: 'nickname'),
            gender: any(named: 'gender'),
            genderVisible: any(named: 'genderVisible'),
            height: any(named: 'height'),
            weight: any(named: 'weight'),
            birthDate: any(named: 'birthDate'),
            bio: any(named: 'bio'),
            unitSystem: any(named: 'unitSystem'),
            isCoach: any(named: 'isCoach'),
            isStudent: any(named: 'isStudent'),
            avatarFile: any(named: 'avatarFile'),
          )).thenThrow(Exception('Error'));

      final result = await controller.updateUserProfile(displayName: '新名稱');

      expect(result, isFalse);
      expect(controller.errorMessage, contains('保存失敗'));
    });
  });

  group('ProfileController.toggleCoachRole', () {
    test('成功應該返回 true 並重新載入', () async {
      when(() => mockUserService.toggleUserRole(any()))
          .thenAnswer((_) async => true);

      final result = await controller.toggleCoachRole(true);

      expect(result, isTrue);
      verify(() => mockUserService.toggleUserRole(true)).called(1);
      // 應該重新載入 profile
      verify(() => mockUserService.getCurrentUserProfile()).called(1);
    });

    test('失敗應該返回 false', () async {
      when(() => mockUserService.toggleUserRole(any()))
          .thenThrow(Exception('Error'));

      final result = await controller.toggleCoachRole(true);

      expect(result, isFalse);
      expect(controller.errorMessage, contains('切換角色失敗'));
    });
  });

  group('ProfileController.isProfileCompleted', () {
    test('userProfile 為 null 應該返回 false', () {
      expect(controller.isProfileCompleted(), isFalse);
    });

    test('資料完整應該返回 true', () async {
      await controller.loadUserProfile();

      expect(controller.isProfileCompleted(), isTrue);
    });

    test('缺少必填欄位應該返回 false', () async {
      final incompleteUser = UserModel(
        uid: 'user-001',
        email: 'test@example.com',
        displayName: '', // 空的 displayName
      );

      when(() => mockUserService.getCurrentUserProfile())
          .thenAnswer((_) async => incompleteUser);

      await controller.loadUserProfile();

      expect(controller.isProfileCompleted(), isFalse);
    });
  });

  group('ProfileController Auth 屬性', () {
    test('isOAuthUser 應該委託給 AuthService', () {
      when(() => mockAuthService.isOAuthUser()).thenReturn(true);

      expect(controller.isOAuthUser, isTrue);
      verify(() => mockAuthService.isOAuthUser()).called(1);
    });

    test('hasPassword 應該委託給 AuthService', () {
      when(() => mockAuthService.hasPassword()).thenReturn(false);

      expect(controller.hasPassword, isFalse);
      verify(() => mockAuthService.hasPassword()).called(1);
    });

    test('userEmail 應該從 currentUser 獲取', () {
      expect(controller.userEmail, 'test@example.com');
    });
  });

  group('ProfileController.clearError', () {
    test('應該清除錯誤訊息', () async {
      when(() => mockUserService.getCurrentUserProfile())
          .thenThrow(Exception('Error'));

      await controller.loadUserProfile();
      expect(controller.errorMessage, isNotNull);

      controller.clearError();
      expect(controller.errorMessage, isNull);
    });
  });
}
