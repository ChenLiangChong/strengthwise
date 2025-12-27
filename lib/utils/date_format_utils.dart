/// 日期格式化工具類別
///
/// 提供日期格式化相關的工具方法
class DateFormatUtils {
  /// 格式化相對日期
  ///
  /// 將日期轉換為相對於現在的描述（今天、昨天、N天前等）
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return '今天';
    if (difference == 1) return '昨天';
    if (difference < 7) return '$difference 天前';
    if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks 週前';
    }
    return '${date.month}/${date.day}';
  }

  /// 格式化日期顯示
  /// 
  /// 規則：
  /// - 今天顯示「今天」
  /// - 同年顯示「M月D日」
  /// - 跨年顯示「YYYY/M/D」
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '今天';
    } else if (date.year == now.year) {
      return '${date.month}月${date.day}日';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }
}

