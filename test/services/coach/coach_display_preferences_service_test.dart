import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/coach_display_preferences_model.dart';

import '../../mocks/mock_services.dart';

/// CoachDisplayPreferencesService 測試
///
/// P3 優先級 - 5 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockCoachDisplayPreferencesService mockService;

  // 測試用的模型資料
  final testPreferences = CoachDisplayPreferencesModel(
    coachId: 'coach-001',
    healthAssessmentFields: ['safety_screening', 'injuries', 'training_goals'],
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockCoachDisplayPreferencesService();
  });

  group('ICoachDisplayPreferencesService', () {
    // =========================================================================
    // getPreferences
    // =========================================================================
    group('getPreferences', () {
      test('正常獲取顯示偏好', () async {
        // Arrange
        when(() => mockService.getPreferences('coach-001'))
            .thenAnswer((_) async => testPreferences);

        // Act
        final result = await mockService.getPreferences('coach-001');

        // Assert
        expect(result.coachId, 'coach-001');
        expect(result.healthAssessmentFields.length, 3);
      });

      test('不存在時返回預設偏好', () async {
        // Arrange
        final defaultPreferences =
            CoachDisplayPreferencesModel.createDefault('new-coach');
        when(() => mockService.getPreferences('new-coach'))
            .thenAnswer((_) async => defaultPreferences);

        // Act
        final result = await mockService.getPreferences('new-coach');

        // Assert
        expect(result.healthAssessmentFields,
            CoachDisplayPreferencesModel.defaultFields);
      });
    });

    // =========================================================================
    // updatePreferences
    // =========================================================================
    group('updatePreferences', () {
      test('正常更新顯示偏好', () async {
        // Arrange
        when(() => mockService.updatePreferences(any()))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.updatePreferences(testPreferences),
          completes,
        );
      });
    });

    // =========================================================================
    // resetToDefault
    // =========================================================================
    group('resetToDefault', () {
      test('正常重置為預設偏好', () async {
        // Arrange
        when(() => mockService.resetToDefault('coach-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.resetToDefault('coach-001'),
          completes,
        );
      });
    });
  });
}
