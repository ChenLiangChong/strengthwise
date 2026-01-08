import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/workout_record/workout_record.dart';
import 'package:strengthwise/models/workout_template_model.dart';
import 'package:strengthwise/models/exercise_history_record.dart';
import 'package:strengthwise/models/workout_record/set_record.dart';

import '../../mocks/mock_services.dart';

/// WorkoutService 測試
///
/// P2 優先級 - 10 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md #P2
void main() {
  late MockWorkoutService mockService;

  // 測試用的模型資料
  final testRecord = WorkoutRecord(
    id: 'record-001',
    workoutPlanId: 'plan-001',
    userId: 'user-001',
    title: '上肢訓練',
    date: DateTime(2025, 12, 15),
    exerciseRecords: [],
    createdAt: DateTime.now(),
  );

  final testTemplate = WorkoutTemplate(
    id: 'template-001',
    userId: 'user-001',
    title: '推拉腿模板',
    description: '三分化訓練',
    planType: 'push',
    exercises: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    // 註冊 WorkoutRecord fallback
    registerFallbackValue(WorkoutRecord(
      id: 'fallback',
      workoutPlanId: 'fallback',
      userId: 'fallback',
      title: 'fallback',
      date: DateTime.now(),
      exerciseRecords: [],
      createdAt: DateTime.now(),
    ));

    // 註冊 WorkoutTemplate fallback
    registerFallbackValue(WorkoutTemplate(
      id: 'fallback',
      userId: 'fallback',
      title: 'fallback',
      description: '',
      planType: 'custom',
      exercises: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  setUp(() {
    mockService = MockWorkoutService();
  });

  group('IWorkoutService', () {
    // =========================================================================
    // P2-159: getUserPlans
    // =========================================================================
    group('getUserPlans', () {
      test('返回用戶訓練計劃', () async {
        // Arrange
        when(() => mockService.getUserPlans())
            .thenAnswer((_) async => [testRecord]);

        // Act
        final result = await mockService.getUserPlans();

        // Assert
        expect(result.length, 1);
        expect(result[0].id, 'record-001');
      });

      test('可按完成狀態篩選', () async {
        // Arrange
        when(() => mockService.getUserPlans(completed: true))
            .thenAnswer((_) async => []);

        // Act
        final result = await mockService.getUserPlans(completed: true);

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // P2-160: getRecordById
    // =========================================================================
    group('getRecordById', () {
      test('找到記錄時返回 Model', () async {
        // Arrange
        when(() => mockService.getRecordById('record-001'))
            .thenAnswer((_) async => testRecord);

        // Act
        final result = await mockService.getRecordById('record-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'record-001');
      });
    });

    // =========================================================================
    // P2-161: getRecordByAppointmentId
    // =========================================================================
    group('getRecordByAppointmentId', () {
      test('找到預約關聯的訓練記錄', () async {
        // Arrange
        when(() => mockService.getRecordByAppointmentId('apt-001'))
            .thenAnswer((_) async => testRecord);

        // Act
        final result = await mockService.getRecordByAppointmentId('apt-001');

        // Assert
        expect(result, isNotNull);
      });
    });

    // =========================================================================
    // P2-162: createRecord
    // =========================================================================
    group('createRecord', () {
      test('建立訓練記錄', () async {
        // Arrange
        when(() => mockService.createRecord(any()))
            .thenAnswer((_) async => testRecord);

        // Act
        final result = await mockService.createRecord(testRecord);

        // Assert
        expect(result.id, 'record-001');
      });
    });

    // =========================================================================
    // P2-163: updateRecord
    // =========================================================================
    group('updateRecord', () {
      test('更新訓練記錄成功', () async {
        // Arrange
        when(() => mockService.updateRecord(any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.updateRecord(testRecord);

        // Assert
        expect(result, isTrue);
      });
    });

    // =========================================================================
    // P2-164: deleteRecord
    // =========================================================================
    group('deleteRecord', () {
      test('刪除訓練記錄成功', () async {
        // Arrange
        when(() => mockService.deleteRecord('record-001'))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.deleteRecord('record-001');

        // Assert
        expect(result, isTrue);
      });
    });

    // =========================================================================
    // P2-165: checkTimeOverlap
    // =========================================================================
    group('checkTimeOverlap', () {
      test('無重疊返回空列表', () async {
        // Arrange
        when(() => mockService.checkTimeOverlap(
              traineeId: 'user-001',
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
            )).thenAnswer((_) async => []);

        // Act
        final result = await mockService.checkTimeOverlap(
          traineeId: 'user-001',
          startTime: DateTime(2025, 12, 15, 10, 0),
          endTime: DateTime(2025, 12, 15, 11, 0),
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // P2-166: getExerciseHistory
    // =========================================================================
    group('getExerciseHistory', () {
      test('返回動作歷史記錄', () async {
        // Arrange
        final history = ExerciseHistoryRecord(
          workoutRecordId: 'record-001',
          exerciseId: 'ex-001',
          exerciseName: '槓鈴臥推',
          trainingDate: DateTime(2025, 12, 10),
          sets: [
            SetRecord(setNumber: 1, reps: 8, weight: 60.0, restTime: 90),
          ],
        );
        when(() => mockService.getExerciseHistory(
              userId: 'user-001',
              exerciseId: 'ex-001',
            )).thenAnswer((_) async => [history]);

        // Act
        final result = await mockService.getExerciseHistory(
          userId: 'user-001',
          exerciseId: 'ex-001',
        );

        // Assert
        expect(result.length, 1);
        expect(result[0].exerciseName, '槓鈴臥推');
      });
    });

    // =========================================================================
    // Template 測試
    // =========================================================================
    group('Template Operations', () {
      test('getUserTemplates 返回模板列表', () async {
        // Arrange
        when(() => mockService.getUserTemplates())
            .thenAnswer((_) async => [testTemplate]);

        // Act
        final result = await mockService.getUserTemplates();

        // Assert
        expect(result.length, 1);
      });

      test('createTemplate 建立模板', () async {
        // Arrange
        when(() => mockService.createTemplate(any()))
            .thenAnswer((_) async => testTemplate);

        // Act
        final result = await mockService.createTemplate(testTemplate);

        // Assert
        expect(result.id, 'template-001');
      });
    });
  });
}
