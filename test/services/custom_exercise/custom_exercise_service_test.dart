import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/custom_exercise_model.dart';

import '../../mocks/mock_services.dart';

/// CustomExerciseService 測試
///
/// P2 優先級 - 10 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockCustomExerciseService mockService;

  // 測試用的模型資料
  final testExercise = CustomExercise(
    id: 'custom-001',
    name: '自訂深蹲',
    userId: 'user-001',
    trainingType: '阻力訓練',
    bodyPart: '腿部',
    equipment: '槓鈴',
    description: '自訂的深蹲變化動作',
    notes: '注意膝蓋不要內夾',
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockCustomExerciseService();
  });

  group('ICustomExerciseService', () {
    // =========================================================================
    // getUserCustomExercises
    // =========================================================================
    group('getUserCustomExercises', () {
      test('正常獲取用戶自訂動作', () async {
        // Arrange
        when(() => mockService.getUserCustomExercises())
            .thenAnswer((_) async => [testExercise]);

        // Act
        final result = await mockService.getUserCustomExercises();

        // Assert
        expect(result.length, 1);
        expect(result[0].name, '自訂深蹲');
      });

      test('無自訂動作返回空列表', () async {
        // Arrange
        when(() => mockService.getUserCustomExercises())
            .thenAnswer((_) async => []);

        // Act
        final result = await mockService.getUserCustomExercises();

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // addCustomExercise
    // =========================================================================
    group('addCustomExercise', () {
      test('正常新增自訂動作', () async {
        // Arrange
        when(() => mockService.addCustomExercise(
              name: any(named: 'name'),
              trainingType: any(named: 'trainingType'),
              bodyPart: any(named: 'bodyPart'),
              equipment: any(named: 'equipment'),
              description: any(named: 'description'),
              notes: any(named: 'notes'),
              trackingMode: any(named: 'trackingMode'),
            )).thenAnswer((_) async => testExercise);

        // Act
        final result = await mockService.addCustomExercise(
          name: '新動作',
          trainingType: '阻力訓練',
          bodyPart: '胸部',
        );

        // Assert
        expect(result.id, isNotEmpty);
      });
    });

    // =========================================================================
    // updateCustomExercise
    // =========================================================================
    group('updateCustomExercise', () {
      test('正常更新自訂動作', () async {
        // Arrange
        when(() => mockService.updateCustomExercise(
              exerciseId: 'custom-001',
              name: any(named: 'name'),
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.updateCustomExercise(
            exerciseId: 'custom-001',
            name: '更新後名稱',
          ),
          completes,
        );
      });
    });

    // =========================================================================
    // deleteCustomExercise
    // =========================================================================
    group('deleteCustomExercise', () {
      test('正常刪除自訂動作', () async {
        // Arrange
        when(() => mockService.deleteCustomExercise('custom-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.deleteCustomExercise('custom-001'),
          completes,
        );
      });
    });

    // =========================================================================
    // isCoachCustomExercise
    // =========================================================================
    group('isCoachCustomExercise', () {
      test('是教練自訂動作返回 true', () async {
        // Arrange
        when(() => mockService.isCoachCustomExercise('coach-exercise-001'))
            .thenAnswer((_) async => true);

        // Act
        final result =
            await mockService.isCoachCustomExercise('coach-exercise-001');

        // Assert
        expect(result, isTrue);
      });

      test('非教練自訂動作返回 false', () async {
        // Arrange
        when(() => mockService.isCoachCustomExercise('system-exercise'))
            .thenAnswer((_) async => false);

        // Act
        final result =
            await mockService.isCoachCustomExercise('system-exercise');

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // copyToMyExercises
    // =========================================================================
    group('copyToMyExercises', () {
      test('正常複製動作到我的動作庫', () async {
        // Arrange
        when(() => mockService.copyToMyExercises(
              name: any(named: 'name'),
              trainingType: any(named: 'trainingType'),
              bodyPart: any(named: 'bodyPart'),
              equipment: any(named: 'equipment'),
              trackingMode: any(named: 'trackingMode'),
              description: any(named: 'description'),
              notes: any(named: 'notes'),
            )).thenAnswer((_) async => testExercise);

        // Act
        final result = await mockService.copyToMyExercises(
          name: '複製的動作',
          trainingType: '阻力訓練',
          bodyPart: '背部',
        );

        // Assert
        expect(result.id, isNotEmpty);
      });
    });

    // =========================================================================
    // getTrainingRecordCount
    // =========================================================================
    group('getTrainingRecordCount', () {
      test('有記錄返回數量', () async {
        // Arrange
        when(() => mockService.getTrainingRecordCount('custom-001'))
            .thenAnswer((_) async => 15);

        // Act
        final result = await mockService.getTrainingRecordCount('custom-001');

        // Assert
        expect(result, 15);
      });

      test('無記錄返回 0', () async {
        // Arrange
        when(() => mockService.getTrainingRecordCount('new-exercise'))
            .thenAnswer((_) async => 0);

        // Act
        final result =
            await mockService.getTrainingRecordCount('new-exercise');

        // Assert
        expect(result, 0);
      });
    });
  });
}
