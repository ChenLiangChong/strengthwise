import 'workout_template.dart';
import 'workout_exercise.dart';
import 'package:strengthwise/utils/datetime_utils.dart';  // ⭐ 新增

/// 訓練計劃模板數據映射器
///
/// 負責在不同數據格式（JSON、Supabase）之間轉換 WorkoutTemplate
class WorkoutTemplateMapper {
  /// 從 JSON 創建對象（客戶端格式）
  static WorkoutTemplate fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      planType: json['planType'] ?? '',
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  /// 從 Supabase 數據創建對象（snake_case 欄位）
  static WorkoutTemplate fromSupabase(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      planType: json['plan_type'] ?? '',
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: json['created_at'] != null 
          ? DateTimeUtils.parseIsoTimestamp(json['created_at'])  // ⭐ 統一工具類
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTimeUtils.parseIsoTimestamp(json['updated_at'])  // ⭐ 統一工具類
          : DateTime.now(),
    );
  }

  /// 轉換為 JSON 數據格式
  static Map<String, dynamic> toJson(WorkoutTemplate template) {
    return {
      'userId': template.userId,
      'title': template.title,
      'description': template.description,
      'planType': template.planType,
      'exercises': template.exercises.map((e) => e.toJson()).toList(),
      'createdAt': DateTimeUtils.formatToUtcIso(template.createdAt),
      'updatedAt': DateTimeUtils.formatToUtcIso(template.updatedAt),
    };
  }
}

