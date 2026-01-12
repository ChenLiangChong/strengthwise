import 'package:uuid/uuid.dart';
import 'set_record.dart';
import '../tracking_mode.dart';
import '../workout_template/workout_exercise.dart';

/// 運動記錄模型
///
/// 表示一個特定運動的詳細記錄，包含多個組的數據
/// 
/// v3.2+ 支援多種追蹤模式（trackingMode）
class ExerciseRecord {
  final String exerciseId;           // 關聯的運動ID
  final String exerciseName;         // 運動名稱
  final List<SetRecord> sets;        // 組數記錄
  final String notes;                // 備註
  final bool completed;              // 是否完成
  final TrackingMode trackingMode;   // v3.2+ 追蹤模式

  /// 創建一個運動記錄實例
  ExerciseRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.notes = '',
    this.completed = false,
    this.trackingMode = TrackingMode.weightReps,
  });

  /// 轉換為 JSON 數據格式
  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((set) => set.toJson()).toList(),
      'notes': notes,
      'completed': completed,
      'trackingMode': trackingMode.toJson(),
    };
  }

  /// 從 JSON 數據創建對象
  factory ExerciseRecord.fromJson(Map<String, dynamic> json) {
    return ExerciseRecord(
      exerciseId: json['exerciseId'] ?? '',
      exerciseName: json['exerciseName'] ?? '',
      sets: ((json['sets'] as List<dynamic>?) ?? [])
          .map((e) => SetRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] ?? '',
      completed: json['completed'] ?? false,
      trackingMode: TrackingModeExtension.fromJson(json['trackingMode'] as String?),
    );
  }

  /// 從 Firestore 數據創建對象
  factory ExerciseRecord.fromFirestore(Map<String, dynamic> data) {
    return ExerciseRecord(
      exerciseId: data['exerciseId'] ?? '',
      exerciseName: data['exerciseName'] ?? '',
      sets: (data['sets'] as List<dynamic>? ?? [])
          .map((e) => SetRecord.fromFirestore(e as Map<String, dynamic>))
          .toList(),
      notes: data['notes'] ?? '',
      completed: data['completed'] ?? false,
      trackingMode: TrackingModeExtension.fromJson(data['trackingMode'] as String?),
    );
  }

  /// 從訓練計畫中的運動創建記錄
  factory ExerciseRecord.fromWorkoutExercise(Map<String, dynamic> exerciseData) {
    final sets = <SetRecord>[];
    final targetSets = exerciseData['sets'] as int? ?? 3;
    
    // v3.2+ 解析 trackingMode
    final trackingMode = TrackingModeExtension.fromJson(
      exerciseData['trackingMode'] as String?,
    );
    
    // 為每個目標組數創建一個SetRecord
    for (int i = 0; i < targetSets; i++) {
      sets.add(SetRecord(
        setNumber: i + 1,
        reps: exerciseData['reps'] as int? ?? 10,
        weight: (exerciseData['weight'] as num?)?.toDouble() ?? 0.0,
        restTime: exerciseData['restTime'] as int? ?? 60,
        // v3.2+ 新增欄位
        time: exerciseData['time'] as int?,
        distance: (exerciseData['distance'] as num?)?.toDouble(),
        calories: (exerciseData['calories'] as num?)?.toDouble(),
      ));
    }
    
    // 優先使用exerciseName，然後是name，最後是actionName
    final name = exerciseData['exerciseName'] ?? 
                exerciseData['name'] ?? 
                exerciseData['actionName'] ?? 
                '未命名運動';
    
    return ExerciseRecord(
      exerciseId: exerciseData['exerciseId'] ?? '',
      exerciseName: name,
      sets: sets,
      notes: exerciseData['notes'] ?? '',
      completed: false,
      trackingMode: trackingMode,
    );
  }

  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
  ExerciseRecord copyWith({
    String? exerciseId,
    String? exerciseName,
    List<SetRecord>? sets,
    String? notes,
    bool? completed,
    TrackingMode? trackingMode,
  }) {
    return ExerciseRecord(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
      trackingMode: trackingMode ?? this.trackingMode,
    );
  }
  
  /// 標記為已完成
  ExerciseRecord markAsCompleted() {
    return copyWith(completed: true);
  }

  /// 轉換為 WorkoutExercise（用於儲存為模板）
  ///
  /// 從訓練記錄轉換為模板格式，使用第一組的數據作為預設值。
  /// 注意：equipment 和 bodyParts 需要從外部補充。
  WorkoutExercise toWorkoutExercise({
    String equipment = '',
    List<String> bodyParts = const [],
  }) {
    final firstSet = sets.isNotEmpty ? sets.first : null;
    return WorkoutExercise(
      id: const Uuid().v4(),
      exerciseId: exerciseId,
      name: exerciseName,
      equipment: equipment,
      bodyParts: bodyParts,
      sets: sets.length,
      reps: firstSet?.reps ?? 10,
      weight: firstSet?.weight ?? 0,
      restTime: firstSet?.restTime ?? 60,
      notes: notes,
      trackingMode: trackingMode,
      time: firstSet?.time,
      distance: firstSet?.distance,
      calories: firstSet?.calories,
    );
  }
  
  /// 添加一個新組
  ExerciseRecord addSet(SetRecord newSet) {
    return copyWith(sets: [...sets, newSet]);
  }
  
  /// 刪除指定的組
  ExerciseRecord removeSet(int setNumber) {
    return copyWith(
      sets: sets.where((set) => set.setNumber != setNumber).toList(),
    );
  }
  
  /// 更新指定的組
  ExerciseRecord updateSet(SetRecord updatedSet) {
    return copyWith(
      sets: sets.map((set) => 
        set.setNumber == updatedSet.setNumber ? updatedSet : set
      ).toList(),
    );
  }
  
  /// 更新備註
  ExerciseRecord updateNotes(String newNotes) {
    return copyWith(notes: newNotes);
  }
  
  @override
  String toString() => 'ExerciseRecord(name: $exerciseName, sets: ${sets.length})';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExerciseRecord && 
           other.exerciseId == exerciseId && 
           other.exerciseName == exerciseName;
  }
  
  @override
  int get hashCode => exerciseId.hashCode ^ exerciseName.hashCode;
}

