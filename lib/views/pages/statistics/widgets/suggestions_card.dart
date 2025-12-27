import 'package:flutter/material.dart';
import '../../../../models/statistics_model.dart';

/// 訓練建議卡片組件
///
/// 顯示基於統計數據的訓練建議
class SuggestionsCard extends StatelessWidget {
  /// 訓練建議列表
  final List<TrainingSuggestion> suggestions;

  const SuggestionsCard({
    Key? key,
    required this.suggestions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, size: 20),
                SizedBox(width: 8),
                Text(
                  '訓練建議',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...suggestions.map(
              (suggestion) => ListTile(
                leading: Icon(
                  _getSuggestionIcon(suggestion.type),
                  color: _getSuggestionColor(context, suggestion.type),
                ),
                title: Text(suggestion.title),
                subtitle: Text(suggestion.description),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根據建議類型返回圖標
  static IconData _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.warning:
        return Icons.warning;
      case SuggestionType.info:
        return Icons.info;
      case SuggestionType.success:
        return Icons.check_circle;
    }
  }

  /// 根據建議類型返回顏色
  static Color _getSuggestionColor(BuildContext context, SuggestionType type) {
    switch (type) {
      case SuggestionType.warning:
        return Theme.of(context).colorScheme.primary;
      case SuggestionType.info:
        return Colors.blue;
      case SuggestionType.success:
        return Theme.of(context).colorScheme.secondary;
    }
  }
}
