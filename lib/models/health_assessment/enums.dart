/// 訓練經驗等級
enum TrainingLevel {
  beginner('beginner', '新手'),
  intermediate('intermediate', '中階'),
  advanced('advanced', '進階');

  final String value;
  final String label;
  const TrainingLevel(this.value, this.label);

  static TrainingLevel fromString(String value) {
    return TrainingLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TrainingLevel.beginner,
    );
  }
}

/// 職業活動度
enum ActivityLevel {
  sedentary('sedentary', '久坐'),
  light('light', '輕度活動'),
  moderate('moderate', '中度活動'),
  vigorous('vigorous', '重度勞動');

  final String value;
  final String label;
  const ActivityLevel(this.value, this.label);

  static ActivityLevel fromString(String value) {
    return ActivityLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ActivityLevel.sedentary,
    );
  }
}

