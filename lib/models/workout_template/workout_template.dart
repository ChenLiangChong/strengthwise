import 'workout_exercise.dart';
import 'plan_type_enum.dart';
import 'workout_template_mapper.dart';

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
    return WorkoutTemplateMapper.toJson(this);
  }
  
  /// 從 JSON 創建對象
  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplateMapper.fromJson(json);
  }

  /// 從 Supabase 數據創建對象（snake_case 欄位）
  factory WorkoutTemplate.fromSupabase(Map<String, dynamic> json) {
    return WorkoutTemplateMapper.fromSupabase(json);
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

