import 'package:flutter/foundation.dart';
import '../../core/error_handling_service.dart';
import '../../../utils/datetime_utils.dart';
import '../../../utils/isolate_utils.dart';
import 'statistics_models.dart';

/// 統計數據解析器
///
/// 負責解析訓練數據並轉換為統一格式
class StatisticsDataParser {
  final ErrorHandlingService _errorService;

  StatisticsDataParser({required ErrorHandlingService errorService})
      : _errorService = errorService;

  /// 解析訓練數據並轉換為統一格式
  UnifiedWorkoutData parseWorkoutData(String id, Map<String, dynamic> data) {
    final exercises = <UnifiedExerciseData>[];
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

            exercises.add(UnifiedExerciseData(
              exerciseId: exerciseData['exerciseId'] ?? '',
              exerciseName:
                  exerciseData['exerciseName'] ?? exerciseData['name'] ?? '',
              weight: (setData['weight'] as num?)?.toDouble() ?? 0.0,
              reps: setData['reps'] as int? ?? 0,
              sets: 1, // 每個 SetRecord 算一組
              isCompleted: true,
              // v3.3+ 新增欄位
              time: setData['time'] as int?,
              distance: (setData['distance'] as num?)?.toDouble(),
              calories: (setData['calories'] as num?)?.toDouble(),
            ));
          }
        } else {
          // 舊格式：WorkoutExercise with simple sets/reps/weight
          exercises.add(UnifiedExerciseData(
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

    return UnifiedWorkoutData(
      id: id,
      title: data['title'] ?? '未命名訓練',
      completedTime: data['completed_date'] != null
          ? DateTimeUtils.parseIsoTimestamp(data['completed_date'] as String)
          : (data['scheduled_date'] != null
              ? DateTimeUtils.parseIsoTimestamp(data['scheduled_date'] as String)
              : DateTimeUtils.parseIsoTimestamp(data['updated_at'] as String)),
      exercises: exercises,
    );
  }

  /// 批量解析訓練數據
  List<UnifiedWorkoutData> parseWorkoutDataList(
      List<Map<String, dynamic>> docs) {
    final List<UnifiedWorkoutData> workouts = [];
    for (var doc in docs) {
      try {
        workouts.add(parseWorkoutData(doc['id'] as String, doc));
      } catch (e) {
        _errorService.logError('解析訓練記錄失敗: $e',
            type: 'StatisticsServiceError');
      }
    }
    return workouts;
  }

  /// ⚡ 批量解析訓練數據（使用 Isolate，避免阻塞主執行緒）
  ///
  /// 當資料量超過閾值時，自動使用背景 Isolate 解析
  Future<List<UnifiedWorkoutData>> parseWorkoutDataListAsync(
      List<Map<String, dynamic>> docs) async {
    // 小型列表直接在主執行緒解析
    if (docs.length < IsolateUtils.listThreshold) {
      return parseWorkoutDataList(docs);
    }

    // 大型列表使用 Isolate
    try {
      final result = await compute(
        _parseWorkoutDataListIsolate,
        docs,
      );

      if (kDebugMode) {
        print('[STATISTICS_PARSER] ⚡ Isolate 解析完成：${result.length} 筆訓練');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('[STATISTICS_PARSER] ⚠️ Isolate 解析失敗，降級到主執行緒: $e');
      }
      // 降級：在主執行緒解析
      return parseWorkoutDataList(docs);
    }
  }
}

/// Isolate 內執行的解析函數（必須是頂層函數）
List<UnifiedWorkoutData> _parseWorkoutDataListIsolate(
    List<Map<String, dynamic>> docs) {
  final List<UnifiedWorkoutData> workouts = [];
  
  for (var doc in docs) {
    try {
      workouts.add(_parseWorkoutDataIsolate(doc['id'] as String, doc));
    } catch (e) {
      // Isolate 內不能使用 ErrorService，直接跳過錯誤
    }
  }
  
  return workouts;
}

/// Isolate 內執行的單筆解析（純函數）
UnifiedWorkoutData _parseWorkoutDataIsolate(String id, Map<String, dynamic> data) {
  final exercises = <UnifiedExerciseData>[];
  final exercisesData = data['exercises'] as List<dynamic>? ?? [];

  for (var exerciseData in exercisesData) {
    try {
      if (exerciseData is! Map<String, dynamic>) continue;

      if (exerciseData['sets'] is List) {
        final setsData = exerciseData['sets'] as List<dynamic>;
        for (var setData in setsData) {
          if (setData is! Map<String, dynamic>) continue;

          final completed = setData['completed'] as bool? ?? false;
          if (!completed) continue;

          exercises.add(UnifiedExerciseData(
            exerciseId: exerciseData['exerciseId'] ?? '',
            exerciseName:
                exerciseData['exerciseName'] ?? exerciseData['name'] ?? '',
            weight: (setData['weight'] as num?)?.toDouble() ?? 0.0,
            reps: setData['reps'] as int? ?? 0,
            sets: 1,
            isCompleted: true,
            // v3.3+ 新增欄位
            time: setData['time'] as int?,
            distance: (setData['distance'] as num?)?.toDouble(),
            calories: (setData['calories'] as num?)?.toDouble(),
          ));
        }
      } else {
        exercises.add(UnifiedExerciseData(
          exerciseId: exerciseData['exerciseId'] ?? '',
          exerciseName: exerciseData['name'] ?? '',
          weight: (exerciseData['weight'] as num?)?.toDouble() ?? 0.0,
          reps: exerciseData['reps'] as int? ?? 0,
          sets: exerciseData['sets'] as int? ?? 0,
          isCompleted: exerciseData['isCompleted'] as bool? ?? false,
        ));
      }
    } catch (e) {
      // Isolate 內不能使用 ErrorService，直接跳過錯誤
    }
  }

  return UnifiedWorkoutData(
    id: id,
    title: data['title'] ?? '未命名訓練',
    completedTime: data['completed_date'] != null
        ? DateTimeUtils.parseIsoTimestamp(data['completed_date'] as String)
        : (data['scheduled_date'] != null
            ? DateTimeUtils.parseIsoTimestamp(data['scheduled_date'] as String)
            : DateTimeUtils.parseIsoTimestamp(data['updated_at'] as String)),
    exercises: exercises,
  );
}

