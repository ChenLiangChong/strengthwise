import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/// 預約監聽器管理器
///
/// 負責設置和管理 Supabase Realtime 監聽器
class BookingListenerManager {
  final SupabaseClient _supabase;
  final void Function(PostgresChangePayload, {required bool isCoach}) _onBookingChange;
  final void Function(String) _logDebug;

  BookingListenerManager({
    required SupabaseClient supabase,
    required void Function(PostgresChangePayload, {required bool isCoach}) onBookingChange,
    required void Function(String) logDebug,
    required void Function(String) logError,
  })  : _supabase = supabase,
        _onBookingChange = onBookingChange,
        _logDebug = logDebug;

  /// 設置預約更新監聽器（Supabase Realtime）
  Future<void> setupListeners() async {
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
              _onBookingChange(payload, isCoach: false);
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
                _onBookingChange(payload, isCoach: true);
              },
            )
            .subscribe();

        _logDebug('教練預約監聽器設置成功');
      }
    } catch (e) {
      _logDebug('Bookings 設置監聽器失敗（可能是權限問題）: $e');
    }
  }
}

