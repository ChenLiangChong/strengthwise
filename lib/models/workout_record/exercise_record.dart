import 'set_record.dart';

/// 運動記錄模型
///
/// 表示一個特定運動的詳細記錄，包含多個組的數據
class ExerciseRecord {
  final String exerciseId;           // 關聯的運動ID
  final String exerciseName;         // 運動名稱
  final List<SetRecord> sets;        // 組數記錄
  final String notes;                // 備註
  final bool completed;              // 是否完成

  /// 創建一個運動記錄實例
  ExerciseRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.notes = '',
    this.completed = false,
  });

  /// 轉換為 JSON 數據格式
  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((set) => set.toJson()).toList(),
      'notes': notes,
      'completed': completed,
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
    );
  }

  /// 從訓練計畫中的運動創建記錄
  factory ExerciseRecord.fromWorkoutExercise(Map<String, dynamic> exerciseData) {
    final sets = <SetRecord>[];
    final targetSets = exerciseData['sets'] as int? ?? 3;
    
    // 為每個目標組數創建一個SetRecord
    for (int i = 0; i < targetSets; i++) {
      sets.add(SetRecord(
        setNumber: i + 1,
        reps: exerciseData['reps'] as int? ?? 10,
        weight: (exerciseData['weight'] as num?)?.toDouble() ?? 0.0,
        restTime: exerciseData['restTime'] as int? ?? 60,
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
    );
  }

  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
  ExerciseRecord copyWith({
    String? exerciseId,
    String? exerciseName,
    List<SetRecord>? sets,
    String? notes,
    bool? completed,
  }) {
    return ExerciseRecord(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }
  
  /// 標記為已完成
  ExerciseRecord markAsCompleted() {
    return copyWith(completed: true);
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

