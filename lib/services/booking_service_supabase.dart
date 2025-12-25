import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'error_handling_service.dart';
import 'interfaces/i_booking_service.dart';
import 'service_locator.dart' show Environment;
import '../utils/firestore_id_generator.dart';

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
  
  // 緩存
  final Map<String, List<Map<String, dynamic>>> _bookingsCache = {};
  final Map<String, DateTime> _bookingsCacheTime = {};
  final Map<String, Map<String, dynamic>> _bookingDetailsCache = {};
  final Map<String, List<Map<String, dynamic>>> _availableSlotsCache = {};
  final Map<String, DateTime> _availableSlotsCacheTime = {};
  Timer? _cacheClearTimer;
  
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
    _errorService = errorService ?? ErrorHandlingService();
  
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
      
      // 設置緩存清理計時器（每小時）
      if (_useCache) {
        _setupCacheCleanupTimer();
      }
      
      // 設置預約更新監聽器
      try {
        await _setupBookingListeners();
      } catch (e) {
        _logError('設置預約監聽器失敗: $e');
        // 繼續執行，不要因為監聽器設置失敗就中斷整個初始化過程
      }
      
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
      // 取消緩存清理計時器
      _cacheClearTimer?.cancel();
      _cacheClearTimer = null;
      
      // 取消所有活動的訂閱
      for (var subscription in _activeSubscriptions) {
        await subscription.cancel();
      }
      _activeSubscriptions.clear();
      
      // 關閉事件控制器
      await _bookingUpdateController.close();
      
      // 清空緩存
      _bookingsCache.clear();
      _bookingsCacheTime.clear();
      _bookingDetailsCache.clear();
      _availableSlotsCache.clear();
      _availableSlotsCacheTime.clear();
      
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
  
  /// 設置緩存清理計時器
  void _setupCacheCleanupTimer() {
    _cacheClearTimer?.cancel();
    // 每小時清理一次緩存
    _cacheClearTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _clearCache();
    });
  }
  
  /// 清除緩存
  void _clearCache() {
    _logDebug('清理預約緩存');
    _bookingsCache.clear();
    _bookingsCacheTime.clear();
    _bookingDetailsCache.clear();
    _availableSlotsCache.clear();
    _availableSlotsCacheTime.clear();
  }
  
  /// 設置預約更新監聽器（Supabase Realtime）
  Future<void> _setupBookingListeners() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      // 監聽用戶的預約更新（使用 Supabase Realtime）
      _supabase
          .channel('user_bookings_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              _handleBookingChange(payload, isCoach: false);
            },
          )
          .subscribe();
      
      _logDebug('用戶預約監聽器設置成功');
      
      // 檢查用戶是否為教練
      final userResponse = await _supabase
          .from('users')
          .select('is_coach')
          .eq('id', userId)
          .maybeSingle();
      
      if (userResponse != null && userResponse['is_coach'] == true) {
        // 監聽教練的預約更新
        _supabase
            .channel('coach_bookings_$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'bookings',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'coach_id',
                value: userId,
              ),
              callback: (payload) {
                _handleBookingChange(payload, isCoach: true);
              },
            )
            .subscribe();
        
        _logDebug('教練預約監聽器設置成功');
      }
    } catch (e) {
      _logDebug('Bookings 設置監聽器失敗（可能是權限問題）: $e');
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
          _clearCoachBookingsCacheFor(userId);
        } else {
          _clearUserBookingsCacheFor(userId);
        }
        
        // 清除預約詳情緩存
        final bookingId = booking['id'] as String?;
        if (bookingId != null) {
          _bookingDetailsCache.remove(bookingId);
        }
      }
    } catch (e) {
      _logError('處理預約變更事件失敗: $e');
    }
  }
  
  /// 清除特定用戶的預約緩存
  void _clearUserBookingsCacheFor(String userId) {
    final cacheKey = 'user_$userId';
    _bookingsCache.remove(cacheKey);
    _bookingsCacheTime.remove(cacheKey);
  }
  
  /// 清除特定教練的預約緩存
  void _clearCoachBookingsCacheFor(String userId) {
    final cacheKey = 'coach_$userId';
    _bookingsCache.remove(cacheKey);
    _bookingsCacheTime.remove(cacheKey);
  }
  
  /// 清除用戶預約緩存
  void _clearUserBookingsCache() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _clearUserBookingsCacheFor(userId);
    }
  }
  
  /// 清除教練預約緩存
  void _clearCoachBookingsCache() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      _clearCoachBookingsCacheFor(userId);
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
    if (_useCache && 
        _bookingsCache.containsKey(cacheKey) && 
        _bookingsCacheTime.containsKey(cacheKey)) {
      final cacheAge = DateTime.now().difference(_bookingsCacheTime[cacheKey]!);
      
      // 緩存有效，直接返回
      if (cacheAge.inMinutes < _cacheDuration) {
        _logDebug('從緩存獲取用戶預約 (${_bookingsCache[cacheKey]!.length} 個)');
        return List.unmodifiable(_bookingsCache[cacheKey]!);
      }
    }
    
    try {
      _logDebug('從 Supabase 獲取用戶預約');
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('user_id', currentUserId!)
          .order('date_time', ascending: true);
      
      final bookings = (response as List<dynamic>)
          .map((data) => data as Map<String, dynamic>)
          .toList();
          
      // 更新緩存
      if (_useCache) {
        _bookingsCache[cacheKey] = bookings;
        _bookingsCacheTime[cacheKey] = DateTime.now();
      }
      
      _logDebug('成功獲取 ${bookings.length} 個用戶預約');
      return bookings;
    } catch (e) {
      _logDebug('Bookings 集合無權限訪問（單機版模式），返回空列表');
      
      // 如果緩存可用但可能已過期，在發生錯誤時仍返回緩存數據
      if (_useCache && _bookingsCache.containsKey(cacheKey)) {
        _logDebug('服務器獲取失敗，返回可能過期的緩存數據');
        return List.unmodifiable(_bookingsCache[cacheKey]!);
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
    if (_useCache && 
        _bookingsCache.containsKey(cacheKey) && 
        _bookingsCacheTime.containsKey(cacheKey)) {
      final cacheAge = DateTime.now().difference(_bookingsCacheTime[cacheKey]!);
      
      // 緩存有效，直接返回
      if (cacheAge.inMinutes < _cacheDuration) {
        _logDebug('從緩存獲取教練預約 (${_bookingsCache[cacheKey]!.length} 個)');
        return List.unmodifiable(_bookingsCache[cacheKey]!);
      }
    }
    
    try {
      _logDebug('從 Supabase 獲取教練預約');
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('coach_id', currentUserId!)
          .order('date_time', ascending: true);
      
      final bookings = (response as List<dynamic>)
          .map((data) => data as Map<String, dynamic>)
          .toList();
          
      // 更新緩存
      if (_useCache) {
        _bookingsCache[cacheKey] = bookings;
        _bookingsCacheTime[cacheKey] = DateTime.now();
      }
      
      _logDebug('成功獲取 ${bookings.length} 個教練預約');
      return bookings;
    } catch (e) {
      _logDebug('Bookings 集合無權限訪問（單機版模式），返回空列表');
      
      // 如果緩存可用但可能已過期，在發生錯誤時仍返回緩存數據
      if (_useCache && _bookingsCache.containsKey(cacheKey)) {
        _logDebug('服務器獲取失敗，返回可能過期的緩存數據');
        return List.unmodifiable(_bookingsCache[cacheKey]!);
      }
      
      return [];
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    _ensureInitialized();
    
    // 檢查緩存
    if (_useCache && _bookingDetailsCache.containsKey(bookingId)) {
      _logDebug('從緩存獲取預約詳情: $bookingId');
      return Map.from(_bookingDetailsCache[bookingId]!);
    }
    
    try {
      _logDebug('從 Supabase 獲取預約詳情: $bookingId');
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .maybeSingle();
          
      if (response == null) {
        _logDebug('預約不存在: $bookingId');
        return null;
      }
      
      final data = response;
      
      // 更新緩存
      if (_useCache) {
        _bookingDetailsCache[bookingId] = data;
      }
      
      _logDebug('成功獲取預約詳情');
      return data;
    } catch (e) {
      _logError('獲取預約詳情失敗: $e');
      return null;
    }
  }
  
  @override
  Future<String> createBooking(Map<String, dynamic> bookingData) async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      _logError('創建預約失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }
    
    try {
      _logDebug('創建新預約');
      final bookingId = generateFirestoreId();
      final now = DateTime.now();
      
      // 設置預約狀態和建立時間
      bookingData['id'] = bookingId;
      bookingData['status'] = 'pending';
      bookingData['user_id'] = currentUserId;
      bookingData['created_at'] = now.toIso8601String();
      bookingData['updated_at'] = now.toIso8601String();
      
      await _supabase.from('bookings').insert(bookingData);
      
      // 清除相關緩存
      _clearUserBookingsCache();
      
      // 如果預約了時段，標記為已預約
      if (bookingData.containsKey('slot_id')) {
        await setSlotBooked(bookingData['slot_id']);
      }
      
      // 發送通知（如果啟用）
      if (_notificationsEnabled && bookingData.containsKey('coach_id')) {
        _sendBookingNotification(
          'new_booking', 
          bookingData['coach_id'], 
          bookingId,
          '您收到一個新的預約請求'
        );
      }
      
      _logDebug('預約創建成功: $bookingId');
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
      _logDebug('更新預約: $bookingId');
      
      // 檢查權限
      final bookingResponse = await _supabase
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .maybeSingle();
          
      if (bookingResponse == null) {
        _logError('預約不存在: $bookingId');
        return false;
      }
      
      final bookingDetails = bookingResponse;
      if (currentUserId != null && 
          currentUserId != bookingDetails['user_id'] && 
          currentUserId != bookingDetails['coach_id']) {
        _logError('無權更新此預約: $bookingId');
        return false;
      }
      
      // 更新時間
      bookingData['updated_at'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from('bookings')
          .update(bookingData)
          .eq('id', bookingId);
      
      // 清除緩存
      _clearUserBookingsCache();
      if (bookingDetails.containsKey('coach_id')) {
        final coachId = bookingDetails['coach_id'];
        if (coachId == currentUserId) {
          _clearCoachBookingsCache();
        }
      }
      _bookingDetailsCache.remove(bookingId);
      
      // 發送通知（如果啟用）
      if (_notificationsEnabled) {
        // 根據更新類型發送不同通知
        if (bookingData.containsKey('status')) {
          String notificationType;
          String message;
          String recipientId;
          
          if (bookingData['status'] == 'confirmed') {
            notificationType = 'booking_confirmed';
            message = '您的預約已被確認';
            recipientId = bookingDetails['user_id'];
          } else if (bookingData['status'] == 'cancelled') {
            notificationType = 'booking_cancelled';
            message = '您的預約已被取消';
            recipientId = bookingDetails['user_id'] == currentUserId 
                ? bookingDetails['coach_id'] 
                : bookingDetails['user_id'];
          } else if (bookingData['status'] == 'completed') {
            notificationType = 'booking_completed';
            message = '您的預約已完成';
            recipientId = bookingDetails['user_id'];
          } else if (bookingData['status'] == 'rejected') {
            notificationType = 'booking_rejected';
            message = '您的預約請求已被拒絕';
            recipientId = bookingDetails['user_id'];
          } else {
            notificationType = 'booking_updated';
            message = '您的預約已更新';
            recipientId = bookingDetails['user_id'] == currentUserId 
                ? bookingDetails['coach_id'] 
                : bookingDetails['user_id'];
          }
          
          _sendBookingNotification(notificationType, recipientId, bookingId, message);
        }
      }
      
      _logDebug('預約更新成功');
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
      _logDebug('取消預約: $bookingId');
      
      // 檢查預約詳情
      final bookingResponse = await _supabase
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .maybeSingle();
          
      if (bookingResponse == null) {
        _logError('預約不存在: $bookingId');
        return false;
      }
      
      final bookingDetails = bookingResponse;
      if (currentUserId != null && 
          currentUserId != bookingDetails['user_id'] && 
          currentUserId != bookingDetails['coach_id']) {
        _logError('無權取消此預約: $bookingId');
        return false;
      }
      
      // 記錄取消人
      final cancelledBy = currentUserId == bookingDetails['user_id'] ? 'user' : 'coach';
      final now = DateTime.now();
      
      await _supabase
          .from('bookings')
          .update({
            'status': 'cancelled',
            'updated_at': now.toIso8601String(),
            'cancelled_by': cancelledBy,
            'cancelled_at': now.toIso8601String(),
          })
          .eq('id', bookingId);
      
      // 清除緩存
      _clearUserBookingsCache();
      if (bookingDetails.containsKey('coach_id')) {
        final coachId = bookingDetails['coach_id'];
        if (coachId == currentUserId) {
          _clearCoachBookingsCache();
        }
      }
      _bookingDetailsCache.remove(bookingId);
      
      // 釋放預約的時段（如果有）
      if (bookingDetails.containsKey('slot_id')) {
        await _supabase
            .from('available_slots')
            .update({'is_booked': false})
            .eq('id', bookingDetails['slot_id']);
      }
      
      // 發送通知（如果啟用）
      if (_notificationsEnabled) {
        final recipientId = currentUserId == bookingDetails['user_id']
            ? bookingDetails['coach_id']
            : bookingDetails['user_id'];
        
        _sendBookingNotification(
          'booking_cancelled', 
          recipientId, 
          bookingId,
          '預約已被${cancelledBy == 'user' ? '用戶' : '教練'}取消'
        );
      }
      
      _logDebug('預約取消成功');
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
      _logDebug('確認預約: $bookingId');
      
      // 檢查預約詳情，確保只有教練能確認預約
      final bookingResponse = await _supabase
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .maybeSingle();
          
      if (bookingResponse == null) {
        _logError('預約不存在: $bookingId');
        return false;
      }
      
      final bookingDetails = bookingResponse;
      if (currentUserId != bookingDetails['coach_id']) {
        _logError('只有教練可以確認預約: $bookingId');
        return false;
      }
      
      final now = DateTime.now();
      
      await _supabase
          .from('bookings')
          .update({
            'status': 'confirmed',
            'updated_at': now.toIso8601String(),
            'confirmed_at': now.toIso8601String(),
          })
          .eq('id', bookingId);
      
      // 清除緩存
      _clearCoachBookingsCache();
      _bookingDetailsCache.remove(bookingId);
      
      // 發送通知（如果啟用）
      if (_notificationsEnabled) {
        _sendBookingNotification(
          'booking_confirmed', 
          bookingDetails['user_id'], 
          bookingId,
          '您的預約已被確認'
        );
      }
      
      _logDebug('預約確認成功');
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
      _logDebug('刪除預約: $bookingId');
      
      // 檢查預約詳情
      final bookingResponse = await _supabase
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .maybeSingle();
          
      if (bookingResponse == null) {
        _logError('預約不存在: $bookingId');
        return false;
      }
      
      final bookingDetails = bookingResponse;
      if (currentUserId != null && 
          currentUserId != bookingDetails['user_id'] && 
          currentUserId != bookingDetails['coach_id']) {
        _logError('無權刪除此預約: $bookingId');
        return false;
      }
      
      // 備份預約數據到歷史記錄集合
      await _supabase.from('booking_history').insert({
        'original_id': bookingId,
        'booking_data': bookingDetails,
        'deleted_by': currentUserId,
        'deleted_at': DateTime.now().toIso8601String(),
      });
      
      await _supabase
          .from('bookings')
          .delete()
          .eq('id', bookingId);
      
      // 清除緩存
      _clearUserBookingsCache();
      if (bookingDetails.containsKey('coach_id')) {
        final coachId = bookingDetails['coach_id'];
        if (coachId == currentUserId) {
          _clearCoachBookingsCache();
        }
      }
      _bookingDetailsCache.remove(bookingId);
      
      _logDebug('預約刪除成功');
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
    if (_useCache && 
        _availableSlotsCache.containsKey(cacheKey) && 
        _availableSlotsCacheTime.containsKey(cacheKey)) {
      final cacheAge = DateTime.now().difference(_availableSlotsCacheTime[cacheKey]!);
      
      // 緩存有效，直接返回
      if (cacheAge.inMinutes < _cacheDuration) {
        _logDebug('從緩存獲取可用時段 (${_availableSlotsCache[cacheKey]!.length} 個)');
        return List.unmodifiable(_availableSlotsCache[cacheKey]!);
      }
    }
    
    try {
      _logDebug('從 Supabase 獲取可用時段');
      
      // 只獲取當前時間之後的可用時段
      final now = DateTime.now();
      
      final response = await _supabase
          .from('available_slots')
          .select()
          .eq('coach_id', coachId)
          .eq('is_booked', false)
          .gte('date_time', now.toIso8601String())
          .order('date_time', ascending: true);
      
      final slots = (response as List<dynamic>)
          .map((data) => data as Map<String, dynamic>)
          .toList();
      
      // 更新緩存
      if (_useCache) {
        _availableSlotsCache[cacheKey] = slots;
        _availableSlotsCacheTime[cacheKey] = DateTime.now();
      }
      
      _logDebug('成功獲取 ${slots.length} 個可用時段');
      return slots;
    } catch (e) {
      _logError('獲取可用時段失敗: $e');
      
      // 如果緩存可用但可能已過期，在發生錯誤時仍返回緩存數據
      if (_useCache && _availableSlotsCache.containsKey(cacheKey)) {
        _logDebug('服務器獲取失敗，返回可能過期的緩存數據');
        return List.unmodifiable(_availableSlotsCache[cacheKey]!);
      }
      
      return [];
    }
  }
  
  @override
  Future<bool> setSlotBooked(String slotId) async {
    _ensureInitialized();
    
    try {
      _logDebug('設置時段已預約: $slotId');
      await _supabase
          .from('available_slots')
          .update({'is_booked': true})
          .eq('id', slotId);
      
      // 清除相關緩存
      _availableSlotsCache.clear();
      _availableSlotsCacheTime.clear();
      
      _logDebug('時段設置已預約成功');
      return true;
    } catch (e) {
      _logError('設置時段已預約失敗: $e');
      return false;
    }
  }
  
  /// 發送預約相關通知
  Future<void> _sendBookingNotification(
    String type, 
    String recipientId, 
    String bookingId,
    String message
  ) async {
    if (!_notificationsEnabled) return;
    
    try {
      await _supabase.from('notifications').insert({
        'id': generateFirestoreId(),
        'user_id': recipientId,
        'type': type,
        'message': message,
        'booking_id': bookingId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      _logDebug('發送通知成功: $type 至 $recipientId');
    } catch (e) {
      _logError('發送通知失敗: $e');
    }
  }
  
  /// 檢查用戶是否有即將到來的預約
  Future<List<Map<String, dynamic>>> getUpcomingBookings() async {
    _ensureInitialized();
    
    if (currentUserId == null) {
      return [];
    }
    
    try {
      final now = DateTime.now();
      
      // 獲取用戶即將到來的預約
      final userResponse = await _supabase
          .from('bookings')
          .select()
          .eq('user_id', currentUserId!)
          .gte('date_time', now.toIso8601String())
          .eq('status', 'confirmed')
          .order('date_time', ascending: true)
          .limit(5);
        
      final userBookings = (userResponse as List<dynamic>)
          .map((data) {
            final booking = data as Map<String, dynamic>;
            booking['role'] = 'user';
            return booking;
          })
          .toList();
      
      // 獲取教練即將到來的預約
      final coachResponse = await _supabase
          .from('bookings')
          .select()
          .eq('coach_id', currentUserId!)
          .gte('date_time', now.toIso8601String())
          .eq('status', 'confirmed')
          .order('date_time', ascending: true)
          .limit(5);
        
      final coachBookings = (coachResponse as List<dynamic>)
          .map((data) {
            final booking = data as Map<String, dynamic>;
            booking['role'] = 'coach';
            return booking;
          })
          .toList();
        
      // 合併並按時間排序
      final allBookings = [...userBookings, ...coachBookings];
      allBookings.sort((a, b) {
        final aTime = DateTime.parse(a['date_time'] as String);
        final bTime = DateTime.parse(b['date_time'] as String);
        return aTime.compareTo(bTime);
      });
      
      return allBookings.take(5).toList();
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

