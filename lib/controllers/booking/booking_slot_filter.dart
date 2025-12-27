/// 預約時段過濾器
///
/// 過濾已過期的時段
class BookingSlotFilter {
  /// 過濾掉已過期的時段
  static List<Map<String, dynamic>> filterExpiredSlots(List<Map<String, dynamic>> slots) {
    final now = DateTime.now();
    return slots.where((slot) {
      final dateTime = slot['dateTime'];
      return dateTime != null && dateTime.isAfter(now);
    }).toList();
  }
}

