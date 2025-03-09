/// 預約控制器接口
/// 
/// 定義與預約相關的業務邏輯操作。
abstract class IBookingController {
  /// 載入用戶預約
  Future<List<Map<String, dynamic>>> loadUserBookings();
  
  /// 載入教練預約
  Future<List<Map<String, dynamic>>> loadCoachBookings();
  
  /// 獲取特定預約
  Future<Map<String, dynamic>?> getBookingById(String bookingId);
  
  /// 創建預約
  Future<String> createBooking(Map<String, dynamic> bookingData);
  
  /// 更新預約
  Future<bool> updateBooking(String bookingId, Map<String, dynamic> bookingData);
  
  /// 取消預約
  Future<bool> cancelBooking(String bookingId);
  
  /// 確認預約
  Future<bool> confirmBooking(String bookingId);
  
  /// 刪除預約
  Future<bool> deleteBooking(String bookingId);
  
  /// 載入可用時段
  Future<List<Map<String, dynamic>>> loadAvailableSlots(String coachId);
  
  /// 設置時段已預約
  Future<bool> setSlotBooked(String slotId);
} 