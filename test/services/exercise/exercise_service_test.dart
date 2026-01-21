import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/exercise_model.dart';
import 'package:strengthwise/models/tracking_mode.dart';

import '../../mocks/mock_services.dart';

/// ExerciseService 測試
///
/// P1 優先級 - 15 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockExerciseService mockService;

  // 測試用的模型資料
  final testExercise = Exercise(
    id: 'ex-001',
    name: '槓鈴臥推',
    nameEn: 'Barbell Bench Press',
    bodyParts: ['chest'],
    type: 'strength',
    equipment: 'barbell',
    jointType: 'compound',
    level1: '重訓',
    level2: '胸',
    level3: '胸大肌',
    level4: '自由重量',
    level5: '槓鈴',
    trainingType: '重訓',
    bodyPart: '胸',
    specificMuscle: '胸大肌',
    equipmentCategory: '自由重量',
    equipmentSubcategory: '槓鈴',
    description: '經典複合動作',
    videoUrl: '',
    apps: ['strengthwise'],
    createdAt: DateTime.now(),
    trackingMode: TrackingMode.weightReps,
  );

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockExerciseService();
  });

  group('IExerciseService', () {
    // =========================================================================
    // getExerciseTypes
    // =========================================================================
    group('getExerciseTypes', () {
      test('正常獲取訓練類型列表', () async {
        // Arrange
        when(() => mockService.getExerciseTypes())
            .thenAnswer((_) async => ['重訓', '有氧', '伸展', '功能性訓練']);

        // Act
        final result = await mockService.getExerciseTypes();

        // Assert
        expect(result.length, 4);
        expect(result, contains('重訓'));
      });
    });

    // =========================================================================
    // getBodyParts
    // =========================================================================
    group('getBodyParts', () {
      test('正常獲取身體部位列表', () async {
        // Arrange
        when(() => mockService.getBodyParts())
            .thenAnswer((_) async => ['胸', '背', '腿', '肩', '手臂', '核心']);

        // Act
        final result = await mockService.getBodyParts();

        // Assert
        expect(result.length, 6);
        expect(result, contains('胸'));
      });
    });

    // =========================================================================
    // getCategoriesByLevel
    // =========================================================================
    group('getCategoriesByLevel', () {
      test('正常獲取指定層級分類', () async {
        // Arrange
        when(() => mockService.getCategoriesByLevel(2, {'level1': '重訓'}))
            .thenAnswer((_) async => ['胸', '背', '腿']);

        // Act
        final result = await mockService.getCategoriesByLevel(
          2,
          {'level1': '重訓'},
        );

        // Assert
        expect(result, contains('胸'));
      });

      test('空篩選條件返回所有分類', () async {
        // Arrange
        when(() => mockService.getCategoriesByLevel(1, {}))
            .thenAnswer((_) async => ['重訓', '有氧', '伸展']);

        // Act
        final result = await mockService.getCategoriesByLevel(1, {});

        // Assert
        expect(result.length, 3);
      });
    });

    // =========================================================================
    // getExercisesByFilters
    // =========================================================================
    group('getExercisesByFilters', () {
      test('正常根據篩選條件獲取運動', () async {
        // Arrange
        when(() => mockService.getExercisesByFilters({'bodyPart': '胸'}))
            .thenAnswer((_) async => [testExercise]);

        // Act
        final result = await mockService.getExercisesByFilters({'bodyPart': '胸'});

        // Assert
        expect(result.length, 1);
        expect(result[0].bodyPart, '胸');
      });

      test('多個篩選條件', () async {
        // Arrange
        when(() => mockService.getExercisesByFilters({
              'trainingType': '重訓',
              'bodyPart': '胸',
              'equipmentCategory': '自由重量',
            })).thenAnswer((_) async => [testExercise]);

        // Act
        final result = await mockService.getExercisesByFilters({
          'trainingType': '重訓',
          'bodyPart': '胸',
          'equipmentCategory': '自由重量',
        });

        // Assert
        expect(result, isNotEmpty);
      });

      test('無符合條件返回空列表', () async {
        // Arrange
        when(() => mockService.getExercisesByFilters({'bodyPart': '不存在'}))
            .thenAnswer((_) async => []);

        // Act
        final result =
            await mockService.getExercisesByFilters({'bodyPart': '不存在'});

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // getExerciseById
    // =========================================================================
    group('getExerciseById', () {
      test('正常獲取運動詳情', () async {
        // Arrange
        when(() => mockService.getExerciseById('ex-001'))
            .thenAnswer((_) async => testExercise);

        // Act
        final result = await mockService.getExerciseById('ex-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'ex-001');
        expect(result.name, '槓鈴臥推');
      });

      test('運動不存在返回 null', () async {
        // Arrange
        when(() => mockService.getExerciseById('not-exist'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getExerciseById('not-exist');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // getExercisesByIds
    // =========================================================================
    group('getExercisesByIds', () {
      test('批量獲取多個運動', () async {
        // Arrange
        when(() => mockService.getExercisesByIds(['ex-001', 'ex-002']))
            .thenAnswer((_) async => {'ex-001': testExercise});

        // Act
        final result =
            await mockService.getExercisesByIds(['ex-001', 'ex-002']);

        // Assert
        expect(result['ex-001'], isNotNull);
        expect(result['ex-001']!.name, '槓鈴臥推');
      });

      test('空 ID 列表返回空 Map', () async {
        // Arrange
        when(() => mockService.getExercisesByIds([]))
            .thenAnswer((_) async => {});

        // Act
        final result = await mockService.getExercisesByIds([]);

        // Assert
        expect(result, isEmpty);
      });

      test('部分 ID 不存在', () async {
        // Arrange
        when(() => mockService.getExercisesByIds(['ex-001', 'not-exist']))
            .thenAnswer((_) async => {'ex-001': testExercise});

        // Act
        final result =
            await mockService.getExercisesByIds(['ex-001', 'not-exist']);

        // Assert
        expect(result.length, 1);
        expect(result.containsKey('not-exist'), isFalse);
      });
    });

    // =========================================================================
    // searchExercises
    // =========================================================================
    group('searchExercises', () {
      test('正常搜尋運動', () async {
        // Arrange
        when(() => mockService.searchExercises('臥推'))
            .thenAnswer((_) async => [testExercise]);

        // Act
        final result = await mockService.searchExercises('臥推');

        // Assert
        expect(result.length, 1);
        expect(result[0].name, contains('臥推'));
      });

      test('limit 參數限制結果數量', () async {
        // Arrange
        when(() => mockService.searchExercises('訓練', limit: 5))
            .thenAnswer((_) async => [testExercise]);

        // Act
        final result = await mockService.searchExercises('訓練', limit: 5);

        // Assert
        expect(result.length, lessThanOrEqualTo(5));
      });

      test('無符合搜尋結果返回空列表', () async {
        // Arrange
        when(() => mockService.searchExercises('不存在的動作'))
            .thenAnswer((_) async => []);

        // Act
        final result = await mockService.searchExercises('不存在的動作');

        // Assert
        expect(result, isEmpty);
      });
    });
  });
}
