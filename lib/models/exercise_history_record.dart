import 'package:strengthwise/models/workout_record/set_record.dart';

/// 動作歷史記錄
///
/// 用於 Session Mode 顯示 PREV 幽靈數據
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

  const ExerciseHistoryRecord({
    required this.workoutRecordId,
    required this.exerciseId,
    required this.exerciseName,
    required this.trainingDate,
    required this.sets,
  });

  /// 取得每組數據的 Map（用於 PREV 顯示）
  /// 
  /// 返回 { setIndex: { 'reps': int, 'weight': double } }
  Map<int, Map<String, dynamic>> toSetMap() {
    final result = <int, Map<String, dynamic>>{};
    for (var i = 0; i < sets.length; i++) {
      result[i] = {
        'reps': sets[i].reps,
        'weight': sets[i].weight,
      };
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
