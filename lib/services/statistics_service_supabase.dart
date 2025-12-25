import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/statistics_model.dart';
import '../models/exercise_model.dart';
import '../models/favorite_exercise_model.dart';
import 'interfaces/i_statistics_service.dart';
import 'interfaces/i_exercise_service.dart';
import 'error_handling_service.dart';

/// 統計服務 Supabase 實作
///
/// 提供訓練數據統計和分析功能（Supabase PostgreSQL 版本）
class StatisticsServiceSupabase implements IStatisticsService {
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;
  final IExerciseService _exerciseService;

  // 動作分類快取（exerciseId -> Exercise）
  final Map<String, Exercise> _exerciseCache = {};

  // 統計數據快取
  Map<String, dynamic>? _statisticsCache;
  DateTime? _cacheTime;
  String? _cachedUserId;
  TimeRange? _cachedTimeRange;

  StatisticsServiceSupabase({
    required SupabaseClient supabase,
    required ErrorHandlingService errorService,
    required IExerciseService exerciseService,
  })  : _supabase = supabase,
        _errorService = errorService,
        _exerciseService = exerciseService;

  @override
  Future<StatisticsData> getStatistics(String userId, TimeRange timeRange) async {
    try {
      // 暫時停用快取，每次都重新載入以確保數據最新
      // 如果性能有問題，可以改為較短的快取時間（例如 5 分鐘）

      // 獲取各項統計
      final frequency = await getTrainingFrequency(userId, timeRange);
      final volumeHistory = await getVolumeHistory(userId, timeRange);
      final bodyPartStats = await getBodyPartStats(userId, timeRange);
      final trainingTypeStats = await getTrainingTypeStats(userId, timeRange);
      final equipmentStats = await getEquipmentStats(userId, timeRange);
      final personalRecords = await getPersonalRecords(userId, limit: 10);

      // 獲取特定肌群細節
      final muscleDetails = <String, List<SpecificMuscleStats>>{};
      for (var stat in bodyPartStats) {
        final details = await getSpecificMuscleStats(userId, stat.bodyPart, timeRange);
        if (details.isNotEmpty) {
          muscleDetails[stat.bodyPart] = details;
        }
      }

      // 獲取新的統計數據
      final strengthProgress = await getStrengthProgress(userId, timeRange, limit: 10);
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

      // 更新快取
      _updateStatisticsCache(userId, timeRange, data);

      return data;
    } catch (e) {
      _errorService.logError('載入統計數據失敗: $e', type: 'StatisticsServiceError');
      return StatisticsData.empty(timeRange);
    }
  }

  @override
  Future<TrainingFrequency> getTrainingFrequency(String userId, TimeRange timeRange) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;

      // 查詢當前時間範圍的訓練
      final currentWorkouts = await _getCompletedWorkouts(userId, startDate, endDate);
      final totalWorkouts = currentWorkouts.length;

      // 計算總訓練時長（估算：每個訓練 1 小時）
      final totalHours = totalWorkouts.toDouble();
      final averageHours = totalWorkouts > 0 ? totalHours / totalWorkouts : 0.0;

      // 計算連續訓練天數
      final consecutiveDays = _calculateConsecutiveDays(currentWorkouts);

      // 計算與上期對比
      final previousStart = _getPreviousPeriodStart(timeRange);
      final previousWorkouts = await _getCompletedWorkouts(userId, previousStart, startDate);
      final comparisonValue = totalWorkouts - previousWorkouts.length;

      return TrainingFrequency(
        totalWorkouts: totalWorkouts,
        totalHours: totalHours,
        averageHours: averageHours,
        consecutiveDays: consecutiveDays,
        comparisonValue: comparisonValue,
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
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      // 按日期分組
      final Map<String, List<_UnifiedWorkoutData>> workoutsByDate = {};
      for (var workout in workouts) {
        final dateKey = _getDateKey(workout.completedTime);
        workoutsByDate.putIfAbsent(dateKey, () => []).add(workout);
      }

      // 載入動作分類
      await _loadExerciseClassifications(workouts);

      // 計算每日訓練量
      final points = <TrainingVolumePoint>[];
      workoutsByDate.forEach((dateKey, dayWorkouts) {
        double totalVolume = 0;
        int totalSets = 0;

        for (var workout in dayWorkouts) {
          for (var exercise in workout.exercises) {
            if (exercise.isCompleted) {
              totalVolume += exercise.weight * exercise.reps * exercise.sets;
              totalSets += exercise.sets;
            }
          }
        }

        final date = DateTime.parse(dateKey);
        points.add(TrainingVolumePoint(
          date: date,
          totalVolume: totalVolume,
          totalSets: totalSets,
          workoutCount: dayWorkouts.length,
        ));
      });

      // 按日期排序
      points.sort((a, b) => a.date.compareTo(b.date));

      return points;
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

      // 統計各身體部位
      final Map<String, _BodyPartAccumulator> stats = {};

      for (var workout in workouts) {
        for (var exercise in workout.exercises) {
          if (!exercise.isCompleted) continue;

          // 從快取獲取動作分類
          final exerciseInfo = _exerciseCache[exercise.exerciseId];
          if (exerciseInfo == null) continue;

          final bodyPart = exerciseInfo.bodyPart;
          if (bodyPart.isEmpty) continue;

          final volume = exercise.weight * exercise.reps * exercise.sets;

          stats.putIfAbsent(
            bodyPart,
            () => _BodyPartAccumulator(bodyPart: bodyPart),
          );
          stats[bodyPart]!.addExercise(volume);
        }
      }

      // 計算總訓練量
      final totalVolume = stats.values.fold<double>(
        0,
        (sum, stat) => sum + stat.totalVolume,
      );

      // 轉換為 BodyPartStats 列表
      final result = stats.values.map((accumulator) {
        return BodyPartStats(
          bodyPart: accumulator.bodyPart,
          totalVolume: accumulator.totalVolume,
          workoutCount: accumulator.exerciseCount,
          exerciseCount: accumulator.exerciseCount,
          percentage: totalVolume > 0 ? accumulator.totalVolume / totalVolume : 0,
        );
      }).toList();

      // 按訓練量排序
      result.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));

      return result;
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

      // 統計特定肌群
      final Map<String, _MuscleAccumulator> stats = {};
      double totalVolumeForBodyPart = 0;

      for (var workout in workouts) {
        for (var exercise in workout.exercises) {
          if (!exercise.isCompleted) continue;

          final exerciseInfo = _exerciseCache[exercise.exerciseId];
          if (exerciseInfo == null || exerciseInfo.bodyPart != bodyPart) continue;

          final specificMuscle = exerciseInfo.specificMuscle;
          if (specificMuscle.isEmpty) continue;

          final volume = exercise.weight * exercise.reps * exercise.sets;
          totalVolumeForBodyPart += volume;

          stats.putIfAbsent(
            specificMuscle,
            () => _MuscleAccumulator(muscleGroup: specificMuscle),
          );
          stats[specificMuscle]!.addExercise(volume);
        }
      }

      if (stats.isEmpty) return [];

      // 轉換為 SpecificMuscleStats 列表
      final result = stats.values.map((accumulator) {
        return SpecificMuscleStats(
          specificMuscle: accumulator.muscleGroup,
          totalVolume: accumulator.totalVolume,
          workoutCount: accumulator.exerciseCount,
          percentage: totalVolumeForBodyPart > 0
              ? accumulator.totalVolume / totalVolumeForBodyPart
              : 0,
        );
      }).toList();

      // 按訓練量排序
      result.sort((a, b) => b.totalVolume.compareTo(a.totalVolume));

      return result;
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
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      if (workouts.isEmpty) return [];

      // 載入動作分類
      await _loadExerciseClassifications(workouts);

      // 統計訓練類型
      final Map<String, int> stats = {};
      int totalExercises = 0;

      for (var workout in workouts) {
        for (var exercise in workout.exercises) {
          if (!exercise.isCompleted) continue;

          final exerciseInfo = _exerciseCache[exercise.exerciseId];
          if (exerciseInfo == null) continue;

          final trainingType = exerciseInfo.trainingType;
          if (trainingType.isEmpty) continue;

          stats[trainingType] = (stats[trainingType] ?? 0) + 1;
          totalExercises++;
        }
      }

      if (stats.isEmpty) return [];

      // 轉換為 TrainingTypeStats 列表
      final result = stats.entries.map((entry) {
        return TrainingTypeStats(
          trainingType: entry.key,
          workoutCount: entry.value,
          percentage: totalExercises > 0 ? entry.value / totalExercises : 0,
        );
      }).toList();

      // 按次數排序
      result.sort((a, b) => b.workoutCount.compareTo(a.workoutCount));

      return result;
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

      // 統計器材類別
      final Map<String, int> stats = {};
      int totalExercises = 0;

      for (var workout in workouts) {
        for (var exercise in workout.exercises) {
          if (!exercise.isCompleted) continue;

          final exerciseInfo = _exerciseCache[exercise.exerciseId];
          if (exerciseInfo == null) continue;

          final equipmentCategory = exerciseInfo.equipmentCategory;
          if (equipmentCategory.isEmpty) continue;

          stats[equipmentCategory] = (stats[equipmentCategory] ?? 0) + 1;
          totalExercises++;
        }
      }

      if (stats.isEmpty) return [];

      // 轉換為 EquipmentStats 列表
      final result = stats.entries.map((entry) {
        return EquipmentStats(
          equipment: entry.key,
          usageCount: entry.value,
          percentage: totalExercises > 0 ? entry.value / totalExercises : 0,
        );
      }).toList();

      // 按使用次數排序
      result.sort((a, b) => b.usageCount.compareTo(a.usageCount));

      return result;
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
    try {
      // 獲取所有已完成的訓練
      final allWorkouts = await _getAllCompletedWorkouts(userId);

      if (allWorkouts.isEmpty) return [];

      // 載入動作分類
      await _loadExerciseClassifications(allWorkouts);

      // 找出每個動作的最大重量
      final Map<String, PersonalRecord> records = {};

      for (var workout in allWorkouts) {
        for (var exercise in workout.exercises) {
          if (!exercise.isCompleted || exercise.weight == 0) continue;

          final exerciseId = exercise.exerciseId;
          final currentRecord = records[exerciseId];

          // 獲取動作信息
          final exerciseInfo = _exerciseCache[exerciseId];
          final bodyPart = exerciseInfo?.bodyPart ?? '';

          // 判斷是否為新記錄
          if (currentRecord == null || exercise.weight > currentRecord.maxWeight) {
            // 檢查是否為本週內達成
            final isNew = workout.completedTime.isAfter(
              DateTime.now().subtract(Duration(days: 7)),
            );

            records[exerciseId] = PersonalRecord(
              exerciseId: exerciseId,
              exerciseName: exercise.exerciseName,
              maxWeight: exercise.weight,
              reps: exercise.reps,
              achievedDate: workout.completedTime,
              bodyPart: bodyPart,
              isNew: isNew,
            );
          }
        }
      }

      // 轉換為列表並按重量排序
      final result = records.values.toList();
      result.sort((a, b) => b.maxWeight.compareTo(a.maxWeight));

      // 限制返回數量
      return result.take(limit).toList();
    } catch (e) {
      _errorService.logError('獲取個人記錄失敗: $e', type: 'StatisticsServiceError');
      return [];
    }
  }

  @override
  List<TrainingSuggestion> getTrainingSuggestions(StatisticsData statisticsData) {
    final suggestions = <TrainingSuggestion>[];

    // 檢查訓練頻率
    if (statisticsData.frequency.totalWorkouts < 3) {
      suggestions.add(TrainingSuggestion(
        title: '訓練頻率偏低',
        description: '建議每週至少訓練 3-4 次以獲得最佳效果',
        type: SuggestionType.warning,
      ));
    } else if (statisticsData.frequency.totalWorkouts >= 5) {
      suggestions.add(TrainingSuggestion(
        title: '訓練頻率優秀',
        description: '保持良好的訓練習慣！',
        type: SuggestionType.success,
      ));
    }

    // 檢查肌群平衡
    if (statisticsData.bodyPartStats.isNotEmpty) {
      final sortedStats = List<BodyPartStats>.from(statisticsData.bodyPartStats);
      sortedStats.sort((a, b) => a.percentage.compareTo(b.percentage));

      final lowest = sortedStats.first;
      if (lowest.percentage < 0.1 && lowest.workoutCount > 0) {
        suggestions.add(TrainingSuggestion(
          title: '${lowest.bodyPart}訓練較少',
          description: '建議增加${lowest.bodyPart}的訓練頻率，保持全面發展',
          type: SuggestionType.warning,
        ));
      }
    }

    // 檢查訓練類型多樣性
    final trainingTypes = statisticsData.trainingTypeStats;
    final hasCardio = trainingTypes.any((t) => t.trainingType == '有氧');
    final hasStretching = trainingTypes.any((t) => t.trainingType == '伸展');

    if (!hasCardio && !hasStretching) {
      suggestions.add(TrainingSuggestion(
        title: '建議增加有氧和伸展',
        description: '在重訓之外，適當的有氧和伸展可以提升整體健康',
        type: SuggestionType.info,
      ));
    }

    return suggestions;
  }

  @override
  void clearCache() {
    _statisticsCache = null;
    _cacheTime = null;
    _cachedUserId = null;
    _cachedTimeRange = null;
    _exerciseCache.clear();
  }

  @override
  Future<List<ExerciseWithRecord>> getExercisesWithRecords(
    String userId, {
    String? trainingType,
    String? bodyPart,
    String? specificMuscle,
    String? equipmentCategory,
  }) async {
    try {
      // 查詢所有已完成的訓練計劃（Supabase 版本）
      final response = await _supabase
          .from('workout_plans')
          .select()
          .eq('trainee_id', userId)
          .eq('completed', true);

      final workoutPlans = response as List<dynamic>;
      
      if (workoutPlans.isEmpty) {
        return [];
      }
      
      // 統計每個動作的訓練數據
      final Map<String, _ExerciseRecordData> exerciseStats = {};
      
      for (var planData in workoutPlans) {
        final data = planData as Map<String, dynamic>;
        final exercises = data['exercises'] as List<dynamic>? ?? [];
        
        for (var exerciseData in exercises) {
          final exerciseMap = exerciseData as Map<String, dynamic>;
          final exerciseId = exerciseMap['exerciseId'] as String?;
          final exerciseName = exerciseMap['exerciseName'] as String? ?? '未知動作';
          final sets = exerciseMap['sets'] as List<dynamic>? ?? [];
          
          if (exerciseId == null) continue;
          
          // 累計訓練數據
          if (!exerciseStats.containsKey(exerciseId)) {
            exerciseStats[exerciseId] = _ExerciseRecordData(
              exerciseId: exerciseId,
              exerciseName: exerciseName,
              lastTrainingDate: DateTime.parse(data['updated_at'] as String),
              maxWeight: 0,
              totalSets: 0,
            );
          }
          
          final stat = exerciseStats[exerciseId]!;
          stat.totalSets += sets.length;
          
          // 更新最後訓練日期
          final updatedAt = DateTime.parse(data['updated_at'] as String);
          if (updatedAt.isAfter(stat.lastTrainingDate)) {
            stat.lastTrainingDate = updatedAt;
          }
          
          // 計算最大重量
          for (var set in sets) {
            final setMap = set as Map<String, dynamic>;
            final isCompleted = setMap['completed'] as bool? ?? false;
            if (isCompleted) {
              final weight = (setMap['weight'] as num?)?.toDouble() ?? 0;
              if (weight > stat.maxWeight) {
                stat.maxWeight = weight;
              }
            }
          }
        }
      }
      
      // 獲取動作分類信息並過濾
      final List<ExerciseWithRecord> results = [];
      
      for (var stat in exerciseStats.values) {
        // 獲取動作詳細信息
        final exercise = await _getExerciseInfo(stat.exerciseId);
        if (exercise == null) continue;
        
        // 根據篩選條件過濾
        if (trainingType != null && exercise.trainingType != trainingType) continue;
        if (bodyPart != null && exercise.bodyPart != bodyPart) continue;
        if (specificMuscle != null && exercise.specificMuscle != specificMuscle) continue;
        if (equipmentCategory != null && exercise.equipmentCategory != equipmentCategory) continue;
        
        results.add(ExerciseWithRecord(
          exerciseId: stat.exerciseId,
          exerciseName: stat.exerciseName,
          bodyPart: exercise.bodyPart.isNotEmpty ? exercise.bodyPart : '其他',
          trainingType: exercise.trainingType.isNotEmpty ? exercise.trainingType : '重訓',
          lastTrainingDate: stat.lastTrainingDate,
          maxWeight: stat.maxWeight,
          totalSets: stat.totalSets,
        ));
      }
      
      // 按最後訓練日期排序（最近的在前）
      results.sort((a, b) => b.lastTrainingDate.compareTo(a.lastTrainingDate));
      
      return results;
    } catch (e) {
      _errorService.logError('獲取有記錄的動作列表失敗: $e');
      return [];
    }
  }

  // ========== 私有輔助方法 ==========

  /// 獲取動作詳細信息（內部使用）
  Future<Exercise?> _getExerciseInfo(String exerciseId) async {
    // 檢查快取
    if (_exerciseCache.containsKey(exerciseId)) {
      return _exerciseCache[exerciseId];
    }

    // 從服務載入
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

  /// 查詢已完成的訓練（轉換為統一格式）- Supabase 版本
  Future<List<_UnifiedWorkoutData>> _getCompletedWorkouts(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // 查詢所有已完成的訓練（Supabase）
      final response = await _supabase
          .from('workout_plans')
          .select()
          .eq('trainee_id', userId)
          .eq('completed', true)
          .gte('updated_at', startDate.toIso8601String())
          .lte('updated_at', endDate.add(Duration(days: 1)).toIso8601String());

      final docs = response as List<dynamic>;

      // 解析並轉換為統一格式
      final List<_UnifiedWorkoutData> workouts = [];
      for (var doc in docs) {
        try {
          final data = doc as Map<String, dynamic>;
          final workout = _parseWorkoutData(data['id'] as String, data);
          workouts.add(workout);
        } catch (e) {
          _errorService.logError('解析訓練記錄失敗: $e', type: 'StatisticsServiceError');
        }
      }

      return workouts;
    } catch (e) {
      _errorService.logError('查詢已完成訓練失敗: $e', type: 'StatisticsServiceError');
      rethrow;
    }
  }

  /// 解析訓練數據並轉換為統一格式
  _UnifiedWorkoutData _parseWorkoutData(String id, Map<String, dynamic> data) {
    final exercises = <_UnifiedExerciseData>[];
    final exercisesData = data['exercises'] as List<dynamic>? ?? [];
    
    for (var exerciseData in exercisesData) {
      try {
        if (exerciseData is! Map<String, dynamic>) continue;
        
        // 檢查是新格式（包含 sets 數組）還是舊格式
        if (exerciseData['sets'] is List) {
          // 新格式：ExerciseRecord with SetRecord array
          final setsData = exerciseData['sets'] as List<dynamic>;
          for (var setData in setsData) {
            if (setData is! Map<String, dynamic>) continue;
            
            final completed = setData['completed'] as bool? ?? false;
            if (!completed) continue;
            
            exercises.add(_UnifiedExerciseData(
              exerciseId: exerciseData['exerciseId'] ?? '',
              exerciseName: exerciseData['exerciseName'] ?? exerciseData['name'] ?? '',
              weight: (setData['weight'] as num?)?.toDouble() ?? 0.0,
              reps: setData['reps'] as int? ?? 0,
              sets: 1, // 每個 SetRecord 算一組
              isCompleted: true,
            ));
          }
        } else {
          // 舊格式：WorkoutExercise with simple sets/reps/weight
          exercises.add(_UnifiedExerciseData(
            exerciseId: exerciseData['exerciseId'] ?? '',
            exerciseName: exerciseData['name'] ?? '',
            weight: (exerciseData['weight'] as num?)?.toDouble() ?? 0.0,
            reps: exerciseData['reps'] as int? ?? 0,
            sets: exerciseData['sets'] as int? ?? 0,
            isCompleted: exerciseData['isCompleted'] as bool? ?? false,
          ));
        }
      } catch (e) {
        _errorService.logError('解析動作數據失敗: $e', type: 'StatisticsServiceError');
      }
    }
    
    return _UnifiedWorkoutData(
      id: id,
      title: data['title'] ?? '未命名訓練',
      completedTime: data['completed_date'] != null 
          ? DateTime.parse(data['completed_date'] as String)
          : (data['scheduled_date'] != null 
              ? DateTime.parse(data['scheduled_date'] as String)
              : DateTime.parse(data['updated_at'] as String)),
      exercises: exercises,
    );
  }

  /// 查詢所有已完成的訓練（不限時間）- Supabase 版本
  Future<List<_UnifiedWorkoutData>> _getAllCompletedWorkouts(String userId) async {
    final response = await _supabase
        .from('workout_plans')
        .select()
        .eq('trainee_id', userId)
        .eq('completed', true);

    final docs = response as List<dynamic>;

    final List<_UnifiedWorkoutData> workouts = [];
    for (var doc in docs) {
      try {
        final data = doc as Map<String, dynamic>;
        workouts.add(_parseWorkoutData(data['id'] as String, data));
      } catch (e) {
        _errorService.logError('解析訓練記錄失敗: $e', type: 'StatisticsServiceError');
      }
    }
    
    return workouts;
  }

  /// 批量載入動作分類信息
  Future<void> _loadExerciseClassifications(List<_UnifiedWorkoutData> workouts) async {
    final exerciseIds = workouts
        .expand((w) => w.exercises)
        .map((e) => e.exerciseId)
        .toSet()
        .toList();

    for (var id in exerciseIds) {
      if (_exerciseCache.containsKey(id)) continue;

      try {
        final exercise = await _exerciseService.getExerciseById(id);
        if (exercise != null) {
          _exerciseCache[id] = exercise;
        }
      } catch (e) {
        // 忽略單個動作載入失敗
        _errorService.logError('載入動作分類失敗 ($id): $e');
      }
    }
  }

  /// 載入單個動作分類信息
  Future<Exercise?> _loadExerciseClassification(String exerciseId) async {
    // 先從快取查找
    if (_exerciseCache.containsKey(exerciseId)) {
      return _exerciseCache[exerciseId];
    }

    // 從服務載入
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

  /// 計算連續訓練天數
  int _calculateConsecutiveDays(List<_UnifiedWorkoutData> workouts) {
    if (workouts.isEmpty) return 0;

    // 提取訓練日期（去重）
    final dates = workouts
        .map((w) => DateTime(
              w.completedTime.year,
              w.completedTime.month,
              w.completedTime.day,
            ))
        .toSet()
        .toList();

    dates.sort((a, b) => b.compareTo(a)); // 降序排列

    int consecutive = 0;
    DateTime? previousDate;

    for (var date in dates) {
      if (previousDate == null) {
        consecutive = 1;
      } else {
        final diff = previousDate.difference(date).inDays;
        if (diff == 1) {
          consecutive++;
        } else {
          break;
        }
      }
      previousDate = date;
    }

    return consecutive;
  }

  /// 獲取日期鍵（YYYY-MM-DD）
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 獲取上一個時間範圍的起始日期
  DateTime _getPreviousPeriodStart(TimeRange timeRange) {
    final startDate = timeRange.startDate;
    final endDate = timeRange.endDate;
    final duration = endDate.difference(startDate);
    return startDate.subtract(duration);
  }

  /// 檢查統計快取是否有效（1 小時）
  bool _isStatisticsCacheValid(String userId, TimeRange timeRange) {
    if (_statisticsCache == null ||
        _cacheTime == null ||
        _cachedUserId != userId ||
        _cachedTimeRange != timeRange) {
      return false;
    }

    final age = DateTime.now().difference(_cacheTime!);
    return age.inHours < 1;
  }

  /// 從快取創建統計數據
  StatisticsData _fromCache(Map<String, dynamic> cache) {
    // 這裡簡化處理，實際應用中可以序列化/反序列化
    return cache['data'] as StatisticsData;
  }

  /// 更新統計快取
  void _updateStatisticsCache(String userId, TimeRange timeRange, StatisticsData data) {
    _statisticsCache = {'data': data};
    _cacheTime = DateTime.now();
    _cachedUserId = userId;
    _cachedTimeRange = timeRange;
  }

  @override
  Future<List<ExerciseStrengthProgress>> getStrengthProgress(
    String userId,
    TimeRange timeRange, {
    int limit = 10,
  }) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;

      // 獲取訓練數據
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      // 按動作ID分組
      final Map<String, List<_ExercisePerformance>> exercisePerformances = {};

      for (var workout in workouts) {
        for (var exercise in workout.exercises) {
          if (!exercise.isCompleted) continue;

          final key = exercise.exerciseId;
          exercisePerformances.putIfAbsent(key, () => []);

          exercisePerformances[key]!.add(_ExercisePerformance(
            date: workout.completedTime,
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.exerciseName,
            weight: exercise.weight,
            reps: exercise.reps,
            sets: exercise.sets,
          ));
        }
      }

      // 計算每個動作的力量進步
      final List<ExerciseStrengthProgress> progressList = [];

      for (var entry in exercisePerformances.entries) {
        final performances = entry.value;
        if (performances.isEmpty) continue;

        // 排序（按日期）
        performances.sort((a, b) => a.date.compareTo(b.date));

        // 計算力量曲線
        final history = <StrengthProgressPoint>[];
        double maxWeight = 0;

        for (var perf in performances) {
          final oneRM = _calculateOneRM(perf.weight, perf.reps);
          final isPR = perf.weight > maxWeight;
          if (isPR) maxWeight = perf.weight;

          history.add(StrengthProgressPoint(
            date: perf.date,
            weight: perf.weight,
            reps: perf.reps,
            estimatedOneRM: oneRM,
            isPR: isPR,
          ));
        }

        // 計算進步百分比（與上一期對比）
        final previousStart = _getPreviousPeriodStart(timeRange);
        final previousPerformances = performances
            .where((p) => p.date.isAfter(previousStart) && p.date.isBefore(startDate))
            .toList();

        final previousMax = previousPerformances.isEmpty
            ? 0.0
            : previousPerformances.map((p) => p.weight).reduce((a, b) => a > b ? a : b);

        final progressPercentage = previousMax > 0 
            ? ((maxWeight - previousMax) / previousMax * 100) 
            : 0.0;

        // 載入動作資訊
        final exercise = await _loadExerciseClassification(performances.first.exerciseId);
        final bodyPart = exercise?.bodyPart.isNotEmpty == true 
            ? exercise!.bodyPart 
            : '未分類';

        // 計算平均重量和總組數
        final totalWeight = performances.fold<double>(0.0, (sum, p) => sum + p.weight * p.sets);
        final totalSets = performances.fold<int>(0, (sum, p) => sum + p.sets);
        final averageWeight = totalSets > 0 ? totalWeight.toDouble() / totalSets.toDouble() : 0.0;

        progressList.add(ExerciseStrengthProgress(
          exerciseId: entry.key,
          exerciseName: performances.first.exerciseName,
          bodyPart: bodyPart,
          history: history,
          currentMax: maxWeight,
          previousMax: previousMax,
          progressPercentage: progressPercentage,
          totalSets: totalSets,
          averageWeight: averageWeight,
        ));
      }

      // 按進步百分比排序，取前 N 個
      progressList.sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
      return progressList.take(limit).toList();
    } catch (e) {
      _errorService.logError('計算力量進步失敗: $e', type: 'StatisticsServiceError');
      return [];
    }
  }

  @override
  Future<MuscleGroupBalance> getMuscleGroupBalance(String userId, TimeRange timeRange) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;

      // 獲取訓練數據
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      // 按肌群類別統計
      final Map<MuscleGroupCategory, _MuscleGroupAccumulator> accumulators = {
        MuscleGroupCategory.push: _MuscleGroupAccumulator(),
        MuscleGroupCategory.pull: _MuscleGroupAccumulator(),
        MuscleGroupCategory.legs: _MuscleGroupAccumulator(),
        MuscleGroupCategory.core: _MuscleGroupAccumulator(),
        MuscleGroupCategory.other: _MuscleGroupAccumulator(),
      };

      for (var workout in workouts) {
        for (var exercise in workout.exercises) {
          if (!exercise.isCompleted) continue;

          // 載入動作分類
          final exerciseData = await _loadExerciseClassification(exercise.exerciseId);
          final bodyPart = exerciseData?.bodyPart.isNotEmpty == true 
              ? exerciseData!.bodyPart 
              : '';

          // 判斷肌群類別
          final category = _categorizeMuscleGroup(bodyPart);
          final volume = (exercise.weight * exercise.reps * exercise.sets).toDouble();

          accumulators[category]!.addExercise(
            exercise.exerciseName,
            volume,
          );
        }
      }

      // 計算總訓練量
      final totalVolume = accumulators.values.fold<double>(
        0.0, 
        (sum, acc) => sum + acc.totalVolume,
      );

      // 生成統計列表
      final stats = <MuscleGroupBalanceStats>[];
      for (var entry in accumulators.entries) {
        if (entry.value.totalVolume == 0) continue;

        final percentage = totalVolume > 0 ? (entry.value.totalVolume / totalVolume).toDouble() : 0.0;
        stats.add(MuscleGroupBalanceStats(
          category: entry.key,
          totalVolume: entry.value.totalVolume,
          workoutCount: entry.value.workoutCount,
          exerciseCount: entry.value.exerciseCount,
          percentage: percentage,
          topExercises: entry.value.topExercises,
        ));
      }

      // 計算推拉比例
      final pushVolume = accumulators[MuscleGroupCategory.push]!.totalVolume;
      final pullVolume = accumulators[MuscleGroupCategory.pull]!.totalVolume;
      final pushPullRatio = pullVolume > 0 ? (pushVolume / pullVolume).toDouble() : 0.0;

      // 判斷是否平衡（推拉比例在 0.8-1.2 之間為平衡）
      final isPushPullBalanced = pushPullRatio >= 0.8 && pushPullRatio <= 1.2;

      // 生成平衡狀態描述和建議
      String balanceStatus;
      List<String> recommendations = [];

      if (isPushPullBalanced) {
        balanceStatus = '推拉平衡良好';
      } else if (pushPullRatio > 1.2) {
        balanceStatus = '推動作過多';
        recommendations.add('增加拉動作訓練（背部、二頭肌）');
      } else {
        balanceStatus = '拉動作過多';
        recommendations.add('增加推動作訓練（胸部、肩膀、三頭肌）');
      }

      // 檢查腿部訓練
      final legPercentage = totalVolume > 0 
          ? accumulators[MuscleGroupCategory.legs]!.totalVolume / totalVolume 
          : 0.0;
      if (legPercentage < 0.15) {
        recommendations.add('腿部訓練不足，建議增加深蹲、硬舉等動作');
      }

      return MuscleGroupBalance(
        stats: stats,
        isPushPullBalanced: isPushPullBalanced,
        pushPullRatio: pushPullRatio,
        balanceStatus: balanceStatus,
        recommendations: recommendations,
      );
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
  Future<TrainingCalendarData> getTrainingCalendar(String userId, TimeRange timeRange) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;

      // 獲取訓練數據
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      // 按日期分組
      final Map<String, List<_UnifiedWorkoutData>> workoutsByDate = {};
      for (var workout in workouts) {
        final dateKey = _getDateKey(workout.completedTime);
        workoutsByDate.putIfAbsent(dateKey, () => []);
        workoutsByDate[dateKey]!.add(workout);
      }

      // 生成日曆數據
      final List<TrainingCalendarDay> days = [];
      DateTime currentDate = startDate;

      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        final dateKey = _getDateKey(currentDate);
        final dayWorkouts = workoutsByDate[dateKey] ?? [];
        final hasWorkout = dayWorkouts.isNotEmpty;

        double totalVolume = 0;
        Set<String> bodyParts = {};

        for (var workout in dayWorkouts) {
          for (var exercise in workout.exercises) {
            if (!exercise.isCompleted) continue;

            totalVolume += exercise.weight * exercise.reps * exercise.sets;

            // 載入身體部位
            final exerciseData = await _loadExerciseClassification(exercise.exerciseId);
            if (exerciseData?.bodyPart.isNotEmpty == true) {
              bodyParts.add(exerciseData!.bodyPart);
            }
          }
        }

        // 計算強度等級（0-4）
        int intensity = 0;
        if (totalVolume > 0) {
          if (totalVolume > 10000) intensity = 4;
          else if (totalVolume > 7000) intensity = 3;
          else if (totalVolume > 4000) intensity = 2;
          else intensity = 1;
        }

        days.add(TrainingCalendarDay(
          date: currentDate,
          hasWorkout: hasWorkout,
          workoutCount: dayWorkouts.length,
          totalVolume: totalVolume,
          intensity: intensity,
          bodyParts: bodyParts.toList(),
        ));

        currentDate = currentDate.add(const Duration(days: 1));
      }

      // 計算連續訓練天數
      int currentStreak = 0;
      int maxStreak = 0;
      int tempStreak = 0;

      for (var i = days.length - 1; i >= 0; i--) {
        if (days[i].hasWorkout) {
          tempStreak++;
          if (i == days.length - 1) {
            currentStreak = tempStreak;
          }
          if (tempStreak > maxStreak) {
            maxStreak = tempStreak;
          }
        } else {
          if (i == days.length - 1) {
            currentStreak = 0;
          }
          tempStreak = 0;
        }
      }

      // 計算統計
      final trainingDays = days.where((d) => d.hasWorkout).toList();
      final totalRestDays = days.length - trainingDays.length;
      final averageVolume = trainingDays.isEmpty
          ? 0.0
          : trainingDays.fold<double>(0, (sum, d) => sum + d.totalVolume) / trainingDays.length;

      return TrainingCalendarData(
        days: days,
        maxStreak: maxStreak,
        currentStreak: currentStreak,
        averageVolume: averageVolume,
        totalRestDays: totalRestDays,
      );
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
  Future<CompletionRateStats> getCompletionRate(String userId, TimeRange timeRange) async {
    try {
      final startDate = timeRange.startDate;
      final endDate = timeRange.endDate;

      // 獲取訓練數據
      final workouts = await _getCompletedWorkouts(userId, startDate, endDate);

      int totalPlannedSets = 0;
      int completedSets = 0;
      Map<String, int> incompleteExercises = {};

      for (var workout in workouts) {
        for (var exercise in workout.exercises) {
          totalPlannedSets += exercise.sets;
          
          if (exercise.isCompleted) {
            completedSets += exercise.sets;
          } else {
            final failedSets = exercise.sets;
            incompleteExercises.update(
              exercise.exerciseName,
              (value) => value + failedSets,
              ifAbsent: () => failedSets,
            );
          }
        }
      }

      final failedSets = totalPlannedSets - completedSets;
      final completionRate = totalPlannedSets > 0 
          ? completedSets / totalPlannedSets 
          : 1.0;

      // 找出弱點動作（失敗次數最多的）
      final weakPoints = incompleteExercises.entries
          .where((e) => e.value > 2)
          .map((e) => e.key)
          .toList();

      return CompletionRateStats(
        totalPlannedSets: totalPlannedSets,
        completedSets: completedSets,
        failedSets: failedSets,
        completionRate: completionRate,
        incompleteExercises: incompleteExercises,
        weakPoints: weakPoints,
      );
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

  /// 計算 1RM（使用 Epley 公式）
  double _calculateOneRM(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

  /// 將身體部位分類到肌群類別
  MuscleGroupCategory _categorizeMuscleGroup(String bodyPart) {
    final part = bodyPart.toLowerCase();
    
    // 推動作
    if (part.contains('胸') || part.contains('肩') || 
        (part.contains('手') && part.contains('三頭'))) {
      return MuscleGroupCategory.push;
    }
    
    // 拉動作
    if (part.contains('背') || (part.contains('手') && part.contains('二頭'))) {
      return MuscleGroupCategory.pull;
    }
    
    // 腿部
    if (part.contains('腿') || part.contains('臀')) {
      return MuscleGroupCategory.legs;
    }
    
    // 核心
    if (part.contains('核心') || part.contains('腹')) {
      return MuscleGroupCategory.core;
    }
    
    return MuscleGroupCategory.other;
  }
}

/// 身體部位累加器（內部使用）
class _BodyPartAccumulator {
  final String bodyPart;
  double totalVolume = 0;
  int exerciseCount = 0;

  _BodyPartAccumulator({required this.bodyPart});

  void addExercise(double volume) {
    totalVolume += volume;
    exerciseCount++;
  }
}

/// 肌群累加器（內部使用）
class _MuscleAccumulator {
  final String muscleGroup;
  double totalVolume = 0;
  int exerciseCount = 0;

  _MuscleAccumulator({required this.muscleGroup});

  void addExercise(double volume) {
    totalVolume += volume;
    exerciseCount++;
  }
}

/// 統一的訓練數據（內部使用）
class _UnifiedWorkoutData {
  final String id;
  final String title;
  final DateTime completedTime;
  final List<_UnifiedExerciseData> exercises;

  _UnifiedWorkoutData({
    required this.id,
    required this.title,
    required this.completedTime,
    required this.exercises,
  });
}

/// 統一的動作數據（內部使用）
class _UnifiedExerciseData {
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final int sets;
  final bool isCompleted;

  _UnifiedExerciseData({
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.sets,
    required this.isCompleted,
  });
}

/// 動作表現記錄（內部使用）
class _ExercisePerformance {
  final DateTime date;
  final String exerciseId;
  final String exerciseName;
  final double weight;
  final int reps;
  final int sets;

  _ExercisePerformance({
    required this.date,
    required this.exerciseId,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.sets,
  });
}

/// 肌群累加器（進階版，用於平衡分析）
class _MuscleGroupAccumulator {
  double totalVolume = 0;
  int workoutCount = 0;
  int exerciseCount = 0;
  final Set<String> exercises = {};
  
  void addExercise(String exerciseName, double volume) {
    totalVolume += volume;
    if (!exercises.contains(exerciseName)) {
      exercises.add(exerciseName);
      exerciseCount++;
    }
    workoutCount++;
  }

  List<String> get topExercises => exercises.take(5).toList();
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

