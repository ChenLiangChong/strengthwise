import '../../../models/exercise_model.dart';

/// 動作搜尋引擎（客戶端）
class ExerciseSearchEngine {
  /// 從快取中搜尋動作
  List<Exercise> searchFromCache({
    required List<Exercise> cache,
    required String query,
    required int limit,
  }) {
    final lowerQuery = query.toLowerCase();
    
    return cache
        .where((exercise) {
          return exercise.name.toLowerCase().contains(lowerQuery) ||
              exercise.nameEn.toLowerCase().contains(lowerQuery) ||
              (exercise.level1.isNotEmpty &&
                  exercise.level1.toLowerCase().contains(lowerQuery)) ||
              (exercise.level2.isNotEmpty &&
                  exercise.level2.toLowerCase().contains(lowerQuery));
        })
        .take(limit)
        .toList();
  }

  /// 從快取中依過濾條件篩選
  List<Exercise> filterFromCache({
    required List<Exercise> cache,
    required Map<String, String> filters,
  }) {
    var exercises = cache;

    for (final entry in filters.entries) {
      if (entry.value.isEmpty) continue;

      if (entry.key == 'bodyPart') {
        exercises = exercises.where((e) => e.bodyPart == entry.value).toList();
      } else if (entry.key == 'type') {
        exercises = exercises.where((e) => e.trainingType == entry.value).toList();
      } else if (entry.key == 'level1') {
        exercises = exercises.where((e) => e.level1 == entry.value).toList();
      } else if (entry.key == 'level2') {
        exercises = exercises.where((e) => e.level2 == entry.value).toList();
      } else if (entry.key == 'level3') {
        exercises = exercises.where((e) => e.level3 == entry.value).toList();
      } else if (entry.key == 'level4') {
        exercises = exercises.where((e) => e.level4 == entry.value).toList();
      } else if (entry.key == 'level5') {
        exercises = exercises.where((e) => e.level5 == entry.value).toList();
      }
    }

    return exercises;
  }
}

