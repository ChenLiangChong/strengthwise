import 'package:cloud_firestore/cloud_firestore.dart';

/// 訓練記錄模型
///
/// 表示用戶已完成或正在進行的訓練記錄，包含詳細的運動數據
class WorkoutRecord {
  final String id;                        // 唯一標識符
  final String workoutPlanId;             // 關聯的訓練計劃ID
  final String userId;                    // 用戶ID
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
    required this.date,
    required this.exerciseRecords,
    this.notes = '',
    this.completed = false,
    required this.createdAt,
    this.trainingTime,
  });

  /// 轉換為 JSON 數據格式
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutPlanId': workoutPlanId,
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'exerciseRecords': exerciseRecords.map((record) => record.toJson()).toList(),
      'notes': notes,
      'completed': completed,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'trainingTime': trainingTime?.millisecondsSinceEpoch,
    };
  }
  
  /// 轉換為 Firestore 可用的數據格式
  Map<String, dynamic> toFirestore() {
    return {
      'workoutPlanId': workoutPlanId,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'exerciseRecords': exerciseRecords.map((record) => record.toJson()).toList(),
      'notes': notes,
      'completed': completed,
      'createdAt': Timestamp.fromDate(createdAt),
      'trainingTime': trainingTime != null ? Timestamp.fromDate(trainingTime!) : null,
    };
  }

  /// 從 Firestore 數據創建對象
  factory WorkoutRecord.fromFirestore(Map<String, dynamic> data, String docId) {
    DateTime? trainingTime;
    if (data['trainingTime'] != null) {
      trainingTime = (data['trainingTime'] as Timestamp).toDate();
    } else if (data['trainingHour'] != null) {
      final date = (data['date'] as Timestamp).toDate();
      final hour = data['trainingHour'] as int;
      trainingTime = DateTime(date.year, date.month, date.day, hour, 0);
    }
    
    return WorkoutRecord(
      id: docId,
      workoutPlanId: data['workoutPlanId'] ?? '',
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      exerciseRecords: (data['exerciseRecords'] as List<dynamic>? ?? [])
          .map((e) => ExerciseRecord.fromFirestore(e as Map<String, dynamic>))
          .toList(),
      notes: data['notes'] ?? '',
      completed: data['completed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      trainingTime: trainingTime,
    );
  }
  
  /// 從 JSON 數據創建對象
  factory WorkoutRecord.fromJson(Map<String, dynamic> json) {
    DateTime? trainingTime;
    if (json['trainingTime'] != null) {
      trainingTime = DateTime.fromMillisecondsSinceEpoch(json['trainingTime']);
    }
    
    return WorkoutRecord(
      id: json['id'] ?? '',
      workoutPlanId: json['workoutPlanId'] ?? '',
      userId: json['userId'] ?? '',
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
  factory WorkoutRecord.fromSupabase(Map<String, dynamic> json) {
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
  factory WorkoutRecord.fromWorkoutPlan(
    String userId,
    String planId,
    Map<String, dynamic> planData,
  ) {
    final exercises = (planData['exercises'] as List<dynamic>? ?? []);
    
    DateTime? trainingTime;
    if (planData['trainingTime'] != null) {
      trainingTime = (planData['trainingTime'] as Timestamp).toDate();
    } else if (planData['trainingHour'] != null) {
      final date = DateTime.now();
      final hour = planData['trainingHour'] as int;
      trainingTime = DateTime(date.year, date.month, date.day, hour, 0);
    }
    
    return WorkoutRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workoutPlanId: planId,
      userId: userId,
      date: DateTime.now(),
      exerciseRecords: exercises
          .map((e) => ExerciseRecord.fromWorkoutExercise(e as Map<String, dynamic>))
          .toList(),
      completed: false,
      createdAt: DateTime.now(),
      trainingTime: trainingTime,
    );
  }
  
  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
  WorkoutRecord copyWith({
    String? id,
    String? workoutPlanId,
    String? userId,
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

/// 組數記錄模型
///
/// 表示一個運動組的詳細數據，包含次數、重量等信息
class SetRecord {
  final int setNumber;        // 組數編號
  final int reps;             // 重複次數
  final double weight;        // 重量(kg)
  final int restTime;         // 休息時間(秒)
  final bool completed;       // 是否完成
  final String note;          // 該組的備註

  /// 創建一個組數記錄實例
  SetRecord({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.restTime,
    this.completed = false,
    this.note = '',
  });

  /// 轉換為 JSON 數據格式
  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'restTime': restTime,
      'completed': completed,
      'note': note,
    };
  }
  
  /// 從 JSON 數據創建對象
  factory SetRecord.fromJson(Map<String, dynamic> json) {
    return SetRecord(
      setNumber: json['setNumber'] ?? 0,
      reps: json['reps'] ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      restTime: json['restTime'] ?? 0,
      completed: json['completed'] ?? false,
      note: json['note'] ?? '',
    );
  }

  /// 從 Firestore 數據創建對象
  factory SetRecord.fromFirestore(Map<String, dynamic> data) {
    return SetRecord(
      setNumber: data['setNumber'] ?? 0,
      reps: data['reps'] ?? 0,
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      restTime: data['restTime'] ?? 0,
      completed: data['completed'] ?? false,
      note: data['note'] ?? '',
    );
  }

  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
  SetRecord copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    int? restTime,
    bool? completed,
    String? note,
  }) {
    return SetRecord(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restTime: restTime ?? this.restTime,
      completed: completed ?? this.completed,
      note: note ?? this.note,
    );
  }
  
  /// 增加重複次數
  SetRecord incrementReps([int increment = 1]) {
    return copyWith(reps: reps + increment);
  }
  
  /// 減少重複次數
  SetRecord decrementReps([int decrement = 1]) {
    final newReps = reps - decrement;
    return copyWith(reps: newReps > 0 ? newReps : 1);
  }
  
  /// 增加重量
  SetRecord incrementWeight([double increment = 2.5]) {
    return copyWith(weight: weight + increment);
  }
  
  /// 減少重量
  SetRecord decrementWeight([double decrement = 2.5]) {
    final newWeight = weight - decrement;
    return copyWith(weight: newWeight > 0 ? newWeight : 0);
  }
  
  /// 標記為已完成
  SetRecord markAsCompleted() {
    return copyWith(completed: true);
  }
  
  /// 標記為未完成
  SetRecord markAsIncomplete() {
    return copyWith(completed: false);
  }
  
  /// 更新備註
  SetRecord updateNote(String newNote) {
    return copyWith(note: newNote);
  }
  
  @override
  String toString() => 'SetRecord(set: $setNumber, reps: $reps, weight: $weight)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetRecord && other.setNumber == setNumber;
  }
  
  @override
  int get hashCode => setNumber.hashCode;
} 