import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// 預約通知服務
///
/// 負責發送預約相關通知
class BookingNotificationService {
  final SupabaseClient _supabase;
  bool _notificationsEnabled = true;

  BookingNotificationService({required SupabaseClient supabase})
      : _supabase = supabase;

  void configure({required bool enabled}) {
    _notificationsEnabled = enabled;
  }

  /// 發送新預約通知
  Future<void> sendNewBookingNotification(
    String coachId,
    String bookingId,
  ) async {
    await _sendNotification(
      'new_booking',
      coachId,
      bookingId,
      '您收到一個新的預約請求',
    );
  }

  /// 發送預約確認通知
  Future<void> sendBookingConfirmedNotification(
    String userId,
    String bookingId,
  ) async {
    await _sendNotification(
      'booking_confirmed',
      userId,
      bookingId,
      '您的預約已被確認',
    );
  }

  /// 發送預約確認通知（簡化版）
  Future<void> sendConfirmationNotification(
    String userId,
    String bookingId,
  ) async {
    await sendBookingConfirmedNotification(userId, bookingId);
  }

  /// 發送狀態變更通知（根據狀態決定通知類型）
  Future<void> sendStatusChangeNotification(
    String status,
    Map<String, dynamic> bookingDetails,
    String bookingId,
    String currentUserId,
  ) async {
    String recipientId;

    if (status == 'confirmed') {
      recipientId = bookingDetails['user_id'];
      await sendBookingConfirmedNotification(recipientId, bookingId);
    } else if (status == 'cancelled') {
      recipientId = bookingDetails['user_id'] == currentUserId
          ? bookingDetails['coach_id']
          : bookingDetails['user_id'];
      final cancelledBy =
          bookingDetails['user_id'] == currentUserId ? 'user' : 'coach';
      await sendBookingCancelledNotification(
          recipientId, bookingId, cancelledBy);
    } else if (status == 'completed') {
      recipientId = bookingDetails['user_id'];
      await sendBookingCompletedNotification(recipientId, bookingId);
    } else if (status == 'rejected') {
      recipientId = bookingDetails['user_id'];
      await sendBookingRejectedNotification(recipientId, bookingId);
    } else {
      recipientId = bookingDetails['user_id'] == currentUserId
          ? bookingDetails['coach_id']
          : bookingDetails['user_id'];
      await sendBookingUpdatedNotification(recipientId, bookingId);
    }
  }

  /// 發送預約取消通知
  Future<void> sendBookingCancelledNotification(
    String recipientId,
    String bookingId,
    String cancelledBy,
  ) async {
    await _sendNotification(
      'booking_cancelled',
      recipientId,
      bookingId,
      '預約已被${cancelledBy == 'user' ? '用戶' : '教練'}取消',
    );
  }

  /// 發送預約拒絕通知
  Future<void> sendBookingRejectedNotification(
    String userId,
    String bookingId,
  ) async {
    await _sendNotification(
      'booking_rejected',
      userId,
      bookingId,
      '您的預約請求已被拒絕',
    );
  }

  /// 發送預約完成通知
  Future<void> sendBookingCompletedNotification(
    String userId,
    String bookingId,
  ) async {
    await _sendNotification(
      'booking_completed',
      userId,
      bookingId,
      '您的預約已完成',
    );
  }

  /// 發送預約更新通知
  Future<void> sendBookingUpdatedNotification(
    String recipientId,
    String bookingId,
  ) async {
    await _sendNotification(
      'booking_updated',
      recipientId,
      bookingId,
      '您的預約已更新',
    );
  }

  /// 發送預約相關通知（內部方法）
  Future<void> _sendNotification(
    String type,
    String recipientId,
    String bookingId,
    String message,
  ) async {
    if (!_notificationsEnabled) return;

    try {
      await _supabase.from('notifications').insert({
        'id': _generateId(),
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

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _logDebug(String message) {
    if (kDebugMode) {
      print('[BOOKING_NOTIFICATION] $message');
    }
  }

  void _logError(String message) {
    if (kDebugMode) {
      print('[BOOKING_NOTIFICATION ERROR] $message');
    }
  }
}

