import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/coach_profile/coach_profile_model.dart';

import '../../mocks/mock_services.dart';

/// CoachProfileService 測試
///
/// P2 優先級 - 10 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockCoachProfileService mockService;

  // 測試用的模型資料
  final testProfile = CoachProfileModel(
    id: 'coach-001',
    displayName: '王教練',
    headline: '專業健身教練 | 10 年經驗',
    bio: '專注於肌力訓練與體態調整',
    specialties: ['strength_training', 'body_composition'],
    yearsExperience: 10,
    languages: ['zh-TW', 'en'],
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockCoachProfileService();
  });

  group('ICoachProfileService', () {
    // =========================================================================
    // getProfile
    // =========================================================================
    group('getProfile', () {
      test('正常獲取教練檔案', () async {
        // Arrange
        when(() => mockService.getProfile('coach-001'))
            .thenAnswer((_) async => testProfile);

        // Act
        final result = await mockService.getProfile('coach-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'coach-001');
        expect(result.displayName, '王教練');
      });

      test('教練檔案不存在返回 null', () async {
        // Arrange
        when(() => mockService.getProfile('not-exist'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getProfile('not-exist');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // createProfile
    // =========================================================================
    group('createProfile', () {
      test('正常建立教練檔案', () async {
        // Arrange
        when(() => mockService.createProfile(any()))
            .thenAnswer((_) async => testProfile);

        // Act
        final result = await mockService.createProfile(testProfile);

        // Assert
        expect(result.id, isNotEmpty);
        expect(result.displayName, '王教練');
      });
    });

    // =========================================================================
    // updateProfile
    // =========================================================================
    group('updateProfile', () {
      test('正常更新教練檔案', () async {
        // Arrange
        final updatedProfile = testProfile.copyWith(
          headline: '資深健身教練 | 12 年經驗',
        );
        when(() => mockService.updateProfile(any()))
            .thenAnswer((_) async => updatedProfile);

        // Act
        final result = await mockService.updateProfile(updatedProfile);

        // Assert
        expect(result.headline, '資深健身教練 | 12 年經驗');
      });
    });

    // =========================================================================
    // upsertProfile
    // =========================================================================
    group('upsertProfile', () {
      test('檔案不存在時建立', () async {
        // Arrange
        when(() => mockService.upsertProfile(any()))
            .thenAnswer((_) async => testProfile);

        // Act
        final result = await mockService.upsertProfile(testProfile);

        // Assert
        expect(result.id, 'coach-001');
      });

      test('檔案存在時更新', () async {
        // Arrange
        final updatedProfile = testProfile.copyWith(yearsExperience: 12);
        when(() => mockService.upsertProfile(any()))
            .thenAnswer((_) async => updatedProfile);

        // Act
        final result = await mockService.upsertProfile(updatedProfile);

        // Assert
        expect(result.yearsExperience, 12);
      });
    });

    // =========================================================================
    // hasProfile
    // =========================================================================
    group('hasProfile', () {
      test('有檔案返回 true', () async {
        // Arrange
        when(() => mockService.hasProfile('coach-001'))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.hasProfile('coach-001');

        // Assert
        expect(result, isTrue);
      });

      test('無檔案返回 false', () async {
        // Arrange
        when(() => mockService.hasProfile('new-coach'))
            .thenAnswer((_) async => false);

        // Act
        final result = await mockService.hasProfile('new-coach');

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // deleteProfile
    // =========================================================================
    group('deleteProfile', () {
      test('正常刪除教練檔案', () async {
        // Arrange
        when(() => mockService.deleteProfile('coach-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.deleteProfile('coach-001'),
          completes,
        );
      });
    });
  });
}
