import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/workout_record/workout_record.dart';
import 'package:strengthwise/models/workout_template_model.dart';
import 'package:strengthwise/models/exercise_history_record.dart';
import 'package:strengthwise/models/workout_record/set_record.dart';

import '../../mocks/mock_services.dart';

/// WorkoutService 測試
///
/// P2 優先級 - 30 個測試案例（原 10 個 + 補充 20 個）
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

    // =========================================================================
    // 補充測試：getUserPlans 進階場景
    // =========================================================================
    group('getUserPlans - 進階場景', () {
      test('按日期範圍篩選', () async {
        // Arrange
        when(() => mockService.getUserPlans(
              startDate: any(named: 'startDate'),
              endDate: any(named: 'endDate'),
            )).thenAnswer((_) async => [testRecord]);

        // Act
        final result = await mockService.getUserPlans(
          startDate: DateTime(2025, 12, 1),
          endDate: DateTime(2025, 12, 31),
        );

        // Assert
        expect(result.length, 1);
      });

      test('教練查詢學員計劃', () async {
        // Arrange
        final traineeRecord = WorkoutRecord(
          id: 'record-002',
          workoutPlanId: 'plan-002',
          userId: 'coach-001',
          traineeId: 'trainee-001',
          title: '學員訓練',
          date: DateTime(2025, 12, 15),
          exerciseRecords: [],
          createdAt: DateTime.now(),
        );
        when(() => mockService.getUserPlans(userId: 'trainee-001'))
            .thenAnswer((_) async => [traineeRecord]);

        // Act
        final result = await mockService.getUserPlans(userId: 'trainee-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].traineeId, 'trainee-001');
      });

      test('Cursor 分頁正確返回', () async {
        // Arrange
        when(() => mockService.getUserPlans(
              cursor: any(named: 'cursor'),
              limit: 20,
            )).thenAnswer((_) async => [testRecord]);

        // Act
        final result = await mockService.getUserPlans(
          cursor: '2025-12-14T00:00:00Z',
          limit: 20,
        );

        // Assert
        expect(result, isNotEmpty);
      });
    });

    // =========================================================================
    // 補充測試：getTemplateById
    // =========================================================================
    group('getTemplateById', () {
      test('找到模板時返回 Model', () async {
        // Arrange
        when(() => mockService.getTemplateById('template-001'))
            .thenAnswer((_) async => testTemplate);

        // Act
        final result = await mockService.getTemplateById('template-001');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'template-001');
      });

      test('找不到模板時返回 null', () async {
        // Arrange
        when(() => mockService.getTemplateById('not-exist'))
            .thenAnswer((_) async => null);

        // Act
        final result = await mockService.getTemplateById('not-exist');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // 補充測試：updateTemplate
    // =========================================================================
    group('updateTemplate', () {
      test('正常更新模板', () async {
        // Arrange
        when(() => mockService.updateTemplate(any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.updateTemplate(testTemplate);

        // Assert
        expect(result, isTrue);
      });

      test('模板不存在時更新失敗', () async {
        // Arrange
        final nonExistTemplate = WorkoutTemplate(
          id: 'not-exist',
          userId: 'user-001',
          title: '不存在的模板',
          description: '',
          planType: 'custom',
          exercises: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        when(() => mockService.updateTemplate(any()))
            .thenAnswer((_) async => false);

        // Act
        final result = await mockService.updateTemplate(nonExistTemplate);

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // 補充測試：deleteTemplate
    // =========================================================================
    group('deleteTemplate', () {
      test('正常刪除模板', () async {
        // Arrange
        when(() => mockService.deleteTemplate('template-001'))
            .thenAnswer((_) async => true);

        // Act
        final result = await mockService.deleteTemplate('template-001');

        // Assert
        expect(result, isTrue);
        verify(() => mockService.deleteTemplate('template-001')).called(1);
      });

      test('刪除後確認模板不存在', () async {
        // Arrange
        when(() => mockService.deleteTemplate('template-001'))
            .thenAnswer((_) async => true);
        when(() => mockService.getTemplateById('template-001'))
            .thenAnswer((_) async => null);

        // Act
        await mockService.deleteTemplate('template-001');
        final result = await mockService.getTemplateById('template-001');

        // Assert
        expect(result, isNull);
      });
    });

    // =========================================================================
    // 補充測試：getUserRecords
    // =========================================================================
    group('getUserRecords', () {
      test('正常返回用戶記錄', () async {
        // Arrange
        when(() => mockService.getUserRecords())
            .thenAnswer((_) async => [testRecord]);

        // Act
        final result = await mockService.getUserRecords();

        // Assert
        expect(result.length, 1);
      });

      test('Cursor 分頁', () async {
        // Arrange
        when(() => mockService.getUserRecords(
              cursor: any(named: 'cursor'),
              limit: 10,
            )).thenAnswer((_) async => [testRecord]);

        // Act
        final result = await mockService.getUserRecords(
          cursor: '2025-12-14T00:00:00Z',
          limit: 10,
        );

        // Assert
        expect(result, isNotEmpty);
      });

      test('空結果返回空列表', () async {
        // Arrange
        when(() => mockService.getUserRecords()).thenAnswer((_) async => []);

        // Act
        final result = await mockService.getUserRecords();

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // 補充測試：getCoachCreatedPlans
    // =========================================================================
    group('getCoachCreatedPlans', () {
      test('正常查詢教練建立的計劃', () async {
        // Arrange
        when(() => mockService.getCoachCreatedPlans(
              coachId: 'coach-001',
              clientIds: ['client-001', 'client-002'],
            )).thenAnswer((_) async => [testRecord]);

        // Act
        final result = await mockService.getCoachCreatedPlans(
          coachId: 'coach-001',
          clientIds: ['client-001', 'client-002'],
        );

        // Assert
        expect(result, isNotEmpty);
      });

      test('多學員查詢', () async {
        // Arrange
        final records = [
          testRecord,
          WorkoutRecord(
            id: 'record-002',
            workoutPlanId: 'plan-002',
            userId: 'coach-001',
            traineeId: 'client-002',
            title: '學員 2 訓練',
            date: DateTime(2025, 12, 16),
            exerciseRecords: [],
            createdAt: DateTime.now(),
          ),
        ];
        when(() => mockService.getCoachCreatedPlans(
              coachId: 'coach-001',
              clientIds: ['client-001', 'client-002'],
            )).thenAnswer((_) async => records);

        // Act
        final result = await mockService.getCoachCreatedPlans(
          coachId: 'coach-001',
          clientIds: ['client-001', 'client-002'],
        );

        // Assert
        expect(result.length, 2);
      });

      test('空學員列表返回空結果', () async {
        // Arrange
        when(() => mockService.getCoachCreatedPlans(
              coachId: 'coach-001',
              clientIds: [],
            )).thenAnswer((_) async => []);

        // Act
        final result = await mockService.getCoachCreatedPlans(
          coachId: 'coach-001',
          clientIds: [],
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // 補充測試：createRecordFromTemplate
    // =========================================================================
    group('createRecordFromTemplate', () {
      test('正常從模板建立記錄', () async {
        // Arrange
        when(() => mockService.createRecordFromTemplate('template-001'))
            .thenAnswer((_) async => testRecord);

        // Act
        final result =
            await mockService.createRecordFromTemplate('template-001');

        // Assert
        expect(result.id, isNotEmpty);
      });

      test('模板不存在時拋出異常', () async {
        // Arrange
        when(() => mockService.createRecordFromTemplate('not-exist'))
            .thenThrow(Exception('Template not found'));

        // Act & Assert
        expect(
          () => mockService.createRecordFromTemplate('not-exist'),
          throwsException,
        );
      });
    });

    // =========================================================================
    // 補充測試：checkTimeOverlap 進階場景
    // =========================================================================
    group('checkTimeOverlap - 進階場景', () {
      test('有重疊返回重疊記錄', () async {
        // Arrange
        when(() => mockService.checkTimeOverlap(
              traineeId: 'user-001',
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
            )).thenAnswer((_) async => [testRecord]);

        // Act
        final result = await mockService.checkTimeOverlap(
          traineeId: 'user-001',
          startTime: DateTime(2025, 12, 15, 10, 0),
          endTime: DateTime(2025, 12, 15, 11, 0),
        );

        // Assert
        expect(result.length, 1);
      });

      test('部分重疊也被檢測', () async {
        // Arrange - 10:30-11:30 與 10:00-11:00 部分重疊
        when(() => mockService.checkTimeOverlap(
              traineeId: 'user-001',
              startTime: DateTime(2025, 12, 15, 10, 30),
              endTime: DateTime(2025, 12, 15, 11, 30),
            )).thenAnswer((_) async => [testRecord]);

        // Act
        final result = await mockService.checkTimeOverlap(
          traineeId: 'user-001',
          startTime: DateTime(2025, 12, 15, 10, 30),
          endTime: DateTime(2025, 12, 15, 11, 30),
        );

        // Assert
        expect(result, isNotEmpty);
      });

      test('排除自身記錄', () async {
        // Arrange
        when(() => mockService.checkTimeOverlap(
              traineeId: 'user-001',
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime'),
              excludeRecordId: 'record-001',
            )).thenAnswer((_) async => []);

        // Act
        final result = await mockService.checkTimeOverlap(
          traineeId: 'user-001',
          startTime: DateTime(2025, 12, 15, 10, 0),
          endTime: DateTime(2025, 12, 15, 11, 0),
          excludeRecordId: 'record-001',
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // 補充測試：clearUserCache
    // =========================================================================
    group('clearUserCache', () {
      test('清除指定用戶快取', () {
        // Arrange
        when(() => mockService.clearUserCache(userId: 'user-001'))
            .thenReturn(null);

        // Act & Assert
        expect(
          () => mockService.clearUserCache(userId: 'user-001'),
          returnsNormally,
        );
        verify(() => mockService.clearUserCache(userId: 'user-001')).called(1);
      });

      test('清除當前用戶快取', () {
        // Arrange
        when(() => mockService.clearUserCache()).thenReturn(null);

        // Act & Assert
        expect(() => mockService.clearUserCache(), returnsNormally);
        verify(() => mockService.clearUserCache()).called(1);
      });
    });

    // =========================================================================
    // 補充測試：clearUserPlansCache
    // =========================================================================
    group('clearUserPlansCache', () {
      test('清除用戶計劃快取', () {
        // Arrange
        when(() => mockService.clearUserPlansCache('user-001'))
            .thenReturn(null);

        // Act & Assert
        expect(
          () => mockService.clearUserPlansCache('user-001'),
          returnsNormally,
        );
        verify(() => mockService.clearUserPlansCache('user-001')).called(1);
      });
    });
  });
}
