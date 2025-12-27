/// 建議類型
enum SuggestionType {
  warning,    // 警告（例如：某肌群訓練不足）
  info,       // 資訊（例如：訓練多樣性良好）
  success,    // 成功（例如：訓練頻率優秀）
}

/// 訓練建議
class TrainingSuggestion {
  final String title;            // 建議標題
  final String description;      // 建議描述
  final SuggestionType type;     // 建議類型

  TrainingSuggestion({
    required this.title,
    required this.description,
    required this.type,
  });

  @override
  String toString() => 'Suggestion($title)';
}

