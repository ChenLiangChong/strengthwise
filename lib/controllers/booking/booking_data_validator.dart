/// 預約數據驗證器
///
/// 驗證預約數據的有效性
class BookingDataValidator {
  /// 驗證創建預約的數據
  static void validateCreateBooking(Map<String, dynamic> bookingData) {
    if (bookingData['coachId'] == null || bookingData['coachId'].toString().isEmpty) {
      throw ArgumentError('教練ID不能為空');
    }
    
    if (bookingData['dateTime'] == null) {
      throw ArgumentError('預約時間不能為空');
    }
  }
}

