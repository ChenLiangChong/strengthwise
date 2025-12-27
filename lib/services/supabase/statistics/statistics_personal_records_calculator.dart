import 'package:flutter/foundation.dart';
import '../../../models/statistics_model.dart';
import '../../../models/exercise_model.dart';
import '../../core/error_handling_service.dart';
import 'statistics_data_loader.dart';
import 'statistics_data_parser.dart';

/// 個人記錄計算器
///
/// 負責計算個人最佳記錄
class PersonalRecordsCalculator {
  final StatisticsDataLoader _dataLoader;
  final StatisticsDataParser _dataParser;
  final ErrorHandlingService _errorService;
  final Map<String, Exercise> _exerciseCache;

  PersonalRecordsCalculator({
    required StatisticsDataLoader dataLoader,
    required StatisticsDataParser dataParser,
    required ErrorHandlingService errorService,
    required Map<String, Exercise> exerciseCache,
  })  : _dataLoader = dataLoader,
        _dataParser = dataParser,
        _errorService = errorService,
        _exerciseCache = exerciseCache;

  /// 計算個人記錄（優先使用彙總表）
  Future<List<PersonalRecord>> calculatePersonalRecords(
    String userId, {
    int limit = 20,
  }) async {
    try {
      // 優先使用彙總表查詢
      _logDebug('📊 從 personal_records 表查詢個人記錄...');
      
      final records = await _dataLoader.getPersonalRecordsFromAggregation(
        userId,
        limit: limit,
      );

      if (records.isEmpty) {
        _logDebug('✅ 從彙總表查詢到 0 個個人記錄');
        return [];
      }

      // 批量查詢動作信息
      final exerciseIds = records
          .map((item) => item['exercise_id'] as String)
          .toSet()
          .toList();

      _logDebug('   🔍 需要查詢 ${exerciseIds.length} 個動作的 body_part');

      final exerciseInfoMap = await _loadExerciseInfo(exerciseIds);

      // 構建 PersonalRecord 列表
      final result = <PersonalRecord>[];
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(Duration(days: 7));

      for (var item in records) {
        try {
          final achievedDate = DateTime.parse(item['achieved_date'] as String);
          final isNew = achievedDate.isAfter(oneWeekAgo);
          final exerciseId = item['exercise_id'] as String;
          final exerciseName = item['exercise_name'] as String;
          final bodyPart = exerciseInfoMap[exerciseId] ?? '';

          result.add(PersonalRecord(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            maxWeight: (item['max_weight'] as num).toDouble(),
            reps: item['max_reps'] as int,
            achievedDate: achievedDate,
            bodyPart: bodyPart,
            isNew: isNew,
          ));
        } catch (e) {
          _errorService.logError('解析個人記錄失敗: $e',
              type: 'StatisticsServiceError');
        }
      }

      _logDebug('✅ 從彙總表查詢到 ${result.length} 個個人記錄');
      return result;
    } catch (e) {
      _logDebug('⚠️ 彙總表查詢失敗，回退到原始查詢方法: $e');
      return _calculateFromRawData(userId, limit);
    }
  }

  /// 原始方法：掃描所有訓練記錄計算個人記錄
  Future<List<PersonalRecord>> _calculateFromRawData(
      String userId, int limit) async {
    _logDebug('🔄 使用原始方法計算個人記錄...');

    final allWorkoutsData = await _dataLoader.getAllCompletedWorkouts(userId);
    if (allWorkoutsData.isEmpty) return [];

    final allWorkouts = _dataParser.parseWorkoutDataList(allWorkoutsData);

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
        if (currentRecord == null ||
            exercise.weight > currentRecord.maxWeight) {
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

    _logDebug('✅ 原始方法查詢到 ${result.length} 個個人記錄');
    return result.take(limit).toList();
  }

  /// 批量載入動作信息
  Future<Map<String, String>> _loadExerciseInfo(
      List<String> exerciseIds) async {
    final exerciseInfoMap = <String, String>{};

    try {
      // 查詢系統動作
      final exercisesData = await _dataLoader.getExerciseInfo(exerciseIds);

      final foundSystemIds = <String>{};
      for (var ex in exercisesData) {
        final id = ex['id'] as String;
        final bodyPart = ex['body_part'] as String? ?? '';
        exerciseInfoMap[id] = bodyPart;
        foundSystemIds.add(id);
      }

      // 查詢自訂動作
      final customExerciseIds =
          exerciseIds.where((id) => !foundSystemIds.contains(id)).toList();

      if (customExerciseIds.isNotEmpty) {
        final customExercisesData =
            await _dataLoader.getCustomExerciseInfo(customExerciseIds);

        for (var ex in customExercisesData) {
          final id = ex['id'] as String;
          final bodyPart = ex['body_part'] as String? ?? '';
          exerciseInfoMap[id] = bodyPart;
        }
      }
    } catch (e) {
      _logDebug('⚠️ 批量查詢動作信息失敗: $e');
      _errorService.logError('批量查詢動作信息失敗: $e',
          type: 'StatisticsServiceError');
    }

    return exerciseInfoMap;
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      print('[PERSONAL_RECORDS] $message');
    }
  }
}

