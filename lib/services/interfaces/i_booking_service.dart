/// 預約服務接口
/// 
/// 定義與預約相關的所有操作，
/// 提供標準接口以支持不同的實現方式。
abstract class IBookingService {
  /// 服務是否已初始化
  bool get isInitialized;
  
  /// 初始化服務
  Future<void> initialize();
  
  /// 獲取用戶的所有預約
  Future<List<Map<String, dynamic>>> getUserBookings();
  
  /// 獲取教練的所有預約
  Future<List<Map<String, dynamic>>> getCoachBookings();
  
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
  
  /// 獲取可用時段
  Future<List<Map<String, dynamic>>> getAvailableSlots(String coachId);
  
  /// 設置時段已預約
  Future<bool> setSlotBooked(String slotId);
} 