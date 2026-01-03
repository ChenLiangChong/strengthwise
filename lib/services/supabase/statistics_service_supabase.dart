import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/statistics_model.dart';
import '../../models/exercise_model.dart';
import '../../models/favorite_exercise_model.dart';
import '../../utils/datetime_utils.dart';
import '../interfaces/i_statistics_service.dart';
import '../interfaces/i_exercise_service.dart';
import '../core/error_handling_service.dart';
import 'statistics/statistics_cache_manager.dart';
import 'statistics/statistics_data_loader.dart';
import 'statistics/statistics_data_parser.dart';
import 'statistics/statistics_calculator.dart';
import 'statistics/statistics_personal_records_calculator.dart';
import 'statistics/statistics_training_suggestions.dart';
import 'statistics/statistics_muscle_balance.dart';
import 'statistics/statistics_calendar.dart';
import 'statistics/statistics_completion_rate.dart';
import 'statistics/statistics_strength_progress.dart';

import 'statistics/statistics_models.dart';

/// 統計服務 Supabase 實作
///
/// 提供訓練數據統計和分析功能（Supabase PostgreSQL 版本）
class StatisticsServiceSupabase implements IStatisticsService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;
  final IExerciseService _exerciseService;

  // 動作分類快取（exerciseId -> Exercise）
  final Map<String, Exercise> _exerciseCache = {};

  // ⚡ ExerciseWithRecord 列表快取（避免重複統計）
  static const int _exerciseCacheVersion = 3; // 🆕 增加版本號清除舊快取
  List<ExerciseWithRecord>? _cachedExercisesWithRecords;
  String? _cachedExercisesUserId;
  Set<String>? _cachedSystemExerciseIds;
  int? _cachedExercisesVersion;

  // 子模組（各司其職）
  late final StatisticsCacheManager _cacheManager;
  late final StatisticsDataLoader _dataLoader;
  late final StatisticsDataParser _dataParser;
  late final StatisticsCalculator _calculator;
  late final PersonalRecordsCalculator _prCalculator;
  late final TrainingSuggestionsGenerator _suggestionsGenerator;
  late final MuscleBalanceAnalyzer _muscleBalanceAnalyzer;
  late final TrainingCalendarGenerator _calendarGenerator;
  late final CompletionRateCalculator _completionRateCalculator;
  late final StrengthProgressCalculator _strengthProgressCalculator;

  StatisticsServiceSupabase({
    required SupabaseClient supabase,
    required ErrorHandlingService errorService,
    required IExerciseService exerciseService,
  })  : _supabase = supabase,
        _errorService = errorService,
        _exerciseService = exerciseService {
    // 初始化子模組
    _cacheManager = StatisticsCacheManager();
    _dataLoader = StatisticsDataLoader(supabase: supabase);
    _dataParser = StatisticsDataParser(errorService: errorService);
    _calculator = StatisticsCalculator(exerciseCache: _exerciseCache);
    _prCalculator = PersonalRecordsCalculator(
      dataLoader: _dataLoader,
      dataParser: _dataParser,
      errorService: errorService,
      exerciseCache: _exerciseCache,
    );
    _suggestionsGenerator = TrainingSuggestionsGenerator();
    _muscleBalanceAnalyzer =
        MuscleBalanceAnalyzer(exerciseCache: _exerciseCache);
    _calendarGenerator = TrainingCalendarGenerator(exerciseCache: _exerciseCache);
    _completionRateCalculator = CompletionRateCalculator();
    _strengthProgressCalculator =
        StrengthProgressCalculator(exerciseCache: _exerciseCache);
  }

  @override
  Future<StatisticsData> getStatistics(
      String userId, TimeRange timeRange) async {
    try {
      // ⚡ 檢查多時間範圍快取（5 分鐘內有效）
      if (_cacheManager.isStatisticsCacheValid(userId, timeRange)) {
        final cached = _cacheManager.getCachedStatistics(userId, timeRange);
        if (cached != null) {
          _logDebug('✅ 從快取返回統計數據（時間範圍：${timeRange.displayName}）');
          return cached;
        }
      }

      _logDebug('🔍 首次查詢統計數據（時間範圍：${timeRange.displayName}）');

      // ⚡ 關鍵優化：只查詢一次訓練數據
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      // ⚡ 預先批量載入所有動作分類（2 次查詢取代 N 次查詢）
      await _loadExerciseClassifications(workouts);

      // 獲取各項統計（現在使用已載入的數據和快取）
      final frequency = await getTrainingFrequency(userId, timeRange);
      final volumeHistory = await getVolumeHistory(userId, timeRange);
      final bodyPartStats = await getBodyPartStats(userId, timeRange);
      final trainingTypeStats = await getTrainingTypeStats(userId, timeRange);
      final equipmentStats = await getEquipmentStats(userId, timeRange);
      final personalRecords = await getPersonalRecords(userId, limit: 10);

      // 獲取特定肌群細節
      final muscleDetails = <String, List<SpecificMuscleStats>>{};
      for (var stat in bodyPartStats) {
        final details =
            await getSpecificMuscleStats(userId, stat.bodyPart, timeRange);
        if (details.isNotEmpty) {
          muscleDetails[stat.bodyPart] = details;
        }
      }

      // 獲取新的統計數據
      final strengthProgress =
          await getStrengthProgress(userId, timeRange, limit: 10);
      final muscleGroupBalance = await getMuscleGroupBalance(userId, timeRange);
      final calendarData = await getTrainingCalendar(userId, timeRange);
      final completionRate = await getCompletionRate(userId, timeRange);

      final data = StatisticsData(
        timeRange: timeRange,
        frequency: frequency,
        volumeHistory: volumeHistory,
        bodyPartStats: bodyPartStats,
        muscleDetails: muscleDetails,
        trainingTypeStats: trainingTypeStats,
        equipmentStats: equipmentStats,
        personalRecords: personalRecords,
        strengthProgress: strengthProgress,
        muscleGroupBalance: muscleGroupBalance,
        calendarData: calendarData,
        completionRate: completionRate,
      );

      // ⚡ 更新多時間範圍快取
      _cacheManager.cacheStatistics(userId, timeRange, data);
      _logDebug('✅ 已快取統計數據（時間範圍：${timeRange.displayName}）');

      return data;
    } catch (e) {
      _errorService.logError('載入統計數據失敗: $e', type: 'StatisticsServiceError');
      return StatisticsData.empty(timeRange);
    }
  }

  @override
  Future<TrainingFrequency> getTrainingFrequency(
      String userId, TimeRange timeRange) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;

      _logDebug('⚡ 訓練頻率：使用 daily_workout_summary 彙總表查詢');

      // ⚡ 使用彙總表查詢（效能提升 80%+）
      final currentStats =
          await _dataLoader.getDailySummary(userId, startDate, endDate);

      // 計算與上期對比
      final previousStart = _getPreviousPeriodStart(timeRange);
      final previousStats =
          await _dataLoader.getDailySummary(userId, previousStart, startDate);

      return _calculator.calculateTrainingFrequency(
        currentStats: currentStats,
        previousStats: previousStats,
      );
    } catch (e) {
      _errorService.logError('計算訓練頻率失敗: $e', type: 'StatisticsServiceError');
      return TrainingFrequency(
        totalWorkouts: 0,
        totalHours: 0,
        averageHours: 0,
        consecutiveDays: 0,
        comparisonValue: 0,
      );
    }
  }

  @override
  Future<List<TrainingVolumePoint>> getVolumeHistory(
    String userId,
    TimeRange timeRange,
  ) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;

      _logDebug('⚡ 訓練量趨勢：使用 daily_workout_summary 彙總表查詢');

      // ⚡ 使用彙總表查詢（效能提升 85%+）
      final summaryData =
          await _dataLoader.getVolumeSummary(userId, startDate, endDate);

      return _calculator.calculateVolumeHistory(summaryData);
    } catch (e) {
      _errorService.logError('計算訓練量歷史失敗: $e', type: 'StatisticsServiceError');
      return [];
    }
  }

  @override
  Future<List<BodyPartStats>> getBodyPartStats(
    String userId,
    TimeRange timeRange,
  ) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      if (workouts.isEmpty) return [];

      // 載入動作分類
      await _loadExerciseClassifications(workouts);

      return _calculator.calculateBodyPartStats(
          workouts.cast<UnifiedWorkoutData>());
    } catch (e) {
      _errorService.logError('計算身體部位統計失敗: $e', type: 'StatisticsServiceError');
      return [];
    }
  }

  @override
  Future<List<SpecificMuscleStats>> getSpecificMuscleStats(
    String userId,
    String bodyPart,
    TimeRange timeRange,
  ) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      if (workouts.isEmpty) return [];

      // 載入動作分類
      await _loadExerciseClassifications(workouts);

      return _calculator.calculateSpecificMuscleStats(
          workouts.cast<UnifiedWorkoutData>(), bodyPart);
    } catch (e) {
      _errorService.logError('計算特定肌群統計失敗: $e', type: 'StatisticsServiceError');
      return [];
    }
  }

  @override
  Future<List<TrainingTypeStats>> getTrainingTypeStats(
    String userId,
    TimeRange timeRange,
  ) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;

      _logDebug('⚡ 訓練類型統計：使用 daily_workout_summary 彙總表查詢');

      // ⚡ 使用彙總表查詢（效能提升 90%+）
      final summaryData = await _dataLoader.getTrainingTypeSummary(
          userId, startDate, endDate);

      return _calculator.calculateTrainingTypeStats(summaryData);
    } catch (e) {
      _errorService.logError('計算訓練類型統計失敗: $e', type: 'StatisticsServiceError');
      return [];
    }
  }

  @override
  Future<List<EquipmentStats>> getEquipmentStats(
    String userId,
    TimeRange timeRange,
  ) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      if (workouts.isEmpty) return [];

      // 載入動作分類
      await _loadExerciseClassifications(workouts);

      return _calculator.calculateEquipmentStats(
          workouts.cast<UnifiedWorkoutData>());
    } catch (e) {
      _errorService.logError('計算器材統計失敗: $e', type: 'StatisticsServiceError');
      return [];
    }
  }

  @override
  Future<List<PersonalRecord>> getPersonalRecords(
    String userId, {
    int limit = 20,
  }) async {
    return await _prCalculator.calculatePersonalRecords(
      userId,
      limit: limit,
    );
  }

  @override
  List<TrainingSuggestion> getTrainingSuggestions(
      StatisticsData statisticsData) {
    return _suggestionsGenerator.generateSuggestions(statisticsData);
  }

  @override
  void clearCache() {
    _exerciseCache.clear();
    _cacheManager.clearAll();
  }

  /// ⚡ 預載入所有時間範圍的統計數據（後台執行）
  Future<void> preloadAllTimeRanges(String userId,
      {TimeRange? currentTimeRange}) async {
    _logDebug('🚀 開始預載入其他時間範圍的統計數據...');

    final timeRanges = [
      TimeRange.week,
      TimeRange.sevenDays,  // 🆕 最近七天
      TimeRange.month,
      TimeRange.threeMonth,
      TimeRange.year,
    ];

    final rangesToPreload =
        timeRanges.where((range) => range != currentTimeRange).toList();

    if (rangesToPreload.isEmpty) {
      _logDebug('⏭️ 沒有需要預載入的時間範圍');
      return;
    }

    _logDebug(
        '📋 將預載入 ${rangesToPreload.length} 個時間範圍：${rangesToPreload.map((r) => r.displayName).join('、')}');

    // 並行載入（不阻塞主線程）
    final futures = rangesToPreload.map((TimeRange range) async {
      try {
        if (_cacheManager.isStatisticsCacheValid(userId, range)) {
          _logDebug('⏭️ 跳過已快取的時間範圍：${range.displayName}');
          return;
        }

        await getStatistics(userId, range);
        _logDebug('✅ 預載入完成：${range.displayName}');
      } catch (e) {
        _logDebug('⚠️ 預載入失敗（${range.displayName}）: $e');
      }
    });

    await Future.wait(futures);
    _logDebug('🎉 所有時間範圍預載入完成！');
  }

  @override
  Future<List<ExerciseWithRecord>> getExercisesWithRecords(
    String userId, {
    String? trainingType,
    String? bodyPart,
    String? specificMuscle,
    String? equipmentCategory,
    TimeRange? timeRange, // 時間範圍過濾（可選）
  }) async {
    try {
      // ⚡ 優化：如果有快取的完整列表，直接從快取過濾
      // ⚠️ 注意：如果傳入 timeRange，跳過快取（因為快取是全時間範圍的）
      if (timeRange == null &&
          _cachedExercisesWithRecords != null &&
          _cachedExercisesUserId == userId &&
          _cachedExercisesVersion == _exerciseCacheVersion) {
        var filtered = _cachedExercisesWithRecords!;

        // 客戶端過濾
        if (trainingType != null) {
          if (trainingType == '自訂') {
            filtered = filtered.where((e) => e.isCustom).toList();
          } else {
            filtered = filtered
                .where((e) => e.trainingType == trainingType && !e.isCustom)
                .toList();
          }
        }
        if (bodyPart != null) {
          filtered = filtered.where((e) => e.bodyPart == bodyPart).toList();
        }

        return filtered;
      }


      // 查詢所有訓練計劃（包括部分完成的）
      // Parser 會過濾出 set.completed = true 的組
      var query = _supabase
          .from('workout_plans')
          .select('id, exercises, completed_date, updated_at, scheduled_date, created_at, trainee_id')
          .eq('trainee_id', userId);

      // 根據時間範圍過濾（使用訓練實際日期，而非更新日期）
      // 優先順序：completed_date > scheduled_date > created_at
      if (timeRange != null) {
        // ⚠️ Supabase 不支援 COALESCE，所以需要在客戶端過濾
        // 先用 updated_at 擴大範圍，再在客戶端精確過濾
        final expandedStartDate = timeRange.startDate.subtract(const Duration(days: 365));
        query = query.gte('updated_at', DateTimeUtils.formatToUtcIso(expandedStartDate));
      }

      final response = await query;

      final workoutPlans = response as List<dynamic>;

      if (workoutPlans.isEmpty) {
        return [];
      }

      // 統計每個動作的訓練數據
      final Map<String, _ExerciseRecordData> exerciseStats = {};
      int filteredCount = 0;

      print('[GET_EXERCISES] 查詢到 ${workoutPlans.length} 個訓練計劃');
      if (timeRange != null) {
        print('[GET_EXERCISES] 時間範圍: ${timeRange.startDate.toLocal()} ~ ${timeRange.endDate.toLocal()}');
      }

      for (var planData in workoutPlans) {
        final data = planData as Map<String, dynamic>;
        
        // ⚡ 客戶端時間範圍過濾
        // 優先順序：completed_date > scheduled_date > created_at
        if (timeRange != null) {
          final completedDateStr = data['completed_date'] as String?;
          final scheduledDateStr = data['scheduled_date'] as String?;
          final createdAtStr = data['created_at'] as String?;
          
          DateTime? trainingDate;
          if (completedDateStr != null) {
            trainingDate = DateTimeUtils.parseIsoTimestamp(completedDateStr);
          } else if (scheduledDateStr != null) {
            trainingDate = DateTimeUtils.parseIsoTimestamp(scheduledDateStr);
          } else if (createdAtStr != null) {
            trainingDate = DateTimeUtils.parseIsoTimestamp(createdAtStr);
          }
          
          // ⚠️ 重要：使用 UTC 日期（只比較年月日，忽略時間）
          // 用戶期望：訓練計劃按 UTC 日期分組，不考慮本地時區
          if (trainingDate != null) {
            // 使用 DateTimeUtils 統一工具類進行時間範圍檢查
            if (!DateTimeUtils.isWithinUtcDateRange(
              trainingDate,
              timeRange.startDate,
              timeRange.endDate,
            )) {
              filteredCount++;
              continue;
            }
          }
        }
        
        final exercises = data['exercises'] as List<dynamic>? ?? [];

        for (var exerciseData in exercises) {
          final exerciseMap = exerciseData as Map<String, dynamic>;
          final exerciseId = exerciseMap['exerciseId'] as String?;
          final exerciseName =
              exerciseMap['exerciseName'] as String? ?? '未知動作';
          final sets = exerciseMap['sets'] as List<dynamic>? ?? [];

          if (exerciseId == null) continue;

          // ⚡ 先檢查是否有完成的組數
          bool hasCompletedSets = false;
          double maxWeight = 0;
          int completedSetsCount = 0;

          for (var set in sets) {
            final setMap = set as Map<String, dynamic>;
            final isCompleted = setMap['completed'] as bool? ?? false;
            if (isCompleted) {
              hasCompletedSets = true;
              completedSetsCount++;
              final weight = (setMap['weight'] as num?)?.toDouble() ?? 0;
              if (weight > maxWeight) {
                maxWeight = weight;
              }
            }
          }

          // ⚠️ 只統計有完成組數的動作
          if (!hasCompletedSets) continue;

          // 累計訓練數據
          if (!exerciseStats.containsKey(exerciseId)) {
            // ⚡ 計算訓練實際日期（優先順序：completed_date > scheduled_date > created_at）
            final completedDateStr = data['completed_date'] as String?;
            final scheduledDateStr = data['scheduled_date'] as String?;
            final createdAtStr = data['created_at'] as String?;
            final dateStr = completedDateStr ?? 
                           scheduledDateStr ?? 
                           createdAtStr ?? 
                           DateTimeUtils.formatToUtcIso(DateTime.now());
            
            exerciseStats[exerciseId] = _ExerciseRecordData(
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              lastTrainingDate: DateTimeUtils.parseIsoTimestamp(dateStr),
              maxWeight: maxWeight,
              totalSets: completedSetsCount,
            );
          } else {
            final stat = exerciseStats[exerciseId]!;
            stat.totalSets += completedSetsCount;

            // ⚡ 更新最後訓練日期（優先順序：completed_date > scheduled_date > created_at）
            final completedDateStr = data['completed_date'] as String?;
            final scheduledDateStr = data['scheduled_date'] as String?;
            final createdAtStr = data['created_at'] as String?;
            final dateStr = completedDateStr ?? scheduledDateStr ?? createdAtStr;
            if (dateStr != null) {
              final trainingDate = DateTimeUtils.parseIsoTimestamp(dateStr);
              if (trainingDate.isAfter(stat.lastTrainingDate)) {
                stat.lastTrainingDate = trainingDate;
              }
            }

            // 更新最大重量
            if (maxWeight > stat.maxWeight) {
              stat.maxWeight = maxWeight;
            }
          }
        }
      }

      // ⚡ 優化：批量查詢所有系統動作 ID
      final allExerciseIds = exerciseStats.keys.toList();
      if (allExerciseIds.isNotEmpty) {
        final systemResponse = await _supabase
            .from('exercises')
            .select('id')
            .inFilter('id', allExerciseIds);

        _cachedSystemExerciseIds =
            (systemResponse as List).map((e) => e['id'] as String).toSet();

        print(
            '[STATISTICS] 批量查詢系統動作：${allExerciseIds.length} 個動作 ID，${_cachedSystemExerciseIds!.length} 個是系統動作');
      }

      // 獲取動作分類信息並過濾
      final List<ExerciseWithRecord> results = [];

      for (var stat in exerciseStats.values) {
        final exercise = await _getExerciseInfo(stat.exerciseId);
        if (exercise == null) continue;

        final isCustom = _cachedSystemExerciseIds != null
            ? !_cachedSystemExerciseIds!.contains(stat.exerciseId)
            : false;

        results.add(ExerciseWithRecord(
          exerciseId: stat.exerciseId,
          exerciseName: stat.exerciseName,
          bodyPart: exercise.bodyPart.isNotEmpty ? exercise.bodyPart : '其他',
          trainingType:
              exercise.trainingType.isNotEmpty ? exercise.trainingType : '阻力訓練',
          lastTrainingDate: stat.lastTrainingDate,
          maxWeight: stat.maxWeight,
          totalSets: stat.totalSets,
          isCustom: isCustom,
        ));
      }

      results.sort((a, b) => b.lastTrainingDate.compareTo(a.lastTrainingDate));

      // ⚡ 快取完整結果（僅當沒有 timeRange 時）
      if (timeRange == null) {
        _cachedExercisesWithRecords = results;
        _cachedExercisesUserId = userId;
        _cachedExercisesVersion = _exerciseCacheVersion;
      }

      if (timeRange != null) {
        print('[GET_EXERCISES] 過濾掉 $filteredCount/${workoutPlans.length} 個訓練計劃');
        print('[GET_EXERCISES] 統計到 ${exerciseStats.length} 個不同的動作');
      }

      // ⚡ 客戶端過濾（與快取邏輯一致）
      var filtered = results;
      if (trainingType != null) {
        if (trainingType == '自訂') {
          filtered = filtered.where((e) => e.isCustom).toList();
        } else {
          filtered = filtered
              .where((e) => e.trainingType == trainingType && !e.isCustom)
              .toList();
        }
      }
      if (bodyPart != null) {
        filtered = filtered.where((e) => e.bodyPart == bodyPart).toList();
      }

      print('[GET_EXERCISES] 返回 ${filtered.length} 個動作');
      if (trainingType != null) print('   過濾條件 - 訓練類型: $trainingType');
      if (bodyPart != null) print('   過濾條件 - 身體部位: $bodyPart');
      for (var r in filtered.take(3)) {
        print('   - ${r.exerciseName} (${r.isCustom ? "自訂" : "系統"}, ${r.bodyPart})');
      }

      return filtered;
    } catch (e) {
      _errorService.logError('獲取有記錄的動作列表失敗: $e');
      return [];
    }
  }

  @override
  Future<List<ExerciseStrengthProgress>> getStrengthProgress(
    String userId,
    TimeRange timeRange, {
    int limit = 10,
  }) async {
    try {
      // ⚡ 檢查多時間範圍快取
      if (_cacheManager.isStrengthProgressCacheValid(userId, timeRange, limit)) {
        final cached =
            _cacheManager.getCachedStrengthProgress(userId, timeRange, limit);
        if (cached != null) {
          _logDebug(
              '✅ 從快取返回 ${cached.length} 個力量進步記錄（時間範圍：${timeRange.displayName}）');
          return cached;
        }
      }

      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      // 載入動作分類
      await _loadExerciseClassifications(workouts);

      final result = _strengthProgressCalculator.calculateProgress(
        workouts.cast<UnifiedWorkoutData>(),
        startDate,
        timeRange,
        limit: limit,
      );

      // ⚡ 更新快取
      _cacheManager.cacheStrengthProgress(userId, timeRange, limit, result);

      _logDebug(
          '✅ 計算並快取 ${result.length} 個力量進步記錄（時間範圍：${timeRange.displayName}）');
      return result;
    } catch (e) {
      _errorService.logError('計算力量進步失敗: $e', type: 'StatisticsServiceError');
      return [];
    }
  }

  @override
  Future<MuscleGroupBalance> getMuscleGroupBalance(
      String userId, TimeRange timeRange) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      // 載入動作分類
      await _loadExerciseClassifications(workouts);

      return _muscleBalanceAnalyzer.calculateBalance(
          workouts.cast<UnifiedWorkoutData>());
    } catch (e) {
      _errorService.logError('計算肌群平衡失敗: $e', type: 'StatisticsServiceError');
      return MuscleGroupBalance(
        stats: [],
        isPushPullBalanced: true,
        pushPullRatio: 1.0,
        balanceStatus: '無數據',
        recommendations: [],
      );
    }
  }

  @override
  Future<TrainingCalendarData> getTrainingCalendar(
      String userId, TimeRange timeRange) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      // 載入動作分類
      await _loadExerciseClassifications(workouts);

      return _calendarGenerator.generateCalendar(
          workouts.cast<UnifiedWorkoutData>(), startDate, endDate);
    } catch (e) {
      _errorService.logError('生成訓練日曆失敗: $e', type: 'StatisticsServiceError');
      return TrainingCalendarData(
        days: [],
        maxStreak: 0,
        currentStreak: 0,
        averageVolume: 0,
        totalRestDays: 0,
      );
    }
  }

  @override
  Future<CompletionRateStats> getCompletionRate(
      String userId, TimeRange timeRange) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      return _completionRateCalculator.calculateCompletionRate(
          workouts.cast<UnifiedWorkoutData>());
    } catch (e) {
      _errorService.logError('計算完成率失敗: $e', type: 'StatisticsServiceError');
      return CompletionRateStats(
        totalPlannedSets: 0,
        completedSets: 0,
        failedSets: 0,
        completionRate: 1.0,
        incompleteExercises: {},
        weakPoints: [],
      );
    }
  }

  // ========== 私有輔助方法 ==========

  /// 獲取動作詳細信息（內部使用）
  Future<Exercise?> _getExerciseInfo(String exerciseId) async {
    if (_exerciseCache.containsKey(exerciseId)) {
      return _exerciseCache[exerciseId];
    }

    try {
      final exercise = await _exerciseService.getExerciseById(exerciseId);
      if (exercise != null) {
        _exerciseCache[exerciseId] = exercise;
      }
      return exercise;
    } catch (e) {
      return null;
    }
  }

  /// 查詢已完成的訓練（轉換為統一格式）
  Future<List<dynamic>> _getCompletedWorkouts(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // ⚡ 檢查快取
    if (_cacheManager.isWorkoutsCacheValid(userId, startDate, endDate)) {
      return _cacheManager.getCachedWorkouts()!;
    }

    final rawWorkouts =
        await _dataLoader.getCompletedWorkouts(userId, startDate, endDate);
    final workouts = _dataParser.parseWorkoutDataList(rawWorkouts);

    // ⚡ 快取結果
    _cacheManager.cacheWorkouts(userId, startDate, endDate, workouts);

    return workouts;
  }

  /// 批量載入動作分類信息
  Future<void> _loadExerciseClassifications(List<dynamic> workouts) async {
    final exerciseIds = workouts
        .cast<UnifiedWorkoutData>()
        .expand((w) => w.exercises)
        .map((e) => e.exerciseId)
        .toSet()
        .toList();

    final uncachedIds =
        exerciseIds.where((id) => !_exerciseCache.containsKey(id)).toList();

    if (uncachedIds.isEmpty) {
      return;
    }

    try {
      final exercises = await _exerciseService.getExercisesByIds(uncachedIds.cast<String>());
      _exerciseCache.addAll(exercises);
    } catch (e) {
      _errorService.logError('批量載入動作分類失敗: $e', type: 'StatisticsServiceError');
    }
  }

  /// 獲取上一個時間範圍的起始日期
  DateTime _getPreviousPeriodStart(TimeRange timeRange) {
    final startDate = timeRange.startDate;
    final endDate = timeRange.endDate;
    final duration = endDate.difference(startDate);
    return startDate.subtract(duration);
  }

  /// 輔助方法：記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[STATISTICS_SERVICE] $message');
    }
  }
}

/// 動作訓練記錄數據（內部使用）
class _ExerciseRecordData {
  final String exerciseId;
  final String exerciseName;
  DateTime lastTrainingDate;
  double maxWeight;
  int totalSets;

  _ExerciseRecordData({
    required this.exerciseId,
    required this.exerciseName,
    required this.lastTrainingDate,
    required this.maxWeight,
    required this.totalSets,
  });
}
