import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../utils/firestore_id_generator.dart';

/// 預約資料庫操作
///
/// 負責所有 Supabase 資料庫的 CRUD 操作
class BookingOperations {
  final SupabaseClient _supabase;
  final String? Function() _getCurrentUserId;
  final void Function(String) _logDebug;
  final void Function(String) _logError;

  BookingOperations({
    required SupabaseClient supabase,
    required String? Function() getCurrentUserId,
    required void Function(String) logDebug,
    required void Function(String) logError,
  })  : _supabase = supabase,
        _getCurrentUserId = getCurrentUserId,
        _logDebug = logDebug,
        _logError = logError;

  /// 獲取用戶預約
  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    _logDebug('從 Supabase 獲取用戶預約');
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('date_time', ascending: true);

    final bookings = (response as List<dynamic>)
        .map((data) => data as Map<String, dynamic>)
        .toList();

    _logDebug('成功獲取 ${bookings.length} 個用戶預約');
    return bookings;
  }

  /// 獲取教練預約
  Future<List<Map<String, dynamic>>> getCoachBookings(String userId) async {
    _logDebug('從 Supabase 獲取教練預約');
    final response = await _supabase
        .from('bookings')
        .select()
        .eq('coach_id', userId)
        .order('date_time', ascending: true);

    final bookings = (response as List<dynamic>)
        .map((data) => data as Map<String, dynamic>)
        .toList();

    _logDebug('成功獲取 ${bookings.length} 個教練預約');
    return bookings;
  }

  /// 獲取預約詳情
  Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
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

    _logDebug('成功獲取預約詳情');
    return response;
  }

  /// 創建預約
  Future<String> createBooking(Map<String, dynamic> bookingData) async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) {
      _logError('創建預約失敗：沒有登入用戶');
      throw Exception('用戶未登入');
    }

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

    _logDebug('預約創建成功: $bookingId');
    return bookingId;
  }

  /// 更新預約
  Future<bool> updateBooking(
    String bookingId,
    Map<String, dynamic> bookingData,
  ) async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) return false;

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
    if (currentUserId != bookingDetails['user_id'] &&
        currentUserId != bookingDetails['coach_id']) {
      _logError('無權更新此預約: $bookingId');
      return false;
    }

    // 更新時間
    bookingData['updated_at'] = DateTime.now().toIso8601String();

    await _supabase.from('bookings').update(bookingData).eq('id', bookingId);

    _logDebug('預約更新成功');
    return true;
  }

  /// 取消預約
  Future<bool> cancelBooking(String bookingId) async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) return false;

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
    if (currentUserId != bookingDetails['user_id'] &&
        currentUserId != bookingDetails['coach_id']) {
      _logError('無權取消此預約: $bookingId');
      return false;
    }

    // 記錄取消人
    final cancelledBy =
        currentUserId == bookingDetails['user_id'] ? 'user' : 'coach';
    final now = DateTime.now();

    await _supabase.from('bookings').update({
      'status': 'cancelled',
      'updated_at': now.toIso8601String(),
      'cancelled_by': cancelledBy,
      'cancelled_at': now.toIso8601String(),
    }).eq('id', bookingId);

    // 釋放預約的時段（如果有）
    if (bookingDetails.containsKey('slot_id')) {
      await _supabase
          .from('available_slots')
          .update({'is_booked': false})
          .eq('id', bookingDetails['slot_id']);
    }

    _logDebug('預約取消成功');
    return true;
  }

  /// 確認預約
  Future<bool> confirmBooking(String bookingId) async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) return false;

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

    await _supabase.from('bookings').update({
      'status': 'confirmed',
      'updated_at': now.toIso8601String(),
      'confirmed_at': now.toIso8601String(),
    }).eq('id', bookingId);

    _logDebug('預約確認成功');
    return true;
  }

  /// 刪除預約
  Future<bool> deleteBooking(String bookingId) async {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) return false;

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
    if (currentUserId != bookingDetails['user_id'] &&
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

    await _supabase.from('bookings').delete().eq('id', bookingId);

    _logDebug('預約刪除成功');
    return true;
  }

  /// 獲取可用時段
  Future<List<Map<String, dynamic>>> getAvailableSlots(String coachId) async {
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

    _logDebug('成功獲取 ${slots.length} 個可用時段');
    return slots;
  }

  /// 設置時段已預約
  Future<bool> setSlotBooked(String slotId) async {
    _logDebug('設置時段已預約: $slotId');
    await _supabase
        .from('available_slots')
        .update({'is_booked': true})
        .eq('id', slotId);

    _logDebug('時段設置已預約成功');
    return true;
  }

  /// 獲取即將到來的預約
  Future<List<Map<String, dynamic>>> getUpcomingBookings(String userId) async {
    final now = DateTime.now();

    // 獲取用戶即將到來的預約
    final userResponse = await _supabase
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .gte('date_time', now.toIso8601String())
        .eq('status', 'confirmed')
        .order('date_time', ascending: true)
        .limit(5);

    final userBookings = (userResponse as List<dynamic>).map((data) {
      final booking = data as Map<String, dynamic>;
      booking['role'] = 'user';
      return booking;
    }).toList();

    // 獲取教練即將到來的預約
    final coachResponse = await _supabase
        .from('bookings')
        .select()
        .eq('coach_id', userId)
        .gte('date_time', now.toIso8601String())
        .eq('status', 'confirmed')
        .order('date_time', ascending: true)
        .limit(5);

    final coachBookings = (coachResponse as List<dynamic>).map((data) {
      final booking = data as Map<String, dynamic>;
      booking['role'] = 'coach';
      return booking;
    }).toList();

    // 合併並按時間排序
    final allBookings = [...userBookings, ...coachBookings];
    allBookings.sort((a, b) {
      final aTime = DateTime.parse(a['date_time'] as String);
      final bTime = DateTime.parse(b['date_time'] as String);
      return aTime.compareTo(bTime);
    });

    return allBookings.take(5).toList();
  }
}

