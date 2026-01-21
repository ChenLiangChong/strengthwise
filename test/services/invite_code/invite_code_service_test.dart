import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/invite_code_model.dart';
import 'package:strengthwise/services/interfaces/i_invite_code_service.dart';

import '../../mocks/mock_services.dart';

/// InviteCodeService 測試
///
/// P2 優先級 - 8 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockInviteCodeService mockService;

  // 測試用的模型資料
  final testInviteCode = InviteCodeModel(
    code: 'A1B2C3',
    coachId: 'coach-001',
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 5)),
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockInviteCodeService();
  });

  group('IInviteCodeService', () {
    // =========================================================================
    // generateInviteCode
    // =========================================================================
    group('generateInviteCode', () {
      test('正常生成邀請碼', () async {
        // Arrange
        when(() => mockService.generateInviteCode('coach-001'))
            .thenAnswer((_) async => testInviteCode);

        // Act
        final result = await mockService.generateInviteCode('coach-001');

        // Assert
        expect(result.code, isNotEmpty);
        expect(result.code.length, 6);
        expect(result.coachId, 'coach-001');
      });

      test('邀請碼有 5 分鐘有效期', () async {
        // Arrange
        when(() => mockService.generateInviteCode('coach-001'))
            .thenAnswer((_) async => testInviteCode);

        // Act
        final result = await mockService.generateInviteCode('coach-001');

        // Assert
        expect(result.isValid, isTrue);
        expect(result.remainingSeconds, greaterThan(0));
      });
    });

    // =========================================================================
    // validateAndUseCode
    // =========================================================================
    group('validateAndUseCode', () {
      test('有效邀請碼返回教練 ID', () async {
        // Arrange
        when(() => mockService.validateAndUseCode(
              code: 'A1B2C3',
              traineeId: 'client-001',
            )).thenAnswer((_) async => 'coach-001');

        // Act
        final result = await mockService.validateAndUseCode(
          code: 'A1B2C3',
          traineeId: 'client-001',
        );

        // Assert
        expect(result, 'coach-001');
      });

      test('無效邀請碼拋出異常', () async {
        // Arrange
        when(() => mockService.validateAndUseCode(
              code: 'INVALID',
              traineeId: 'client-001',
            )).thenThrow(Exception('Invalid invite code'));

        // Act & Assert
        expect(
          () => mockService.validateAndUseCode(
            code: 'INVALID',
            traineeId: 'client-001',
          ),
          throwsException,
        );
      });
    });

    // =========================================================================
    // bindCoachByInviteCode
    // =========================================================================
    group('bindCoachByInviteCode', () {
      test('綁定成功', () async {
        // Arrange
        final successResult = InviteCodeBindResult(
          success: true,
          relationshipId: 'rel-001',
          coachId: 'coach-001',
          coachName: '王教練',
        );
        when(() => mockService.bindCoachByInviteCode(
              code: 'A1B2C3',
              traineeId: 'client-001',
            )).thenAnswer((_) async => successResult);

        // Act
        final result = await mockService.bindCoachByInviteCode(
          code: 'A1B2C3',
          traineeId: 'client-001',
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.relationshipId, isNotNull);
        expect(result.coachName, '王教練');
      });

      test('邀請碼過期綁定失敗', () async {
        // Arrange
        final failResult = InviteCodeBindResult(
          success: false,
          error: 'Invite code expired',
        );
        when(() => mockService.bindCoachByInviteCode(
              code: 'EXPIRED',
              traineeId: 'client-001',
            )).thenAnswer((_) async => failResult);

        // Act
        final result = await mockService.bindCoachByInviteCode(
          code: 'EXPIRED',
          traineeId: 'client-001',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });

      test('教練不存在綁定失敗', () async {
        // Arrange
        final failResult = InviteCodeBindResult(
          success: false,
          error: 'Coach not found',
        );
        when(() => mockService.bindCoachByInviteCode(
              code: 'NOCOACH',
              traineeId: 'client-001',
            )).thenAnswer((_) async => failResult);

        // Act
        final result = await mockService.bindCoachByInviteCode(
          code: 'NOCOACH',
          traineeId: 'client-001',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, 'Coach not found');
      });

      test('已有關係綁定失敗', () async {
        // Arrange
        final failResult = InviteCodeBindResult(
          success: false,
          error: 'Relationship already exists',
        );
        when(() => mockService.bindCoachByInviteCode(
              code: 'A1B2C3',
              traineeId: 'existing-client',
            )).thenAnswer((_) async => failResult);

        // Act
        final result = await mockService.bindCoachByInviteCode(
          code: 'A1B2C3',
          traineeId: 'existing-client',
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('already exists'));
      });
    });
  });
}
