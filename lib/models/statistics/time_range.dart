/// 時間範圍枚舉
enum TimeRange {
  week,       // 本週
  sevenDays,  // 最近七天 🆕
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
      case TimeRange.sevenDays:
        return '最近七天';
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
        // ⚡ 修正：本週 = 從週一開始
        // weekday: 1=週一, 2=週二, ..., 7=週日
        final weekday = now.weekday;
        final daysFromMonday = weekday - 1; // 週一=0, 週二=1, ..., 週日=6
        final monday = now.subtract(Duration(days: daysFromMonday));
        return DateTime(monday.year, monday.month, monday.day);
      case TimeRange.sevenDays:
        // 🆕 最近七天：從今天往前推 7 天
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);
      case TimeRange.month:
        return DateTime(now.year, now.month, 1);
      case TimeRange.threeMonth:
        return DateTime(now.year, now.month - 3, 1);
      case TimeRange.year:
        return DateTime(now.year, 1, 1);
    }
  }

  /// 獲取結束日期（當天的 23:59:59）
  DateTime get endDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }
}

