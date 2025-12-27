// Firestore 已移除，改用 Supabase
import 'exercise_record.dart';
import 'workout_record_factory.dart';

/// 訓練記錄模型
///
/// 表示用戶已完成或正在進行的訓練記錄，包含詳細的運動數據
class WorkoutRecord {
  final String id;                        // 唯一標識符
  final String workoutPlanId;             // 關聯的訓練計劃ID
  final String userId;                    // 用戶ID
  final String title;                     // 訓練標題
  final DateTime date;                    // 訓練日期
  final List<ExerciseRecord> exerciseRecords; // 運動記錄列表
  final String notes;                     // 備註
  final bool completed;                   // 是否完成
  final DateTime createdAt;               // 創建時間
  final DateTime? trainingTime;           // 訓練時間

  /// 創建一個訓練記錄實例
  WorkoutRecord({
    required this.id,
    required this.workoutPlanId,
    required this.userId,
    required this.title,
    required this.date,
    required this.exerciseRecords,
    this.notes = '',
    this.completed = false,
    required this.createdAt,
    this.trainingTime,
  });

  /// 轉換為 JSON 數據格式
  Map<String, dynamic> toJson() {
    return WorkoutRecordFactory.toJson(this);
  }
  
  /// 從 JSON 數據創建對象
  factory WorkoutRecord.fromJson(Map<String, dynamic> json) {
    return WorkoutRecordFactory.fromJson(json);
  }

  /// 從 Supabase 數據創建對象（從 workout_plans 表，completed=true）
  factory WorkoutRecord.fromSupabase(Map<String, dynamic> json) {
    return WorkoutRecordFactory.fromSupabase(json);
  }

  /// 從訓練計畫創建新的訓練記錄
  factory WorkoutRecord.fromWorkoutPlan(
    String userId,
    String planId,
    Map<String, dynamic> planData,
  ) {
    return WorkoutRecordFactory.fromWorkoutPlan(userId, planId, planData);
  }
  
  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
  WorkoutRecord copyWith({
    String? id,
    String? workoutPlanId,
    String? userId,
    String? title,
    DateTime? date,
    List<ExerciseRecord>? exerciseRecords,
    String? notes,
    bool? completed,
    DateTime? createdAt,
    DateTime? trainingTime,
  }) {
    return WorkoutRecord(
      id: id ?? this.id,
      workoutPlanId: workoutPlanId ?? this.workoutPlanId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      exerciseRecords: exerciseRecords ?? this.exerciseRecords,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      trainingTime: trainingTime ?? this.trainingTime,
    );
  }
  
  /// 更新訓練記錄的完成狀態
  WorkoutRecord markAsCompleted() {
    return copyWith(completed: true);
  }
  
  /// 更新訓練記錄的備註
  WorkoutRecord updateNotes(String newNotes) {
    return copyWith(notes: newNotes);
  }
  
  /// 添加一個運動記錄
  WorkoutRecord addExerciseRecord(ExerciseRecord record) {
    return copyWith(
      exerciseRecords: [...exerciseRecords, record],
    );
  }
  
  /// 更新特定運動記錄
  WorkoutRecord updateExerciseRecord(ExerciseRecord updatedRecord) {
    return copyWith(
      exerciseRecords: exerciseRecords.map((record) => 
        record.exerciseId == updatedRecord.exerciseId ? updatedRecord : record
      ).toList(),
    );
  }
  
  /// 刪除特定運動記錄
  WorkoutRecord removeExerciseRecord(String exerciseId) {
    return copyWith(
      exerciseRecords: exerciseRecords.where((record) => 
        record.exerciseId != exerciseId
      ).toList(),
    );
  }
  
  @override
  String toString() => 'WorkoutRecord(id: $id, date: $date, exercises: ${exerciseRecords.length})';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutRecord && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

