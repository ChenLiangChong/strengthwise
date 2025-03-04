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
  final DateTime? trainingTime;

  WorkoutTemplate({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.planType,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
    this.trainingTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'planType': planType,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'trainingTime': trainingTime != null ? Timestamp.fromDate(trainingTime!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory WorkoutTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    DateTime? trainingTime;
    if (data['trainingTime'] != null) {
      trainingTime = (data['trainingTime'] as Timestamp).toDate();
    } else if (data['trainingHour'] != null) {
      final today = DateTime.now();
      final hour = data['trainingHour'] as int;
      trainingTime = DateTime(today.year, today.month, today.day, hour, 0);
    }
    
    return WorkoutTemplate(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      planType: data['planType'] ?? '',
      exercises: (data['exercises'] as List<dynamic>?)
          ?.map((e) => WorkoutExercise.fromFirestore(e as Map<String, dynamic>))
          .toList() ?? [],
      trainingTime: trainingTime,
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
    DateTime? trainingTime,
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
      trainingTime: trainingTime ?? this.trainingTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 