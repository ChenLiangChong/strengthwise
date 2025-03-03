import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_exercise_model.dart';

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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
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