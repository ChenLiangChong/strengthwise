import '../../../models/exercise_model.dart';
import '../../core/error_handling_service.dart';

/// 動作資料解析器
class ExerciseDataParser {
  final ErrorHandlingService? _errorService;

  ExerciseDataParser({
    required ErrorHandlingService? errorService,
  }) : _errorService = errorService;

  /// 解析動作列表
  List<Exercise> parseExerciseList(List<dynamic> data) {
    List<Exercise> exercises = [];
    
    for (var item in data) {
      try {
        final exercise = Exercise.fromSupabase(item);
        exercises.add(exercise);
      } catch (e) {
        _errorService?.logError('解析動作失敗: ${item['id']} - $e');
      }
    }
    
    return exercises;
  }

  /// 解析單個動作
  Exercise? parseExercise(Map<String, dynamic>? data) {
    if (data == null) return null;
    
    try {
      return Exercise.fromSupabase(data);
    } catch (e) {
      _errorService?.logError('解析動作失敗: ${data['id']} - $e');
      return null;
    }
  }

  /// 將自訂動作轉換為 Exercise 格式
  Exercise? parseCustomExercise(Map<String, dynamic> data) {
    try {
      final customExercise = {
        'id': data['id'],
        'name': data['name'],
        'name_en': '',
        'body_parts': [data['body_part']],
        'type': data['training_type'] ?? '阻力訓練',
        'equipment': data['equipment'] ?? '徒手',
        'joint_type': '',
        'level1': '',
        'level2': '',
        'level3': '',
        'level4': '',
        'level5': '',
        'action_name': data['name'],
        'description': data['description'] ?? '用戶自訂動作',
        'image_url': '',
        'video_url': '',
        'apps': [],
        'created_at': data['created_at'],
        'training_type': data['training_type'] ?? '阻力訓練',
        'body_part': data['body_part'],
        'specific_muscle': '',
        'equipment_category': data['equipment'] ?? '徒手',
        'equipment_subcategory': '',
      };

      return Exercise.fromSupabase(customExercise);
    } catch (e) {
      _errorService?.logError('解析自訂動作失敗: ${data['id']} - $e');
      return null;
    }
  }

  /// 提取分類層級的唯一值
  List<String> extractCategoriesFromLevel(List<dynamic> data, int level) {
    Set<String> categories = {};
    final fieldName = 'level$level';
    
    for (var item in data) {
      final category = item[fieldName] as String? ?? '';
      if (category.isNotEmpty) {
        categories.add(category);
      }
    }

    return categories.toList()..sort();
  }
}

