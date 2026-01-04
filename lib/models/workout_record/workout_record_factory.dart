import 'workout_record.dart';
import 'exercise_record.dart';
import '../../utils/datetime_utils.dart'; // ⭐ 使用時間工具

/// 訓練記錄工廠類
///
/// 提供多種創建 WorkoutRecord 的工廠方法
class WorkoutRecordFactory {
  /// 從 JSON 數據創建對象（客戶端格式）
  static WorkoutRecord fromJson(Map<String, dynamic> json) {
    DateTime? trainingTime;
    if (json['trainingTime'] != null) {
      trainingTime = DateTime.fromMillisecondsSinceEpoch(json['trainingTime']);
    }

    return WorkoutRecord(
      id: json['id'] ?? '',
      workoutPlanId: json['workoutPlanId'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '訓練記錄',
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      exerciseRecords: (json['exerciseRecords'] as List<dynamic>? ?? [])
          .map((e) => ExerciseRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] ?? '',
      completed: json['completed'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      trainingTime: trainingTime,
    );
  }

  /// 從 Supabase 數據創建對象（從 workout_plans 表）
  static WorkoutRecord fromSupabase(Map<String, dynamic> json) {
    DateTime? trainingTime;
    DateTime? trainingEndTime;

    // ⭐ v2.1: 處理訓練時間範圍（training_time_range）
    if (json['training_time_range'] != null) {
      final timeRange =
          DateTimeUtils.parseTstzRange(json['training_time_range'] as String);
      trainingTime = timeRange['start']; // ⭐ 已經是本地時間
      trainingEndTime = timeRange['end']; // ⭐ 已經是本地時間
    }
    // 向後兼容：舊數據只有 training_time
    else if (json['training_time'] != null) {
      trainingTime =
          DateTimeUtils.parseIsoTimestamp(json['training_time']); // ⭐ 統一工具類
      // 如果沒有 end time，假設訓練 1 小時
      trainingEndTime = trainingTime.add(const Duration(hours: 1));
    }

    // exerciseRecords 從 exercises JSONB 欄位轉換
    final exercisesJson = json['exercises'] as List<dynamic>? ?? [];

    // ⭐ v2.9.1: 解析訓練狀態追蹤欄位
    DateTime? actualStartTime;
    DateTime? actualEndTime;
    if (json['actual_start_time'] != null) {
      actualStartTime =
          DateTimeUtils.parseIsoTimestamp(json['actual_start_time']);
    }
    if (json['actual_end_time'] != null) {
      actualEndTime = DateTimeUtils.parseIsoTimestamp(json['actual_end_time']);
    }

    return WorkoutRecord(
      id: json['id'] ?? '',
      workoutPlanId: json['id'] ?? '', // workout_plans 的 id 就是 workoutPlanId
      userId: json['trainee_id'] ?? json['user_id'] ?? '',
      traineeId: json['trainee_id'], // Phase 4C
      creatorId: json['creator_id'], // Phase 4C
      title: json['title'] ?? '訓練記錄',
      date: json['completed_date'] != null
          ? DateTimeUtils.parseIsoTimestamp(json['completed_date']) // ⭐ 統一工具類
          : (json['scheduled_date'] != null
              ? DateTimeUtils.parseIsoTimestamp(
                  json['scheduled_date']) // ⭐ 統一工具類
              : DateTime.now()),
      exerciseRecords: exercisesJson
          .map((e) => ExerciseRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['note'] ?? '',
      completed: json['completed'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTimeUtils.parseIsoTimestamp(json['created_at']) // ⭐ 統一工具類
          : DateTime.now(),
      trainingTime: trainingTime,
      trainingEndTime: trainingEndTime,
      // ⭐ v2.9.1: 訓練狀態追蹤
      actualStartTime: actualStartTime,
      actualEndTime: actualEndTime,
      elapsedSeconds: json['elapsed_seconds'] as int? ?? 0,
      trainingStatus: json['training_status'] as String? ?? 'pending',
    );
  }

  /// 從訓練計畫創建新的訓練記錄
  static WorkoutRecord fromWorkoutPlan(
    String userId,
    String planId,
    Map<String, dynamic> planData,
  ) {
    final exercises = (planData['exercises'] as List<dynamic>? ?? []);

    DateTime? trainingTime;
    if (planData['trainingTime'] != null) {
      // 支援 DateTime 或 String 格式
      final timeData = planData['trainingTime'];
      if (timeData is DateTime) {
        trainingTime = timeData;
      } else if (timeData is String) {
        trainingTime = DateTimeUtils.parseIsoTimestamp(timeData); // ⭐ 統一工具類
      }
    } else if (planData['trainingHour'] != null) {
      final date = DateTime.now();
      final hour = planData['trainingHour'] as int;
      trainingTime = DateTime(date.year, date.month, date.day, hour, 0);
    }

    return WorkoutRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workoutPlanId: planId,
      userId: userId,
      title: planData['title'] ?? '訓練記錄',
      date: DateTime.now(),
      exerciseRecords: exercises
          .map((e) =>
              ExerciseRecord.fromWorkoutExercise(e as Map<String, dynamic>))
          .toList(),
      completed: false,
      createdAt: DateTime.now(),
      trainingTime: trainingTime,
    );
  }

  /// 轉換為 JSON 數據格式
  static Map<String, dynamic> toJson(WorkoutRecord record) {
    return {
      'id': record.id,
      'workoutPlanId': record.workoutPlanId,
      'userId': record.userId,
      'title': record.title,
      'date': record.date.millisecondsSinceEpoch,
      'exerciseRecords':
          record.exerciseRecords.map((record) => record.toJson()).toList(),
      'notes': record.notes,
      'completed': record.completed,
      'createdAt': record.createdAt.millisecondsSinceEpoch,
      'trainingTime': record.trainingTime?.millisecondsSinceEpoch,
      // ⭐ v2.9.1: 訓練狀態追蹤
      'actualStartTime': record.actualStartTime?.millisecondsSinceEpoch,
      'actualEndTime': record.actualEndTime?.millisecondsSinceEpoch,
      'elapsedSeconds': record.elapsedSeconds,
      'trainingStatus': record.trainingStatus,
    };
  }
}
