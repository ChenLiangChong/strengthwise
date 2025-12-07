import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'error_handling_service.dart';
import 'interfaces/i_booking_service.dart';
import 'service_locator.dart' show Environment;

/// 預約服務的Firebase實現
/// 
/// 提供預約的創建、讀取、更新、取消等功能
/// 支持環境配置、緩存機制和統一錯誤處理
class BookingService implements IBookingService {
  // 依賴注入
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ErrorHandlingService _errorService;
  
  // 服務狀態
  bool _isInitialized = false;
  Environment _environment = Environment.development;
  
  // 服務配置
  bool _useCache = true;
  int _queryTimeout = 10; // 秒
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
  /// 允許注入自定義的Firestore和Auth實例，便於測試
  BookingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ErrorHandlingService? errorService,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance,
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
      
      // 設置預約更新監聽器，增加錯誤處理
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
        _queryTimeout = 15; // 較長的超時時間，便於調試
        _cacheDuration = 10; // 較長的緩存時間，便於開發
        _notificationsEnabled = true;
        _logDebug('預約服務配置為開發環境');
        break;
      case Environment.testing:
        // 測試環境設置
        _useCache = false; // 測試需要實時數據，不使用緩存
        _queryTimeout = 8;
        _cacheDuration = 2;
        _notificationsEnabled = false;
        _logDebug('預約服務配置為測試環境');
        break;
      case Environment.production:
        // 生產環境設置
        _useCache = true;
        _queryTimeout = 10;
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
  
  /// 設置預約更新監聽器
  Future<void> _setupBookingListeners() async {
    // 直接從 _auth 獲取用戶 ID，而不是使用 currentUserId getter
    // 這樣可以避免調用 _ensureInitialized() 而導致的循環依賴
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    // 監聽用戶的預約更新
    try {
      final userBookingsSubscription = _bookingsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            final booking = change.doc.data() as Map<String, dynamic>;
            booking['id'] = change.doc.id;
            
            if (change.type == DocumentChangeType.added) {
              booking['changeType'] = 'added';
              _bookingUpdateController.add(booking);
              _clearUserBookingsCacheFor(userId);
            } else if (change.type == DocumentChangeType.modified) {
              booking['changeType'] = 'modified';
              _bookingUpdateController.add(booking);
              _clearUserBookingsCacheFor(userId);
              // 清除該預約的詳情緩存
              _bookingDetailsCache.remove(change.doc.id);
            } else if (change.type == DocumentChangeType.removed) {
              booking['changeType'] = 'removed';
              _bookingUpdateController.add(booking);
              _clearUserBookingsCacheFor(userId);
              // 清除該預約的詳情緩存
              _bookingDetailsCache.remove(change.doc.id);
            }
          }
        });
      
      _activeSubscriptions.add(userBookingsSubscription);
      _logDebug('用戶預約監聽器設置成功');
      
      // 如果用戶也是教練，監聽教練的預約更新
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData != null && userData['isCoach'] == true) {
        final coachBookingsSubscription = _bookingsRef
          .where('coachId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
            for (var change in snapshot.docChanges) {
              final booking = change.doc.data() as Map<String, dynamic>;
              booking['id'] = change.doc.id;
              
              if (change.type == DocumentChangeType.added) {
                booking['changeType'] = 'added';
                booking['asCoach'] = true;
                _bookingUpdateController.add(booking);
                _clearCoachBookingsCacheFor(userId);
              } else if (change.type == DocumentChangeType.modified) {
                booking['changeType'] = 'modified';
                booking['asCoach'] = true;
                _bookingUpdateController.add(booking);
                _clearCoachBookingsCacheFor(userId);
                // 清除該預約的詳情緩存
                _bookingDetailsCache.remove(change.doc.id);
              } else if (change.type == DocumentChangeType.removed) {
                booking['changeType'] = 'removed';
                booking['asCoach'] = true;
                _bookingUpdateController.add(booking);
                _clearCoachBookingsCacheFor(userId);
                // 清除該預約的詳情緩存
                _bookingDetailsCache.remove(change.doc.id);
              }
            }
          });
        
        _activeSubscriptions.add(coachBookingsSubscription);
        _logDebug('教練預約監聽器設置成功');
      }
    } catch (e) {
      _logError('設置預約監聽器失敗: $e');
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
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      _clearUserBookingsCacheFor(userId);
    }
  }
  
  /// 清除教練預約緩存
  void _clearCoachBookingsCache() {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      _clearCoachBookingsCacheFor(userId);
    }
  }
  
  /// 獲取預約更新流
  Stream<Map<String, dynamic>> get bookingUpdates => _bookingUpdateController.stream;
  
  // 獲取當前用戶ID
  String? get currentUserId {
    _ensureInitialized();
    return _auth.currentUser?.uid;
  }
  
  // 獲取預約集合引用
  CollectionReference get _bookingsRef => _firestore.collection('bookings');
  
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
      _logDebug('從Firestore獲取用戶預約');
      final querySnapshot = await _bookingsRef
          .where('userId', isEqualTo: currentUserId)
          .orderBy('dateTime', descending: false)
          .get()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取用戶預約超時'),
          );
      
      final bookings = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .toList();
          
      // 更新緩存
      if (_useCache) {
        _bookingsCache[cacheKey] = bookings;
        _bookingsCacheTime[cacheKey] = DateTime.now();
      }
      
      _logDebug('成功獲取 ${bookings.length} 個用戶預約');
      return bookings;
    } catch (e) {
      _logError('獲取用戶預約失敗: $e');
      
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
      _logDebug('從Firestore獲取教練預約');
      final querySnapshot = await _bookingsRef
          .where('coachId', isEqualTo: currentUserId)
          .orderBy('dateTime', descending: false)
          .get()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取教練預約超時'),
          );
      
      final bookings = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .toList();
          
      // 更新緩存
      if (_useCache) {
        _bookingsCache[cacheKey] = bookings;
        _bookingsCacheTime[cacheKey] = DateTime.now();
      }
      
      _logDebug('成功獲取 ${bookings.length} 個教練預約');
      return bookings;
    } catch (e) {
      _logError('獲取教練預約失敗: $e');
      
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
      _logDebug('從Firestore獲取預約詳情: $bookingId');
      final docSnapshot = await _bookingsRef.doc(bookingId).get()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取預約詳情超時'),
          );
          
      if (!docSnapshot.exists) {
        _logDebug('預約不存在: $bookingId');
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      data['id'] = docSnapshot.id;
      
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
      
      // 設置預約狀態和建立時間
      bookingData['status'] = 'pending';
      bookingData['userId'] = currentUserId;
      bookingData['createdAt'] = FieldValue.serverTimestamp();
      bookingData['updatedAt'] = FieldValue.serverTimestamp();
      
      final docRef = await _bookingsRef.add(bookingData)
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('創建預約超時'),
          );
      
      // 清除相關緩存
      _clearUserBookingsCache();
      
      // 如果預約了時段，標記為已預約
      if (bookingData.containsKey('slotId')) {
        await setSlotBooked(bookingData['slotId']);
      }
      
      // 發送通知（如果啟用）
      if (_notificationsEnabled && bookingData.containsKey('coachId')) {
        _sendBookingNotification(
          'new_booking', 
          bookingData['coachId'], 
          docRef.id,
          '您收到一個新的預約請求'
        );
      }
      
      _logDebug('預約創建成功: ${docRef.id}');
      return docRef.id;
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
      final bookingDoc = await _bookingsRef.doc(bookingId).get();
      if (!bookingDoc.exists) {
        _logError('預約不存在: $bookingId');
        return false;
      }
      
      final bookingDetails = bookingDoc.data() as Map<String, dynamic>;
      if (currentUserId != null && 
          currentUserId != bookingDetails['userId'] && 
          currentUserId != bookingDetails['coachId']) {
        _logError('無權更新此預約: $bookingId');
        return false;
      }
      
      // 更新時間
      bookingData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _bookingsRef.doc(bookingId).update(bookingData)
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('更新預約超時'),
          );
      
      // 清除緩存
      _clearUserBookingsCache();
      if (bookingDetails.containsKey('coachId')) {
        final coachId = bookingDetails['coachId'];
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
            recipientId = bookingDetails['userId'];
          } else if (bookingData['status'] == 'cancelled') {
            notificationType = 'booking_cancelled';
            message = '您的預約已被取消';
            recipientId = bookingDetails['userId'] == currentUserId 
                ? bookingDetails['coachId'] 
                : bookingDetails['userId'];
          } else if (bookingData['status'] == 'completed') {
            notificationType = 'booking_completed';
            message = '您的預約已完成';
            recipientId = bookingDetails['userId'];
          } else if (bookingData['status'] == 'rejected') {
            notificationType = 'booking_rejected';
            message = '您的預約請求已被拒絕';
            recipientId = bookingDetails['userId'];
          } else {
            notificationType = 'booking_updated';
            message = '您的預約已更新';
            recipientId = bookingDetails['userId'] == currentUserId 
                ? bookingDetails['coachId'] 
                : bookingDetails['userId'];
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
      final bookingDoc = await _bookingsRef.doc(bookingId).get();
      if (!bookingDoc.exists) {
        _logError('預約不存在: $bookingId');
        return false;
      }
      
      final bookingDetails = bookingDoc.data() as Map<String, dynamic>;
      if (currentUserId != null && 
          currentUserId != bookingDetails['userId'] && 
          currentUserId != bookingDetails['coachId']) {
        _logError('無權取消此預約: $bookingId');
        return false;
      }
      
      // 記錄取消人
      final cancelledBy = currentUserId == bookingDetails['userId'] ? 'user' : 'coach';
      
      await _bookingsRef.doc(bookingId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
        'cancelledBy': cancelledBy,
        'cancelledAt': FieldValue.serverTimestamp(),
      }).timeout(
        Duration(seconds: _queryTimeout),
        onTimeout: () => throw TimeoutException('取消預約超時'),
      );
      
      // 清除緩存
      _clearUserBookingsCache();
      if (bookingDetails.containsKey('coachId')) {
        final coachId = bookingDetails['coachId'];
        if (coachId == currentUserId) {
          _clearCoachBookingsCache();
        }
      }
      _bookingDetailsCache.remove(bookingId);
      
      // 釋放預約的時段（如果有）
      if (bookingDetails.containsKey('slotId')) {
        await _firestore
          .collection('availableSlots')
          .doc(bookingDetails['slotId'])
          .update({'isBooked': false});
      }
      
      // 發送通知（如果啟用）
      if (_notificationsEnabled) {
        final recipientId = currentUserId == bookingDetails['userId']
          ? bookingDetails['coachId']
          : bookingDetails['userId'];
        
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
      final bookingDoc = await _bookingsRef.doc(bookingId).get();
      if (!bookingDoc.exists) {
        _logError('預約不存在: $bookingId');
        return false;
      }
      
      final bookingDetails = bookingDoc.data() as Map<String, dynamic>;
      if (currentUserId != bookingDetails['coachId']) {
        _logError('只有教練可以確認預約: $bookingId');
        return false;
      }
      
      await _bookingsRef.doc(bookingId).update({
        'status': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
        'confirmedAt': FieldValue.serverTimestamp(),
      }).timeout(
        Duration(seconds: _queryTimeout),
        onTimeout: () => throw TimeoutException('確認預約超時'),
      );
      
      // 清除緩存
      _clearCoachBookingsCache();
      _bookingDetailsCache.remove(bookingId);
      
      // 發送通知（如果啟用）
      if (_notificationsEnabled) {
        _sendBookingNotification(
          'booking_confirmed', 
          bookingDetails['userId'], 
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
      final bookingDoc = await _bookingsRef.doc(bookingId).get();
      if (!bookingDoc.exists) {
        _logError('預約不存在: $bookingId');
        return false;
      }
      
      final bookingDetails = bookingDoc.data() as Map<String, dynamic>;
      if (currentUserId != null && 
          currentUserId != bookingDetails['userId'] && 
          currentUserId != bookingDetails['coachId']) {
        _logError('無權刪除此預約: $bookingId');
        return false;
      }
      
      // 備份預約數據到歷史記錄集合
      await _firestore.collection('bookingHistory').add({
        ...bookingDetails,
        'originalId': bookingId,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': currentUserId,
      });
      
      await _bookingsRef.doc(bookingId).delete()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('刪除預約超時'),
          );
      
      // 清除緩存
      _clearUserBookingsCache();
      if (bookingDetails.containsKey('coachId')) {
        final coachId = bookingDetails['coachId'];
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
      _logDebug('從Firestore獲取可用時段');
      
      // 只獲取當前時間之後的可用時段
      final now = Timestamp.now();
      
      final querySnapshot = await _firestore
          .collection('availableSlots')
          .where('coachId', isEqualTo: coachId)
          .where('isBooked', isEqualTo: false)
          .where('dateTime', isGreaterThanOrEqualTo: now)
          .orderBy('dateTime', descending: false)
          .get()
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('獲取可用時段超時'),
          );
      
      final slots = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
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
      await _firestore
          .collection('availableSlots')
          .doc(slotId)
          .update({'isBooked': true})
          .timeout(
            Duration(seconds: _queryTimeout),
            onTimeout: () => throw TimeoutException('設置時段已預約超時'),
          );
      
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
      await _firestore.collection('notifications').add({
        'userId': recipientId,
        'type': type,
        'message': message,
        'bookingId': bookingId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
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
      final now = Timestamp.now();
      
      // 獲取用戶即將到來的預約
      final userQuery = await _bookingsRef
        .where('userId', isEqualTo: currentUserId)
        .where('dateTime', isGreaterThanOrEqualTo: now)
        .where('status', isEqualTo: 'confirmed')
        .orderBy('dateTime', descending: false)
        .limit(5)
        .get();
        
      final userBookings = userQuery.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          data['role'] = 'user';
          return data;
        })
        .toList();
      
      // 獲取教練即將到來的預約
      final coachQuery = await _bookingsRef
        .where('coachId', isEqualTo: currentUserId)
        .where('dateTime', isGreaterThanOrEqualTo: now)
        .where('status', isEqualTo: 'confirmed')
        .orderBy('dateTime', descending: false)
        .limit(5)
        .get();
        
      final coachBookings = coachQuery.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          data['role'] = 'coach';
          return data;
        })
        .toList();
        
      // 合併並按時間排序
      final allBookings = [...userBookings, ...coachBookings];
      allBookings.sort((a, b) {
        final aTime = a['dateTime'] as Timestamp;
        final bTime = b['dateTime'] as Timestamp;
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