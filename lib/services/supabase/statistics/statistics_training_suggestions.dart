import '../../../models/statistics_model.dart';

/// 訓練建議生成器
///
/// 根據統計數據生成個性化訓練建議
class TrainingSuggestionsGenerator {
  /// 生成訓練建議
  List<TrainingSuggestion> generateSuggestions(StatisticsData statisticsData) {
    final suggestions = <TrainingSuggestion>[];

    // 檢查訓練頻率
    _checkTrainingFrequency(statisticsData, suggestions);

    // 檢查肌群平衡
    _checkMuscleBalance(statisticsData, suggestions);

    // 檢查訓練類型多樣性
    _checkTrainingDiversity(statisticsData, suggestions);

    return suggestions;
  }

  /// 檢查訓練頻率
  void _checkTrainingFrequency(
    StatisticsData statisticsData,
    List<TrainingSuggestion> suggestions,
  ) {
    if (statisticsData.frequency.totalWorkouts < 3) {
      suggestions.add(TrainingSuggestion(
        title: '訓練頻率偏低',
        description: '建議每週至少訓練 3-4 次以獲得最佳效果',
        type: SuggestionType.warning,
      ));
    } else if (statisticsData.frequency.totalWorkouts >= 5) {
      suggestions.add(TrainingSuggestion(
        title: '訓練頻率優秀',
        description: '保持良好的訓練習慣！',
        type: SuggestionType.success,
      ));
    }
  }

  /// 檢查肌群平衡
  void _checkMuscleBalance(
    StatisticsData statisticsData,
    List<TrainingSuggestion> suggestions,
  ) {
    if (statisticsData.bodyPartStats.isNotEmpty) {
      final sortedStats =
          List<BodyPartStats>.from(statisticsData.bodyPartStats);
      sortedStats.sort((a, b) => a.percentage.compareTo(b.percentage));

      final lowest = sortedStats.first;
      if (lowest.percentage < 0.1 && lowest.workoutCount > 0) {
        suggestions.add(TrainingSuggestion(
          title: '${lowest.bodyPart}訓練較少',
          description: '建議增加${lowest.bodyPart}的訓練頻率，保持全面發展',
          type: SuggestionType.warning,
        ));
      }
    }
  }

  /// 檢查訓練類型多樣性
  void _checkTrainingDiversity(
    StatisticsData statisticsData,
    List<TrainingSuggestion> suggestions,
  ) {
    final trainingTypes = statisticsData.trainingTypeStats;
    final hasCardio = trainingTypes.any((t) => t.trainingType == '有氧');
    final hasStretching = trainingTypes.any((t) => t.trainingType == '伸展');

    if (!hasCardio && !hasStretching) {
      suggestions.add(TrainingSuggestion(
        title: '建議增加有氧和伸展',
        description: '在重訓之外,適當的有氧和伸展可以提升整體健康',
        type: SuggestionType.info,
      ));
    }
  }
}
