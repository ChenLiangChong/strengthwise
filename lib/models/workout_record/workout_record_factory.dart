import 'workout_record.dart';
import 'exercise_record.dart';

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

  /// 從 Supabase 數據創建對象（從 workout_plans 表，completed=true）
  static WorkoutRecord fromSupabase(Map<String, dynamic> json) {
    DateTime? trainingTime;
    if (json['training_time'] != null) {
      trainingTime = DateTime.parse(json['training_time']);
    }
    
    // exerciseRecords 從 exercises JSONB 欄位轉換
    final exercisesJson = json['exercises'] as List<dynamic>? ?? [];
    
    return WorkoutRecord(
      id: json['id'] ?? '',
      workoutPlanId: json['id'] ?? '', // workout_plans 的 id 就是 workoutPlanId
      userId: json['trainee_id'] ?? json['user_id'] ?? '',
      title: json['title'] ?? '訓練記錄',
      date: json['completed_date'] != null 
          ? DateTime.parse(json['completed_date'])
          : (json['scheduled_date'] != null 
              ? DateTime.parse(json['scheduled_date']) 
              : DateTime.now()),
      exerciseRecords: exercisesJson
          .map((e) => ExerciseRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['note'] ?? '',
      completed: json['completed'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      trainingTime: trainingTime,
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
        trainingTime = DateTime.parse(timeData);
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
          .map((e) => ExerciseRecord.fromWorkoutExercise(e as Map<String, dynamic>))
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
      'exerciseRecords': record.exerciseRecords
          .map((record) => record.toJson())
          .toList(),
      'notes': record.notes,
      'completed': record.completed,
      'createdAt': record.createdAt.millisecondsSinceEpoch,
      'trainingTime': record.trainingTime?.millisecondsSinceEpoch,
    };
  }
}

