import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:strengthwise/models/statistics_model.dart';
import 'package:strengthwise/models/favorite_exercise_model.dart';

import '../../mocks/mock_services.dart';

/// StatisticsService 測試
///
/// P0 優先級 - 45 個測試案例
/// 參考：docs/planning/TESTING_STRATEGY.md
void main() {
  late MockStatisticsService mockService;

  // 測試用的模型資料
  final testStatisticsData = StatisticsData(
    timeRange: TimeRange.week,
    frequency: TrainingFrequency(
      scheduledWorkouts: 5,
      totalWorkouts: 3,
      completedWorkouts: 2,
      partialWorkouts: 1,
      trainingDays: 3,
      totalHours: 4.5,
      averageHours: 1.5,
      consecutiveDays: 2,
      comparisonValue: 1,
    ),
    volumeHistory: [
      TrainingVolumePoint(
        date: DateTime(2026, 1, 15),
        totalVolume: 5000.0,
        totalSets: 12,
        workoutCount: 1,
      ),
      TrainingVolumePoint(
        date: DateTime(2026, 1, 16),
        totalVolume: 6000.0,
        totalSets: 15,
        workoutCount: 1,
      ),
    ],
    bodyPartStats: [
      BodyPartStats(
        bodyPart: '胸',
        totalVolume: 3000.0,
        workoutCount: 3,
        exerciseCount: 4,
        percentage: 0.3,
      ),
      BodyPartStats(
        bodyPart: '背',
        totalVolume: 2500.0,
        workoutCount: 2,
        exerciseCount: 3,
        percentage: 0.25,
      ),
    ],
    muscleDetails: {},
    trainingTypeStats: [
      TrainingTypeStats(
        trainingType: '重訓',
        workoutCount: 5,
        percentage: 0.8,
      ),
    ],
    equipmentStats: [
      EquipmentStats(
        equipment: '自由重量',
        usageCount: 30,
        percentage: 0.6,
      ),
    ],
    personalRecords: [
      PersonalRecord(
        exerciseId: 'ex-001',
        exerciseName: '槓鈴臥推',
        maxWeight: 100.0,
        reps: 5,
        achievedDate: DateTime(2026, 1, 15),
        bodyPart: '胸',
        isNew: false,
      ),
    ],
    strengthProgress: [],
    muscleGroupBalance: null,
    calendarData: null,
    completionRate: null,
  );

  final testPersonalRecords = [
    PersonalRecord(
      exerciseId: 'ex-001',
      exerciseName: '槓鈴臥推',
      maxWeight: 100.0,
      reps: 5,
      achievedDate: DateTime(2026, 1, 15),
      bodyPart: '胸',
      isNew: false,
    ),
    PersonalRecord(
      exerciseId: 'ex-002',
      exerciseName: '深蹲',
      maxWeight: 120.0,
      reps: 5,
      achievedDate: DateTime(2026, 1, 16),
      bodyPart: '腿',
      isNew: true,
    ),
  ];

  setUpAll(() {
    // 註冊所有 fallback values
    registerFallbackValues();
  });

  setUp(() {
    mockService = MockStatisticsService();
  });

  group('IStatisticsService', () {
    // =========================================================================
    // P2-177 ~ P2-182: getStatistics（核心統計查詢）
    // =========================================================================
    group('getStatistics', () {
      test('正常返回完整統計數據', () async {
        // Arrange
        when(() => mockService.getStatistics('user-001', TimeRange.week))
            .thenAnswer((_) async => testStatisticsData);

        // Act
        final result =
            await mockService.getStatistics('user-001', TimeRange.week);

        // Assert
        expect(result.timeRange, TimeRange.week);
        expect(result.frequency.totalWorkouts, 3);
        expect(result.bodyPartStats, isNotEmpty);
        expect(result.personalRecords, isNotEmpty);
      });

      test('快取命中時直接返回', () async {
        // Arrange
        when(() => mockService.hasCachedStatistics('user-001', TimeRange.week))
            .thenAnswer((_) async => true);

        // Act
        final hasCached =
            await mockService.hasCachedStatistics('user-001', TimeRange.week);

        // Assert
        expect(hasCached, isTrue);
      });

      test('無訓練數據時返回空統計', () async {
        // Arrange
        when(() => mockService.getStatistics('new-user', TimeRange.year))
            .thenAnswer((_) async => StatisticsData.empty(TimeRange.year));

        // Act
        final result =
            await mockService.getStatistics('new-user', TimeRange.year);

        // Assert
        expect(result.frequency.totalWorkouts, 0);
        expect(result.bodyPartStats, isEmpty);
        expect(result.personalRecords, isEmpty);
      });

      test('各時間範圍查詢正確 - week', () async {
        // Arrange
        when(() => mockService.getStatistics('user-001', TimeRange.week))
            .thenAnswer((_) async => StatisticsData.empty(TimeRange.week));

        // Act
        final result =
            await mockService.getStatistics('user-001', TimeRange.week);

        // Assert
        expect(result.timeRange, TimeRange.week);
      });

      test('各時間範圍查詢正確 - month', () async {
        // Arrange
        when(() => mockService.getStatistics('user-001', TimeRange.month))
            .thenAnswer((_) async => StatisticsData.empty(TimeRange.month));

        // Act
        final result =
            await mockService.getStatistics('user-001', TimeRange.month);

        // Assert
        expect(result.timeRange, TimeRange.month);
      });

      test('各時間範圍查詢正確 - year', () async {
        // Arrange
        when(() => mockService.getStatistics('user-001', TimeRange.year))
            .thenAnswer((_) async => StatisticsData.empty(TimeRange.year));

        // Act
        final result =
            await mockService.getStatistics('user-001', TimeRange.year);

        // Assert
        expect(result.timeRange, TimeRange.year);
      });
    });

    // =========================================================================
    // P2-183 ~ P2-186: getTrainingFrequency（訓練頻率）
    // =========================================================================
    group('getTrainingFrequency', () {
      test('正常計算訓練頻率', () async {
        // Arrange
        final frequency = TrainingFrequency(
          scheduledWorkouts: 5,
          totalWorkouts: 3,
          completedWorkouts: 2,
          partialWorkouts: 1,
          trainingDays: 3,
          totalHours: 4.5,
          averageHours: 1.5,
          consecutiveDays: 2,
          comparisonValue: 1,
        );
        when(() =>
                mockService.getTrainingFrequency('user-001', TimeRange.week))
            .thenAnswer((_) async => frequency);

        // Act
        final result =
            await mockService.getTrainingFrequency('user-001', TimeRange.week);

        // Assert
        expect(result.totalWorkouts, 3);
        expect(result.totalHours, 4.5);
        expect(result.consecutiveDays, 2);
      });

      test('零訓練時返回空頻率', () async {
        // Arrange
        final emptyFrequency = TrainingFrequency(
          totalWorkouts: 0,
          totalHours: 0,
          averageHours: 0,
          consecutiveDays: 0,
          comparisonValue: 0,
        );
        when(() =>
                mockService.getTrainingFrequency('new-user', TimeRange.week))
            .thenAnswer((_) async => emptyFrequency);

        // Act
        final result =
            await mockService.getTrainingFrequency('new-user', TimeRange.week);

        // Assert
        expect(result.totalWorkouts, 0);
        expect(result.totalHours, 0);
      });

      test('與上期比較 - 有增長', () async {
        // Arrange
        final frequency = TrainingFrequency(
          totalWorkouts: 5,
          totalHours: 6.0,
          averageHours: 1.2,
          consecutiveDays: 3,
          comparisonValue: 2, // 比上期多 2 次
        );
        when(() =>
                mockService.getTrainingFrequency('user-001', TimeRange.week))
            .thenAnswer((_) async => frequency);

        // Act
        final result =
            await mockService.getTrainingFrequency('user-001', TimeRange.week);

        // Assert
        expect(result.comparisonValue, 2);
        expect(result.hasGrowth, isTrue);
      });

      test('與上期比較 - 有下降', () async {
        // Arrange
        final frequency = TrainingFrequency(
          totalWorkouts: 2,
          totalHours: 2.0,
          averageHours: 1.0,
          consecutiveDays: 1,
          comparisonValue: -3, // 比上期少 3 次
        );
        when(() =>
                mockService.getTrainingFrequency('user-001', TimeRange.week))
            .thenAnswer((_) async => frequency);

        // Act
        final result =
            await mockService.getTrainingFrequency('user-001', TimeRange.week);

        // Assert
        expect(result.comparisonValue, -3);
        expect(result.hasGrowth, isFalse);
      });
    });

    // =========================================================================
    // P2-187 ~ P2-189: getVolumeHistory（訓練量歷史）
    // =========================================================================
    group('getVolumeHistory', () {
      test('正常返回訓練量歷史', () async {
        // Arrange
        final volumeHistory = [
          TrainingVolumePoint(
            date: DateTime(2026, 1, 15),
            totalVolume: 5000.0,
            totalSets: 10,
            workoutCount: 1,
          ),
          TrainingVolumePoint(
            date: DateTime(2026, 1, 16),
            totalVolume: 6000.0,
            totalSets: 12,
            workoutCount: 1,
          ),
        ];
        when(() => mockService.getVolumeHistory('user-001', TimeRange.week))
            .thenAnswer((_) async => volumeHistory);

        // Act
        final result =
            await mockService.getVolumeHistory('user-001', TimeRange.week);

        // Assert
        expect(result.length, 2);
        expect(result[0].totalVolume, 5000.0);
      });

      test('日期正確排序', () async {
        // Arrange
        final volumeHistory = [
          TrainingVolumePoint(
            date: DateTime(2026, 1, 15),
            totalVolume: 5000.0,
            totalSets: 10,
            workoutCount: 1,
          ),
          TrainingVolumePoint(
            date: DateTime(2026, 1, 16),
            totalVolume: 6000.0,
            totalSets: 12,
            workoutCount: 1,
          ),
          TrainingVolumePoint(
            date: DateTime(2026, 1, 17),
            totalVolume: 4500.0,
            totalSets: 9,
            workoutCount: 1,
          ),
        ];
        when(() => mockService.getVolumeHistory('user-001', TimeRange.week))
            .thenAnswer((_) async => volumeHistory);

        // Act
        final result =
            await mockService.getVolumeHistory('user-001', TimeRange.week);

        // Assert
        expect(result[0].date.isBefore(result[1].date), isTrue);
        expect(result[1].date.isBefore(result[2].date), isTrue);
      });

      test('空數據返回空列表', () async {
        // Arrange
        when(() => mockService.getVolumeHistory('new-user', TimeRange.week))
            .thenAnswer((_) async => []);

        // Act
        final result =
            await mockService.getVolumeHistory('new-user', TimeRange.week);

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // P2-190 ~ P2-192: getBodyPartStats（身體部位統計）
    // =========================================================================
    group('getBodyPartStats', () {
      test('正常計算身體部位統計', () async {
        // Arrange
        final bodyPartStats = [
          BodyPartStats(
            bodyPart: '胸',
            totalVolume: 3000.0,
            workoutCount: 12,
            exerciseCount: 4,
            percentage: 0.30,
          ),
          BodyPartStats(
            bodyPart: '背',
            totalVolume: 2500.0,
            workoutCount: 10,
            exerciseCount: 3,
            percentage: 0.25,
          ),
        ];
        when(() => mockService.getBodyPartStats('user-001', TimeRange.week))
            .thenAnswer((_) async => bodyPartStats);

        // Act
        final result =
            await mockService.getBodyPartStats('user-001', TimeRange.week);

        // Assert
        expect(result.length, 2);
        expect(result[0].bodyPart, '胸');
        expect(result[0].percentage, 0.30);
      });

      test('多個身體部位', () async {
        // Arrange
        final bodyPartStats = [
          BodyPartStats(
              bodyPart: '胸', totalVolume: 3000.0, workoutCount: 12, exerciseCount: 4, percentage: 0.25),
          BodyPartStats(
              bodyPart: '背', totalVolume: 2500.0, workoutCount: 10, exerciseCount: 3, percentage: 0.20),
          BodyPartStats(
              bodyPart: '腿', totalVolume: 4000.0, workoutCount: 15, exerciseCount: 5, percentage: 0.35),
          BodyPartStats(
              bodyPart: '肩', totalVolume: 1500.0, workoutCount: 8, exerciseCount: 2, percentage: 0.15),
          BodyPartStats(
              bodyPart: '手臂', totalVolume: 600.0, workoutCount: 6, exerciseCount: 2, percentage: 0.05),
        ];
        when(() => mockService.getBodyPartStats('user-001', TimeRange.month))
            .thenAnswer((_) async => bodyPartStats);

        // Act
        final result =
            await mockService.getBodyPartStats('user-001', TimeRange.month);

        // Assert
        expect(result.length, 5);
        // 百分比總和應接近 1.0
        final totalPercentage =
            result.fold<double>(0.0, (sum, stat) => sum + stat.percentage);
        expect(totalPercentage, closeTo(1.0, 0.01));
      });

      test('無記錄返回空列表', () async {
        // Arrange
        when(() => mockService.getBodyPartStats('new-user', TimeRange.week))
            .thenAnswer((_) async => []);

        // Act
        final result =
            await mockService.getBodyPartStats('new-user', TimeRange.week);

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // P2-193 ~ P2-195: getSpecificMuscleStats（特定肌群統計）
    // =========================================================================
    group('getSpecificMuscleStats', () {
      test('正常返回特定肌群統計', () async {
        // Arrange
        final muscleStats = [
          SpecificMuscleStats(
            specificMuscle: '胸大肌',
            totalVolume: 2000.0,
            workoutCount: 8,
            percentage: 0.65,
          ),
          SpecificMuscleStats(
            specificMuscle: '上胸',
            totalVolume: 1000.0,
            workoutCount: 4,
            percentage: 0.35,
          ),
        ];
        when(() =>
                mockService.getSpecificMuscleStats('user-001', '胸', TimeRange.week))
            .thenAnswer((_) async => muscleStats);

        // Act
        final result = await mockService.getSpecificMuscleStats(
            'user-001', '胸', TimeRange.week);

        // Assert
        expect(result.length, 2);
        expect(result[0].specificMuscle, '胸大肌');
      });

      test('無該部位記錄返回空列表', () async {
        // Arrange
        when(() => mockService.getSpecificMuscleStats(
            'user-001', '核心', TimeRange.week)).thenAnswer((_) async => []);

        // Act
        final result = await mockService.getSpecificMuscleStats(
            'user-001', '核心', TimeRange.week);

        // Assert
        expect(result, isEmpty);
      });

      test('筆數統計正確', () async {
        // Arrange
        final muscleStats = [
          SpecificMuscleStats(
            specificMuscle: '股四頭',
            totalVolume: 5000.0,
            workoutCount: 12,
            percentage: 0.50,
          ),
          SpecificMuscleStats(
            specificMuscle: '股二頭',
            totalVolume: 3000.0,
            workoutCount: 8,
            percentage: 0.35,
          ),
          SpecificMuscleStats(
            specificMuscle: '臀肌',
            totalVolume: 1500.0,
            workoutCount: 4,
            percentage: 0.15,
          ),
        ];
        when(() =>
                mockService.getSpecificMuscleStats('user-001', '腿', TimeRange.week))
            .thenAnswer((_) async => muscleStats);

        // Act
        final result = await mockService.getSpecificMuscleStats(
            'user-001', '腿', TimeRange.week);

        // Assert
        expect(result.length, 3);
        final totalWorkouts = result.fold<int>(0, (sum, stat) => sum + stat.workoutCount);
        expect(totalWorkouts, 24);
      });
    });

    // =========================================================================
    // P2-196 ~ P2-198: getTrainingTypeStats（訓練類型統計）
    // =========================================================================
    group('getTrainingTypeStats', () {
      test('正常返回訓練類型統計', () async {
        // Arrange
        final typeStats = [
          TrainingTypeStats(
            trainingType: '重訓',
            workoutCount: 50,
            percentage: 0.80,
          ),
          TrainingTypeStats(
            trainingType: '有氧',
            workoutCount: 10,
            percentage: 0.15,
          ),
        ];
        when(() => mockService.getTrainingTypeStats('user-001', TimeRange.week))
            .thenAnswer((_) async => typeStats);

        // Act
        final result =
            await mockService.getTrainingTypeStats('user-001', TimeRange.week);

        // Assert
        expect(result.length, 2);
        expect(result[0].trainingType, '重訓');
      });

      test('百分比計算正確', () async {
        // Arrange
        final typeStats = [
          TrainingTypeStats(
            trainingType: '重訓',
            workoutCount: 80,
            percentage: 0.80,
          ),
          TrainingTypeStats(
            trainingType: '功能性訓練',
            workoutCount: 20,
            percentage: 0.20,
          ),
        ];
        when(() => mockService.getTrainingTypeStats('user-001', TimeRange.month))
            .thenAnswer((_) async => typeStats);

        // Act
        final result =
            await mockService.getTrainingTypeStats('user-001', TimeRange.month);

        // Assert
        final totalPercentage =
            result.fold<double>(0.0, (sum, stat) => sum + stat.percentage);
        expect(totalPercentage, closeTo(1.0, 0.01));
      });

      test('無記錄返回空列表', () async {
        // Arrange
        when(() => mockService.getTrainingTypeStats('new-user', TimeRange.week))
            .thenAnswer((_) async => []);

        // Act
        final result =
            await mockService.getTrainingTypeStats('new-user', TimeRange.week);

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // P2-199 ~ P2-200: getEquipmentStats（器材統計）
    // =========================================================================
    group('getEquipmentStats', () {
      test('正常返回器材統計', () async {
        // Arrange
        final equipmentStats = [
          EquipmentStats(
            equipment: '自由重量',
            usageCount: 30,
            percentage: 0.60,
          ),
          EquipmentStats(
            equipment: '機械式',
            usageCount: 20,
            percentage: 0.40,
          ),
        ];
        when(() => mockService.getEquipmentStats('user-001', TimeRange.week))
            .thenAnswer((_) async => equipmentStats);

        // Act
        final result =
            await mockService.getEquipmentStats('user-001', TimeRange.week);

        // Assert
        expect(result.length, 2);
        expect(result[0].equipment, '自由重量');
      });

      test('無器材記錄返回空列表', () async {
        // Arrange
        when(() => mockService.getEquipmentStats('new-user', TimeRange.week))
            .thenAnswer((_) async => []);

        // Act
        final result =
            await mockService.getEquipmentStats('new-user', TimeRange.week);

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // P2-201 ~ P2-204: getPersonalRecords（個人最佳記錄）
    // =========================================================================
    group('getPersonalRecords', () {
      test('正常返回個人最佳記錄', () async {
        // Arrange
        when(() => mockService.getPersonalRecords('user-001', limit: 20))
            .thenAnswer((_) async => testPersonalRecords);

        // Act
        final result =
            await mockService.getPersonalRecords('user-001', limit: 20);

        // Assert
        expect(result.length, 2);
        expect(result[0].exerciseName, '槓鈴臥推');
        expect(result[0].maxWeight, 100.0);
      });

      test('無 PR 記錄返回空列表', () async {
        // Arrange
        when(() => mockService.getPersonalRecords('new-user'))
            .thenAnswer((_) async => []);

        // Act
        final result = await mockService.getPersonalRecords('new-user');

        // Assert
        expect(result, isEmpty);
      });

      test('limit 參數限制返回數量', () async {
        // Arrange
        final limitedRecords = testPersonalRecords.take(1).toList();
        when(() => mockService.getPersonalRecords('user-001', limit: 1))
            .thenAnswer((_) async => limitedRecords);

        // Act
        final result =
            await mockService.getPersonalRecords('user-001', limit: 1);

        // Assert
        expect(result.length, 1);
      });

      test('新 PR 標記為 isNew=true', () async {
        // Arrange
        when(() => mockService.getPersonalRecords('user-001'))
            .thenAnswer((_) async => testPersonalRecords);

        // Act
        final result = await mockService.getPersonalRecords('user-001');

        // Assert
        final newPRs = result.where((pr) => pr.isNew).toList();
        expect(newPRs.length, 1);
        expect(newPRs[0].exerciseName, '深蹲');
      });
    });

    // =========================================================================
    // P2-205 ~ P2-207: getStrengthProgress（力量進步）
    // =========================================================================
    group('getStrengthProgress', () {
      test('正常計算力量進步', () async {
        // Arrange
        final progressData = [
          ExerciseStrengthProgress(
            exerciseId: 'ex-001',
            exerciseName: '槓鈴臥推',
            bodyPart: '胸',
            history: [],
            currentMax: 100.0,
            previousMax: 80.0,
            progressPercentage: 25.0,
            totalSets: 12,
            averageWeight: 90.0,
          ),
        ];
        when(() => mockService.getStrengthProgress('user-001', TimeRange.month))
            .thenAnswer((_) async => progressData);

        // Act
        final result =
            await mockService.getStrengthProgress('user-001', TimeRange.month);

        // Assert
        expect(result.length, 1);
        expect(result[0].progressPercentage, 25.0);
      });

      test('進步百分比計算正確', () async {
        // Arrange
        final progressData = [
          ExerciseStrengthProgress(
            exerciseId: 'ex-001',
            exerciseName: '深蹲',
            bodyPart: '腿',
            history: [],
            currentMax: 120.0,
            previousMax: 100.0,
            progressPercentage: 20.0, // (120-100)/100 * 100 = 20%
            totalSets: 15,
            averageWeight: 110.0,
          ),
        ];
        when(() => mockService.getStrengthProgress('user-001', TimeRange.month))
            .thenAnswer((_) async => progressData);

        // Act
        final result =
            await mockService.getStrengthProgress('user-001', TimeRange.month);

        // Assert
        expect(result[0].previousMax, 100.0);
        expect(result[0].currentMax, 120.0);
        expect(result[0].progressPercentage, 20.0);
      });

      test('無歷史記錄返回空列表', () async {
        // Arrange
        when(() => mockService.getStrengthProgress('new-user', TimeRange.month))
            .thenAnswer((_) async => []);

        // Act
        final result =
            await mockService.getStrengthProgress('new-user', TimeRange.month);

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // P2-208 ~ P2-210: getMuscleGroupBalance（肌群平衡）
    // =========================================================================
    group('getMuscleGroupBalance', () {
      test('正常計算肌群平衡', () async {
        // Arrange
        final balance = MuscleGroupBalance(
          stats: [
            MuscleGroupBalanceStats(
              category: MuscleGroupCategory.push,
              totalVolume: 5000.0,
              workoutCount: 10,
              exerciseCount: 5,
              percentage: 0.30,
              topExercises: ['臥推', '肩推'],
            ),
            MuscleGroupBalanceStats(
              category: MuscleGroupCategory.pull,
              totalVolume: 4500.0,
              workoutCount: 9,
              exerciseCount: 4,
              percentage: 0.27,
              topExercises: ['划船', '引體向上'],
            ),
          ],
          isPushPullBalanced: true,
          pushPullRatio: 1.11,
          balanceStatus: '良好',
          recommendations: [],
        );
        when(() =>
                mockService.getMuscleGroupBalance('user-001', TimeRange.month))
            .thenAnswer((_) async => balance);

        // Act
        final result =
            await mockService.getMuscleGroupBalance('user-001', TimeRange.month);

        // Assert
        expect(result.stats.length, 2);
        expect(result.pushPullRatio, closeTo(1.11, 0.01));
      });

      test('推拉比例計算正確', () async {
        // Arrange
        final balance = MuscleGroupBalance(
          stats: [
            MuscleGroupBalanceStats(
              category: MuscleGroupCategory.push,
              totalVolume: 6000.0,
              workoutCount: 10,
              exerciseCount: 5,
              percentage: 0.30,
              topExercises: ['臥推'],
            ),
            MuscleGroupBalanceStats(
              category: MuscleGroupCategory.pull,
              totalVolume: 6000.0,
              workoutCount: 10,
              exerciseCount: 5,
              percentage: 0.30,
              topExercises: ['划船'],
            ),
          ],
          isPushPullBalanced: true,
          pushPullRatio: 1.0, // 推拉平衡
          balanceStatus: '完美平衡',
          recommendations: [],
        );
        when(() =>
                mockService.getMuscleGroupBalance('user-001', TimeRange.week))
            .thenAnswer((_) async => balance);

        // Act
        final result =
            await mockService.getMuscleGroupBalance('user-001', TimeRange.week);

        // Assert
        expect(result.pushPullRatio, 1.0);
      });

      test('肌群統計正確', () async {
        // Arrange
        final balance = MuscleGroupBalance(
          stats: [
            MuscleGroupBalanceStats(
              category: MuscleGroupCategory.legs,
              totalVolume: 10000.0,
              workoutCount: 15,
              exerciseCount: 8,
              percentage: 0.50,
              topExercises: ['深蹲', '腿推'],
            ),
          ],
          isPushPullBalanced: false,
          pushPullRatio: 0.0,
          balanceStatus: '腿部為主',
          recommendations: ['增加上肢訓練'],
        );
        when(() =>
                mockService.getMuscleGroupBalance('user-001', TimeRange.week))
            .thenAnswer((_) async => balance);

        // Act
        final result =
            await mockService.getMuscleGroupBalance('user-001', TimeRange.week);

        // Assert
        expect(result.legStats?.totalVolume, 10000.0);
      });
    });

    // =========================================================================
    // P2-211 ~ P2-212: getTrainingCalendar（訓練日曆）
    // =========================================================================
    group('getTrainingCalendar', () {
      test('正常生成訓練日曆', () async {
        // Arrange
        final calendarData = TrainingCalendarData(
          days: [
            TrainingCalendarDay(
              date: DateTime(2026, 1, 15),
              hasWorkout: true,
              workoutCount: 1,
              totalVolume: 5000.0,
              intensity: 3,
              bodyParts: ['胸', '肩'],
            ),
            TrainingCalendarDay(
              date: DateTime(2026, 1, 16),
              hasWorkout: true,
              workoutCount: 1,
              totalVolume: 6000.0,
              intensity: 4,
              bodyParts: ['背'],
            ),
            TrainingCalendarDay(
              date: DateTime(2026, 1, 17),
              hasWorkout: false,
              workoutCount: 0,
              totalVolume: 0,
              intensity: 0,
              bodyParts: [],
            ),
          ],
          maxStreak: 3,
          currentStreak: 2,
          averageVolume: 5500.0,
          totalRestDays: 1,
        );
        when(() =>
                mockService.getTrainingCalendar('user-001', TimeRange.week))
            .thenAnswer((_) async => calendarData);

        // Act
        final result =
            await mockService.getTrainingCalendar('user-001', TimeRange.week);

        // Assert
        expect(result.trainingDays, 2);
        expect(result.currentStreak, 2);
      });

      test('連續天數計算正確', () async {
        // Arrange
        final calendarData = TrainingCalendarData(
          days: [
            TrainingCalendarDay(
              date: DateTime(2026, 1, 15),
              hasWorkout: true,
              workoutCount: 1,
              totalVolume: 5000.0,
              intensity: 3,
              bodyParts: ['胸'],
            ),
            TrainingCalendarDay(
              date: DateTime(2026, 1, 16),
              hasWorkout: true,
              workoutCount: 1,
              totalVolume: 6000.0,
              intensity: 4,
              bodyParts: ['背'],
            ),
            TrainingCalendarDay(
              date: DateTime(2026, 1, 17),
              hasWorkout: true,
              workoutCount: 1,
              totalVolume: 7000.0,
              intensity: 4,
              bodyParts: ['腿'],
            ),
          ],
          maxStreak: 5,
          currentStreak: 3,
          averageVolume: 6000.0,
          totalRestDays: 0,
        );
        when(() =>
                mockService.getTrainingCalendar('user-001', TimeRange.week))
            .thenAnswer((_) async => calendarData);

        // Act
        final result =
            await mockService.getTrainingCalendar('user-001', TimeRange.week);

        // Assert
        expect(result.currentStreak, 3);
        expect(result.maxStreak, 5);
      });
    });

    // =========================================================================
    // P2-213 ~ P2-215: getCompletionRate（完成率）
    // =========================================================================
    group('getCompletionRate', () {
      test('正常計算完成率', () async {
        // Arrange
        final completionRate = CompletionRateStats(
          totalPlannedSets: 10,
          completedSets: 8,
          failedSets: 2,
          completionRate: 0.80,
          incompleteExercises: {'深蹲': 2},
          weakPoints: ['深蹲'],
        );
        when(() => mockService.getCompletionRate('user-001', TimeRange.week))
            .thenAnswer((_) async => completionRate);

        // Act
        final result =
            await mockService.getCompletionRate('user-001', TimeRange.week);

        // Assert
        expect(result.completionRate, 0.80);
        expect(result.completedSets, 8);
      });

      test('100% 完成率', () async {
        // Arrange
        final completionRate = CompletionRateStats(
          totalPlannedSets: 5,
          completedSets: 5,
          failedSets: 0,
          completionRate: 1.0,
          incompleteExercises: {},
          weakPoints: [],
        );
        when(() => mockService.getCompletionRate('perfect-user', TimeRange.week))
            .thenAnswer((_) async => completionRate);

        // Act
        final result =
            await mockService.getCompletionRate('perfect-user', TimeRange.week);

        // Assert
        expect(result.completionRate, 1.0);
      });

      test('0% 完成率', () async {
        // Arrange
        final completionRate = CompletionRateStats(
          totalPlannedSets: 5,
          completedSets: 0,
          failedSets: 5,
          completionRate: 0.0,
          incompleteExercises: {'臥推': 3, '深蹲': 2},
          weakPoints: ['臥推', '深蹲'],
        );
        when(() => mockService.getCompletionRate('lazy-user', TimeRange.week))
            .thenAnswer((_) async => completionRate);

        // Act
        final result =
            await mockService.getCompletionRate('lazy-user', TimeRange.week);

        // Assert
        expect(result.completionRate, 0.0);
      });
    });

    // =========================================================================
    // P2-216 ~ P2-217: getTrainingSuggestions（訓練建議）
    // =========================================================================
    group('getTrainingSuggestions', () {
      test('正常生成訓練建議', () async {
        // Arrange
        final suggestions = [
          TrainingSuggestion(
            type: SuggestionType.warning,
            title: '增加背部訓練',
            description: '您的推拉比例失衡，建議增加背部訓練',
          ),
        ];
        when(() => mockService.getTrainingSuggestions(testStatisticsData))
            .thenReturn(suggestions);

        // Act
        final result = mockService.getTrainingSuggestions(testStatisticsData);

        // Assert
        expect(result.length, 1);
        expect(result[0].type, SuggestionType.warning);
      });

      test('無數據時不生成建議', () async {
        // Arrange
        final emptyData = StatisticsData.empty(TimeRange.week);
        when(() => mockService.getTrainingSuggestions(emptyData)).thenReturn([]);

        // Act
        final result = mockService.getTrainingSuggestions(emptyData);

        // Assert
        expect(result, isEmpty);
      });
    });

    // =========================================================================
    // P2-218: clearCache（清除快取）
    // =========================================================================
    group('clearCache', () {
      test('清除快取成功', () {
        // Arrange
        when(() => mockService.clearCache()).thenReturn(null);

        // Act & Assert
        expect(() => mockService.clearCache(), returnsNormally);
        verify(() => mockService.clearCache()).called(1);
      });
    });

    // =========================================================================
    // P2-219 ~ P2-221: hasCachedStatistics（快取檢查）
    // =========================================================================
    group('hasCachedStatistics', () {
      test('快取存在返回 true', () async {
        // Arrange
        when(() => mockService.hasCachedStatistics('user-001', TimeRange.week))
            .thenAnswer((_) async => true);

        // Act
        final result =
            await mockService.hasCachedStatistics('user-001', TimeRange.week);

        // Assert
        expect(result, isTrue);
      });

      test('快取不存在返回 false', () async {
        // Arrange
        when(() => mockService.hasCachedStatistics('user-001', TimeRange.year))
            .thenAnswer((_) async => false);

        // Act
        final result =
            await mockService.hasCachedStatistics('user-001', TimeRange.year);

        // Assert
        expect(result, isFalse);
      });

      test('新用戶無快取', () async {
        // Arrange
        when(() => mockService.hasCachedStatistics('new-user', TimeRange.week))
            .thenAnswer((_) async => false);

        // Act
        final result =
            await mockService.hasCachedStatistics('new-user', TimeRange.week);

        // Assert
        expect(result, isFalse);
      });
    });

    // =========================================================================
    // P2-222: preloadAllTimeRanges（預載入）
    // =========================================================================
    group('preloadAllTimeRanges', () {
      test('正常預載入所有時間範圍', () async {
        // Arrange
        when(() => mockService.preloadAllTimeRanges(
              'user-001',
              currentTimeRange: TimeRange.week,
            )).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.preloadAllTimeRanges(
            'user-001',
            currentTimeRange: TimeRange.week,
          ),
          completes,
        );
        verify(() => mockService.preloadAllTimeRanges(
              'user-001',
              currentTimeRange: TimeRange.week,
            )).called(1);
      });
    });

    // =========================================================================
    // P2-223 ~ P2-224: warmupFromLocalCache（預熱）
    // =========================================================================
    group('warmupFromLocalCache', () {
      test('正常從本地快取預熱', () async {
        // Arrange
        when(() => mockService.warmupFromLocalCache('user-001'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.warmupFromLocalCache('user-001'),
          completes,
        );
        verify(() => mockService.warmupFromLocalCache('user-001')).called(1);
      });

      test('無本地快取時正常完成', () async {
        // Arrange
        when(() => mockService.warmupFromLocalCache('new-user'))
            .thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          mockService.warmupFromLocalCache('new-user'),
          completes,
        );
      });
    });

    // =========================================================================
    // P2-225 ~ P2-226: getExercisesWithRecords（有記錄的動作）
    // =========================================================================
    group('getExercisesWithRecords', () {
      test('正常返回有記錄的動作列表', () async {
        // Arrange
        final exercises = [
          ExerciseWithRecord(
            exerciseId: 'ex-001',
            exerciseName: '槓鈴臥推',
            bodyPart: '胸',
            trainingType: '阻力訓練',
            lastTrainingDate: DateTime(2026, 1, 15),
            maxWeight: 100.0,
            totalSets: 24,
          ),
        ];
        when(() => mockService.getExercisesWithRecords('user-001'))
            .thenAnswer((_) async => exercises);

        // Act
        final result = await mockService.getExercisesWithRecords('user-001');

        // Assert
        expect(result.length, 1);
        expect(result[0].exerciseName, '槓鈴臥推');
      });

      test('篩選條件正確過濾', () async {
        // Arrange
        final chestExercises = [
          ExerciseWithRecord(
            exerciseId: 'ex-001',
            exerciseName: '槓鈴臥推',
            bodyPart: '胸',
            trainingType: '阻力訓練',
            lastTrainingDate: DateTime(2026, 1, 15),
            maxWeight: 100.0,
            totalSets: 24,
          ),
          ExerciseWithRecord(
            exerciseId: 'ex-002',
            exerciseName: '啞鈴飛鳥',
            bodyPart: '胸',
            trainingType: '阻力訓練',
            lastTrainingDate: DateTime(2026, 1, 14),
            maxWeight: 15.0,
            totalSets: 12,
          ),
        ];
        when(() => mockService.getExercisesWithRecords(
              'user-001',
              bodyPart: '胸',
            )).thenAnswer((_) async => chestExercises);

        // Act
        final result = await mockService.getExercisesWithRecords(
          'user-001',
          bodyPart: '胸',
        );

        // Assert
        expect(result.length, 2);
      });
    });
  });
}
