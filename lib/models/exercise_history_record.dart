import 'package:strengthwise/models/workout_record/set_record.dart';
import 'package:strengthwise/models/tracking_mode.dart';

/// 動作歷史記錄
///
/// 用於 Session Mode 顯示 PREV 幽靈數據
/// v3.2+ 支援多元追蹤模式
class ExerciseHistoryRecord {
  /// 訓練記錄 ID
  final String workoutRecordId;

  /// 動作 ID
  final String exerciseId;

  /// 動作名稱
  final String exerciseName;

  /// 訓練日期
  final DateTime trainingDate;

  /// 每組完成數據（複用現有 SetRecord）
  final List<SetRecord> sets;
  
  /// v3.2+ 追蹤模式
  final TrackingMode trackingMode;

  const ExerciseHistoryRecord({
    required this.workoutRecordId,
    required this.exerciseId,
    required this.exerciseName,
    required this.trainingDate,
    required this.sets,
    this.trackingMode = TrackingMode.weightReps,
  });

  /// 取得每組數據的 Map（用於 PREV 顯示）
  /// 
  /// v3.2+ 根據 trackingMode 返回不同欄位
  /// - weight_reps: { 'reps': int, 'weight': double }
  /// - weight_time: { 'weight': double, 'time': int }
  /// - reps_only: { 'reps': int }
  /// - time_only: { 'time': int }
  /// - distance_time: { 'distance': double, 'time': int }
  /// - calories: { 'calories': double }
  Map<int, Map<String, dynamic>> toSetMap() {
    final result = <int, Map<String, dynamic>>{};
    for (var i = 0; i < sets.length; i++) {
      final set = sets[i];
      final data = <String, dynamic>{};
      
      // 根據追蹤模式返回相應欄位
      switch (trackingMode) {
        case TrackingMode.weightReps:
          data['reps'] = set.reps;
          data['weight'] = set.weight;
          break;
        case TrackingMode.weightTime:
          data['weight'] = set.weight;
          data['time'] = set.time ?? 0;
          break;
        case TrackingMode.repsOnly:
          data['reps'] = set.reps;
          break;
        case TrackingMode.timeOnly:
          data['time'] = set.time ?? 0;
          break;
        case TrackingMode.repsTime:
          data['reps'] = set.reps;
          data['time'] = set.time ?? 0;
          break;
        case TrackingMode.distanceTime:
          data['distance'] = set.distance ?? 0.0;
          data['time'] = set.time ?? 0;
          break;
        case TrackingMode.distanceOnly:
          data['distance'] = set.distance ?? 0.0;
          break;
        case TrackingMode.calories:
          data['calories'] = set.calories ?? 0.0;
          break;
      }
      
      result[i] = data;
    }
    return result;
  }

  /// 總訓練量（重量 x 次數 x 組數）
  double get totalVolume {
    return sets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));
  }

  /// 最大重量
  double get maxWeight {
    if (sets.isEmpty) return 0;
    return sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  }

  /// 格式化日期
  String get formattedDate {
    return '${trainingDate.month}/${trainingDate.day}';
  }

  @override
  String toString() {
    return 'ExerciseHistoryRecord(exerciseName: $exerciseName, date: $formattedDate, sets: ${sets.length})';
  }
}
