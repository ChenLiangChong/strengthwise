import 'package:flutter/material.dart';
import 'dart:async';
import '../services/interfaces/i_booking_service.dart';
import '../services/core/error_handling_service.dart';
import '../services/service_locator.dart' show serviceLocator;
import 'interfaces/i_booking_controller.dart';
import 'booking/booking_cache_manager.dart';
import 'booking/booking_data_validator.dart';
import 'booking/booking_data_sorter.dart';
import 'booking/booking_slot_filter.dart';

/// 預約控制器實現
/// 
/// 管理用戶和教練預約的業務邏輯，提供數據驗證，錯誤處理和狀態管理功能
class BookingController extends ChangeNotifier implements IBookingController {
  // 依賴注入
  final IBookingService _bookingService;
  final ErrorHandlingService _errorService;
  
  // 狀態管理
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();
  
  // 子模組
  late final BookingCacheManager _cacheManager;
  
  /// 正在載入數據
  bool get isLoading => _isLoading;
  
  /// 錯誤訊息
  String? get errorMessage => _errorMessage;
  
  /// 緩存的用戶預約
  List<Map<String, dynamic>> get cachedUserBookings => _cacheManager.userBookingsCache ?? [];
  
  /// 緩存的教練預約
  List<Map<String, dynamic>> get cachedCoachBookings => _cacheManager.coachBookingsCache ?? [];
  
  /// 緩存的可用時段
  List<Map<String, dynamic>> get cachedAvailableSlots => _cacheManager.availableSlotsCache ?? [];
  
  /// 初始化完成的Future
  Future<void> get initialized => _initCompleter.future;
  
  /// 構造函數，支持依賴注入
  BookingController({
    IBookingService? bookingService,
    ErrorHandlingService? errorService,
  }) : 
    _bookingService = bookingService ?? serviceLocator<IBookingService>(),
    _errorService = errorService ?? serviceLocator<ErrorHandlingService>() {
    // 初始化子模組
    _cacheManager = BookingCacheManager();
    _initialize();
  }
  
  /// 初始化控制器
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      
      bool isBookingServiceInitialized = false;
      
      // 嘗試以一個隔離的方式調用 BookingService
      try {
        // 使用 try-catch 包裝所有訪問 BookingService 的操作
        isBookingServiceInitialized = _bookingService.isInitialized;
      } catch (e) {
        _logDebug('檢查 BookingService 初始化狀態時出錯: ${e.toString()}');
        // 發生錯誤時，我們假設服務未初始化
        isBookingServiceInitialized = false;
      }
      
      if (!isBookingServiceInitialized) {
        _logDebug('檢測到預約服務尚未初始化，將嘗試初始化');
        
        // 使用超時和錯誤隔離機制
        try {
          // 嘗試初始化 BookingService
          bool initSuccess = false;
          await Future.any<void>([
            Future(() async {
              try {
                await _bookingService.initialize();
                initSuccess = true;
                _logDebug('預約服務初始化成功完成');
              } catch (e) {
                _logDebug('標準初始化方法失敗: ${e.toString()}');
              }
            }),
            Future.delayed(const Duration(seconds: 3), () {
              if (!initSuccess) {
                _logDebug('預約服務初始化超時，將繼續執行');
              }
            })
          ]);
        } catch (e) {
          _logDebug('預約服務初始化過程中發生錯誤: ${e.toString()}');
        }
      } else {
        _logDebug('預約服務已經初始化，跳過初始化步驟');
      }
      
      // 無論 BookingService 初始化是否成功，都標記控制器為已初始化
      // 這確保應用UI不會被卡住
      _isInitialized = true;
      _setLoading(false);
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
      _logDebug('預約控制器初始化完成');
    } catch (e) {
      _logDebug('預約控制器初始化過程中發生錯誤: ${e.toString()}');
      _handleError('初始化預約控制器失敗', e);
      
      // 即使發生錯誤，也要標記為已初始化，防止界面卡住
      _isInitialized = true;
      
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
    }
  }
  
  /// 設置載入狀態
  void _setLoading(bool isLoading) {
    if (_isLoading != isLoading) {
      _isLoading = isLoading;
      notifyListeners();
    }
  }
  
  /// 處理錯誤
  void _handleError(String message, [dynamic error]) {
    _errorMessage = message;
    _errorService.logError('$message: $error', type: 'BookingControllerError');
    _setLoading(false);
    notifyListeners();
  }
  
  /// 清除錯誤消息
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
  
  /// 清除特定類型的緩存
  void clearCache(String cacheType) {
    _cacheManager.clearCache(cacheType);
  }
  
  /// 釋放資源
  @override
  void dispose() {
    _isInitialized = false;
    clearCache('all');
    super.dispose();
  }
  
  @override
  Future<List<Map<String, dynamic>>> loadUserBookings() async {
    if (!_isInitialized) await _initialize();
    
    try {
      // 檢查是否需要重新載入
      final shouldRefresh = _cacheManager.shouldRefresh('userBookings');
      
      if (shouldRefresh || _cacheManager.userBookingsCache == null) {
        _setLoading(true);
        clearError();
        
        final bookings = await _bookingService.getUserBookings();
        
        // 排序並緩存
        final sortedBookings = BookingDataSorter.sortByDate(bookings);
        _cacheManager.userBookingsCache = sortedBookings;
        _cacheManager.updateRefreshTime('userBookings');
        
        _setLoading(false);
      }
      
      return _cacheManager.userBookingsCache ?? [];
    } catch (e) {
      _handleError('載入用戶預約失敗', e);
      return _cacheManager.userBookingsCache ?? [];
    }
  }
  
  /// 強制重新載入用戶預約，忽略緩存
  Future<List<Map<String, dynamic>>> reloadUserBookings() async {
    clearCache('userBookings');
    return loadUserBookings();
  }
  
  @override
  Future<List<Map<String, dynamic>>> loadCoachBookings() async {
    if (!_isInitialized) await _initialize();
    
    try {
      // 檢查是否需要重新載入
      final shouldRefresh = _cacheManager.shouldRefresh('coachBookings');
      
      if (shouldRefresh || _cacheManager.coachBookingsCache == null) {
        _setLoading(true);
        clearError();
        
        final bookings = await _bookingService.getCoachBookings();
        
        // 排序並緩存
        final sortedBookings = BookingDataSorter.sortByDate(bookings);
        _cacheManager.coachBookingsCache = sortedBookings;
        _cacheManager.updateRefreshTime('coachBookings');
        
        _setLoading(false);
      }
      
      return _cacheManager.coachBookingsCache ?? [];
    } catch (e) {
      _handleError('載入教練預約失敗', e);
      return _cacheManager.coachBookingsCache ?? [];
    }
  }
  
  /// 強制重新載入教練預約，忽略緩存
  Future<List<Map<String, dynamic>>> reloadCoachBookings() async {
    clearCache('coachBookings');
    return loadCoachBookings();
  }
  
  @override
  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      // 從緩存中查找
      if (_cacheManager.hasBookingDetails(bookingId)) {
        return _cacheManager.getBookingDetails(bookingId);
      }
      
      // 從用戶預約緩存中查找
      final userBooking = _cacheManager.findInUserBookings(bookingId);
      if (userBooking != null) {
        _cacheManager.setBookingDetails(bookingId, userBooking);
        return userBooking;
      }
      
      // 從教練預約緩存中查找
      final coachBooking = _cacheManager.findInCoachBookings(bookingId);
      if (coachBooking != null) {
        _cacheManager.setBookingDetails(bookingId, coachBooking);
        return coachBooking;
      }
      
      // 從服務獲取
      _setLoading(true);
      clearError();
      
      final booking = await _bookingService.getBookingById(bookingId);
      
      if (booking != null) {
        _cacheManager.setBookingDetails(bookingId, booking);
      }
      
      _setLoading(false);
      return booking;
    } catch (e) {
      _handleError('獲取預約詳情失敗', e);
      return null;
    }
  }
  
  @override
  Future<String> createBooking(Map<String, dynamic> bookingData) async {
    if (!_isInitialized) await _initialize();
    
    // 輸入驗證
    try {
      BookingDataValidator.validateCreateBooking(bookingData);
    } catch (e) {
      _handleError(e.toString());
      rethrow;
    }
    
    try {
      _setLoading(true);
      clearError();
      
      final bookingId = await _bookingService.createBooking(bookingData);
      
      // 清除緩存，以便下次獲取最新數據
      clearCache('userBookings');
      
      _setLoading(false);
      return bookingId;
    } catch (e) {
      _handleError('創建預約失敗', e);
      rethrow;
    }
  }
  
  @override
  Future<bool> updateBooking(String bookingId, Map<String, dynamic> bookingData) async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      final success = await _bookingService.updateBooking(bookingId, bookingData);
      
      // 更新緩存
      if (success) {
        _cacheManager.removeBookingDetails(bookingId);
        clearCache('userBookings');
        clearCache('coachBookings');
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _handleError('更新預約失敗', e);
      return false;
    }
  }
  
  @override
  Future<bool> cancelBooking(String bookingId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      final success = await _bookingService.cancelBooking(bookingId);
      
      // 更新緩存
      if (success) {
        _cacheManager.removeBookingDetails(bookingId);
        clearCache('userBookings');
        clearCache('coachBookings');
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _handleError('取消預約失敗', e);
      return false;
    }
  }
  
  @override
  Future<bool> confirmBooking(String bookingId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      final success = await _bookingService.confirmBooking(bookingId);
      
      // 更新緩存
      if (success) {
        _cacheManager.removeBookingDetails(bookingId);
        clearCache('userBookings');
        clearCache('coachBookings');
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _handleError('確認預約失敗', e);
      return false;
    }
  }
  
  @override
  Future<bool> deleteBooking(String bookingId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      final success = await _bookingService.deleteBooking(bookingId);
      
      // 更新緩存
      if (success) {
        _cacheManager.removeBookingDetails(bookingId);
        clearCache('userBookings');
        clearCache('coachBookings');
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _handleError('刪除預約失敗', e);
      return false;
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> loadAvailableSlots(String coachId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      // 每次都重新載入可用時段，因為這些數據可能會頻繁變化
      _setLoading(true);
      clearError();
      
      final slots = await _bookingService.getAvailableSlots(coachId);
      
      // 過濾掉已過期的時段
      final availableSlots = BookingSlotFilter.filterExpiredSlots(slots);
      
      _cacheManager.availableSlotsCache = availableSlots;
      _cacheManager.updateRefreshTime('availableSlots');
      
      _setLoading(false);
      return availableSlots;
    } catch (e) {
      _handleError('載入可用時段失敗', e);
      return _cacheManager.availableSlotsCache ?? [];
    }
  }
  
  @override
  Future<bool> setSlotBooked(String slotId) async {
    if (!_isInitialized) await _initialize();
    
    try {
      _setLoading(true);
      clearError();
      
      final success = await _bookingService.setSlotBooked(slotId);
      
      // 清除緩存
      if (success) {
        clearCache('availableSlots');
      }
      
      _setLoading(false);
      return success;
    } catch (e) {
      _handleError('設置時段已預約失敗', e);
      return false;
    }
  }
  
  /// 輸出調試信息
  void _logDebug(String message) {
    print('[BOOKING] $message');
  }
} 