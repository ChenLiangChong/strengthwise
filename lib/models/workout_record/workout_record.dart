// Firestore 已移除，改用 Supabase
import 'exercise_record.dart';
import 'workout_record_factory.dart';

/// 訓練記錄模型
///
/// 表示用戶已完成或正在進行的訓練記錄，包含詳細的運動數據
class WorkoutRecord {
  final String id; // 唯一標識符
  final String workoutPlanId; // 關聯的訓練計劃ID
  final String userId; // 用戶ID（歷史遺留，對應 traineeId）
  final String? traineeId; // 受訓者 ID（v2.0 Phase 4C）
  final String? creatorId; // 創建者 ID（v2.0 Phase 4C）
  final String title; // 訓練標題
  final DateTime date; // 訓練日期
  final List<ExerciseRecord> exerciseRecords; // 運動記錄列表
  final String notes; // 備註
  final bool completed; // 是否完成
  final DateTime createdAt; // 創建時間
  final DateTime? trainingTime; // 訓練時間（開始時間）
  final DateTime? trainingEndTime; // 訓練結束時間 ⭐ v2.1

  // ⭐ v2.9.1: 訓練狀態追蹤欄位
  final DateTime? actualStartTime; // 實際開始訓練的時間
  final DateTime? actualEndTime; // 實際結束訓練的時間
  final int elapsedSeconds; // 累計訓練秒數（不含暫停）
  final String trainingStatus; // pending | in_progress | paused | completed

  // ⭐ v3.1: Session Mode 關聯預約 ID
  final String? appointmentId; // 關聯的預約 ID（上課訓練計畫）

  /// 創建一個訓練記錄實例
  WorkoutRecord({
    required this.id,
    required this.workoutPlanId,
    required this.userId,
    this.traineeId,
    this.creatorId,
    required this.title,
    required this.date,
    required this.exerciseRecords,
    this.notes = '',
    this.completed = false,
    required this.createdAt,
    this.trainingTime,
    this.trainingEndTime,
    // ⭐ v2.9.1: 訓練狀態追蹤
    this.actualStartTime,
    this.actualEndTime,
    this.elapsedSeconds = 0,
    this.trainingStatus = 'pending',
    // ⭐ v3.1: Session Mode
    this.appointmentId,
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
    String? traineeId,
    String? creatorId,
    String? title,
    DateTime? date,
    List<ExerciseRecord>? exerciseRecords,
    String? notes,
    bool? completed,
    DateTime? createdAt,
    DateTime? trainingTime,
    DateTime? trainingEndTime,
    // ⭐ v2.9.1: 訓練狀態追蹤
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    int? elapsedSeconds,
    String? trainingStatus,
    // ⭐ v3.1: Session Mode
    String? appointmentId,
  }) {
    return WorkoutRecord(
      id: id ?? this.id,
      workoutPlanId: workoutPlanId ?? this.workoutPlanId,
      userId: userId ?? this.userId,
      traineeId: traineeId ?? this.traineeId,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      date: date ?? this.date,
      exerciseRecords: exerciseRecords ?? this.exerciseRecords,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      trainingTime: trainingTime ?? this.trainingTime,
      trainingEndTime: trainingEndTime ?? this.trainingEndTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      trainingStatus: trainingStatus ?? this.trainingStatus,
      appointmentId: appointmentId ?? this.appointmentId,
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
      exerciseRecords: exerciseRecords
          .map((record) => record.exerciseId == updatedRecord.exerciseId
              ? updatedRecord
              : record)
          .toList(),
    );
  }

  /// 刪除特定運動記錄
  WorkoutRecord removeExerciseRecord(String exerciseId) {
    return copyWith(
      exerciseRecords: exerciseRecords
          .where((record) => record.exerciseId != exerciseId)
          .toList(),
    );
  }

  @override
  String toString() =>
      'WorkoutRecord(id: $id, date: $date, exercises: ${exerciseRecords.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
