import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutRecord {
  final String id;
  final String workoutPlanId;
  final String userId;
  final DateTime date;
  final List<ExerciseRecord> exerciseRecords;
  final String notes;
  final bool completed;
  final DateTime createdAt;

  WorkoutRecord({
    required this.id,
    required this.workoutPlanId,
    required this.userId,
    required this.date,
    required this.exerciseRecords,
    this.notes = '',
    this.completed = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutPlanId': workoutPlanId,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'exerciseRecords': exerciseRecords.map((record) => record.toJson()).toList(),
      'notes': notes,
      'completed': completed,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WorkoutRecord.fromFirestore(Map<String, dynamic> data, String docId) {
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
    );
  }

  // 從訓練計畫創建新的訓練記錄
  factory WorkoutRecord.fromWorkoutPlan(
    String userId,
    String planId,
    Map<String, dynamic> planData,
  ) {
    final exercises = (planData['exercises'] as List<dynamic>? ?? []);
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
    );
  }
}

class ExerciseRecord {
  final String exerciseId;
  final String exerciseName;
  final List<SetRecord> sets;
  final String notes;
  final bool completed;

  ExerciseRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.notes = '',
    this.completed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((set) => set.toJson()).toList(),
      'notes': notes,
      'completed': completed,
    };
  }

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

  // 從訓練計畫中的運動創建記錄
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
    
    print('創建運動記錄，名稱: $name, 原始數據: ${exerciseData.keys}');
    
    return ExerciseRecord(
      exerciseId: exerciseData['exerciseId'] ?? '',
      exerciseName: name,
      sets: sets,
      notes: exerciseData['notes'] ?? '',
      completed: false,
    );
  }

  // 複製並修改
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
}

class SetRecord {
  final int setNumber;
  final int reps;
  final double weight;
  final int restTime;
  final bool completed;

  SetRecord({
    required this.setNumber,
    required this.reps,
    required this.weight,
    required this.restTime,
    this.completed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'restTime': restTime,
      'completed': completed,
    };
  }

  factory SetRecord.fromFirestore(Map<String, dynamic> data) {
    return SetRecord(
      setNumber: data['setNumber'] ?? 0,
      reps: data['reps'] ?? 0,
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      restTime: data['restTime'] ?? 0,
      completed: data['completed'] ?? false,
    );
  }

  // 複製並修改
  SetRecord copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    int? restTime,
    bool? completed,
  }) {
    return SetRecord(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restTime: restTime ?? this.restTime,
      completed: completed ?? this.completed,
    );
  }
} 