import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_model.dart';

class WorkoutExercise {
  final String id;
  final String exerciseId;
  final String name;
  final String? actionName;
  final String equipment;
  final List<String> bodyParts;
  final int sets;
  final int reps;
  final double weight;
  final int restTime; // 休息時間（秒）
  final String notes;
  final bool isCompleted;

  WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.name,
    this.actionName,
    required this.equipment,
    required this.bodyParts,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restTime,
    this.notes = '',
    this.isCompleted = false,
  });

  factory WorkoutExercise.fromExercise(Exercise exercise) {
    return WorkoutExercise(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseId: exercise.id,
      name: exercise.name,
      actionName: exercise.actionName,
      equipment: exercise.equipment,
      bodyParts: exercise.bodyParts,
      sets: 3, // 預設值
      reps: 10, // 預設值
      weight: 0, // 預設值
      restTime: 60, // 預設休息時間60秒
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'name': name,
      'actionName': actionName,
      'equipment': equipment,
      'bodyParts': bodyParts,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'restTime': restTime,
      'notes': notes,
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseId: json['exerciseId'] ?? '',
      name: json['name'] ?? '',
      actionName: json['actionName'],
      equipment: json['equipment'] ?? '',
      bodyParts: List<String>.from(json['bodyParts'] ?? []),
      sets: json['sets'] ?? 3,
      reps: json['reps'] ?? 10,
      weight: (json['weight'] ?? 0).toDouble(),
      restTime: json['restTime'] ?? 60,
      notes: json['notes'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  factory WorkoutExercise.fromFirestore(Map<String, dynamic> data) {
    return WorkoutExercise(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseId: data['exerciseId'] ?? '',
      name: data['name'] ?? '',
      actionName: data['actionName'],
      equipment: data['equipment'] ?? '',
      bodyParts: List<String>.from(data['bodyParts'] ?? []),
      sets: data['sets'] ?? 3,
      reps: data['reps'] ?? 10,
      weight: (data['weight'] ?? 0).toDouble(),
      restTime: data['restTime'] ?? 60,
      notes: data['notes'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  WorkoutExercise copyWith({
    String? id,
    String? exerciseId,
    String? name,
    String? actionName,
    String? equipment,
    List<String>? bodyParts,
    int? sets,
    int? reps,
    double? weight,
    int? restTime,
    String? notes,
    bool? isCompleted,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      actionName: actionName ?? this.actionName,
      equipment: equipment ?? this.equipment,
      bodyParts: bodyParts ?? this.bodyParts,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restTime: restTime ?? this.restTime,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class WorkoutTemplate {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String planType;
  final List<WorkoutExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutTemplate({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.planType,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'planType': planType,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory WorkoutTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutTemplate(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      planType: data['planType'] ?? '',
      exercises: (data['exercises'] as List<dynamic>?)
          ?.map((e) => WorkoutExercise.fromFirestore(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  // 複製並修改
  WorkoutTemplate copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? planType,
    List<WorkoutExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      planType: planType ?? this.planType,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 