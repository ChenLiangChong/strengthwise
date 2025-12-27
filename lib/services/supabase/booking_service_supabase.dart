import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../core/error_handling_service.dart';
import '../interfaces/i_booking_service.dart';
import '../service_locator.dart' show Environment;
import 'booking/booking_cache_manager.dart';
import 'booking/booking_operations.dart';
import 'booking/booking_listener_manager.dart';
import 'booking/booking_notification_service.dart';

/// 預約服務的 Supabase 實現
/// 
/// 提供預約的創建、讀取、更新、取消等功能（Supabase PostgreSQL 版本）
class BookingServiceSupabase implements IBookingService {
  // 依賴注入
  final SupabaseClient _supabase;
  final ErrorHandlingService _errorService;
  
  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;
  
  // 服務配置
  bool _useCache = true;
  int _cacheDuration = 5; // 分鐘
  bool _notificationsEnabled = true;
  
  /// 服務是否已初始化
  @override
  bool get isInitialized => _isInitialized;
  
  // 子模組（各司其職）
  late final BookingCacheManager _cacheManager;
  late final BookingOperations _operations;
  late final BookingListenerManager _listenerManager;
  late final BookingNotificationService _notificationService;
  
  // 事件監聽器
  final StreamController<Map<String, dynamic>> _bookingUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final List<StreamSubscription> _activeSubscriptions = [];
  
  /// 創建服務實例
  /// 
  /// 允許注入自定義的 Supabase 客戶端，便於測試
  BookingServiceSupabase({
    required SupabaseClient supabase,
    ErrorHandlingService? errorService,
  }) : 
    _supabase = supabase,
    _errorService = errorService ?? ErrorHandlingService() {
    // 初始化子模組
    _cacheManager = BookingCacheManager();
    _operations = BookingOperations(
      supabase: _supabase,
      getCurrentUserId: () => currentUserId,
      logDebug: _logDebug,
      logError: _logError,
    );
    _listenerManager = BookingListenerManager(
      supabase: _supabase,
      onBookingChange: _handleBookingChange,
      logDebug: _logDebug,
      logError: _logError,
    );
    _notificationService = BookingNotificationService(
      supabase: _supabase,
    );
  }
  
  /// 初始化服務
  /// 
  /// 設置環境配置並初始化緩存系統
  @override
  Future<void> initialize({Environment environment = Environment.development}) async {
    // 如果已經初始化，直接返回，不要拋出錯誤
    if (_isInitialized) return;
    
    try {
      // 設置環境
      configureForEnvironment(environment);
      
      // 配置快取管理器
      _cacheManager.configure(
        useCache: _useCache,
        cacheDuration: _cacheDuration,
      );
      
      // 設置緩存清理計時器（每小時）
      if (_useCache) {
        _cacheManager.setupCacheCleanupTimer();
      }
      
      // 設置預約更新監聽器
      try {
        await _listenerManager.setupListeners();
      } catch (e) {
        _logError('設置預約監聽器失敗: $e');
        // 繼續執行，不要因為監聽器設置失敗就中斷整個初始化過程
      }
      
      // 配置通知服務
      _notificationService.configure(enabled: _notificationsEnabled);
      
      _isInitialized = true;
      _logDebug('預約服務初始化完成');
    } catch (e) {
      _logError('預約服務初始化失敗: $e');
      // 即使失敗，也標記為已初始化，以避免反覆嘗試初始化
      _isInitialized = true;
      // 不再向上拋出錯誤，讓服務可以繼續使用
    }
  }
  
  /// 釋放資源
  Future<void> dispose() async {
    try {
      // 取消所有活動的訂閱
      for (var subscription in _activeSubscriptions) {
        await subscription.cancel();
      }
      _activeSubscriptions.clear();
      
      // 關閉事件控制器
      await _bookingUpdateController.close();
      
      // 釋放快取管理器
      _cacheManager.dispose();
      
      _isInitialized = false;
      _logDebug('預約服務資源已釋放');
    } catch (e) {
      _logError('釋放預約服務資源時發生錯誤: $e');
    }
  }
  
  /// 根據環境配置服務
  void configureForEnvironment(Environment environment) {
    _environment = environment;
    
    switch (environment) {
      case Environment.development:
        // 開發環境設置
        _useCache = true;
        _cacheDuration = 10; // 較長的緩存時間，便於開發
        _notificationsEnabled = true;
        _logDebug('預約服務配置為開發環境');
        break;
      case Environment.testing:
        // 測試環境設置
        _useCache = false; // 測試需要實時數據，不使用緩存
        _cacheDuration = 2;
        _notificationsEnabled = false;
        _logDebug('預約服務配置為測試環境');
        break;
      case Environment.production:
        // 生產環境設置
        _useCache = true;
        _cacheDuration = 5;
        _notificationsEnabled = true;
        _logDebug('預約服務配置為生產環境');
        break;
    }
  }
  
  /// 處理預約變更事件
  void _handleBookingChange(PostgresChangePayload payload, {required bool isCoach}) {
    try {
      final booking = payload.newRecord;
      if (booking.isEmpty) return;
      
      booking['changeType'] = payload.eventType.name;
      booking['asCoach'] = isCoach;
      
      _bookingUpdateController.add(booking);
      
      // 清除相關緩存
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        if (isCoach) {
          _cacheManager.clearCoachBookings(userId);
        } else {
          _cacheManager.clearUserBookings(userId);
        }
        
        // 清除預約詳情緩存
        final bookingId = booking['id'] as String?;
        if (bookingId != null) {
          _cacheManager.clearBookingDetails(bookingId);
        }
      }
    } catch (e) {
      _logError('處理預約變更事件失敗: $e');
    }
  }
  
  /// 獲取預約更新流
  Stream<Map<String, dynamic>> get bookingUpdates => _bookingUpdateController.stream;
  
  // 獲取當前用戶ID
  String? get currentUserId {
    _ensureInitialized();
    return _supabase.auth.currentUser?.id;
  }
  
  @override
  Future<List<Map<String, dynamic>>> getUserBookings() async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logDebug('獲取用戶預約：沒有登入用戶');
      return [];
    }
    
    final cacheKey = 'user_$currentUserId';
    
    // 檢查緩存是否有效（如果啟用）
    if (_cacheManager.isBookingsListCacheValid(cacheKey)) {
      final cached = _cacheManager.getBookingsList(cacheKey);
      if (cached != null) {
        _logDebug('從緩存獲取用戶預約 (${cached.length} 個)');
        return cached;
      }
    }
    
    try {
      final bookings = await _operations.getUserBookings(currentUserId!);
      
      // 更新緩存
      _cacheManager.cacheBookingsList(cacheKey, bookings);
      
      return bookings;
    } catch (e) {
      _logDebug('Bookings 集合無權限訪問（單機版模式），返回空列表');
      
      // 如果緩存可用但可能已過期，在發生錯誤時仍返回緩存數據
      final cached = _cacheManager.getBookingsList(cacheKey);
      if (cached != null) {
        _logDebug('服務器獲取失敗，返回可能過期的緩存數據');
        return cached;
      }
      
      return [];
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getCoachBookings() async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logDebug('獲取教練預約：沒有登入用戶');
      return [];
    }
    
    final cacheKey = 'coach_$currentUserId';
    
    // 檢查緩存是否有效（如果啟用）
    if (_cacheManager.isBookingsListCacheValid(cacheKey)) {
      final cached = _cacheManager.getBookingsList(cacheKey);
      if (cached != null) {
        _logDebug('從緩存獲取教練預約 (${cached.length} 個)');
        return cached;
      }
    }
    
    try {
      final bookings = await _operations.getCoachBookings(currentUserId!);
      
      // 更新緩存
      _cacheManager.cacheBookingsList(cacheKey, bookings);
      
      return bookings;
    } catch (e) {
      _logDebug('Bookings 集合無權限訪問（單機版模式），返回空列表');
      
      // 如果緩存可用但可能已過期，在發生錯誤時仍返回緩存數據
      final cached = _cacheManager.getBookingsList(cacheKey);
      if (cached != null) {
        _logDebug('服務器獲取失敗，返回可能過期的緩存數據');
        return cached;
      }
      
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    _ensureInitialized();
    
    // 檢查緩存
    if (_cacheManager.hasBookingDetails(bookingId)) {
      _logDebug('從緩存獲取預約詳情: $bookingId');
      return _cacheManager.getBookingDetails(bookingId);
    }
    
    try {
      final data = await _operations.getBookingById(bookingId);
      
      if (data == null) return null;
      
      // 更新緩存
      _cacheManager.cacheBookingDetails(bookingId, data);
      
      return data;
    } catch (e) {
      _logError('獲取預約詳情失敗: $e');
      return null;
    }
  }
  
  @override
  Future<String> createBooking(Map<String, dynamic> bookingData) async {
    _ensureInitialized();
    
    try {
      final bookingId = await _operations.createBooking(bookingData);
      
      // 清除相關緩存
      _cacheManager.clearUserBookings(currentUserId!);
      
      // 如果預約了時段，標記為已預約
      if (bookingData.containsKey('slot_id')) {
        await setSlotBooked(bookingData['slot_id']);
      }
      
      // 發送通知（如果啟用）
      if (bookingData.containsKey('coach_id')) {
        await _notificationService.sendNewBookingNotification(
          bookingData['coach_id'],
          bookingId,
        );
      }
      
      return bookingId;
    } catch (e) {
      _logError('創建預約失敗: $e');
      rethrow;
    }
  }
  
  @override
  Future<bool> updateBooking(String bookingId, Map<String, dynamic> bookingData) async {
    _ensureInitialized();
    
    try {
      // 獲取預約詳情（用於發送通知）
      final bookingDetails = await getBookingById(bookingId);
      if (bookingDetails == null) {
        _logError('預約不存在: $bookingId');
        return false;
      }
      
      final success = await _operations.updateBooking(bookingId, bookingData);
      
      if (!success) return false;
      
      // 清除緩存
      _cacheManager.clearUserBookings(currentUserId!);
      if (bookingDetails.containsKey('coach_id')) {
        final coachId = bookingDetails['coach_id'];
        if (coachId == currentUserId) {
          _cacheManager.clearCoachBookings(currentUserId!);
        }
      }
      _cacheManager.clearBookingDetails(bookingId);
      
      // 發送通知（如果啟用且狀態有變化）
      if (bookingData.containsKey('status')) {
        await _notificationService.sendStatusChangeNotification(
          bookingData['status'],
          bookingDetails,
          bookingId,
          currentUserId!,
        );
      }
      
      return true;
    } catch (e) {
      _logError('更新預約失敗: $e');
      return false;
    }
  }
  
  @override
  Future<bool> cancelBooking(String bookingId) async {
    _ensureInitialized();
    
    try {
      final success = await _operations.cancelBooking(bookingId);
      
      if (!success) return false;
      
      // 清除緩存
      _cacheManager.clearUserBookings(currentUserId!);
      _cacheManager.clearCoachBookings(currentUserId!);
      _cacheManager.clearBookingDetails(bookingId);
      
      return true;
    } catch (e) {
      _logError('取消預約失敗: $e');
      return false;
    }
  }
  
  @override
  Future<bool> confirmBooking(String bookingId) async {
    _ensureInitialized();
    
    try {
      // 獲取預約詳情（用於發送通知）
      final bookingDetails = await getBookingById(bookingId);
      if (bookingDetails == null) {
        _logError('預約不存在: $bookingId');
        return false;
      }
      
      final success = await _operations.confirmBooking(bookingId);
      
      if (!success) return false;
      
      // 清除緩存
      _cacheManager.clearCoachBookings(currentUserId!);
      _cacheManager.clearBookingDetails(bookingId);
      
      // 發送通知（如果啟用）
      await _notificationService.sendConfirmationNotification(
        bookingDetails['user_id'],
        bookingId,
      );
      
      return true;
    } catch (e) {
      _logError('確認預約失敗: $e');
      return false;
    }
  }
  
  @override
  Future<bool> deleteBooking(String bookingId) async {
    _ensureInitialized();
    
    try {
      final success = await _operations.deleteBooking(bookingId);
      
      if (!success) return false;
      
      // 清除緩存
      _cacheManager.clearUserBookings(currentUserId!);
      _cacheManager.clearCoachBookings(currentUserId!);
      _cacheManager.clearBookingDetails(bookingId);
      
      return true;
    } catch (e) {
      _logError('刪除預約失敗: $e');
      return false;
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getAvailableSlots(String coachId) async {
    _ensureInitialized();
    
    final cacheKey = 'slots_$coachId';
    
    // 檢查緩存是否有效（如果啟用）
    if (_cacheManager.isSlotsCacheValid(cacheKey)) {
      final cached = _cacheManager.getSlotsList(cacheKey);
      if (cached != null) {
        _logDebug('從緩存獲取可用時段 (${cached.length} 個)');
        return cached;
      }
    }
    
    try {
      final slots = await _operations.getAvailableSlots(coachId);
      
      // 更新緩存
      _cacheManager.cacheSlotsList(cacheKey, slots);
      
      return slots;
    } catch (e) {
      _logError('獲取可用時段失敗: $e');
      
      // 如果緩存可用但可能已過期，在發生錯誤時仍返回緩存數據
      final cached = _cacheManager.getSlotsList(cacheKey);
      if (cached != null) {
        _logDebug('服務器獲取失敗，返回可能過期的緩存數據');
        return cached;
      }
      
      return [];
    }
  }
  
  @override
  Future<bool> setSlotBooked(String slotId) async {
    _ensureInitialized();
    
    try {
      final success = await _operations.setSlotBooked(slotId);
      
      // 清除相關緩存
      _cacheManager.clearAllSlots();
      
      return success;
    } catch (e) {
      _logError('設置時段已預約失敗: $e');
      return false;
    }
  }
  
  /// 檢查用戶是否有即將到來的預約
  Future<List<Map<String, dynamic>>> getUpcomingBookings() async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      return [];
    }
    
    try {
      return await _operations.getUpcomingBookings(currentUserId!);
    } catch (e) {
      _logError('獲取即將到來的預約失敗: $e');
      return [];
    }
  }
  
  /// 確保服務已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      _logDebug('警告: 預約服務在初始化前被調用');
      // 在開發環境中自動初始化，但在其他環境拋出錯誤
      if (_environment == Environment.development) {
        // 直接設置標誌而不是調用 initialize() 方法，避免堆疊溢出
        _isInitialized = true;
        // 必要的初始化可以在這裡同步執行
        // 但不要調用 initialize() 方法，因為這可能導致循環調用
        Future.microtask(() => initialize());
      } else {
        throw StateError('預約服務未初始化');
      }
    }
  }
  
  /// 記錄調試信息
  void _logDebug(String message) {
    if (kDebugMode) {
      print('[BOOKING] $message');
    }
  }
  
  /// 記錄錯誤信息
  void _logError(String message) {
    if (kDebugMode) {
      print('[BOOKING ERROR] $message');
    }
    
    _errorService.logError(message);
  }
}

