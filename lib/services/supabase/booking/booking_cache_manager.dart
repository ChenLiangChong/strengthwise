import 'dart:async';
import 'package:flutter/foundation.dart';

/// 預約服務快取管理器
///
/// 管理預約數據的快取
class BookingCacheManager {
  final Map<String, List<Map<String, dynamic>>> _bookingsCache = {};
  final Map<String, DateTime> _bookingsCacheTime = {};
  final Map<String, Map<String, dynamic>> _bookingDetailsCache = {};
  final Map<String, List<Map<String, dynamic>>> _availableSlotsCache = {};
  final Map<String, DateTime> _availableSlotsCacheTime = {};
  Timer? _cacheClearTimer;

  // 配置
  bool _useCache = true;
  int _cacheDuration = 5; // 分鐘

  void configure({required bool useCache, required int cacheDuration}) {
    _useCache = useCache;
    _cacheDuration = cacheDuration;
  }

  /// 設置快取清理計時器
  void setupCacheCleanupTimer() {
    _cacheClearTimer?.cancel();
    _cacheClearTimer = Timer.periodic(const Duration(hours: 1), (_) {
      clearAll();
    });
  }

  /// 檢查預約列表快取是否有效
  bool isBookingsListCacheValid(String cacheKey) {
    if (!_useCache) return false;
    if (!_bookingsCache.containsKey(cacheKey)) return false;
    if (!_bookingsCacheTime.containsKey(cacheKey)) return false;

    final cacheAge = DateTime.now().difference(_bookingsCacheTime[cacheKey]!);
    return cacheAge.inMinutes < _cacheDuration;
  }

  /// 取得快取的預約列表
  List<Map<String, dynamic>>? getBookingsList(String cacheKey) {
    if (!_bookingsCache.containsKey(cacheKey)) return null;
    return List.unmodifiable(_bookingsCache[cacheKey]!);
  }

  /// 更新預約列表快取
  void cacheBookingsList(String cacheKey, List<Map<String, dynamic>> bookings) {
    if (!_useCache) return;
    _bookingsCache[cacheKey] = bookings;
    _bookingsCacheTime[cacheKey] = DateTime.now();
  }

  /// 檢查預約詳情快取
  bool hasBookingDetails(String bookingId) {
    return _useCache && _bookingDetailsCache.containsKey(bookingId);
  }

  /// 取得快取的預約詳情
  Map<String, dynamic>? getBookingDetails(String bookingId) {
    if (!_bookingDetailsCache.containsKey(bookingId)) return null;
    return Map.from(_bookingDetailsCache[bookingId]!);
  }

  /// 更新預約詳情快取
  void cacheBookingDetails(String bookingId, Map<String, dynamic> data) {
    if (!_useCache) return;
    _bookingDetailsCache[bookingId] = data;
  }

  /// 檢查時段列表快取是否有效
  bool isSlotsCacheValid(String cacheKey) {
    if (!_useCache) return false;
    if (!_availableSlotsCache.containsKey(cacheKey)) return false;
    if (!_availableSlotsCacheTime.containsKey(cacheKey)) return false;

    final cacheAge = DateTime.now().difference(_availableSlotsCacheTime[cacheKey]!);
    return cacheAge.inMinutes < _cacheDuration;
  }

  /// 取得快取的時段列表
  List<Map<String, dynamic>>? getSlotsList(String cacheKey) {
    if (!_availableSlotsCache.containsKey(cacheKey)) return null;
    return List.unmodifiable(_availableSlotsCache[cacheKey]!);
  }

  /// 更新時段列表快取
  void cacheSlotsList(String cacheKey, List<Map<String, dynamic>> slots) {
    if (!_useCache) return;
    _availableSlotsCache[cacheKey] = slots;
    _availableSlotsCacheTime[cacheKey] = DateTime.now();
  }

  /// 清除特定使用者的預約快取
  void clearUserBookings(String userId) {
    final cacheKey = 'user_$userId';
    _bookingsCache.remove(cacheKey);
    _bookingsCacheTime.remove(cacheKey);
  }

  /// 清除特定教練的預約快取
  void clearCoachBookings(String userId) {
    final cacheKey = 'coach_$userId';
    _bookingsCache.remove(cacheKey);
    _bookingsCacheTime.remove(cacheKey);
  }

  /// 清除特定預約的詳情快取
  void clearBookingDetails(String bookingId) {
    _bookingDetailsCache.remove(bookingId);
  }

  /// 清除所有時段快取
  void clearAllSlots() {
    _availableSlotsCache.clear();
    _availableSlotsCacheTime.clear();
  }

  /// 清除所有快取
  void clearAll() {
    _logDebug('清理預約快取');
    _bookingsCache.clear();
    _bookingsCacheTime.clear();
    _bookingDetailsCache.clear();
    _availableSlotsCache.clear();
    _availableSlotsCacheTime.clear();
  }

  /// 釋放資源
  void dispose() {
    _cacheClearTimer?.cancel();
    _cacheClearTimer = null;
    clearAll();
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      print('[BOOKING_CACHE] $message');
    }
  }
}

