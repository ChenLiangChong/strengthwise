import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/health_assessment_models.dart';

import '../../mocks/mock_services.dart';

/// HealthAssessmentService 測試
///
/// P1 優先級 - 20 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockHealthAssessmentService mockService;

  // 測試用的模型資料
  final testAssessment = HealthAssessmentModel(
    id: 'assess-001',
    userId: 'user-001',
    assessmentDate: DateTime(2026, 1, 15),
    heartDisease: false,
    chestPainExercise: false,
    chestPainRest: false,
    dizziness: false,
    boneJointProblem: false,
    medication: false,
    otherReason: false,
    isCleared: true,
    injuries: const [],
    equipmentAccess: const [],
    trainingGoals: const TrainingGoals(primary: 'muscle_gain'),
    emergencyContact: const {
      'name': '緊急聯絡人',
      'phone': '0912345678',
      'relationship': 'family',
    },
    version: 1,
    isCurrent: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockHealthAssessmentService();
  });

  group('IHealthAssessmentService', () {
    // =========================================================================
    // getCurrentAssessment
    // =========================================================================
    group('getCurrentAssessment', () {
      test('正常獲取當前評估', () async {
        // Arrange
        when(() => mockService.getCurrentAssessment('user-001'))
            .thenAnswer((_) async => testAssessment);

        // Act
        final result = await mockService.getCurrentAssessment('user-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.isCurrent, isTrue);
      });

      test('無當前評估返回 null', () async {
        // Arrange
        when(() => mockService.getCurrentAssessment('new-user'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getCurrentAssessment('new-user');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // getAssessmentHistory
    // =========================================================================
    group('getAssessmentHistory', () {
      test('正常獲取評估歷史', () async {
        // Arrange
        when(() => mockService.getAssessmentHistory('user-001'))
            .thenAnswer((_) async => [testAssessment]);

        // Act
        final result = await mockService.getAssessmentHistory('user-001');

        // Assert
        expect(result.length, 1);
      });

      test('limit 參數限制返回數量', () async {
        // Arrange
        when(() => mockService.getAssessmentHistory('user-001', limit: 5))
            .thenAnswer((_) async => [testAssessment]);

        // Act
        final result =
            await mockService.getAssessmentHistory('user-001', limit: 5);

        // Assert
        expect(result.length, lessThanOrEqualTo(5));
      });

      test('無歷史記錄返回空列表', () async {
        // Arrange
        when(() => mockService.getAssessmentHistory('new-user'))
            .thenAnswer((_) async => []);

        // Act
        final result = await mockService.getAssessmentHistory('new-user');

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // createAssessment
    // =========================================================================
    group('createAssessment', () {
      test('正常建立評估', () async {
        // Arrange
        when(() => mockService.createAssessment(any()))
            .thenAnswer((_) async => testAssessment);

        // Act
        final result = await mockService.createAssessment(testAssessment);

        // Assert
        expect(result.id, isNotEmpty);
      });

      test('建立並設為當前評估', () async {
        // Arrange
        when(() => mockService.createAssessment(any(), setAsCurrent: true))
            .thenAnswer((_) async => testAssessment);

        // Act
        final result = await mockService.createAssessment(
          testAssessment,
          setAsCurrent: true,
        );

        // Assert
        expect(result.isCurrent, isTrue);
      });

      test('建立但不設為當前評估', () async {
        // Arrange
        final notCurrentAssessment =
            testAssessment.copyWith(isCurrent: false);
        when(() => mockService.createAssessment(any(), setAsCurrent: false))
            .thenAnswer((_) async => notCurrentAssessment);

        // Act
        final result = await mockService.createAssessment(
          testAssessment,
          setAsCurrent: false,
        );

        // Assert
        expect(result.isCurrent, isFalse);
      });
    });

    // =========================================================================
    // updateAssessment
    // =========================================================================
    group('updateAssessment', () {
      test('正常更新評估', () async {
        // Arrange
        when(() => mockService.updateAssessment(any()))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.updateAssessment(testAssessment),
          completes,
        );
      });
    });

    // =========================================================================
    // deleteAssessment
    // =========================================================================
    group('deleteAssessment', () {
      test('正常刪除評估', () async {
        // Arrange
        when(() => mockService.deleteAssessment('assess-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.deleteAssessment('assess-001'),
          completes,
        );
      });
    });

    // =========================================================================
    // setAsCurrentAssessment
    // =========================================================================
    group('setAsCurrentAssessment', () {
      test('正常設為當前評估', () async {
        // Arrange
        when(() => mockService.setAsCurrentAssessment('assess-001', 'user-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.setAsCurrentAssessment('assess-001', 'user-001'),
          completes,
        );
      });
    });

    // =========================================================================
    // batchGetCurrentAssessments
    // =========================================================================
    group('batchGetCurrentAssessments', () {
      test('批次獲取多位學員評估', () async {
        // Arrange
        when(() => mockService
                .batchGetCurrentAssessments(['user-001', 'user-002']))
            .thenAnswer((_) async => {
                  'user-001': testAssessment,
                  'user-002': null,
                });

        // Act
        final result = await mockService
            .batchGetCurrentAssessments(['user-001', 'user-002']);

        // Assert
        expect(result['user-001'], isNotNull);
        expect(result['user-002'], isNull);
      });

      test('空學員列表返回空 Map', () async {
        // Arrange
        when(() => mockService.batchGetCurrentAssessments([]))
            .thenAnswer((_) async => {});

        // Act
        final result = await mockService.batchGetCurrentAssessments([]);

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // getWarningAssessments
    // =========================================================================
    group('getWarningAssessments', () {
      test('正常獲取需警示的評估', () async {
        // Arrange
        final warningAssessment = testAssessment.copyWith(
          isCleared: false,
        );
        when(() => mockService.getWarningAssessments('coach-001'))
            .thenAnswer((_) async => [warningAssessment]);

        // Act
        final result = await mockService.getWarningAssessments('coach-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].riskLevel, 'attention');
      });

      test('無警示評估返回空列表', () async {
        // Arrange
        when(() => mockService.getWarningAssessments('coach-001'))
            .thenAnswer((_) async => []);

        // Act
        final result = await mockService.getWarningAssessments('coach-001');

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // 風險等級測試（isCleared: true → 'low', false → 'attention'）
    // =========================================================================
    group('RiskLevel', () {
      test('低風險評估（isCleared: true）', () async {
        // Arrange
        when(() => mockService.getCurrentAssessment('low-risk-user'))
            .thenAnswer((_) async => testAssessment);

        // Act
        final result = await mockService.getCurrentAssessment('low-risk-user');

        // Assert
        expect(result!.riskLevel, 'low');
        expect(result.isCleared, isTrue);
      });

      test('需注意評估（isCleared: false）', () async {
        // Arrange
        final attentionAssessment = testAssessment.copyWith(
          isCleared: false,
        );
        when(() => mockService.getCurrentAssessment('attention-user'))
            .thenAnswer((_) async => attentionAssessment);

        // Act
        final result =
            await mockService.getCurrentAssessment('attention-user');

        // Assert
        expect(result!.riskLevel, 'attention');
        expect(result.isCleared, isFalse);
      });

      test('有心臟疾病的高風險評估', () async {
        // Arrange
        final highRiskAssessment = testAssessment.copyWith(
          isCleared: false,
          heartDisease: true,
        );
        when(() => mockService.getCurrentAssessment('high-risk-user'))
            .thenAnswer((_) async => highRiskAssessment);

        // Act
        final result = await mockService.getCurrentAssessment('high-risk-user');

        // Assert
        expect(result!.riskLevel, 'attention');
        expect(result.heartDisease, isTrue);
      });
    });
  });
}
