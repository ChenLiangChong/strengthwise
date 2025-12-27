/// 時間範圍枚舉
enum TimeRange {
  week,       // 本週
  month,      // 本月
  threeMonth, // 三個月
  year,       // 本年
}

/// 時間範圍擴展方法
extension TimeRangeExtension on TimeRange {
  /// 獲取顯示名稱
  String get displayName {
    switch (this) {
      case TimeRange.week:
        return '本週';
      case TimeRange.month:
        return '本月';
      case TimeRange.threeMonth:
        return '三個月';
      case TimeRange.year:
        return '本年';
    }
  }

  /// 獲取起始日期
  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case TimeRange.week:
        // ⚡ 修正：本週 = 從週日開始（ISO 8601）
        // weekday: 1=週一, 2=週二, ..., 7=週日
        final weekday = now.weekday;
        final daysFromSunday = weekday % 7; // 週日=0, 週一=1, ..., 週六=6
        final sunday = now.subtract(Duration(days: daysFromSunday));
        // 返回當週週日的 00:00:00
        return DateTime(sunday.year, sunday.month, sunday.day);
      case TimeRange.month:
        return DateTime(now.year, now.month, 1);
      case TimeRange.threeMonth:
        return DateTime(now.year, now.month - 3, 1);
      case TimeRange.year:
        return DateTime(now.year, 1, 1);
    }
  }

  /// 獲取結束日期
  DateTime get endDate => DateTime.now();
}

