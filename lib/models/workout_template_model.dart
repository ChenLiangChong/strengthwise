import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_exercise_model.dart';

/// 訓練計劃類型枚舉
enum PlanType {
  fullBody,      // 全身訓練
  upperBody,     // 上半身訓練
  lowerBody,     // 下半身訓練
  push,          // 推動訓練
  pull,          // 拉動訓練
  legs,          // 腿部訓練
  core,          // 核心訓練
  cardio,        // 有氧訓練
  custom         // 自定義
}

/// 訓練計劃類型枚舉擴展方法
extension PlanTypeExtension on PlanType {
  /// 獲取類型的顯示名稱
  String get displayName {
    switch (this) {
      case PlanType.fullBody: return '全身訓練';
      case PlanType.upperBody: return '上半身訓練';
      case PlanType.lowerBody: return '下半身訓練';
      case PlanType.push: return '推動訓練';
      case PlanType.pull: return '拉動訓練';
      case PlanType.legs: return '腿部訓練';
      case PlanType.core: return '核心訓練';
      case PlanType.cardio: return '有氧訓練';
      case PlanType.custom: return '自定義';
    }
  }
  
  /// 從字符串轉換為枚舉值
  static PlanType fromString(String value) {
    switch (value) {
      case '全身訓練': return PlanType.fullBody;
      case '上半身訓練': return PlanType.upperBody;
      case '下半身訓練': return PlanType.lowerBody;
      case '推動訓練': return PlanType.push;
      case '拉動訓練': return PlanType.pull;
      case '腿部訓練': return PlanType.legs;
      case '核心訓練': return PlanType.core;
      case '有氧訓練': return PlanType.cardio;
      case '自定義': return PlanType.custom;
      default: return PlanType.custom;
    }
  }
}

/// 訓練計劃模板模型
///
/// 用於創建和管理用戶的訓練計劃模板，可用於生成訓練記錄
class WorkoutTemplate {
  final String id;                     // 唯一標識符
  final String userId;                 // 用戶ID
  final String title;                  // 標題
  final String description;            // 描述
  final String planType;               // 計劃類型
  final List<WorkoutExercise> exercises; // 訓練動作列表
  final DateTime createdAt;            // 創建時間
  final DateTime updatedAt;            // 更新時間
  final DateTime? trainingTime;        // 計劃訓練時間

  /// 創建一個訓練計劃模板實例
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

  /// 轉換為 JSON 數據格式
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
  
  /// 轉換為 Firestore 可用的數據格式
  Map<String, dynamic> toFirestore() {
    return toJson();
  }

  /// 從 Firestore 文檔創建對象
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
  
  /// 從 JSON 創建對象
  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    DateTime? trainingTime;
    if (json['trainingTime'] != null) {
      trainingTime = DateTime.fromMillisecondsSinceEpoch(json['trainingTime']);
    }
    
    return WorkoutTemplate(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      planType: json['planType'] ?? '',
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      trainingTime: trainingTime,
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt']) 
          : DateTime.now(),
    );
  }
  
  /// 創建一個本對象的副本，並可選擇性地修改某些屬性
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
  
  /// 獲取計劃類型的枚舉值
  PlanType get planTypeEnum => PlanTypeExtension.fromString(planType);
  
  /// 更新最後修改時間
  WorkoutTemplate updateTimestamp() {
    return copyWith(updatedAt: DateTime.now());
  }
  
  /// 添加一個訓練動作到計劃中
  WorkoutTemplate addExercise(WorkoutExercise exercise) {
    return copyWith(
      exercises: [...exercises, exercise],
      updatedAt: DateTime.now(),
    );
  }
  
  /// 刪除指定ID的訓練動作
  WorkoutTemplate removeExercise(String exerciseId) {
    return copyWith(
      exercises: exercises.where((e) => e.id != exerciseId).toList(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// 更新指定ID的訓練動作
  WorkoutTemplate updateExercise(WorkoutExercise updatedExercise) {
    return copyWith(
      exercises: exercises.map((e) => 
        e.id == updatedExercise.id ? updatedExercise : e
      ).toList(),
      updatedAt: DateTime.now(),
    );
  }
  
  @override
  String toString() => 'WorkoutTemplate(id: $id, title: $title, exercises: ${exercises.length})';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutTemplate && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
} 