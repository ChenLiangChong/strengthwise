/// 預約數據緩存管理器
///
/// 管理預約相關的本地緩存
class BookingCacheManager {
  // 數據緩存
  List<Map<String, dynamic>>? _userBookingsCache;
  List<Map<String, dynamic>>? _coachBookingsCache;
  List<Map<String, dynamic>>? _availableSlotsCache;
  final Map<String, Map<String, dynamic>> _bookingDetailsCache = {};
  final Map<String, DateTime> _lastRefreshTime = {};
  
  /// 緩存有效期（分鐘）
  static const int cacheExpiryMinutes = 5;
  
  /// 獲取用戶預約緩存
  List<Map<String, dynamic>>? get userBookingsCache => _userBookingsCache;
  
  /// 設置用戶預約緩存
  set userBookingsCache(List<Map<String, dynamic>>? value) {
    _userBookingsCache = value;
  }
  
  /// 獲取教練預約緩存
  List<Map<String, dynamic>>? get coachBookingsCache => _coachBookingsCache;
  
  /// 設置教練預約緩存
  set coachBookingsCache(List<Map<String, dynamic>>? value) {
    _coachBookingsCache = value;
  }
  
  /// 獲取可用時段緩存
  List<Map<String, dynamic>>? get availableSlotsCache => _availableSlotsCache;
  
  /// 設置可用時段緩存
  set availableSlotsCache(List<Map<String, dynamic>>? value) {
    _availableSlotsCache = value;
  }
  
  /// 獲取預約詳情
  Map<String, dynamic>? getBookingDetails(String bookingId) {
    return _bookingDetailsCache[bookingId];
  }
  
  /// 設置預約詳情
  void setBookingDetails(String bookingId, Map<String, dynamic> booking) {
    _bookingDetailsCache[bookingId] = booking;
  }
  
  /// 檢查預約詳情是否已緩存
  bool hasBookingDetails(String bookingId) {
    return _bookingDetailsCache.containsKey(bookingId);
  }
  
  /// 檢查緩存是否需要刷新
  bool shouldRefresh(String cacheKey) {
    final lastRefresh = _lastRefreshTime[cacheKey];
    if (lastRefresh == null) return true;
    
    final now = DateTime.now();
    return now.difference(lastRefresh).inMinutes > cacheExpiryMinutes;
  }
  
  /// 更新最後刷新時間
  void updateRefreshTime(String cacheKey) {
    _lastRefreshTime[cacheKey] = DateTime.now();
  }
  
  /// 從用戶預約緩存中查找
  Map<String, dynamic>? findInUserBookings(String bookingId) {
    if (_userBookingsCache == null) return null;
    return _userBookingsCache!
        .where((b) => b['id'] == bookingId)
        .firstOrNull;
  }
  
  /// 從教練預約緩存中查找
  Map<String, dynamic>? findInCoachBookings(String bookingId) {
    if (_coachBookingsCache == null) return null;
    return _coachBookingsCache!
        .where((b) => b['id'] == bookingId)
        .firstOrNull;
  }
  
  /// 清除特定類型的緩存
  void clearCache(String cacheType) {
    switch (cacheType) {
      case 'all':
        _userBookingsCache = null;
        _coachBookingsCache = null;
        _availableSlotsCache = null;
        _bookingDetailsCache.clear();
        _lastRefreshTime.clear();
        break;
      case 'userBookings':
        _userBookingsCache = null;
        _lastRefreshTime.remove('userBookings');
        break;
      case 'coachBookings':
        _coachBookingsCache = null;
        _lastRefreshTime.remove('coachBookings');
        break;
      case 'availableSlots':
        _availableSlotsCache = null;
        _lastRefreshTime.remove('availableSlots');
        break;
      case 'bookingDetails':
        _bookingDetailsCache.clear();
        break;
    }
  }
  
  /// 移除特定預約的詳情緩存
  void removeBookingDetails(String bookingId) {
    _bookingDetailsCache.remove(bookingId);
  }
}

