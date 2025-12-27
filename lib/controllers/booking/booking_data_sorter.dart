/// 預約數據排序器
///
/// 對預約數據進行排序
class BookingDataSorter {
  /// 按日期排序預約列表
  static List<Map<String, dynamic>> sortByDate(List<Map<String, dynamic>> bookings) {
    final mutableBookings = List<Map<String, dynamic>>.from(bookings);
    mutableBookings.sort((a, b) {
      final aTime = a['dateTime'] ?? a['date'];
      final bTime = b['dateTime'] ?? b['date'];
      if (aTime == null || bTime == null) return 0;
      return aTime.compareTo(bTime);
    });
    return mutableBookings;
  }
}

