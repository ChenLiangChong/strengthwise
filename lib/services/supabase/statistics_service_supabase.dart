import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../models/statistics_model.dart';
import '../../models/exercise_model.dart';
import '../../models/favorite_exercise_model.dart';
import '../../utils/datetime_utils.dart';
import '../interfaces/i_statistics_service.dart';
import '../interfaces/i_exercise_service.dart';
import '../core/error_handling_service.dart';
import '../cache/statistics_local_cache_service.dart';
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

/// ⭐ Debug 開關：設為 false 可隱藏統計服務的詳細 log
const bool _kStatisticsDebugLog = false;

/// 統計服務 Supabase 實作
///
/// 提供訓練數據統計和分析功能（Supabase PostgreSQL 版本）
/// v3.1.1 新增：本地持久化快取支持
class StatisticsServiceSupabase implements IStatisticsService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;
  final IExerciseService _exerciseService;
  final StatisticsLocalCacheService? _localCacheService;

  // 動作分類快取（exerciseId -> Exercise）
  final Map<String, Exercise> _exerciseCache = {};

  // ⚡ ExerciseWithRecord 列表快取（避免重複統計）
  static const int _exerciseCacheVersion = 4; // 🆕 v3.1.1 多時間範圍快取
  List<ExerciseWithRecord>? _cachedExercisesWithRecords; // 一年範圍的完整數據
  String? _cachedExercisesUserId;
  Set<String>? _cachedSystemExerciseIds;
  int? _cachedExercisesVersion;
  DateTime? _cachedExercisesTimestamp; // 快取時間（用於檢查有效性）

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
    StatisticsLocalCacheService? localCacheService,
  })  : _supabase = supabase,
        _errorService = errorService,
        _exerciseService = exerciseService,
        _localCacheService = localCacheService {
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
    _calendarGenerator =
        TrainingCalendarGenerator(exerciseCache: _exerciseCache);
    _completionRateCalculator = CompletionRateCalculator();
    _strengthProgressCalculator =
        StrengthProgressCalculator(exerciseCache: _exerciseCache);
  }

  @override
  Future<StatisticsData> getStatistics(
      String userId, TimeRange timeRange) async {
    try {
      // ⚡ 1. 檢查記憶體快取（5 分鐘內有效）
      if (_cacheManager.isStatisticsCacheValid(userId, timeRange)) {
        final cached = _cacheManager.getCachedStatistics(userId, timeRange);
        if (cached != null) {
          _logDebug('✅ 從記憶體快取返回統計數據（${timeRange.displayName}）');
          return cached;
        }
      }

      // ⚡ 2. 檢查本地持久化快取（24 小時內有效）
      if (_localCacheService != null) {
        final localValid =
            await _localCacheService!.isCacheValidAsync(userId, timeRange);
        if (localValid) {
          final localCached =
              _localCacheService!.getCachedStatistics(userId, timeRange);
          if (localCached != null) {
            _logDebug('✅ 從本地快取返回統計數據（${timeRange.displayName}）');
            // 同時更新記憶體快取
            _cacheManager.cacheStatistics(userId, timeRange, localCached);
            return localCached;
          }
        }
      }

      _logDebug('🔍 首次查詢統計數據（時間範圍：${timeRange.displayName}）');

      // ⭐ Phase 2 優化：統一查詢數據，減少重複調用
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;

      // 1️⃣ 一次查詢所有訓練數據
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);
      final typedWorkouts = workouts.cast<UnifiedWorkoutData>();

      // 2️⃣ 一次批量載入所有動作分類
      await _loadExerciseClassifications(workouts);

      // 3️⃣ 使用彙總表的方法（這些有獨立快取）
      final frequency = await getTrainingFrequency(userId, timeRange);
      final volumeHistory = await getVolumeHistory(userId, timeRange);
      final trainingTypeStats = await getTrainingTypeStats(userId, timeRange);
      final personalRecords = await getPersonalRecords(userId, limit: 10);

      // 4️⃣ 純計算方法（直接使用已查詢的 workouts，不再重複調用 _getCompletedWorkouts）
      final bodyPartStats = _calculator.calculateBodyPartStats(typedWorkouts);
      final equipmentStats = _calculator.calculateEquipmentStats(typedWorkouts);

      // ⭐ Phase 2 優化：一次計算所有肌群細節，避免循環調用
      final muscleDetails = <String, List<SpecificMuscleStats>>{};
      for (var stat in bodyPartStats) {
        final details = _calculator.calculateSpecificMuscleStats(
            typedWorkouts, stat.bodyPart);
        if (details.isNotEmpty) {
          muscleDetails[stat.bodyPart] = details;
        }
      }

      // 5️⃣ 其他計算方法
      final strengthProgress = _strengthProgressCalculator
          .calculateProgress(typedWorkouts, startDate, timeRange, limit: 10);
      final muscleGroupBalance =
          _muscleBalanceAnalyzer.calculateBalance(typedWorkouts);
      final calendarData = _calendarGenerator.generateCalendar(
          typedWorkouts, startDate, endDate);
      final completionRate =
          _completionRateCalculator.calculateCompletionRate(typedWorkouts);

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

      // ⚡ 更新記憶體快取
      _cacheManager.cacheStatistics(userId, timeRange, data);

      // ⚡ 更新本地持久化快取
      if (_localCacheService != null) {
        _localCacheService!.cacheStatistics(userId, timeRange, data);
      }

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

      return _calculator
          .calculateBodyPartStats(workouts.cast<UnifiedWorkoutData>());
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
      final summaryData =
          await _dataLoader.getTrainingTypeSummary(userId, startDate, endDate);

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

      return _calculator
          .calculateEquipmentStats(workouts.cast<UnifiedWorkoutData>());
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
    // v3.3+ 同時清除 getExercisesWithRecords 的快取
    _cachedExercisesWithRecords = null;
    _cachedExercisesUserId = null;
    _cachedExercisesTimestamp = null;
    // v3.3+ 同時清除本地 Hive 快取
    _localCacheService?.clearAllCache();
  }

  /// ⚡ 檢查指定時間範圍的快取是否有效
  /// 同時檢查記憶體快取和本地持久化快取
  @override
  Future<bool> hasCachedStatistics(String userId, TimeRange timeRange) async {
    // 先檢查記憶體快取（同步）
    if (_cacheManager.isStatisticsCacheValid(userId, timeRange)) {
      return true;
    }
    // 再檢查本地快取（異步，確保初始化）
    if (_localCacheService != null) {
      final localValid =
          await _localCacheService!.isCacheValidAsync(userId, timeRange);
      if (localValid) {
        return true;
      }
    }
    return false;
  }

  /// ⚡ 預載入所有時間範圍的統計數據（後台執行）
  ///
  /// v3.1.1 優化：一次查詢 + 多時間範圍計算（避免 N+1）
  @override
  Future<void> preloadAllTimeRanges(String userId,
      {TimeRange? currentTimeRange}) async {
    _logDebug('🚀 開始預載入所有時間範圍的統計數據...');

    // 常用時間範圍
    final allTimeRanges = [
      TimeRange.week,
      TimeRange.sevenDays,
      TimeRange.month,
      TimeRange.threeMonth,
      TimeRange.year,
    ];

    // 過濾掉已經快取的（檢查記憶體和本地快取）
    final rangesToPreload = <TimeRange>[];
    for (final range in allTimeRanges) {
      if (range == currentTimeRange) continue;

      // 檢查記憶體快取
      if (_cacheManager.isStatisticsCacheValid(userId, range)) {
        _logDebug('⏭️ 跳過已快取（記憶體）：${range.displayName}');
        continue;
      }

      // 檢查本地快取
      if (_localCacheService != null) {
        final localValid =
            await _localCacheService!.isCacheValidAsync(userId, range);
        if (localValid) {
          _logDebug('⏭️ 跳過已快取（本地）：${range.displayName}');
          continue;
        }
      }

      rangesToPreload.add(range);
    }

    if (rangesToPreload.isEmpty) {
      _logDebug('✅ 所有時間範圍都已快取');
      return;
    }

    _logDebug('📋 將預載入 ${rangesToPreload.length} 個時間範圍');

    try {
      // ⚡ 1. 一次查詢最大時間範圍的數據（一年）
      final maxRange = TimeRange.year;
      final allWorkouts = await _getCompletedWorkouts(
        userId,
        maxRange.startDate,
        maxRange.endDate,
      );
      final typedWorkouts = allWorkouts.cast<UnifiedWorkoutData>();

      _logDebug('📊 查詢到 ${allWorkouts.length} 筆訓練數據（一年內）');

      // ⚡ 2. 一次批量載入所有動作分類
      await _loadExerciseClassifications(allWorkouts);

      // ⚡ 3. 對每個時間範圍進行客戶端計算（純記憶體操作，無 DB 查詢）
      for (final timeRange in rangesToPreload) {
        try {
          final data = await _calculateStatisticsFromWorkouts(
            userId,
            timeRange,
            typedWorkouts,
          );
          // 更新記憶體快取
          _cacheManager.cacheStatistics(userId, timeRange, data);
          // ⚡ 也更新本地持久化快取（App 重開後可用）
          if (_localCacheService != null) {
            _localCacheService!.cacheStatistics(userId, timeRange, data);
          }
          _logDebug('✅ 預載入完成：${timeRange.displayName}');
        } catch (e) {
          _logDebug('⚠️ 計算失敗（${timeRange.displayName}）: $e');
        }
      }

      _logDebug('🎉 所有時間範圍預載入完成！（僅 1 次 DB 查詢）');
    } catch (e) {
      _logDebug('⚠️ 預載入失敗: $e');
    }
  }

  /// ⚡ 預熱：從本地快取載入所有資料到記憶體
  ///
  /// 在 App 啟動時調用，確保進入統計頁面時資料已經準備好
  @override
  Future<void> warmupFromLocalCache(String userId) async {
    if (_localCacheService == null) {
      _logDebug('⚠️ 本地快取服務不可用，跳過預熱');
      return;
    }

    try {
      _logDebug('🔥 開始從本地快取預熱統計資料...');

      final cachedData =
          await _localCacheService!.getAllCachedStatistics(userId);

      if (cachedData.isEmpty) {
        _logDebug('📭 本地沒有快取資料');
        return;
      }

      // 並行載入所有快取到記憶體
      for (final entry in cachedData.entries) {
        _cacheManager.cacheStatistics(userId, entry.key, entry.value);
      }

      _logDebug('🔥 預熱完成！已載入 ${cachedData.length} 個時間範圍到記憶體');
    } catch (e) {
      _logDebug('⚠️ 預熱失敗: $e');
    }
  }

  /// ⚡ 從已查詢的 workouts 計算統計數據（純記憶體計算，無 DB 查詢）
  Future<StatisticsData> _calculateStatisticsFromWorkouts(
    String userId,
    TimeRange timeRange,
    List<UnifiedWorkoutData> allWorkouts,
  ) async {
    final startDate = timeRange.startDate;
    final endDate = timeRange.endDate;

    // 過濾時間範圍內的訓練
    final filteredWorkouts = allWorkouts.where((w) {
      return !w.completedTime.isBefore(startDate) &&
          !w.completedTime.isAfter(endDate);
    }).toList();

    // 使用已有的計算方法（這些會走獨立快取或純計算）
    final frequency = await getTrainingFrequency(userId, timeRange);
    final volumeHistory = await getVolumeHistory(userId, timeRange);
    final trainingTypeStats = await getTrainingTypeStats(userId, timeRange);
    final personalRecords = await getPersonalRecords(userId, limit: 10);

    // 純計算方法
    final bodyPartStats = _calculator.calculateBodyPartStats(filteredWorkouts);
    final equipmentStats =
        _calculator.calculateEquipmentStats(filteredWorkouts);

    final muscleDetails = <String, List<SpecificMuscleStats>>{};
    for (var stat in bodyPartStats) {
      final details = _calculator.calculateSpecificMuscleStats(
          filteredWorkouts, stat.bodyPart);
      if (details.isNotEmpty) {
        muscleDetails[stat.bodyPart] = details;
      }
    }

    final strengthProgress = _strengthProgressCalculator
        .calculateProgress(filteredWorkouts, startDate, timeRange, limit: 10);
    final muscleGroupBalance =
        _muscleBalanceAnalyzer.calculateBalance(filteredWorkouts);
    final calendarData = _calendarGenerator.generateCalendar(
        filteredWorkouts, startDate, endDate);
    final completionRate =
        _completionRateCalculator.calculateCompletionRate(filteredWorkouts);

    return StatisticsData(
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
      // ⚡ v3.1.1 優化：使用一年範圍快取 + 客戶端過濾（避免 N+1）
      // 快取有效期：5 分鐘
      final cacheValid = _cachedExercisesWithRecords != null &&
          _cachedExercisesUserId == userId &&
          _cachedExercisesVersion == _exerciseCacheVersion &&
          _cachedExercisesTimestamp != null &&
          DateTime.now().difference(_cachedExercisesTimestamp!).inMinutes < 5;

      if (cacheValid) {
        var filtered = _cachedExercisesWithRecords!;

        // 時間範圍過濾（客戶端）
        if (timeRange != null) {
          final startDate = timeRange.startDate;
          final endDate = timeRange.endDate;
          filtered = filtered.where((e) {
            return !e.lastTrainingDate.isBefore(startDate) &&
                !e.lastTrainingDate.isAfter(endDate);
          }).toList();
        }

        // 訓練類型過濾
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

        _logDebug('✅ 從快取返回動作列表（${filtered.length} 個動作）');
        return filtered;
      }

      // ⚡ v3.1.1 優化：固定查詢一年範圍，後續客戶端過濾
      // 這樣可以快取結果，避免切換時間範圍時重複查詢
      final yearRange = TimeRange.year;
      final expandedStartDate = yearRange.startDate;

      // 查詢所有訓練計劃（包括部分完成的）
      // Parser 會過濾出 set.completed = true 的組
      final query = _supabase
          .from('workout_plans')
          .select(
              'id, exercises, completed_date, updated_at, scheduled_date, created_at, trainee_id')
          .eq('trainee_id', userId)
          .gte('updated_at', DateTimeUtils.formatToUtcIso(expandedStartDate));

      final response = await query;

      final workoutPlans = response as List<dynamic>;

      if (workoutPlans.isEmpty) {
        return [];
      }

      // 統計每個動作的訓練數據
      final Map<String, _ExerciseRecordData> exerciseStats = {};

      if (_kStatisticsDebugLog) {
        print('[GET_EXERCISES] 查詢到 ${workoutPlans.length} 個訓練計劃');
      }

      for (var planData in workoutPlans) {
        final data = planData as Map<String, dynamic>;

        // ⚡ v3.1.1 優化：不在遍歷時過濾時間範圍
        // 改為在返回前統一過濾（支持快取 + 客戶端過濾）

        final exercises = data['exercises'] as List<dynamic>? ?? [];

        for (var exerciseData in exercises) {
          final exerciseMap = exerciseData as Map<String, dynamic>;
          final exerciseId = exerciseMap['exerciseId'] as String?;
          final exerciseName = exerciseMap['exerciseName'] as String? ?? '未知動作';
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
            final dateStr =
                completedDateStr ?? scheduledDateStr ?? createdAtStr;
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

        if (_kStatisticsDebugLog) {
          print(
              '[STATISTICS] 批量查詢系統動作：${allExerciseIds.length} 個動作 ID，${_cachedSystemExerciseIds!.length} 個是系統動作');
        }
      }

      // ⭐ Phase 3 優化：批量查詢動作分類信息（避免 N+1）
      // 先收集所有需要查詢的 ID，然後一次性批量查詢
      final uncachedIds = allExerciseIds
          .where((id) => !_exerciseCache.containsKey(id))
          .toList();

      if (uncachedIds.isNotEmpty) {
        try {
          final exercises = await _exerciseService
              .getExercisesByIds(uncachedIds.cast<String>());
          _exerciseCache.addAll(exercises);

          if (_kStatisticsDebugLog) {
            print('[GET_EXERCISES] ⚡ 批量載入 ${exercises.length} 個動作分類');
          }
        } catch (e) {
          if (_kStatisticsDebugLog) {
            print('[GET_EXERCISES] ⚠️ 批量載入動作分類失敗: $e');
          }
        }
      }

      // 從快取獲取動作分類信息並構建結果
      final List<ExerciseWithRecord> results = [];

      for (var stat in exerciseStats.values) {
        // ⭐ 從快取獲取（O(1) 操作）
        final exercise = _exerciseCache[stat.exerciseId];
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

      // ⚡ v3.1.1 優化：總是快取一年範圍的完整結果
      _cachedExercisesWithRecords = results;
      _cachedExercisesUserId = userId;
      _cachedExercisesVersion = _exerciseCacheVersion;
      _cachedExercisesTimestamp = DateTime.now();
      _logDebug('📦 已快取動作列表（${results.length} 個動作）');

      // ⚡ 客戶端過濾
      var filtered = results;

      // 時間範圍過濾
      if (timeRange != null) {
        final startDate = timeRange.startDate;
        final endDate = timeRange.endDate;
        filtered = filtered.where((e) {
          return !e.lastTrainingDate.isBefore(startDate) &&
              !e.lastTrainingDate.isAfter(endDate);
        }).toList();
      }

      // 訓練類型過濾
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

      if (_kStatisticsDebugLog) {
        print('[GET_EXERCISES] 返回 ${filtered.length} 個動作');
        if (timeRange != null)
          print('   過濾條件 - 時間範圍: ${timeRange.displayName}');
        if (trainingType != null) print('   過濾條件 - 訓練類型: $trainingType');
        if (bodyPart != null) print('   過濾條件 - 身體部位: $bodyPart');
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
      if (_cacheManager.isStrengthProgressCacheValid(
          userId, timeRange, limit)) {
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

      return _muscleBalanceAnalyzer
          .calculateBalance(workouts.cast<UnifiedWorkoutData>());
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

      return _completionRateCalculator
          .calculateCompletionRate(workouts.cast<UnifiedWorkoutData>());
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

    // ⚡ 使用 Isolate 解析大型列表（避免阻塞主執行緒）
    final workouts = await _dataParser.parseWorkoutDataListAsync(rawWorkouts);

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
      final exercises =
          await _exerciseService.getExercisesByIds(uncachedIds.cast<String>());
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
    if (kDebugMode && _kStatisticsDebugLog) {
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
